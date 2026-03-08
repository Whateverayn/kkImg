import Foundation

/// exiftool の -stay_open モードを使用した永続的セッション
public actor ExifToolSession {
    private let exiftoolPath: String
    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?

    private var stdoutTask: Task<Void, Error>?
    private var stderrTask: Task<Void, Error>?

    private var currentStdoutBuffer = ""
    private var currentStderrBuffer = ""

    private var activeContinuation: CheckedContinuation<ExifToolResult, Error>?
    private var currentReadyToken = ""
    private var isStdoutReady = false
    private var isStderrReady = false

    /// - Parameter exiftoolPath: exiftool の実行可能ファイルパス。
    ///   省略した場合は `/usr/bin/env` または `cmd.exe` を使用。
    public init(exiftoolPath: String? = nil) {
        if let path = exiftoolPath {
            self.exiftoolPath = path
        } else {
            #if os(Windows)
            self.exiftoolPath = "cmd.exe"
            #else
            self.exiftoolPath = "/usr/bin/env"
            #endif
        }
    }

    deinit {
        // Actor deinit cannot be async, so we just terminate the process directly if needed.
        if let currentProcess = process, currentProcess.isRunning {
            currentProcess.terminate()
        }
    }

    private func resolveExiftoolPath() -> String? {
        let defaultPaths = [
            "/opt/homebrew/bin/exiftool",
            "/usr/local/bin/exiftool",
            "/opt/local/bin/exiftool",
            "/usr/bin/exiftool"
        ]
        
        // 1. Check if we can find it via sheer execution of `which`
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-l", "-c", "which exiftool"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty, FileManager.default.fileExists(atPath: path) {
                return path
            }
        } catch {
            // Fallback to default paths
        }
        
        // 2. Fallback to default paths
        for path in defaultPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    /// プロセスを開始する (実行時に遅延初期化してもよいが、明示的に開始も可能)
    public func start() throws {
        guard process == nil else { return }

        let task = Process()
        var taskArgs: [String] = []

        if exiftoolPath == "/usr/bin/env" {
            if let resolved = resolveExiftoolPath() {
                task.executableURL = URL(fileURLWithPath: resolved)
                taskArgs.append(contentsOf: ["-stay_open", "True", "-@", "-"])
            } else {
                task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                taskArgs.append("exiftool")
                taskArgs.append(contentsOf: ["-stay_open", "True", "-@", "-"])
            }
        } else if exiftoolPath.lowercased() == "cmd.exe" {
            task.executableURL = URL(fileURLWithPath: "cmd.exe")
            taskArgs.append("/c")
            taskArgs.append("exiftool")
            taskArgs.append(contentsOf: ["-stay_open", "True", "-@", "-"])
        } else {
            task.executableURL = URL(fileURLWithPath: exiftoolPath)
            taskArgs.append(contentsOf: ["-stay_open", "True", "-@", "-"])
        }
        
        task.arguments = taskArgs

        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardInput = inPipe
        task.standardOutput = outPipe
        task.standardError = errPipe
        
        task.terminationHandler = { [weak self] p in
            Task { [weak self] in
                await self?.handleProcessTermination()
            }
        }

        do {
            try task.run()
        } catch {
            throw ExifToolError.launchFailed(error.localizedDescription)
        }

        self.process = task
        self.stdinPipe = inPipe
        self.stdoutPipe = outPipe
        self.stderrPipe = errPipe
        
        startReadingOutput()
    }
    
    private func handleProcessTermination() {
        let exitCode = process?.terminationStatus ?? -1
        let reason = process?.terminationReason
        
        let errorDetails = "Process terminated unexpectedly (exitCode: \(exitCode), reason: \(String(describing: reason))). Stderr context: \(currentStderrBuffer.trimmingCharacters(in: .whitespacesAndNewlines))"
        
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume(throwing: ExifToolError.launchFailed(errorDetails))
        }
        process = nil
    }

    private var stdoutBuffer = Data()
    private var stderrBuffer = Data()

    private func startReadingOutput() {
        guard let outPipe = stdoutPipe, let errPipe = stderrPipe else { return }

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                Task { [weak self] in
                    await self?.handlePipeEOF()
                }
                return
            }
            Task { [weak self] in
                await self?.processStdoutData(data)
            }
        }

        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                Task { [weak self] in
                    await self?.handlePipeEOF()
                }
                return
            }
            Task { [weak self] in
                await self?.processStderrData(data)
            }
        }
    }

    private func processStdoutData(_ data: Data) {
        stdoutBuffer.append(data)
        processBuffer(&stdoutBuffer, handler: handleStdoutLine)
    }

    private func processStderrData(_ data: Data) {
        stderrBuffer.append(data)
        processBuffer(&stderrBuffer, handler: handleStderrLine)
    }

    private func processBuffer(_ buffer: inout Data, handler: (String) -> Void) {
        guard let newline = "\n".data(using: .utf8) else { return }
        
        while let range = buffer.range(of: newline) {
            let lineData = buffer.subdata(in: 0..<range.lowerBound)
            if let line = String(data: lineData, encoding: .utf8) {
                handler(line)
            }
            buffer.removeSubrange(0..<range.upperBound)
        }
    }

    private func handleStdoutLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if !currentReadyToken.isEmpty && trimmed == currentReadyToken {
            isStdoutReady = true
            checkCompletion()
        } else if trimmed == "{ready}" && !currentReadyToken.isEmpty {
            // Ignore the default {ready} if we are waiting for our token
        } else {
            currentStdoutBuffer += line + "\n"
        }
    }

    private func handleStderrLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if !currentReadyToken.isEmpty && trimmed == "\(currentReadyToken)_err" {
            isStderrReady = true
            checkCompletion()
        } else {
            currentStderrBuffer += line + "\n"
        }
    }

    private var eofCount = 0

    private func handlePipeEOF() {
        eofCount += 1
        if eofCount >= 2 {
            // Both stdout and stderr pipes are closed.
            let exitCode = process?.terminationStatus ?? -1
            let reason = process?.terminationReason
            
            let errorDetails = "Process terminated unexpectedly before completion (exitCode: \(exitCode), reason: \(String(describing: reason))). Stderr context: \(currentStderrBuffer.trimmingCharacters(in: .whitespacesAndNewlines))"
            
            if let continuation = activeContinuation {
                activeContinuation = nil
                continuation.resume(throwing: ExifToolError.launchFailed(errorDetails))
            }
        }
    }

    private func checkCompletion() {
        if isStdoutReady && isStderrReady {
            if let continuation = activeContinuation {
                let result = ExifToolResult(stdout: currentStdoutBuffer, stderr: currentStderrBuffer, exitCode: 0)
                activeContinuation = nil
                currentReadyToken = ""
                isStdoutReady = false
                isStderrReady = false
                continuation.resume(returning: result)
            }
        }
    }

    private var isStopping = false

    /// セッションを終了する (-stay_open False を送信)
    public func stop() async {
        guard !isStopping else { return }
        isStopping = true

        guard let currentProcess = process, let inPipe = stdinPipe else {
            cleanUp()
            return
        }

        if let data = "-stay_open\nFalse\n".data(using: .utf8) {
            try? inPipe.fileHandleForWriting.write(contentsOf: data)
        }
        try? inPipe.fileHandleForWriting.close()
        
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil
        
        // ExifToolに終了の猶予を与える (正常終了を待つ)
        var attempts = 0
        while currentProcess.isRunning && attempts < 20 { // 最大2秒
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            attempts += 1
        }
        
        // それでも居座る場合のみ強制終了 (保険)
        if currentProcess.isRunning {
             currentProcess.terminate()
        }
        
        cleanUp()
        
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume(throwing: ExifToolError.launchFailed("Session stopped by user"))
        }
    }

    private func cleanUp() {
        process = nil
        stdinPipe = nil
        stdoutPipe = nil
        stderrPipe = nil
        isStdoutReady = false
        isStderrReady = false
        currentReadyToken = ""
        eofCount = 0
    }

    /// args を実行して結果を待つ
    public func execute(args: [String]) async throws -> ExifToolResult {
        if process == nil {
            try start()
        }

        // すでに実行中の場合はエラーにするか、待機(アクターなので直列化されるが、Continuationは1つ)
        if activeContinuation != nil {
            throw ExifToolError.launchFailed("Already executing a command")
        }

        guard let inPipe = stdinPipe else {
            throw ExifToolError.launchFailed("Process pipes not available")
        }

        // バッファクリア
        currentStdoutBuffer = ""
        currentStderrBuffer = ""

        // 一意のトークンを生成
        let uuid = UUID().uuidString
        let readyToken = "{ready\(uuid)}"
        
        self.currentReadyToken = readyToken
        self.isStdoutReady = false
        self.isStderrReady = false

        var commands = ""
        for arg in args {
            commands += arg + "\n"
        }
        
        // stdout/stderr用の同期トークン
        commands += "-echo3\n"
        commands += "\(readyToken)\n"
        commands += "-echo4\n"
        commands += "\(readyToken)_err\n"
        
        commands += "-execute\n"

        guard let data = commands.data(using: .utf8) else {
            throw ExifToolError.launchFailed("Failed to encode arguments")
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.activeContinuation = continuation
            
            do {
                try inPipe.fileHandleForWriting.write(contentsOf: data)
            } catch {
                self.activeContinuation = nil
                continuation.resume(throwing: ExifToolError.launchFailed("Failed to write to stdin: \(error)"))
            }
        }
    }
}

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
        process?.terminate()
    }

    /// プロセスを開始する (実行時に遅延初期化してもよいが、明示的に開始も可能)
    public func start() throws {
        guard process == nil else { return }

        let task = Process()
        var taskArgs: [String] = []

        if exiftoolPath == "/usr/bin/env" {
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            taskArgs.append("exiftool")
            taskArgs.append(contentsOf: ["-stay_open", "True", "-@", "-"])
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
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume(throwing: ExifToolError.launchFailed("Process terminated unexpectedly"))
        }
        process = nil
    }

    private func startReadingOutput() {
        guard let outPipe = stdoutPipe, let errPipe = stderrPipe else { return }

        stdoutTask = Task {
            for try await line in outPipe.fileHandleForReading.bytes.lines {
                handleStdoutLine(line)
            }
        }

        stderrTask = Task {
            for try await line in errPipe.fileHandleForReading.bytes.lines {
                handleStderrLine(line)
            }
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

    /// セッションを終了する (-stay_open False を送信)
    public func stop() {
        guard process != nil, let inPipe = stdinPipe else { return }
        if let data = "-stay_open\nFalse\n".data(using: .utf8) {
            try? inPipe.fileHandleForWriting.write(contentsOf: data)
        }
        try? inPipe.fileHandleForWriting.close()
        process?.waitUntilExit()
        
        process = nil
        stdinPipe = nil
        stdoutPipe = nil
        stderrPipe = nil
        
        stdoutTask?.cancel()
        stderrTask?.cancel()
        
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume(throwing: ExifToolError.launchFailed("Session stopped"))
        }
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

import Foundation

// MARK: - Result Types

/// exiftool の実行結果
public struct ExifToolResult: Sendable {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32

    public var succeeded: Bool { exitCode == 0 }
}

/// ログエントリー（将来的にファイルやUIへ流しやすいように構造化）
public struct ExifToolLog: Sendable {
    public let timestamp: Date
    public let args: [String]
    public let result: ExifToolResult
}

// MARK: - Errors

public enum ExifToolError: Error, LocalizedError {
    case executableNotFound(String)
    case launchFailed(String)
    case nonZeroExit(Int32, stderr: String)

    public var errorDescription: String? {
        switch self {
        case .executableNotFound(let path):
            return "exiftool が見つかりません: \(path)"
        case .launchFailed(let reason):
            return "exiftool の起動に失敗しました: \(reason)"
        case .nonZeroExit(let code, let stderr):
            return "exiftool が終了コード \(code) で終了しました: \(stderr)"
        }
    }
}

// MARK: - Runner

/// exiftool を子プロセスとして実行するクラス
public final class ExifToolRunner: @unchecked Sendable {

    /// exiftool の検索パス (フルパスを直接渡すこともできる)
    private let exiftoolPath: String

    /// - Parameter exiftoolPath: exiftool の実行可能ファイルパス。
    ///   省略した場合は `/usr/bin/env` 経由で `exiftool` を探す。
    public init(exiftoolPath: String? = nil) {
        if let path = exiftoolPath {
            self.exiftoolPath = path
        } else {
            #if os(Windows)
            self.exiftoolPath = "cmd.exe" // Default for Windows
            #else
            self.exiftoolPath = "/usr/bin/env" // Default for macOS/Linux
            #endif
        }
    }

    // MARK: Public API

    /// exiftool を非同期で実行する
    ///
    /// - Parameter args: exiftool に渡す引数（`exiftool` 自体は含めない）
    /// - Returns: `ExifToolResult`
    /// - Throws: `ExifToolError`
    @discardableResult
    public func execute(args: [String]) async throws -> ExifToolResult {
        let log = try await run(args: args)
        return log.result
    }

    /// exiftool を非同期で実行し、構造化ログごと返す
    ///
    /// - Parameter args: exiftool に渡す引数（`exiftool` 自体は含めない）
    /// - Returns: `ExifToolLog`（タイムスタンプ・引数・結果を含む）
    /// - Throws: `ExifToolError`
    public func executeWithLog(args: [String]) async throws -> ExifToolLog {
        return try await run(args: args)
    }

    // MARK: Private

    private func run(args: [String]) async throws -> ExifToolLog {
        let startedAt = Date()

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try self.runSync(args: args)
                    let log = ExifToolLog(timestamp: startedAt, args: args, result: result)
                    continuation.resume(returning: log)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func runSync(args: [String]) throws -> ExifToolResult {
        let task = Process()
        var taskArgs: [String] = []

        if exiftoolPath == "/usr/bin/env" {
            // macOS/Linux: Use /usr/bin/env to find exiftool
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            taskArgs.append("exiftool")
            taskArgs.append(contentsOf: args)
        } else if exiftoolPath.lowercased() == "cmd.exe" {
            // Windows: Use cmd.exe /c to execute exiftool
            task.executableURL = URL(fileURLWithPath: "cmd.exe")
            taskArgs.append("/c")
            taskArgs.append("exiftool")
            taskArgs.append(contentsOf: args)
        } else {
            // Explicit path provided
            task.executableURL = URL(fileURLWithPath: exiftoolPath)
            taskArgs.append(contentsOf: args)
        }
        
        task.arguments = taskArgs

        let outPipe = Pipe()
        let errPipe = Pipe()
        task.standardOutput = outPipe
        task.standardError = errPipe

        do {
            try task.run()
        } catch {
            throw ExifToolError.launchFailed(error.localizedDescription)
        }

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""
        let exitCode = task.terminationStatus

        return ExifToolResult(stdout: stdout, stderr: stderr, exitCode: exitCode)
    }
}

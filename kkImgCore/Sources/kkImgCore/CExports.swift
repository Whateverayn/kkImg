import Foundation

// MARK: - C API (Windows / C# DllImport 向け)
//
// 引数はJSON配列文字列形式で受け取り、結果もJSON文字列で返す。
// 呼び出し元は戻り値のポインタを kkimg_free_string() で解放すること。
//
// C# 側の例:
//   [DllImport("kkImgCore")] static extern IntPtr kkimg_exiftool_execute(string argsJson);
//   [DllImport("kkImgCore")] static extern void   kkimg_free_string(IntPtr ptr);
//
//   var ptr = kkimg_exiftool_execute("[\"-ver\"]");
//   var json = Marshal.PtrToStringUTF8(ptr)!;
//   kkimg_free_string(ptr);

@_cdecl("kkimg_exiftool_execute")
public func kkimg_exiftool_execute(_ argsJsonPtr: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>? {
    guard let argsJsonPtr else {
        return makeErrorJSON("args_json is null")
    }

    let argsJsonString = String(cString: argsJsonPtr)

    // JSON配列のパース
    guard
        let data = argsJsonString.data(using: .utf8),
        let args = try? JSONDecoder().decode([String].self, from: data)
    else {
        return makeErrorJSON("Invalid JSON: expected array of strings")
    }

    // 同期実行（C API はブロッキング）
    let runner = ExifToolRunner()
    let semaphore = DispatchSemaphore(value: 0)
    var resultJSON: String = "{\"stdout\":\"\",\"stderr\":\"Internal error\",\"exitCode\":-1}"

    Task {
        do {
            let result = try await runner.execute(args: args)
            resultJSON = encodeResult(result)
        } catch let e as ExifToolError {
            resultJSON = encodeError(e)
        } catch {
            resultJSON = makeErrorString(error.localizedDescription)
        }
        semaphore.signal()
    }

    semaphore.wait()
    return duplicateCString(resultJSON)
}

@_cdecl("kkimg_free_string")
public func kkimg_free_string(_ ptr: UnsafeMutablePointer<CChar>?) {
    ptr?.deallocate()
}

// MARK: - ExifTool Session C API

@_cdecl("kkimg_exiftool_session_start")
public func kkimg_exiftool_session_start() -> UnsafeMutableRawPointer {
    let session = ExifToolSession()
    // Retain the object and return an opaque pointer
    let unmanaged = Unmanaged.passRetained(session)
    return unmanaged.toOpaque()
}

@_cdecl("kkimg_exiftool_session_execute")
public func kkimg_exiftool_session_execute(
    _ sessionPtr: UnsafeMutableRawPointer?,
    _ argsJsonPtr: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<CChar>? {
    guard let sessionPtr else {
        return makeErrorJSON("session_ptr is null")
    }
    guard let argsJsonPtr else {
        return makeErrorJSON("args_json is null")
    }

    let session = Unmanaged<ExifToolSession>.fromOpaque(sessionPtr).takeUnretainedValue()
    let argsJsonString = String(cString: argsJsonPtr)

    guard
        let data = argsJsonString.data(using: .utf8),
        let args = try? JSONDecoder().decode([String].self, from: data)
    else {
        return makeErrorJSON("Invalid JSON: expected array of strings")
    }

    let semaphore = DispatchSemaphore(value: 0)
    var resultJSON: String = "{\"stdout\":\"\",\"stderr\":\"Internal error\",\"exitCode\":-1}"

    Task {
        do {
            let result = try await session.execute(args: args)
            resultJSON = encodeResult(result)
        } catch let e as ExifToolError {
            resultJSON = encodeError(e)
        } catch {
            resultJSON = makeErrorString(error.localizedDescription)
        }
        semaphore.signal()
    }

    semaphore.wait()
    return duplicateCString(resultJSON)
}

@_cdecl("kkimg_exiftool_session_stop")
public func kkimg_exiftool_session_stop(_ sessionPtr: UnsafeMutableRawPointer?) {
    guard let sessionPtr else { return }
    let unmanaged = Unmanaged<ExifToolSession>.fromOpaque(sessionPtr)
    let session = unmanaged.takeRetainedValue() // release balance
    
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await session.stop()
        semaphore.signal()
    }
    semaphore.wait()
}

// MARK: - Helpers

private func encodeResult(_ result: ExifToolResult) -> String {
    // 手動JSON構築（依存を増やさないため）
    let stdout = jsonEscape(result.stdout)
    let stderr = jsonEscape(result.stderr)
    return "{\"stdout\":\"\(stdout)\",\"stderr\":\"\(stderr)\",\"exitCode\":\(result.exitCode)}"
}

private func encodeError(_ error: ExifToolError) -> String {
    return makeErrorString(error.localizedDescription)
}

private func makeErrorString(_ message: String) -> String {
    let escaped = jsonEscape(message)
    return "{\"stdout\":\"\",\"stderr\":\"\(escaped)\",\"exitCode\":-1}"
}

private func makeErrorJSON(_ message: String) -> UnsafeMutablePointer<CChar>? {
    return duplicateCString(makeErrorString(message))
}

private func duplicateCString(_ string: String) -> UnsafeMutablePointer<CChar>? {
    let bytes = Array(string.utf8) + [0]  // null terminator
    let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: bytes.count)
    bytes.withUnsafeBytes { raw in
        ptr.initialize(from: raw.bindMemory(to: CChar.self).baseAddress!, count: bytes.count)
    }
    return ptr
}

/// JSON文字列内の特殊文字をエスケープする
private func jsonEscape(_ string: String) -> String {
    var result = ""
    result.reserveCapacity(string.count)
    for char in string {
        switch char {
        case "\"": result += "\\\""
        case "\\": result += "\\\\"
        case "\n": result += "\\n"
        case "\r": result += "\\r"
        case "\t": result += "\\t"
        default:   result.append(char)
        }
    }
    return result
}

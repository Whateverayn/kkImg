import Foundation
import kkImgCore

// CLIターゲット: 動作確認用
// 使い方: swift run kkImgCoreCLI [exiftoolの引数...]
// 例:    swift run kkImgCoreCLI -ver
//        swift run kkImgCoreCLI -T -DateTimeOriginal /path/to/photo.jpg

@main
struct CLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.isEmpty {
            print("Usage: kkImgCoreCLI [exiftool args...]")
            print("Example: kkImgCoreCLI -ver")
            return
        }

        let runner = ExifToolRunner()

        do {
            let log = try await runner.executeWithLog(args: args)
            let result = log.result

            print("=== kkImgCore ExifTool Runner ===")
            print("Timestamp : \(log.timestamp)")
            print("Args      : \(log.args.joined(separator: " "))")
            print("Exit Code : \(result.exitCode)")
            print("")
            if !result.stdout.isEmpty {
                print("--- stdout ---")
                print(result.stdout)
            }
            if !result.stderr.isEmpty {
                print("--- stderr ---")
                print(result.stderr, to: &standardError)
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}

// stderr への書き込みヘルパー
var standardError = StandardError()
struct StandardError: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

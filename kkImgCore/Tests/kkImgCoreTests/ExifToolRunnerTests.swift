import XCTest
@testable import kkImgCore

final class ExifToolRunnerTests: XCTestCase {

    // exiftool がインストールされている前提のテスト
    // CI環境でskipしたい場合は SKIP_EXIFTOOL_TESTS=1 を設定する

    private var runner: ExifToolRunner!

    override func setUp() {
        super.setUp()
        runner = ExifToolRunner()
    }

    func testExifToolVersion() async throws {
        guard ProcessInfo.processInfo.environment["SKIP_EXIFTOOL_TESTS"] == nil else {
            throw XCTSkip("SKIP_EXIFTOOL_TESTS が設定されているためスキップします")
        }

        let result = try await runner.execute(args: ["-ver"])

        XCTAssertEqual(result.exitCode, 0, "exiftool -ver は exit code 0 を返すべき")
        XCTAssertFalse(result.stdout.isEmpty, "stdout にバージョン文字列が含まれるべき")

        // バージョン番号は "12.xx" のような形式
        let version = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let versionPattern = try NSRegularExpression(pattern: #"^\d+\.\d+"#)
        let range = NSRange(version.startIndex..., in: version)
        XCTAssertNotNil(
            versionPattern.firstMatch(in: version, range: range),
            "バージョン文字列がパターンに一致するべき (got: '\(version)')"
        )
    }

    func testExecuteWithLogReturnsTimestamp() async throws {
        guard ProcessInfo.processInfo.environment["SKIP_EXIFTOOL_TESTS"] == nil else {
            throw XCTSkip("SKIP_EXIFTOOL_TESTS が設定されているためスキップします")
        }

        let before = Date()
        let log = try await runner.executeWithLog(args: ["-ver"])
        let after = Date()

        XCTAssertGreaterThanOrEqual(log.timestamp, before)
        XCTAssertLessThanOrEqual(log.timestamp, after)
        XCTAssertEqual(log.args, ["-ver"])
    }

    func testNonExistentFileReturnsNonZeroExitCode() async throws {
        guard ProcessInfo.processInfo.environment["SKIP_EXIFTOOL_TESTS"] == nil else {
            throw XCTSkip("SKIP_EXIFTOOL_TESTS が設定されているためスキップします")
        }

        // exiftool は存在しないファイルでも exit code 1 で stderr にエラーを出す
        let result = try await runner.execute(args: ["/nonexistent/path/to/image.jpg"])

        XCTAssertNotEqual(result.exitCode, 0, "存在しないファイルでは非ゼロの exit code を返すべき")
    }

    func testExifToolResultSucceeded() {
        let success = ExifToolResult(stdout: "12.76\n", stderr: "", exitCode: 0)
        XCTAssertTrue(success.succeeded)

        let failure = ExifToolResult(stdout: "", stderr: "error", exitCode: 1)
        XCTAssertFalse(failure.succeeded)
    }
}

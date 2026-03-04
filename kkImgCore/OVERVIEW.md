# kkImgCore — 概要ドキュメント

Windows側での開発用メモ

---

## このライブラリは何か

`kkImgCore` は、exiftool を子プロセスとして起動して呼び出すロジックを Swift で実装した共有ライブラリです。

- **macOS (React Native)**: Xcodeプロジェクトに組み込んでネイティブモジュール経由で利用
- **Windows (C# / Windows App SDK)**: DLL としてビルドして `DllImport` / `P/Invoke` 経由で利用

GUI は共有せず、**内部ロジックのみを共有する**のがこのライブラリの役割です。

---

## 主要な型

### `ExifToolResult`

exiftool 実行の出力をまとめた構造体。

```swift
struct ExifToolResult {
    let stdout: String    // 標準出力（exiftoolの結果テキスト）
    let stderr: String    // 標準エラー出力（エラーメッセージ等）
    let exitCode: Int32   // プロセスの終了コード（0 = 正常）
    var succeeded: Bool   // exitCode == 0 のとき true
}
```

### `ExifToolLog`

実行時のタイムスタンプと引数も含むログ構造体。

```swift
struct ExifToolLog {
    let timestamp: Date        // 実行開始時刻
    let args: [String]         // 渡した引数
    let result: ExifToolResult // 実行結果
}
```

### `ExifToolError`

実行失敗時にスローされるエラー。

| ケース | 意味 |
|---|---|
| `.executableNotFound(path)` | exiftool のパスが存在しない |
| `.launchFailed(reason)` | プロセスの起動に失敗 |
| `.nonZeroExit(code, stderr)` | exiftool が非ゼロで終了 |

---

## 処理の流れ

1. `ExifToolRunner.execute(args:)` が呼ばれる
2. 内部で `Process` オブジェクトを生成し exiftool を起動（OS別に起動方法が異なる）
3. stdout / stderr を `Pipe` で受け取る
4. `waitUntilExit()` でプロセスの終了を待つ
5. `ExifToolResult` にまとめて返す

**macOS / Linux**: `/usr/bin/env exiftool [args...]`
```
呼び出し元
  └─ execute(args: ["-T", "-DateTimeOriginal", "/path/to/photo.jpg"])
       └─ /usr/bin/env exiftool -T -DateTimeOriginal /path/to/photo.jpg
            ├─ stdout: "2024:03:15 12:34:56\n"
            ├─ stderr: ""
            └─ exitCode: 0
```

**Windows**: `cmd.exe /c exiftool [args...]`
```
呼び出し元
  └─ execute(args: ["-T", "-DateTimeOriginal", "C:\\photo.jpg"])
       └─ cmd.exe /c exiftool -T -DateTimeOriginal C:\photo.jpg
            ├─ stdout: "2024:03:15 12:34:56\n"
            ├─ stderr: ""
            └─ exitCode: 0
```

**引数には `"exiftool"` 自体は含めない**。ライブラリが自動で先頭に追加する。

フルパスを `ExifToolRunner(exiftoolPath: "C:\\tools\\exiftool.exe")` のように渡した場合は、cmd.exe を経由せず直接起動する。

---

## 永続セッション処理の流れ (`ExifToolSession`)

`ExifToolRunner` が1ファイル/1コマンドごとにプロセスを起動・終了するのに対し、`ExifToolSession` は `exiftool -stay_open True -@ -` モードを利用し、ひとつのプロセスを常駐させます。
数千枚のファイルを処理する場合など、パフォーマンスが求められるシナリオ（特にWindows環境などでのプロセス起動コスト削減）で利用します。

1. `let session = ExifToolSession()` でインスタンスを生成
2. `try await session.execute(args:)` を実行（內部で初回のみプロセス起動）
3. パイプ経由でコマンドを送信し、非同期で `stdout` / `stderr` を読み取って結果を返す
4. `await session.stop()` でプロセスを正常終了させる

---

## C API（Windows向け）

`CExports.swift` にて `@_cdecl` で以下の関数群を公開している。

### 1-shot実行API (旧来)

#### `kkimg_exiftool_execute(args_json)`

```
入力: JSON配列文字列 例: "["-T", "-DateTimeOriginal", "/path/to/photo.jpg"]"
出力: JSON文字列    例: {"stdout":"2024:03:15 12:34:56\n","stderr":"","exitCode":0}
```

- 同期（ブロッキング）で実行される
- 呼び出し元が戻り値のポインタを `kkimg_free_string()` で解放する責任を持つ

### Session API (stay_open モード利用)

#### `kkimg_exiftool_session_start()`
セッションを開始し、`ExifToolSession` インスタンスの不透明ポインタ (`IntPtr`) を返す。

#### `kkimg_exiftool_session_execute(session_ptr, args_json)`
保持しているセッションポインタを利用してコマンドを実行する。戻り値の形式・扱いは `kkimg_exiftool_execute` と同じ（都度 `kkimg_free_string` で解放が必要）。UIを1件ずつ更新するのに適している。

#### `kkimg_exiftool_session_stop(session_ptr)`
セッションを終了させ、インスタンスのメモリを解放する。

---

### 共通関数

#### `kkimg_free_string(ptr)`

`execute` メソッド群が返したJSON結果のポインタを解放する。必ず呼ぶこと。

---

## ヘッダーファイル

`include/kkImgCore.h` に C言語の関数宣言がある。  
C++ / C# / Rust などから利用する際にインクルードまたは参照する。

---

## Windows向け DLL のビルド方法

> [!NOTE]
> Swift for Windows (Swift SDK) を使ってビルドする。2025年時点では Windows 上で Swift をインストールするか、クロスコンパイルで生成する。

### 方法A: Windows上で直接ビルド

1. [Swift公式](https://www.swift.org/install/windows/) から Swift for Windows をインストール
2. `kkImgCore` ディレクトリで以下を実行:

```powershell
swift build -c release
```

3. ビルド成果物は `.build\release\kkImgCore.dll` に生成される
4. `include\kkImgCore.h` を C# プロジェクトに含める（または直接 DllImport で宣言）

### 方法B: macOS からクロスコンパイル（将来対応予定）

Swift クロスコンパイル SDK が安定したら対応予定。現時点では方法Aを推奨。

### ビルド確認

Windows PowerShell で依存関係確認:

```powershell
swift build -c release 2>&1
# Build complete! と表示されれば成功
```

---

## 今後実装予定のロジック（このライブラリに追加していくもの）

- **ファイル名→日時推測** (`kkImg.py` の `convert_filename_to_datetime_2` 相当)
- **exiftoolによる日付書き込み** (`-alldates=...` の実行)
- **avifenc の実行ロジック** (AVIF変換)

これらも同様に `ExifToolRunner.swift` と並べて `Sources/kkImgCore/` 以下に追加していく予定。

---

## ファイル構成まとめ

```
kkImgCore/
├── Package.swift                          Swift Package Managerの設定
├── OVERVIEW.md                            このドキュメント
├── include/
│   └── kkImgCore.h                        C言語ヘッダー（DllImport用）
├── Sources/
│   ├── kkImgCore/
│   │   ├── ExifToolRunner.swift           1-shotのexiftool実行ロジック
│   │   ├── ExifToolSession.swift          stay_openモードを利用する永続セッション
│   │   └── CExports.swift                 @_cdecl C API（Windows向け）
│   └── kkImgCoreCLI/
│       └── main.swift                     動作確認用CLIツール
└── Tests/
    └── kkImgCoreTests/
        └── ExifToolRunnerTests.swift      ユニットテスト
```
## Swift (macOS / iOS) での使用例

Swift環境からは、`ExifToolSession` Actor をそのまま利用できます。Async/Await ベースで直感的に結果を受け取ることができます。

```swift
import kkImgCore

Task {
    // セッションのインスタンスを作成
    let session = ExifToolSession()
    
    do {
        // 1ファイル目の実行（初回は自動的にプロセスが起動します）
        let result1 = try await session.execute(args: ["-j", "file1.jpg"])
        print("Stdout1:", result1.stdout) // JSON形式のメタデータ
        
        // 2ファイル目の実行
        let result2 = try await session.execute(args: ["-T", "-DateTimeOriginal", "file2.jpg"])
        print("Stdout2:", result2.stdout)
        
        // 不要になったら stop() を呼んでプロセスを終了させます
        await session.stop()
    } catch {
        print("ExifTool session error: \(error)")
    }
}
```

## C# での使用例

```csharp
using System.Runtime.InteropServices;

[DllImport("kkImgCore")]
static extern IntPtr kkimg_exiftool_session_start();

[DllImport("kkImgCore")]
static extern IntPtr kkimg_exiftool_session_execute(IntPtr sessionPtr, string argsJson);

[DllImport("kkImgCore")]
static extern void kkimg_exiftool_session_stop(IntPtr sessionPtr);

[DllImport("kkImgCore")]
static extern void kkimg_free_string(IntPtr ptr);

// 使用例
var sessionPtr = kkimg_exiftool_session_start();

var resPtr1 = kkimg_exiftool_session_execute(sessionPtr, "[\"-j\", \"file1.jpg\"]");
var json1 = Marshal.PtrToStringUTF8(resPtr1)!;
kkimg_free_string(resPtr1);
// json1 を利用してUIを更新

var resPtr2 = kkimg_exiftool_session_execute(sessionPtr, "[\"-j\", \"file2.jpg\"]");
var json2 = Marshal.PtrToStringUTF8(resPtr2)!;
kkimg_free_string(resPtr2);
// json2 を利用してUIを更新

kkimg_exiftool_session_stop(sessionPtr);
```
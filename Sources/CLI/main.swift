import Foundation

// MARK: - Localization (LANG env: en / ja / zh)
enum L10n {
    static let lang: String = {
        let l = (ProcessInfo.processInfo.environment["LANG"]
                 ?? ProcessInfo.processInfo.environment["LC_ALL"] ?? "en").lowercased()
        if l.hasPrefix("ja") { return "ja" }
        if l.hasPrefix("zh") { return "zh" }
        return "en"
    }()

    private static let strings: [String: [String: String]] = [
        "usage": [
            "en": """
                  mknb — blink the MacBook keyboard backlight as a notification

                  usage:
                    mknb get                        print brightness (0.0-1.0)
                    mknb status                     print full state
                    mknb set <0.0-1.0>              set brightness
                    mknb auto [on|off]              get/set auto brightness (ALS)
                    mknb ids                        list keyboard backlight IDs
                    mknb blink [times] [fade] [hold]   blink (default: 2, 1.4s, 0.5s)
                    mknb notify <title> [body]      Notification Center + blink
                  """,
            "ja": """
                  mknb — キーボードバックライトをゆっくり点滅させる通知ツール

                  使い方:
                    mknb get                        現在の輝度 (0.0-1.0)
                    mknb status                     状態をすべて表示
                    mknb set <0.0-1.0>              輝度を設定
                    mknb auto [on|off]              自動調整(ALS)の確認/切替
                    mknb ids                        バックライトID一覧
                    mknb blink [回数] [fade] [hold] 点滅（既定: 2回, 1.4秒, 0.5秒）
                    mknb notify <タイトル> [本文]     通知センター + 点滅
                  """,
            "zh": """
                  mknb — 让 MacBook 键盘背光缓慢闪烁作为通知

                  用法:
                    mknb get                        显示当前亮度 (0.0-1.0)
                    mknb status                     显示完整状态
                    mknb set <0.0-1.0>              设置亮度
                    mknb auto [on|off]              查看/切换自动亮度 (ALS)
                    mknb ids                        列出背光键盘 ID
                    mknb blink [次数] [fade] [hold]  闪烁 (默认: 2次, 1.4秒, 0.5秒)
                    mknb notify <标题> [正文]         通知中心 + 闪烁
                  """,
        ],
        "err.framework": [
            "en": "error: CoreBrightness private API unavailable",
            "ja": "エラー: CoreBrightness のプライベートAPIが使えません",
            "zh": "错误: CoreBrightness 私有 API 不可用",
        ],
        "err.nokeyboard": [
            "en": "error: no backlit keyboard found",
            "ja": "エラー: バックライト付きキーボードが見つかりません",
            "zh": "错误: 未找到背光键盘",
        ],
        "err.args": [
            "en": "error: invalid arguments",
            "ja": "エラー: 引数が不正です",
            "zh": "错误: 参数无效",
        ],
        "done": [
            "en": "done. restored=",
            "ja": "完了。復帰輝度=",
            "zh": "完成。恢复亮度=",
        ],
    ]

    static func t(_ key: String) -> String {
        strings[key]?[lang] ?? strings[key]?["en"] ?? key
    }
}

// MARK: - main
func errOut(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }

let args = CommandLine.arguments
let cmd = args.count > 1 ? args[1] : "help"

do {
    let bl = try Backlight()
    switch cmd {
    case "get":
        print(String(format: "%.4f", bl.brightness))
    case "status":
        let s = bl.status
        print("kbID=\(bl.keyboardID) brightness=\(s.brightness) level=\(s.level) suppressed=\(s.suppressed) saturated=\(s.saturated) auto=\(s.auto)")
    case "ids":
        print(bl.keyboardID)
    case "set":
        guard args.count > 2, let v = Double(args[2]) else { throw CocoaError(.coderInvalidValue) }
        bl.brightness = v
        Thread.sleep(forTimeInterval: 0.1)
        print(String(format: "%.4f", bl.brightness))
    case "auto":
        if args.count > 2 { bl.auto = (args[2] == "on" || args[2] == "1") }
        print("auto: \(bl.auto)")
    case "blink":
        let times = args.count > 2 ? Int(args[2]) ?? 2 : 2
        let fade  = args.count > 3 ? Double(args[3]) ?? 1.4 : 1.4
        let hold  = args.count > 4 ? Double(args[4]) ?? 0.5 : 0.5
        bl.blink(times: times, fade: fade, hold: hold)
        print(L10n.t("done") + String(format: "%.4f", bl.brightness))
    case "notify":
        guard args.count > 2 else {
            errOut(L10n.t("err.args"))
            exit(2)
        }
        bl.notify(title: args[2], body: args.count > 3 ? args[3] : "")
    default:
        print(L10n.t("usage"))
    }
} catch Backlight.Failure.frameworkUnavailable {
    errOut(L10n.t("err.framework"))
    exit(1)
} catch Backlight.Failure.noKeyboard {
    errOut(L10n.t("err.nokeyboard"))
    exit(1)
} catch {
    errOut(L10n.t("err.args"))
    exit(2)
}

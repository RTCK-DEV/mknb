# Matataki (瞬き)

**MacBook のキーボードバックライトを、ゆっくり点滅させて知らせるツール。**

[English](README.md) · [简体中文](README.zh-Hans.md)

ビルド完了・バックアップ終了・長時間コマンドの終了など、気づきたいタイミングで
キーボードが「瞬きます」（既定: 2回・約8秒）。手動操作用のメニューバーアプリ
**Matataki.app** も同梱。

## 機能

- CLI `matataki`: 輝度の取得/設定、自動調整の切替、点滅、通知
- `matataki notify "タイトル" "本文"` — 通知センターへ通知＋点滅
- メニューバーアプリ: 輝度スライダー、自動調整トグル、点滅テスト、
  ログイン時起動、状態表示（レベル/抑制/飽和）
- 日本語 / English / 简体中文（CLI は `LANG` に、アプリはシステム言語に追従）
- アクセシビリティ権限不要、sudo 不要、依存なし

## インストール

[Releases](../../releases) から:

```sh
unzip matataki.zip
sudo install -m 755 matataki /usr/local/bin/   # または ~/bin, ~/.local/bin
xattr -d com.apple.quarantine matataki          # ブラウザでDLした場合
```

アプリ: `Matataki.app.zip` を解凍して `/Applications` へ。

## 使い方

```sh
matataki get                          # 現在の輝度 (0.0-1.0)
matataki set 0.5                      # 輝度を設定
matataki auto on                      # 環境光による自動調整
matataki status                       # 輝度, レベル(nits), 抑制, 飽和
matataki blink                        # ゆっくり2回点滅（フェード1.4秒+ホールド0.5秒）
matataki blink 3 1.0 0.3              # 3回・フェード1.0秒・ホールド0.3秒
matataki notify "ビルド" "完了"         # 通知 + 点滅

# 例
make && matataki notify "ビルド" "成功"
sleep 300 && matataki blink           # 5分タイマーがキーボードを光らせる
```

## 仕組み

macOS にはキーボードバックライトの公開 API がありません。`matataki` は
システム設定と同じプライベート `CoreBrightness.framework` を使います。

近年の macOS では、便利クラス `KeyboardBrightnessClient` の
`setBrightness:forKeyboard:` は設定値だけを書き換え、LED には届きません。
Matataki は汎用 `BrightnessSystemClient` 経由で `KeyboardBacklightBrightness`
プロパティを書き込みます — これが実際にハードウェア（`KeyboardBacklightLevel`、
単位はニト）へ伝わる経路です。点滅中は環境光による自動調整とアイドル減光を
一時停止し、終了後に復帰。元の輝度へはフェードで戻ります。

> 注意: プライベート API のため将来の macOS で動かなくなる可能性があります。
> macOS 27 (Mac17,9) で確認済み。動かなくなった場合は `matataki status` で
> `level` が `brightness` に追従しているか確認してください。

## ビルド

Xcode Command Line Tools（`xcode-select --install`）が必要です。

```sh
./scripts/build.sh        # CLI + Matataki.app を build/ に生成
make install              # CLI を ~/.local/bin にインストール
```

## ライセンス

MIT

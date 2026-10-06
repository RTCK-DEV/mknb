# Matataki (瞬き)

**让 MacBook 键盘背光缓慢闪烁来通知你。**

[English](README.md) · [日本語](README.ja.md)

当编译完成、备份结束或长时间命令跑完时，键盘会"眨眼"提醒你
（默认：2次，约8秒）。同时附带用于手动控制的菜单栏应用 **Matataki.app**。

## 功能

- CLI `matataki`：读取/设置亮度、切换自动亮度、闪烁、通知
- `matataki notify "标题" "正文"` — 通知中心横幅 + 闪烁
- 菜单栏应用：亮度滑块、自动亮度开关、闪烁测试、
  登录时启动、实时状态（亮度级/抑制/饱和）
- 简体中文 / English / 日本語（CLI 跟随 `LANG`，应用跟随系统语言）
- 无需辅助功能权限、无需 sudo、无依赖

## 安装

从 [Releases](../../releases) 下载：

```sh
unzip matataki.zip
sudo install -m 755 matataki /usr/local/bin/   # 或 ~/bin, ~/.local/bin
xattr -d com.apple.quarantine matataki          # 浏览器下载时
```

应用：解压 `Matataki.app.zip`，把 `Matataki.app` 移到 `/Applications`。

## 用法

```sh
matataki get                          # 当前亮度 (0.0-1.0)
matataki set 0.5                      # 设置亮度
matataki auto on                      # 环境光自动调节
matataki status                       # 亮度, 亮度级(nits), 抑制, 饱和
matataki blink                        # 缓慢闪烁2次（渐变1.4秒+保持0.5秒）
matataki blink 3 1.0 0.3              # 3次·渐变1.0秒·保持0.3秒
matataki notify "编译" "完成"          # 通知 + 闪烁

# 示例
make && matataki notify "编译" "成功"
sleep 300 && matataki blink           # 5分钟计时器点亮键盘
```

## 原理

macOS 没有键盘背光的公开 API。`matataki` 使用与系统设置相同的私有
`CoreBrightness.framework`。

在较新的 macOS 上，便捷类 `KeyboardBrightnessClient` 的
`setBrightness:forKeyboard:` 只会更新保存的偏好值，不会驱动 LED。
Matataki 通过通用 `BrightnessSystemClient` 接口写入
`KeyboardBacklightBrightness` 属性 —— 这是真正能传到硬件
（`KeyboardBacklightLevel`，单位尼特）的路径。闪烁期间会临时暂停
环境光自动调节和空闲变暗，结束后恢复，并渐变回原来的亮度。

> 注意：私有 API —— 未来 macOS 版本可能会失效。已在 macOS 27
> (Mac17,9) 上验证。若失效，用 `matataki status` 检查 `level`
> 是否仍跟随 `brightness` 变化。

## 构建

需要 Xcode Command Line Tools（`xcode-select --install`）。

```sh
./scripts/build.sh        # 构建 CLI + Matataki.app 到 build/
make install              # 安装 CLI 到 ~/.local/bin
```

## 许可证

MIT

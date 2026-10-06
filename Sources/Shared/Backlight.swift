import Foundation

/// Thin wrapper over private CoreBrightness APIs.
///
/// On modern macOS the convenience class `KeyboardBrightnessClient` accepts
/// writes but they never reach the LED. The generic property interface on
/// `BrightnessSystemClient` (`setProperty:withKey:keyboardID:` /
/// `copyPropertyForKey:keyboardID:`) is the path that actually drives the
/// hardware ("KeyboardBacklightBrightness" write propagates to
/// "KeyboardBacklightLevel" in nits).
public final class Backlight {
    public enum Failure: Error {
        case frameworkUnavailable
        case noKeyboard
    }

    public struct Status {
        public var brightness: Double
        public var level: Double       // hardware level (nits)
        public var suppressed: Bool
        public var saturated: Bool
        public var auto: Bool
    }

    private typealias ActFn  = @convention(c) (NSObject, Selector, UnsafeMutablePointer<NSError?>) -> Bool
    private typealias C2     = @convention(c) (NSObject, Selector, AnyObject, UInt64) -> AnyObject?
    private typealias S3     = @convention(c) (NSObject, Selector, AnyObject, AnyObject, UInt64) -> Void
    private typealias IDsFn  = @convention(c) (NSObject, Selector) -> NSArray
    private typealias BoolF  = @convention(c) (NSObject, Selector, UInt64) -> Bool
    private typealias BoolB  = @convention(c) (NSObject, Selector, Bool, UInt64) -> Bool

    private let bs: NSObject    // BrightnessSystemClient
    private let kb: NSObject    // KeyboardBrightnessClient
    public  let keyboardID: UInt64

    private let sC2  = NSSelectorFromString("copyPropertyForKey:keyboardID:")
    private let sS3  = NSSelectorFromString("setProperty:withKey:keyboardID:")
    private let sAuto  = NSSelectorFromString("enableAutoBrightness:forKeyboard:")
    private let sAutoG = NSSelectorFromString("isAutoBrightnessEnabledForKeyboard:")
    private let sSusp  = NSSelectorFromString("suspendIdleDimming:forKeyboard:")

    private lazy var c2: C2 = unsafeBitCast(bs.method(for: sC2), to: C2.self)
    private lazy var s3: S3 = unsafeBitCast(bs.method(for: sS3), to: S3.self)

    public init() throws {
        guard dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_NOW) != nil,
              let bsCls = NSClassFromString("BrightnessSystemClient") as? NSObject.Type,
              let kbCls = NSClassFromString("KeyboardBrightnessClient") as? NSObject.Type else {
            throw Failure.frameworkUnavailable
        }
        let bsClient = bsCls.init()
        let kbClient = kbCls.init()

        var err: NSError? = nil
        let actSel = NSSelectorFromString("activateWithError:")
        let act = unsafeBitCast(bsClient.method(for: actSel), to: ActFn.self)
        _ = withUnsafeMutablePointer(to: &err) { act(bsClient, actSel, $0) }

        let sIDs = NSSelectorFromString("copyKeyboardBacklightIDs")
        let idsFn = unsafeBitCast(kbClient.method(for: sIDs), to: IDsFn.self)
        let ids = idsFn(kbClient, sIDs) as? [UInt64] ?? []
        let sBlt = NSSelectorFromString("isKeyboardBuiltIn:")
        let built = unsafeBitCast(kbClient.method(for: sBlt), to: BoolF.self)
        let builtIn = ids.filter { built(kbClient, sBlt, $0) }.first
        guard let id = builtIn ?? ids.first else {
            throw Failure.noKeyboard
        }
        bs = bsClient
        kb = kbClient
        keyboardID = id
    }

    private func prop(_ key: String) -> AnyObject? { c2(bs, sC2, key as NSString, keyboardID) }
    private func propNum(_ key: String) -> Double { (prop(key) as? NSNumber)?.doubleValue ?? 0 }

    public var brightness: Double {
        get { propNum("KeyboardBacklightBrightness") }
        set { s3(bs, sS3, NSNumber(value: min(1, max(0, newValue))), "KeyboardBacklightBrightness" as NSString, keyboardID) }
    }

    public var level: Double      { propNum("KeyboardBacklightLevel") }
    public var suppressed: Bool   { propNum("KeyboardBacklightSuppressed") > 0 }
    public var saturated: Bool    { propNum("KeyboardBacklightSaturated") > 0 }

    public var auto: Bool {
        get { unsafeBitCast(kb.method(for: sAutoG), to: BoolF.self)(kb, sAutoG, keyboardID) }
        set { _ = unsafeBitCast(kb.method(for: sAuto), to: BoolB.self)(kb, sAuto, newValue, keyboardID) }
    }

    public var status: Status {
        Status(brightness: brightness, level: level, suppressed: suppressed, saturated: saturated, auto: auto)
    }

    /// Suspend idle dimming (writes return Bool, fire-and-forget).
    public func suspendIdleDimming(_ on: Bool) {
        _ = unsafeBitCast(kb.method(for: sSusp), to: BoolB.self)(kb, sSusp, on, keyboardID)
    }

    /// Smoothly ramp brightness. Hardware already applies ~1s of fade lag.
    public func ramp(to target: Double, seconds: Double, steps: Int = 20) {
        let from = brightness
        for i in 1...steps {
            brightness = from + (target - from) * Double(i) / Double(steps)
            Thread.sleep(forTimeInterval: seconds / Double(steps))
        }
    }

    /// Blink `times` times. Auto-brightness and idle dimming are suspended for
    /// the duration and restored afterwards; the saved brightness is always
    /// faded back to at the end.
    public func blink(times: Int = 2, fade: Double = 1.4, hold: Double = 0.5) {
        let saved = brightness
        let wasAuto = auto
        if wasAuto { auto = false }
        suspendIdleDimming(true)
        let upTo = max(saved, 0.6)
        for i in 0..<times {
            ramp(to: upTo, seconds: fade)
            if i < times - 1 || saved < upTo { Thread.sleep(forTimeInterval: hold) }
            ramp(to: 0.0, seconds: fade)
            Thread.sleep(forTimeInterval: hold)
        }
        ramp(to: saved, seconds: 0.6)
        suspendIdleDimming(false)
        if wasAuto { auto = true }
    }

    /// Fire a Notification Center notification and blink at the same time.
    public func notify(title: String, body: String) {
        func esc(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\")
             .replacingOccurrences(of: "\"", with: "\\\"")
        }
        let script = "display notification \"\(esc(body))\" with title \"\(esc(title))\""
        var err: NSDictionary? = nil
        NSAppleScript(source: script)?.executeAndReturnError(&err)
        blink()
    }
}

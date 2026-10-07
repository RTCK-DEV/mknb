import SwiftUI
import ServiceManagement

final class BacklightModel: ObservableObject {
    let backlight: Backlight?
    @Published var brightness: Double = 0
    @Published var auto: Bool = false
    @Published var level: Double = 0
    @Published var suppressed = false
    @Published var saturated = false
    @Published var blinking = false

    init() {
        backlight = try? Backlight()
        refresh()
    }

    func refresh() {
        guard let b = backlight else { return }
        brightness = b.brightness
        auto = b.auto
        level = b.level
        suppressed = b.suppressed
        saturated = b.saturated
    }

    func setBrightness(_ v: Double) {
        backlight?.brightness = v
        brightness = v
    }

    func setAuto(_ on: Bool) {
        backlight?.auto = on
        auto = on
    }

    func blink() {
        guard !blinking else { return }
        blinking = true
        DispatchQueue.global().async { [weak self] in
            self?.backlight?.blink()
            DispatchQueue.main.async {
                self?.blinking = false
                self?.refresh()
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var model: BacklightModel
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MKNB")
                .font(.headline)

            if model.backlight == nil {
                Text("No backlit keyboard", comment: "shown when unsupported")
                    .foregroundColor(.secondary)
            } else {
                HStack {
                    Image(systemName: "light.min")
                    Slider(value: Binding(
                        get: { model.brightness },
                        set: { model.setBrightness($0) }), in: 0...1)
                    Image(systemName: "light.max")
                }

                HStack {
                    Text("Brightness")
                    Spacer()
                    Text("\(Int(model.brightness * 100))%")
                        .foregroundColor(.secondary)
                }
                .font(.caption)

                Toggle("Auto brightness", isOn: Binding(
                    get: { model.auto },
                    set: { model.setAuto($0) }))

                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { updateLoginItem($0) }))

                Divider()

                HStack {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(statusLine)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Button("Blink test") { model.blink() }
                        .disabled(model.blinking)
                    Spacer()
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                }
            }
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            model.refresh()
            syncLoginToggle()
        }
    }

    private var statusLine: String {
        var parts = [String(format: "%.1f nits", model.level)]
        if model.suppressed { parts.append(NSLocalizedString("suppressed", comment: "")) }
        if model.saturated  { parts.append(NSLocalizedString("saturated", comment: "")) }
        return parts.joined(separator: " · ")
    }

    /// Reflect the real BTM registration state in the toggle.
    private func syncLoginToggle() {
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }

    private func updateLoginItem(_ want: Bool) {
        do {
            if want {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            FileHandle.standardError.write("login item error: \(error)\n".data(using: .utf8)!)
        }
        syncLoginToggle()
        if want, SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}

@main
struct MKNBApp: App {
    @StateObject private var model = BacklightModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(model: model)
        } label: {
            Image(systemName: "keyboard")
        }
        .menuBarExtraStyle(.window)
    }
}

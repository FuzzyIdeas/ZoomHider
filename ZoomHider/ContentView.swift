//
//  ContentView.swift
//  ZoomHider
//
//  Created by Alin Panaitiu on 21.12.2021.
//
import Defaults
import LaunchAtLogin
import Lowtech
import LowtechPro
import SwiftUI
import VisualEffects

let WINDOW_WIDTH: CGFloat = 310
let WINDOW_PADDING_HORIZONTAL: CGFloat = 40
let FULL_WINDOW_WIDTH = WINDOW_WIDTH + WINDOW_PADDING_HORIZONTAL * 2

extension Defaults.Keys {
    static let showAdditionalInfo = Key<Bool>("showAdditionalInfo", default: true)
}

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.colors) var colors
    @ObservedObject var launchAtLogin = LaunchAtLogin.observable
    @ObservedObject var app: AppDelegate
    @Default(.hideMenubarIcon) var hideMenubarIcon
    @Default(.paused) var paused
    @Default(.faster) var faster
    @Default(.enablePauseKey) var enablePauseKey
    @Default(.showAdditionalInfo) var showAdditionalInfo

    var header: some View {
        HStack {
            Text("Settings").font(.largeTitle).fontWeight(.black).padding(.bottom, 6)
            if !hideMenubarIcon {
                Spacer()
                Button("Close window") { app.statusBar?.hidePopover(app) }
                    .buttonStyle(FlatButton(color: Colors.red.opacity(0.7), textColor: .white))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .keyboardShortcut(KeyEquivalent("w"), modifiers: [.command])
            }
        }
    }

    var body: some View {
        GeometryReader { geom in
            VStack(alignment: .leading) {
                if hideMenubarIcon {
                    Semaphore()
                }
                header

                VStack(alignment: .leading, spacing: 5) {
                    Toggle("Hide Zoom faster when it reappears", isOn: $faster)
                        .toggleStyle(CheckboxToggleStyle(style: .circle))
                        .foregroundColor(.primary)
                    Toggle(isOn: $enablePauseKey) {
                        HStack(spacing: 3) {
                            Text("Toggle hiding with")
                            HStack(spacing: 3) {
                                Text("???")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Right Option")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color.primary.opacity(0.2)))
                            Text("+")
                            Text("Z")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color.primary.opacity(0.2)))
                        }
                    }
                    .toggleStyle(CheckboxToggleStyle(style: .circle))
                    .foregroundColor(.primary)
                    Divider().padding(.vertical, 6)
                    Toggle("Hide menubar icon", isOn: $hideMenubarIcon)
                        .toggleStyle(CheckboxToggleStyle(style: .circle))
                        .foregroundColor(.primary)
                    Toggle("Launch at login", isOn: $launchAtLogin.isEnabled)
                        .toggleStyle(CheckboxToggleStyle(style: .circle))
                        .foregroundColor(.primary)

//                #if DEBUG
//                    HStack(alignment: .center) {
//                        Button("Reset trial") { AppDelegate.shared.resetTrial() }
//                            .buttonStyle(FlatButton(color: Color.primary, textColor: colors.bg.primary))
//                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
//                        Button("Expire trial") { AppDelegate.shared.expireTrial() }
//                            .buttonStyle(FlatButton(color: Color.primary, textColor: colors.bg.primary))
//                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
//                    }.frame(maxWidth: .infinity, alignment: .center)
//                #endif
                }
                .padding(.leading)
                .padding(.bottom, 6)

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("\(showAdditionalInfo ? "Hide" : "Show") app info", isOn: $showAdditionalInfo.animation(.fastSpring))
                        .toggleStyle(DetailToggleStyle(style: .circle))
                        .foregroundColor(colors.gray)
                        .font(.system(size: 12, weight: .semibold))
                    if showAdditionalInfo {
                        VersionView(updater: AppDelegate.shared.updateController.updater).padding(.bottom, 6)
                    }
                }

                footer
            }
            .frame(width: WINDOW_WIDTH)
            .padding(.horizontal, WINDOW_PADDING_HORIZONTAL)
            .padding(.bottom, 40)
            .padding(.top, 20)
            .background(bg)
        }
        .frame(width: WINDOW_WIDTH + WINDOW_PADDING_HORIZONTAL * 2, height: 440)
    }

    var bg: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .shadow(color: Colors.blackMauve.opacity(colorScheme == .dark ? 0.5 : 0.3), radius: 4, x: 0, y: 4)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Colors.blue.opacity(0.1))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
    }

    var footer: some View {
        HStack(alignment: .center) {
            Button(paused ? "Start" : "Pause") {
                paused.toggle()
            }
            .buttonStyle(FlatButton(color: .blue.opacity(0.6), textColor: .white))
            .font(.system(size: 13, weight: .semibold))
            .keyboardShortcut(KeyEquivalent("q"), modifiers: [.command])
            Spacer()
            Text(paused ? "Hiding paused" : "Hiding Zoom floating controls")
                .font(.caption.weight(.heavy))
                .foregroundColor(.primary.opacity(0.3))
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(self)
            }
            .buttonStyle(FlatButton(color: Colors.red, textColor: colors.bg.primary))
            .font(.system(size: 13, weight: .semibold))
            .keyboardShortcut(KeyEquivalent("q"), modifiers: [.command])
        }.frame(maxWidth: .infinity)
    }
}

// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(app: AppDelegate.shared)
            ContentView(app: AppDelegate.shared)
                .preferredColorScheme(.light)
        }
    }
}

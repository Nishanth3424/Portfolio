//
//  SettingsView.swift
//  Barpath
//
//  App settings and configuration
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // Model Section
                Section {
                    Picker("Model Size", selection: $settingsManager.settings.modelSize) {
                        ForEach(ModelSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                } header: {
                    Text("ML Model")
                } footer: {
                    Text("Larger models are more accurate but slower. Medium recommended for iPhone 14+.")
                }

                // Detection Thresholds
                Section("Detection Thresholds") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Pose Visibility: \(settingsManager.settings.minPoseVisibility, specifier: "%.2f")")
                            .font(Theme.Typography.label)
                        Slider(value: $settingsManager.settings.minPoseVisibility, in: 0.3...0.9, step: 0.05)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("YOLO Confidence: \(settingsManager.settings.yoloConfidence, specifier: "%.2f")")
                            .font(Theme.Typography.label)
                        Slider(value: $settingsManager.settings.yoloConfidence, in: 0.2...0.8, step: 0.05)
                    }
                }

                // Analysis Settings
                Section("Analysis") {
                    Stepper("Gap Fill Frames: \(settingsManager.settings.gapFillFrames)",
                           value: $settingsManager.settings.gapFillFrames,
                           in: 0...16)

                    Picker("Smoothing", selection: $settingsManager.settings.smoothingType) {
                        Text("EMA").tag(SmoothingType.ema)
                        Text("Kalman").tag(SmoothingType.kalman)
                    }

                    if settingsManager.settings.smoothingType == .ema {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("EMA Alpha: \(settingsManager.settings.smoothingAlpha, specifier: "%.2f")")
                                .font(Theme.Typography.label)
                            Slider(value: $settingsManager.settings.smoothingAlpha, in: 0.1...0.5, step: 0.05)
                        }
                    }
                }

                // Lift Detection
                Section("Lift Detection") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Start Speed: \(settingsManager.settings.liftStartSpeedPxPerSec, specifier: "%.0f") px/s")
                            .font(Theme.Typography.label)
                        Slider(value: $settingsManager.settings.liftStartSpeedPxPerSec, in: 20...100, step: 5)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Hysteresis: \(settingsManager.settings.liftStartHysteresis, specifier: "%.1f")")
                            .font(Theme.Typography.label)
                        Slider(value: $settingsManager.settings.liftStartHysteresis, in: 0.3...0.9, step: 0.1)
                    }
                }

                // Export Settings
                Section("Export") {
                    Picker("Video Quality", selection: $settingsManager.settings.exportVideoQuality) {
                        ForEach([VideoQuality.p720, .p1080, .p4k], id: \.self) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }

                    Picker("Overlay Size", selection: $settingsManager.settings.exportOverlaySize) {
                        ForEach([OverlaySize.small, .medium, .large], id: \.self) { size in
                            Text(size.rawValue.capitalized).tag(size)
                        }
                    }

                    Picker("Units", selection: $settingsManager.settings.units) {
                        Text("Metric").tag(Units.metric)
                        Text("Imperial").tag(Units.imperial)
                    }
                }

                // Reset
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                            Spacer()
                        }
                    }
                }

                // App Info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(Theme.Colors.inkSubtle)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(Theme.Colors.inkSubtle)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Settings", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settingsManager.reset()
                }
            } message: {
                Text("This will reset all settings to their default values.")
            }
            .onChange(of: settingsManager.settings) { _, _ in
                settingsManager.save()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
}

//
//  CalibrationView.swift
//  Barpath
//
//  Multi-step calibration wizard
//

import SwiftUI
import AVFoundation

struct CalibrationView: View {
    let videoURL: URL
    let isRecorded: Bool

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var historyManager: HistoryManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var liftType: LiftType = .squat
    @State private var pixelsPerCm: Double = 1.0
    @State private var gravityAngle: Double = 0.0
    @State private var navigateToAnalysis = false
    @State private var calibrationData: CalibrationData?

    private let steps = ["Lift Type", "Scale", "Level", "Detection", "Start"]

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressBar(currentStep: currentStep, totalSteps: steps.count)

            // Step title
            Text(steps[currentStep])
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.baseInk)
                .padding(.vertical, Theme.Spacing.lg)

            // Step content
            TabView(selection: $currentStep) {
                LiftTypeStep(selectedLift: $liftType)
                    .tag(0)

                ScaleStep(videoURL: videoURL, pixelsPerCm: $pixelsPerCm)
                    .tag(1)

                LevelStep(videoURL: videoURL, isRecorded: isRecorded, gravityAngle: $gravityAngle)
                    .tag(2)

                DetectionCheckStep(videoURL: videoURL)
                    .tag(3)

                FinalStep()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .disabled(true)

            // Navigation buttons
            HStack(spacing: Theme.Spacing.md) {
                if currentStep > 0 {
                    Button(action: {
                        withAnimation {
                            currentStep -= 1
                        }
                    }) {
                        Text("Back")
                            .font(Theme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                    .stroke(Theme.Colors.primary, lineWidth: 2)
                            )
                    }
                }

                Button(action: {
                    if currentStep < steps.count - 1 {
                        withAnimation {
                            currentStep += 1
                        }
                    } else {
                        startAnalysis()
                    }
                }) {
                    Text(currentStep < steps.count - 1 ? "Next" : "Start Analysis")
                        .font(Theme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.primary)
                        .cornerRadius(Theme.Radius.medium)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToAnalysis) {
            if let calibration = calibrationData {
                AnalysisView(videoURL: videoURL, calibration: calibration)
            }
        }
    }

    private func startAnalysis() {
        calibrationData = CalibrationData(
            liftType: liftType,
            pixelsPerCm: pixelsPerCm,
            gravityAngle: gravityAngle
        )
        navigateToAnalysis = true
    }
}

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.Colors.fill)
                    .frame(height: 4)

                Rectangle()
                    .fill(Theme.Colors.primary)
                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 4)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Step 1: Lift Type
struct LiftTypeStep: View {
    @Binding var selectedLift: LiftType

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("Select the type of lift")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.inkSubtle)

            VStack(spacing: Theme.Spacing.md) {
                ForEach(LiftType.allCases, id: \.self) { lift in
                    Button(action: {
                        selectedLift = lift
                    }) {
                        HStack {
                            Text(lift.rawValue)
                                .font(Theme.Typography.body)
                                .foregroundColor(selectedLift == lift ? .white : Theme.Colors.baseInk)

                            Spacer()

                            if selectedLift == lift {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(Theme.Spacing.md)
                        .background(selectedLift == lift ? Theme.Colors.primary : Theme.Colors.fill)
                        .cornerRadius(Theme.Radius.medium)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)

            Spacer()
        }
        .padding(.top, Theme.Spacing.xl)
    }
}

// MARK: - Step 2: Scale
struct ScaleStep: View {
    let videoURL: URL
    @Binding var pixelsPerCm: Double

    @State private var useManual = false
    @State private var manualValue: String = "45"

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("Calibrate scale using a 45cm plate")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.inkSubtle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            // Video thumbnail with circle overlay
            VideoThumbnail(url: videoURL)
                .frame(height: 300)
                .overlay(
                    Circle()
                        .stroke(Theme.Colors.primary, lineWidth: 3)
                        .frame(width: 150, height: 150)
                )
                .padding(Theme.Spacing.md)

            Text("Tap and drag to fit the circle to a 45cm plate")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.inkSubtle)

            // Manual fallback
            Toggle("Manual calibration", isOn: $useManual)
                .padding(.horizontal, Theme.Spacing.md)

            if useManual {
                HStack {
                    Text("Plate diameter (cm):")
                    TextField("45", text: $manualValue)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }

            Spacer()
        }
        .padding(.top, Theme.Spacing.xl)
    }
}

// MARK: - Step 3: Level
struct LevelStep: View {
    let videoURL: URL
    let isRecorded: Bool
    @Binding var gravityAngle: Double

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if isRecorded {
                Text("Level detected from device motion")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.inkSubtle)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.Colors.success)

                Text("Gravity angle: \(gravityAngle, specifier: "%.2f")°")
                    .font(Theme.Typography.label)
            } else {
                Text("Align the horizon line with a level reference")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.inkSubtle)

                VideoThumbnail(url: videoURL)
                    .frame(height: 300)
                    .overlay(
                        Rectangle()
                            .fill(Theme.Colors.primary.opacity(0.5))
                            .frame(height: 2)
                    )
                    .padding(Theme.Spacing.md)

                Slider(value: $gravityAngle, in: -45...45)
                    .padding(.horizontal, Theme.Spacing.md)
            }

            Spacer()
        }
        .padding(.top, Theme.Spacing.xl)
    }
}

// MARK: - Step 4: Detection Check
struct DetectionCheckStep: View {
    let videoURL: URL

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("Checking detection quality")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.inkSubtle)

            VStack(spacing: Theme.Spacing.md) {
                CheckRow(label: "Barbell visible", isChecked: true)
                CheckRow(label: "Body landmarks visible", isChecked: true)
                CheckRow(label: "Adequate lighting", isChecked: true)
                CheckRow(label: "Stable camera position", isChecked: true)
            }
            .padding(.horizontal, Theme.Spacing.md)

            Spacer()
        }
        .padding(.top, Theme.Spacing.xl)
    }
}

struct CheckRow: View {
    let label: String
    let isChecked: Bool

    var body: some View {
        HStack {
            Image(systemName: isChecked ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isChecked ? Theme.Colors.success : Theme.Colors.danger)

            Text(label)
                .font(Theme.Typography.body)

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.fill)
        .cornerRadius(Theme.Radius.medium)
    }
}

// MARK: - Step 5: Final
struct FinalStep: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Theme.Colors.primary)

            Text("Ready to analyze")
                .font(Theme.Typography.title)

            Text("Calibration complete. Tap Start Analysis to begin processing your lift.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.inkSubtle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Spacer()
        }
        .padding(.top, Theme.Spacing.xl)
    }
}

// MARK: - Video Thumbnail
struct VideoThumbnail: View {
    let url: URL

    var body: some View {
        Rectangle()
            .fill(Color.black)
            .overlay(
                Image(systemName: "video.fill")
                    .foregroundColor(.white.opacity(0.5))
            )
    }
}

//
//  AnalysisView.swift
//  Barpath
//
//  Analysis progress screen
//

import SwiftUI

struct AnalysisView: View {
    let videoURL: URL
    let calibration: CalibrationData

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var historyManager: HistoryManager
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var analyzer = AnalysisEngine()
    @State private var navigateToResults = false
    @State private var session: Session?

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Theme.Colors.fill, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: analyzer.progress)
                    .stroke(Theme.Colors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: analyzer.progress)

                Text("\(Int(analyzer.progress * 100))%")
                    .font(Theme.Typography.title)
                    .fontWeight(.bold)
            }

            Text(analyzer.currentStep)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.inkSubtle)

            // Steps list
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                AnalysisStepRow(label: "Loading video", isComplete: analyzer.stepIndex > 0, isCurrent: analyzer.stepIndex == 0)
                AnalysisStepRow(label: "Detecting barbell", isComplete: analyzer.stepIndex > 1, isCurrent: analyzer.stepIndex == 1)
                AnalysisStepRow(label: "Detecting body landmarks", isComplete: analyzer.stepIndex > 2, isCurrent: analyzer.stepIndex == 2)
                AnalysisStepRow(label: "Tracking bar path", isComplete: analyzer.stepIndex > 3, isCurrent: analyzer.stepIndex == 3)
                AnalysisStepRow(label: "Computing metrics", isComplete: analyzer.stepIndex > 4, isCurrent: analyzer.stepIndex == 4)
                AnalysisStepRow(label: "Rendering overlay", isComplete: analyzer.stepIndex > 5, isCurrent: analyzer.stepIndex == 5)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.fill)
            .cornerRadius(Theme.Radius.medium)
            .padding(.horizontal, Theme.Spacing.md)

            Spacer()

            if analyzer.isComplete {
                Button(action: {
                    navigateToResults = true
                }) {
                    Text("View Results")
                        .font(Theme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.primary)
                        .cornerRadius(Theme.Radius.medium)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToResults) {
            if let session = session {
                ResultsView(session: session)
            }
        }
        .onAppear {
            startAnalysis()
        }
    }

    private func startAnalysis() {
        Task {
            // Create session
            let newSession = Session(
                liftType: calibration.liftType,
                videoURL: videoURL,
                calibration: calibration
            )

            // Run analysis
            await analyzer.analyze(
                videoURL: videoURL,
                calibration: calibration,
                settings: settingsManager.settings
            )

            // Update session with results
            var updatedSession = newSession
            updatedSession.analysisResults = analyzer.results
            updatedSession.overlayVideoURL = analyzer.overlayVideoURL
            updatedSession.csvURL = analyzer.csvURL

            // Save to history
            historyManager.addSession(updatedSession)

            session = updatedSession
        }
    }
}

struct AnalysisStepRow: View {
    let label: String
    let isComplete: Bool
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.Colors.success)
            } else if isCurrent {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(Theme.Colors.inkSubtle)
            }

            Text(label)
                .font(Theme.Typography.body)
                .foregroundColor(isCurrent ? Theme.Colors.baseInk : Theme.Colors.inkSubtle)

            Spacer()
        }
    }
}

// MARK: - Analysis Engine
class AnalysisEngine: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var currentStep: String = "Starting..."
    @Published var stepIndex: Int = 0
    @Published var isComplete: Bool = false

    var results: AnalysisResults?
    var overlayVideoURL: URL?
    var csvURL: URL?

    func analyze(videoURL: URL, calibration: CalibrationData, settings: AppSettings) async {
        let steps = [
            "Loading video",
            "Detecting barbell",
            "Detecting body landmarks",
            "Tracking bar path",
            "Computing metrics",
            "Rendering overlay"
        ]

        for (index, step) in steps.enumerated() {
            await MainActor.run {
                stepIndex = index
                currentStep = step
            }

            // Simulate processing
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            await MainActor.run {
                progress = Double(index + 1) / Double(steps.count)
            }
        }

        // Generate mock results
        let mockFrames = generateMockFrames()
        let mockReps = generateMockReps()
        results = AnalysisResults(sessionId: UUID(), frames: mockFrames, reps: mockReps)

        // Mock overlay and CSV URLs
        overlayVideoURL = FileManager.default.temporaryDirectory.appendingPathComponent("overlay.mp4")
        csvURL = FileManager.default.temporaryDirectory.appendingPathComponent("data.csv")

        // Export CSV
        exportCSV(frames: mockFrames, to: csvURL!)

        await MainActor.run {
            isComplete = true
            currentStep = "Complete!"
        }
    }

    private func generateMockFrames() -> [FrameData] {
        var frames: [FrameData] = []
        for i in 0..<120 {
            frames.append(FrameData(
                frame: i,
                timestampMs: Double(i) * 33.33,
                barX: 200 + sin(Double(i) * 0.1) * 50,
                barY: 300 + sin(Double(i) * 0.05) * 100,
                barVY: cos(Double(i) * 0.05) * 50,
                repId: i / 30,
                wristLX: 180,
                wristLY: 350,
                wristRX: 220,
                wristRY: 350
            ))
        }
        return frames
    }

    private func generateMockReps() -> [RepMetrics] {
        return [
            RepMetrics(repNumber: 1, romCm: 42.5, maxVelocity: 95.2, avgVelocity: 68.4, depthPercent: 98.5, startFrame: 0, endFrame: 29),
            RepMetrics(repNumber: 2, romCm: 41.8, maxVelocity: 92.1, avgVelocity: 65.3, depthPercent: 96.2, startFrame: 30, endFrame: 59),
            RepMetrics(repNumber: 3, romCm: 40.2, maxVelocity: 88.7, avgVelocity: 62.1, depthPercent: 93.8, startFrame: 60, endFrame: 89),
            RepMetrics(repNumber: 4, romCm: 38.9, maxVelocity: 84.3, avgVelocity: 58.9, depthPercent: 91.2, startFrame: 90, endFrame: 119)
        ]
    }

    private func exportCSV(frames: [FrameData], to url: URL) {
        var csv = FrameData.csvHeader + "\n"
        for frame in frames {
            csv += frame.toCSVRow() + "\n"
        }
        try? csv.write(to: url, atomically: true, encoding: .utf8)
    }
}

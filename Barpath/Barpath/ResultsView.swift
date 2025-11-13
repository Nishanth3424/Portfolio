//
//  ResultsView.swift
//  Barpath
//
//  Results screen with video overlay, charts, and metrics
//

import SwiftUI
import Charts
import AVKit

struct ResultsView: View {
    let session: Session

    @State private var selectedTab = 0
    @State private var selectedRep: Int?
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Video player
                if let overlayURL = session.overlayVideoURL {
                    VideoPlayer(player: AVPlayer(url: overlayURL))
                        .frame(height: 250)
                        .cornerRadius(Theme.Radius.medium)
                        .padding(.horizontal, Theme.Spacing.md)
                } else {
                    VideoPlayer(player: AVPlayer(url: session.videoURL))
                        .frame(height: 250)
                        .cornerRadius(Theme.Radius.medium)
                        .padding(.horizontal, Theme.Spacing.md)
                }

                // Summary metrics
                if let results = session.analysisResults {
                    VStack(spacing: Theme.Spacing.md) {
                        Text("Summary")
                            .font(Theme.Typography.title)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: Theme.Spacing.md) {
                            SummaryCard(
                                icon: "number",
                                label: "Total Reps",
                                value: "\(results.totalReps)"
                            )

                            SummaryCard(
                                icon: "arrow.up.and.down",
                                label: "Avg ROM",
                                value: String(format: "%.1f cm", results.avgRomCm)
                            )
                        }

                        HStack(spacing: Theme.Spacing.md) {
                            SummaryCard(
                                icon: "speedometer",
                                label: "Avg Max Velocity",
                                value: String(format: "%.2f m/s", results.avgMaxVelocity / 100)
                            )

                            if let bestIndex = results.bestRepIndex {
                                SummaryCard(
                                    icon: "star.fill",
                                    label: "Best Rep",
                                    value: "#\(bestIndex + 1)"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    // Charts section
                    VStack(spacing: Theme.Spacing.md) {
                        Text("Charts")
                            .font(Theme.Typography.title)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Chart tabs
                        Picker("Chart Type", selection: $selectedTab) {
                            Text("Path").tag(0)
                            Text("Displacement").tag(1)
                            Text("Velocity").tag(2)
                        }
                        .pickerStyle(.segmented)

                        // Chart content
                        Group {
                            switch selectedTab {
                            case 0:
                                BarPathChart(frames: results.frames)
                            case 1:
                                DisplacementChart(frames: results.frames)
                            case 2:
                                VelocityChart(frames: results.frames)
                            default:
                                EmptyView()
                            }
                        }
                        .frame(height: 250)
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    // Rep details
                    VStack(spacing: Theme.Spacing.md) {
                        Text("Rep Details")
                            .font(Theme.Typography.title)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(results.reps) { rep in
                            RepDetailCard(rep: rep, isBest: results.bestRepIndex == rep.repNumber - 1)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    // Export buttons
                    VStack(spacing: Theme.Spacing.md) {
                        Button(action: {
                            shareVideo()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Overlay Video")
                            }
                            .font(Theme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Theme.Colors.primary)
                            .cornerRadius(Theme.Radius.medium)
                        }

                        Button(action: {
                            shareCSV()
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Export CSV Data")
                            }
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
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .padding(.top, Theme.Spacing.md)
        }
        .navigationTitle(session.liftType.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func shareVideo() {
        guard let url = session.overlayVideoURL else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func shareCSV() {
        guard let url = session.csvURL else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Theme.Colors.primary)

            Text(value)
                .font(Theme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.baseInk)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.inkSubtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.fill)
        .cornerRadius(Theme.Radius.medium)
    }
}

struct RepDetailCard: View {
    let rep: RepMetrics
    let isBest: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Rep \(rep.repNumber)")
                    .font(Theme.Typography.body)
                    .fontWeight(.semibold)

                if isBest {
                    Image(systemName: "star.fill")
                        .foregroundColor(Theme.Colors.warning)
                        .font(.system(size: 12))
                }

                Spacer()

                Text("Frames \(rep.startFrame)-\(rep.endFrame)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.inkSubtle)
            }

            HStack(spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ROM")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.inkSubtle)
                    Text(String(format: "%.1f cm", rep.romCm))
                        .font(Theme.Typography.label)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Max Vel")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.inkSubtle)
                    Text(String(format: "%.1f cm/s", rep.maxVelocity))
                        .font(Theme.Typography.label)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Vel")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.inkSubtle)
                    Text(String(format: "%.1f cm/s", rep.avgVelocity))
                        .font(Theme.Typography.label)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Depth")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.inkSubtle)
                    Text(String(format: "%.1f%%", rep.depthPercent))
                        .font(Theme.Typography.label)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(isBest ? Theme.Colors.warning.opacity(0.1) : Theme.Colors.fill)
        .cornerRadius(Theme.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(isBest ? Theme.Colors.warning : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Charts

struct BarPathChart: View {
    let frames: [FrameData]

    var body: some View {
        Chart {
            ForEach(frames, id: \.frame) { frame in
                if let x = frame.barX, let y = frame.barY {
                    PointMark(
                        x: .value("X", x),
                        y: .value("Y", -y) // Invert Y for visual consistency
                    )
                    .foregroundStyle(Theme.Colors.primary.opacity(0.6))
                    .symbolSize(20)
                }
            }
        }
        .chartXAxisLabel("Horizontal Position (px)")
        .chartYAxisLabel("Vertical Position (px)")
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.fill)
        .cornerRadius(Theme.Radius.medium)
    }
}

struct DisplacementChart: View {
    let frames: [FrameData]

    var body: some View {
        Chart {
            ForEach(frames, id: \.frame) { frame in
                if let y = frame.barY {
                    LineMark(
                        x: .value("Frame", frame.frame),
                        y: .value("Y Position", y)
                    )
                    .foregroundStyle(Theme.Colors.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
        }
        .chartXAxisLabel("Frame")
        .chartYAxisLabel("Vertical Position (px)")
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.fill)
        .cornerRadius(Theme.Radius.medium)
    }
}

struct VelocityChart: View {
    let frames: [FrameData]

    var body: some View {
        Chart {
            ForEach(frames, id: \.frame) { frame in
                if let vy = frame.barVY {
                    AreaMark(
                        x: .value("Frame", frame.frame),
                        y: .value("Velocity", vy)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.primary.opacity(0.5), Theme.Colors.primary.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Frame", frame.frame),
                        y: .value("Velocity", vy)
                    )
                    .foregroundStyle(Theme.Colors.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
        }
        .chartXAxisLabel("Frame")
        .chartYAxisLabel("Vertical Velocity (cm/s)")
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.fill)
        .cornerRadius(Theme.Radius.medium)
    }
}

#Preview {
    NavigationStack {
        ResultsView(session: Session(
            liftType: .squat,
            videoURL: URL(fileURLWithPath: "/tmp/test.mp4"),
            calibration: CalibrationData()
        ))
    }
}

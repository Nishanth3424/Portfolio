//
//  Models.swift
//  Barpath
//
//  Core data models
//

import Foundation
import AVFoundation
import CoreGraphics

// MARK: - Lift Type
enum LiftType: String, Codable, CaseIterable {
    case squat = "Squat"
    case bench = "Bench Press"
    case deadlift = "Deadlift"

    var id: String { rawValue }
}

// MARK: - Model Size
enum ModelSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Video Source
enum VideoSource {
    case imported(URL)
    case recorded(URL)
}

// MARK: - Calibration Data
struct CalibrationData: Codable {
    var liftType: LiftType
    var pixelsPerCm: Double // Scale calibration
    var gravityAngle: Double // Level/gravity calibration in radians
    var plateRadius: CGPoint? // Center of calibrated plate

    init(liftType: LiftType = .squat, pixelsPerCm: Double = 1.0, gravityAngle: Double = 0.0) {
        self.liftType = liftType
        self.pixelsPerCm = pixelsPerCm
        self.gravityAngle = gravityAngle
    }
}

// MARK: - Frame Data
struct FrameData: Codable {
    let frame: Int
    let timestampMs: Double
    var barX: Double?
    var barY: Double?
    var barVY: Double?
    var repId: Int?
    var wristLX: Double?
    var wristLY: Double?
    var wristRX: Double?
    var wristRY: Double?

    // CSV header
    static let csvHeader = "frame,timestamp_ms,bar_x,bar_y,bar_vy,rep_id,wrist_l_x,wrist_l_y,wrist_r_x,wrist_r_y"

    // Convert to CSV row
    func toCSVRow() -> String {
        let fields = [
            "\(frame)",
            String(format: "%.2f", timestampMs),
            barX.map { String(format: "%.2f", $0) } ?? "",
            barY.map { String(format: "%.2f", $0) } ?? "",
            barVY.map { String(format: "%.2f", $0) } ?? "",
            repId.map { "\($0)" } ?? "",
            wristLX.map { String(format: "%.2f", $0) } ?? "",
            wristLY.map { String(format: "%.2f", $0) } ?? "",
            wristRX.map { String(format: "%.2f", $0) } ?? "",
            wristRY.map { String(format: "%.2f", $0) } ?? ""
        ]
        return fields.joined(separator: ",")
    }
}

// MARK: - Rep Metrics
struct RepMetrics: Codable, Identifiable {
    let id: UUID
    let repNumber: Int
    let romCm: Double // Range of motion
    let maxVelocity: Double
    let avgVelocity: Double
    let depthPercent: Double
    let startFrame: Int
    let endFrame: Int

    init(id: UUID = UUID(), repNumber: Int, romCm: Double, maxVelocity: Double,
         avgVelocity: Double, depthPercent: Double, startFrame: Int, endFrame: Int) {
        self.id = id
        self.repNumber = repNumber
        self.romCm = romCm
        self.maxVelocity = maxVelocity
        self.avgVelocity = avgVelocity
        self.depthPercent = depthPercent
        self.startFrame = startFrame
        self.endFrame = endFrame
    }
}

// MARK: - Analysis Results
struct AnalysisResults: Codable {
    let sessionId: UUID
    let frames: [FrameData]
    let reps: [RepMetrics]
    let totalReps: Int
    let bestRepIndex: Int?
    let avgRomCm: Double
    let avgMaxVelocity: Double

    init(sessionId: UUID, frames: [FrameData], reps: [RepMetrics]) {
        self.sessionId = sessionId
        self.frames = frames
        self.reps = reps
        self.totalReps = reps.count

        // Find best rep (highest avg velocity)
        if let bestIndex = reps.enumerated().max(by: { $0.element.avgVelocity < $1.element.avgVelocity })?.offset {
            self.bestRepIndex = bestIndex
        } else {
            self.bestRepIndex = nil
        }

        // Calculate averages
        self.avgRomCm = reps.isEmpty ? 0 : reps.map { $0.romCm }.reduce(0, +) / Double(reps.count)
        self.avgMaxVelocity = reps.isEmpty ? 0 : reps.map { $0.maxVelocity }.reduce(0, +) / Double(reps.count)
    }
}

// MARK: - Session
struct Session: Codable, Identifiable {
    let id: UUID
    let date: Date
    let liftType: LiftType
    let videoURL: URL
    let calibration: CalibrationData
    var analysisResults: AnalysisResults?
    var overlayVideoURL: URL?
    var csvURL: URL?

    init(id: UUID = UUID(), date: Date = Date(), liftType: LiftType,
         videoURL: URL, calibration: CalibrationData) {
        self.id = id
        self.date = date
        self.liftType = liftType
        self.videoURL = videoURL
        self.calibration = calibration
    }
}

// MARK: - App Settings
struct AppSettings: Codable {
    var modelSize: ModelSize
    var minPoseVisibility: Double
    var yoloConfidence: Double
    var gapFillFrames: Int
    var smoothingType: SmoothingType
    var smoothingAlpha: Double
    var liftStartSpeedPxPerSec: Double
    var liftStartHysteresis: Double
    var units: Units
    var exportVideoQuality: VideoQuality
    var exportOverlaySize: OverlaySize

    static let `default` = AppSettings(
        modelSize: .medium,
        minPoseVisibility: 0.50,
        yoloConfidence: 0.35,
        gapFillFrames: 8,
        smoothingType: .ema,
        smoothingAlpha: 0.25,
        liftStartSpeedPxPerSec: 50.0,
        liftStartHysteresis: 0.6,
        units: .metric,
        exportVideoQuality: .p1080,
        exportOverlaySize: .small
    )
}

enum SmoothingType: String, Codable {
    case ema = "ema"
    case kalman = "kalman"
}

enum Units: String, Codable {
    case metric = "metric"
    case imperial = "imperial"
}

enum VideoQuality: String, Codable {
    case p720 = "720p"
    case p1080 = "1080p"
    case p4k = "4K"
}

enum OverlaySize: String, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var currentSession: Session?
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Double = 0.0
    @Published var analysisStep: String = ""
}

//
//  AnalysisService.swift
//  Barpath
//
//  Core analysis algorithms: smoothing, gap-fill, lift detection, tracking
//

import Foundation
import CoreGraphics

// MARK: - Analysis Service
class AnalysisService {
    let settings: AppSettings
    let calibration: CalibrationData

    init(settings: AppSettings, calibration: CalibrationData) {
        self.settings = settings
        self.calibration = calibration
    }

    // MARK: - Smoothing
    func smoothPath(_ points: [CGPoint?]) -> [CGPoint?] {
        switch settings.smoothingType {
        case .ema:
            return applyEMA(points, alpha: settings.smoothingAlpha)
        case .kalman:
            return applyKalmanFilter(points)
        }
    }

    private func applyEMA(_ points: [CGPoint?], alpha: Double) -> [CGPoint?] {
        var smoothed: [CGPoint?] = []
        var previous: CGPoint?

        for point in points {
            guard let current = point else {
                smoothed.append(nil)
                continue
            }

            if let prev = previous {
                let smoothX = alpha * current.x + (1 - alpha) * prev.x
                let smoothY = alpha * current.y + (1 - alpha) * prev.y
                let smoothPoint = CGPoint(x: smoothX, y: smoothY)
                smoothed.append(smoothPoint)
                previous = smoothPoint
            } else {
                smoothed.append(current)
                previous = current
            }
        }

        return smoothed
    }

    private func applyKalmanFilter(_ points: [CGPoint?]) -> [CGPoint?] {
        // Simplified 1D Kalman filter for each axis
        var smoothed: [CGPoint?] = []
        var estimateX: Double = 0
        var estimateY: Double = 0
        var errorX: Double = 1.0
        var errorY: Double = 1.0

        let processNoise = 0.01
        let measurementNoise = 0.1

        for point in points {
            guard let current = point else {
                smoothed.append(nil)
                continue
            }

            // Predict
            let predictErrorX = errorX + processNoise
            let predictErrorY = errorY + processNoise

            // Update X
            let gainX = predictErrorX / (predictErrorX + measurementNoise)
            estimateX = estimateX + gainX * (current.x - estimateX)
            errorX = (1 - gainX) * predictErrorX

            // Update Y
            let gainY = predictErrorY / (predictErrorY + measurementNoise)
            estimateY = estimateY + gainY * (current.y - estimateY)
            errorY = (1 - gainY) * predictErrorY

            smoothed.append(CGPoint(x: estimateX, y: estimateY))
        }

        return smoothed
    }

    // MARK: - Gap Filling
    func fillGaps(_ points: [CGPoint?], maxGap: Int) -> [CGPoint?] {
        var filled = points
        var gapStart: Int?

        for i in 0..<filled.count {
            if filled[i] == nil {
                if gapStart == nil {
                    gapStart = i
                }
            } else {
                if let start = gapStart {
                    let gapLength = i - start
                    if gapLength <= maxGap, start > 0 {
                        // Linear interpolation
                        let startPoint = filled[start - 1]!
                        let endPoint = filled[i]!

                        for j in start..<i {
                            let t = Double(j - start + 1) / Double(gapLength + 1)
                            let interpolated = CGPoint(
                                x: startPoint.x + (endPoint.x - startPoint.x) * t,
                                y: startPoint.y + (endPoint.y - startPoint.y) * t
                            )
                            filled[j] = interpolated
                        }
                    }
                    gapStart = nil
                }
            }
        }

        return filled
    }

    // MARK: - Velocity Calculation
    func calculateVelocities(_ points: [CGPoint?], fps: Double) -> [Double?] {
        var velocities: [Double?] = [nil] // First frame has no velocity

        for i in 1..<points.count {
            guard let current = points[i], let previous = points[i - 1] else {
                velocities.append(nil)
                continue
            }

            // Calculate vertical velocity (cm/s)
            let deltaY = (current.y - previous.y) * calibration.pixelsPerCm
            let deltaT = 1.0 / fps
            let velocity = deltaY / deltaT

            velocities.append(velocity)
        }

        return velocities
    }

    // MARK: - Lift Window Detection
    func detectLiftWindows(velocities: [Double?], fps: Double) -> [(start: Int, end: Int)] {
        var windows: [(Int, Int)] = []
        var inLift = false
        var liftStart: Int?

        let threshold = settings.liftStartSpeedPxPerSec
        let hysteresis = settings.liftStartHysteresis
        let minFrames = Int(fps * 0.5) // Minimum 0.5 seconds

        for i in 0..<velocities.count {
            guard let velocity = velocities[i] else { continue }

            let absVelocity = abs(velocity)

            if !inLift && absVelocity > threshold {
                // Start of lift
                inLift = true
                liftStart = i
            } else if inLift && absVelocity < threshold * hysteresis {
                // End of lift (with hysteresis)
                if let start = liftStart, i - start >= minFrames {
                    windows.append((start, i))
                }
                inLift = false
                liftStart = nil
            }
        }

        // Handle case where lift continues to end of video
        if let start = liftStart {
            windows.append((start, velocities.count - 1))
        }

        return windows
    }

    // MARK: - Rep Detection
    func detectReps(points: [CGPoint?], velocities: [Double?], fps: Double) -> [RepMetrics] {
        var reps: [RepMetrics] = []
        let windows = detectLiftWindows(velocities: velocities, fps: fps)

        for (windowIndex, window) in windows.enumerated() {
            let windowPoints = Array(points[window.start...window.end])
            let windowVelocities = Array(velocities[window.start...window.end])

            // Find min and max Y positions (for ROM calculation)
            let validPoints = windowPoints.compactMap { $0 }
            guard !validPoints.isEmpty else { continue }

            let minY = validPoints.map { $0.y }.min()!
            let maxY = validPoints.map { $0.y }.max()!
            let romPx = abs(maxY - minY)
            let romCm = romPx * calibration.pixelsPerCm

            // Calculate velocity metrics
            let validVelocities = windowVelocities.compactMap { $0 }
            guard !validVelocities.isEmpty else { continue }

            let maxVelocity = validVelocities.map { abs($0) }.max()!
            let avgVelocity = validVelocities.map { abs($0) }.reduce(0, +) / Double(validVelocities.count)

            // Depth percentage (for squats, assume starting position is reference)
            let depthPercent = min(100.0, (romCm / 40.0) * 100) // Assuming ~40cm is full depth

            let rep = RepMetrics(
                repNumber: windowIndex + 1,
                romCm: romCm,
                maxVelocity: maxVelocity,
                avgVelocity: avgVelocity,
                depthPercent: depthPercent,
                startFrame: window.start,
                endFrame: window.end
            )
            reps.append(rep)
        }

        return reps
    }

    // MARK: - Multi-Bar Disambiguation
    func selectBestTrack(detections: [[BarbellDetection]], wristMidpoints: [CGPoint?]) -> [CGPoint?] {
        var selectedPoints: [CGPoint?] = []
        var previousPoint: CGPoint?

        for (frameIndex, frameDetections) in detections.enumerated() {
            guard !frameDetections.isEmpty else {
                selectedPoints.append(nil)
                continue
            }

            let wristMidpoint = wristMidpoints[frameIndex]

            // Score each detection based on:
            // 1. Distance to wrist midpoint
            // 2. Continuity with previous point
            // 3. Confidence
            var bestDetection: BarbellDetection?
            var bestScore: Double = -Double.infinity

            for detection in frameDetections {
                var score = Double(detection.confidence)

                // Prefer detections closer to wrists
                if let wrist = wristMidpoint {
                    let distance = hypot(detection.center.x - wrist.x, detection.center.y - wrist.y)
                    score -= distance * 2.0
                }

                // Prefer continuity
                if let prev = previousPoint {
                    let distance = hypot(detection.center.x - prev.x, detection.center.y - prev.y)
                    score -= distance * 3.0
                }

                if score > bestScore {
                    bestScore = score
                    bestDetection = detection
                }
            }

            if let best = bestDetection {
                let point = best.center
                selectedPoints.append(point)
                previousPoint = point
            } else {
                selectedPoints.append(nil)
            }
        }

        return selectedPoints
    }

    // MARK: - Complete Analysis Pipeline
    func analyzeVideo(
        rawBarDetections: [[BarbellDetection]],
        poseLandmarks: [PoseLandmarks?],
        fps: Double
    ) -> AnalysisResults {
        // 1. Extract wrist midpoints
        let wristMidpoints = poseLandmarks.map { $0?.wristMidpoint }

        // 2. Select best track (disambiguate)
        let rawPath = selectBestTrack(detections: rawBarDetections, wristMidpoints: wristMidpoints)

        // 3. Fill gaps
        let gapFilled = fillGaps(rawPath, maxGap: settings.gapFillFrames)

        // 4. Smooth
        let smoothed = smoothPath(gapFilled)

        // 5. Calculate velocities
        let velocities = calculateVelocities(smoothed, fps: fps)

        // 6. Detect reps
        let reps = detectReps(points: smoothed, velocities: velocities, fps: fps)

        // 7. Build frame data
        var frames: [FrameData] = []
        for (i, point) in smoothed.enumerated() {
            let timestamp = Double(i) * (1000.0 / fps)
            let repId = reps.first(where: { $0.startFrame <= i && $0.endFrame >= i })?.repNumber

            frames.append(FrameData(
                frame: i,
                timestampMs: timestamp,
                barX: point?.x,
                barY: point?.y,
                barVY: velocities.indices.contains(i) ? velocities[i] : nil,
                repId: repId,
                wristLX: poseLandmarks.indices.contains(i) ? poseLandmarks[i]?.leftWrist.x : nil,
                wristLY: poseLandmarks.indices.contains(i) ? poseLandmarks[i]?.leftWrist.y : nil,
                wristRX: poseLandmarks.indices.contains(i) ? poseLandmarks[i]?.rightWrist.x : nil,
                wristRY: poseLandmarks.indices.contains(i) ? poseLandmarks[i]?.rightWrist.y : nil
            ))
        }

        return AnalysisResults(sessionId: UUID(), frames: frames, reps: reps)
    }
}

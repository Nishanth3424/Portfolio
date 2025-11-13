//
//  AnalysisServiceTests.swift
//  BarpathTests
//
//  Unit tests for analysis algorithms
//

import XCTest
@testable import Barpath

class AnalysisServiceTests: XCTestCase {
    var service: AnalysisService!

    override func setUp() {
        super.setUp()
        let settings = AppSettings.default
        let calibration = CalibrationData(liftType: .squat, pixelsPerCm: 2.0, gravityAngle: 0.0)
        service = AnalysisService(settings: settings, calibration: calibration)
    }

    // MARK: - Smoothing Tests
    func testEMASmoothing() {
        let points: [CGPoint?] = [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 105, y: 102),
            CGPoint(x: 110, y: 104),
            CGPoint(x: 115, y: 106)
        ]

        let smoothed = service.smoothPath(points)

        XCTAssertEqual(smoothed.count, points.count)
        XCTAssertNotNil(smoothed[0])
        XCTAssertNotNil(smoothed[1])

        // First point should remain unchanged
        XCTAssertEqual(smoothed[0]?.x, 100.0, accuracy: 0.1)

        // Subsequent points should be smoothed
        XCTAssertNotEqual(smoothed[1]?.x, points[1]?.x)
    }

    func testSmoothingWithNilValues() {
        let points: [CGPoint?] = [
            CGPoint(x: 100, y: 100),
            nil,
            CGPoint(x: 110, y: 104),
            CGPoint(x: 115, y: 106)
        ]

        let smoothed = service.smoothPath(points)

        XCTAssertEqual(smoothed.count, points.count)
        XCTAssertNotNil(smoothed[0])
        XCTAssertNil(smoothed[1])
        XCTAssertNotNil(smoothed[2])
    }

    // MARK: - Gap Filling Tests
    func testGapFilling() {
        let points: [CGPoint?] = [
            CGPoint(x: 100, y: 100),
            nil,
            nil,
            CGPoint(x: 110, y: 110)
        ]

        let filled = service.fillGaps(points, maxGap: 3)

        XCTAssertNotNil(filled[0])
        XCTAssertNotNil(filled[1])
        XCTAssertNotNil(filled[2])
        XCTAssertNotNil(filled[3])

        // Check interpolation
        XCTAssertEqual(filled[1]?.x, 102.5, accuracy: 1.0)
        XCTAssertEqual(filled[2]?.x, 106.67, accuracy: 1.0)
    }

    func testGapFillingExceedsMaxGap() {
        let points: [CGPoint?] = [
            CGPoint(x: 100, y: 100),
            nil,
            nil,
            nil,
            nil,
            CGPoint(x: 110, y: 110)
        ]

        let filled = service.fillGaps(points, maxGap: 2)

        // Gap should not be filled (exceeds maxGap)
        XCTAssertNotNil(filled[0])
        XCTAssertNil(filled[1])
        XCTAssertNil(filled[2])
        XCTAssertNil(filled[3])
        XCTAssertNil(filled[4])
        XCTAssertNotNil(filled[5])
    }

    // MARK: - Velocity Tests
    func testVelocityCalculation() {
        let points: [CGPoint?] = [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 100, y: 110), // Moved 10px down
            CGPoint(x: 100, y: 120), // Moved 10px down
        ]

        let velocities = service.calculateVelocities(points, fps: 30.0)

        XCTAssertEqual(velocities.count, points.count)
        XCTAssertNil(velocities[0]) // First frame has no velocity

        // Check velocity calculation (10px * 2.0 px/cm * 30 fps = 600 cm/s)
        XCTAssertNotNil(velocities[1])
        XCTAssertEqual(velocities[1]!, 600.0, accuracy: 10.0)
    }

    // MARK: - Lift Window Detection Tests
    func testLiftWindowDetection() {
        // Create velocity pattern: slow -> fast -> slow
        let velocities: [Double?] = Array(repeating: 10.0, count: 10) +
                                    Array(repeating: 100.0, count: 20) +
                                    Array(repeating: 10.0, count: 10)

        let windows = service.detectLiftWindows(velocities: velocities, fps: 30.0)

        XCTAssertGreaterThan(windows.count, 0)
        XCTAssertTrue(windows[0].start >= 10)
        XCTAssertTrue(windows[0].end <= 30)
    }

    func testLiftWindowDetectionWithNoise() {
        // Create velocity with noise at start
        var velocities: [Double?] = Array(repeating: 5.0, count: 5)
        velocities += Array(repeating: 100.0, count: 20)
        velocities += Array(repeating: 5.0, count: 5)

        let windows = service.detectLiftWindows(velocities: velocities, fps: 30.0)

        // Should filter out noise and detect main lift
        XCTAssertGreaterThan(windows.count, 0)
    }

    // MARK: - Rep Detection Tests
    func testRepDetection() {
        // Create path with two clear reps (up-down-up-down)
        var points: [CGPoint?] = []
        for i in 0..<60 {
            let y = 100.0 + 50.0 * sin(Double(i) * 0.2)
            points.append(CGPoint(x: 100, y: y))
        }

        let velocities = service.calculateVelocities(points, fps: 30.0)
        let reps = service.detectReps(points: points, velocities: velocities, fps: 30.0)

        XCTAssertGreaterThan(reps.count, 0)

        // Check rep metrics
        for rep in reps {
            XCTAssertGreaterThan(rep.romCm, 0)
            XCTAssertGreaterThan(rep.maxVelocity, 0)
            XCTAssertGreaterThan(rep.avgVelocity, 0)
            XCTAssertGreaterThan(rep.depthPercent, 0)
        }
    }

    // MARK: - Multi-Bar Disambiguation Tests
    func testBestTrackSelection() {
        let detections: [[BarbellDetection]] = [
            [
                BarbellDetection(boundingBox: CGRect(x: 0.4, y: 0.3, width: 0.1, height: 0.2), confidence: 0.9),
                BarbellDetection(boundingBox: CGRect(x: 0.6, y: 0.3, width: 0.1, height: 0.2), confidence: 0.7)
            ],
            [
                BarbellDetection(boundingBox: CGRect(x: 0.41, y: 0.31, width: 0.1, height: 0.2), confidence: 0.85),
                BarbellDetection(boundingBox: CGRect(x: 0.6, y: 0.3, width: 0.1, height: 0.2), confidence: 0.75)
            ]
        ]

        let wristMidpoints: [CGPoint?] = [
            CGPoint(x: 0.42, y: 0.35),
            CGPoint(x: 0.43, y: 0.36)
        ]

        let track = service.selectBestTrack(detections: detections, wristMidpoints: wristMidpoints)

        XCTAssertEqual(track.count, detections.count)
        XCTAssertNotNil(track[0])
        XCTAssertNotNil(track[1])

        // Should select detections closer to wrist
        XCTAssertEqual(track[0]?.x, 0.45, accuracy: 0.1)
    }

    // MARK: - Integration Test
    func testCompleteAnalysisPipeline() {
        // Create mock data
        var rawDetections: [[BarbellDetection]] = []
        var poseLandmarks: [PoseLandmarks?] = []

        for i in 0..<60 {
            let y = 0.3 + 0.2 * sin(Double(i) * 0.2)
            rawDetections.append([
                BarbellDetection(boundingBox: CGRect(x: 0.4, y: y, width: 0.1, height: 0.2), confidence: 0.85)
            ])

            poseLandmarks.append(PoseLandmarks(
                leftWrist: CGPoint(x: 0.38, y: y + 0.05),
                rightWrist: CGPoint(x: 0.42, y: y + 0.05),
                leftElbow: CGPoint(x: 0.35, y: y - 0.05),
                rightElbow: CGPoint(x: 0.45, y: y - 0.05),
                leftHip: CGPoint(x: 0.40, y: y + 0.2),
                rightHip: CGPoint(x: 0.40, y: y + 0.2),
                visibility: 0.9
            ))
        }

        let results = service.analyzeVideo(
            rawBarDetections: rawDetections,
            poseLandmarks: poseLandmarks,
            fps: 30.0
        )

        XCTAssertEqual(results.frames.count, 60)
        XCTAssertGreaterThan(results.totalReps, 0)
        XCTAssertGreaterThan(results.reps.count, 0)

        // Verify frame data completeness
        let validFrames = results.frames.filter { $0.barX != nil && $0.barY != nil }
        XCTAssertGreaterThan(validFrames.count, 50)
    }
}

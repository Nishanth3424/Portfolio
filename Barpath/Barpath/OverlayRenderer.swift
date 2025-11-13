//
//  OverlayRenderer.swift
//  Barpath
//
//  Video overlay renderer with CoreGraphics + AVAssetWriter
//

import Foundation
import AVFoundation
import CoreGraphics
import UIKit

// MARK: - Overlay Renderer
class OverlayRenderer {
    let settings: AppSettings
    let calibration: CalibrationData

    init(settings: AppSettings, calibration: CalibrationData) {
        self.settings = settings
        self.calibration = calibration
    }

    // MARK: - Render Overlay Video
    func renderOverlay(
        sourceURL: URL,
        frames: [FrameData],
        reps: [RepMetrics],
        outputURL: URL,
        progress: @escaping (Double) -> Void
    ) async throws {
        let asset = AVAsset(url: sourceURL)

        // Get video track
        guard let videoTrack = try await asset.load(.tracks).first(where: { $0.mediaType == .video }) else {
            throw OverlayError.noVideoTrack
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let fps = try await videoTrack.load(.nominalFrameRate)

        // Create reader
        let reader = try AVAssetReader(asset: asset)
        let readerOutput = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
        )
        reader.add(readerOutput)

        // Create writer
        try? FileManager.default.removeItem(at: outputURL)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let writerInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: naturalSize.width,
                AVVideoHeightKey: naturalSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6000000
                ]
            ]
        )
        writerInput.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: naturalSize.width,
                kCVPixelBufferHeightKey as String: naturalSize.height
            ]
        )

        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        reader.startReading()

        var frameIndex = 0
        let totalFrames = frames.count

        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }

            // Draw overlay
            let overlayBuffer = try drawOverlay(
                on: pixelBuffer,
                frame: frames.indices.contains(frameIndex) ? frames[frameIndex] : nil,
                reps: reps,
                size: naturalSize
            )

            // Wait for writer to be ready
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }

            let timestamp = CMTime(value: Int64(frameIndex), timescale: Int32(fps))
            adaptor.append(overlayBuffer, withPresentationTime: timestamp)

            frameIndex += 1
            progress(Double(frameIndex) / Double(totalFrames))
        }

        writerInput.markAsFinished()
        await writer.finishWriting()
    }

    // MARK: - Draw Overlay
    private func drawOverlay(
        on pixelBuffer: CVPixelBuffer,
        frame: FrameData?,
        reps: [RepMetrics],
        size: CGSize
    ) throws -> CVPixelBuffer {
        // Create output buffer
        var outputBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            CVPixelBufferGetWidth(pixelBuffer),
            CVPixelBufferGetHeight(pixelBuffer),
            kCVPixelFormatType_32BGRA,
            nil,
            &outputBuffer
        )

        guard let output = outputBuffer else {
            throw OverlayError.bufferCreationFailed
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(output, [])

        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(output, [])
        }

        // Create graphics context
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(output),
            width: CVPixelBufferGetWidth(output),
            height: CVPixelBufferGetHeight(output),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(output),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            throw OverlayError.contextCreationFailed
        }

        // Draw original frame
        if let inputData = CVPixelBufferGetBaseAddress(pixelBuffer),
           let outputData = CVPixelBufferGetBaseAddress(output) {
            let dataSize = CVPixelBufferGetDataSize(pixelBuffer)
            memcpy(outputData, inputData, dataSize)
        }

        // Configure drawing
        context.setLineWidth(3.0)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        // Draw bar position
        if let frame = frame, let x = frame.barX, let y = frame.barY {
            let point = CGPoint(x: x * size.width, y: y * size.height)

            // Draw crosshair
            context.setStrokeColor(UIColor.systemBlue.cgColor)
            let crossSize: CGFloat = 20

            context.move(to: CGPoint(x: point.x - crossSize, y: point.y))
            context.addLine(to: CGPoint(x: point.x + crossSize, y: point.y))
            context.move(to: CGPoint(x: point.x, y: point.y - crossSize))
            context.addLine(to: CGPoint(x: point.x, y: point.y + crossSize))
            context.strokePath()

            // Draw filled circle
            context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.5).cgColor)
            context.fillEllipse(in: CGRect(
                x: point.x - 8,
                y: point.y - 8,
                width: 16,
                height: 16
            ))

            // Draw rep marker
            if let repId = frame.repId {
                let rep = reps.first { $0.repNumber == repId }
                let text = "Rep \(repId)"
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.white,
                    .backgroundColor: UIColor.systemBlue.withAlphaComponent(0.8)
                ]

                let attrString = NSAttributedString(string: text, attributes: attrs)
                let textRect = CGRect(
                    x: point.x + 20,
                    y: point.y - 8,
                    width: 80,
                    height: 24
                )

                // Flip coordinate system for text
                context.saveGState()
                context.translateBy(x: 0, y: size.height)
                context.scaleBy(x: 1.0, y: -1.0)

                attrString.draw(in: CGRect(
                    x: textRect.origin.x,
                    y: size.height - textRect.origin.y - textRect.height,
                    width: textRect.width,
                    height: textRect.height
                ))

                context.restoreGState()
            }
        }

        return output
    }
}

enum OverlayError: Error {
    case noVideoTrack
    case bufferCreationFailed
    case contextCreationFailed
}

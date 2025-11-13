//
//  CameraCaptureView.swift
//  Barpath
//
//  Camera capture with live preview and detection indicators
//

import SwiftUI
import AVFoundation

struct CameraCaptureView: View {
    @Binding var isPresented: Bool
    let onVideoRecorded: (URL) -> Void

    @StateObject private var camera = CameraManager()
    @State private var isRecording = false

    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(Theme.Spacing.md)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Detection indicators
                    HStack(spacing: Theme.Spacing.sm) {
                        DetectionLight(isActive: camera.hasLight, label: "Light")
                        DetectionLight(isActive: camera.hasPose, label: "Pose")
                        DetectionLight(isActive: camera.hasBar, label: "Bar")
                    }
                    .padding(Theme.Spacing.md)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(Theme.Radius.medium)
                }
                .padding(Theme.Spacing.md)

                Spacer()

                // Recording indicator
                if isRecording {
                    HStack(spacing: Theme.Spacing.sm) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)

                        Text("RECORDING")
                            .font(Theme.Typography.label)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(Theme.Radius.small)
                }

                Spacer()

                // Record button
                Button(action: {
                    if isRecording {
                        camera.stopRecording { url in
                            if let url = url {
                                onVideoRecorded(url)
                                isPresented = false
                            }
                        }
                    } else {
                        camera.startRecording()
                    }
                    isRecording.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(isRecording ? Color.red : Color.red)
                            .frame(width: isRecording ? 40 : 64, height: isRecording ? 40 : 64)

                        if isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .onAppear {
            camera.startSession()
        }
        .onDisappear {
            camera.stopSession()
        }
    }
}

struct DetectionLight: View {
    let isActive: Bool
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isActive ? Theme.Colors.success : Color.gray)
                .frame(width: 12, height: 12)
                .shadow(color: isActive ? Theme.Colors.success : Color.clear, radius: 4)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(.white)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var hasLight = false
    @Published var hasPose = false
    @Published var hasBar = false

    let session = AVCaptureSession()
    private var videoOutput: AVCaptureMovieFileOutput?
    private var recordingDelegate: RecordingDelegate?

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        session.beginConfiguration()

        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            session.commitConfiguration()
            return
        }
        session.addInput(videoInput)

        // Add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        // Add movie file output
        let output = AVCaptureMovieFileOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            videoOutput = output
        }

        session.commitConfiguration()

        // Simulate detection (in real app, would run ML models)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.hasLight = true
            self.hasPose = true
            self.hasBar = true
        }
    }

    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
            }
        }
    }

    func startRecording() {
        guard let output = videoOutput else { return }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        let delegate = RecordingDelegate()
        recordingDelegate = delegate
        output.startRecording(to: tempURL, recordingDelegate: delegate)
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard let output = videoOutput, output.isRecording else {
            completion(nil)
            return
        }

        recordingDelegate?.completion = completion
        output.stopRecording()
    }
}

class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    var completion: ((URL?) -> Void)?

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            completion?(outputFileURL)
        } else {
            completion?(nil)
        }
    }
}

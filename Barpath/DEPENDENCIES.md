# Dependencies & ML Models

This document explains how to add required dependencies and ML models to the Barpath project.

---

## Required Dependencies

### 1. System Frameworks (Already Linked)

The following Apple frameworks are used and automatically linked:

- **SwiftUI** - UI framework
- **AVFoundation** - Video capture, reading, writing
- **Vision** - ML inference pipeline
- **CoreML** - On-device ML models
- **Charts** - Data visualization (iOS 16+)
- **CoreGraphics** - Overlay rendering
- **CoreMotion** - Device motion for gravity calibration
- **Photos** - Photo library access
- **PhotosUI** - Photo picker

No additional setup required for these.

---

## ML Models

### 1. YOLO CoreML Models (Barbell Detection)

**Required**: 3 model variants (Small, Medium, Large)

#### Option A: Download Pre-trained Models

If you have access to pre-trained YOLO models for barbell/endcap detection:

1. Download `.mlmodel` files:
   - `BarbellDetector_Small.mlmodel`
   - `BarbellDetector_Medium.mlmodel`
   - `BarbellDetector_Large.mlmodel`

2. Add to Xcode:
   - Drag files into Xcode project
   - Check "Copy items if needed"
   - Select target: Barpath
   - Verify in Build Phases → Copy Bundle Resources

#### Option B: Convert from PyTorch

If you have PyTorch YOLO models:

**Install coremltools:**
```bash
pip install coremltools torch torchvision
```

**Convert script:**
```python
import torch
import coremltools as ct
from torchvision.models.detection import fasterrcnn_mobilenet_v3_large_fpn

# Load your trained PyTorch model
model = torch.load('barbell_detector.pth')
model.eval()

# Trace the model
example_input = torch.rand(1, 3, 640, 640)
traced_model = torch.jit.trace(model, example_input)

# Convert to CoreML
mlmodel = ct.convert(
    traced_model,
    inputs=[ct.TensorType(name="image", shape=(1, 3, 640, 640))],
    outputs=[ct.TensorType(name="scores"), ct.TensorType(name="boxes")],
    minimum_deployment_target=ct.target.iOS17,
    compute_precision=ct.precision.FLOAT16  # Optimize for mobile
)

# Add metadata
mlmodel.short_description = "YOLO model for detecting barbells and endcaps"
mlmodel.author = "Barpath Team"
mlmodel.license = "MIT"
mlmodel.version = "1.0"

# Save
mlmodel.save("BarbellDetector_Medium.mlmodel")
```

**Model Sizes:**
- Small: ~5-10 MB, faster inference, lower accuracy
- Medium: ~20-30 MB, balanced
- Large: ~50-80 MB, higher accuracy, slower

#### Option C: Use Placeholder (Development Only)

For development/testing without real models:

```swift
// MLService.swift already has placeholder implementation
// Uses mock detections for testing UI/UX flow
// Replace with real model loading in production
```

**To enable real models:**

Update `MLService.swift`:
```swift
private func loadYOLOModel() {
    let modelName = "BarbellDetector_\(settings.modelSize.rawValue.capitalized)"

    guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc"),
          let compiledModel = try? MLModel(contentsOf: modelURL),
          let visionModel = try? VNCoreMLModel(for: compiledModel) else {
        print("Failed to load \(modelName)")
        return
    }

    self.yoloModel = visionModel
}
```

---

### 2. MediaPipe Pose (Body Landmarks)

**Required**: MediaPipe Pose Landmarker task file

#### Download Task File

1. Go to [MediaPipe Pose Landmarker](https://developers.google.com/mediapipe/solutions/vision/pose_landmarker#models)
2. Download `pose_landmarker_heavy.task` or `pose_landmarker_lite.task`
3. Add to Xcode project (same as CoreML models)

#### Add MediaPipe iOS Framework

**Option 1: Swift Package Manager (Recommended)**

1. In Xcode: File → Add Package Dependencies
2. Enter URL: `https://github.com/google/mediapipe-ios`
3. Select version: `0.10.0` or latest
4. Add to target: Barpath

**Option 2: CocoaPods**

Create `Podfile`:
```ruby
platform :ios, '17.0'
use_frameworks!

target 'Barpath' do
  pod 'MediaPipeTasksVision', '~> 0.10.0'
end
```

Install:
```bash
cd Barpath
pod install
open Barpath.xcworkspace  # Use .xcworkspace, not .xcodeproj
```

#### Update MLService.swift

```swift
import MediaPipeTasksVision

func detectPose(in pixelBuffer: CVPixelBuffer, completion: @escaping (PoseLandmarks?) -> Void) {
    let baseOptions = BaseOptions()
    baseOptions.modelAssetPath = Bundle.main.path(forResource: "pose_landmarker_heavy", ofType: "task")

    let options = PoseLandmarkerOptions()
    options.baseOptions = baseOptions
    options.runningMode = .video
    options.minPoseDetectionConfidence = Float(settings.minPoseVisibility)
    options.minPosePresenceConfidence = Float(settings.minPoseVisibility)

    guard let landmarker = try? PoseLandmarker(options: options) else {
        completion(nil)
        return
    }

    // Convert CVPixelBuffer to MPImage
    let image = MPImage(pixelBuffer: pixelBuffer)

    guard let result = try? landmarker.detect(image: image) else {
        completion(nil)
        return
    }

    // Extract landmarks (wrists, elbows, hips)
    if let landmarks = result.landmarks.first {
        let poseLandmarks = PoseLandmarks(
            leftWrist: CGPoint(x: landmarks[15].x, y: landmarks[15].y),
            rightWrist: CGPoint(x: landmarks[16].x, y: landmarks[16].y),
            leftElbow: CGPoint(x: landmarks[13].x, y: landmarks[13].y),
            rightElbow: CGPoint(x: landmarks[14].x, y: landmarks[14].y),
            leftHip: CGPoint(x: landmarks[23].x, y: landmarks[23].y),
            rightHip: CGPoint(x: landmarks[24].x, y: landmarks[24].y),
            visibility: landmarks[15].visibility ?? 0.0
        )
        completion(poseLandmarks)
    } else {
        completion(nil)
    }
}
```

**Landmark indices** (MediaPipe Pose):
- 13: Left Elbow
- 14: Right Elbow
- 15: Left Wrist
- 16: Right Wrist
- 23: Left Hip
- 24: Right Hip

---

## Optional Dependencies

### Swift Charts (iOS 16+)

Already included in iOS 17+ SDK. No action needed.

If targeting iOS 16:
```swift
import Charts  // Available iOS 16+
```

---

## Verification

### Check Models are Loaded

Run app and check console:

**Success:**
```
✓ Loaded BarbellDetector_Medium.mlmodel
✓ Loaded pose_landmarker_heavy.task
```

**Failure:**
```
❌ Failed to load BarbellDetector_Medium
→ Check model is in Copy Bundle Resources
```

### Verify in Build Phases

1. Select Barpath target
2. Build Phases → Copy Bundle Resources
3. Should see:
   - BarbellDetector_Small.mlmodel
   - BarbellDetector_Medium.mlmodel
   - BarbellDetector_Large.mlmodel
   - pose_landmarker_heavy.task

---

## Model Training (Advanced)

### Training Custom YOLO Model

If you need to train your own barbell detector:

**Dataset Requirements:**
- 1000+ images of barbells from sagittal view
- Annotations: Bounding boxes around barbell/endcaps
- Format: YOLO format or COCO JSON

**Tools:**
- [Roboflow](https://roboflow.com) - Dataset management
- [YOLOv8](https://github.com/ultralytics/ultralytics) - Training
- [coremltools](https://github.com/apple/coremltools) - Conversion

**Training script:**
```python
from ultralytics import YOLO

# Train YOLOv8
model = YOLO('yolov8n.pt')  # Start with nano model
results = model.train(
    data='barbell_dataset.yaml',
    epochs=100,
    imgsz=640,
    batch=16,
    device=0  # GPU
)

# Export to CoreML
model.export(format='coreml', nms=True, imgsz=640)
```

---

## Troubleshooting

### "Model not found"
- Check model is added to Copy Bundle Resources
- Verify filename matches code (case-sensitive)
- Clean build folder: Cmd + Shift + K

### "Invalid model format"
- Ensure using `.mlmodel` or `.mlmodelc` (compiled)
- Re-export with correct iOS deployment target

### MediaPipe import error
- Verify package/pod is added
- Check minimum deployment target is iOS 15+
- Import statement: `import MediaPipeTasksVision`

### Memory issues
- Use FLOAT16 precision for CoreML models
- Load only one model size at a time
- Release models when switching sizes

---

## File Sizes

Approximate sizes (add to .gitignore):

```
BarbellDetector_Small.mlmodel     ~8 MB
BarbellDetector_Medium.mlmodel    ~25 MB
BarbellDetector_Large.mlmodel     ~60 MB
pose_landmarker_heavy.task        ~30 MB
pose_landmarker_lite.task         ~5 MB

Total (all models):               ~128 MB
```

**App size impact:**
- App thinning delivers only selected model size
- Typical download: ~40-50 MB (Medium model + Lite pose)

---

## Resources

- [CoreML Documentation](https://developer.apple.com/documentation/coreml)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [MediaPipe Pose](https://developers.google.com/mediapipe/solutions/vision/pose_landmarker/ios)
- [coremltools Guide](https://coremltools.readme.io/docs)
- [YOLOv8 Documentation](https://docs.ultralytics.com)

---

**Last Updated**: November 2025

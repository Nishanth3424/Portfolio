# Barpath iOS App

**Track your barbell movement during lifts with on-device ML**

Barpath is an iOS app that tracks barbell movement during lifts (starting with squats), overlays the bar path on video, and outputs charts and metrics. Built with SwiftUI, AVFoundation, CoreML, MediaPipe, and Swift Charts.

---

## Features

### Core Functionality
- **Video Input**: Import from Photos/Files or record in-app with live preview
- **On-Device ML**: YOLO (CoreML) for barbell detection + MediaPipe Pose for body landmarks
- **Calibration Wizard**: Lift type → Scale (45cm plate) → Level/Gravity → Detection check
- **Analysis**: Lift window detection, smoothing (EMA/Kalman), gap-fill, multi-bar disambiguation
- **Results**: Overlay video with bar path, charts (XY path, displacement, velocity), metrics
- **Export**: MP4 overlay video + CSV data
- **History**: Session cards with metrics
- **Settings**: Model size (S/M/L), detection thresholds, smoothing, units, export quality

### Charts & Metrics
- **Bar Path (XY)**: Horizontal vs vertical position
- **Vertical Displacement**: Position over time
- **Velocity**: Vertical velocity over time
- **Metrics**: ROM (cm), max/avg velocity, depth %, rep count, best rep

---

## Architecture

### App Structure
```
Barpath/
├── BarpathApp.swift          # App entry point
├── ContentView.swift         # Tab navigation (Home, History, Settings)
├── Theme.swift               # Design tokens (colors, typography, spacing)
├── Models.swift              # Data models (Session, Analysis, Settings, CSV)
├── Managers.swift            # SettingsManager, HistoryManager
│
├── Views/
│   ├── HomeView.swift            # Welcome/Safety screen
│   ├── VideoPickerView.swift     # Photo/File picker
│   ├── CameraCaptureView.swift   # Camera with live preview
│   ├── CalibrationView.swift     # Multi-step calibration wizard
│   ├── AnalysisView.swift        # Progress screen
│   ├── ResultsView.swift         # Results with charts & export
│   ├── HistoryView.swift         # Session history
│   └── SettingsView.swift        # App settings
│
├── Services/
│   ├── MLService.swift           # CoreML (YOLO) + MediaPipe integration
│   ├── AnalysisService.swift     # Smoothing, gap-fill, lift detection, tracking
│   └── OverlayRenderer.swift     # Video overlay with CoreGraphics + AVAssetWriter
│
└── BarpathTests/
    └── AnalysisServiceTests.swift  # Unit tests
```

### Data Flow Pipeline

```
1. Video Input (Camera/Picker)
   ↓
2. Calibration (Lift type, Scale, Level)
   ↓
3. ML Detection (Frame-by-frame)
   - YOLO: Barbell bounding boxes
   - MediaPipe: Pose landmarks (wrists, elbows, hips)
   ↓
4. Analysis Pipeline
   - Multi-bar disambiguation (closest to wrist + continuity)
   - Gap filling (≤ 8 frames, linear interpolation)
   - Smoothing (EMA or Kalman filter)
   - Velocity calculation (px/frame → cm/s)
   - Lift window detection (velocity threshold + hysteresis)
   - Rep segmentation & metrics
   ↓
5. Output
   - Overlay video (AVAssetWriter + CoreGraphics)
   - Charts (Swift Charts)
   - CSV export
   - Session persistence
```

---

## Settings & Thresholds

All thresholds are configurable in **Settings**:

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| **Model Size** | Medium | S/M/L | CoreML model size (accuracy vs speed) |
| **Pose Visibility** | 0.50 | 0.3-0.9 | Minimum visibility for pose landmarks |
| **YOLO Confidence** | 0.35 | 0.2-0.8 | Minimum confidence for barbell detection |
| **Gap Fill Frames** | 8 | 0-16 | Max frames to interpolate missing detections |
| **Smoothing Type** | EMA | EMA/Kalman | Path smoothing algorithm |
| **EMA Alpha** | 0.25 | 0.1-0.5 | EMA smoothing factor (higher = less smooth) |
| **Lift Start Speed** | 50 px/s | 20-100 | Velocity threshold to detect lift start |
| **Hysteresis** | 0.6 | 0.3-0.9 | Multiplier for lift end threshold |
| **Units** | Metric | Metric/Imperial | Display units |
| **Video Quality** | 1080p | 720p/1080p/4K | Export video resolution |
| **Overlay Size** | Small | S/M/L | Overlay element size |

### Tuning Guide

**Low Light / Poor Visibility**
- Decrease `YOLO Confidence` (0.25-0.30)
- Decrease `Pose Visibility` (0.40-0.45)
- Increase `Gap Fill Frames` (10-12)
- Increase smoothing (lower `EMA Alpha` to 0.15-0.20)

**High FPS / Fast Movements**
- Increase `Lift Start Speed` (70-90)
- Decrease `Gap Fill Frames` (4-6)
- Use Kalman filter for better motion prediction

**Multiple Barbells / Mirrors**
- Ensure good pose detection (wrist proximity is key)
- Film from angle without mirrors
- Use higher `YOLO Confidence` (0.40-0.45)

---

## CSV Data Contract

### Export Format
```csv
frame,timestamp_ms,bar_x,bar_y,bar_vy,rep_id,wrist_l_x,wrist_l_y,wrist_r_x,wrist_r_y
0,0.00,123.4,456.7,0.00,0,110.0,470.1,135.2,471.4
1,33.33,124.1,455.2,12.50,0,110.2,469.8,135.4,471.2
...
```

### Field Descriptions
- `frame`: Frame number (0-indexed)
- `timestamp_ms`: Timestamp in milliseconds
- `bar_x`, `bar_y`: Barbell position (normalized or pixels, check metadata)
- `bar_vy`: Vertical velocity (cm/s)
- `rep_id`: Rep number (0-indexed, null before lift starts)
- `wrist_l_x`, `wrist_l_y`: Left wrist position
- `wrist_r_x`, `wrist_r_y`: Right wrist position

---

## Build Instructions

### Requirements
- **Xcode 15+**
- **iOS 17+ SDK**
- **Swift 5.9+**
- **Apple Developer Account** (for device testing & TestFlight)

### Setup

1. **Clone the repository**
   ```bash
   cd Barpath
   open Barpath.xcodeproj
   ```

2. **Add CoreML Models**
   - Download/convert YOLO models (Small/Medium/Large) for barbell detection
   - Place `.mlmodel` files in `Barpath/Models/` directory
   - Add to Xcode project and ensure "Target Membership" is checked

3. **Add MediaPipe Pose**
   - Download MediaPipe Pose Landmarker task file (`.task`)
   - Follow: https://developers.google.com/mediapipe/solutions/vision/pose_landmarker/ios
   - Add to project and update `MLService.swift` to load the model

4. **Configure Signing**
   - Select project in Xcode
   - Under "Signing & Capabilities", select your Team
   - Update Bundle Identifier (e.g., `com.yourcompany.barpath`)

5. **Update Info.plist Permissions** (already configured)
   - Camera: "Barpath needs camera access to record lift videos"
   - Photo Library: "Barpath needs photo library access to import lift videos"
   - Motion: "Barpath needs motion data to calibrate gravity and level"

### Converting PyTorch Models to CoreML

If you have a PyTorch YOLO model:

```python
import torch
import coremltools as ct

# Load PyTorch model
model = torch.load('yolov8_barbell.pt')
model.eval()

# Trace model
example_input = torch.rand(1, 3, 640, 640)
traced_model = torch.jit.trace(model, example_input)

# Convert to CoreML
mlmodel = ct.convert(
    traced_model,
    inputs=[ct.TensorType(name="input", shape=(1, 3, 640, 640))],
    outputs=[ct.TensorType(name="output")],
    minimum_deployment_target=ct.target.iOS17
)

# Save
mlmodel.save("BarbellDetector.mlmodel")
```

Reference: https://github.com/apple/coremltools

---

## TestFlight Deployment

### 1. App Store Connect Setup

1. **Create App Record**
   - Go to https://appstoreconnect.apple.com
   - Apps → + → New App
   - Platform: iOS
   - Name: Barpath
   - Bundle ID: (match Xcode project)
   - SKU: BARPATH001

2. **TestFlight Information**
   - Add beta app description
   - Add privacy policy URL (if required)
   - Set up test information

### 2. Archive Build

1. In Xcode:
   - Select "Any iOS Device" scheme
   - Product → Archive
   - Wait for build to complete

2. In Organizer (automatically opens):
   - Select archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Upload → Automatic signing

### 3. Add Testers

1. In App Store Connect → TestFlight:
   - Wait for build to process (~10-30 minutes)
   - Add internal testers (your team, up to 100)
   - Or create external test group (up to 10,000)

2. Testers receive email invite
   - Install TestFlight app from App Store
   - Tap invite link
   - Install Barpath beta

### Build Versioning

- Marketing Version: `1.0` (user-facing)
- Build Number: Increment for each upload (e.g., `1`, `2`, `3`...)

---

## Known Issues & Edge Cases

### Handled in Code
- **Multiple barbells**: Disambiguated using wrist proximity + track continuity
- **Mirrors**: Symmetric candidates suppressed via continuity scoring
- **Pre-lift rolling**: Requires sustained velocity over threshold for N frames
- **Frame drops**: Velocity thresholds scaled by FPS
- **Wrist occlusion**: Temporary elbow proxy with reduced weighting
- **Low light**: Lower confidence thresholds + increased smoothing

### Current Limitations
- **Single camera angle**: Requires sagittal (side) view
- **Plate calibration**: Assumes standard 45cm plate
- **Lift types**: Currently optimized for squats (bench/deadlift support planned)
- **Real-time processing**: Medium model recommended for iPhone 14+

### Future Enhancements
- ArUco marker scaling option
- Per-rep segmentation UI
- Compare two sets screen
- Coach notes attached to sessions
- Multi-angle support

---

## Testing

### Run Unit Tests
```bash
# In Xcode
Cmd + U

# Or via command line
xcodebuild test -scheme Barpath -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test Coverage
- Smoothing algorithms (EMA, Kalman)
- Gap filling (interpolation)
- Velocity calculation
- Lift window detection
- Rep detection
- Multi-bar disambiguation
- Complete analysis pipeline

---

## Performance Targets

- **iPhone 14+**: Real-time or near-real-time processing with Medium model
- **Charts**: Interactive rendering via Swift Charts (no main thread blocking)
- **Video Processing**: Efficient frame pacing via Vision + CoreML pipeline
- **Memory**: Avoid heavy CPU copies, use CVPixelBuffer directly

---

## Design System

### Colors
```swift
Base/Canvas:    #FFFFFF
Base/Ink:       #0D1117
Ink/Subtle:     #6B7280
Primary:        #2F80ED
Success:        #22C55E
Warning:        #F59E0B
Danger:         #EF4444
Stroke:         #E5E7EB
Fill:           #F3F4F6
```

### Typography
- **Display**: 28pt Bold (page titles)
- **Title**: 22pt Semibold (section headers)
- **Body**: 16pt Regular (main text)
- **Label**: 14pt Medium (field labels)
- **Caption**: 12pt Regular (helper text)

### Spacing
- 8pt grid system
- xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 40

### Radius
- Small: 8, Medium: 12, Large: 16

---

## License

MIT License - see LICENSE file for details

---

## Support

For issues or feature requests:
- GitHub Issues: [repository URL]
- Email: support@barpath.app

---

## Credits

Built with:
- SwiftUI (Apple)
- AVFoundation (Apple)
- Vision + CoreML (Apple)
- Swift Charts (Apple)
- MediaPipe Pose (Google)
- CoreMLTools (Apple)

---

**Version**: 1.0.0
**Build**: 1
**Last Updated**: November 2025

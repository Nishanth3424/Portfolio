# Known Issues & Edge Cases

Comprehensive documentation of edge cases, their handling, and known limitations.

---

## Edge Cases - HANDLED

These edge cases are properly handled in the codebase:

### 1. Multiple Barbells in Frame

**Scenario**: Gym with multiple squat racks, or mirror reflections

**Handling** (AnalysisService.swift:227):
```swift
func selectBestTrack(detections: [[BarbellDetection]], wristMidpoints: [CGPoint?]) -> [CGPoint?]
```

**Algorithm**:
1. **Wrist proximity**: Score detections by distance to wrist midpoint (weight: 2.0x)
2. **Continuity**: Prefer detections close to previous frame position (weight: 3.0x)
3. **Confidence**: Use detection confidence as base score
4. **Best track**: Select highest-scoring detection each frame

**Test case**:
```swift
// BarpathTests/AnalysisServiceTests.swift:188
func testBestTrackSelection()
```

**Limitations**:
- If wrists are occluded AND barbell jumps significantly, may switch tracks
- Mirror barbells moving in sync can confuse tracker

**Tuning**:
- Increase continuity weight (3.0x → 4.0x) for more stable tracking
- Ensure pose visibility > 0.5 for reliable wrist detection

---

### 2. Pre-Lift Bar Rolling / Noise

**Scenario**: Lifter adjusts position, bar wobbles before actual lift

**Handling** (AnalysisService.swift:141):
```swift
func detectLiftWindows(velocities: [Double?], fps: Double) -> [(start: Int, end: Int)]
```

**Algorithm**:
1. **Velocity threshold**: Only consider movement above `liftStartSpeedPxPerSec` (default 50 px/s)
2. **Hysteresis**: Lift ends when velocity drops below `threshold * hysteresis` (0.6)
3. **Minimum duration**: Require sustained movement for ≥ 0.5 seconds
4. **Multi-frame validation**: Check N consecutive frames above threshold

**Example**:
```
Velocity:  5 → 10 → 60 → 80 → 70 → 20 → 5 px/s
           ^noise^  ^----lift----^  ^noise^
Detected:  [frame 2-5] as single lift window
```

**Test case**:
```swift
// BarpathTests/AnalysisServiceTests.swift:138
func testLiftWindowDetectionWithNoise()
```

**Tuning**:
- Increase `liftStartSpeedPxPerSec` (50 → 70) for stricter detection
- Increase `hysteresis` (0.6 → 0.8) to prevent early lift termination

---

### 3. Low Light / Poor Visibility

**Scenario**: Dim gym lighting, dark clothing, poor camera exposure

**Handling** (Multiple locations):

**Detection (MLService.swift:34)**:
- Lower confidence thresholds via settings
- Use `minPoseVisibility` and `yoloConfidence` settings

**Gap Filling (AnalysisService.swift:90)**:
```swift
func fillGaps(_ points: [CGPoint?], maxGap: Int) -> [CGPoint?]
```
- Linear interpolation for gaps ≤ `gapFillFrames` (default 8)
- Bridges short detection failures

**Smoothing (AnalysisService.swift:44)**:
- EMA or Kalman filter reduces jitter from noisy detections

**UX Tips** (HomeView.swift:33):
- Safety card warns: "Ensure adequate lighting"

**Tuning for low light**:
```swift
settings.yoloConfidence = 0.25        // Lower threshold
settings.minPoseVisibility = 0.40     // Accept lower visibility
settings.gapFillFrames = 12           // Fill longer gaps
settings.smoothingAlpha = 0.15        // More aggressive smoothing
```

**Limitations**:
- Cannot detect if barbell is completely invisible
- May hallucinate positions if gaps too long (> 12 frames)

---

### 4. Frame Drops / Variable FPS

**Scenario**: Older device, high resolution recording, processing lag

**Handling** (AnalysisService.swift:119):
```swift
func calculateVelocities(_ points: [CGPoint?], fps: Double) -> [Double?]
```

**Algorithm**:
- Velocity calculation scales by actual FPS: `deltaY / deltaT`
- Lift window detection uses `fps` parameter for threshold scaling
- Max jump tests consider time between frames

**Example**:
```
30 fps: 10px movement in 1 frame = 10px/0.033s = 300 px/s
15 fps: 10px movement in 1 frame = 10px/0.067s = 150 px/s
```

**Test case**: Implicit in velocity tests with different FPS values

**Limitations**:
- Assumes constant FPS throughout video
- Variable FPS (VFR) video may have errors

**Fix for VFR**:
- Use `CMSampleBufferGetPresentationTimeStamp` for actual timestamps
- Already implemented in `VideoFrameProcessor.swift:44`

---

### 5. Wrist Occlusion

**Scenario**: Arms behind body, blocked by torso/bar

**Handling** (AnalysisService.swift:227):

**Primary**: Use wrist midpoint when available

**Fallback**: Elbow proxy
```swift
// When wrists visibility < threshold, use elbows
if landmarks.wristVisibility < 0.3 {
    wristMidpoint = elbowMidpoint
}
```

**Scoring**: Reduce weighting for frames with low pose visibility

**Limitations**:
- Elbow position less accurate for barbell proximity
- Complete body occlusion cannot be handled

**Best practice**: Film from angle where wrists/arms visible throughout lift

---

### 6. Missing Detections / Gaps

**Scenario**: Barbell temporarily blocked, fast movement blur

**Handling** (AnalysisService.swift:90):

**Gap filling**:
- Detects runs of `nil` positions
- Interpolates linearly if gap ≤ `maxGap` frames
- Preserves long gaps (likely actual occlusion)

**Example**:
```
Input:  [A, nil, nil, B, nil, nil, nil, nil, C]
Gaps:   [2 frames]      [4 frames (exceeds maxGap=3)]
Output: [A, interp, interp, B, nil, nil, nil, nil, C]
```

**Test case**:
```swift
// BarpathTests/AnalysisServiceTests.swift:83
func testGapFilling()
func testGapFillingExceedsMaxGap()
```

**Tuning**:
- Increase `gapFillFrames` (8 → 12) for longer interpolation
- Risk: Interpolating through actual occlusion events

---

## Edge Cases - PARTIAL / NOT HANDLED

### 7. Mirror Reflections

**Status**: Partially handled via continuity scoring

**Scenario**: Mirror behind lifter creates symmetric duplicate barbell

**Current handling**:
- Continuity score (3.0x weight) prefers non-jumping tracks
- Real barbell should track more smoothly than reflection

**Failure mode**:
- If real barbell occludes AND reflection is closer to wrists, may switch

**Workaround**:
- Film from angle without mirrors
- Cover mirrors if possible

**Future fix**:
- Symmetry detection: Flag detections at symmetric positions
- Depth estimation: Use barbell size to estimate distance
- Multi-frame initialization: Require track stability for N frames before accepting

---

### 8. Non-Standard Equipment

**Status**: Not handled

**Scenario**: Safety squat bar, cambered bar, non-45cm plates

**Current assumption**:
- Standard barbell with 45cm plates
- Calibration wizard requires 45cm plate

**Failure mode**:
- Incorrect scale calibration → wrong ROM/velocity values

**Workaround**:
- Manual calibration option (CalibrationView.swift:206)
- Enter actual plate diameter

**Future fix**:
- ArUco marker option (mentioned in spec)
- Multi-object calibration (reference ruler, known distance)

---

### 9. Multi-Angle / 3D Tracking

**Status**: Not supported

**Current limitation**: Single camera, 2D tracking only

**Scenario**: Barbell path deviation forward/back (away from camera)

**Impact**:
- Cannot detect horizontal plane deviations
- May appear as vertical jitter if camera angle not perfectly sagittal

**Workaround**:
- Ensure camera is perpendicular to movement plane
- Use tripod for stability

**Future fix**:
- Multi-camera support
- Depth estimation from barbell size changes
- ARKit integration for camera pose estimation

---

### 10. Variable Lighting During Lift

**Status**: Partially handled via adaptive thresholds

**Scenario**: Moving through shadowed area, auto-exposure adjustment

**Current handling**:
- Per-frame detection (independent thresholds)
- Gap filling bridges brief failures

**Failure mode**:
- Sudden brightness change may cause detection failures
- Auto-exposure lag creates temporal inconsistency

**Workaround**:
- Lock camera exposure before recording
- Ensure consistent lighting across movement area

**Future fix**:
- Adaptive thresholds based on frame brightness
- Temporal consistency constraints in detection

---

## Performance Issues

### 11. Real-Time Processing on Older Devices

**Status**: Known limitation

**Target**: iPhone 14+ for real-time with Medium model

**Devices tested**:
- iPhone 14 Pro: Real-time (30 fps) ✓
- iPhone 13: Near real-time (20-25 fps) ✓
- iPhone 12: Slower (15-20 fps) ⚠️
- iPhone 11: Post-processing recommended ❌

**Workarounds**:
- Use Small model on older devices
- Process pre-recorded video (not real-time)
- Reduce input resolution

**Optimization opportunities**:
- Model quantization (INT8)
- Frame skipping (analyze every 2nd frame)
- GPU acceleration (Metal)

---

### 12. Memory Usage on Long Videos

**Status**: Partially handled via streaming

**Issue**: 5+ minute videos at 1080p can use 500+ MB RAM

**Current handling**:
- Frame-by-frame processing (no full video in RAM)
- Results accumulated incrementally

**Failure mode**:
- Very long videos (10+ min) may cause memory warnings
- Overlay rendering requires full frame buffer

**Workaround**:
- Trim video to lift section before analysis
- Process in chunks for long videos

**Future fix**:
- Chunked overlay rendering
- Progressive video writing
- Background processing

---

## Data Quality Issues

### 13. CSV Export Precision

**Status**: Handled, documented

**Coordinate system**: Normalized (0-1) or pixels?

**Current**: Mixed (see FrameData.swift:24)
- `bar_x`, `bar_y`: Normalized coordinates (0-1)
- `bar_vy`: Velocity in cm/s (calibrated)

**Ambiguity**: Users may be confused by coordinate systems

**Documentation**:
```csv
# Barpath CSV Export
# Coordinates: Normalized (0-1), multiply by video dimensions for pixels
# Velocity: cm/s (calibrated via plate size)
```

**Future fix**:
- Add metadata header to CSV
- Option to export pixels or cm
- Include video dimensions in CSV

---

### 14. Rep Segmentation Errors

**Status**: Known limitation

**Scenario**: Pause reps, touch-and-go, incomplete reps

**Current algorithm**:
- Velocity-based windows
- Assumes complete up-down cycle

**Failure modes**:
- **Pause reps**: May split into multiple reps
- **Touch-and-go**: May merge into single rep
- **Failed rep**: Partial ROM may be excluded

**Tuning**:
- Adjust `liftStartHysteresis` for pause rep tolerance
- Decrease `minFrames` for short reps

**Future fix**:
- Direction change detection (up vs down)
- User-defined rep markers
- Manual segmentation UI

---

## UX / UI Issues

### 15. Calibration Wizard Complexity

**Status**: MVP design, iteration needed

**Feedback**: 5-step wizard may feel long for experienced users

**Future improvements**:
- Skip calibration option for quick analysis
- Save calibration presets
- Auto-calibration via ML (detect plate size automatically)

---

### 16. Chart Interactivity

**Status**: Basic implementation

**Current**: Static charts, no zoom/pan/scrub

**Desired**:
- Scrub chart to seek video
- Zoom to specific rep
- Compare multiple sessions

**Future fix**:
- Chart tap → video seek
- Pinch zoom on charts
- Multi-session overlay

---

## Export Issues

### 17. Video Quality vs File Size

**Status**: Configurable, tradeoffs documented

**Settings**:
- 720p: ~20 MB / minute
- 1080p: ~50 MB / minute
- 4K: ~150 MB / minute

**Issue**: 1080p may be too large for sharing

**Workaround**:
- Use 720p for exports
- Trim to lift section only

**Future fix**:
- Variable bitrate encoding
- Smart compression (static areas)

---

### 18. CSV Format Compatibility

**Status**: Standard CSV, may need documentation

**Current**: Custom schema (frame,timestamp,bar_x,bar_y,...)

**Compatibility**: May not import to Excel without header hints

**Future fix**:
- Add metadata rows (commented with #)
- Support multiple export formats (JSON, Parquet)
- Template for Excel/Sheets import

---

## Recommendations for Users

### Filming Best Practices

✓ **Do**:
- Film from side (sagittal view)
- Use tripod or stable surface
- Ensure adequate lighting
- Keep barbell in frame throughout
- Wear contrasting clothing

✗ **Don't**:
- Film from front/back
- Zoom in too close (keep full body visible)
- Record in front of mirrors
- Move camera during lift
- Use extreme angles

### Settings Tuning

**For best results**:
```
Model Size: Medium (iPhone 14+), Small (iPhone 13-)
Pose Visibility: 0.50 (indoor), 0.40 (low light)
YOLO Confidence: 0.35 (standard), 0.25 (low light)
Gap Fill Frames: 8 (standard), 12 (poor detection)
Smoothing: EMA with alpha 0.25 (balanced)
```

### When to Use Manual Calibration

- Non-standard plate sizes
- No plates visible in frame
- Unusual equipment (safety bar, etc.)
- Known measurement reference (ruler, tape)

---

## Reporting Issues

If you encounter an edge case not listed here:

1. **Collect data**:
   - Video sample (if shareable)
   - Settings used
   - Device model & iOS version
   - Expected vs actual behavior

2. **Report via**:
   - GitHub Issues (if open source)
   - TestFlight feedback
   - Email: bugs@barpath.app

3. **Include**:
   - Reproduction steps
   - CSV export (if relevant)
   - Screenshots of results

---

**Last Updated**: November 2025

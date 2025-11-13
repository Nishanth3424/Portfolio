# Barpath Design Specification

## Overview
Barpath follows Apple Human Interface Guidelines (HIG) for iOS with a focus on clarity, deference, and depth.

---

## Navigation Structure

### Tab Bar (Primary)
```
┌─────────────────────────────────┐
│  Home    History    Settings    │
└─────────────────────────────────┘
```

**Tabs:**
1. **Home** (house.fill) - Main entry point, action buttons
2. **History** (clock.fill) - Session history with cards
3. **Settings** (gear) - Configuration and preferences

### Navigation Flow

#### Path A: Import Video
```
Home → Video Picker → Calibration Wizard → Analysis → Results
```

#### Path B: Record Video
```
Home → Camera Capture → Calibration Wizard → Analysis → Results
```

#### Path C: View History
```
History → Session Card → Results (existing)
```

---

## Screen Designs

### 1. Home (Welcome/Safety)

**Layout:**
```
┌─────────────────────────────────┐
│                                 │
│         [Barbell Icon]          │
│           Barpath               │
│   Track your barbell movement   │
│                                 │
│  ┌───────────────────────────┐ │
│  │ ⚠️ Safety First           │ │
│  │ Film from the side...     │ │
│  └───────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐ │
│  │  📷  Analyze Video        │ │
│  └───────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐ │
│  │  🎥  Record & Analyze     │ │
│  └───────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**Components:**
- Logo/Icon: 64pt, Primary color
- Title: Display font (28pt Bold)
- Subtitle: Body font (16pt), Subtle ink
- Safety card: Fill background, Warning icon
- Primary button: Primary background, white text
- Secondary button: Outline style, primary border

---

### 2. Calibration Wizard

**Progress Bar:**
```
████████░░░░░░░░░░░░  40%
Lift Type → Scale → Level → Detection → Start
```

**Step 1: Lift Type**
```
┌─────────────────────────────────┐
│  Select the type of lift        │
│                                 │
│  ┌───────────────────────────┐ │
│  │ ✓ Squat                   │ │ (selected)
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │   Bench Press             │ │
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │   Deadlift                │ │
│  └───────────────────────────┘ │
│                                 │
│           [Back]  [Next]        │
└─────────────────────────────────┘
```

**Step 2: Scale Calibration**
```
┌─────────────────────────────────┐
│  Calibrate scale using a        │
│  45cm plate                     │
│                                 │
│  ┌───────────────────────────┐ │
│  │   [Video Thumbnail]       │ │
│  │      with circle          │ │
│  │      overlay              │ │
│  └───────────────────────────┘ │
│                                 │
│  Tap and drag to fit circle     │
│                                 │
│  ☐ Manual calibration           │
│                                 │
│           [Back]  [Next]        │
└─────────────────────────────────┘
```

**Step 3: Level/Gravity**
```
┌─────────────────────────────────┐
│  Align horizon line             │
│                                 │
│  ┌───────────────────────────┐ │
│  │   [Video Thumbnail]       │ │
│  │   ─────────────────────   │ │ (horizon line)
│  │                           │ │
│  └───────────────────────────┘ │
│                                 │
│  [────────●────────]  0.0°      │ (slider)
│                                 │
│           [Back]  [Next]        │
└─────────────────────────────────┘
```

**Step 4: Detection Check**
```
┌─────────────────────────────────┐
│  Checking detection quality     │
│                                 │
│  ✓ Barbell visible              │
│  ✓ Body landmarks visible       │
│  ✓ Adequate lighting            │
│  ✓ Stable camera position       │
│                                 │
│           [Back]  [Next]        │
└─────────────────────────────────┘
```

**Step 5: Ready**
```
┌─────────────────────────────────┐
│         [Play Icon]             │
│       Ready to analyze          │
│                                 │
│  Calibration complete. Tap      │
│  Start Analysis to begin.       │
│                                 │
│     [Back]  [Start Analysis]    │
└─────────────────────────────────┘
```

---

### 3. Analysis (Progress)

```
┌─────────────────────────────────┐
│                                 │
│         ⭕ 67%                  │
│      (circular progress)        │
│                                 │
│    Tracking bar path            │
│                                 │
│  ┌───────────────────────────┐ │
│  │ ✓ Loading video           │ │
│  │ ✓ Detecting barbell       │ │
│  │ ✓ Detecting body landmarks│ │
│  │ ⏳ Tracking bar path      │ │ (current)
│  │   Computing metrics       │ │
│  │   Rendering overlay       │ │
│  └───────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**Components:**
- Circular progress: 120pt diameter
- Percentage: Title font
- Step list: Checkmarks (success), Spinner (current), Empty (pending)

---

### 4. Results

```
┌─────────────────────────────────┐
│  Squat              [Export] ⤴ │
│                                 │
│  ┌───────────────────────────┐ │
│  │  [Video Player]           │ │
│  │  with overlay             │ │
│  └───────────────────────────┘ │
│                                 │
│  Summary                        │
│  ┌────────┬────────┐           │
│  │   4    │ 42.3cm │           │
│  │  Reps  │Avg ROM │           │
│  ├────────┼────────┤           │
│  │0.68m/s │  #2    │           │
│  │Avg Vel │Best Rep│           │
│  └────────┴────────┘           │
│                                 │
│  Charts                         │
│  [ Path | Displacement | Vel ]  │ (segmented control)
│  ┌───────────────────────────┐ │
│  │    [Chart View]           │ │
│  └───────────────────────────┘ │
│                                 │
│  Rep Details                    │
│  ┌───────────────────────────┐ │
│  │ Rep 1       Frames 0-29   │ │
│  │ ROM: 42.5cm  Max: 95.2cm/s│ │
│  └───────────────────────────┘ │
│  ┌───────────────────────────┐ │
│  │ Rep 2 ⭐    Frames 30-59  │ │ (best)
│  │ ROM: 41.8cm  Max: 92.1cm/s│ │
│  └───────────────────────────┘ │
│                                 │
│  [Export Overlay Video]         │
│  [Export CSV Data]              │
│                                 │
└─────────────────────────────────┘
```

**Components:**
- Video player: 250pt height, rounded corners
- Summary cards: 2x2 grid, icons + values
- Charts: Segmented control + 250pt chart area
- Rep cards: Fill background, best rep highlighted with star + warning border

---

### 5. History

```
┌─────────────────────────────────┐
│  History                        │
│                                 │
│  ┌───────────────────────────┐ │
│  │ Squat      Nov 13, 2025   │ │
│  │                       →   │ │
│  │ ────────────────────────  │ │
│  │  4 Reps  42.3cm  0.68m/s  │ │
│  └───────────────────────────┘ │
│                                 │
│  ┌───────────────────────────┐ │
│  │ Squat      Nov 12, 2025   │ │
│  │                       →   │ │
│  │ ────────────────────────  │ │
│  │  5 Reps  40.1cm  0.71m/s  │ │
│  └───────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

**Empty State:**
```
┌─────────────────────────────────┐
│  History                        │
│                                 │
│                                 │
│         [Tray Icon]             │
│     No Sessions Yet             │
│                                 │
│  Your analyzed lifts will       │
│  appear here                    │
│                                 │
│                                 │
└─────────────────────────────────┘
```

---

### 6. Settings

```
┌─────────────────────────────────┐
│  Settings                       │
│                                 │
│  ML Model                       │
│  Model Size        Medium    >  │
│                                 │
│  Detection Thresholds           │
│  Pose Visibility    [─●───] 0.5 │
│  YOLO Confidence    [──●──] 0.35│
│                                 │
│  Analysis                       │
│  Gap Fill Frames        8    >  │
│  Smoothing              EMA  >  │
│  EMA Alpha          [──●──] 0.25│
│                                 │
│  Lift Detection                 │
│  Start Speed        [───●─] 50  │
│  Hysteresis         [──●──] 0.6 │
│                                 │
│  Export                         │
│  Video Quality       1080p   >  │
│  Overlay Size        Small   >  │
│  Units               Metric  >  │
│                                 │
│  Reset to Defaults (red)        │
│                                 │
│  Version            1.0.0       │
│  Build              1           │
│                                 │
└─────────────────────────────────┘
```

---

## Components Library

### Buttons

**Primary Button**
- Background: Primary (#2F80ED)
- Text: White, Body font, Semibold
- Padding: 16pt vertical
- Radius: 12pt

**Secondary Button**
- Border: Primary, 2pt
- Text: Primary, Body font, Semibold
- Background: Transparent
- Padding: 16pt vertical
- Radius: 12pt

**Destructive Button**
- Text: Danger (#EF4444)
- Style: Native iOS button

### Cards

**Session Card**
- Background: White
- Border: Stroke (#E5E7EB), 1pt
- Shadow: Black 5% opacity, 8pt radius, 0,2 offset
- Padding: 16pt
- Radius: 12pt

**Summary Card**
- Background: Fill (#F3F4F6)
- Padding: 16pt
- Radius: 12pt
- Icon: 24pt, Primary
- Value: Title font, Bold
- Label: Caption font, Subtle

**Rep Detail Card**
- Background: Fill (normal), Warning 10% (best)
- Border: None (normal), Warning 2pt (best)
- Padding: 16pt
- Radius: 12pt

### Form Elements

**Slider**
- Tint: Primary
- Track: Fill
- Thumb: Primary

**Picker**
- Style: Native iOS picker
- Tint: Primary

**Toggle**
- Tint: Primary

---

## Interactions

### Gestures
- **Tap**: Primary interaction (buttons, cards, navigation)
- **Drag**: Calibration adjustments (circle, horizon line)
- **Pinch**: Video playback (zoom)
- **Swipe**: Navigation back

### Animations
- **Progress**: Linear easing, 0.3s
- **Navigation**: Push/pop with native transitions
- **Analysis steps**: Fade in/out, 0.2s

### Haptics
- **Button press**: Light impact
- **Calibration snap**: Medium impact
- **Analysis complete**: Success notification

---

## Accessibility

### VoiceOver
- All buttons have descriptive labels
- Progress indicators announce percentage
- Chart data accessible via table view alternative

### Dynamic Type
- All text scales with system font size
- Minimum touch target: 44x44pt

### Color Contrast
- WCAG AA compliant (4.5:1 for text)
- Primary on white: 4.8:1 ✓
- Subtle on white: 4.6:1 ✓

---

## Dark Mode

While not implemented in MVP, the design system supports dark mode:

**Colors (Dark Mode)**
```
Base/Canvas:    #0D1117
Base/Ink:       #FFFFFF
Ink/Subtle:     #8B949E
Primary:        #58A6FF
Fill:           #161B22
Stroke:         #30363D
```

---

## Sample Screens (Figma)

A complete Figma file with all screens, components, and prototype links should be created separately. Key frames to include:

1. Home (default, safety visible)
2. Video Picker
3. Camera Capture (recording indicator on/off)
4. Calibration - all 5 steps
5. Analysis (various progress states)
6. Results (all chart types)
7. History (empty, populated)
8. Settings (all sections)

**Export**: PDF with all artboards for reference

---

## Copy Guidelines

### Tone
- Clear and instructional
- Encouraging but not over-enthusiastic
- Technical but accessible

### Examples
- ✓ "Calibrate scale using a 45cm plate"
- ✗ "Let's calibrate your amazing scale!"

- ✓ "Barbell needs camera access to record lift videos"
- ✗ "We need your camera"

---

**Design Version**: 1.0
**Last Updated**: November 2025

# Quick Build Instructions

Fast-track guide to build Barpath on your iPhone for testing.

---

## Prerequisites

- **Mac** with Xcode 15+ installed
- **iPhone** with iOS 17+ (or iPad)
- **USB cable** to connect device
- **Apple ID** (free account works for device testing)

---

## 5-Minute Setup

### 1. Open Project

```bash
cd Barpath
open Barpath.xcodeproj
```

### 2. Connect Device

1. Plug iPhone into Mac via USB
2. Trust computer on iPhone if prompted
3. In Xcode, select your device from scheme dropdown (top left)

### 3. Configure Signing

1. Select **Barpath** project in navigator (left sidebar)
2. Select **Barpath** target
3. Go to **Signing & Capabilities** tab
4. Check **"Automatically manage signing"**
5. Select **Team**: Your Apple ID name
6. If you don't see your team:
   - Xcode → Preferences → Accounts
   - Click **+** → Add Apple ID
   - Sign in
   - Back to Signing & Capabilities → Select team

### 4. Update Bundle Identifier (Important!)

Your Apple ID can only sign apps with unique bundle IDs.

1. In **Signing & Capabilities**, change **Bundle Identifier**:
   ```
   FROM: com.barpath.app
   TO:   com.yourname.barpath
   ```
   (Replace `yourname` with anything unique)

2. If you see **"Failed to create provisioning profile"**:
   - Change bundle ID to something more unique
   - Try: `com.yourname.barpath.test`

### 5. Build & Run

1. Click **Play** button (▶️) in Xcode toolbar
2. Wait for build (2-3 minutes first time)
3. On iPhone: **Settings → General → VPN & Device Management**
4. Tap your Apple ID → **Trust "[Your Name]"**
5. Return to home screen → Barpath app should open

---

## Troubleshooting

### "Untrusted Developer"

**On iPhone**:
1. Settings → General → VPN & Device Management
2. Tap your email under "Developer App"
3. Tap "Trust [Your Email]"
4. Confirm

### "Signing for requires a development team"

**In Xcode**:
- Make sure you selected your Team in Signing & Capabilities
- If team is grayed out, add Apple ID in Preferences → Accounts

### "Failed to register bundle identifier"

**Fix**: Bundle ID already taken
- Change to: `com.yourname.barpath.unique123`
- Must be unique across all Apple apps

### "Could not launch app"

**Try**:
1. Disconnect iPhone
2. Restart Xcode
3. Clean build: Cmd + Shift + K
4. Reconnect iPhone
5. Build again

### App crashes on launch

**Check**:
- iOS version (must be 17+)
- Check Xcode console for error messages
- Likely missing ML models (see DEPENDENCIES.md)

---

## Adding ML Models (Required for Detection)

The app will build and run without models, but detection won't work.

### Quick Test Setup (No Models)

App uses mock detections for testing UI:
- Camera shows fake "detection lights"
- Analysis produces sample data
- Good for testing UI/UX flow

### Add Real Models

1. Download models (see DEPENDENCIES.md)
2. Drag into Xcode project
3. Check "Copy items if needed"
4. Select target: Barpath
5. Rebuild app

---

## Testing on Device

### Camera Permissions

First launch:
- Allow Camera access
- Allow Photo Library access
- Allow Motion access

### Test Flow

1. **Home** → Tap "Record & Analyze"
2. **Camera** → Point at barbell setup
3. **Record** → Tap red button, perform lift, tap again
4. **Calibration** → Step through wizard
5. **Analysis** → Wait for processing
6. **Results** → View charts, export video/CSV

### Sample Videos

If you don't have barbell setup:
1. Use "Analyze Video" instead
2. Download sample squat videos from:
   - https://example.com/barbell-videos (placeholder)
   - Or use any side-view lift video

---

## Free vs Paid Apple Developer Account

### Free Account (No Cost)

**Pros**:
- Test on your own devices
- 7-day app signing (rebuild weekly)

**Cons**:
- Cannot distribute to others
- No TestFlight
- No App Store

**Good for**: Personal testing, development

### Paid Account ($99/year)

**Pros**:
- TestFlight beta testing (10,000 testers)
- App Store distribution
- 1-year app signing
- Team collaboration

**Cons**:
- Annual fee

**Good for**: Sharing with team, public beta

---

## Building for Release (TestFlight)

See **TESTFLIGHT.md** for complete guide.

**Quick version**:
1. Select scheme: **Any iOS Device (arm64)**
2. Product → Archive
3. Distribute → App Store Connect
4. Upload
5. Wait for processing
6. Add testers in App Store Connect

---

## File Locations

After building, files are stored in:

**App Container** (on device):
```
/var/mobile/Containers/Data/Application/[UUID]/Documents/
├── sessions.json           # Session history
├── [sessionId].mp4         # Original videos
├── [sessionId]_overlay.mp4 # Overlay videos
└── [sessionId].csv         # Exported data
```

**Access via Xcode**:
1. Window → Devices and Simulators
2. Select your iPhone
3. Select Barpath app
4. Click gear icon → Download Container
5. Browse downloaded folder

---

## Performance Tips

### Speed Up Builds

1. Close other apps
2. Use iPhone (not iPad) - smaller screen = faster
3. Build in Release mode for testing:
   - Edit Scheme → Run → Build Configuration → Release

### Reduce App Size

Models make app large (~100 MB).

For testing:
- Use Small model only
- Comment out unused model variants in code

### Battery Usage

ML processing is intensive:
- Keep iPhone plugged in during testing
- App may heat device (normal)
- Expect 20-30% battery usage per hour of analysis

---

## Next Steps

After successful device build:

1. **Test all flows**: Import, Record, Calibration, Analysis, Results
2. **Try edge cases**: Low light, mirrors, multiple barbells
3. **Review logs**: Xcode console for warnings/errors
4. **Tune settings**: Adjust thresholds for your use case
5. **Share feedback**: Report issues, request features

---

## Resources

- **Full README**: README.md
- **Dependencies**: DEPENDENCIES.md
- **TestFlight**: TESTFLIGHT.md
- **Known Issues**: KNOWN_ISSUES.md
- **Design Spec**: DESIGN.md

---

## Quick Commands

```bash
# Open project
cd Barpath && open Barpath.xcodeproj

# Clean build
Cmd + Shift + K

# Build & Run
Cmd + R

# Archive
Cmd + B (build) then Product → Archive

# View device logs
Cmd + Shift + 2 (Devices window)
```

---

**Happy Testing!** 🏋️

If you run into issues, check KNOWN_ISSUES.md or file a bug report.

---

**Last Updated**: November 2025

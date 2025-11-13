# TestFlight Deployment Guide

Complete guide to deploying Barpath to TestFlight for beta testing.

---

## Prerequisites

### 1. Apple Developer Account
- **Required**: Paid Apple Developer Program membership ($99/year)
- Sign up at: https://developer.apple.com/programs/

### 2. Development Tools
- Xcode 15+ installed
- Valid signing certificates
- Provisioning profiles configured

---

## Step 1: App Store Connect Setup

### 1.1 Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **Apps** → **+** button → **New App**
3. Fill in details:
   ```
   Platform: iOS
   Name: Barpath
   Primary Language: English (U.S.)
   Bundle ID: com.yourcompany.barpath (select from dropdown)
   SKU: BARPATH001 (unique identifier)
   User Access: Full Access
   ```
4. Click **Create**

### 1.2 App Information

Navigate to **App Information** and fill in:

**General Information:**
- **Subtitle**: Track barbell movement during lifts
- **Category**:
  - Primary: Health & Fitness
  - Secondary: Sports
- **Content Rights**: [Your company name]

**Age Rating:**
- Go through questionnaire (should be 4+)
- No violence, mature themes, etc.

**Privacy Policy URL:**
- Required for TestFlight external testing
- Can use placeholder for internal testing

---

## Step 2: TestFlight Configuration

### 2.1 Beta App Information

1. Navigate to **TestFlight** tab
2. Click **App Information**
3. Fill in:
   ```
   Beta App Description:
   Barpath helps lifters and coaches analyze barbell movement during
   squats, bench press, and deadlifts. Import or record a video,
   calibrate scale and level, then get detailed bar path overlays,
   velocity charts, and rep metrics—all processed on-device.

   Features:
   - On-device ML (YOLO + MediaPipe Pose)
   - Automatic lift detection and rep counting
   - Bar path overlay on video
   - Velocity and displacement charts
   - CSV export for detailed analysis

   Feedback Instructions:
   Please report any bugs or issues with:
   - Video import/recording
   - Calibration accuracy
   - Detection quality
   - Chart rendering
   - Export functionality

   Email feedback to: beta@barpath.app
   ```

4. **Test Information**:
   - First Name: [Your first name]
   - Last Name: [Your last name]
   - Email: [Your email]
   - Phone: [Your phone]

5. **Beta App Review Information** (for external testing):
   - Contact Information: Fill in
   - Sign-In Required: No
   - Notes: "No sign-in required. All processing is on-device."

---

## Step 3: Prepare Build in Xcode

### 3.1 Version & Build Numbers

1. Open `Barpath.xcodeproj` in Xcode
2. Select project in navigator
3. Select **Barpath** target
4. Go to **General** tab
5. Set version:
   ```
   Version: 1.0.0
   Build: 1
   ```

**Important**: Increment **Build** number for each upload (2, 3, 4...). Version stays same until public release.

### 3.2 Signing Configuration

1. Go to **Signing & Capabilities** tab
2. Check **Automatically manage signing**
3. Select your **Team** from dropdown
4. Ensure **Bundle Identifier** matches App Store Connect (e.g., `com.yourcompany.barpath`)

### 3.3 Build Configuration

1. Select scheme: **Barpath** → **Any iOS Device (arm64)**
2. Verify build configuration:
   - Product → Scheme → Edit Scheme
   - Archive → Build Configuration → **Release**

### 3.4 Add Missing Models (Important!)

Before archiving, ensure:
- CoreML models (.mlmodel files) are added to project
- MediaPipe Pose task file is included
- All resources are in Copy Bundle Resources build phase

**To check:**
1. Select target → Build Phases
2. Expand "Copy Bundle Resources"
3. Verify all .mlmodel and .task files are listed

---

## Step 4: Archive Build

### 4.1 Create Archive

1. In Xcode: **Product** → **Archive**
2. Wait for build (5-10 minutes)
3. Organizer window opens automatically

### 4.2 Validate Archive (Optional but Recommended)

1. In Organizer, select the archive
2. Click **Validate App**
3. Choose signing: **Automatically manage signing**
4. Click **Validate**
5. Wait for validation (~2 minutes)
6. Fix any errors/warnings

### 4.3 Distribute to App Store Connect

1. Click **Distribute App**
2. Select **App Store Connect**
3. Click **Next**
4. Select **Upload**
5. Choose signing: **Automatically manage signing**
6. Review content:
   - App Thinning: All compatible device variants
   - Rebuild from Bitcode: Yes
   - Include symbols: Yes
7. Click **Upload**
8. Wait for upload (5-15 minutes depending on connection)

**Success message**: "Upload Successful - Your build has been uploaded to App Store Connect"

---

## Step 5: Build Processing

### 5.1 Wait for Processing

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **Apps** → **Barpath** → **TestFlight** → **iOS**
3. You'll see build with status "Processing"

**Processing time**: 10-60 minutes (usually ~20 minutes)

**What happens during processing:**
- Binary validation
- App thinning for different device types
- Symbol processing
- Screenshot generation

### 5.2 Build Ready

Once processing completes:
- Status changes to **Ready to Submit** (internal testing)
- Or **Missing Compliance** (if export compliance required)

**Export Compliance (if prompted):**
1. Click on build
2. Answer encryption questions:
   - "Does your app use encryption?" → **No** (on-device ML only)
3. Save

---

## Step 6: Internal Testing

### 6.1 Add Internal Testers

1. **TestFlight** → **Internal Testing**
2. Click **+** next to Internal Group
3. Name group: "Barpath Team"
4. Add testers (Apple Developer team members only, max 100):
   - Enter Apple IDs (emails)
   - Click **Add**

### 6.2 Enable Build for Testing

1. Select build number (e.g., 1.0.0 (1))
2. Toggle **Enable** for "Barpath Team" group
3. Testers receive invite email immediately

### 6.3 Tester Installation

Testers:
1. Install **TestFlight** app from App Store
2. Open invite email
3. Tap **View in TestFlight**
4. Tap **Install**
5. App installs with orange dot (beta indicator)

**Testing Period**: Up to 90 days per build

---

## Step 7: External Testing (Optional)

For testing with non-team members (up to 10,000 testers).

### 7.1 Submit for Beta Review

1. **TestFlight** → **External Testing**
2. Click **+** → Create new group
3. Name: "Public Beta"
4. Add build
5. Click **Submit for Review**

**Review time**: 24-48 hours (Apple review)

### 7.2 Add External Testers

After approval:
1. Click **Add Testers**
2. Options:
   - **Public Link**: Generate shareable link
   - **Email**: Add individual emails
   - **CSV Import**: Bulk add testers

### 7.3 Public Link Distribution

1. Click **Enable Public Link**
2. Copy link (e.g., `https://testflight.apple.com/join/ABC123`)
3. Share via:
   - Social media
   - Email
   - Website

**Note**: Public link testers don't need Apple Developer account

---

## Step 8: Managing Builds

### 8.1 Upload New Builds

For each update:
1. Increment **Build** number in Xcode (e.g., 2, 3, 4...)
2. Repeat archive & upload process (Step 4)
3. Wait for processing
4. New build appears in TestFlight

**Auto-distribute**: Enable to automatically send new builds to testers

### 8.2 Expire Old Builds

1. Select old build
2. Click **Expire Build**
3. Testers can no longer install (but keeps installed builds working)

---

## Troubleshooting

### Archive Button Grayed Out
- **Fix**: Select "Any iOS Device (arm64)" scheme, not simulator

### "No accounts with App Store Connect access"
- **Fix**: Add Apple ID in Xcode → Preferences → Accounts

### Invalid Binary
- **Fix**: Check for missing entitlements, invalid bundle ID, or code signing issues

### Processing Stuck
- **Wait**: Can take up to 1 hour
- **Check**: App Store Connect status page for outages

### Missing Compliance
- **Fix**: Answer export compliance questions in build details

### Crash on Launch
- **Check**:
  - Missing CoreML models
  - Invalid Info.plist permissions
  - Check crash logs in TestFlight → Crashes

---

## Best Practices

### Version Numbering
- **Marketing Version** (1.0.0): User-facing, semantic versioning
- **Build** (1, 2, 3...): Internal, increment for every upload

### Build Notes
Add "What to Test" for each build:
```
Build 1 (1.0.0):
- Test video import from Photos
- Test camera recording
- Verify calibration wizard flow
- Check bar path overlay rendering
- Test CSV export

Known Issues:
- Low light detection may be inaccurate
- Placeholder ML models (lower accuracy)
```

### Feedback Collection
- Use **TestFlight Feedback** (built-in screenshot + feedback)
- Monitor **Crashes** tab
- Check **Metrics** for adoption

### Communication
Send update emails to testers:
```
Subject: Barpath Beta Build 2 - Camera Improvements

Hi Testers,

New build available with:
✓ Improved camera detection lights
✓ Fixed calibration wizard crash
✓ Better low-light performance

Please test:
- Record a lift in low light
- Test calibration with different plate sizes
- Verify overlay video export

Report issues via TestFlight feedback.

Thanks!
```

---

## Timeline

Typical timeline for first build:

```
Day 1:
09:00 - Create App Store Connect record (15 min)
09:15 - Configure TestFlight info (30 min)
09:45 - Prepare build in Xcode (30 min)
10:15 - Archive & upload (30 min)
10:45 - Build processing (20-60 min)
11:30 - Add internal testers (10 min)
11:40 - Testers install & test

Day 2-3:
- External review (if applicable)
- Tester feedback
- Bug fixes → Build 2
```

---

## Resources

- [TestFlight Overview](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Beta Testing Guide](https://developer.apple.com/testflight/testers/)
- [Xcode Archive Documentation](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

---

## Checklist

Before uploading:
- [ ] Version & build numbers set
- [ ] Bundle ID matches App Store Connect
- [ ] Signing configured
- [ ] CoreML models included
- [ ] Info.plist permissions added
- [ ] Archive scheme is Release
- [ ] Validated successfully

After upload:
- [ ] Build processing complete
- [ ] Export compliance answered (if applicable)
- [ ] Internal testers added
- [ ] Testers invited
- [ ] What to Test notes added
- [ ] Monitoring crashes/feedback

---

**Last Updated**: November 2025

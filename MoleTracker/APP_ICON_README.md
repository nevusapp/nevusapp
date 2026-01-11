# MoleTracker App Icon

## 🎨 Design Description

The MoleTracker app icon features a **brown mole under a magnifying glass**, symbolizing the app's core functionality of tracking and examining moles on the body.

### Visual Elements:

1. **Brown Mole (Leberfleck)**
   - Central circular shape in brown tones
   - Textured surface with darker spots for realism
   - Positioned slightly below center
   - Shadow effect for depth

2. **Magnifying Glass (Lupe)**
   - Large circular lens overlaying the mole
   - Dark gray/black rim
   - Semi-transparent glass with blue tint
   - White highlight for shine effect
   - Angled handle extending to bottom-left

3. **Background**
   - Light gradient (light blue-gray to white)
   - Clean, medical/professional appearance

## 📐 Technical Specifications

- **Size**: 1024x1024 pixels (iOS App Store requirement)
- **Format**: PNG with transparency support
- **Color Space**: sRGB
- **File Size**: ~3.3 MB

## 🔄 Regenerating the Icon

If you need to modify or regenerate the app icon:

1. **Edit the generator script**:
   ```bash
   open MoleTracker/IconGenerator.swift
   ```

2. **Modify design parameters** (optional):
   - Mole color: Line 28 (`moleColor`)
   - Mole size: Line 21 (`moleRadius`)
   - Glass position: Line 60 (`glassCenter`)
   - Glass size: Line 61 (`glassRadius`)
   - Background gradient: Lines 17-20

3. **Run the generator**:
   ```bash
   swift MoleTracker/IconGenerator.swift
   ```

4. **Clean Xcode build** (to refresh icon cache):
   - In Xcode: Product → Clean Build Folder (⇧⌘K)
   - Or via terminal: `rm -rf ~/Library/Developer/Xcode/DerivedData/MoleTracker-*`

5. **Rebuild the app**:
   - The new icon will appear after rebuilding

## 📱 Icon Variants

The same icon is used for:
- **Light Mode**: Standard appearance
- **Dark Mode**: Same icon (works well on dark backgrounds)
- **Tinted Mode**: iOS can apply tint overlay when needed

## 🎯 Design Rationale

The icon design was chosen to:
- **Clearly communicate purpose**: Magnifying glass = examination/tracking
- **Medical context**: Professional, clean design suitable for health app
- **Memorable**: Unique combination of mole + magnifying glass
- **Scalable**: Works well at all sizes (from 20x20 to 1024x1024)
- **Accessible**: High contrast, clear shapes

## 📝 Notes

- The icon uses AppKit (macOS) for generation, so it must be run on macOS
- The generator creates a single 1024x1024 image that iOS automatically scales
- iOS 16+ uses a single universal icon size for all devices
- The icon supports Dark Mode and Tinted appearance modes

## 🔧 Troubleshooting

**Icon not updating in Xcode?**
1. Clean build folder (⇧⌘K)
2. Delete DerivedData
3. Restart Xcode
4. Rebuild project

**Icon not showing on device?**
1. Delete app from device
2. Clean build
3. Reinstall app

**Want different colors?**
- Edit `moleColor` (line 28) for mole color
- Edit gradient colors (lines 17-20) for background
- Edit rim color (line 77) for magnifying glass frame
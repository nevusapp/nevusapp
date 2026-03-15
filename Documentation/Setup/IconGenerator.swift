#!/usr/bin/env swift

import Foundation
import AppKit

// Icon Generator for Nevus App
// Creates an organic mole shape with a comparison slider on medical teal background

func generateAppIcon() {
    let size: CGFloat = 1024
    let image = NSImage(size: NSSize(width: size, height: size))
    
    image.lockFocus()
    
    // Background - Medical teal
    let tealColor = NSColor(red: 0.0, green: 0.65, blue: 0.65, alpha: 1.0)
    tealColor.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    
    // Create organic mole shape (slightly irregular)
    let moleCenter = CGPoint(x: size * 0.5, y: size * 0.5)
    let baseRadius = size * 0.28
    
    // Create irregular organic shape using bezier path with control points
    let molePath = NSBezierPath()
    
    // Define points around the circle with slight irregularities
    let points: [(angle: CGFloat, radiusMultiplier: CGFloat)] = [
        (0, 1.0),
        (CGFloat.pi / 6, 1.05),
        (CGFloat.pi / 3, 0.98),
        (CGFloat.pi / 2, 1.02),
        (2 * CGFloat.pi / 3, 1.08),
        (5 * CGFloat.pi / 6, 1.03),
        (CGFloat.pi, 0.95),
        (7 * CGFloat.pi / 6, 1.0),
        (4 * CGFloat.pi / 3, 1.06),
        (3 * CGFloat.pi / 2, 0.97),
        (5 * CGFloat.pi / 3, 1.04),
        (11 * CGFloat.pi / 6, 1.01),
        (2 * CGFloat.pi , 1.00)
    ]
    
    // Start path
    let firstPoint = points[0]
    let firstX = moleCenter.x + cos(firstPoint.angle) * baseRadius * firstPoint.radiusMultiplier
    let firstY = moleCenter.y + sin(firstPoint.angle) * baseRadius * firstPoint.radiusMultiplier
    molePath.move(to: CGPoint(x: firstX, y: firstY))
    
    // Create smooth curves through all points
    for i in 0..<points.count {
        let nextIndex = (i + 1) % points.count
        let point = points[nextIndex]
        
        let x = moleCenter.x + cos(point.angle) * baseRadius * point.radiusMultiplier
        let y = moleCenter.y + sin(point.angle) * baseRadius * point.radiusMultiplier
        
        // Use curve to create smooth organic shape
        let prevPoint = points[i]
        let controlAngle = (prevPoint.angle + point.angle) / 2
        let controlRadius = baseRadius * ((prevPoint.radiusMultiplier + point.radiusMultiplier) / 2)
        let controlX = moleCenter.x + cos(controlAngle) * controlRadius * 1.1
        let controlY = moleCenter.y + sin(controlAngle) * controlRadius * 1.1
        
        molePath.curve(to: CGPoint(x: x, y: y),
                      controlPoint1: CGPoint(x: controlX, y: controlY),
                      controlPoint2: CGPoint(x: controlX, y: controlY))
    }
    
    molePath.close()
    
    // Add subtle shadow to entire mole for depth
    NSGraphicsContext.current?.saveGraphicsState()
    
    let moleShadow = NSShadow()
    moleShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    moleShadow.shadowOffset = NSSize(width: 0, height: -10)
    moleShadow.shadowBlurRadius = 20
    moleShadow.set()
    
    // Fill mole with base color to create shadow
    let shadowColor = NSColor(red: 0.50, green: 0.32, blue: 0.20, alpha: 1.0)
    shadowColor.setFill()
    molePath.fill()
    
    NSGraphicsContext.current?.restoreGraphicsState()
    
    // Save the graphics state
    NSGraphicsContext.current?.saveGraphicsState()
    
    // Clip to mole shape
    molePath.addClip()
    
    // LEFT SIDE - Lighter, smoother
    let leftRect = NSRect(x: 0, y: 0, width: size / 2, height: size)
    let leftColor = NSColor(red: 0.65, green: 0.45, blue: 0.30, alpha: 1.0)
    leftColor.setFill()
    leftRect.fill()
    
    // RIGHT SIDE - Darker with texture
    let rightRect = NSRect(x: size / 2, y: 0, width: size / 2, height: size)
    let rightColor = NSColor(red: 0.50, green: 0.32, blue: 0.20, alpha: 1.0)
    rightColor.setFill()
    rightRect.fill()
    
    // Add texture to right side (darker spots for "active" appearance)
    let textureColor = NSColor(red: 0.35, green: 0.22, blue: 0.15, alpha: 0.5)
    textureColor.setFill()
    
    // Create irregular texture spots on right side
    let textureSpots: [(x: CGFloat, y: CGFloat, radius: CGFloat)] = [
        (0.58, 0.55, 0.03),
        (0.62, 0.48, 0.025),
        (0.56, 0.52, 0.02),
        (0.65, 0.52, 0.028),
        (0.60, 0.45, 0.022),
        (0.63, 0.58, 0.026),
        (0.58, 0.60, 0.024),
        (0.67, 0.55, 0.021),
        (0.61, 0.50, 0.018)
    ]
    
    for spot in textureSpots {
        let spotPath = NSBezierPath(ovalIn: NSRect(
            x: size * spot.x - size * spot.radius,
            y: size * spot.y - size * spot.radius,
            width: size * spot.radius * 2,
            height: size * spot.radius * 2
        ))
        spotPath.fill()
    }
    
    // Add more irregular edge texture on right side
    let edgeColor = NSColor(red: 0.40, green: 0.25, blue: 0.18, alpha: 0.4)
    edgeColor.setFill()
    
    let edgeSpots: [(x: CGFloat, y: CGFloat, radius: CGFloat)] = [
        (0.64, 0.62, 0.035),
        (0.68, 0.50, 0.032),
        (0.66, 0.44, 0.030)
    ]
    
    for spot in edgeSpots {
        let spotPath = NSBezierPath(ovalIn: NSRect(
            x: size * spot.x - size * spot.radius,
            y: size * spot.y - size * spot.radius,
            width: size * spot.radius * 2,
            height: size * spot.radius * 2
        ))
        spotPath.fill()
    }
    
    // Restore graphics state
    NSGraphicsContext.current?.restoreGraphicsState()
    
    // Draw mole outline for definition
    let outlineColor = NSColor(red: 0.30, green: 0.18, blue: 0.12, alpha: 0.6)
    outlineColor.setStroke()
    molePath.lineWidth = 3
    molePath.stroke()
    
    // Draw comparison slider line (vertical white line) - 4x thicker for visibility
    NSGraphicsContext.current?.saveGraphicsState()
    
    let sliderPath = NSBezierPath()
    let sliderX = size / 2
    let sliderTop = size * 0.10
    let sliderBottom = size * 0.90
    
    sliderPath.move(to: CGPoint(x: sliderX, y: sliderTop))
    sliderPath.line(to: CGPoint(x: sliderX, y: sliderBottom))
    sliderPath.lineWidth = 24  // 4x thicker (was 6)
    sliderPath.lineCapStyle = .round
    
    // Add shadow to slider for depth
    let sliderShadow = NSShadow()
    sliderShadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
    sliderShadow.shadowOffset = NSSize(width: 0, height: 0)
    sliderShadow.shadowBlurRadius = 12  // Increased shadow for thicker line
    sliderShadow.set()
    
    NSColor.white.setStroke()
    sliderPath.stroke()
    
    // Draw comparison arrows (< >) - 8x larger for maximum visibility
    let arrowSize: CGFloat = 96  // 4x larger (was 24, then 48, now 96)
    let arrowOffset: CGFloat = 100  // Increased offset for much larger arrows
    let center = CGPoint(x: size / 2, y: size / 2)
    
    // Left arrow (<)
    let leftArrow = NSBezierPath()
    leftArrow.move(to: CGPoint(x: center.x - arrowOffset + arrowSize * 0.3, y: center.y - arrowSize * 0.5))
    leftArrow.line(to: CGPoint(x: center.x - arrowOffset - arrowSize * 0.3, y: center.y))
    leftArrow.line(to: CGPoint(x: center.x - arrowOffset + arrowSize * 0.3, y: center.y + arrowSize * 0.5))
    leftArrow.lineWidth = 16  // 8x thicker (was 4, then 16, now 32)
    leftArrow.lineCapStyle = .round
    leftArrow.lineJoinStyle = .round
    
    // Right arrow (>)
    let rightArrow = NSBezierPath()
    rightArrow.move(to: CGPoint(x: center.x + arrowOffset - arrowSize * 0.3, y: center.y - arrowSize * 0.5))
    rightArrow.line(to: CGPoint(x: center.x + arrowOffset + arrowSize * 0.3, y: center.y))
    rightArrow.line(to: CGPoint(x: center.x + arrowOffset - arrowSize * 0.3, y: center.y + arrowSize * 0.5))
    rightArrow.lineWidth = 16  // 8x thicker (was 4, then 16, now 32)
    rightArrow.lineCapStyle = .round
    rightArrow.lineJoinStyle = .round
    
    // Draw arrows
    NSColor.white.setStroke()
    leftArrow.stroke()
    rightArrow.stroke()
    
    NSGraphicsContext.current?.restoreGraphicsState()
    
    image.unlockFocus()
    
    // Create bitmap representation with exact size (avoid Retina 2x scaling)
    let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )
    
    if let bitmapRep = bitmapRep {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        
        // Redraw everything into the bitmap context
        // Background - Medical teal
        let tealColor = NSColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1.0)
        tealColor.setFill()
        NSRect(x: 0, y: 0, width: size, height: size).fill()
        
        // Draw the image into the bitmap context
        image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        
        NSGraphicsContext.restoreGraphicsState()
        
        // Save the bitmap as PNG
        if let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            let outputPath = "../../Nevus/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
            let url = URL(fileURLWithPath: outputPath)
            
            do {
                try pngData.write(to: url)
                print("✅ App icon generated successfully at: \(outputPath)")
                print("📱 Size: 1024x1024 pixels (verified)")
                print("🎨 Design: Organic mole with comparison slider on medical teal background")
                print("   - Left side: Lighter, smoother")
                print("   - Right side: Darker with texture")
                print("   - Vertical white comparison slider with arrows")
            } catch {
                print("❌ Error saving icon: \(error)")
            }
        }
    }
}

// Run the generator
generateAppIcon()

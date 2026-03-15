#!/usr/bin/env swift

import Foundation
import AppKit

// Icon Generator for Nevus App
// Creates a brown mole under a magnifying glass

func generateAppIcon() {
    let size: CGFloat = 1024
    let image = NSImage(size: NSSize(width: size, height: size))
    
    image.lockFocus()
    
    // Background - Light gradient
    let gradient = NSGradient(colors: [
        NSColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1.0),
        NSColor(red: 0.88, green: 0.90, blue: 0.95, alpha: 1.0)
    ])
    gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: 135)
    
    // Draw the mole (brown circle with texture)
    let moleCenter = CGPoint(x: size * 0.5, y: size * 0.52)
    let moleRadius = size * 0.22
    
    // Mole shadow
    let moleShadow = NSShadow()
    moleShadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    moleShadow.shadowOffset = NSSize(width: 0, height: -8)
    moleShadow.shadowBlurRadius = 15
    
    // Main mole body
    let molePath = NSBezierPath(ovalIn: NSRect(
        x: moleCenter.x - moleRadius,
        y: moleCenter.y - moleRadius,
        width: moleRadius * 2,
        height: moleRadius * 2
    ))
    
    moleShadow.set()
    
    // Brown color for mole
    let moleColor = NSColor(red: 0.45, green: 0.30, blue: 0.20, alpha: 1.0)
    moleColor.setFill()
    molePath.fill()
    
    // Add texture to mole (darker spots)
    let darkSpotColor = NSColor(red: 0.35, green: 0.22, blue: 0.15, alpha: 0.6)
    darkSpotColor.setFill()
    
    // Small texture spots
    let spots: [(CGFloat, CGFloat, CGFloat)] = [
        (0.45, 0.55, 0.08),
        (0.52, 0.48, 0.06),
        (0.48, 0.50, 0.05),
        (0.55, 0.52, 0.07),
        (0.50, 0.45, 0.04)
    ]
    
    for (xRatio, yRatio, radiusRatio) in spots {
        let spotPath = NSBezierPath(ovalIn: NSRect(
            x: size * xRatio - moleRadius * radiusRatio,
            y: size * yRatio - moleRadius * radiusRatio,
            width: moleRadius * radiusRatio * 2,
            height: moleRadius * radiusRatio * 2
        ))
        spotPath.fill()
    }
    
    // Draw magnifying glass
    let glassCenter = CGPoint(x: size * 0.62, y: size * 0.38)
    let glassRadius = size * 0.28
    let handleLength = size * 0.20
    let handleWidth = size * 0.05
    
    // Glass rim (outer circle)
    let rimPath = NSBezierPath(ovalIn: NSRect(
        x: glassCenter.x - glassRadius,
        y: glassCenter.y - glassRadius,
        width: glassRadius * 2,
        height: glassRadius * 2
    ))
    
    // Rim shadow
    let rimShadow = NSShadow()
    rimShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    rimShadow.shadowOffset = NSSize(width: 0, height: -6)
    rimShadow.shadowBlurRadius = 12
    rimShadow.set()
    
    // Dark gray rim
    NSColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0).setFill()
    rimPath.fill()
    
    // Glass lens (inner circle with transparency)
    let lensRadius = glassRadius * 0.85
    let lensPath = NSBezierPath(ovalIn: NSRect(
        x: glassCenter.x - lensRadius,
        y: glassCenter.y - lensRadius,
        width: lensRadius * 2,
        height: lensRadius * 2
    ))
    
    // Clear glass with slight blue tint
    NSColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 0.4).setFill()
    lensPath.fill()
    
    // Glass highlight (shine effect)
    let highlightPath = NSBezierPath(ovalIn: NSRect(
        x: glassCenter.x - lensRadius * 0.5,
        y: glassCenter.y + lensRadius * 0.2,
        width: lensRadius * 0.8,
        height: lensRadius * 0.6
    ))
    NSColor.white.withAlphaComponent(0.3).setFill()
    highlightPath.fill()
    
    // Handle
    let handleAngle: CGFloat = .pi * 0.75 // 135 degrees
    let handleStartX = glassCenter.x + cos(handleAngle) * glassRadius
    let handleStartY = glassCenter.y + sin(handleAngle) * glassRadius
    let handleEndX = handleStartX + cos(handleAngle) * handleLength
    let handleEndY = handleStartY + sin(handleAngle) * handleLength
    
    let handlePath = NSBezierPath()
    handlePath.move(to: CGPoint(x: handleStartX, y: handleStartY))
    handlePath.line(to: CGPoint(x: handleEndX, y: handleEndY))
    handlePath.lineWidth = handleWidth
    handlePath.lineCapStyle = .round
    
    // Handle shadow
    let handleShadow = NSShadow()
    handleShadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    handleShadow.shadowOffset = NSSize(width: -3, height: -3)
    handleShadow.shadowBlurRadius = 8
    handleShadow.set()
    
    NSColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1.0).setStroke()
    handlePath.stroke()
    
    image.unlockFocus()
    
    // Save the image
    if let tiffData = image.tiffRepresentation,
       let bitmapImage = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
        
        let outputPath = "Nevus/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        let url = URL(fileURLWithPath: outputPath)
        
        do {
            try pngData.write(to: url)
            print("✅ App icon generated successfully at: \(outputPath)")
            print("📱 Size: 1024x1024 pixels")
            print("🎨 Design: Brown mole under magnifying glass")
        } catch {
            print("❌ Error saving icon: \(error)")
        }
    }
}

// Run the generator
generateAppIcon()

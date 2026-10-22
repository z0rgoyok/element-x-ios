// Reproducible original Tich Connect mark. Run: swift Tools/Scripts/tich-brand.swift
import AppKit

func drawMark(in context: CGContext, size: CGFloat) {
    context.scaleBy(x: size / 1024, y: size / 1024)
    let space = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(colorsSpace: space,
                              colors: [NSColor(srgbRed: 0.02, green: 0.15, blue: 0.20, alpha: 1).cgColor,
                                       NSColor(srgbRed: 0.03, green: 0.38, blue: 0.42, alpha: 1).cgColor] as CFArray,
                              locations: [0, 1])!
    context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 1024, y: 1024), options: [])
    let bubble = CGPath(roundedRect: CGRect(x: 184, y: 252, width: 656, height: 560),
                        cornerWidth: 156, cornerHeight: 156, transform: nil)
    context.setFillColor(NSColor(srgbRed: 0.28, green: 0.94, blue: 0.78, alpha: 1).cgColor)
    context.addPath(bubble)
    context.fillPath()
    context.beginPath()
    context.move(to: CGPoint(x: 266, y: 325))
    context.addLine(to: CGPoint(x: 266, y: 166))
    context.addLine(to: CGPoint(x: 444, y: 288))
    context.closePath()
    context.fillPath()
    context.setStrokeColor(NSColor(srgbRed: 0.02, green: 0.19, blue: 0.24, alpha: 1).cgColor)
    context.setLineWidth(74)
    context.setLineCap(.round)
    context.move(to: CGPoint(x: 365, y: 632))
    context.addLine(to: CGPoint(x: 659, y: 632))
    context.move(to: CGPoint(x: 512, y: 632))
    context.addLine(to: CGPoint(x: 512, y: 418))
    context.strokePath()
}

let bitmap = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
                       bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
drawMark(in: bitmap, size: 1024)
let image = NSBitmapImageRep(cgImage: bitmap.makeImage()!)
try image.representation(using: .png, properties: [:])!.write(to: URL(filePath: "ElementX/Resources/AppIcon.icon/Assets/AppIcon.png"))

var box = CGRect(x: 0, y: 0, width: 110, height: 110)
let pdf = CGContext(URL(filePath: "ElementX/Resources/Assets.xcassets/images/app-logo.imageset/app-logo.pdf") as CFURL,
                    mediaBox: &box, nil)!
pdf.beginPDFPage(nil)
drawMark(in: pdf, size: 110)
pdf.endPDFPage()
pdf.closePDF()

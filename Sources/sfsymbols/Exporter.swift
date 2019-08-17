//
//  Exporter.swift
//  
//
//  Created by Dave DeLong on 8/17/19.
//

import Foundation
import AppKit
import SPMUtility

enum ExportFormat: String, CaseIterable, ArgumentKind {
    
    static var completion: ShellCompletion {
        let values = allCases.map { (value: $0.rawValue, description: $0.rawValue) }
        return .values(values)
    }
    
    init(argument: String) throws {
        if let f = ExportFormat(rawValue: argument) {
            self = f
        } else {
            throw ArgumentConversionError.custom("Unknown format '\(argument)'")
        }
    }
    
    case svg = "svg"
    case iosSwift = "ios-swift"
    case iosObjC = "ios-objc"
    case macosSwift = "macos-swift"
    case macosObjC = "macos-objc"
    case png = "png"
    case pdf = "pdf"
    case iconset = "iconset"
    case iconsetPDF = "iconset-pdf"
    
    var exporter: Exporter {
        switch self {
            case .svg: return SVGExporter()
            case .iosSwift: return iOSSwiftExporter()
            case .iosObjC: return iOSObjCExporter()
            case .macosSwift: return macOSSwiftExporter()
            case .macosObjC: return macOSObjCExporter()
            case .png: return PNGExporter()
            case .pdf: return PDFExporter()
            case .iconset: return IconsetExporter()
            case .iconsetPDF: return PDFAssetCatalog()
        }
    }
}

protocol Exporter {
    func exportGlyphs(in font: Font, to folder: URL) throws
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws
    func data(for glyph: Glyph, in font: Font) -> Data
}

extension Exporter {
    func exportGlyphs(in font: Font, to folder: URL) throws {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory) == false || isDirectory.boolValue == false {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        }
        
        for glyph in font.glyphs {
            try autoreleasepool {
                try exportGlyph(glyph, in: font, to: folder)
            }
        }
    }
}

struct SVGExporter: Exporter {
    
    private func format(_ point: CGPoint) -> String {
        return "\(point.x),\(point.y)"
    }
    
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let name = "\(glyph.fullName).svg"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font)
        try glyphData.write(to: file)
    }
     
    func data(for glyph: Glyph, in font: Font) -> Data {
        var lines = Array<String>()
        if let restriction = glyph.restrictionNote {
            lines.append("<!--")
            lines.append("    " + restriction)
            lines.append("-->")
        }
        
        let direction = glyph.allowsMirroring ? "" : " direction='ltr'"
        lines.append("<svg width='\(glyph.boundingBox.width)px' height='\(glyph.boundingBox.height)px'\(direction) xmlns='http://www.w3.org/2000/svg' version='1.1'>")
        lines.append("<g fill-rule='nonzero' transform='scale(1,-1) translate(0,-\(glyph.boundingBox.height))'>")
        lines.append("<path fill='black' stroke='black' fill-opacity='1.0' stroke-width='\(font.strokeWidth)' d='")
        glyph.enumerateElements { (_, element) in
            switch element {
                case .move(let p): lines.append("    M \(format(p))")
                case .line(let p): lines.append("    L \(format(p))")
                case .quadCurve(let p, let c): lines.append("    Q \(format(p)) \(format(c))")
                case .curve(let p, let c1, let c2): lines.append("    C \(format(p)) \(format(c1)) \(format(c2))")
                case .close: lines.append("    Z")
            }
        }
        lines.append("' />")
        lines.append("</g>")
        lines.append("</svg>")
        
        let svg = lines.joined(separator: "\n")
        
        return Data(svg.utf8)
    }
}

struct iOSSwiftExporter: Exporter {
    
    private func format(_ point: CGPoint) -> String {
        return "CGPoint(x: \(point.x), y: \(point.y))"
    }
    
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let name = "\(glyph.fullName).swift"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font)
        try glyphData.write(to: file)
    }
    
    func data(for glyph: Glyph, in font: Font) -> Data {
        var restriction = ""
        if let r = glyph.restrictionNote {
            restriction = "\n    // \(r)"
        }
        let header = """
        import UIKit

        extension UIBezierPath {
            \(restriction)
            static var \(glyph.identifierName): UIBezierPath {
        
        """
        
        let footer = """

            }

        }
        """
        
        var lines = Array<String>()
        lines.append("let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: \(glyph.boundingBox.width), height: \(glyph.boundingBox.height)))")
        glyph.enumerateElements { (_, element) in
            switch element {
                case .move(let p): lines.append("path.move(to: \(format(p)))")
                case .line(let p): lines.append("path.addLine(to: \(format(p)))")
                case .quadCurve(let p, let c): lines.append("path.addQuadCurve(to: \(format(p)), controlPoint: \(format(c)))")
                case .curve(let p, let c1, let c2): lines.append("path.addCurve(to: \(format(p)), controlPoint1: \(format(c1)), controlPoint2: \(format(c2)))")
                case .close: lines.append("path.close()")
            }
        }
        lines.append("return path")
        
        let body = lines.joined(separator: "\n        ")
        let file = header + "        " + body + footer
        return Data(file.utf8)
    }
}

struct iOSObjCExporter: Exporter {
    
    private func format(_ point: CGPoint) -> String {
        return "CGPoint(x: \(point.x), y: \(point.y))"
    }
    
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let name = "UIBezierPath+\(glyph.fullName).m"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font)
        try glyphData.write(to: file)
        
        var restriction = ""
        if let r = glyph.restrictionNote {
            restriction = "\n// \(r)"
        }
        
        let headerFile = folder.appendingPathComponent("UIBezierPath+\(glyph.fullName).h")
        let header = """
        #import <UIKit/UIKit.h>

        @interface UIBezierPath (\(glyph.identifierName))
        \(restriction)
        @property (class, readonly, nonnull) UIBezierPath *\(glyph.identifierName);
        
        @end
        """
        try Data(header.utf8).write(to: headerFile)
    }
    
    func data(for glyph: Glyph, in font: Font) -> Data {
        let header = """
        #import "UIBezierPath+\(glyph.fullName).h"

        @implementation UIBezierPath (\(glyph.identifierName))
        
        + (UIBezierPath *)\(glyph.identifierName) {
        
        """
        
        let footer = """

        }

        @end
        """
        
        var lines = Array<String>()
        lines.append("UIBezierPath *path = [[UIBezierPath alloc] initWithRect:CGRectMake(x: 0, y: 0, width: \(glyph.boundingBox.width), height: \(glyph.boundingBox.height))];")
        glyph.enumerateElements { (_, element) in
            switch element {
                case .move(let p): lines.append("[path moveToPoint:\(format(p))];")
                case .line(let p): lines.append("[path addLineToPoint:\(format(p))];")
                case .quadCurve(let p, let c): lines.append("[path addQuadCurveToPoint:\(format(p)) controlPoint:\(format(c))];")
                case .curve(let p, let c1, let c2): lines.append("[path addCurveToPoint:\(format(p)) controlPoint1:\(format(c1)) controlPoint2:\(format(c2))];")
                case .close: lines.append("[path close];")
            }
        }
        lines.append("return path;")
        
        let body = lines.joined(separator: "\n    ")
        let file = header + "    " + body + footer
        return Data(file.utf8)
    }
}

struct macOSSwiftExporter: Exporter {
    
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let name = "\(glyph.fullName).swift"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font)
        try glyphData.write(to: file)
    }
    
    private func format(_ point: CGPoint) -> String {
        return "CGPoint(x: \(point.x), y: \(point.y))"
    }
    
    func data(for glyph: Glyph, in font: Font) -> Data {
        var restriction = ""
        if let r = glyph.restrictionNote {
            restriction = "\n    // \(r)"
        }
        
        let header = """
        import AppKit

        extension NSBezierPath {
            \(restriction)
            static var \(glyph.identifierName): NSBezierPath {
        
        """
        
        let footer = """

            }

        }
        """
        
        var lines = Array<String>()
        lines.append("let path = NSBezierPath(rect: NSRect(x: 0, y: 0, width: \(glyph.boundingBox.width), height: \(glyph.boundingBox.height)))")
        glyph.enumerateElements { (current, element) in
            switch element {
                case .move(let p): lines.append("path.move(to: \(format(p)))")
                case .line(let p): lines.append("path.line(to: \(format(p)))")
                case .quadCurve(let p, let c):
                    // NSBezierPath does not have a quadratic curve method
                    let (c1, c2) = NSBezierPath.cubicPointsFromQuadratic(currentPoint: current!, destinationPoint: p, controlPoint: c)
                    lines.append("path.curve(to: \(format(p)), controlPoint1: \(format(c1)), controlPoint2: \(format(c2)))")
                case .curve(let p, let c1, let c2): lines.append("path.curve(to: \(format(p)), controlPoint1: \(format(c1)), controlPoint2: \(format(c2)))")
                case .close: lines.append("path.close()")
            }
        }
        lines.append("return path")
        
        let body = lines.joined(separator: "\n        ")
        let file = header + "        " + body + footer
        return Data(file.utf8)
    }
    
}

struct macOSObjCExporter: Exporter {
    
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let name = "NSBezierPath+\(glyph.fullName).m"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font)
        try glyphData.write(to: file)
        
        var restriction = ""
        if let r = glyph.restrictionNote {
            restriction = "\n// \(r)"
        }
        
        let headerFile = folder.appendingPathComponent("NSBezierPath+\(glyph.fullName).h")
        let header = """
        #import <AppKit/AppKit.h>
        \(restriction)
        @interface NSBezierPath (\(glyph.identifierName))
        
        @property (class, readonly, nonnull) NSBezierPath *\(glyph.identifierName);
        
        @end
        """
        try Data(header.utf8).write(to: headerFile)
    }
    
    private func format(_ point: CGPoint) -> String {
        return "CGPoint(x: \(point.x), y: \(point.y))"
    }
    
    func data(for glyph: Glyph, in font: Font) -> Data {
        let header = """
        #import "NSBezierPath+\(glyph.fullName).h"

        @implementation NSBezierPath (\(glyph.identifierName))
        
        + (NSBezierPath *)\(glyph.identifierName) {
        
        """
        
        let footer = """

        }

        @end
        """
        
        var lines = Array<String>()
        lines.append("NSBezierPath *path = [[NSBezierPath alloc] initWithRect:NSRectMake(x: 0, y: 0, width: \(glyph.boundingBox.width), height: \(glyph.boundingBox.height))];")
        glyph.enumerateElements { (current, element) in
            switch element {
                case .move(let p): lines.append("[path moveToPoint:\(format(p))];")
                case .line(let p): lines.append("[path lineToPoint:\(format(p))];")
                case .quadCurve(let p, let c):
                    // NSBezierPath does not have a quadratic curve method
                    let (c1, c2) = NSBezierPath.cubicPointsFromQuadratic(currentPoint: current!, destinationPoint: p, controlPoint: c)
                    lines.append("[path curveToPoint:\(format(p)) controlPoint1:\(format(c1)) controlPoint2:\(format(c2))];")
                case .curve(let p, let c1, let c2): lines.append("[path curveToPoint:\(format(p)) controlPoint1:\(format(c1)) controlPoint2:\(format(c2))];")
                case .close: lines.append("[path close];")
            }
        }
        lines.append("return path;")
        
        let body = lines.joined(separator: "\n    ")
        let file = header + "    " + body + footer
        return Data(file.utf8)
    }
    
}

struct PNGExporter: Exporter {
    
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let name = "\(glyph.fullName).png"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font)
        try glyphData.write(to: file)
    }
    
    func data(for glyph: Glyph, in font: Font, scale: CGFloat) -> Data {
        var size = glyph.boundingBox.size
        size.width *= scale
        size.height *= scale
        let image = NSImage(size: size, flipped: false, drawingHandler: { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.scaleBy(x: scale, y: scale)
            
            context.setShouldAntialias(true)
            context.addPath(glyph.cgPath)

            context.setFillColor(NSColor.black.cgColor)
            context.fillPath()
            return true
        })
        
        return image.pngData
    }
    
    func data(for glyph: Glyph, in font: Font) -> Data {
        return data(for: glyph, in: font, scale: 1.0)
    }
    
}

struct IconsetExporter: Exporter {

    private let png = PNGExporter()
    
    func exportGlyphs(in font: Font, to folder: URL) throws {
        let assetFolder = folder.appendingPathComponent("SFSymbols.xcassets")
        try FileManager.default.createDirectory(at: assetFolder, withIntermediateDirectories: true, attributes: nil)
        
        let contentsURL = assetFolder.appendingPathComponent("Contents.json")
        let contentsJSON = """
{
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
"""
        try Data(contentsJSON.utf8).write(to: contentsURL)
        
        for glyph in font.glyphs {
            try autoreleasepool {
                try exportGlyph(glyph, in: font, to: assetFolder)
            }
        }
    }
    
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let iconset = folder.appendingPathComponent("\(glyph.fullName).iconset")
        try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true, attributes: nil)
        let contents = """
{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "\(glyph.fullName)@1x.png",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "filename" : "\(glyph.fullName)@2x.png",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "filename" : "\(glyph.fullName)@3x.png",
      "scale" : "3x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
"""
        let contentsURL = iconset.appendingPathComponent("Contents.json")
        try Data(contents.utf8).write(to: contentsURL)
        
        for scale in 1...3 {
            let data = png.data(for: glyph, in: font, scale: CGFloat(scale))
            let file = iconset.appendingPathComponent("\(glyph.fullName)@\(scale)x.png")
            try data.write(to: file)
        }
    }
    
    func data(for glyph: Glyph, in font: Font) -> Data { fatalError() }
    
}

struct PDFExporter: Exporter {
    
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let name = "\(glyph.fullName).pdf"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font)
        try glyphData.write(to: file)
    }
    
    func data(for glyph: Glyph, in font: Font) -> Data {
        let destination = NSMutableData()
        guard let dataConsumer = CGDataConsumer(data: destination as CFMutableData) else { return Data() }
        
        var box = glyph.boundingBox
        guard let pdf = CGContext(consumer: dataConsumer, mediaBox: &box, nil) else { return Data() }
        
        let pageInfo = [
            kCGPDFContextMediaBox: Data(bytes: &box, count: MemoryLayout<CGRect>.size) as CFData
        ]
        pdf.beginPDFPage(pageInfo as CFDictionary)
        pdf.setShouldAntialias(true)
        pdf.addPath(glyph.cgPath)

        pdf.setFillColor(NSColor.black.cgColor)
        pdf.fillPath()
        pdf.endPDFPage()
        pdf.closePDF()
        
        return destination as Data
    }
    
}

struct PDFAssetCatalog: Exporter {
    
    let pdf = PDFExporter()
    
    func exportGlyphs(in font: Font, to folder: URL) throws {
        let assetFolder = folder.appendingPathComponent("SFSymbols.xcassets")
        try FileManager.default.createDirectory(at: assetFolder, withIntermediateDirectories: true, attributes: nil)
        
        let contentsURL = assetFolder.appendingPathComponent("Contents.json")
        let contentsJSON = """
{
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
"""
        try Data(contentsJSON.utf8).write(to: contentsURL)
        
        for glyph in font.glyphs {
            try autoreleasepool {
                try exportGlyph(glyph, in: font, to: assetFolder)
            }
        }
    }
    
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let imageset = folder.appendingPathComponent("\(glyph.fullName).imageset")
        try FileManager.default.createDirectory(at: imageset, withIntermediateDirectories: true, attributes: nil)
        let mirrors = glyph.allowsMirroring ? "" : ",\n      \"language-direction\" : \"left-to-right\""
        let contents = """
{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "\(glyph.fullName).pdf"\(mirrors)
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  },
  "properties" : {
    "preserves-vector-representation" : true
  }
}
"""
        let contentsURL = imageset.appendingPathComponent("Contents.json")
        try Data(contents.utf8).write(to: contentsURL)
        
        let pdfData = data(for: glyph, in: font)
        let file = imageset.appendingPathComponent("\(glyph.fullName).pdf")
        try pdfData.write(to: file)
    }
    
    func data(for glyph: Glyph, in font: Font) -> Data {
        return pdf.data(for: glyph, in: font)
    }
    
}

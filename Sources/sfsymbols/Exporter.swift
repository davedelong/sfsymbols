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
    case iconset = "iconset"
    
    var exporter: Exporter {
        switch self {
            case .svg: return SVGExporter()
            case .iosSwift: return iOSSwiftExporter()
            case .iosObjC: return iOSObjCExporter()
            case .macosSwift: return macOSSwiftExporter()
            case .macosObjC: return macOSObjCExporter()
            case .png: return PNGExporter()
            case .iconset: return IconsetExporter()
        }
    }
}

protocol Exporter {
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
            try exportGlyph(glyph, in: font, to: folder)
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
        glyph.enumerateElements { element in
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
        glyph.enumerateElements { element in
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
        glyph.enumerateElements { element in
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
        glyph.enumerateElements { element in
            switch element {
                case .move(let p): lines.append("path.move(to: \(format(p)))")
                case .line(let p): lines.append("path.line(to: \(format(p)))")
                case .quadCurve(let p, let c): lines.append("path.addQuadCurve(to: \(format(p)), controlPoint: \(format(c)))")
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
        glyph.enumerateElements { element in
            switch element {
                case .move(let p): lines.append("[path moveToPoint:\(format(p))];")
                case .line(let p): lines.append("[path lineToPoint:\(format(p))];")
                case .quadCurve(let p, let c): lines.append("[path addQuadCurveToPoint:\(format(p)) controlPoint:\(format(c))];")
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
    
    func data(for glyph: Glyph, in font: Font) -> Data {
        let image = NSImage(size: glyph.boundingBox.size, flipped: false, drawingHandler: { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            
            context.setShouldAntialias(true)
            context.addPath(glyph.cgPath)

            context.setFillColor(NSColor.black.cgColor)
            context.fillPath()
            return true
        })
        
        return image.tiffRepresentation ?? Data()
    }
    
}

struct IconsetExporter: Exporter {
    
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        fatalError()
    }
    
    func data(for glyph: Glyph, in font: Font) -> Data {
        fatalError()
    }
    
}

//
//  macOSExporter.swift
//  
//
//  Created by Dave DeLong on 9/19/19.
//

import Cocoa

public struct macOSSwiftExporter: Exporter {
    
    public func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let name = "\(glyph.fullName).swift"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font)
        try glyphData.write(to: file)
    }
    
    private func format(_ point: CGPoint) -> String {
        return "CGPoint(x: \(point.x), y: \(point.y))"
    }
    
    public func data(for glyph: Glyph, in font: Font) -> Data {
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

public struct macOSObjCExporter: Exporter {
    
    public func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
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
    
    public func data(for glyph: Glyph, in font: Font) -> Data {
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

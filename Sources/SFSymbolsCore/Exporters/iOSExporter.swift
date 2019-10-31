//
//  iOSExporter.swift
//  
//
//  Created by Dave DeLong on 9/19/19.
//

import Foundation

public struct iOSSwiftExporter: Exporter {
    
    private func format(_ point: CGPoint) -> String {
        return "CGPoint(x: \(point.x), y: \(point.y))"
    }
    
    public func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let name = "\(glyph.fullName).swift"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font)
        try glyphData.write(to: file)
    }
    
    public func data(for glyph: Glyph, in font: Font) -> Data {
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

public struct iOSObjCExporter: Exporter {
    
    private func format(_ point: CGPoint) -> String {
        return "CGPoint(x: \(point.x), y: \(point.y))"
    }
    
    public func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
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
    
    public func data(for glyph: Glyph, in font: Font) -> Data {
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

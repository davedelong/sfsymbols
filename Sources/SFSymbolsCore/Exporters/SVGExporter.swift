//
//  SVGExporter.swift
//  
//
//  Created by Dave DeLong on 9/19/19.
//

import Foundation

public struct SVGExporter: Exporter {
    
    private func format(_ point: CGPoint) -> String {
        return "\(point.x),\(point.y)"
    }
    
    public func exportGlyph(_ glyph: Glyph, in font: Font, colored hexColor: String, to folder: URL) throws {
        let name = "\(glyph.fullName).svg"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font, colored: hexColor)
        try glyphData.write(to: file)
    }
     
    public func data(for glyph: Glyph, in font: Font, colored hexColor: String) -> Data {
        var lines = Array<String>()
        if let restriction = glyph.restrictionNote {
            lines.append("<!--")
            lines.append("    " + restriction)
            lines.append("-->")
        }
        
        let direction = glyph.allowsMirroring ? "" : " direction='ltr'"
        lines.append("<svg width='\(glyph.boundingBox.width)px' height='\(glyph.boundingBox.height)px'\(direction) xmlns='http://www.w3.org/2000/svg' version='1.1'>")
        lines.append("<g fill-rule='nonzero' transform='scale(1,-1) translate(0,-\(glyph.boundingBox.height))'>")
        let normalizedColor = normalizeColor(hexColor)
        lines.append("<path fill='\(normalizedColor)' stroke='\(normalizedColor)' fill-opacity='1.0' stroke-width='\(font.strokeWidth)' d='")
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
  
    /// ensures the hexColor starts with `#` and is the proper length, else returns `black`
    private func normalizeColor(_ hexColor: String) -> String {
        // make sure the hex value starts with `#`
        let normalizedHexColor = hexColor.hasPrefix("#") ? hexColor : "#\(hexColor)"
        // make sure the hex value is either 6 or 8 length plus the preceeding #
        if normalizedHexColor.count == 7 || normalizedHexColor.count == 9 {
            return normalizedHexColor
        } else {
            return "black"
        }
    }
}

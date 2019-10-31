//
//  SVGExporter.swift
//  
//
//  Created by Dave DeLong on 9/19/19.
//

import Foundation

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

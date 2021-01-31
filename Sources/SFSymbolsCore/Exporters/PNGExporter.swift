//
//  PNGExporter.swift
//  
//
//  Created by Dave DeLong on 9/19/19.
//

import Cocoa

public struct PNGExporter: Exporter {
    
    public func exportGlyph(_ glyph: Glyph, in font: Font, colored hexColor: String, to folder: URL) throws {
        let name = "\(glyph.fullName).png"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font, colored: hexColor)
        try glyphData.write(to: file)
    }
    
    public func data(for glyph: Glyph, in font: Font, scale: CGFloat, color: String) -> Data {
        var size = glyph.boundingBox.size
        size.width *= scale
        size.height *= scale
        let image = NSImage(size: size, flipped: false, drawingHandler: { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.scaleBy(x: scale, y: scale)
            
            context.setShouldAntialias(true)
            context.addPath(glyph.cgPath)

            context.setFillColor(NSColor(hexString: color).cgColor)
            context.fillPath()
            return true
        })
        
        return image.pngData
    }
    
    public func data(for glyph: Glyph, in font: Font, colored hexColor: String) -> Data {
        return data(for: glyph, in: font, scale: 1.0, color: hexColor)
    }
    
}

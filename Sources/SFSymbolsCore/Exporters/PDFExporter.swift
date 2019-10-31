//
//  PDFExporter.swift
//  
//
//  Created by Dave DeLong on 9/19/19.
//

import Cocoa

public struct PDFExporter: Exporter {
    
    public func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        let name = "\(glyph.fullName).pdf"
        let file = folder.appendingPathComponent(name)
        let glyphData = data(for: glyph, in: font)
        try glyphData.write(to: file)
    }
    
    public func data(for glyph: Glyph, in font: Font) -> Data {
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

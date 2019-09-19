//
//  IconsetExporter.swift
//  
//
//  Created by Dave DeLong on 9/19/19.
//

import Foundation

struct IconsetExporter: Exporter {

    private let png = PNGExporter()
    
    func exportGlyphs(in font: Font, matching pattern: String, to folder: URL) throws {
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
            guard fnmatch(pattern, glyph.fullName, 0) == 0 else { continue }
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

struct PDFAssetCatalog: Exporter {
    
    let pdf = PDFExporter()
    
    func exportGlyphs(in font: Font, matching pattern: String, to folder: URL) throws {
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
            guard fnmatch(pattern, glyph.fullName, 0) == 0 else { continue }
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

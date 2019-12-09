//
//  IconsetExporter.swift
//  
//
//  Created by Dave DeLong on 9/19/19.
//

import Foundation

public struct IconsetExporter: Exporter {

    private let png = PNGExporter()
    
    public func exportGlyphs(in font: Font, using options: ExportOptions) throws {
        let assetFolder = options.outputFolder.appendingPathComponent("SFSymbols.xcassets")
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
        
        for glyph in font.glyphs(matching: options.matchPattern) {
            try autoreleasepool {
                try [ThemeMode.light, ThemeMode.dark].forEach {
                    try exportGlyph(glyph, in: font, to: assetFolder, theme: $0)
                }
            }
        }
    }
    
    public func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL, theme: ThemeMode) throws {
        let iconset = folder.appendingPathComponent("\(glyph.fullName).iconset")
        try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true, attributes: nil)
        let contents = """
{
  "images" : [
    {
      "idiom" : "universal",
        "filename" : "\(glyph.fullName)\(theme == .light ? "" : ".\(theme)")@1x.png",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "filename" : "\(glyph.fullName)\(theme == .light ? "" : ".\(theme)")@2x.png",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "filename" : "\(glyph.fullName)\(theme == .light ? "" : ".\(theme)")@3x.png",
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
            let data = png.data(for: glyph, in: font, scale: CGFloat(scale), theme: theme)
            let file = iconset.appendingPathComponent("\(glyph.fullName)@\(scale)x.png")
            try data.write(to: file)
        }
    }
    
    public func data(for glyph: Glyph, in font: Font, theme: ThemeMode) -> Data { fatalError() }
    
}

public struct PDFAssetCatalog: Exporter {
    let pdf = PDFExporter()
    
    public func exportGlyphs(in font: Font, using options: ExportOptions) throws {
        let assetFolder = options.outputFolder.appendingPathComponent("SFSymbols.xcassets")
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
        
        for glyph in font.glyphs(matching: options.matchPattern) {
            try [ThemeMode.light, ThemeMode.dark].forEach {
                try exportGlyph(glyph, in: font, to: assetFolder, theme: $0)
            }
        }
    }
    
    private func writeContents(glyph: Glyph, imageset: URL) throws {
        let mirrors = glyph.allowsMirroring ? "" : ",\n\t\t\t\"language-direction\" : \"left-to-right\""
        let contents = """
{
    "images" : [
        {
            "idiom" : "universal",
            "filename" : "\(glyph.fullName).pdf"\(mirrors)
        },
        {
            "idiom" : "universal",
            "filename" : "\(glyph.fullName).dark.pdf"\(mirrors),
            "appearances" : [
                {
                    "appearance" : "luminosity",
                    "value" : "dark"
                }
            ]
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
    }
    
    public func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL, theme: ThemeMode) throws {
        let imageset = folder.appendingPathComponent("\(glyph.fullName).imageset")
        try FileManager.default.createDirectory(at: imageset, withIntermediateDirectories: true, attributes: nil)
        
        if theme == .dark {
            try writeContents(glyph: glyph, imageset: imageset)
        }
        
        let pdfData = data(for: glyph, in: font, theme: theme)
        let file = imageset.appendingPathComponent("\(glyph.fullName)\(theme == .light ? "" : ".dark").pdf")
        try pdfData.write(to: file)
    }
    
    public func data(for glyph: Glyph, in font: Font, theme: ThemeMode) -> Data {
        return pdf.data(for: glyph, in: font, theme: theme)
    }
    
}

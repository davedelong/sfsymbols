//
//  Exporter.swift
//  
//
//  Created by Dave DeLong on 8/17/19.
//

import Foundation
import AppKit

public enum ExportFormat: String, CaseIterable {
    
    case svg = "svg"
    case iosSwift = "ios-swift"
    case iosObjC = "ios-objc"
    case macosSwift = "macos-swift"
    case macosObjC = "macos-objc"
    case png = "png"
    case pdf = "pdf"
    case iconset = "iconset"
    case iconsetPDF = "iconset-pdf"
    case imageset = "imageset"
    
    public var exporter: Exporter {
        switch self {
            case .svg: return SVGExporter()
            case .iosSwift: return iOSSwiftExporter()
            case .iosObjC: return iOSObjCExporter()
            case .macosSwift: return macOSSwiftExporter()
            case .macosObjC: return macOSObjCExporter()
            case .png: return PNGExporter()
            case .pdf: return PDFExporter()
            case .iconset: return SetExporter(ext: "iconset")
            case .iconsetPDF: return PDFAssetCatalog()
            case .imageset: return SetExporter(ext: "imageset")
        }
    }
}

public protocol Exporter {
    func exportGlyphs(in font: Font, using options: ExportOptions) throws
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws
    func data(for glyph: Glyph, in font: Font) -> Data
}

extension Exporter {
    public func exportGlyphs(in font: Font, using options: ExportOptions) throws {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: options.outputFolder.path, isDirectory: &isDirectory) == false || isDirectory.boolValue == false {
            try FileManager.default.createDirectory(at: options.outputFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        for glyph in font.glyphs(matching: options.matchPattern) {
            try autoreleasepool {
                try exportGlyph(glyph, in: font, to: options.outputFolder)
            }
        }
    }
}

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
    case pdf = "pdf"
    case iconset = "iconset"
    case iconsetPDF = "iconset-pdf"
    
    var exporter: Exporter {
        switch self {
            case .svg: return SVGExporter()
            case .iosSwift: return iOSSwiftExporter()
            case .iosObjC: return iOSObjCExporter()
            case .macosSwift: return macOSSwiftExporter()
            case .macosObjC: return macOSObjCExporter()
            case .png: return PNGExporter()
            case .pdf: return PDFExporter()
            case .iconset: return IconsetExporter()
            case .iconsetPDF: return PDFAssetCatalog()
        }
    }
}

protocol Exporter {
    func exportGlyphs(in font: Font, using options: ExportOptions) throws
    func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws
    func data(for glyph: Glyph, in font: Font) -> Data
}

extension Exporter {
    func exportGlyphs(in font: Font, using options: ExportOptions) throws {
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

//
//  File.swift
//  
//
//  Created by Dave DeLong on 10/31/19.
//

import Foundation
import SFSymbolsCore
//import SPMUtility

enum ArgumentParserError: Error {
    case conversionToFontFamily(String)
    case conversionToFontVariant(String)
    case conversionToFontWeight(String)
    case conversionToGlyphSize(String)
    case conversionToExportFormat(String)
    case fontLocationString(String)
}

func toFontFamily(_ string: String) throws -> Font.Family {
    guard let family = Font.Family(rawValue: string) else {
        throw ArgumentParserError.conversionToFontFamily(string)
    }
    return family
}

func toFontVariant(_ string: String) throws -> Font.Variant {
    guard let variant = Font.Variant(rawValue: string) else {
        throw ArgumentParserError.conversionToFontVariant(string)
    }
    return variant
}

func toFontWeight(_ string: String) throws -> Font.Weight {
    guard let pair = Font.Weight.knownWeights.first(where: { $0.0 == string }) else {
        throw ArgumentParserError.conversionToFontWeight(string)
    }
    return pair.1
}

func toGlyphSize(_ string: String) throws -> Glyph.Size {
    guard let size = Glyph.Size(rawValue: string) else {
        throw ArgumentParserError.conversionToGlyphSize(string)
    }
    return size
}

func toExportFormat(_ string: String) throws -> ExportFormat {
    guard let format = ExportFormat(rawValue: string) else {
        throw ArgumentParserError.conversionToExportFormat(string)
    }
    return format
}

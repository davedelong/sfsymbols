//
//  Parser.swift
//  
//
//  Created by Dave DeLong on 10/31/19.
//

import Foundation
import SPMUtility
import SFSymbolsCore

struct Configuration {
    
    let exportOptions: ExportOptions
    let exporter: Exporter
    let font: Font
 
    func run() throws {
        try exporter.exportGlyphs(in: font, using: exportOptions)
    }
    
}

func parseConfiguration(_ arguments: Array<String>) throws -> Configuration {
    let parser = ArgumentParser(usage: "<options>", overview: "Export symbols from the SF Symbols font")

    let fontFile: OptionArgument<PathArgument> = parser.add(option: "--font-file", kind: PathArgument.self, usage: "A path to the SFSymbols ttf file. If omitted, the font will be located in a copy of SF Symbols.app")
    let fontFamily: OptionArgument<Font.Family> = parser.add(option: "--font-family", kind: Font.Family.self, usage: "The family of SF font to use. Default value: 'Pro'")
    let fontVariant: OptionArgument<Font.Variant> = parser.add(option: "--font-variant", kind: Font.Variant.self, usage: "The variant of SF font to use. Default value: 'Display'")
    let fontWeight: OptionArgument<Font.Weight> = parser.add(option: "--font-weight", kind: Font.Weight.self, usage: "The weight of the SFSymbols font to use. Default value: 'regular'")
    let fontSize: OptionArgument<Int> = parser.add(option: "--font-size", kind: Int.self, usage: "The size in points to use when exporting symbols. Default value: '44'")
    let symbolSize: OptionArgument<Glyph.Size> = parser.add(option: "--symbol-size", kind: Glyph.Size.self, usage: "The size of symbol to use. Default value: 'medium'")
    let symbolName: OptionArgument<String> = parser.add(option: "--symbol-name", kind: String.self, usage: "A pattern to limit which symbols are exported. Example: '*.fill' or '*cloud*'. Default value: '*' (all symbols)")

    let format: OptionArgument<ExportFormat> = parser.add(option: "--format", kind: ExportFormat.self, usage: "The formatter to use when exporting. Default value: 'svg'")
    let outputFolder: OptionArgument<PathArgument> = parser.add(option: "--output", kind: PathArgument.self, usage: "A path to the folder where symbols will be exported. If omitted, the current directory will be used")

    let verbose: OptionArgument<Bool> = parser.add(option: "--verbose", kind: Bool.self, usage: "Log verbose information about how exporting is proceeding")
    
    
    let parsed = try parser.parse(arguments)
    
    let exportOptions = ExportOptions(verbose: parsed.get(verbose) ?? false,
                                      outputFolder: parsed.get(outputFolder)?.path.asURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
                                      matchPattern: parsed.get(symbolName) ?? "*")
    
    let exportFormat = parsed.get(format) ?? .svg
    let exporter = exportFormat.exporter
    
    let fontDescriptor = Font.Descriptor(family: parsed.get(fontFamily) ?? .pro,
                                         variant: parsed.get(fontVariant) ?? .display,
                                         weight: parsed.get(fontWeight) ?? .regular,
                                         fontSize: CGFloat(parsed.get(fontSize) ?? 44),
                                         glyphSize: parsed.get(symbolSize) ?? .medium)
    
    let overrideFont = parsed.get(fontFile)?.path.asURL
    
    guard let font = Font.bestFontMatching(url: overrideFont, descriptor: fontDescriptor) else {
        throw ArgumentConversionError.custom("Unable to locate suitable SF Symbols font")
    }
    
    return Configuration(exportOptions: exportOptions, exporter: exporter, font: font)
}

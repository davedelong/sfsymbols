//
//  Parser.swift
//
//
//  Created by Dave DeLong on 10/31/19.
//

import Foundation
import ArgumentParser
import SFSymbolsCore

struct Configuration {

    let exportOptions: ExportOptions
    let exporter: Exporter
    let font: Font

    func run() throws {
        try exporter.exportGlyphs(in: font, using: exportOptions)
    }

}

struct SFSymbols: ParsableCommand {

    static var configuration = CommandConfiguration(
        abstract: "Export symbols from the SF Symbols font")

    @Option(help: "A path to the SFSymbols ttf file. If omitted, the font will be located in a copy of SF Symbols.app")
    var fontFile: String?

    @Option(help: "The family of SF font to use",transform: toFontFamily)
    var fontFamily: Font.Family = .Pro

    @Option(help: "The family of SF font to use",transform: toFontVariant)
    var fontVariant: Font.Variant = .Display

    @Option(help: "The weight of the SFSymbols font to use",transform: toFontWeight)
    var fontWeight: Font.Weight = Font.Weight.regular

    @Option(help: "The size of symbol to use.")
    var fontSize: Int = 44

    @Option(help: "The size of symbol to use",transform: toGlyphSize)
    var symbolSize: Glyph.Size = .medium

    @Option(help: "A pattern to limit which symbols are exported. Example: '*.fill' or '*cloud*'")
    var symbolName: String = "*"

    @Option(help: "The formatter to use when exporting",transform: toExportFormat)
    var format: ExportFormat = .svg

    @Option(help: "A path to the folder where symbols will be exported.")
    var output: String = "."

    @Flag(help: "Log verbose information about how exporting is proceeding")
	var verbose: Bool = false

    func constructConfiguration() throws -> Configuration {
        let exportOptions = ExportOptions(
            verbose: verbose,
            outputFolder: URL(fileURLWithPath: output),
            matchPattern: symbolName)
        let fontDescriptor = Font.Descriptor(
            family: fontFamily,
            variant: fontVariant,
            weight: fontWeight,
            fontSize: CGFloat(fontSize),
            glyphSize: symbolSize)

        var overrideFontPath: URL?
        if let fontFile = fontFile {
            overrideFontPath = URL(fileURLWithPath: fontFile)
        }
        guard let font = Font.bestFontMatching(url: overrideFontPath,
                                               descriptor: fontDescriptor) else {
            throw ArgumentParserError.fontLocationString("Unable to locate suitable SF Symbols font")
        }

        let configuration = Configuration(exportOptions: exportOptions, exporter: format.exporter, font: font)
        return configuration
    }
}

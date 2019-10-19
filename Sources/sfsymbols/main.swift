import Foundation
import SPMUtility

// The first argument is always the executable, drop it
let arguments = Array(CommandLine.arguments.dropFirst())

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

func export(using arguments: ArgumentParser.Result) throws {
    let shouldBeVerbose = arguments.get(verbose) ?? false
    
    let providedFile = arguments.get(fontFile)?.path.asURL
    
    let family = arguments.get(fontFamily) ?? .pro
    let variant = arguments.get(fontVariant) ?? .display
    let weight = arguments.get(fontWeight) ?? .regular
    let size = arguments.get(fontSize) ?? 44
    let glyphSize = arguments.get(symbolSize) ?? .medium
    let pattern = arguments.get(symbolName) ?? "*"
    
    let descriptor = Font.Descriptor(family: family, variant: variant, weight: weight, fontSize: CGFloat(size), glyphSize: glyphSize)
    
    guard let font = Font.bestFontMatching(url: providedFile, descriptor: descriptor) else {
        throw ArgumentConversionError.custom("Unable to locate suitable SF Symbols font")
    }
    
    let exportFormat = arguments.get(format) ?? .svg
    let folderURL = arguments.get(outputFolder)?.path.asURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    
    let options = ExportOptions(verbose: shouldBeVerbose, outputFolder: folderURL, matchPattern: pattern)
    
    let exporter = exportFormat.exporter
    try exporter.exportGlyphs(in: font, using: options)
}

do {
    let parsedArguments = try parser.parse(arguments)
    try export(using: parsedArguments)
} catch let error as ArgumentParserError {
    print(error.description)
} catch let error {
    print(error.localizedDescription)
}

import Foundation
import SPMUtility

// The first argument is always the executable, drop it
let arguments = Array(CommandLine.arguments.dropFirst())

let parser = ArgumentParser(usage: "<options>", overview: "Export symbols from the SF Symbols font")

let fontFile: OptionArgument<PathArgument> = parser.add(option: "--font-file", kind: PathArgument.self, usage: "A path to the SFSymbols ttf file. If omitted, the font will be located in a copy of SF Symbols.app")
let fontWeight: OptionArgument<Font.Weight> = parser.add(option: "--font-weight", kind: Font.Weight.self, usage: "The weight of the SFSymbols font to use. Default value: 'regular'")
let fontSize: OptionArgument<Int> = parser.add(option: "--font-size", kind: Int.self, usage: "The size in points to use when exporting symbols. Default value: '44'")
let glyphList: OptionArgument<PathArgument> = parser.add(option: "--list", kind: PathArgument.self, usage: "A path to the list of symbols you want to create.")
let symbolSize: OptionArgument<Glyph.Size> = parser.add(option: "--symbol-size", kind: Glyph.Size.self, usage: "Ths size of symbol to use. Default value: 'medium'")

let format: OptionArgument<ExportFormat> = parser.add(option: "--format", kind: ExportFormat.self, usage: "The formatter to use when exporting. Default value: 'svg'")
let outputFolder: OptionArgument<PathArgument> = parser.add(option: "--output", kind: PathArgument.self, usage: "A path to the folder where symbols will be exported. If omitted, the current directory will be used")

func export(using arguments: ArgumentParser.Result) throws {
    let providedFile = arguments.get(fontFile)
    var resolvedFontFile = providedFile?.path.asURL
    if resolvedFontFile == nil {
        resolvedFontFile = Font.sfsymbolsFonts().first
    }
    
    guard let fontFile = resolvedFontFile else {
        throw ArgumentConversionError.custom("Unable to locate SF Symbols font file")
    }
    
    var list: GlyphList? = nil
    if let listPath = arguments.get(glyphList) {
      list = try GlyphList.list(listPath)
    }
  
    let weight = arguments.get(fontWeight) ?? .regular
    let size = arguments.get(fontSize) ?? 44
    let glyphSize = arguments.get(symbolSize) ?? .medium
    
    guard let font = Font(url: fontFile,
                          size: CGFloat(size),
                          glyphSize: glyphSize,
                          weight: weight,
                          list: list) else {
        throw ArgumentConversionError.custom("Unable to load SF Symbols font")
    }
    
    let exportFormat = arguments.get(format) ?? .svg
    let folder = arguments.get(outputFolder) ?? (try? PathArgument(argument: FileManager.default.currentDirectoryPath))
    guard let folderURL = folder?.path.asURL else {
        throw ArgumentConversionError.custom("Missing output folder")
    }
    
    let exporter = exportFormat.exporter
    try exporter.exportGlyphs(in: font, to: folderURL)
}

do {
    let parsedArguments = try parser.parse(arguments)
    try export(using: parsedArguments)
} catch let error as ArgumentParserError {
    print(error.description)
} catch let error {
    print(error.localizedDescription)
}

//
//  Font.swift
//  
//
//  Created by Dave DeLong on 8/16/19.
//

import Foundation
import CoreServices
import AppKit
import CommonCrypto
import SPMUtility

// SPMUtility declares its own URL type, but we want "URL" to mean Foundation's version
typealias URL = Foundation.URL

struct Font {
    typealias Weight = NSFont.Weight
    
    private let font: CTFont
    
    let glyphs: Array<Glyph>
    let weight: Weight
    let size: CGFloat
    
    var strokeWidth: CGFloat {
        return 1.0
    }
    
    static func sfsymbolsFonts() -> Array<URL> {
        let maybeCFURLs = LSCopyApplicationURLsForBundleIdentifier("com.apple.SFSymbols" as CFString, nil)?.takeRetainedValue()
        
        guard let cfURLs = maybeCFURLs as? Array<URL> else { return [] }
        
        return cfURLs.compactMap { url -> URL? in
            guard let appBundle = Bundle(url: url) else { return nil }
            return appBundle.url(forResource: "SFSymbolsFallback", withExtension: "ttf")
        }
    }
    
    init?(url: URL, size: CGFloat, glyphSize: Glyph.Size, weight: Weight) {
        guard let provider = CGDataProvider(url: url as CFURL) else { return nil }
        guard let cgFont = CGFont(provider) else { return nil }
        
        let attributes = [
            kCTFontTraitsAttribute: [
                kCTFontWeightTrait: weight.rawValue
            ]
        ]
        let ctAttributes = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        let font = CTFontCreateWithGraphicsFont(cgFont, size, nil, ctAttributes)
        
        guard let data = CTFontCopyDecodedSYMPData(font) else { return nil }
        guard let csv = String(data: data, encoding: .utf8) else { return nil }
        
        // drop the first and last lines (headers + summary, respectively)
        let csvLines = csv.components(separatedBy: "\r\n").dropFirst().dropLast()
        
        self.font = font
        self.weight = weight
        self.size = size
        self.glyphs = csvLines.compactMap { line -> Glyph? in
            return Glyph(size: glyphSize, pieces: CSVFields(line), inFont: font)
        }
    }
}

private let weights = [
    ("ultralight", Font.Weight.ultraLight),
    ("thin", Font.Weight.thin),
    ("light", Font.Weight.light),
    ("regular", Font.Weight.regular),
    ("medium", Font.Weight.medium),
    ("semibold", Font.Weight.semibold),
    ("bold", Font.Weight.bold),
    ("heavy", Font.Weight.heavy),
    ("black", Font.Weight.black),
]

extension Font.Weight: ArgumentKind {
    
    public init(argument: String) throws {
        guard let pair = weights.first(where: { $0.0 == argument }) else {
            throw ArgumentConversionError.custom("Unknown argument value: '\(argument)'")
        }
        self = pair.1
    }
    
    public static var completion: ShellCompletion {
        let values = weights.map { (value: $0.0, description: $0.0) }
        return .values(values)
    }
    
    
}

private func CTFontCopyDecodedSYMPData(_ font: CTFont) -> Data? {
    func fourCharCode(_ string: String) -> FourCharCode {
        return string.utf16.reduce(0, {$0 << 8 + FourCharCode($1)})
    }
    
    let tag = fourCharCode("symp")
    guard let data = CTFontCopyTable(font, tag, []) else { return nil }
    guard let base64String = String(data: data as Data, encoding: .utf8) else { return nil }
    guard let encoded = NSData(base64Encoded: base64String) else { return nil }
    guard let decoded = NSMutableData(length: encoded.length) else { return nil }
    
    var key: Array<UInt8> = [0xB8, 0x85, 0xF6, 0x9E, 0x39, 0x8C, 0xBA, 0x72, 0x40, 0xDB, 0x49, 0x6B, 0xE8, 0xC6, 0x14, 0x88, 0x54, 0x9F, 0x1F, 0x88, 0x5D, 0x47, 0x6B, 0x2E, 0x2C, 0xC1, 0x14, 0xF1, 0x3B, 0x17, 0x21, 0x20]
    var iv: Array<UInt8> = [0xEF, 0xB0, 0xD1, 0x2E, 0xFA, 0xC5, 0x91, 0x14, 0xC3, 0xE5, 0xB9, 0x12, 0x70, 0xF0, 0xC0, 0x46]
    
    var bytesWritten = 0
    let result = CCCrypt(CCOperation(kCCDecrypt),
                         CCAlgorithm(kCCAlgorithmAES),
                         CCOptions(kCCOptionPKCS7Padding),
                         &key, key.count,
                         &iv,
                         encoded.bytes, encoded.length,
                         decoded.mutableBytes, decoded.length,
                         &bytesWritten)
    
    guard result == kCCSuccess else { return nil }
    decoded.length = bytesWritten
    return decoded as Data
}

internal func CSVFields(_ line: String) -> Array<String> {
    var fields = Array<String>()
    
    var insideQuote = false
    var fieldStart = line.startIndex
    var currentIndex = fieldStart
    while currentIndex < line.endIndex {
        let character = line[currentIndex]
        
        if insideQuote == false {
            if character == "," {
                let subString = line[fieldStart ..< currentIndex]
                fields.append(String(subString))
                fieldStart = line.index(after: currentIndex)
            } else if character == "\"" {
                insideQuote = true
            }
        } else {
            if character == "\"" { insideQuote = false }
        }
        
        if currentIndex >= line.endIndex { break }
        currentIndex = line.index(after: currentIndex)
    }
    
    let lastField = line[fieldStart ..< line.endIndex]
    fields.append(String(lastField))
    
    return fields
}

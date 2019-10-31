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

public extension NSFont.Weight {
    static var knownWeights = [
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
}

public struct Font {
    public typealias Weight = NSFont.Weight
    
    public enum Family: String, CaseIterable {
        case pro = "Pro"
        case compact = "Compact"
    }
    
    public enum Variant: String, CaseIterable {
        case display = "Display"
        case rounded = "Rounded"
        case text = "Text"
    }
    
    public struct Descriptor {
        
        public let family: Family
        public let variant: Variant
        public let weight: Weight
        public let fontSize: CGFloat
        public let glyphSize: Glyph.Size
        
        public init(family: Font.Family, variant: Font.Variant, weight: Font.Weight, fontSize: CGFloat, glyphSize: Glyph.Size) {
            self.family = family
            self.variant = variant
            self.weight = weight
            self.fontSize = fontSize
            self.glyphSize = glyphSize
        }
    }
    
    private let font: CTFont
    
    public let glyphs: Array<Glyph>
    public let weight: Weight
    public let size: CGFloat
    
    public var strokeWidth: CGFloat {
        return 1.0
    }
    
    public static func bestFontMatching(url: URL?, descriptor: Descriptor) -> Font? {
        if let u = url, let f = Font(url: u, descriptor: descriptor) {
            return f
        }
        
        // we don't have a custom font, or it didn't work out
        // can we find the built-in SF fonts
        if let f = builtInFont(matching: descriptor) {
            return f
        }
        
        // we couldn't find the built-in SF fonts
        // can we find the SFSymbols app?
        if let f = sfsymbolsFont(matching: descriptor) {
            return f
        }
        
        return nil
    }
    
    private static func builtInFont(matching descriptor: Descriptor) -> Font? {
        let name = "SF \(descriptor.family.rawValue) \(descriptor.variant.rawValue)"
        
        let manager = NSFontManager.shared
        if let font = manager.font(withFamily: name, traits: [], weight: Int(descriptor.weight.rawValue), size: descriptor.fontSize) {
            let ctFont = font as CTFont
            if let parsedFont = Font(font: ctFont, descriptor: descriptor) {
                return parsedFont
            }
        }
        
        return nil
    }
    
    private static func sfsymbolsFont(matching descriptor: Descriptor) -> Font? {
        let maybeCFURLs = LSCopyApplicationURLsForBundleIdentifier("com.apple.SFSymbols" as CFString, nil)?.takeRetainedValue()
        
        guard let cfURLs = maybeCFURLs as? Array<URL> else { return nil }
        
        for bundleURL in cfURLs {
            guard let appBundle = Bundle(url: bundleURL) else { continue }
            guard let fontURL = appBundle.url(forResource: "SFSymbolsFallback", withExtension: "ttf") else { continue }
            if let f = Font(url: fontURL, descriptor: descriptor) { return f }
        }
        return nil
    }
    
    public init?(url: URL, descriptor: Descriptor) {
        guard let provider = CGDataProvider(url: url as CFURL) else { return nil }
        guard let cgFont = CGFont(provider) else { return nil }
        
        let attributes = [
            kCTFontTraitsAttribute: [
                kCTFontWeightTrait: descriptor.weight.rawValue
            ]
        ]
        let ctAttributes = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        let font = CTFontCreateWithGraphicsFont(cgFont, descriptor.fontSize, nil, ctAttributes)
        self.init(font: font, descriptor: descriptor)
    }
    
    public init?(font: CTFont, descriptor: Descriptor) {
        
        guard let data = CTFontCopyDecodedSYMPData(font) else { return nil }
        guard let csv = String(data: data, encoding: .utf8) else { return nil }
        
        // drop the first and last lines (headers + summary, respectively)
        let csvLines = csv.components(separatedBy: "\r\n").dropFirst().dropLast()
        
        self.font = font
        self.weight = descriptor.weight
        self.size = descriptor.fontSize
        self.glyphs = csvLines.compactMap { line -> Glyph? in
            return Glyph(size: descriptor.glyphSize, pieces: CSVFields(line), inFont: font)
        }
    }
    
    public func glyphs(matching pattern: String) -> Array<Glyph> {
        if pattern == "*" { return glyphs }
        return glyphs.filter { fnmatch(pattern, $0.fullName, 0) == 0 }
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
                fields.append(String(subString).trimmingCharacters(in: .whitespaces))
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
    fields.append(String(lastField).trimmingCharacters(in: .whitespaces))
    
    return fields
}

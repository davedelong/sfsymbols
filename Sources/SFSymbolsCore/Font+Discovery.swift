//
//  File.swift
//  
//
//  Created by Dave DeLong on 10/31/19.
//

import Cocoa

extension Font {
    
    public static func bestFontMatching(url: URL?, descriptor: Descriptor) -> Font? {
        // if we've got an explicitly-specified font file, attempt to load that
        if let f = explicitFont(from: url, descriptor: descriptor) {
            return f
        }
        
        // we don't have a custom font, or it didn't work out
        // can we find the built-in SF fonts
        if let f = builtInFont(matching: descriptor) {
            return f
        }
        
        // we couldn't find the built-in SF fonts
        // can we find the SFSymbols app?
        if let f = appFallbackFont(matching: descriptor) {
            return f
        }
        
        return nil
    }
    
    private static func explicitFont(from url: URL?, descriptor: Descriptor) -> Font? {
        guard let u = url else { return nil }
        return Font(url: u, descriptor: descriptor)
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
    
    private static func appFallbackFont(matching descriptor: Descriptor) -> Font? {
        let maybeCFURLs = LSCopyApplicationURLsForBundleIdentifier("com.apple.SFSymbols" as CFString, nil)?.takeRetainedValue()
        
        guard let cfURLs = maybeCFURLs as? Array<URL> else { return nil }
        let bundles = cfURLs.compactMap { Bundle(url: $0) }
        
        let sortedBundles = bundles.sorted(by: { $0.shortVersionString > $1.shortVersionString })
        
        for appBundle in sortedBundles {
            guard let fontURL = appBundle.url(forResource: "SFSymbolsFallback", withExtension: "ttf") else { continue }
            if let f = Font(url: fontURL, descriptor: descriptor) { return f }
        }
        return nil
    }

}

extension Bundle {
    
    fileprivate var shortVersionString: String {
        return (infoDictionary?[kCFBundleVersionKey as String] as? String) ?? "0"
    }
    
}

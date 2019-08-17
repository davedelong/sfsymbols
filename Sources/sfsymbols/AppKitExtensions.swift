//
//  File.swift
//  
//
//  Created by Dave DeLong on 8/17/19.
//

import Cocoa


extension NSImage {
    
    var pngData: Data {
        guard let tiffData = tiffRepresentation else { return Data() }
        guard let bitmap = NSBitmapImageRep(data: tiffData) else { return Data() }
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else { return Data() }
        return pngData
    }
    
}

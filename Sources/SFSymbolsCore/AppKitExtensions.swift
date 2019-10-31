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

extension NSBezierPath {

    // https://stackoverflow.com/a/49011112
    // Thank you, "Jon"
    static func cubicPointsFromQuadratic(currentPoint: CGPoint, destinationPoint: CGPoint, controlPoint: CGPoint) -> (controlPoint1: CGPoint, controlPoint2: CGPoint) {
        let qp0 = currentPoint
        let qp1 = controlPoint
        let qp2 = destinationPoint
        
        let m: CGFloat = 2.0 / 3.0
        var cp1 = CGPoint.zero
        cp1.x = qp0.x + ((qp1.x - qp0.x) * m)
        cp1.y = qp0.y + ((qp1.y - qp0.y) * m)
        
        var cp2 = CGPoint.zero
        cp2.x = qp2.x + ((qp1.x - qp2.x) * m)
        cp2.y = qp2.y + ((qp1.y - qp2.y) * m)
        
        return (cp1, cp2)
    }
    
}

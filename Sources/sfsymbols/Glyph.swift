//
//  Glyph.swift
//  
//
//  Created by Dave DeLong on 8/16/19.
//

import Foundation
import SPMUtility

struct Glyph {
    
    enum Size: String, CaseIterable, ArgumentKind {
        
        init(argument: String) throws {
            guard let s = Size(rawValue: argument) else {
                throw ArgumentConversionError.custom("Unknown symbol size '\(argument)'")
            }
            self = s
        }
        
        static var completion: ShellCompletion {
            return .values(allCases.map { (value: $0.rawValue, description: $0.rawValue) })
        }
        
        case small
        case medium
        case large
    }
    
    enum Element {
        case move(CGPoint)
        case line(CGPoint)
        case quadCurve(CGPoint, CGPoint)
        case curve(CGPoint, CGPoint, CGPoint)
        case close
    }
    
    private let font: CTFont
    private let originOffset: CGPoint
    private let glyph: CGGlyph
    
    let cgPath: CGPath
    
    let identifierName: String
    let fullName: String
    let baseName: String
    let isFilled: Bool
    let variant: String?
    let isRTL: Bool
    
    let boundingBox: CGRect
    let allowsMirroring: Bool
    let appleOnly: Bool
    let keywords: Array<String>
    let restrictionNote: String?
    
    
    init?(size: Size, pieces: Array<String>, inFont font: CTFont) {
        guard pieces.count > 43 else { return nil }
        let name = "uni\(pieces[1]).\(size.rawValue)"
        var glyph = CTFontGetGlyphWithName(font, name as CFString)
        if glyph == 0 { return nil }
        
        self.font = font
        self.glyph = glyph
        
        var box = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(font, .default, &glyph, &box, 1)
        let paddedBox = CGRect(x: 0, y: 0, width: box.width + (2 * box.origin.x), height: box.height - (2 * box.origin.y))
        self.boundingBox = paddedBox
        self.originOffset = box.origin
        

        let path = CTFontCreatePathForGlyph(font, glyph, nil)
        var transform = CGAffineTransform(translationX: 0, y: -originOffset.y)
        let copy = path?.copy(using: &transform)
        self.cgPath = copy ?? CGPath(rect: CGRect(origin: .zero, size: paddedBox.size), transform: nil)
        
        self.fullName = pieces[12]
        self.identifierName = "symbol" + fullName.components(separatedBy: ".").map { $0.capitalized }.joined()
        self.baseName = pieces[13]
        self.variant = pieces[15].isEmpty ? nil : pieces[15]
        self.isFilled = pieces[16] == "fill"
        self.isRTL = pieces[17] != ""
        
        let keywords = pieces[38].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        self.keywords = CSVFields(keywords).map { $0.trimmingCharacters(in: .whitespaces) }
        
        self.appleOnly = Bool(pieces[8].lowercased()) ?? false
        self.allowsMirroring = Bool(pieces[42].lowercased()) ?? false
        
        if pieces[46].isEmpty == true {
            self.restrictionNote = nil
        } else {
            self.restrictionNote = pieces[46]
        }
    }
    
    func enumerateElements(enumerator: (Element) -> Void) {
        cgPath.applyWithBlock { elementRef in
            let pathElement = elementRef.pointee
            
            let points = [
                pathElement.points[0],
                pathElement.points[1],
                pathElement.points[2]
            ]
            
            let element: Element
            switch pathElement.type {
                case .moveToPoint: element = .move(points[0])
                case .addLineToPoint: element = .line(points[0])
                case .addQuadCurveToPoint: element = .quadCurve(points[0], points[1])
                case .addCurveToPoint: element = .curve(points[0], points[1], points[2])
                case .closeSubpath: element = .close
                @unknown default: return
            }
            
            enumerator(element)
        }
    }
    
}

//
//  File.swift
//  
//
//  Created by Dave DeLong on 10/31/19.
//

import Foundation
import SFSymbolsCore
import SPMUtility

extension ExportFormat: ArgumentKind {
    
    public static var completion: ShellCompletion {
        let values = allCases.map { (value: $0.rawValue, description: $0.rawValue) }
        return .values(values)
    }
    
    public init(argument: String) throws {
        if let f = ExportFormat(rawValue: argument) {
            self = f
        } else {
            throw ArgumentConversionError.custom("Unknown format '\(argument)'")
        }
    }
    
}


extension Font.Family: ArgumentKind {
    public static let completion: ShellCompletion = .values(allCases.map { (value: $0.rawValue, description: $0.rawValue) })
    
    public init(argument: String) throws {
        guard let s = Font.Family(rawValue: argument) else {
            throw ArgumentConversionError.unknown(value: argument)
        }
        self = s
    }
}

extension Font.Variant: ArgumentKind {
    public static let completion: ShellCompletion = .values(allCases.map { (value: $0.rawValue, description: $0.rawValue) })

    public init(argument: String) throws {
        guard let s = Font.Variant(rawValue: argument) else {
            throw ArgumentConversionError.unknown(value: argument)
        }
        self = s
    }
    
}

extension Font.Weight: ArgumentKind {
    
    public init(argument: String) throws {
        guard let pair = Font.Weight.knownWeights.first(where: { $0.0 == argument }) else {
            throw ArgumentConversionError.custom("Unknown argument value: '\(argument)'")
        }
        self = pair.1
    }
    
    public static var completion: ShellCompletion {
        let values = Font.Weight.knownWeights.map { (value: $0.0, description: $0.0) }
        return .values(values)
    }
    
    
}

extension Glyph.Size: ArgumentKind {
    public static let completion: ShellCompletion = .values(allCases.map { (value: $0.rawValue, description: $0.rawValue) })
    
    public init(argument: String) throws {
        guard let s = Glyph.Size(rawValue: argument) else {
            throw ArgumentConversionError.custom("Unknown symbol size '\(argument)'")
        }
        self = s
    }
}

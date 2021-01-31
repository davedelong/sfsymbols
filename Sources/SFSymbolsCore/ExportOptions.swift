//
//  ExportOptions.swift
//  
//
//  Created by Dave DeLong on 9/19/19.
//

import Foundation

public struct ExportOptions {
    
    public let verbose: Bool
    public let outputFolder: URL
    public let matchPattern: String
    public let color: String
    
    public init(verbose: Bool, outputFolder: URL, matchPattern: String, color: String) {
        self.verbose = verbose
        self.outputFolder = outputFolder
        self.matchPattern = matchPattern
        self.color = color
    }
    
}

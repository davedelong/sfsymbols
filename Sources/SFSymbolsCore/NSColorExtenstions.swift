//
//  NSColorExtensions.swift
//  
//
//  Created by Steven Vlaminck on 7/8/20.
//

import Cocoa

extension NSColor {
  
  public convenience init(hexString hex: String) {
    let r, g, b, a: CGFloat
    
    var hexColor: String = hex
    
    if hex.hasPrefix("#") {
      // strip the first character so we only deal with hex values
      let start = hex.index(hex.startIndex, offsetBy: 1)
      hexColor = String(hex[start...])
    }
    
    if hexColor.count == 6 {
      // no alpha was sent. default to 100% alpha
      hexColor = "\(hexColor)FF"
    }
    
    if hexColor.count == 8 {
      let scanner = Scanner(string: hexColor)
      var hexNumber: UInt64 = 0
      
      if scanner.scanHexInt64(&hexNumber) {
        r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
        g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
        b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
        a = CGFloat(hexNumber & 0x000000ff) / 255
        
        self.init(red: r, green: g, blue: b, alpha: a)
        return
      }
    }
    
    // we failed to parse this color. return black
    self.init(red: 0, green: 0, blue: 0, alpha: 1)
  }
  
  func toHexString() -> String {
    var r:CGFloat = 0
    var g:CGFloat = 0
    var b:CGFloat = 0
    var a:CGFloat = 0
    getRed(&r, green: &g, blue: &b, alpha: &a)
    let rgba: Int = (Int)(r * 255) << 24 | (Int)(g * 255) << 16 | (Int)(b * 255) << 8 | (Int)(a * 255) << 0
    return String(format:"#%08x", rgba).uppercased()
  }
  
}

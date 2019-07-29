//
//  Utilities.m
//  sfsymbols
//
//  Created by Dave DeLong on 7/28/19.
//  Copyright © 2019 Syzygy Development. All rights reserved.
//

#import "Utilities.h"

@import CommonCrypto;
@import CoreText;

uint8_t key[] = {0xB8, 0x85, 0xF6, 0x9E, 0x39, 0x8C, 0xBA, 0x72, 0x40, 0xDB, 0x49, 0x6B, 0xE8, 0xC6, 0x14, 0x88, 0x54, 0x9F, 0x1F, 0x88, 0x5D, 0x47, 0x6B, 0x2E, 0x2C, 0xC1, 0x14, 0xF1, 0x3B, 0x17, 0x21, 0x20};

uint8_t iv[] = {0xEF, 0xB0, 0xD1, 0x2E, 0xFA, 0xC5, 0x91, 0x14, 0xC3, 0xE5, 0xB9, 0x12, 0x70, 0xF0, 0xC0, 0x46};

NSData *CTFontCopyDecodedSYMPData(CTFontRef font, CTFontTableTag tag) {
    
    NSData *tableData = CFBridgingRelease(CTFontCopyTable(font, tag, 0));
    if (tableData == nil) { return nil; }
    
    NSString *tableString = [[NSString alloc] initWithData:tableData encoding:NSUTF8StringEncoding];
    if (tableString == nil) { return nil; }
    
    NSData *encoded = [[NSData alloc] initWithBase64EncodedString:tableString options:0];
    if (encoded == nil) { return nil; }
    
    NSMutableData *decoded = [NSMutableData dataWithLength:encoded.length];
    size_t bytesWritten = 0;
    CCCryptorStatus result = CCCrypt(kCCDecrypt,
                         kCCAlgorithmAES,
                         kCCOptionPKCS7Padding,
                         key,
                         0x20,
                         iv,
                         encoded.bytes,
                         encoded.length,
                         decoded.mutableBytes,
                         decoded.length,
                         &bytesWritten);
    
    if (result != kCCSuccess) { return nil; }
    
    decoded.length = bytesWritten;
    return decoded;
}

NSArray *ParseCSVLine(NSString *line) {
    NSMutableArray *fields = [NSMutableArray array];
    
    BOOL insideQuote = NO;
    NSUInteger fieldStart = 0;
    for (NSUInteger currentIndex = 0; currentIndex < line.length; currentIndex++) {
        unichar character = [line characterAtIndex:currentIndex];
        if (insideQuote == NO) {
            if (character == ',') {
                // end of field
                NSRange r = NSMakeRange(fieldStart, currentIndex - fieldStart);
                [fields addObject:[line substringWithRange:r]];
                fieldStart = currentIndex + 1; // + 1 to skip the ,
            } else if (character == '"') {
                insideQuote = YES;
            }
        } else {
            if (character == '"') { insideQuote = NO; }
        }
    }
    
    // don't forget the last field
    NSRange r = NSMakeRange(fieldStart, line.length - fieldStart);
    [fields addObject:[line substringWithRange:r]];
    
    return fields;
}


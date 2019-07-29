//
//  SFGlyph.m
//  sfsymbols
//
//  Created by Dave DeLong on 7/28/19.
//  Copyright © 2019 Syzygy Development. All rights reserved.
//

#import "SFGlyph.h"
#import "Utilities.h"

@implementation SFGlyph {
    CTFontRef _font;
    CGGlyph _glyph;
    CGPoint _offset;
}

+ (nullable NSArray<SFGlyph *> *)glyphsInSFSymbolsApp:(NSURL *)url ofSize:(NSInteger)size {
    NSBundle *appBundle = [NSBundle bundleWithURL:url];
    
    // see if we can find the font in the app bundle
    NSURL *fontURL = [appBundle URLForResource:@"SFSymbolsFallback" withExtension:@"ttf"];
    if (fontURL == nil) { return nil; }
    
    // load up the font's data
    CGDataProviderRef cgFontProvider = CGDataProviderCreateWithURL((CFURLRef)fontURL);
    if (cgFontProvider == NULL) { return nil; }
    
    // attempt to create the font
    CGFontRef cgFont = CGFontCreateWithDataProvider(cgFontProvider);
    CGDataProviderRelease(cgFontProvider);
    if (cgFont == NULL) { return nil; }
    
    // turn it in to a CTFont
    CTFontRef font = CTFontCreateWithGraphicsFont(cgFont, (CGFloat)size, NULL, NULL);
    CGFontRelease(cgFont);
    if (font == NULL) { return nil; }
    
    // pull out the encoded SYMP data, which has the list of glyphs
    NSData *decoded = CTFontCopyDecodedSYMPData(font, 'symp');
    if (decoded == nil) { return nil; }
    
    // this is CSV data
    NSString *csv = [[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding];
    if (csv == nil) { return nil; }
    
    NSArray *lines = [csv componentsSeparatedByString:@"\r\n"];
    NSMutableArray *glyphs = [NSMutableArray arrayWithCapacity:lines.count];
    
    // the first line is the columns
    // the last line is some summary info
    NSUInteger numberOfGlyphs = lines.count - 2;
    for (NSUInteger i = 1; i <= numberOfGlyphs; i++) {
        
        // create a glyph from each line of CSV
        NSString *line = lines[i];
        NSArray *bits = ParseCSVLine(line);
        SFGlyph *glyph = [[SFGlyph alloc] initWithPieces:bits inFont:font];
        if (glyph != nil) {
            [glyphs addObject:glyph];
        }
    }
    return glyphs;
}

- (instancetype)initWithPieces:(NSArray *)bits inFont:(CTFontRef)font {
    self = [super init];
    if (self) {
        NSString *glyphName = [NSString stringWithFormat:@"uni%@.large", bits[1]];
        CGGlyph g = CTFontGetGlyphWithName(font, (CFStringRef)glyphName);
        if (g == 0) { return nil; }
        
        _font = font;
        _glyph = g;
        _name = bits[12];
        
        CGRect box;
        CTFontGetBoundingRectsForGlyphs(font, kCTFontOrientationDefault, &g, &box, 1);
        _boundingBox.origin = CGPointZero;
        _boundingBox.size = box.size;
        _offset = box.origin;
        
//        NSString *order = bits[4];
//        NSString *blacklist = bits[8];
//        NSString *name = bits[12];
//        NSString *baseName = bits[13];
//        NSString *mirrorsForRTL = bits[42];
    }
    return self;
}

- (void)enumeratePathElements:(NS_NOESCAPE void(^)(const GlyphPathElement *element))enumerator {
    CGPathRef path = CTFontCreatePathForGlyph(_font, _glyph, NULL);
    CGPoint offset = _offset;
    CGPathApplyWithBlock(path, ^(const CGPathElement *element) {
        GlyphPathElement e;
        e.type = element->type;
        e.points[0] = CGPointZero;
        e.points[1] = CGPointZero;
        e.points[2] = CGPointZero;
        
        if (e.type != kCGPathElementCloseSubpath) {
            e.points[0] = CGPointMake(element->points[0].x - offset.x, element->points[0].y - offset.y);
        }
        if (e.type == kCGPathElementAddCurveToPoint || e.type == kCGPathElementAddQuadCurveToPoint) {
            e.points[1] = CGPointMake(element->points[1].x - offset.x, element->points[1].y - offset.y);
        }
        if (e.type == kCGPathElementAddCurveToPoint) {
            e.points[2] = CGPointMake(element->points[2].x - offset.x, element->points[2].y - offset.y);
        }
        
        enumerator(&e);
    });
    CFRelease(path);
}

@end

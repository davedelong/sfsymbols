//
//  Generator.m
//  sfsymbols
//
//  Created by Dave DeLong on 7/28/19.
//  Copyright © 2019 Syzygy Development. All rights reserved.
//

#import "Generator.h"
#import "SFGlyph.h"

@interface Swift_iOS : Generator @end
@interface ObjC_iOS : Generator @end
@interface Swift_macOS : Generator @end
@interface ObjC_macOS : Generator @end
@interface SVG : Generator @end

@implementation Generator

+ (instancetype)generatorForFormat:(NSString *)format {
    if ([format isEqualToString:@"ios-swift"]) { return [[Swift_iOS alloc] init]; }
    if ([format isEqualToString:@"ios-objc"]) { return [[ObjC_iOS alloc] init]; }
    if ([format isEqualToString:@"macos-swift"]) { return [[Swift_macOS alloc] init]; }
    if ([format isEqualToString:@"macos-objc"]) { return [[ObjC_macOS alloc] init]; }
    if ([format isEqualToString:@"svg"]) { return [[SVG alloc] init]; }
    return nil;
}

- (NSString *)generateGlyph:(SFGlyph *)glyph { exit(-1); }

@end

NSString *P(CGPoint p) {
    return [NSString stringWithFormat:@"CGPoint(x: %f, y: %f)", p.x, p.y];
}

NSString *NS_P(CGPoint p) {
    return [NSString stringWithFormat:@"NSMakePoint(x: %f, y: %f)", p.x, p.y];
}

NSString *SVG_P(CGPoint p) {
    return [NSString stringWithFormat:@"%f,%f", p.x, p.y];
}

@implementation Swift_iOS
- (NSString *)pathExtension { return @"swift"; }
- (NSString *)generateGlyph:(SFGlyph *)g {
    NSMutableArray *lines = [NSMutableArray array];
    CGRect box = g.boundingBox;
    
    [lines addObject:[NSString stringWithFormat:@"let path = UIBezierPath(rect: CGRect(x: %f, y: %f, width: %f, height: %f))", box.origin.x, box.origin.y, box.size.width, box.size.height]];
    [g enumeratePathElements:^(const GlyphPathElement * _Nonnull element) {
        NSString *line;
        switch (element->type) {
            case kCGPathElementMoveToPoint:
                line = [NSString stringWithFormat:@"path.move(to: %@)", P(element->points[0])];
                break;
            case kCGPathElementAddLineToPoint:
                line = [NSString stringWithFormat:@"path.addLine(to: %@)", P(element->points[0])];
                break;
            case kCGPathElementAddQuadCurveToPoint:
                line = [NSString stringWithFormat:@"path.addQuadCurve(to: %@, controlPoint: %@)", P(element->points[1]), P(element->points[0])];
                break;
            case kCGPathElementAddCurveToPoint:
                line = [NSString stringWithFormat:@"path.addCurve(to: %@, controlPoint1: %@, controlPoint2: %@)", P(element->points[0]), P(element->points[1]), P(element->points[2])];
                break;
            case kCGPathElementCloseSubpath:
                line = @"path.close()";
                break;
        }
        [lines addObject:line];
    }];
    
    return [lines componentsJoinedByString:@"\n"];
}
@end

@implementation ObjC_iOS
- (NSString *)pathExtension { return @"m"; }
- (NSString *)generateGlyph:(SFGlyph *)g {
    NSMutableArray *lines = [NSMutableArray array];
    CGRect box = g.boundingBox;
    
    [lines addObject:[NSString stringWithFormat:@"UIBezierPath *path = [[UIBezierPath alloc] initWithRect:CGRectMake(x: %f, y: %f, width: %f, height: %f)];", box.origin.x, box.origin.y, box.size.width, box.size.height]];
    [g enumeratePathElements:^(const GlyphPathElement * _Nonnull element) {
        NSString *line;
        switch (element->type) {
            case kCGPathElementMoveToPoint:
                line = [NSString stringWithFormat:@"[path moveToPoint:%@];", P(element->points[0])];
                break;
            case kCGPathElementAddLineToPoint:
                line = [NSString stringWithFormat:@"[path addLineToPoint:%@];", P(element->points[0])];
                break;
            case kCGPathElementAddQuadCurveToPoint:
                line = [NSString stringWithFormat:@"[path addQuadCurveToPoint:%@ controlPoint:%@];", P(element->points[1]), P(element->points[0])];
                break;
            case kCGPathElementAddCurveToPoint:
                line = [NSString stringWithFormat:@"[path addCurveToPoint:%@ controlPoint1:%@ controlPoint2:%@];", P(element->points[0]), P(element->points[1]), P(element->points[2])];
                break;
            case kCGPathElementCloseSubpath:
                line = @"[path close];";
                break;
        }
        [lines addObject:line];
    }];
    
    return [lines componentsJoinedByString:@"\n"];
}
@end

@implementation Swift_macOS
- (NSString *)pathExtension { return @"swift"; }
- (NSString *)generateGlyph:(SFGlyph *)g {
    NSMutableArray *lines = [NSMutableArray array];
    CGRect box = g.boundingBox;
    
    [lines addObject:[NSString stringWithFormat:@"let path = NSBezierPath(rect: NSRect(x: %f, y: %f, width: %f, height: %f))", box.origin.x, box.origin.y, box.size.width, box.size.height]];
    [g enumeratePathElements:^(const GlyphPathElement * _Nonnull element) {
        NSString *line;
        switch (element->type) {
            case kCGPathElementMoveToPoint:
                line = [NSString stringWithFormat:@"path.move(to: %@)", P(element->points[0])];
                break;
            case kCGPathElementAddLineToPoint:
                line = [NSString stringWithFormat:@"path.line(to: %@)", P(element->points[0])];
                break;
            case kCGPathElementAddQuadCurveToPoint:
                // NSBezierPath doesn't seem to have a "quad curve" equivalent
                line = [NSString stringWithFormat:@"path.addQuadCurve(to: %@, controlPoint: %@)", P(element->points[1]), P(element->points[0])];
                break;
            case kCGPathElementAddCurveToPoint:
                line = [NSString stringWithFormat:@"path.curve(to: %@, controlPoint1: %@, controlPoint2: %@)", P(element->points[0]), P(element->points[1]), P(element->points[2])];
                break;
            case kCGPathElementCloseSubpath:
                line = @"path.close()";
                break;
        }
        [lines addObject:line];
    }];
    
    return [lines componentsJoinedByString:@"\n"];
}
@end

@implementation ObjC_macOS
- (NSString *)pathExtension { return @"m"; }
- (NSString *)generateGlyph:(SFGlyph *)g {
    NSMutableArray *lines = [NSMutableArray array];
    CGRect box = g.boundingBox;
    
    [lines addObject:[NSString stringWithFormat:@"NSBezierPath *path = [[NSBezierPath alloc] initWithRect:NSRectMake(x: %f, y: %f, width: %f, height: %f)];", box.origin.x, box.origin.y, box.size.width, box.size.height]];
    [g enumeratePathElements:^(const GlyphPathElement * _Nonnull element) {
        NSString *line;
        switch (element->type) {
            case kCGPathElementMoveToPoint:
                line = [NSString stringWithFormat:@"[path moveToPoint:%@];", NS_P(element->points[0])];
                break;
            case kCGPathElementAddLineToPoint:
                line = [NSString stringWithFormat:@"[path lineToPoint:%@];", NS_P(element->points[0])];
                break;
            case kCGPathElementAddQuadCurveToPoint:
                // NSBezierPath doesn't seem to have a "quad curve" equivalent
                line = [NSString stringWithFormat:@"path.addQuadCurve(to: %@, controlPoint: %@)", NS_P(element->points[1]), NS_P(element->points[0])];
                break;
            case kCGPathElementAddCurveToPoint:
                line = [NSString stringWithFormat:@"[path curveToPoint:%@ controlPoint1:%@ controlPoint2:%@];", NS_P(element->points[0]), NS_P(element->points[1]), NS_P(element->points[2])];
                break;
            case kCGPathElementCloseSubpath:
                line = @"path.close()";
                break;
        }
        [lines addObject:line];
    }];
    
    return [lines componentsJoinedByString:@"\n"];
}
@end

@implementation SVG
- (NSString *)pathExtension { return @"svg"; }
- (NSString *)generateGlyph:(SFGlyph *)g {
    NSMutableArray *lines = [NSMutableArray array];
    CGRect box = g.boundingBox;
    
    [lines addObject:[NSString stringWithFormat:@"<svg width='%fpx' height='%fpx' xmlns='http://www.w3.org/2000/svg' version='1.1'>", box.size.width, box.size.height]];
    [lines addObject:[NSString stringWithFormat:@"<g fill-rule='nonzero' transform='scale(1,-1) translate(0,-%f)'>", box.size.height]];
    [lines addObject:@"<path fill='black' stroke='black' fill-opacity='1.0' stroke-width='0.125' d='"];
    
    [g enumeratePathElements:^(const GlyphPathElement * _Nonnull element) {
        NSString *line;
        switch (element->type) {
            case kCGPathElementMoveToPoint:
                line = [NSString stringWithFormat:@"M %@", SVG_P(element->points[0])];
                break;
            case kCGPathElementAddLineToPoint:
                line = [NSString stringWithFormat:@"L %@", SVG_P(element->points[0])];
                break;
            case kCGPathElementAddQuadCurveToPoint:
                line = [NSString stringWithFormat:@"Q %@ %@", SVG_P(element->points[0]), SVG_P(element->points[1])];
                break;
            case kCGPathElementAddCurveToPoint:
                line = [NSString stringWithFormat:@"C %@ %@ %@", SVG_P(element->points[0]), SVG_P(element->points[1]), SVG_P(element->points[2])];
                break;
            case kCGPathElementCloseSubpath:
                line = @"Z";
                break;
        }
        [lines addObject:line];
    }];
    [lines addObject:@"' />"];
    [lines addObject:@"</g>"];
    [lines addObject:@"</svg>"];
    
    return [lines componentsJoinedByString:@"\n"];
}
@end

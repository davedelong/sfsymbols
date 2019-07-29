//
//  SFGlyph.h
//  sfsymbols
//
//  Created by Dave DeLong on 7/28/19.
//  Copyright © 2019 Syzygy Development. All rights reserved.
//

#import <Foundation/Foundation.h>

struct GlyphPathElement {
    CGPathElementType type;
    CGPoint points[3];
};
typedef struct GlyphPathElement GlyphPathElement;

NS_ASSUME_NONNULL_BEGIN

@interface SFGlyph : NSObject

+ (nullable NSArray<SFGlyph *> *)glyphsInSFSymbolsApp:(NSURL *)url ofSize:(NSInteger)size;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) CGRect boundingBox;

- (void)enumeratePathElements:(NS_NOESCAPE void(^)(const GlyphPathElement *element))enumerator;

@end

NS_ASSUME_NONNULL_END

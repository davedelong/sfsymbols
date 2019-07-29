//
//  Generator.h
//  sfsymbols
//
//  Created by Dave DeLong on 7/28/19.
//  Copyright © 2019 Syzygy Development. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SFGlyph;

// a class cluster to generate path code
@interface Generator : NSObject

+ (nullable instancetype)generatorForFormat:(nullable NSString *)format;

@property (nonatomic, readonly) NSString *pathExtension;

- (NSString *)generateGlyph:(SFGlyph *)glyph;

@end

NS_ASSUME_NONNULL_END

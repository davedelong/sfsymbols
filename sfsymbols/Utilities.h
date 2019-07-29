//
//  Utilities.h
//  sfsymbols
//
//  Created by Dave DeLong on 7/28/19.
//  Copyright © 2019 Syzygy Development. All rights reserved.
//

#import <Foundation/Foundation.h>

NSData *CTFontCopyDecodedSYMPData(CTFontRef font, CTFontTableTag tag);

NSArray *ParseCSVLine(NSString *line);

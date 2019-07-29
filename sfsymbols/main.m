//
//  main.m
//  sfsymbols
//
//  Created by Dave DeLong on 7/28/19.
//  Copyright © 2019 Syzygy Development. All rights reserved.
//

@import Foundation;
@import CoreServices;

#import "SFGlyph.h"
#import "Generator.h"

void printHelp() {
    NSString *name = [[[[NSProcessInfo processInfo] arguments] firstObject] lastPathComponent];
    NSString *help = [NSString stringWithFormat:@"%@ -output path/to/output/folder -format [ios-swift, ios-objc, macos-swift, macos-objc, svg] [-font-size number]", name];
    printf("%s\n", help.UTF8String);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSDictionary *options = [[NSUserDefaults standardUserDefaults] volatileDomainForName:NSArgumentDomain];
        
        NSURL *currentDirectory = [NSURL fileURLWithPath:[[NSFileManager defaultManager] currentDirectoryPath]];
        NSString *outputPath = [options[@"output"] stringByExpandingTildeInPath];
        if (outputPath == nil) {
            printHelp();
            return -1;
        }
        NSURL *outputFolder = [NSURL URLWithString:outputPath relativeToURL:currentDirectory];
        Generator *generator = [Generator generatorForFormat:options[@"format"]];
        if (generator == nil) {
            printHelp();
            return -1;
        }
        
        [[NSFileManager defaultManager] createDirectoryAtURL:outputFolder withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *sizeString = options[@"font-size"];
        NSInteger size = [sizeString integerValue] ?: 0;
        
        CFErrorRef err = NULL;
        NSArray<NSURL *> *urls = CFBridgingRelease(LSCopyApplicationURLsForBundleIdentifier(CFSTR("com.apple.SFSymbols"), &err));
        if (err != NULL) {
            NSString *msg = [NSString stringWithFormat:@"Error locating SF Symbols app: %@", CFBridgingRelease(CFErrorCopyDescription(err))];
            printf("%s\n", msg.UTF8String);
            return -1;
        }
        
        NSArray<SFGlyph *> *glyphs = nil;
        for (NSURL *url in urls) {
            glyphs = [SFGlyph glyphsInSFSymbolsApp:url ofSize:size];
            if (glyphs != nil) { break; }
        }
        
        if (glyphs == nil) {
            printf("Unable to locate SF Symbols.app. Please make sure it's installed and try again.\n");
            return -1;
        }
        
        for (SFGlyph *glyph in glyphs) {
            NSString *name = [glyph.name stringByAppendingPathExtension:generator.pathExtension];
            NSURL *outputFile = [outputFolder URLByAppendingPathComponent:name];
            
            NSString *code = [generator generateGlyph:glyph];
            NSError *error = nil;
            [code writeToURL:outputFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error != nil) {
                printf("Error writing glyph %s: %s\n", name.UTF8String, error.description.UTF8String);
                exit(-1);
            }
        }
        
        printf("Exported %lu glyphs to %s\n", glyphs.count, outputFolder.absoluteURL.path.UTF8String);
    }
    return 0;
}

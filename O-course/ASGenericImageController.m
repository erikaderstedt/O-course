//
//  ASGenericImageController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-10-19.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASGenericImageController.h"
#import <AppKit/AppKit.h>

@implementation ASGenericImageController

- (id)initWithContentsOfFile:(NSString *)path
{
    self = [super init];
    if (self) {
        image = NULL;
        NSImage *i = [[NSImage alloc] initWithContentsOfFile:path];
        if (i != nil) {
            NSRect bounds = NSZeroRect;
            bounds.size = [i size];
            NSImageRep *r = [i bestRepresentationForRect:bounds context:nil hints:nil];
            image = [r CGImageForProposedRect:NULL context:nil hints:nil];
            CGImageRetain(image);
            [i release];
        } else {
            [self release];
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc {
    if (image != NULL) CGImageRelease(image);
    [super dealloc];
}

- (NSInteger)symbolNumberAtPosition:(CGPoint)p {
    return 0; // We don't know anything about symbol numbers.
}

- (CGRect)mapBounds {
    if (image == NULL) {
        return CGRectZero;
    }
    return CGRectMake(0.0,0.0, CGImageGetWidth(image), CGImageGetHeight(image));
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (image != NULL) {
        CGContextDrawImage (ctx, [self mapBounds], image);
    }
}

// Brown image not supported.
- (BOOL)supportsBrownImage {
    return NO;
}
- (void)setBrownImage:(BOOL)bi {}
- (BOOL)brownImage { return NO; }

@end

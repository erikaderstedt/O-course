//
//  ASGenericImageController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-10-19.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASGenericImageController.h"

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
        } else {
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc {
    if (image != NULL) CGImageRelease(image);
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

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx useSecondaryTransform:(BOOL)useSecondaryTransform {
    if (image != NULL) {
        CGContextDrawImage (ctx, [self mapBounds], image);
    }
}

// Brown image not supported.
- (BOOL)supportsHiddenSymbolNumbers{
    return NO;
}

- (void)setHiddenSymbolNumbers:(const int32_t *)symbols count:(size_t)count {
    NSAssert(NO, @"Not supported on this map provider");
}

- (const int32_t *)hiddenSymbolNumbers:(size_t *)count {
    NSAssert(NO, @"Not supported on this map provider");
    return NULL;
}

- (NSArray *)symbolList {
    return @[];
}

@end

//
//  ASMapViewDelegate.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-02.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@protocol ASMapProvider <NSObject>
/*
- (void)beginRenderingMapWithSize:(NSSize)sz fromSourceRect:(NSRect)sourceRect whenDone:(void (^)(NSImage *i))completionBlock;
- (NSInteger)symbolNumberAtPosition:(CGPoint)p;
- (NSRect)mapBounds; // In native coordinates.
*/
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;

@end

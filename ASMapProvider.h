//
//  ASMapViewDelegate.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-02.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "ASCourseObject.h"

@protocol ASOverprintProvider <NSObject>

- (CGRect)frameForOverprintObject:(id <ASOverprintObject>)object;
- (CGSize)frameSizeForOverprintObjectType:(enum ASOverprintObjectType)type;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
- (void)updateOverprint;
- (void)hideOverprintObject:(id <ASOverprintObject>)courseObject informLayer:(CATiledLayer *)layer;
- (void)showOverprintObject:(id <ASOverprintObject>)courseObject informLayer:(CATiledLayer *)layer;

@end

@protocol ASMapProvider <NSObject>

- (NSInteger)symbolNumberAtPosition:(CGPoint)p;
- (CGRect)mapBounds; // In native coordinates.
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx useSecondaryTransform:(BOOL)useSecondaryTransform;

- (BOOL)supportsBrownImage;
- (void)setBrownImage:(BOOL)bi;
- (BOOL)brownImage;

@end

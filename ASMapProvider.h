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

- (NSInteger)symbolNumberAtPosition:(CGPoint)p;
- (CGRect)mapBounds; // In native coordinates.
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;

@end

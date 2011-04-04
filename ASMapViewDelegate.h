//
//  ASMapViewDelegate.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-02.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol ASMapViewDelegate <NSObject>

- (NSImage *)renderedMapWithImageSize:(NSSize)sz atPoint:(CGPoint)point;
- (NSInteger)symbolNumberAtPosition:(CGPoint)p;
- (NSRect)mapBounds; // In native coordinates.
@end

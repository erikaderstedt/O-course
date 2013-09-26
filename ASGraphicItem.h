//
//  ASGraphicItem.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

enum ASCorner {
    kASCornerBottomLeft,
    kASCornerLeft,
    kASCornerTopLeft,
    kASCornerTop,
    kASCornerTopRight,
    kASCornerRight,
    kASCornerBottomRight,
    kASCornerBottom
};

@protocol ASGraphicItem <NSObject>

- (CGRect)frame;
- (CGPoint)position;
- (NSImage *)image;
- (void)setPosition:(CGPoint)position;
- (void)moveCorner:(enum ASCorner)corner deltaX:(CGFloat)dX deltaY:(CGFloat)dY;
- (BOOL)whiteBackground;
- (void)setWhiteBackground:(BOOL)whiteBackground;

@end

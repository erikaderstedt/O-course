//
//  Graphic.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "Graphic.h"
#import "Layout.h"


@implementation Graphic

@dynamic position_x;
@dynamic position_y;
@dynamic z_index;
@dynamic image;
@dynamic layout;
@dynamic scale;
@dynamic whiteBackground;

- (CGPoint)position {
    return CGPointMake(self.position_x, self.position_y);
}

- (void)setPosition:(CGPoint)p {
    self.position_y = p.y;
    self.position_x = p.x;
}

- (CGRect)frame {
    NSSize sz = [self.image size];
    CGFloat f = self.scale;
    sz.height *= f;
    sz.width *= f;
    
    CGRect r;
    r.origin = self.position;
    r.size = sz;
    return r;
}

- (void)setFrame:(NSRect)r {
    self.position = r.origin;
    NSSize sz = [self.image size];
    self.scale = r.size.width / sz.width;
}

- (void)moveCorner:(enum ASCorner)corner deltaX:(CGFloat)dX deltaY:(CGFloat)dY {
    NSRect r = [self frame];
    
    if (r.size.height == 0.0) r.size.height = 1.0;
    
    CGFloat ratio = r.size.width / r.size.height;
    CGFloat diff;

    switch (corner) {
        case kASCornerTop:
            r.size.height += dY;
            diff = r.size.height * ratio - r.size.width;
            r.size.width += diff;
            r.origin.x -= 0.5*diff;
            break;
        case kASCornerLeft:
            r.size.width -= dX;
            diff = r.size.width / ratio - r.size.height;
            r.size.height += diff;
            r.origin.x += dX;
            r.origin.y -= 0.5*diff;
            break;
        case kASCornerBottom:
            r.size.height -= dY;
            diff = r.size.height * ratio - r.size.width;
            r.size.width += diff;
            r.origin.x -= 0.5*diff;
            r.origin.y += dY;
            break;
        case kASCornerRight:
            r.size.width += dX;
            diff = r.size.width / ratio - r.size.height;
            r.size.height += diff;
            r.origin.y -= 0.5*diff;
            break;
        case kASCornerBottomRight:
            if (fabs(dY)>fabs(dX)) {
                r.size.height -= dY;
                diff = r.size.height * ratio - r.size.width;
                r.size.width += diff;
                r.origin.y += dY;
            } else {
                r.size.width += dX;
                diff = r.size.width / ratio - r.size.height;
                r.size.height += diff;
                r.origin.y -= diff;
            }
            break;
        case kASCornerBottomLeft:
            if (fabs(dY)>fabs(dX)) {
                r.size.height -= dY;
                diff = r.size.height * ratio - r.size.width;
                r.size.width += diff;
                r.origin.y += dY;
                r.origin.x -= diff;
            } else {
                r.size.width -= dX;
                diff = r.size.width / ratio - r.size.height;
                r.size.height += diff;
                r.origin.y -= diff;
                r.origin.x += dX;
            }
            break;
        case kASCornerTopLeft:
            if (fabs(dY)>fabs(dX)) {
                r.size.height += dY;
                diff = r.size.height * ratio - r.size.width;
                r.size.width += diff;
                r.origin.x -= diff;
            } else {
                r.size.width -= dX;
                diff = r.size.width / ratio - r.size.height;
                r.size.height += diff;
                r.origin.x += dX;
            }
            break;
        case kASCornerTopRight:
            if (fabs(dY)>fabs(dX)) {
                r.size.height += dY;
                diff = r.size.height * ratio - r.size.width;
                r.size.width += diff;
            } else {
                r.size.width += dX;
                diff = r.size.width / ratio - r.size.height;
                r.size.height += diff;
            }
            break;
        default:
            break;
    }
    [self setFrame:r];
}

@end

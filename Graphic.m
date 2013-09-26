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

@end

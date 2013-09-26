//
//  ASMaskedAreaItem.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

// Masked areas are in *map* coordinates. Of course.

@protocol ASMaskedAreaItem <NSObject>

- (void)addVertex:(CGPoint)p;
- (CGPoint)firstVertex;
- (CGPathRef)path;
- (CGPathRef)vertexPath;
- (NSArray *)vertices;

@end

//
//  ASGraphicItem.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ASGraphicItem <NSObject>

- (CGRect)frame;
- (CGPoint)position;
- (NSImage *)image;

@end

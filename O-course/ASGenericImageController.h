//
//  ASGenericImageController.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-10-19.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Quartz/Quartz.h>
#import "ASMapProvider.h"

@interface ASGenericImageController : NSObject <ASMapProvider> {
    CGImageRef image;
}

- (id)initWithContentsOfFile:(NSString *)path;

@end

//
//  ASScaleFormatter.h
//  O-course
//
//  Created by Erik Aderstedt on 2013-08-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ASScaleFormatter : NSNumberFormatter

@end

@interface ASScaleTransformer : NSValueTransformer {
    ASScaleFormatter *formatter;
}

@end
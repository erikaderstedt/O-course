//
//  ASDistanceFormatter.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-16.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASDistanceFormatter.h"

@implementation ASDistanceFormatter

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setMaximumFractionDigits:1];
        [self setMinimumFractionDigits:1];
    }
    return self;
}

- (NSString *)stringForObjectValue:(id)obj {
    if ([(NSNumber *)obj floatValue] < 1.0 && [(NSNumber *)obj floatValue] > 0.0) {
        return [NSString stringWithFormat:@"%@ m", [super stringForObjectValue:[NSNumber numberWithFloat:1000.0*[(NSNumber *)obj floatValue]]]];
    }
    return [NSString stringWithFormat:@"%@ km", [super stringForObjectValue:obj]];    
}

@end

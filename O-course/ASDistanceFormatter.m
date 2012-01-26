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

- (NSString *)stringFromNumber:(NSNumber *)number {
    return [NSString stringWithFormat:@"%@ km", [super stringFromNumber:number]];
}

- (NSString *)stringForObjectValue:(id)obj {
    return [NSString stringWithFormat:@"%@ km", [super stringForObjectValue:obj]];    
}

@end

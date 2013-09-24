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
        [self setLocalizesFormat:YES];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setMaximumFractionDigits:1];
        [self setMinimumFractionDigits:1];
        [self setLocalizesFormat:YES];
    }
    return self;
}

- (NSString *)stringForObjectValue:(id)obj {
    if (obj == nil || [obj floatValue] == 0.0) return @"";
    
    if ([(NSNumber *)obj floatValue] < 1.0 && [(NSNumber *)obj floatValue] > 0.0) {
        CGFloat f = [(NSNumber *)obj floatValue];
        f = round(f*100.0);
        [self setMaximumFractionDigits:0];
        NSString *s = [NSString stringWithFormat:@"%@ m", [super stringForObjectValue:@(f*10.0)]];
        [self setMaximumFractionDigits:1];
        return s;
    }
    return [NSString stringWithFormat:@"%@ km", [super stringForObjectValue:obj]];
}

@end

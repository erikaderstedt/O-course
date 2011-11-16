//
//  ASOverprintController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOverprintController.h"

@implementation ASOverprintController 

@synthesize course;

- (void)dealloc {
    [course release];
    
    [super dealloc];
}

#pragma mark ASOverprintProvider

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    
    if (course == nil) return;
    
    // Draw the actual course.
    
    
}

#pragma mark ASControlDescriptionProvider

- (NSString *)eventName {
    
}

- (NSString *)classNamesForCourse:(id)course {
    
}

- (NSString *)numberForCourse:(id)course {
    
}

- (NSNumber *)lengthOfCourse:(id)course {
    
}

- (NSNumber *)heightClimbForCourse:(id)course {
    return nil; // Not yet implemented.
}

// Each item returned by the course object enumerator conforms
// to <ASControlDescriptionItem>
- (NSEnumerator *)courseObjectEnumeratorForCourse:(id)course {
    
}

@end

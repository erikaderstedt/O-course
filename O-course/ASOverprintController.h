//
//  ASOverprintController.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASOverprintProvider.h"
#import "ASControlDescriptionProvider.h"

// Users of the overprint and/or the control description can observe
// "course" to know when to update.

// - Constructs a list of course items to display for a selected course.
// - If no course is selected, all course items are shown.
// - The position of the control number depends on the selected course.
// - No control description can be generated for forked "super"-courses?

@class ASOcourseDocument;

@interface ASOverprintController : NSObject <ASOverprintProvider> {
    NSManagedObject *course;
    ASOcourseDocument *document;
    
    CGColorRef _overprintColor;
    CGColorRef _transparentOverprintColor;
    
    NSArray *cacheArray;
    NSData *cachedCuts;
    
    BOOL drawConnectingLines;
}
@property (nonatomic,assign) IBOutlet id <ASCourseProvider> courseProvider;
@property (nonatomic,assign) IBOutlet ASOcourseDocument *document;

- (CGColorRef)overprintColor;
- (void)updateCache;

@end

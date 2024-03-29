//
//  ASOverprintController.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASCourseObject.h"
#import "ASMapProvider.h"

// Users of the overprint and/or the control description can observe
// "course" to know when to update.

// - Constructs a list of course items to display for a selected course.
// - If no course is selected, all course items are shown.
// - The position of the control number depends on the selected course.
// - No control description can be generated for forked "super"-courses?

@class ASOcourseDocument;

@interface ASOverprintController : NSObject <ASOverprintProvider> {
    NSManagedObject *course;
    ASOcourseDocument *__weak document;
    
    CGColorRef _overprintColor;
    CGColorRef _transparentOverprintColor;
    
    NSData *cachedCuts;
    
    BOOL drawConnectingLines;
    
    ASOverprintController *masterController;
}
@property (nonatomic,weak) IBOutlet id <ASCourseDataSource> dataSource;
@property (nonatomic,weak) IBOutlet ASOcourseDocument *document;
@property (nonatomic,strong) NSArray *cacheArray;
@property (nonatomic,strong) NSDictionary *controlDigitAttributes;
@property (nonatomic,strong) ASOverprintController *_layoutProxy;

- (CGColorRef)overprintColor;
- (ASOverprintController *)layoutProxy;

- (void)teardown;
@end

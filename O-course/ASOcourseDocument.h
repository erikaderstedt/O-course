//
//  ASOcourseDocument.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-06.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ASMapView;
@class Project;
@class ASOverprintController;
@class ASCourseController;

@interface ASOcourseDocument : NSPersistentDocument {
@private
	ASMapView *mapView;
    ASOverprintController *overprintController;
    ASCourseController *courseController;
}
@property (nonatomic,retain) IBOutlet ASMapView *mapView;
@property (nonatomic,retain) IBOutlet ASOverprintController *overprintController;
@property (nonatomic,retain) IBOutlet ASCourseController *courseController;

- (Project *)project;
- (IBAction)chooseBackgroundMap:(id)sender;
- (void)updateMap:(NSNotification *)n;

@end

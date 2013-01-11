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

@interface ASOcourseDocument : NSDocument {
@private
	ASMapView *mapView;
    ASOverprintController *overprintController;
    ASCourseController *courseController;
    NSObjectController *projectController;
    
    NSPersistentStoreCoordinator *_psc;
	NSManagedObjectContext *_context;
	NSManagedObjectModel *_model;
}
@property (nonatomic,retain) IBOutlet ASMapView *mapView;
@property (nonatomic,retain) IBOutlet ASOverprintController *overprintController;
@property (nonatomic,retain) IBOutlet ASCourseController *courseController;
@property (nonatomic,retain) IBOutlet NSObjectController *projectController;
@property (nonatomic,retain) NSURL *mapURL;

- (NSManagedObjectContext *)managedObjectContext;

- (Project *)project;
- (IBAction)chooseBackgroundMap:(id)sender;
- (void)updateMap:(NSNotification *)n;

- (void)setMapURL:(NSURL *)mapURL;

@end

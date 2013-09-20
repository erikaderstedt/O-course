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
    NSObjectController *__weak projectController;
    
    NSPersistentStoreCoordinator *_psc;
	NSManagedObjectContext *_context;
	NSManagedObjectModel *_model;
}
@property (nonatomic,weak) IBOutlet ASMapView *mapView;
@property (nonatomic,strong) IBOutlet ASOverprintController *overprintController;
@property (nonatomic,strong) IBOutlet ASCourseController *courseController;
@property (nonatomic,weak) IBOutlet NSObjectController *projectController;
@property (nonatomic,strong) NSURL *mapURL;
@property (strong) NSURL *loadedURL;
@property (nonatomic,weak) IBOutlet NSPopover *eventInfoPopover;

- (IBAction)changeEventInfoOK:(id)sender;
- (IBAction)changeEventInfoCancel:(id)sender;

- (NSManagedObjectContext *)managedObjectContext;

- (Project *)project;
- (IBAction)chooseBackgroundMap:(id)sender;
- (void)updateMap:(NSNotification *)n;

- (void)setMapURL:(NSURL *)mapURL;

+ (NSWindow *)windowForManagedObjectContext:(NSManagedObjectContext *)context ;
@end

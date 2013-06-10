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
@property (nonatomic,assign) IBOutlet ASMapView *mapView;
@property (nonatomic,assign) IBOutlet ASOverprintController *overprintController;
@property (nonatomic,assign) IBOutlet ASCourseController *courseController;
@property (nonatomic,assign) IBOutlet NSObjectController *projectController;
@property (nonatomic,retain) NSURL *mapURL;
@property (nonatomic,assign) IBOutlet NSPopover *controlDefinitionsPopover;
@property (nonatomic,assign) IBOutlet NSToolbarItem *showControlDefinitionsToolbarItem;

- (IBAction)showControlDefinitionsPopover:(id)sender;

- (NSManagedObjectContext *)managedObjectContext;

- (Project *)project;
- (IBAction)chooseBackgroundMap:(id)sender;
- (void)updateMap:(NSNotification *)n;

- (void)setMapURL:(NSURL *)mapURL;

+ (NSWindow *)windowForManagedObjectContext:(NSManagedObjectContext *)context ;
@end

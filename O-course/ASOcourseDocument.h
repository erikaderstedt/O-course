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
	ASMapView *__weak mapView;
    ASOverprintController *__weak overprintController;
    ASCourseController *__weak courseController;
    NSObjectController *__weak projectController;
    
    NSPersistentStoreCoordinator *_psc;
	NSManagedObjectContext *_context;
	NSManagedObjectModel *_model;
}
@property (nonatomic,weak) IBOutlet ASMapView *mapView;
@property (nonatomic,weak) IBOutlet ASOverprintController *overprintController;
@property (nonatomic,weak) IBOutlet ASCourseController *courseController;
@property (nonatomic,weak) IBOutlet NSObjectController *projectController;
@property (nonatomic,strong) NSURL *mapURL;
@property (nonatomic,weak) IBOutlet NSPopover *controlDefinitionsPopover;
@property (nonatomic,weak) IBOutlet NSToolbarItem *showControlDefinitionsToolbarItem;

- (IBAction)showControlDefinitionsPopover:(id)sender;

- (NSManagedObjectContext *)managedObjectContext;

- (Project *)project;
- (IBAction)chooseBackgroundMap:(id)sender;
- (void)updateMap:(NSNotification *)n;

- (void)setMapURL:(NSURL *)mapURL;

+ (NSWindow *)windowForManagedObjectContext:(NSManagedObjectContext *)context ;
@end

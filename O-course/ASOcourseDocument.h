//
//  ASOcourseDocument.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-06.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASMapProvider.h"

@class ASMapView;
@class Project;
@class ASOverprintController;
@class ASCourseController;
@class BackgroundMap;

@interface ASOcourseDocument : NSPersistentDocument <ASBackgroundImageLoaderDelegate> {
@private
    NSObjectController *__weak projectController;
    
    dispatch_semaphore_t loader;
    dispatch_queue_t queue;
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

- (Project *)project;
- (IBAction)chooseBackgroundMap:(id)sender;
- (void)updateMap:(NSNotification *)n;

- (void)clearMapBookmarks;
- (BackgroundMap *)mapInfoForFile:(NSString *)file;

- (void)setMapURL:(NSURL *)mapURL;
- (void)loadCoursesFromMap;
+ (NSWindow *)windowForManagedObjectContext:(NSManagedObjectContext *)context;

@end

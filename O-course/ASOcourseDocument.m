//
//  ASOcourseDocument.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-06.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOcourseDocument.h"
#import "ASOCADController.h"
#import "ASGenericImageController.h"
#import "ASMapView.h"
#import "Project.h"
#import "ASOverprintProvider.h"

#import "ASOverprintController.h"
#import "ASCourseController.h"

@implementation ASOcourseDocument
@synthesize mapView;
@synthesize overprintController, courseController;
@synthesize projectController;

- (id)initWithType:(NSString *)type error:(NSError **)error {
    self = [super initWithType:type error:error];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        
        // Create a project object.
        [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:[self managedObjectContext]];
        
		[[self managedObjectContext] processPendingChanges];
		[[[self managedObjectContext] undoManager] removeAllActions];
		[self updateChangeCount:NSChangeCleared];
    }
    return self;
}

- (Project *)project {
    return [projectController valueForKeyPath:@"content"];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"ASOcourseDocument";
}

- (void)setDisplayName:(NSString *)displayNameOrNil {
    [super setDisplayName:displayNameOrNil];

    NSString *newName = nil;
    Project *p = [projectController valueForKey:@"content"];
    
    if (displayNameOrNil != nil) {
        if (![[p valueForKey:@"event"] isEqualToString:displayNameOrNil]) 
            newName = displayNameOrNil;        
    } else {
        NSString *unknown = NSLocalizedString(@"Unknown event", nil);
        if (![[p valueForKey:@"event"] isEqualToString:unknown])
            newName = unknown;
    }

    if (newName != nil) {
        [p setValue:newName forKey:@"event"];
        [courseController.mainControlDescription setNeedsDisplay:YES];
    }
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_6
    [[aController window] setCollectionBehavior:([[aController window] collectionBehavior] | NSWindowCollectionBehaviorFullScreenPrimary)];
#endif 
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (IBAction)chooseBackgroundMap:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowedFileTypes:[NSArray arrayWithObjects:@"pdf",@"ocd", @"tiff",@"jpg",@"jpeg",@"gif",@"tif", nil]];
    [op setAllowsOtherFileTypes:YES];
    [op setAllowsMultipleSelection:NO];
    [op beginSheetModalForWindow:[mapView window] completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            NSURL *u = [op URL];
            NSAssert([u isFileURL], @"Not a file URL!");
            [self project].map = [u path];        
        }
    }
    ];
}

- (void)updateMap:(NSNotification *)n {
    Project *project = [projectController valueForKey:@"content"];
    NSString *path = project.map;

    if (project == nil || path == nil) {
        mapView.mapProvider = nil;
    } else {
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            // TODO: initiate a spotlight search to find the file.
            mapView.mapProvider = nil;
        } else if ([[path pathExtension] isEqualToString:@"ocd"]) {
            ASOCADController *o = [[ASOCADController alloc] initWithOCADFile:path];
            [o prepareCacheWithAreaTransform:CGAffineTransformIdentity];
            mapView.mapProvider = o;
            [o autorelease];
        } else {
            ASGenericImageController *i = [[ASGenericImageController alloc] initWithContentsOfFile:path];
            mapView.mapProvider = i;
        }
    }
    
    [mapView mapLoaded];
}

- (void)awakeFromNib {
    [projectController addObserver:self forKeyPath:@"content.map" options:NSKeyValueObservingOptionInitial context:NULL];
    
    [courseController setManagedObjectContext:[self managedObjectContext]];
    [courseController willAppear];
}

- (void)windowWillClose:(NSNotification *)notification {
    [projectController removeObserver:self forKeyPath:@"content.map"];
    
    [courseController setManagedObjectContext:nil];
    [courseController willDisappear];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == projectController) {
        [self updateMap:nil];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [projectController release];
    
    [super dealloc];
}

- (IBAction)zoomIn:(id)sender {
    mapView.zoom = (1.1)* mapView.zoom;
}
- (IBAction)zoomOut:(id)sender {
    mapView.zoom = (1.0/1.1)* mapView.zoom;
}

@end

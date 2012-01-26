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

- (id)initWithType:(NSString *)type error:(NSError **)error {
    self = [super initWithType:type error:error];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        
        // Create a project object.
        NSLog(@"Creating a new project");
        [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:[self managedObjectContext]];
    }
    return self;
}

- (Project *)project {
    return [Project projectInManagedObjectContext:[self managedObjectContext]];
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
    Project *p = [Project projectInManagedObjectContext:[self managedObjectContext]];
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
    NSString *path = [[self project] valueForKey:@"map"];
    if (path == nil) {
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMap:) name:@"ASMapChangedNotification" object:[self managedObjectContext]];
    
    [self updateMap:nil];
    
    [courseController setManagedObjectContext:[self managedObjectContext]];
    [courseController willAppear];
}

- (void)windowWillClose:(NSNotification *)notification {
    [courseController setManagedObjectContext:nil];
    [courseController willDisappear];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)zoomIn:(id)sender {
    mapView.zoom = (1.1)* mapView.zoom;
}
- (IBAction)zoomOut:(id)sender {
    mapView.zoom = (1.0/1.1)* mapView.zoom;
}

@end

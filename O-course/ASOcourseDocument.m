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

@implementation ASOcourseDocument
@synthesize mapView;

- (id)initWithType:(NSString *)type error:(NSError **)error {
    self = [super initWithType:type error:error];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        
        // Create a project object.
        [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:[self managedObjectContext]];
    }
    return self;
}

- (Project *)project {
    NSFetchRequest *request = [[self managedObjectModel] fetchRequestTemplateForName:@"THE_PROJECT"];
    NSError *error = nil;
    NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:&error];
    if (results == nil || [results count] == 0) {
        NSLog(@"Error fetching project: %@", error);
        NSAssert(0, @"No use continuing now :(");
    }
    return [results objectAtIndex:0];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"ASOcourseDocument";
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

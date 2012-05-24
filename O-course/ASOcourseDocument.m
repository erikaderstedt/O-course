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
    Project *p = [self project];
    
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
    
- (void)setMapURL:(NSURL *)u {
    // Add a document-scoped bookmark.
    NSError *error = nil;
    NSData *bookmarkData = [u bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope 
                       includingResourceValuesForKeys:nil 
                                        relativeToURL:[self fileURL] 
                                                error:&error];
    if (bookmarkData == nil) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    } else {
        [[self project] setMapBookmark:bookmarkData];
    }    
}

- (IBAction)chooseBackgroundMap:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowedFileTypes:[NSArray arrayWithObjects:@"pdf",@"ocd", @"tiff",@"jpg",@"jpeg",@"gif",@"tif", nil]];
    [op setAllowsOtherFileTypes:YES];
    [op setAllowsMultipleSelection:NO];
    [op beginSheetModalForWindow:[mapView window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *u = [op URL];
            NSAssert([u isFileURL], @"Not a file URL!");
            
            [self setMapURL:u];
        }
    }
    ];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
    if ([super readFromURL:absoluteURL ofType:typeName error:outError]) {
        [self updateMap:nil];
        return YES;
    }
    return NO;
}

- (void)updateMap:(NSNotification *)n {
    Project *project = [self project];
    NSData *bookmarkData = [project mapBookmark];

    if (project == nil || bookmarkData == nil) {
        mapView.mapProvider = nil;
    } else {
        BOOL stale;
        NSError *error = nil;
        NSURL *u = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:[self fileURL] bookmarkDataIsStale:&stale error:&error];

        if (u != nil && !stale) {
            [u startAccessingSecurityScopedResource];
            NSString *s = [u path];
            if ([[s pathExtension] isEqualToString:@"ocd"]) {
                ASOCADController *o = [[ASOCADController alloc] initWithOCADFile:s];
                [o prepareCacheWithAreaTransform:CGAffineTransformIdentity];
                mapView.mapProvider = o;
                [o autorelease];
            } else {
                ASGenericImageController *i = [[ASGenericImageController alloc] initWithContentsOfFile:s];
                mapView.mapProvider = i;
            }
            [u stopAccessingSecurityScopedResource];
        }
    }
    
    [mapView mapLoaded];
}

- (void)awakeFromNib {
    [self.projectController addObserver:self forKeyPath:@"content.mapBookmark" options:NSKeyValueObservingOptionInitial context:NULL];
    
    [self.courseController setManagedObjectContext:[self managedObjectContext]];
    [self.courseController willAppear];
}

- (void)windowWillClose:(NSNotification *)notification {
    [self.projectController removeObserver:self forKeyPath:@"content.mapBookmark"];
    
    [self.courseController setManagedObjectContext:nil];
    [self.courseController willDisappear];
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

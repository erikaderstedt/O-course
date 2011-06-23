//
//  ASOcourseDocument.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-06.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOcourseDocument.h"
#import "ASOCADController.h"
#import "ASMapView.h"

@implementation ASOcourseDocument
@synthesize mapView;

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    }
    return self;
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

- (void)awakeFromNib {
    ASOCADController *o = [[ASOCADController alloc] initWithOCADFile:@"/Users/erik/Documents/Orientering/OCAD-filer/Kastellegarden_ver_1_3_100302.ocd"];
//	ASOCADController *o = [[ASOCADController alloc] initWithOCADFile:@"/Users/erik/Documents/Orientering/Stor-kungälv_1_06_090426_ocad 9.ocd"];
    mapView.mapProvider = o;
    [mapView mapLoaded];
}

- (IBAction)zoomIn:(id)sender {
    mapView.zoom = (1.1)* mapView.zoom;
}
- (IBAction)zoomOut:(id)sender {
    mapView.zoom = (1.0/1.1)* mapView.zoom;
}

@end

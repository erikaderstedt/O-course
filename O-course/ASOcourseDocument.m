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
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    // @"/Users/erik/Documents/Orientering/Stor-kungälv_1_06_090426_ocad 9.ocd"
	// Guddehjälm_1_04_090804.ocd
    // 
//    ASOCADController *o = [[ASOCADController alloc] initWithOCADFile:@"/Users/erik/Documents/Orientering/Bottenstugan_Braseröd_1_2_090123_ocad9.ocd"];
//    ASOCADController *o = [[ASOCADController alloc] initWithOCADFile:@"/Users/erik/Documents/Orientering/Stor-kungälv_1_06_090426_ocad 9.ocd"];
}

- (void)awakeFromNib {
    ASOCADController *o = [[ASOCADController alloc] initWithOCADFile:@"/Users/erik/Desktop/Gudde.ocd"];
//	ASOCADController *o = [[ASOCADController alloc] initWithOCADFile:@"/Users/erik/Documents/Orientering/Stor-kungälv_1_06_090426_ocad 9.ocd"];
    mapView.mapProvider = o;
    [mapView mapLoaded];
}

@end

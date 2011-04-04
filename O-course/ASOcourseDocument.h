//
//  ASOcourseDocument.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-06.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ASMapView;

@interface ASOcourseDocument : NSPersistentDocument {
@private
	ASMapView *mapView;
}
@property (nonatomic,retain) IBOutlet ASMapView *mapView;

@end

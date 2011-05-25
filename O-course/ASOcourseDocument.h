//
//  ASOcourseDocument.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-02-06.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ASOcourseDocument : NSPersistentDocument {
@private
	NSView *mapView;
}
@property (nonatomic,retain) IBOutlet NSView *mapView;

@end

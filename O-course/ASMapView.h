//
//  ASMapView.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-04.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASMapViewDelegate.h"

@interface ASMapView : NSView {
	id <ASMapViewDelegate> delegate;
}
@property(nonatomic,retain) id <ASMapViewDelegate> delegate;

@end

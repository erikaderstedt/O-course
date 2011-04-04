//
//  ASMapView.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-04.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASMapView.h"
#define LogR(t,z) NSLog(@"%@: {{%.0f, %.0f}, {%.0f, %.0f}}", t, z.origin.x, z.origin.y, z.size.width, z.size.height)


@implementation ASMapView

@synthesize delegate;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc {
	[delegate release];
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
	NSRect frame = [self bounds];
	NSRect q = [delegate mapBounds];
	LogR(@"bounds", q);

    
    // Drawing code here.
	NSImage *i = [delegate renderedMapWithImageSize:frame.size atPoint:NSMakePoint(NSMidX(q), NSMidY(q))];
	[i drawInRect:frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	
}

@end

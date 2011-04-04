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
@synthesize cachedImage;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc {
	[delegate release];
	[cachedImage release];
	
	[super dealloc];
}

- (void)mapLoaded {
	zoom = 1.0; // Reset zoom.
	mapBounds = [delegate mapBounds];
	[delegate beginRenderingMapWithImageSize:[self frame].size fromSourceRect:mapBounds whenDone:^(NSImage *i) {
		[self performSelectorOnMainThread:@selector(setCachedImage:) withObject:i waitUntilDone:YES];
		[self setNeedsDisplay:YES];
	}];
}
	
- (void)setFrameSize:(NSSize)newSize {
	[super setFrameSize:newSize];
	[delegate beginRenderingMapWithImageSize:newSize fromSourceRect:mapBounds whenDone:^(NSImage *i) {
		[self performSelectorOnMainThread:@selector(setCachedImage:) withObject:i waitUntilDone:YES];
		[self setNeedsDisplay:YES];
	}];
}

- (void)drawRect:(NSRect)dirtyRect {
	NSRect frame = [self bounds];
    
    // Drawing code here.
	
	[self.cachedImage drawInRect:frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	
}

@end

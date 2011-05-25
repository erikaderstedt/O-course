//
//  ASOCADRenderingOperation.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-04.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOCADRenderingOperation.h"

@implementation ASOCADRenderingOperation

@synthesize ocdf=_ocdf;
@synthesize startIndex=_startIndex;
@synthesize stopIndex=_stopIndex;
@synthesize cachedDrawingInformation=_cachedDrawingInformation;
@synthesize transform=_transform;
@synthesize size=_size;
@synthesize result;

- (void)main {
	result = [[NSImage alloc] initWithSize:_size]; 
	[result lockFocus];
	if (_startIndex == 0) {
		[[NSColor whiteColor] set];
		[NSBezierPath fillRect:NSMakeRect(0.0, 0.0, _size.width, _size.height)];
	}
	
	[_transform concat];
	
	// Draw into the image.
	NSInteger i;
	NSDictionary *info;
	for (i = _startIndex; i < _stopIndex; i++) {
		
		// Periodically check to see if we are cancelled.
		if (!(i & 31) && [self isCancelled]) {
			[result unlockFocus];
			[result release];
			result = nil;
			return;
		}
		info = [_cachedDrawingInformation objectAtIndex:i];
		NSBezierPath *path = [info objectForKey:@"path"];
		NSColor *stroke = [info objectForKey:@"strokeColor"];
		NSColor *fill = [info objectForKey:@"fillColor"];
		
		if (fill != nil) {
			[fill set];
			[path fill];
		}
		if (stroke != nil) {
			[stroke set];
			[path stroke];
		}
		
	}
	[result unlockFocus];
}

- (void)dealloc {
	[_transform release];
	[result release];
	[super dealloc];
}

@end

@implementation ASOCADFinishRenderingOperation

@synthesize renderingOperations;

- (void)main {
	// Composite images.
	NSSize baseSize = [[[renderingOperations objectAtIndex:0] result] size];
	NSImage *composited = [[[NSImage alloc] initWithSize:baseSize] autorelease];
	[composited lockFocus];
	for (ASOCADRenderingOperation *op in renderingOperations) {
		NSImage *opImage = [op result];
		[opImage drawInRect:NSMakeRect(0.0, 0.0, baseSize.width, baseSize.height) 
				   fromRect:NSZeroRect 
				  operation:NSCompositeSourceOver 
				   fraction:1.0];
		if ([self isCancelled]) {
			[composited unlockFocus];
			return;
		}
	}
	[composited unlockFocus];

	// Execute "when done". Race condition?
	if (![self isCancelled]) 
		whenDone(composited); 
}

- (void)setWhenDone:(void (^)(NSImage *i))completionBlock {
	whenDone = Block_copy(completionBlock);
}

- (void)dealloc {
	[renderingOperations release];
	Block_release(whenDone);
	[super dealloc];
}

@end


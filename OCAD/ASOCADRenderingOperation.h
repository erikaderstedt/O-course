//
//  ASOCADRenderingOperation.h
//  O-course
//
//  Created by Erik Aderstedt on 2011-04-04.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ocdimport.h"


@interface ASOCADRenderingOperation : NSOperation
{
	struct ocad_file *_ocdf;
	NSArray *_cachedDrawingInformation;
	NSInteger _startIndex;
	NSInteger _stopIndex;
	NSAffineTransform *_transform;
	NSSize _size;
	
	NSImage *result;
}
@property (assign) NSInteger startIndex;
@property (assign) NSInteger stopIndex;
@property (assign) NSArray *cachedDrawingInformation;
@property (assign) struct ocad_file *ocdf;
@property (nonatomic,retain) NSAffineTransform *transform;
@property (retain, readonly) NSImage *result;
@property (assign) NSSize size;

@end

@interface ASOCADFinishRenderingOperation : NSOperation 
{
	NSArray *renderingOperations;
	void (^whenDone)(NSImage *);
}
@property (nonatomic, retain) NSArray *renderingOperations;

- (void)setWhenDone:(void (^)(NSImage *i))completionBlock;

@end
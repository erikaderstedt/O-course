#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include "ASOCADController.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    UInt8 buffer[1024];
    if (!CFURLGetFileSystemRepresentation(url, true, buffer, 1024))
        return 1;
    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    ASOCADController *ocad = [[ASOCADController alloc] initWithOCADFile:[(NSURL *)url path]];
    
   // Get the bounds.
    // Calculate appropriate scaling, so that the longest dimension is 2048 pixels, and the other is scaled with
    // a preserved aspect ratio.
    CGRect r = NSRectToCGRect([ocad mapBounds]);
    CGFloat scalingFactor;
    scalingFactor = ((r.size.height/maxSize.height > r.size.width/maxSize.width)?(r.size.height/maxSize.height):(r.size.width/maxSize.width)) / 2048.0;
    
    CGSize thumbnailSize = CGSizeMake(r.size.width / scalingFactor, r.size.height / scalingFactor);
    
    // Since we're halfway (having loaded the file, but not drawn anything), we check
    // to see if we are cancelled.
    if (!QLThumbnailRequestIsCancelled(thumbnail)) {
        CGContextRef ctx = QLThumbnailRequestCreateContext(thumbnail, thumbnailSize, true, nil);
        
        // Set up a transform
        CGAffineTransform t = CGAffineTransformMake(1.0/scalingFactor, 0.0, 0.0, 1.0/scalingFactor, -CGRectGetMinX(r)/scalingFactor, -CGRectGetMinY(r)/scalingFactor);
        
        CGContextConcatCTM(ctx, t);
        CGFloat white[4] = {1.0,1.0,1.0,1.0};
        CGContextSetFillColor(ctx, white);
        CGContextFillRect(ctx, r);
        
        [ocad drawLayer:NULL inContext:ctx];
        QLThumbnailRequestFlushContext(thumbnail, ctx);
    }   
    
    [ocad release];
    [pool release];
    return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}

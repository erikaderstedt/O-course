#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include "ASOCADController.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
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
    printf("%.2f %.2f\t%.2f %.2f\n", r.origin.x, r.origin.y, r.size.width, r.size.height);
    CGFloat scalingFactor;
    scalingFactor = ((r.size.height > r.size.width)?r.size.height:r.size.width) / 2048.0;
    CGSize previewSize = CGSizeMake(r.size.width / scalingFactor, r.size.height / scalingFactor);
    
    // Since we're halfway (having loaded the file, but not drawn anything), we check
    // to see if we are cancelled.
    if (!QLPreviewRequestIsCancelled(preview)) {
        CGContextRef ctx = QLPreviewRequestCreateContext(preview, previewSize, true, NULL);
        
        // Set up a transform
        CGAffineTransform t = CGAffineTransformMake(1.0/scalingFactor, 0.0, 0.0, 1.0/scalingFactor, -CGRectGetMinX(r)/scalingFactor, -CGRectGetMinY(r)/scalingFactor);
        
        CGContextConcatCTM(ctx, t);
        CGFloat white[4] = {1.0,1.0,1.0,1.0};
        CGContextSetFillColor(ctx, white);
        CGContextFillRect(ctx, r);

        [ocad drawLayer:NULL inContext:ctx];
        QLPreviewRequestFlushContext(preview, ctx);
    }   
    
    [ocad release];
    [pool release];
    
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
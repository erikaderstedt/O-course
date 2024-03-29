#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include "ASOCADController.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview);
/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    UInt8 buffer[1024];
    if (!CFURLGetFileSystemRepresentation(url, true, buffer, 1024))
        return 1;
 
    @autoreleasepool {
    
        ASOCADController *ocad = [[ASOCADController alloc] initWithOCADFile:[(__bridge NSURL *)url path]];
        
        if (ocad == nil) {
            return noErr;
        }
        
        CGFloat requestedWidth = [[(__bridge NSDictionary *)options objectForKey:(id)kQLPreviewPropertyWidthKey] doubleValue];
        CGFloat requestedHeight = [[(__bridge NSDictionary *)options objectForKey:(id)kQLPreviewPropertyHeightKey] doubleValue];
        if (requestedWidth == 0.0) requestedWidth = 2048.0;
        if (requestedHeight == 0.0) requestedHeight = 2048.0;
        // Get the bounds.
        // Calculate appropriate scaling, so that the longest dimension is 2048 pixels, and the other is scaled with
        // a preserved aspect ratio.
        CGRect r = [ocad mapBounds];
        CGFloat scalingFactor;
        scalingFactor = ((r.size.height/requestedHeight > r.size.width/requestedWidth)?(r.size.height/requestedHeight):(r.size.width/requestedWidth));
        CGSize previewSize = CGSizeMake(r.size.width / scalingFactor, r.size.height / scalingFactor);
 
        CGAffineTransform t = CGAffineTransformMake(1.0/scalingFactor, 0.0, 0.0, 1.0/scalingFactor, -CGRectGetMinX(r)/scalingFactor, -CGRectGetMinY(r)/scalingFactor);
        if (!QLPreviewRequestIsCancelled(preview)) {
            [ocad prepareCacheWithAreaTransform:t];
        }

        // Since we're halfway (having loaded the file, but not drawn anything), we check
        // to see if we are cancelled.
        if (!QLPreviewRequestIsCancelled(preview)) {        
            CGContextRef ctx = QLPreviewRequestCreateContext(preview, previewSize, true, NULL);
            CGContextConcatCTM(ctx, t);
            CGFloat white[4] = {1.0,1.0,1.0,1.0};
            CGContextSetFillColor(ctx, white);
            CGContextFillRect(ctx, r);

            [ocad drawLayer:NULL inContext:ctx];
            QLPreviewRequestFlushContext(preview, ctx);
            
            CGContextRelease(ctx);
        }   
        
        
        return noErr;
    }
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
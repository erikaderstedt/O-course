//
//  ASMapView+Dragging.m
//  O-course
//
//  Created by Erik Aderstedt on 2013-09-26.
//  Copyright (c) 2013 Aderstedt Software AB. All rights reserved.
//

#import "ASMapView+Dragging.h"
#import "ASMapView+Layout.h"
#import "ASLayoutController.h"
#import "Layout.h"

@implementation ASMapView (Dragging)

- (NSArray *)draggingTypes {
    return [[NSImage imagePasteboardTypes] arrayByAddingObjectsFromArray:@[NSPasteboardURLReadingFileURLsOnlyKey, NSFilenamesPboardType]];
}

- (CGPoint)dragOperationPositionInPaperCoordinates:(id < NSDraggingInfo >)sender {
    // Get the position in view coordinates.
    NSPoint p = [self convertPoint:[sender draggingLocation] fromView:nil];
    
    // Convert this to paper coordinates.
    CGPoint p2 = [[self printedMapLayer] convertPoint:p fromLayer:[self layer]];
    
    // Adjust this for the "scale"; the relation
    CGFloat f = [self actualPaperRelatedToPaperOnPage];
    p2.x *= f;
    p2.y *= f;
    
    return p2;
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender {
    if (self.state != kASMapViewLayout) return NSDragOperationNone;
    
    if ([sender draggingSourceOperationMask] & NSDragOperationCopy) {
        return NSDragOperationCopy;
    }
    if ([sender draggingSourceOperationMask] & NSDragOperationLink) {
        return NSDragOperationLink;
    }
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender {
    CGPoint p = [self dragOperationPositionInPaperCoordinates:sender];
    CGRect r = CGRectMake(0.0, 0.0, 1.0, 1.0);
    r.size = [self.layoutController paperSize];
    if ([self.layoutController orientation] == NSLandscapeOrientation) {
        CGFloat h = r.size.height;
        r.size.height = r.size.width;
        r.size.width = h;
    }
    if (!CGRectContainsPoint(r, p)) return NSDragOperationNone;
    
    return [self draggingEntered:sender];
}

- (BOOL)prepareForDragOperation:(id )sender
{
    return YES;
}
                 
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSArray *items = [[sender draggingPasteboard] readObjectsForClasses:@[[NSURL class], [NSImage class]] options:@{}];
    
    if ([items count] == 0) return NO;
    NSObject *draggedItem = items[0];
    NSImage *image;
    
    if ([draggedItem isKindOfClass:[NSImage class]]) {
        image = (NSImage *)draggedItem;
    } else {
        NSAssert([draggedItem isKindOfClass:[NSURL class]], @"Not an URL");
        image = [[NSImage alloc] initWithContentsOfURL:(NSURL *)draggedItem];
    }
    
    if (image == nil) return NO;
    
    CGPoint p = [self dragOperationPositionInPaperCoordinates:sender];  
    // Store this image.
    [self.layoutController addImage:image atLocation:p];
    return YES;
}

@end

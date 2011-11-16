//
//  ASControlDescriptionView.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASControlDescriptionView.h"

#define THICK_LINE  (5.0)
#define THIN_LINE   (2.0)

@implementation ASControlDescriptionView

@synthesize provider;
@synthesize course;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc {
    [provider release];
    [course release];
    [overprintColor release];
    
    [boldAttributes release];
    [regularAttributes release];
    [dimensionsAttributes release];
    
    [super dealloc];
}

- (void)setup {
    NSMutableParagraphStyle *mps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [mps setAlignment:NSCenterTextAlignment];
    boldAttributes = [NSMutableDictionary dictionaryWithObject:mps forKey:NSParagraphStyleAttributeName];
    regularAttributes = [NSMutableDictionary dictionaryWithObject:mps forKey:NSParagraphStyleAttributeName];
    dimensionsAttributes = [NSMutableDictionary dictionaryWithObject:mps forKey:NSParagraphStyleAttributeName];
    [mps release]; 

    [self setOverprintColor:[[self class] defaultOverprintColor]];
    
    // 
    
    [boldAttributes retain];
    [regularAttributes retain];
    [dimensionsAttributes retain];
    
}

- (void)setOverprintColor:(NSColor *)newColor {
    NSColor *oldOverprint = overprintColor;
    overprintColor = [newColor retain];
    [oldOverprint release];
    
    [boldAttributes setObject:overprintColor forKey:NSForegroundColorAttributeName];
    [regularAttributes setObject:overprintColor forKey:NSForegroundColorAttributeName];
    [dimensionsAttributes setObject:overprintColor forKey:NSForegroundColorAttributeName];
    
    [self setNeedsDisplay:YES];
}

+ (NSColor *)defaultOverprintColor {
    CGFloat comps[5] = {0.0, 1.0, 0.0, 0.0, 1.0};
    return [NSColor colorWithColorSpace:[NSColorSpace genericCMYKColorSpace] 
                             components:comps
                                  count:5];

}

- (NSInteger)numberOfItems {
    NSInteger numberOfItems;
    
    numberOfItems = [[[self.provider courseObjectEnumeratorForCourse:self.course] allObjects] count];
    if ([self.provider eventName]) numberOfItems++;
    if ([self.provider classNamesForCourse:self.course]) numberOfItems ++;
    if ([self.provider numberForCourse:self.course] || [self.provider lengthOfCourse:self.course]) numberOfItems ++;

    return numberOfItems;
}

- (CGFloat)heightForWidth:(CGFloat)width {
    // 8 columns.
    return width / 8.0 * [self numberOfItems];
}

- (void)drawThickGridAtOrigin:(NSPoint)origin blockSize:(CGFloat)blockSize {
    [NSBezierPath setDefaultLineWidth:THICK_LINE];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x + 3.0 * blockSize, origin.y) 
                              toPoint:NSMakePoint(origin.x + 3.0 * blockSize, origin.y + blockSize)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x + 6.0 * blockSize, origin.y) 
                              toPoint:NSMakePoint(origin.x + 6.0 * blockSize, origin.y + blockSize)];
}

- (void)drawThinGridAtOrigin:(NSPoint)origin blockSize:(CGFloat)blockSize {
    [NSBezierPath setDefaultLineWidth:THIN_LINE];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x + 1.0 * blockSize, origin.y) 
                              toPoint:NSMakePoint(origin.x + 1.0 * blockSize, origin.y + blockSize)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x + 2.0 * blockSize, origin.y) 
                              toPoint:NSMakePoint(origin.x + 2.0 * blockSize, origin.y + blockSize)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x + 4.0 * blockSize, origin.y) 
                              toPoint:NSMakePoint(origin.x + 4.0 * blockSize, origin.y + blockSize)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x + 5.0 * blockSize, origin.y) 
                              toPoint:NSMakePoint(origin.x + 5.0 * blockSize, origin.y + blockSize)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x + 7.0 * blockSize, origin.y) 
                              toPoint:NSMakePoint(origin.x + 7.0 * blockSize, origin.y + blockSize)];
}

- (void)drawRect:(NSRect)dirtyRect {
    /*
                    Competition name (date)
                         Class names
                    Course  | Length | Height climb
     */
    
    if ([[NSGraphicsContext currentContext] isDrawingToScreen]) {
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect:dirtyRect];
    }
    
    [overprintColor set];

    CGRect  bounds = [self bounds];
    CGFloat height = [self heightForWidth:bounds.size.width];
    CGFloat y, x;
    CGFloat blockSize = bounds.size.width / 8.0;
    
    x = bounds.origin.x;
    y = height + (0.5 * (bounds.size.height - height));

    // Frame all of it.
    [NSBezierPath setDefaultLineWidth:THICK_LINE];
    [NSBezierPath strokeRect:NSMakeRect(x, y - height, bounds.size.width, height)];
    
    // Draw the name.
    y -= blockSize;
    if ([self.provider eventName] != nil) {
        [[self.provider eventName] drawInRect:NSMakeRect(x, y, bounds.size.width, y + blockSize) 
                               withAttributes:boldAttributes];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) toPoint:NSMakePoint(x + bounds.size.width, y)];
        y -= blockSize;
    }
    
    // The class names.
    if ([self.provider classNamesForCourse:self.course]) {
        [[self.provider classNamesForCourse:self.course] drawInRect:NSMakeRect(bounds.origin.x, y, bounds.size.width, y + blockSize) 
                                                     withAttributes:boldAttributes];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) toPoint:NSMakePoint(x + bounds.size.width, y)];
        y -= blockSize;       
    }
    
    // Draw the course and the distance..
    if ([self.provider numberForCourse:self.course] || [self.provider lengthOfCourse:self.course]) {
        [[self.provider numberForCourse:self.course] drawInRect:NSMakeRect(x, y, 3.0*blockSize, y + blockSize) 
                                                 withAttributes:boldAttributes];
        x += 3.0*blockSize;
        [[self.provider lengthOfCourse:self.course] drawInRect:NSMakeRect(x, y, 3.0*blockSize, y + blockSize) 
                                                 withAttributes:boldAttributes];
        x += 3.0*blockSize;
        [[self.provider heightClimbForCourse:self.course] drawInRect:NSMakeRect(x, y, 2.0*blockSize, y + blockSize) 
                                                withAttributes:boldAttributes];

        x = bounds.origin.x;
        [self drawThickGridAtOrigin:NSMakePoint(x, y) blockSize:blockSize];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) 
                                  toPoint:NSMakePoint(x + bounds.size.width, y)];
        y -= blockSize;
    }
    
    // Draw the items.
    NSInteger i = 0;
    for (id <ASControlDescriptionItem> item in [self.provider courseObjectEnumeratorForCourse:self.course]) {
        enum ControlDescriptionItemType type = [item controlDescriptionItemType];
        if (type == kASStart || type == kASRegularControl) { 
            // Column A.
            if (type == kASStart) {
                //
                i--;
            } else {
                
            }
           
            i ++;
            [NSBezierPath setDefaultLineWidth:(i % 3)?THICK_LINE:THIN_LINE];
            x = bounds.origin.x;
            [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) 
                                      toPoint:NSMakePoint(x + bounds.size.width, y)];
            
            [self drawThickGridAtOrigin:NSMakePoint(x, y) blockSize:blockSize];
            [self drawThinGridAtOrigin:NSMakePoint(x, y) blockSize:blockSize];
        } else {
            // Draw any of the different variations of taped routes.
            // If the previous horizontal divider was drawn with a thin line, we redraw it with a thick line.
            x = bounds.origin.x;
            if (i % 3) {
                [NSBezierPath setDefaultLineWidth:THICK_LINE];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y + blockSize) 
                                          toPoint:NSMakePoint(x + bounds.size.width, y + blockSize)];
            }
            
        }
    }
}

- (NSBezierPath *)bezierPathForTapedRoute:(enum ControlDescriptionItemType)routeType atPosition:(NSPoint)p usingBlockSize:(CGFloat)blockSize {
    [NSBezierPath setDefaultLineWidth:1.0];

    // Start with a circle
    NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(p.x, p.y, blockSize, blockSize)];
    
    // Opening arrow mark.
    if (routeType != kASTapedRouteFromControl && routeType != kASTapedRouteBetweenControls) {
        [bp moveToPoint:NSMakePoint(p.x + 1.5*blockSize, p.y)];
        [bp relativeLineToPoint:NSMakePoint(-0.5*blockSize, 0.5*blockSize)];
        [bp relativeLineToPoint:NSMakePoint(0.5*blockSize, 0.5*blockSize)];
    }
    
    // Draw the end symbol
    if (routeType != kASTapedRouteToMapExchange) {
        NSRect r = NSMakeRect(p.x + 7.0*blockSize, p.y, blockSize, blockSize);
        [bp appendBezierPathWithOvalInRect:r];
        if (routeType == kASTapedRouteToFinish ||
            routeType == kASRouteToFinish ||
            routeType == kASPartlyTapedRouteToFinish) {
            [bp appendBezierPathWithOvalInRect:NSInsetRect(r, -0.07*blockSize, -0.07*blockSize)];
        }
    } else if (routeType != kASTapedRouteFromControl) {
        [bp moveToPoint:NSMakePoint(p.x + 7.0*blockSize, p.y)];
        [bp relativeLineToPoint:NSMakePoint(blockSize, 0.0)];
        [bp relativeLineToPoint:NSMakePoint(-0.5*blockSize, blockSize)];
        [bp closePath];
    }

    // Closing arrow mark
    [bp moveToPoint:NSMakePoint(p.x + 6.5*blockSize, p.y)];
    [bp relativeLineToPoint:NSMakePoint(0.5*blockSize, 0.5*blockSize)];
    [bp relativeLineToPoint:NSMakePoint(-0.5*blockSize, 0.5*blockSize)];
    
    [bp stroke];
  
    
    
}

@end

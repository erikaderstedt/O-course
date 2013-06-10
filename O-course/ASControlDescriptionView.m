//
//  ASControlDescriptionView.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-11-14.
//  Copyright (c) 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASControlDescriptionView.h"
#import "ASDistanceFormatter.h"
#import "CourseObject.h"
#import "ASControlDescriptionView+CourseObjects.h"

#define THICK_LINE  (2.0)
#define THIN_LINE   (1.0)
#define START_FRACTION (0.7)
#define CIRCLE_FRACTION (0.7)
#define ARROW_FRACTION (0.8)
#define INSET_DIST (5.0)
@implementation ASControlDescriptionView

@synthesize provider;

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
    [overprintColor release];
    
    [boldAttributes release];
    [regularAttributes release];
    [dimensionsAttributes release];
    
    [linenTextureColor release];
    [dropShadow release];
    
    [super dealloc];
}

- (void)setup {
    
    linenTextureColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"linen_texture.jpg"]] retain];
    dropShadow = [[NSShadow alloc] init];
    [dropShadow setShadowColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.6]];
    [dropShadow setShadowBlurRadius:5.0];
    [dropShadow setShadowOffset:NSMakeSize(4.0, -4.0)];
    
    NSMutableParagraphStyle *mps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [mps setAlignment:NSCenterTextAlignment];
    boldAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:mps, NSParagraphStyleAttributeName, [NSFont fontWithName:@"Helvetica-Bold" size:16.0], NSFontAttributeName, nil];
    regularAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:mps, NSParagraphStyleAttributeName, [NSFont fontWithName:@"Helvetica" size:14.0], NSFontAttributeName, nil];
    dimensionsAttributes = [NSMutableDictionary dictionaryWithObject:mps forKey:NSParagraphStyleAttributeName];
    [mps release]; 

    [self setOverprintColor:[[self class] defaultOverprintColor]];
    
    // 
    distanceFormatter = [[ASDistanceFormatter alloc] init];
    
    [boldAttributes retain];
    [regularAttributes retain];
    [dimensionsAttributes retain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(courseChanged:) name:@"ASOverprintChanged" object:nil];
}

- (void)courseChanged:(NSNotification *)n {
    [self recalculateLayout];
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

- (void)recalculateLayout {
    CGRect  bounds = [self bounds];
    bounds = CGRectInset(bounds, INSET_DIST*2.0, INSET_DIST*2.0);

    CGFloat height = [self heightForWidth:bounds.size.width];
    if (height == 0.0) {
        blockSize = 0.0;
        actualDescriptionBounds = CGRectZero;
        return;
    }
    
    CGFloat y, x;
    
    blockSize = bounds.size.width / 8.0;
    
    x = bounds.origin.x;
    y = height + (0.5 * (bounds.size.height - height));
    paperBounds = CGRectMake(x, y - height, bounds.size.width, height);
    actualDescriptionBounds = CGRectInset(paperBounds, -INSET_DIST, -INSET_DIST);
    
    [self updateTrackingAreas];
    layoutNeedsUpdate = NO;
    [self setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize {
    layoutNeedsUpdate = YES;
    [super setFrameSize:newSize];
}

- (NSInteger)numberOfItems {
    NSInteger numberOfItems;
    
    numberOfItems = [[[self.provider courseObjectEnumerator] allObjects] count];
    if ([self.provider eventName]) numberOfItems++;
    if ([self.provider classNames]) numberOfItems ++;
    if ([self.provider number] || [self.provider length]) numberOfItems ++;

    return numberOfItems;
}

- (CGFloat)heightForWidth:(CGFloat)width {
    // 8 columns.
    return width / 8.0 * [self numberOfItems];
}

- (void)drawThickGridAtOrigin:(NSPoint)origin {
    [NSBezierPath setDefaultLineWidth:THICK_LINE];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x + 3.0 * blockSize, origin.y) 
                              toPoint:NSMakePoint(origin.x + 3.0 * blockSize, origin.y + blockSize)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x + 6.0 * blockSize, origin.y) 
                              toPoint:NSMakePoint(origin.x + 6.0 * blockSize, origin.y + blockSize)];
}

- (void)drawThinGridAtOrigin:(NSPoint)origin {
    origin.y = round(origin.y);
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

- (CGRect)boundsForRow:(NSInteger)rowIndex column:(enum ASControlDescriptionColumn)column {
    CGFloat minY = NSMaxY(paperBounds) - blockSize * (rowIndex + 1);
    CGFloat minX = NSMinX(paperBounds) + blockSize * ((int)column);
    
    return CGRectMake(minX, minY, blockSize, blockSize);
}

- (void)drawRect:(NSRect)dirtyRect {
    /*
                    Competition name (date)
                         Class names
                    Course  | Length | Height climb
     */
    
    if (layoutNeedsUpdate) {
        [self recalculateLayout];
    }
    
    [NSGraphicsContext saveGraphicsState];
    [linenTextureColor set];
    [NSBezierPath fillRect:[self bounds]];
    
    [[NSColor whiteColor] set];
    [dropShadow set];
    [NSBezierPath fillRect:NSRectFromCGRect(actualDescriptionBounds)];
    [NSGraphicsContext restoreGraphicsState];
    
    [overprintColor set];

    // Frame all of it.
    [NSBezierPath setDefaultLineWidth:THICK_LINE];
    [NSBezierPath strokeRect:NSRectFromCGRect(paperBounds)];
    
    CGFloat x, y;
    NSSize sz, block;
    x = CGRectGetMinX(paperBounds);
    y = CGRectGetMaxY(paperBounds);
    block = NSMakeSize(blockSize, blockSize);
    
    // Draw the name.
    y -= blockSize;
    if ([self.provider eventName] != nil) {
        eventBounds = CGRectMake(CGRectGetMinX(paperBounds), CGRectGetMaxY(paperBounds) - blockSize,
                                 paperBounds.size.width, blockSize);
        sz = [[self.provider eventName] boundingRectWithSize:NSSizeFromCGSize(eventBounds.size) 
                                                     options:NSStringDrawingUsesFontLeading 
                                                  attributes:boldAttributes].size;
        NSRect r =  NSRectFromCGRect(eventBounds); 
        r.origin.y = r.origin.y - 0.5*(blockSize - sz.height);
        [[self.provider eventName] drawInRect:NSIntegralRect(r)
                               withAttributes:boldAttributes];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) toPoint:NSMakePoint(x + paperBounds.size.width, y)];
        y -= blockSize;
    }
    
    // The class names.
    if ([self.provider classNames]) {
        [[self.provider classNames] drawInRect:NSMakeRect(paperBounds.origin.x, y, paperBounds.size.width, blockSize) 
                                                     withAttributes:boldAttributes];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) toPoint:NSMakePoint(x + paperBounds.size.width, y)];
        y -= blockSize;       
    }
    
    // Draw the course and the distance..
    if ([self.provider number] || [self.provider length]) {
        [[self.provider number] drawInRect:NSMakeRect(x, y, 3.0*blockSize, blockSize) 
                                                 withAttributes:boldAttributes];
        x += 3.0*blockSize;
        [[self.provider length] drawInRect:NSMakeRect(x, y, 3.0*blockSize, blockSize) 
                                                 withAttributes:boldAttributes];
        x += 3.0*blockSize;
        [[self.provider heightClimb] drawInRect:NSMakeRect(x, y, 2.0*blockSize, blockSize) 
                                                withAttributes:boldAttributes];

        x = paperBounds.origin.x;
        [self drawThickGridAtOrigin:NSMakePoint(x, y)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) 
                                  toPoint:NSMakePoint(x + paperBounds.size.width, y)];
        y -= blockSize;
    }
    
    // Draw the items.
    NSInteger consecutiveRegularControls = 0, controlNumber = 1;
    for (id <ASControlDescriptionItem> item in [self.provider courseObjectEnumerator]) {
        enum ControlDescriptionItemType type = [item controlDescriptionItemType];
        [NSBezierPath setDefaultLineWidth:((++consecutiveRegularControls == 3) || (type == kASStart))?THICK_LINE:THIN_LINE];
        x = paperBounds.origin.x;
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) 
                                  toPoint:NSMakePoint(x + paperBounds.size.width, y)];

        if (type == kASStart || type == kASRegularControl) { 

            [self drawThickGridAtOrigin:NSMakePoint(x, y)];
            [self drawThinGridAtOrigin:NSMakePoint(x, y)];

            if (type == kASRegularControl) {
                // Draw number and control code.
                NSString *s = [NSString stringWithFormat:@"%d", (int)(controlNumber++)];
                sz = [s boundingRectWithSize:block
                                                             options:NSStringDrawingUsesFontLeading 
                                                          attributes:boldAttributes].size;
                [s drawInRect:NSIntegralRect(NSMakeRect(x, y- 0.5*(blockSize - sz.height), blockSize, blockSize)) withAttributes:boldAttributes];
                s = [NSString stringWithFormat:@"%@", [item controlCode]];
                sz = [s boundingRectWithSize:block
                                     options:NSStringDrawingUsesFontLeading 
                                  attributes:regularAttributes].size;
                [s drawInRect:NSIntegralRect(NSMakeRect(x + blockSize+1.0, y- 0.5*(blockSize - sz.height), blockSize, blockSize)) withAttributes:regularAttributes];
                
                if (consecutiveRegularControls == 3) consecutiveRegularControls = 0;
            } else {
                // Draw start symbol.
                [[self bezierPathForStartAtOrigin:NSMakePoint(x, y)] stroke];
                consecutiveRegularControls = 0;
            }
            
            CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
            if (type == kASRegularControl && [item whichOfAnySimilarFeature] != nil) {
                CFArrayRef paths = [self createPathsForColumn:kASWhichOfAnySimilarFeature withValue:[item whichOfAnySimilarFeature] atPosition:CGPointMake(x+2.5*blockSize, y + 0.5*blockSize) withSize:blockSize];
                for (int i = 0; i < CFArrayGetCount(paths); i++) {
                    CGContextBeginPath(ctx);
                    CGContextAddPath(ctx, (CGPathRef)CFArrayGetValueAtIndex(paths, i));
                    CGContextFillPath(ctx);
                }
                CFRelease(paths);
            }
            
            if (type == kASRegularControl && [item controlFeature] != nil) {
                CFArrayRef paths = [self createPathsForColumn:kASFeature withValue:[item controlFeature] atPosition:CGPointMake(x+3.5*blockSize+1.0, y + 0.5*blockSize) withSize:blockSize];
                for (int i = 0; i < CFArrayGetCount(paths); i++) {
                    CGContextBeginPath(ctx);
                    CGContextAddPath(ctx, (CGPathRef)CFArrayGetValueAtIndex(paths, i));
                    CGContextFillPath(ctx);
                }
                CFRelease(paths);
                
            }
        } else {
            // Draw any of the different variations of taped routes.
            // If the previous horizontal divider was drawn with a thin line, we redraw it with a thick line. Always.
            x = paperBounds.origin.x;
            [NSBezierPath setDefaultLineWidth:THICK_LINE];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y + blockSize) 
                                          toPoint:NSMakePoint(x + paperBounds.size.width, y + blockSize)];
            CGFloat blankSegment = 0.0;
            if ([item distance] != nil) {
                NSString *s = [distanceFormatter stringFromNumber:[item distance]];
                sz = [s boundingRectWithSize:NSMakeSize(blockSize * 4.0, blockSize)
                                     options:NSStringDrawingUsesFontLeading 
                                  attributes:regularAttributes].size;
                [s drawInRect:NSIntegralRect(NSMakeRect(x+2.0*blockSize, y - 0.5*(blockSize - sz.height), 4.0*blockSize, blockSize)) withAttributes:regularAttributes];
                blankSegment = sz.width;
            }
            [[self bezierPathForTapedRoute:type atPosition:NSMakePoint(x, y) blankSegment:blankSegment] stroke];
        }
        y -= blockSize;
    }
}

- (NSBezierPath *)bezierPathForTapedRoute:(enum ControlDescriptionItemType)routeType atPosition:(NSPoint)p blankSegment:(CGFloat)leaveThisBlank {
    [NSBezierPath setDefaultLineWidth:THIN_LINE];
    CGFloat center = p.y + 0.5*blockSize;

    // Start with a circle
    NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:NSIntegralRect(NSInsetRect(NSMakeRect(p.x, p.y, blockSize, blockSize), (1.0-CIRCLE_FRACTION)*0.5*blockSize,(1.0-CIRCLE_FRACTION)*0.5*blockSize))];
    
    // Opening arrow mark.
    CGFloat lineStart = 1.0*blockSize;
    if (routeType != kASTapedRouteFromControl && routeType != kASTapedRouteBetweenControls) {
        if (routeType == kASPartlyTapedRouteToFinish) {
            [bp moveToPoint:NSMakePoint(p.x + 1.5*blockSize, p.y + 0.5*(1.0 - ARROW_FRACTION)*blockSize)];
            [bp relativeLineToPoint:NSMakePoint(0.5*blockSize, 0.5*ARROW_FRACTION*blockSize)];
            [bp relativeLineToPoint:NSMakePoint(-0.5*blockSize, 0.5*ARROW_FRACTION*blockSize)];
            lineStart = 2.0*blockSize;
        } else {
            [bp moveToPoint:NSMakePoint(p.x + 1.5*blockSize, p.y + 0.5*(1.0 - ARROW_FRACTION)*blockSize)];
            [bp relativeLineToPoint:NSMakePoint(-0.5*blockSize, 0.5*ARROW_FRACTION*blockSize)];
            [bp relativeLineToPoint:NSMakePoint(0.5*blockSize, 0.5*ARROW_FRACTION*blockSize)];
        }
    }
    
    // Closing arrow mark
    [bp moveToPoint:NSMakePoint(p.x + 6.5*blockSize, p.y + 0.5*(1.0 - ARROW_FRACTION)*blockSize)];
    [bp relativeLineToPoint:NSMakePoint(0.5*blockSize, 0.5*ARROW_FRACTION*blockSize)];
    [bp relativeLineToPoint:NSMakePoint(-0.5*blockSize, 0.5*ARROW_FRACTION*blockSize)];

    if (routeType == kASPartlyTapedRouteToFinish ||
        routeType == kASTapedRouteToFinish ||
        routeType == kASTapedRouteToMapExchange ||
        routeType == kASTapedRouteFromControl ||
        routeType == kASTapedRouteBetweenControls) {
        
        NSBezierPath *tapedRoute = [NSBezierPath bezierPath];
        CGFloat dashes[2] = {0.4*blockSize, 0.075*blockSize};
        
        [tapedRoute setLineDash:dashes count:2 phase:0.0];
        [tapedRoute moveToPoint:NSMakePoint(p.x + lineStart, center)];
        if (leaveThisBlank > 0.0) {
            CGFloat middle = p.x + 0.5*8.0*blockSize;
            [tapedRoute lineToPoint:NSMakePoint(middle - 0.5*(leaveThisBlank + 0.2*blockSize), center)];
            [tapedRoute relativeMoveToPoint:NSMakePoint(leaveThisBlank + 0.2*blockSize, 0.0)];
        }
        [tapedRoute lineToPoint:NSMakePoint(p.x + 7.0*blockSize, center)];
        [bp appendBezierPath:[tapedRoute bezierPathByStrokingPath]];
    }
    
    // Draw the end symbol
    if (routeType != kASTapedRouteToMapExchange) {
        NSRect r = NSIntegralRect(NSInsetRect(NSMakeRect(p.x + 7.0*blockSize, p.y, blockSize, blockSize), (1.0-CIRCLE_FRACTION)*0.5*blockSize,(1.0-CIRCLE_FRACTION)*0.5*blockSize));
        if (routeType == kASTapedRouteToFinish ||
            routeType == kASRouteToFinish ||
            routeType == kASPartlyTapedRouteToFinish) {
            [bp appendBezierPathWithOvalInRect:NSInsetRect(r, -0.04*blockSize, -0.04*blockSize)];
            [bp appendBezierPathWithOvalInRect:NSInsetRect(r, 0.04*blockSize, 0.04*blockSize)];
        } else {
            [bp appendBezierPathWithOvalInRect:r];
            
        }
    } else if (routeType != kASTapedRouteFromControl) {
        [bp moveToPoint:NSMakePoint(p.x + 7.0*blockSize, p.y)];
        [bp relativeLineToPoint:NSMakePoint(blockSize, 0.0)];
        [bp relativeLineToPoint:NSMakePoint(-0.5*blockSize, blockSize)];
        [bp closePath];
    }

    
    return bp;
}

- (NSBezierPath *)bezierPathForStartAtOrigin:(NSPoint)p {
    [NSBezierPath setDefaultLineWidth:THIN_LINE];
    CGFloat leg = round(blockSize*START_FRACTION), x0;
    x0 = 0.5*(blockSize - sin(M_PI/3.0)*leg);
    NSPoint p1, p2, p3;
    p1 = NSMakePoint(round(p.x + x0), round(p.y + (1.0 - START_FRACTION)*0.5*blockSize));
    p2 = NSMakePoint(round(p.x + x0), round(p.y + blockSize - (1.0 - START_FRACTION)*0.5*blockSize));
    p3 = NSMakePoint(round(p.x + blockSize - x0), round(p.y + 0.5*blockSize));
    
    NSBezierPath *bp = [NSBezierPath bezierPath];
    [bp moveToPoint:p1];
    [bp lineToPoint:p2];
    [bp lineToPoint:p3];
    [bp lineToPoint:p1];
    
    return bp;
}

@end

@implementation NSBezierPath (ASDashedBezierPaths)

- (NSBezierPath *)bezierPathByStrokingPath {
    NSBezierPath *output = [NSBezierPath bezierPath];
    NSBezierPath *flattened = [self bezierPathByFlatteningPath];
    
    if ([self elementCount] == 0) return output;
    
    CGFloat dashes[MAX_NUMBER_OF_DASHES];
    NSInteger numDashes;
    CGFloat phase;
    [self getLineDash:dashes count:&numDashes phase:&phase];
    
    NSPoint points[3];
    NSPoint currentPoint, nextPoint;
    CGFloat remainingDistanceOnCurrentDashIndex, f;
    NSInteger dashIndex;
    
    // Find the current dash index, and determine the remaining distance on it.
    NSAssert(phase >= 0.0, @"Negative phase isn't supported.");
    for (dashIndex = 0, f = 0.0; f + dashes[dashIndex] < phase;) {
        f += dashes[dashIndex];
        if (++dashIndex == numDashes) dashIndex = 0;
    }
    if (f == 0.0) return self;
    
    remainingDistanceOnCurrentDashIndex = f + dashes[dashIndex] - phase;
    
    for (NSInteger pointIndex = 0; pointIndex < [flattened elementCount]; pointIndex++) {
        NSBezierPathElement element = [flattened elementAtIndex:pointIndex associatedPoints:points];
        NSAssert(element != NSCurveToBezierPathElement, @"NSBezierPath not flattened?");
        
        if (element == NSMoveToBezierPathElement) {
            [output moveToPoint:points[0]];
        } else if (element == NSLineToBezierPathElement) {
            CGFloat segmentLength = sqrt((currentPoint.x - points[0].x)*(currentPoint.x - points[0].x) + (currentPoint.y - points[0].y)*(currentPoint.y - points[0].y));
            while (segmentLength > 0.0) {
                if (remainingDistanceOnCurrentDashIndex < segmentLength) {
                    double angle = atan2(-(currentPoint.y - points[0].y), -(currentPoint.x - points[0].x));
                    // Calculate the same point at the required angle.
                    nextPoint = NSMakePoint(currentPoint.x + cos(angle)*remainingDistanceOnCurrentDashIndex,
                                            currentPoint.y + sin(angle)*remainingDistanceOnCurrentDashIndex);
                    segmentLength -= remainingDistanceOnCurrentDashIndex;

                    // Switch to the next dash index.
                    if (++dashIndex == numDashes) dashIndex = 0;
                    remainingDistanceOnCurrentDashIndex = dashes[dashIndex];
                    currentPoint = nextPoint;
                } else {
                    // The entire segment is used.
                    nextPoint = points[0];
                    remainingDistanceOnCurrentDashIndex -= segmentLength;
                    segmentLength = 0.0;
                }
                if (dashIndex % 2) {
                    [output lineToPoint:nextPoint];
                } else {
                    [output moveToPoint:nextPoint];
                }
            }
        }
        currentPoint = points[0];
    }
    return output;
}

@end

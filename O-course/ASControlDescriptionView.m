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
    [self setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    
    [self recalculateLayout];
}

- (void)setCourse:(id<NSObject>)_course {
    NSObject *oldCourse = course;
    course = [_course retain];
    [oldCourse release];
    
    [self recalculateLayout];
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

- (void)drawRect:(NSRect)dirtyRect {
    /*
                    Competition name (date)
                         Class names
                    Course  | Length | Height climb
     */
    
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
    if ([self.provider classNamesForCourse:self.course]) {
        [[self.provider classNamesForCourse:self.course] drawInRect:NSMakeRect(paperBounds.origin.x, y, paperBounds.size.width, blockSize) 
                                                     withAttributes:boldAttributes];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) toPoint:NSMakePoint(x + paperBounds.size.width, y)];
        y -= blockSize;       
    }
    
    // Draw the course and the distance..
    if ([self.provider numberForCourse:self.course] || [self.provider lengthOfCourse:self.course]) {
        [[self.provider numberForCourse:self.course] drawInRect:NSMakeRect(x, y, 3.0*blockSize, blockSize) 
                                                 withAttributes:boldAttributes];
        x += 3.0*blockSize;
        [[self.provider lengthOfCourse:self.course] drawInRect:NSMakeRect(x, y, 3.0*blockSize, blockSize) 
                                                 withAttributes:boldAttributes];
        x += 3.0*blockSize;
        [[self.provider heightClimbForCourse:self.course] drawInRect:NSMakeRect(x, y, 2.0*blockSize, blockSize) 
                                                withAttributes:boldAttributes];

        x = paperBounds.origin.x;
        [self drawThickGridAtOrigin:NSMakePoint(x, y)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) 
                                  toPoint:NSMakePoint(x + paperBounds.size.width, y)];
        y -= blockSize;
    }
    
    // Draw the items.
    NSInteger consecutiveRegularControls = 0, controlNumber = 1;
    for (id <ASControlDescriptionItem> item in [self.provider courseObjectEnumeratorForCourse:self.course]) {
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

- (CFArrayRef)createPathsForFeatureOrAppearance:(NSNumber *)value transform:(CGAffineTransform *)tran {
    enum ASFeature feature = (enum ASFeature)[value intValue];
    CGMutablePathRef path = CGPathCreateMutable(), nonfilled = NULL;
    CGPathRef fillable;
    int xindex, yindex;
    
    switch (feature) {
        case kASFeatureTerrace:
            CGPathMoveToPoint(path, NULL, -31.5, 48.5);
            CGPathAddCurveToPoint(path, NULL, -29.5, 42.5, -25.59, 15.49, -25.5, 1.5);
            CGPathAddCurveToPoint(path, NULL, -25.41, -12.49, -27.14, -40.77, -31.5, -51.5);
            
            
            CGPathMoveToPoint(path, NULL, -13.5, 47.5);
            CGPathAddCurveToPoint(path, NULL, -12.5, 43.5, -13.44, 36.84, -7.5, 33.5);
            CGPathAddCurveToPoint(path, NULL, -1.56, 30.16, 24.61, 32.39, 29.5, 25.5);
            CGPathAddCurveToPoint(path, NULL, 34.39, 18.61, 39.26, -20.52, 29.5, -27.5);
            CGPathAddCurveToPoint(path, NULL, 19.74, -34.48, -1.5, -30.26, -7.5, -36.5);
            CGPathAddCurveToPoint(path, NULL, -13.5, -42.74, -11.49, -40.23, -13.5, -51);
            break;            
        case kASFeatureSpur:
            CGPathMoveToPoint(path, NULL, -31.5, 48.5);
            CGPathAddCurveToPoint(path, NULL, -29.5, 42.5, -25.59, 15.49, -25.5, 1.5);
            CGPathAddCurveToPoint(path, NULL, -25.41, -12.49, -27.14, -40.77, -31.5, -51.5);
            
            
            CGPathMoveToPoint(path, NULL, -14.5, 47.5);
            CGPathAddCurveToPoint(path, NULL, -13.5, 37.5, -11.61, 20.18, -6.5, 14.5);
            CGPathAddCurveToPoint(path, NULL, -1.39, 8.82, 40.78, 11.79, 43.5, 7.5);
            CGPathAddCurveToPoint(path, NULL, 46.22, 3.21, 48.17, -8.82, 43.5, -12.5);
            CGPathAddCurveToPoint(path, NULL, 38.83, -16.18, 1.5, -13.88, -6.5, -18.5);
            CGPathAddCurveToPoint(path, NULL, -14.5, -23.12, -13.35, -43.99, -14, -52);
            break;
        case kASFeatureRe_Entrant:
            CGPathMoveToPoint(path, NULL, -55.5, -48.5);
            CGPathAddCurveToPoint(path, NULL, -51.5, -48.5, -37.77, -52.2, -32.5, -43.5);
            CGPathAddCurveToPoint(path, NULL, -27.23, -34.8, -27.6, 38.94, -2.5, 38.5);
            CGPathAddCurveToPoint(path, NULL, 22.6, 38.06, 22.24, -34.69, 29.5, -43.5);
            CGPathAddCurveToPoint(path, NULL, 36.76, -52.31, 43.84, -48.5, 55.5, -48.5);
            break;
        case kASFeatureEarthBank:
            CGPathMoveToPoint(path, NULL, -39.5, 12.5);
            CGPathAddCurveToPoint(path, NULL, -34.5, 8.5, -27.56, 0, 0.5, 0.5);
            CGPathAddCurveToPoint(path, NULL, 28.56, 1, 34.03, 6.04, 43.5, 12.5);
            CGPathMoveToPoint(path, NULL, -29.5, 5.5);
            CGPathAddCurveToPoint(path, NULL, -40.5, -7.5, -40.5, -7.5, -40.5, -7.5);            
            CGPathMoveToPoint(path, NULL, -12.5, -0.5);
            CGPathAddCurveToPoint(path, NULL, -16.5, -21.5, -16.5, -21.5, -16.5, -21.5);
            CGPathMoveToPoint(path, NULL, 9.5, -0.5);
            CGPathAddCurveToPoint(path, NULL, 12.5, -21.5, 12.5, -21.5, 12.5, -21.5);
            CGPathMoveToPoint(path, NULL, 31.5, 3.5);
            CGPathAddCurveToPoint(path, NULL, 39.5, -10.5, 39.5, -11.5, 39.5, -11.5);
            break;
        case kASFeatureEarthWall:
            CGPathMoveToPoint(path, NULL, -42.5, -0.5);
            CGPathAddCurveToPoint(path, NULL, 42.5, -0.5, 42.5, -0.5, 42.5, -0.5);
            CGPathMoveToPoint(path, NULL, -28.5, 10.5);
            CGPathAddCurveToPoint(path, NULL, -28.5, -12.5, -28.5, -13.5, -28.5, -13.5);
            CGPathMoveToPoint(path, NULL, -9.5, 16.5);
            CGPathAddCurveToPoint(path, NULL, -9.5, -17.5, -9.5, -18.5, -9.5, -18.5);
            CGPathMoveToPoint(path, NULL, 10.5, 16.5);
            CGPathAddCurveToPoint(path, NULL, 10.5, -18.5, 10.5, -18.5, 10.5, -18.5);
            CGPathMoveToPoint(path, NULL, 29.5, 11.5);
            CGPathAddCurveToPoint(path, NULL, 29.5, -13.5, 29.5, -13.5, 29.5, -13.5);
            break;
        case kASFeatureErosionGully:
            CGPathMoveToPoint(path, NULL, -31.5, -45.5);
            CGPathAddLineToPoint(path, NULL, -2.5, 41.5);
            CGPathAddLineToPoint(path, NULL, 25.5, -45.5);
            break;
        case kASFeatureQuarry:
            CGPathMoveToPoint(path, NULL, -38.5, -47.5);
            CGPathAddCurveToPoint(path, NULL, -44.5, -37.5, -54.96, -14.62, -54.5, -2.5);
            CGPathAddCurveToPoint(path, NULL, -54.04, 9.62, -41.93, 30.03, -33.5, 37.5);
            CGPathAddCurveToPoint(path, NULL, -25.07, 44.97, -17.74, 49.43, -0.5, 49.5);
            CGPathAddCurveToPoint(path, NULL, 16.74, 49.57, 24.22, 43.99, 32.5, 37.5);
            CGPathAddCurveToPoint(path, NULL, 40.78, 31.01, 52.31, 11.16, 52.5, -2.5);
            CGPathAddCurveToPoint(path, NULL, 52.69, -16.16, 42.37, -39.5, 36.5, -48.5);
            CGPathMoveToPoint(path, NULL, -33.5, 36.5);
            CGPathAddLineToPoint(path, NULL, -15.5, 16.5);
            CGPathMoveToPoint(path, NULL, 33.5, 36.5);
            CGPathAddLineToPoint(path, NULL, 13.5, 16.5);
            CGPathMoveToPoint(path, NULL, 48.5, -22.5);
            CGPathAddLineToPoint(path, NULL, 29.5, -15.5);
            CGPathMoveToPoint(path, NULL, -49.5, -22.5);
            CGPathAddLineToPoint(path, NULL, -31.5, -16.5);
            break;
        case kASFeatureSmallErosionGully:
            nonfilled = CGPathCreateMutable();
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-39.5, 23.5, 16, 17));  
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-22.5, 6.5, 16, 17));  
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-7.5, -9.5, 16, 17));  
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(10.5, -26.5, 16, 17));  
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(26.5, -43.5, 16, 17));  
            CGPathMoveToPoint(path, NULL, -23.5, 49.5);
            CGPathAddLineToPoint(path, NULL, 53.5, -27.5);
            CGPathMoveToPoint(path, NULL, -49.5, 24.5);
            CGPathAddLineToPoint(path, NULL, 26.5, -51.5);
            break;
        case kASFeatureHill:
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-55.5, -33.5, 110, 67));
            break;
        case kASFeatureKnoll:
            nonfilled = CGPathCreateMutable();
            CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-17.5, -17.5, 36, 36));
            break;
        case kASFeatureSaddle:
            CGPathMoveToPoint(path, NULL, -24.5, 51.5);
            CGPathAddCurveToPoint(path, NULL, -20.5, 43.5, -11.53, 22.95, -11.5, 0.5);
            CGPathAddCurveToPoint(path, NULL, -11.47, -21.95, -18.67, -40.42, -24.5, -49.5);
            CGPathMoveToPoint(path, NULL, 24.5, 51.5);
            CGPathAddCurveToPoint(path, NULL, 20.5, 43.5, 11.53, 22.95, 11.5, 0.5);
            CGPathAddCurveToPoint(path, NULL, 11.47, -21.95, 18.67, -40.42, 24.5, -49.5);
            break;
        case kASFeatureDepression:
            CGPathMoveToPoint(path, NULL, -17.5, -0.5);
            CGPathAddLineToPoint(path, NULL, -54.5, -0.5);
            CGPathMoveToPoint(path, NULL, 18.5, -1);
            CGPathAddLineToPoint(path, NULL, 54.5, -1);
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-54.5, -33.5, 109, 66));
            break;
        case kASFeatureSmallDepression:
            CGPathMoveToPoint(path, NULL, -42.5, 29.5);
            CGPathAddCurveToPoint(path, NULL, -47.5, 19.5, -48.97, 12.57, -48.5, 4.5);
            CGPathAddCurveToPoint(path, NULL, -48.03, -3.57, -39.25, -21.59, -32.5, -26.5);
            CGPathAddCurveToPoint(path, NULL, -25.75, -31.41, -12.55, -37.49, -0.5, -37.5);
            CGPathAddCurveToPoint(path, NULL, 11.55, -37.51, 22.74, -32.79, 29.5, -26.5);
            CGPathAddCurveToPoint(path, NULL, 36.26, -20.21, 44.5, -7.63, 44.5, 4.5);
            CGPathAddCurveToPoint(path, NULL, 44.5, 16.63, 44.4, 18.36, 39.5, 29.5);
            break;
        case kASFeaturePit:
            CGPathMoveToPoint(path, NULL, -34.5, 37.5);
            CGPathAddLineToPoint(path, NULL, 0.5, -39.5);
            CGPathAddLineToPoint(path, NULL, 35.5, 37.5);
            break;
        case kASFeatureBrokenGround:
            CGPathMoveToPoint(path, NULL, -47.5, 34.5);
            CGPathAddCurveToPoint(path, NULL, -50.5, 29.5, -51.92, 19.56, -45, 12.5);
            CGPathAddCurveToPoint(path, NULL, -38.08, 5.44, -26.93, 3.88, -19.5, 12);
            CGPathAddCurveToPoint(path, NULL, -12.07, 20.12, -13.16, 23.44, -15.5, 33.5);
            CGPathMoveToPoint(path, NULL, 19.5, 34.5);
            CGPathAddCurveToPoint(path, NULL, 16.5, 29.5, 15.08, 19.56, 22, 12.5);
            CGPathAddCurveToPoint(path, NULL, 28.92, 5.44, 40.07, 3.88, 47.5, 12);
            CGPathAddCurveToPoint(path, NULL, 54.93, 20.12, 53.84, 23.44, 51.5, 33.5);
            CGPathMoveToPoint(path, NULL, -15, -13.5);
            CGPathAddCurveToPoint(path, NULL, -18, -18.5, -19.42, -28.44, -12.5, -35.5);
            CGPathAddCurveToPoint(path, NULL, -5.58, -42.56, 5.57, -44.12, 13, -36);
            CGPathAddCurveToPoint(path, NULL, 20.43, -27.88, 19.34, -24.56, 17, -14.5);
            break;
        case kASFeatureAntHill:
            CGPathMoveToPoint(path, NULL, 0.5, 49.5);
            CGPathAddLineToPoint(path, NULL, 0.5, -53.5);
            CGPathMoveToPoint(path, NULL, 37.5, 36.5);
            CGPathAddLineToPoint(path, NULL, -34.5, -35.5);
            CGPathMoveToPoint(path, NULL, 52.5, 0.5);
            CGPathAddLineToPoint(path, NULL, -49.5, 0.5);
            CGPathMoveToPoint(path, NULL, -34.5, 34.5);
            CGPathAddLineToPoint(path, NULL, 37.5, -37.5);
            break;
        case kASFeatureCliff:
            CGPathMoveToPoint(path, NULL, -49.5, -15.5);
            CGPathAddLineToPoint(path, NULL, -49.5, 17.5);
            CGPathAddLineToPoint(path, NULL, 50.5, 16.5);
            CGPathAddLineToPoint(path, NULL, 50.5, -15.5);
            CGPathMoveToPoint(path, NULL, -18.5, -15.5);
            CGPathAddLineToPoint(path, NULL, -18.5, 16.5);
            CGPathMoveToPoint(path, NULL, 15.5, -15.5);
            CGPathAddLineToPoint(path, NULL, 15.5, 16.5);
            break;
        case kASFeatureRockPillar:
            nonfilled = CGPathCreateMutable();
            CGPathMoveToPoint(nonfilled, tran, -22.5, -50.5);
            CGPathAddLineToPoint(nonfilled, tran, -0.5, 49.5);
            CGPathAddLineToPoint(nonfilled, tran, 20.5, -50.5);
            CGPathCloseSubpath(nonfilled);
            break;
        case kASFeatureCave:
            CGPathMoveToPoint(path, NULL, -8.5, -53.5);
            CGPathAddCurveToPoint(path, NULL, -3.5, -44.5, 6.13, -29.36, 7.5, -10.5);
            CGPathMoveToPoint(path, NULL, -8.5, 52.5);
            CGPathAddCurveToPoint(path, NULL, -3.5, 43.5, 6.13, 28.36, 7.5, 9.5);
            CGPathMoveToPoint(path, NULL, 29.5, 18.5);
            CGPathAddLineToPoint(path, NULL, -17.5, 0.5);
            CGPathAddLineToPoint(path, NULL, 29.5, -19.5);
            break;
        case kASFeatureBoulder:
            nonfilled = CGPathCreateMutable();
            CGPathMoveToPoint(nonfilled, tran, -0.5, 36.5);
            CGPathAddLineToPoint(nonfilled, tran, -38.5, -27.5);
            CGPathAddLineToPoint(nonfilled, tran, 37.5, -27.5);
            CGPathCloseSubpath(nonfilled);
            break;
        case kASFeatureBoulderField:
            nonfilled = CGPathCreateMutable();
            CGPathMoveToPoint(nonfilled, tran, -32.5, 52.5);
            CGPathAddLineToPoint(nonfilled, tran, -51.5, 19.5);
            CGPathAddLineToPoint(nonfilled, tran, -12.5, 19.5);
            CGPathCloseSubpath(nonfilled);
            CGPathMoveToPoint(nonfilled, tran, 30.5, 52.5);
            CGPathAddLineToPoint(nonfilled, tran, 11.5, 19.5);
            CGPathAddLineToPoint(nonfilled, tran, 50.5, 19.5);
            CGPathCloseSubpath(nonfilled);
            CGPathMoveToPoint(nonfilled, tran, -1.5, 18.5);
            CGPathAddLineToPoint(nonfilled, tran, -20.5, -14.5);
            CGPathAddLineToPoint(nonfilled, tran, 18.5, -14.5);
            CGPathCloseSubpath(nonfilled);
            CGPathMoveToPoint(nonfilled, tran, -32.5, -18);
            CGPathAddLineToPoint(nonfilled, tran, -51.5, -51);
            CGPathAddLineToPoint(nonfilled, tran, -12.5, -51);
            CGPathCloseSubpath(nonfilled);
            CGPathMoveToPoint(nonfilled, tran, 30.5, -18);
            CGPathAddLineToPoint(nonfilled, tran, 11.5, -51);
            CGPathAddLineToPoint(nonfilled, tran, 50.5, -51);
            CGPathCloseSubpath(nonfilled);
            break;
        case kASFeatureBoulderCluster:
            nonfilled = CGPathCreateMutable();
            CGPathMoveToPoint(nonfilled, tran, -10.5, 37.5);
            CGPathAddLineToPoint(nonfilled, tran, -43.5, -19.5);
            CGPathAddLineToPoint(nonfilled, tran, -10.5, -19.5);
            CGPathAddLineToPoint(nonfilled, tran, -16.5, -29.5);
            CGPathAddLineToPoint(nonfilled, tran, 42.5, -29.5);
            CGPathAddLineToPoint(nonfilled, tran, 15.5, 25.5);
            CGPathAddLineToPoint(nonfilled, tran, 5.5, 6.5);
            CGPathCloseSubpath(nonfilled);
            break;
        case kASFeatureStonyGround:
            nonfilled = CGPathCreateMutable();
            for (xindex = -2; xindex <= 2; xindex ++) {
                for (yindex = -2; yindex <= 2; yindex++) {
                    CGPathAddEllipseInRect(nonfilled, tran, CGRectMake(-10.0 + 20.0*xindex, -10.0 + 20.0*yindex, 15, 15));                    
                }
            }
            break;
        case kASFeatureBareRock:
            CGPathMoveToPoint(path, NULL, -36.5, 36.5);
            CGPathAddLineToPoint(path, NULL, -10.5, 10.5);
            CGPathMoveToPoint(path, NULL, 0.5, 14.5);
            CGPathAddLineToPoint(path, NULL, 0.5, 53.5);
            CGPathMoveToPoint(path, NULL, -53.5, 0.5);
            CGPathAddLineToPoint(path, NULL, -14.5, 0.5);
            CGPathMoveToPoint(path, NULL, -37.5, -37.5);
            CGPathAddLineToPoint(path, NULL, -10.5, -10.5);
            CGPathMoveToPoint(path, NULL, 0.5, -53.5);
            CGPathAddLineToPoint(path, NULL, 0.5, -14.5);
            CGPathMoveToPoint(path, NULL, 10.5, -10.5);
            CGPathAddLineToPoint(path, NULL, 37.5, -37.5);
            CGPathMoveToPoint(path, NULL, 14.5, 0.5);
            CGPathAddLineToPoint(path, NULL, 53.5, 0.5);
            CGPathMoveToPoint(path, NULL, 10.5, 10.5);
            CGPathAddLineToPoint(path, NULL, 37.5, 37.5);
            break;
        case kASFeatureNarrowPassage:
            CGPathMoveToPoint(path, NULL, -27.5, 33.5);
            CGPathAddLineToPoint(path, NULL, -10.5, 33.5);
            CGPathAddLineToPoint(path, NULL, -10.5, -32.5);
            CGPathAddLineToPoint(path, NULL, -27.5, -32.5);
            CGPathMoveToPoint(path, NULL, 27.5, 33.5);
            CGPathAddLineToPoint(path, NULL, 10.5, 33.5);
            CGPathAddLineToPoint(path, NULL, 10.5, -32.5);
            CGPathAddLineToPoint(path, NULL, 27.5, -32.5);
            break;
        case kASFeatureLake:
            CGPathMoveToPoint(path, NULL, -27.5, -11.5);
            CGPathAddCurveToPoint(path, NULL, -27.5, -5.5, -28.97, -0.14, -25, 5.5);
            CGPathAddCurveToPoint(path, NULL, -21.03, 11.14, -15.02, 10.55, -10.5, 4.5);
            CGPathAddCurveToPoint(path, NULL, -5.98, -1.55, -11.29, -7.13, -6.5, -12);
            CGPathAddCurveToPoint(path, NULL, -1.71, -16.87, 3.63, -15.72, 7.5, -10);
            CGPathAddCurveToPoint(path, NULL, 11.37, -4.28, 7.26, 1.38, 12, 6);
            CGPathAddCurveToPoint(path, NULL, 16.74, 10.62, 24.03, 9.12, 27.5, 3.5);
            CGPathAddCurveToPoint(path, NULL, 30.97, -2.12, 27.5, -11, 27.5, -11.5);
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-46.5, -37.5, 95, 70));
            break;
        case kASFeaturePond:
            CGPathMoveToPoint(path, NULL, -30.5, 2.5);
            CGPathAddCurveToPoint(path, NULL, -34.5, -5.5, -39.12, -23.21, -27.5, -36.5);
            CGPathAddCurveToPoint(path, NULL, -15.88, -49.79, -7.03, -50.76, 0.5, -51);
            CGPathAddCurveToPoint(path, NULL, 8.03, -51.24, 22.64, -47.48, 29, -36);
            CGPathAddCurveToPoint(path, NULL, 35.36, -24.52, 38.32, -11.62, 32.5, 2);
            CGPathMoveToPoint(path, NULL, 47.5, 21.5);
            CGPathAddCurveToPoint(path, NULL, 47.5, 28.5, 48.05, 37.9, 45, 45);
            CGPathAddCurveToPoint(path, NULL, 41.95, 52.1, 33, 50.93, 30.5, 45.5);
            CGPathAddCurveToPoint(path, NULL, 28, 40.07, 30.78, 29.5, 26.5, 25.5);
            CGPathAddCurveToPoint(path, NULL, 22.22, 21.5, 18.03, 18.17, 11.5, 25.5);
            CGPathAddCurveToPoint(path, NULL, 4.97, 32.83, 11.59, 36.99, 6.5, 45.5);
            CGPathAddCurveToPoint(path, NULL, 1.41, 54.01, -5.06, 51.23, -8.5, 45.5);
            CGPathAddCurveToPoint(path, NULL, -11.94, 39.77, -7.84, 33.54, -12.5, 25.5);
            CGPathAddCurveToPoint(path, NULL, -17.16, 17.46, -24.2, 19.24, -27.5, 25.5);
            CGPathAddCurveToPoint(path, NULL, -30.8, 31.76, -26.41, 37.48, -32.5, 45.5);
            CGPathAddCurveToPoint(path, NULL, -38.59, 53.52, -42.8, 52.07, -46.5, 45.5);
            CGPathAddCurveToPoint(path, NULL, -50.2, 38.93, -48.87, 32.96, -49, 26.5);
        case kASFeatureWaterhole:
            CGPathMoveToPoint(path, NULL, 45.5, 22.41);
            CGPathAddCurveToPoint(path, NULL, 45.5, 28.96, 46.03, 37.75, 43.13, 44.39);
            CGPathAddCurveToPoint(path, NULL, 40.23, 51.02, 31.75, 49.93, 29.38, 44.86);
            CGPathAddCurveToPoint(path, NULL, 27.01, 39.78, 29.64, 29.89, 25.59, 26.15);
            CGPathAddCurveToPoint(path, NULL, 21.53, 22.41, 17.55, 19.3, 11.36, 26.15);
            CGPathAddCurveToPoint(path, NULL, 5.18, 33.01, 11.45, 36.9, 6.62, 44.86);
            CGPathAddCurveToPoint(path, NULL, 1.8, 52.81, -4.34, 50.21, -7.6, 44.86);
            CGPathAddCurveToPoint(path, NULL, -10.86, 39.5, -6.97, 33.67, -11.39, 26.15);
            CGPathAddCurveToPoint(path, NULL, -15.82, 18.63, -22.49, 20.29, -25.62, 26.15);
            CGPathAddCurveToPoint(path, NULL, -28.75, 32.01, -24.58, 37.36, -30.36, 44.86);
            CGPathAddCurveToPoint(path, NULL, -36.14, 52.35, -40.13, 51, -43.64, 44.86);
            CGPathAddCurveToPoint(path, NULL, -47.15, 38.71, -45.89, 33.13, -46.01, 27.09);
            CGPathMoveToPoint(path, NULL, -23.5, 1.5);
            CGPathAddLineToPoint(path, NULL, -0.5, -52.5);
            CGPathAddLineToPoint(path, NULL, 23.5, 1.5);
            break;
        case kASFeatureStream:
            CGPathMoveToPoint(path, NULL, -38.5, 50.5);
            CGPathAddCurveToPoint(path, NULL, -43.5, 45.5, -49.32, 44.05, -49.5, 35.5);
            CGPathAddCurveToPoint(path, NULL, -49.68, 26.95, -46.77, 26.49, -38.5, 26.5);
            CGPathAddCurveToPoint(path, NULL, -30.23, 26.51, -31.89, 35.5, -22.5, 35.5);
            CGPathAddCurveToPoint(path, NULL, -13.11, 35.5, -14.3, 30.78, -14.5, 26.5);
            CGPathAddCurveToPoint(path, NULL, -14.7, 22.22, -22.5, 20.48, -22.5, 10.5);
            CGPathAddCurveToPoint(path, NULL, -22.5, 0.52, -18.41, 1.33, -14.5, 1.5);
            CGPathAddCurveToPoint(path, NULL, -10.59, 1.67, -4.67, 10.5, 3.5, 10.5);
            CGPathAddCurveToPoint(path, NULL, 11.67, 10.5, 11.69, 6.18, 11.5, 1.5);
            CGPathAddCurveToPoint(path, NULL, 11.31, -3.18, 3.5, -6.2, 3.5, -14.5);
            CGPathAddCurveToPoint(path, NULL, 3.5, -22.8, 6.21, -24.33, 11.5, -24.5);
            CGPathAddCurveToPoint(path, NULL, 16.79, -24.67, 21.84, -14.5, 29.5, -14.5);
            CGPathAddCurveToPoint(path, NULL, 37.16, -14.5, 36.92, -19.26, 36.5, -24.5);
            CGPathAddCurveToPoint(path, NULL, 36.08, -29.74, 29.5, -30.52, 29.5, -38.5);
            CGPathAddCurveToPoint(path, NULL, 29.5, -46.48, 30.98, -49.17, 36.5, -49.5);
        case kASFeatureDitch:
            CGPathMoveToPoint(path, NULL, -21.5, 50.5);
            CGPathAddLineToPoint(path, NULL, 0.5, 28.5);
            CGPathMoveToPoint(path, NULL, 7.5, 21.5);
            CGPathAddLineToPoint(path, NULL, 25.5, 3.5);
            CGPathMoveToPoint(path, NULL, 33.5, -4.5);
            CGPathAddLineToPoint(path, NULL, 50.5, -21.5);
            CGPathMoveToPoint(path, NULL, -50.5, 20.5);
            CGPathAddLineToPoint(path, NULL, -28.5, -1.5);
            CGPathMoveToPoint(path, NULL, -21.5, -8.5);
            CGPathAddLineToPoint(path, NULL, -3.5, -26.5);
            CGPathMoveToPoint(path, NULL, 4.5, -34.5);
            CGPathAddLineToPoint(path, NULL, 21.5, -51.5);
            CGPathMoveToPoint(path, NULL, -27.5, 36.5);
            CGPathAddCurveToPoint(path, NULL, -30.5, 33.5, -35.22, 29.65, -35, 25);
            CGPathAddCurveToPoint(path, NULL, -34.78, 20.35, -33.25, 20.03, -29.5, 19.5);
            CGPathAddCurveToPoint(path, NULL, -25.75, 18.97, -21.4, 27.46, -16, 27);
            CGPathAddCurveToPoint(path, NULL, -10.6, 26.54, -9.84, 23.95, -10.5, 20);
            CGPathAddCurveToPoint(path, NULL, -11.16, 16.05, -16.96, 12.03, -16.5, 7.5);
            CGPathAddCurveToPoint(path, NULL, -16.04, 2.97, -15.86, 1.29, -11.5, 1);
            CGPathAddCurveToPoint(path, NULL, -7.14, 0.71, -3.42, 8.54, 3, 8.5);
            CGPathAddCurveToPoint(path, NULL, 9.42, 8.46, 8.27, 5.54, 8.5, 1.5);
            CGPathAddCurveToPoint(path, NULL, 8.73, -2.54, 2, -3.85, 2.5, -9.5);
            CGPathAddCurveToPoint(path, NULL, 3, -15.15, 3.94, -17.26, 7.5, -17.5);
            CGPathAddCurveToPoint(path, NULL, 11.06, -17.74, 14.77, -9.72, 20.5, -10);
            CGPathAddCurveToPoint(path, NULL, 26.23, -10.28, 26.53, -13.18, 26.5, -17.5);
            CGPathAddCurveToPoint(path, NULL, 26.47, -21.82, 19.98, -22.53, 20.5, -27.5);
            CGPathAddCurveToPoint(path, NULL, 21.02, -32.47, 21.17, -35.12, 25, -35);
            CGPathAddCurveToPoint(path, NULL, 28.83, -34.88, 32.54, -32.34, 37.5, -28);
        case kASFeatureNarrowMarch:
            CGPathAddEllipseInRect(path, NULL, CGRectMake(25, -43, 17, 17));
            CGPathAddEllipseInRect(path, NULL, CGRectMake(8, -26, 17, 17));
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-41, 25, 17, 17));
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-25, 8, 17, 17));
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-8, -9, 17, 17));
            break;
        case kASFeatureMarch:
            CGPathMoveToPoint(path, NULL, -21.5, 49.5);
            CGPathAddLineToPoint(path, NULL, 21.5, 49.5);
            CGPathMoveToPoint(path, NULL, -42.5, 24.5);
            CGPathAddLineToPoint(path, NULL, 40.5, 24.5);
            CGPathMoveToPoint(path, NULL, -55.5, 0.5);
            CGPathAddLineToPoint(path, NULL, 54.5, 0.5);
            CGPathMoveToPoint(path, NULL, -43.5, -24.5);
            CGPathAddLineToPoint(path, NULL, 39.5, -24.5);
            CGPathMoveToPoint(path, NULL, -23.5, -49.5);
            CGPathAddLineToPoint(path, NULL, 22.5, -49.5);
            break;
        case kASFeatureFirmGroundInMarch:
            CGPathMoveToPoint(path, NULL, -54.5, 49.5);
            CGPathAddLineToPoint(path, NULL, 54.5, 49.5);
            CGPathMoveToPoint(path, NULL, -54.5, 24.5);
            CGPathAddLineToPoint(path, NULL, -26.5, 24.5);
            CGPathMoveToPoint(path, NULL, 25.5, 24.5);
            CGPathAddLineToPoint(path, NULL, 54.5, 24.5);
            CGPathMoveToPoint(path, NULL, 35.5, 0.5);
            CGPathAddLineToPoint(path, NULL, 55.5, 0.5);
            CGPathMoveToPoint(path, NULL, -54.5, -24.5);
            CGPathAddLineToPoint(path, NULL, -26.5, -24.5);
            CGPathMoveToPoint(path, NULL, 24.5, -24.5);
            CGPathAddLineToPoint(path, NULL, 55.5, -24.5);
            CGPathMoveToPoint(path, NULL, -55.5, -49.5);
            CGPathAddLineToPoint(path, NULL, 55.5, -49.5);
            CGPathMoveToPoint(path, NULL, -55.5, -0.5);
            CGPathAddLineToPoint(path, NULL, -36.5, -0.5);
            break;
        case kASFeatureWell:
            CGPathAddEllipseInRect(path, NULL, CGRectMake(-32.5, -15.5, 65, 63));
            CGPathMoveToPoint(path, NULL, -32.5, -49.5);
            CGPathAddCurveToPoint(path, NULL, -32.5, -42.5, -34.97, -33.27, -28.5, -27);
            CGPathAddCurveToPoint(path, NULL, -22.03, -20.73, -17.45, -23.05, -13.5, -28.5);
            CGPathAddCurveToPoint(path, NULL, -9.55, -33.95, -14.66, -41.15, -9, -46.5);
            CGPathAddCurveToPoint(path, NULL, -3.34, -51.85, 4.33, -53.76, 10, -47);
            CGPathAddCurveToPoint(path, NULL, 15.67, -40.24, 9.09, -33.38, 15, -28);
            CGPathAddCurveToPoint(path, NULL, 20.91, -22.62, 24.48, -21.46, 30.5, -29);
            CGPathAddCurveToPoint(path, NULL, 36.52, -36.54, 33.21, -41.37, 34, -48.5);
            break;
        case kASFeatureSpring:
            CGPathMoveToPoint(path, NULL, -30.5, 11.5);
            CGPathAddCurveToPoint(path, NULL, -36.5, 12.5, -39.07, 15.66, -42.5, 20.5);
            CGPathAddCurveToPoint(path, NULL, -45.93, 25.34, -45.39, 34.55, -42.5, 40.5);
            CGPathAddCurveToPoint(path, NULL, -39.61, 46.45, -34.14, 49.68, -27.5, 49.5);
            CGPathAddCurveToPoint(path, NULL, -20.86, 49.32, -16.97, 48.45, -8.5, 36);
            CGPathMoveToPoint(path, NULL, -25.5, 29.5);
            CGPathAddCurveToPoint(path, NULL, -17.5, 20.5, -15.69, 13.97, -9.5, 12);
            CGPathAddCurveToPoint(path, NULL, -3.31, 10.03, 2.64, 13.79, 9, 10.5);
            CGPathAddCurveToPoint(path, NULL, 15.36, 7.21, 15.69, 4.45, 14.5, -1);
            CGPathAddCurveToPoint(path, NULL, 13.31, -6.45, 7.18, -8.17, 7, -14);
            CGPathAddCurveToPoint(path, NULL, 6.82, -19.83, 9.64, -27.48, 15.5, -27.5);
            CGPathAddCurveToPoint(path, NULL, 21.36, -27.52, 24.32, -16.78, 34.5, -18);
            CGPathAddCurveToPoint(path, NULL, 44.68, -19.22, 44.87, -22.55, 46, -27.5);
            CGPathAddCurveToPoint(path, NULL, 47.13, -32.45, 43.24, -43.16, 41, -49);
            break;
        case kASFeatureWaterTrough:
            CGPathAddRect(path, NULL, CGRectMake(-37.5, -42.5, 73, 38));
            CGPathMoveToPoint(path, NULL, -45.5, 17.5);
            CGPathAddCurveToPoint(path, NULL, -45.5, 25.5, -46.33, 35.07, -41.5, 39.5);
            CGPathAddCurveToPoint(path, NULL, -36.67, 43.93, -33.32, 43.24, -29, 36.5);
            CGPathAddCurveToPoint(path, NULL, -24.68, 29.76, -29.95, 25.56, -26, 19.5);
            CGPathAddCurveToPoint(path, NULL, -22.05, 13.44, -15.71, 13.66, -11.5, 19.5);
            CGPathAddCurveToPoint(path, NULL, -7.29, 25.34, -11.52, 33.39, -6.5, 38.5);
            CGPathAddCurveToPoint(path, NULL, -1.48, 43.61, 1.79, 43.11, 6, 38.5);
            CGPathAddCurveToPoint(path, NULL, 10.21, 33.89, 5.92, 26.74, 9.5, 21);
            CGPathAddCurveToPoint(path, NULL, 13.08, 15.26, 20.75, 13.5, 24.5, 20.5);
            CGPathAddCurveToPoint(path, NULL, 28.25, 27.5, 23.3, 33.41, 29, 39.5);
            CGPathAddCurveToPoint(path, NULL, 34.7, 45.59, 37.03, 42.92, 41, 37.5);
            CGPathAddCurveToPoint(path, NULL, 44.97, 32.08, 43.49, 26.65, 43.5, 20);
            break;
        default:
            break;
    }
    CGFloat lw = THIN_LINE;
    if (tran != NULL) lw /= tran->a;
    fillable = CGPathCreateCopyByStrokingPath(path, tran, lw, kCGLineCapButt, kCGLineJoinBevel, 0.0);
    CGPathRelease(path);
    CFArrayRef pathArray;
    if (nonfilled != NULL) {
        CGPathRef paths[2] = {fillable, nonfilled};
        pathArray = CFArrayCreate(NULL, (const void **)paths, 2, &kCFTypeArrayCallBacks);
        CGPathRelease(nonfilled);
    } else {
        CGPathRef paths[1] = {fillable};
        pathArray = CFArrayCreate(NULL, (const void **)paths, 1, &kCFTypeArrayCallBacks);
    }    
    CGPathRelease(fillable);
    
    return pathArray;
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

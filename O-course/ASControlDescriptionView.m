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

#define THICK_LINE  (2.0)
#define THIN_LINE   (1.0)
#define START_FRACTION (0.7)
#define CIRCLE_FRACTION (0.7)
#define ARROW_FRACTION (0.8)

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

- (void)setFrameSize:(NSSize)newSize {
    
}

- (void)setCourse:(id<NSObject>)_course {
    NSObject *oldCourse = course;
    course = [_course retain];
    [oldCourse release];
    
    [self setNeedsDisplay:YES];
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
    
    if ([[NSGraphicsContext currentContext] isDrawingToScreen]) {
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect:dirtyRect];
    }
    
    [overprintColor set];

    CGRect  bounds = [self bounds];
    bounds = CGRectInset(bounds, 5.0, 5.0);
    CGFloat height = [self heightForWidth:bounds.size.width];
    if (height == 0.0) return;
    CGFloat y, x;
    CGFloat blockSize = bounds.size.width / 8.0;
    NSSize sz, block;
    
    block = NSMakeSize(blockSize, blockSize);
    
    x = bounds.origin.x;
    y = height + (0.5 * (bounds.size.height - height));

    // Frame all of it.
    [NSBezierPath setDefaultLineWidth:THICK_LINE];
    [NSBezierPath strokeRect:NSMakeRect(x, y - height, bounds.size.width, height)];
    
    // Draw the name.
    y -= blockSize;
    if ([self.provider eventName] != nil) {
        sz = [[self.provider eventName] boundingRectWithSize:NSMakeSize(bounds.size.width, blockSize) 
                                                     options:NSStringDrawingUsesFontLeading 
                                                  attributes:boldAttributes].size;
        [[self.provider eventName] drawInRect:NSIntegralRect(NSMakeRect(x, y - 0.5*(blockSize - sz.height), bounds.size.width, blockSize))
                               withAttributes:boldAttributes];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) toPoint:NSMakePoint(x + bounds.size.width, y)];
        y -= blockSize;
    }
    
    // The class names.
    if ([self.provider classNamesForCourse:self.course]) {
        [[self.provider classNamesForCourse:self.course] drawInRect:NSMakeRect(bounds.origin.x, y, bounds.size.width, blockSize) 
                                                     withAttributes:boldAttributes];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) toPoint:NSMakePoint(x + bounds.size.width, y)];
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

        x = bounds.origin.x;
        [self drawThickGridAtOrigin:NSMakePoint(x, y) blockSize:blockSize];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) 
                                  toPoint:NSMakePoint(x + bounds.size.width, y)];
        y -= blockSize;
    }
    
    // Draw the items.
    NSInteger consecutiveRegularControls = 0, controlNumber = 1;
    for (id <ASControlDescriptionItem> item in [self.provider courseObjectEnumeratorForCourse:self.course]) {
        enum ControlDescriptionItemType type = [item controlDescriptionItemType];
        [NSBezierPath setDefaultLineWidth:((++consecutiveRegularControls == 3) || (type == kASStart))?THICK_LINE:THIN_LINE];
        x = bounds.origin.x;
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y) 
                                  toPoint:NSMakePoint(x + bounds.size.width, y)];

        if (type == kASStart || type == kASRegularControl) { 

            [self drawThickGridAtOrigin:NSMakePoint(x, y) blockSize:blockSize];
            [self drawThinGridAtOrigin:NSMakePoint(x, y) blockSize:blockSize];

            if (type == kASRegularControl) {
                // Draw number and control code.
                NSString *s = [NSString stringWithFormat:@"%d", controlNumber++];
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
                [[self bezierPathForStartAtOrigin:NSMakePoint(x, y) usingBlockSize:blockSize] stroke];
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
            x = bounds.origin.x;
            [NSBezierPath setDefaultLineWidth:THICK_LINE];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(x, y + blockSize) 
                                          toPoint:NSMakePoint(x + bounds.size.width, y + blockSize)];
            CGFloat blankSegment = 0.0;
            if ([item distance] != nil) {
                NSString *s = [distanceFormatter stringFromNumber:[item distance]];
                sz = [s boundingRectWithSize:NSMakeSize(blockSize * 4.0, blockSize)
                                     options:NSStringDrawingUsesFontLeading 
                                  attributes:regularAttributes].size;
                [s drawInRect:NSIntegralRect(NSMakeRect(x+2.0*blockSize, y - 0.5*(blockSize - sz.height), 4.0*blockSize, blockSize)) withAttributes:regularAttributes];
                blankSegment = sz.width;
            }
            [[self bezierPathForTapedRoute:type atPosition:NSMakePoint(x, y) usingBlockSize:blockSize blankSegment:blankSegment] stroke];
        }
        y -= blockSize;
    }
}

- (NSBezierPath *)bezierPathForTapedRoute:(enum ControlDescriptionItemType)routeType atPosition:(NSPoint)p usingBlockSize:(CGFloat)blockSize blankSegment:(CGFloat)leaveThisBlank {
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

- (NSBezierPath *)bezierPathForStartAtOrigin:(NSPoint)p usingBlockSize:(CGFloat)blockSize {
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

- (CFArrayRef)createPathsForColumn:(enum ASControlDescriptionColumn)column 
                       withValue:(NSNumber *)value 
                      atPosition:(CGPoint)p 
                        withSize:(CGFloat)sz {
    // Centered around the midpoint.
    CGFloat s = 0.75*0.5*sz/SYMBOL_SIZE;
    CGAffineTransform at = CGAffineTransformMakeScale(s,s);
    at = CGAffineTransformTranslate(at, p.x/s, p.y/s);
    switch (column) {
        case kASWhichOfAnySimilarFeature:
            return [self createPathsForWhichOfAnySimilarFeatureWithValue:value transform:&at];
            break;
        case kASFeature:
        case kASAppearanceOrSecondaryFeature:
            return [self createPathsForFeatureOrAppearance:value transform:&at];
            break;
            
        default:
            break;
    }
    return NULL;
}

- (NSArray *)supportedValuesForColumn:(enum ASControlDescriptionColumn)column {
    NSArray *values;
    switch (column) {
        case kASWhichOfAnySimilarFeature:
            values =  [NSArray arrayWithObjects:
                       [NSNumber numberWithInt:kASFeatureNorth],
                       [NSNumber numberWithInt:kASFeatureNorthEast],
                       [NSNumber numberWithInt:kASFeatureEast],
                       [NSNumber numberWithInt:kASFeatureSouthEast],
                       [NSNumber numberWithInt:kASFeatureSouth],
                       [NSNumber numberWithInt:kASFeatureSouthWest],
                       [NSNumber numberWithInt:kASFeatureWest], 
                       [NSNumber numberWithInt:kASFeatureNorthWest], 
                       [NSNumber numberWithInt:kASFeatureUpper], 
                       [NSNumber numberWithInt:kASFeatureLower],
                       [NSNumber numberWithInt:kASFeatureLeft],
                       [NSNumber numberWithInt:kASFeatureMiddle],
                       [NSNumber numberWithInt:kASFeatureRight],
                       nil];
            break;
            
        default:
            break;
    }
    return values;
}

#define C_ARROW_FRACTION 0.4
#define C_DUAL_LINE_SPACING 0.3
#define C_TRIPLE_LINE_SPACING 0.5
#define C_MARK_DOT 0.2

- (CFArrayRef)createPathsForWhichOfAnySimilarFeatureWithValue:(NSNumber *)value transform:(CGAffineTransform *)tran {
    enum ASWhichOfAnySimilarFeature feature = (enum ASWhichOfAnySimilarFeature)[value intValue];
    CGMutablePathRef path = CGPathCreateMutable(), subpath = NULL;
    CGPathRef fillable;
    switch (feature) {
        case kASFeatureNorth:
            CGPathMoveToPoint(path, NULL, 0.0, -SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, 0.0, SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, C_ARROW_FRACTION*SYMBOL_SIZE, (1.0-C_ARROW_FRACTION)*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, 0.0, SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -C_ARROW_FRACTION*SYMBOL_SIZE, (1.0-C_ARROW_FRACTION)*SYMBOL_SIZE);
            break;
        case kASFeatureNorthEast:
            CGPathMoveToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        case kASFeatureEast:
            CGPathMoveToPoint(path, NULL, -SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE, C_ARROW_FRACTION*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE, -C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        case kASFeatureSouthEast:
            CGPathMoveToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        case kASFeatureSouth:
            CGPathMoveToPoint(path, NULL, 0.0, SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, 0.0, -SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, ARROW_FRACTION*SYMBOL_SIZE, -(1.0-C_ARROW_FRACTION)*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, 0.0, -SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -ARROW_FRACTION*SYMBOL_SIZE, -(1.0-C_ARROW_FRACTION)*SYMBOL_SIZE);
            break;
        case kASFeatureSouthWest:
            CGPathMoveToPoint(path, NULL, SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        case kASFeatureWest:
            CGPathMoveToPoint(path, NULL, SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, -SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, -SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE, C_ARROW_FRACTION*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, -SYMBOL_SIZE, 0.0);
            CGPathAddLineToPoint(path, NULL, -SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE, -C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        case kASFeatureNorthWest:
            CGPathMoveToPoint(path, NULL, SQRT2*SYMBOL_SIZE, -SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE+C_ARROW_FRACTION*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathMoveToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE);
            CGPathAddLineToPoint(path, NULL, -SQRT2*SYMBOL_SIZE, SQRT2*SYMBOL_SIZE-C_ARROW_FRACTION*SYMBOL_SIZE);
            break;
        default:
            break;
    };
    
    if (feature == kASFeatureUpper || feature == kASFeatureLower) {
        CGPathMoveToPoint(path, NULL, -SYMBOL_SIZE, C_DUAL_LINE_SPACING*SYMBOL_SIZE);
        CGPathAddLineToPoint(path, NULL, SYMBOL_SIZE, C_DUAL_LINE_SPACING*SYMBOL_SIZE);
        CGPathMoveToPoint(path, NULL, -SYMBOL_SIZE, -C_DUAL_LINE_SPACING*SYMBOL_SIZE);
        CGPathAddLineToPoint(path, NULL, SYMBOL_SIZE, -C_DUAL_LINE_SPACING*SYMBOL_SIZE);
        
        subpath = CGPathCreateMutable();
        CGRect r = CGRectMake(-C_MARK_DOT*SYMBOL_SIZE, 
                              ((feature == kASFeatureLower)?(-1.0):(1.0))*C_DUAL_LINE_SPACING*SYMBOL_SIZE-C_MARK_DOT*SYMBOL_SIZE, C_MARK_DOT*SYMBOL_SIZE*2.0, C_MARK_DOT*SYMBOL_SIZE*2.0);
        CGPathAddEllipseInRect(subpath, tran, r);
    }
    
    if (feature == kASFeatureLeft || feature == kASFeatureMiddle || feature == kASFeatureRight) {
        CGPathMoveToPoint(path, NULL, -C_TRIPLE_LINE_SPACING*SYMBOL_SIZE, -SYMBOL_SIZE);
        CGPathAddLineToPoint(path, NULL, -C_TRIPLE_LINE_SPACING*SYMBOL_SIZE, SYMBOL_SIZE);
        CGPathMoveToPoint(path, NULL, 0.0, -SYMBOL_SIZE);
        CGPathAddLineToPoint(path, NULL, 0.0, SYMBOL_SIZE);
        CGPathMoveToPoint(path, NULL, C_TRIPLE_LINE_SPACING*SYMBOL_SIZE, -SYMBOL_SIZE);
        CGPathAddLineToPoint(path, NULL, C_TRIPLE_LINE_SPACING*SYMBOL_SIZE, SYMBOL_SIZE);
        
        subpath = CGPathCreateMutable();
        CGRect r = CGRectMake(-C_MARK_DOT*SYMBOL_SIZE, 
                              -C_MARK_DOT*SYMBOL_SIZE, C_MARK_DOT*SYMBOL_SIZE*2.0, C_MARK_DOT*SYMBOL_SIZE*2.0);
        if (feature == kASFeatureRight) {
            r.origin.x = r.origin.x + C_TRIPLE_LINE_SPACING*SYMBOL_SIZE;
        } else if (feature == kASFeatureLeft) {
            r.origin.x = r.origin.x - C_TRIPLE_LINE_SPACING*SYMBOL_SIZE;
        }
        CGPathAddEllipseInRect(subpath, tran, r);
    }
    
    // Stroke original path
    CGFloat lw = THIN_LINE;
    if (tran != NULL) lw /= tran->a;
    fillable = CGPathCreateCopyByStrokingPath(path, tran, lw, kCGLineCapButt, kCGLineJoinBevel, 0.0);
    CGPathRelease(path);
    CFArrayRef pathArray;
    if (subpath != NULL) {
        CGPathRef paths[2] = {fillable, subpath};
        pathArray = CFArrayCreate(NULL, (const void **)paths, 2, &kCFTypeArrayCallBacks);
        CGPathRelease(subpath);
    } else {
        CGPathRef paths[1] = {fillable};
        pathArray = CFArrayCreate(NULL, (const void **)paths, 1, &kCFTypeArrayCallBacks);
    }
    CGPathRelease(fillable);
    
    return pathArray;
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

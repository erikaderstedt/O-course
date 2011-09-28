//
//  ASOCADController_Line.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-26.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOCADController_Line.h"

float ocad_distance_between_points(float p1x, float p1y, float p2x, float p2y);
float regular_distance_between_points(float p1x, float p1y, float p2x, float p2y);
CGPoint bezierCurvePoint(float t, CGPoint p0, CGPoint cp1, CGPoint cp2, CGPoint p1);
void splitBezier(float t, CGPoint p0, CGPoint cp1, CGPoint cp2, CGPoint p1, CGPoint *points);

#define BEZIER_STEP ((float)0.025);

@interface CoordinateTransverser : NSObject {
@private
    int currentIndex;
    CGFloat currentFraction;
    BOOL nothingLeft;
    
    struct TDPoly *_coords;
    int _num_coords;
    CGMutablePathRef _path;
}

- (id)initWith:(int)num_coords coordinates:(struct TDPoly *)coords withPath:(CGMutablePathRef)path;
- (BOOL)endHasBeenReached;
- (BOOL)onFirstSegment;
- (BOOL)onLastSegment;

- (CGPoint)advanceDistance:(CGFloat)distance;
- (CGPoint)advanceDistance:(CGFloat)distance stroke:(BOOL)s;

- (CGFloat)lengthOfElementAtIndex:(int)i nextElement:(int *)next;
- (CGFloat)lengthOfCurrentSegment;
- (CGFloat)lengthOfSegmentAtIndex:(int)i nextSegment:(int *)next;
- (float)lengthOfEntirePath;

@end

@implementation ASOCADController (ASOCADController_Line)

- (NSArray *)cachedDrawingInfoForLineObject:(struct ocad_element *)e {
    struct ocad_line_symbol *line = (struct ocad_line_symbol *)(e->symbol);
    int c;
	
	CGMutablePathRef p = CGPathCreateMutable();
    
    NSDictionary *roadCache = nil;
    NSMutableArray *cachedData = [NSMutableArray arrayWithCapacity:10];
    
    if (e->nCoordinates == 0 || (line != NULL && line->status == 2 /* Hidden */)) {
        return [NSArray array];
    }
    
    if (line != NULL && (line->dbl_width != 0)) {
		CGMutablePathRef left = CGPathCreateMutable();
		CGMutablePathRef right = CGPathCreateMutable();
		CGMutablePathRef road = CGPathCreateMutable();
        
        NSPoint p0 = NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8), p1;
		CGPathMoveToPoint(road, NULL, p0.x, p0.y);
        
        // For each point
        float angle = 0.0, thisAngle, nextangle;
        float *angles = calloc(sizeof(float), e->nCoordinates);
        int angleIndex = 0;
       
        for (c = 1; c < e->nCoordinates; c++) {
            p1 = NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8);
            thisAngle = [[self class] angleBetweenPoint:p0 andPoint:p1];
            
            if (angleIndex > 0) {
                // We want to calculate the average between this angle and the last. If the angle "wraps"
                // (i.e., one angle is very small and the other is near 2*pi), we cannot take the arithmetic average.
                angles[angleIndex] = atan2f(sinf(thisAngle)+sinf(angles[angleIndex - 1]), cosf(thisAngle) + cosf(angles[angleIndex - 1]));
            } else {
                angles[angleIndex] = thisAngle;
            }
            
            if (e->coords[c].x & 1) {
                // Bezier curve.
                NSPoint p2 = NSMakePoint(e->coords[c + 1].x >> 8, e->coords[c + 1].y >> 8);
                NSAssert(e->coords[c+1].x & 2, @"Next is not the second control point");
                NSPoint p3 = NSMakePoint(e->coords[c+2].x >> 8, e->coords[c+2].y >> 8);

				CGPathAddCurveToPoint(road, NULL, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
                c += 2;
                // 3 coordinates consumed and 2 angles consumed.
                p0 = p3;
                angles[++angleIndex] = [[self class] angleBetweenPoint:p2 andPoint:p3];
            } else {
                p0 = p1;
				CGPathAddLineToPoint(road, NULL, p1.x, p1.y);
            }
            
            angleIndex ++;
        }
        
        // Get the angle to the next normal point. 
        // Translate the point half the width to each side.
        // Create the path to the next point in the normal manner.
        // Be sure to watch for gaps in the left / right lines.
        
        float translateDistanceLeft = 0.5*((float)line->dbl_width) + 0.5*((float)line->dbl_left_width);
        float translateDistanceRight = 0.5*((float)line->dbl_width) + 0.5*((float)line->dbl_right_width);
        angleIndex = 0;
		p1 = [[self class] translatePoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) distance:translateDistanceLeft angle:(angles[0] + pi/2)]; 
		CGPathMoveToPoint(left, NULL, p1.x, p1.y);
		p1 = [[self class] translatePoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) distance:translateDistanceRight angle:(angles[0] - pi/2)];
		CGPathMoveToPoint(right, NULL, p1.x, p1.y);
        
        for (c = 1; c < e->nCoordinates; c++) {
            angle = angles[angleIndex];
            
            p1 = NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8);
            NSPoint p1l, p2l, p3l, p1r, p2r, p3r;
            p1l = [[self class] translatePoint:p1 distance:translateDistanceLeft angle:(angle + pi/2)];
            p1r = [[self class] translatePoint:p1 distance:translateDistanceRight angle:(angle - pi/2)];
            
            if (e->coords[c].x & 1) {
                NSPoint p2 = NSMakePoint(e->coords[c + 1].x >> 8, e->coords[c + 1].y >> 8);
                NSPoint p3 = NSMakePoint(e->coords[c+2].x >> 8, e->coords[c+2].y >> 8);

                nextangle = angles[++angleIndex];
                // Bezier curve.
                p2l = [[self class] translatePoint:p2 distance:translateDistanceLeft angle:(nextangle + pi/2)];
                p3l = [[self class] translatePoint:p3 distance:translateDistanceLeft angle:(nextangle + pi/2)];
                p2r = [[self class] translatePoint:p2 distance:translateDistanceRight angle:(nextangle - pi/2)];
                p3r = [[self class] translatePoint:p3 distance:translateDistanceRight angle:(nextangle - pi/2)];
                
                CGPathAddCurveToPoint(left, NULL, p1l.x, p1l.y, p2l.x, p2l.y, p3l.x, p3l.y);
				CGPathAddCurveToPoint(right, NULL, p1r.x, p1r.y, p2r.x, p2r.y, p3r.x, p3r.y);
                c += 2; // A total of 3 coordinates and 2 angles consumed.
                
            } else {
                if (e->coords[c].x & 4) {
					CGPathMoveToPoint(left, NULL, p1l.x, p1l.y);
				} else {
					CGPathAddLineToPoint(left, NULL, p1l.x, p1l.y);
				}
				
                if (e->coords[c].y & 4) {
					CGPathMoveToPoint(right, NULL, p1r.x, p1r.y);
				} else {
					CGPathAddLineToPoint(right, NULL, p1r.x, p1r.y);
				}
            }
            angleIndex ++;
        }

        free(angles);
        
        if (line->dbl_flags > 0) {
            roadCache = [NSDictionary dictionaryWithObjectsAndKeys:(id)[self colorWithNumber:line->dbl_fill_color], @"strokeColor", 
                         [NSNumber numberWithInt:line->dbl_fill_color],@"colornum",
                         [NSValue valueWithPointer:e], @"element",
                         road, @"path", [NSNumber numberWithFloat:line->dbl_width], @"width", nil];
        }
        [cachedData addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)[self colorWithNumber:line->dbl_left_color], @"strokeColor", 
                               [NSNumber numberWithInt:line->dbl_left_color],@"colornum",
                               [NSValue valueWithPointer:e], @"element",
							   left, @"path",[NSNumber numberWithInt:line->dbl_left_width], @"width", 
							   [NSNumber numberWithInt:kCGLineCapSquare], @"capStyle", nil]];
        [cachedData addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)[self colorWithNumber:line->dbl_right_color], @"strokeColor", 
                               [NSNumber numberWithInt:line->dbl_right_color],@"colornum",
                               [NSValue valueWithPointer:e], @"element",
							   right, @"path",[NSNumber numberWithInt:line->dbl_right_width], @"width", 
							   [NSNumber numberWithInt:kCGLineCapSquare], @"capStyle", nil]]; 
    }
    
    NSAssert(line != NULL, @"Line was null!");
    
    // Create the path for the main line. 
    if (e->linewidth != 0 || (line != NULL && line->line_width != 0)) {
        float x = e->coords[0].x >> 8;
        float y = e->coords[0].y >> 8;
		 CGPathMoveToPoint(p, NULL, x, y);
        
        if (line != NULL && line->main_length != 0) { // A dashed line.
            
            CoordinateTransverser *ct = [[CoordinateTransverser alloc] initWith:e->nCoordinates coordinates:e->coords withPath:p];
            
            while (![ct endHasBeenReached]) {
                
                int total_gaps = 0, gaps;
                float distance_to_next_cornerpoint;
                
                float first_dash;
                float last_dash;
                float actual_dash_length;
                float main_length = (float)line->main_length;
                float main_gap = (float)line->main_gap;
                
                // Get the distance to the next corner point.
                distance_to_next_cornerpoint = [ct lengthOfCurrentSegment];
                
                // If we are at the start of the line, the first dash of the segment should be 'end-length'.
                first_dash = [ct onFirstSegment]?line->end_length:line->main_length;
                
                // If we are at the end of the line, the last dash of the segment should be 'end-length'.
                last_dash = [ct onLastSegment]?line->end_length:line->main_length;
                
                // Calculate the number of gaps and the new main length to use.
                // dist = first + gaps*gap_length + (gaps-1)*dash_length + end. Solved for gaps.
                gaps = ((int)roundf((distance_to_next_cornerpoint + main_length - first_dash - last_dash)/(main_length + main_gap)));
                
                // If the next corner point is the last coordinate, then we need to look at min_gap to know the number of gaps.
                if ([ct onLastSegment] && line->min_sym != -1 && line->min_sym >= total_gaps) {
                    gaps = line->min_sym + 1 - total_gaps;
                }
                
                if (gaps < 1) {
                    first_dash = distance_to_next_cornerpoint;
                } else if (gaps == 1) {
                    first_dash = last_dash = 0.5*(distance_to_next_cornerpoint - main_gap);
                } else {
                    // dist = first + gaps*gap_length + (gaps-1)*dash_length + end. Solved for the dash_length.
                    actual_dash_length = (distance_to_next_cornerpoint - first_dash - last_dash - gaps*main_gap)/(gaps - 1);
                }
                
                total_gaps += gaps;
                
                // Ok, the calculation is done for this segment. Now traverse it.
                int gaps_traversed;
                [ct advanceDistance:first_dash stroke:YES];
                for (gaps_traversed = 0; gaps_traversed < gaps; gaps_traversed++) {
                    [ct advanceDistance:main_gap stroke:NO];
                    if (gaps_traversed != gaps - 1) {
                        [ct advanceDistance:actual_dash_length stroke:YES];
                    }
                }
                [ct advanceDistance:last_dash stroke:YES];
            }
            [ct release];
      
        } else {
            for (c = 0; c < e->nCoordinates; c++) {
                if (e->coords[c].x & 1) {
                    // Bezier curve.
                    CGPathAddCurveToPoint(p, NULL, e->coords[c].x >> 8, e->coords[c].y >> 8, e->coords[c+1].x >> 8, e->coords[c+1].y >> 8, e->coords[c+2].x >> 8, e->coords[c+2].y >> 8);
                    c += 2;
                    
                } else {
                    CGPathAddLineToPoint(p, NULL, e->coords[c].x >> 8, e->coords[c].y >> 8);
                }
                
                if (e->coords[c].y & 1 && line != NULL && line->corner_d_size != 0) {
                    struct ocad_symbol_element *se = (struct ocad_symbol_element *)(line->coords + line->prim_d_size + line->sec_d_size);
                    
                    float angle = [[self class] angleForCoords:e->coords ofLength:e->nCoordinates atIndex:c];
                    [cachedData addObjectsFromArray:[self cacheSymbolElements:se 
                                                                      atPoint:NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8) 
                                                                    withAngle:angle 
                                                                totalDataSize:(se->ncoords + 2)
                                                                      element:e]];
                }
            }
        }

        NSMutableDictionary *mainLine = [NSMutableDictionary dictionaryWithCapacity:5];
        int colornum = (line != NULL)?line->line_color:e->color;
        float linewidth = (line != NULL)?line->line_width:e->linewidth;
        
        [mainLine setObject:(id)[self colorWithNumber:colornum] forKey:@"strokeColor"];
        [mainLine setObject:[NSNumber numberWithInt:colornum] forKey:@"colornum"];
        [mainLine setObject:[NSNumber numberWithFloat:linewidth] forKey:@"width"];
        [mainLine setObject:(id)p forKey:@"path"];
        [mainLine setObject:[NSValue valueWithPointer:e] forKey:@"element"];
        
        if (line != NULL) {
            switch (line->line_style) {
                case 0:
					[mainLine setObject:[NSNumber numberWithInt:kCGLineJoinBevel] forKey:@"joinStyle"];
					[mainLine setObject:[NSNumber numberWithInt:kCGLineCapButt] forKey:@"capStyle"];
                    break;
                case 1:
					[mainLine setObject:[NSNumber numberWithInt:kCGLineJoinRound] forKey:@"joinStyle"];
					[mainLine setObject:[NSNumber numberWithInt:kCGLineCapRound] forKey:@"capStyle"];
                    break;
                case 2:
					[mainLine setObject:[NSNumber numberWithInt:kCGLineJoinMiter] forKey:@"joinStyle"];
					[mainLine setObject:[NSNumber numberWithInt:kCGLineCapButt] forKey:@"capStyle"];
                    break;
            };
        }        
        
        [cachedData addObject:mainLine];
    }
    
    // Symbol elements along the line.
    // If prim_sym_dist > 0 and nprim_sym > 1, we must render two symbols.
    if (line != NULL && line->prim_d_size) {
        float phase = (float)line->end_length;
        float interval = (float)line->main_length;
        float last_symbol_position;
        float next_interval;
        float distance = -phase;
        float angle;
        float x, y, xp, yp;
        int current_prim_sym = 1;
        
        next_interval = interval;
        last_symbol_position = distance;
        
        for (c = 0; c < e->nCoordinates - 1; c++) {
            x = (float)(e->coords[c].x >> 8);
            y = (float)(e->coords[c].y >> 8);
            
            if (e->coords[c + 1].x & 1) {
                // Track the bezier curve to find places to put symbols.
                
                float t;
                float x2, y2;
                float xp0, yp0;
                float xb1, yb1, xb2, yb2;
                
                x2 = (float)(e->coords[c + 3].x >> 8);
                y2 = (float)(e->coords[c + 3].y >> 8);
                xb2 = (float)(e->coords[c + 2].x >> 8);
                yb2 = (float)(e->coords[c + 2].y >> 8);
                xb1 = (float)(e->coords[c + 1].x >> 8);
                yb1 = (float)(e->coords[c + 1].y >> 8);
                
                yp0 = y; xp0 = x;
                for (t = 0.025; t < 1.0; t+= 0.025) {
                    xp = powf(1.0-t, 3)*x + 3.0 * powf(1.0-t, 2.0) * t * xb1 + 3.0*(1.0-t)*t*t*xb2 + t*t*t*x2;
                    yp = powf(1.0-t, 3)*y + 3.0 * powf(1.0-t, 2.0) * t * yb1 + 3.0*(1.0-t)*t*t*yb2 + t*t*t*y2;
                    distance += sqrtf((xp - xp0)*(xp - xp0) + (yp - yp0)*(yp - yp0));
                    if (distance - last_symbol_position > next_interval) {
                        angle = [[self class] angleBetweenPoint:NSMakePoint(xp0, yp0) andPoint:NSMakePoint(xp, yp)];
                        [cachedData addObjectsFromArray:[self cacheSymbolElements:(struct ocad_symbol_element *)line->coords 
                                                                          atPoint:NSMakePoint(xp, yp) 
                                                                        withAngle:angle 
                                                                    totalDataSize:0
                                                                           element:e]];
                        last_symbol_position += next_interval;
                        if (++current_prim_sym > line->nprim_sym) {
                            current_prim_sym = line->nprim_sym;
                            next_interval = interval;
                        } else {
                            next_interval = line->prim_sym_dist;
                        }
                    }
                    xp0 = xp; yp0 = yp;
                }
                c += 2;
            } else {
                float x2, y2;
                float segment_distance, initial_distance = distance;
                BOOL space_left = YES;
                x2 = (float)(e->coords[c + 1].x >> 8);
                y2 = (float)(e->coords[c + 1].y >> 8);
                segment_distance = sqrtf((x2-x)*(x2-x) + (y2-y)*(y2-y));
                
                while (space_left) {
                    if (last_symbol_position + next_interval < initial_distance + segment_distance) {
                        // Ok, it fit
                        angle = [[self class] angleBetweenPoint:NSMakePoint(x, y) andPoint:NSMakePoint(x2, y2)];
                        last_symbol_position += next_interval;
                        [cachedData addObjectsFromArray:[self cacheSymbolElements:(struct ocad_symbol_element *)line->coords 
                                                                          atPoint:NSMakePoint(x + cos(angle)*(last_symbol_position - initial_distance), y + sin(angle)*(last_symbol_position - initial_distance)) 
                                                                        withAngle:angle 
                                                                    totalDataSize:0
                                                                           element:e]];
                        if (++current_prim_sym > line->nprim_sym) {
                            space_left = NO;
                        } else {
                            next_interval = line->prim_sym_dist;
                        }

                    } else {
                        space_left = NO;
                        distance = initial_distance + segment_distance;
                    }
                }
            }
        }
    }
    
    if (line != NULL && line->start_d_size != 0 && e->nCoordinates > 1) {
        float x, y, x0, y0;
        x = e->coords[0].x >> 8;
        y = e->coords[0].y >> 8;
        x0 = e->coords[1].x >> 8;
        y0 = e->coords[1].y >> 8;
        float angle = [[self class] angleBetweenPoint:NSMakePoint(x, y) andPoint:NSMakePoint(x0,y0)];
        struct TDPoly *p = line->coords;
        p += line->prim_d_size + line->sec_d_size + line->corner_d_size;
        [cachedData addObjectsFromArray:[self cacheSymbolElements:(struct ocad_symbol_element *)p
                                                          atPoint:NSMakePoint(x, y) 
                                                        withAngle:angle 
                                                    totalDataSize:0
                                                           element:e]];
    }

    if (line != NULL && line->end_d_size != 0 && e->nCoordinates > 1) {
        float x, y, x0, y0;
        x = e->coords[e->nCoordinates - 1].x >> 8;
        y = e->coords[e->nCoordinates - 1].y >> 8;
        x0 = e->coords[e->nCoordinates - 2].x >> 8;
        y0 = e->coords[e->nCoordinates - 2].y >> 8;
        float angle = [[self class] angleBetweenPoint:NSMakePoint(x0, y0) andPoint:NSMakePoint(x,y)];
        struct TDPoly *p = line->coords;
        p += line->prim_d_size + line->sec_d_size + line->corner_d_size + line->start_d_size;
        [cachedData addObjectsFromArray:[self cacheSymbolElements:(struct ocad_symbol_element *)p
                                                          atPoint:NSMakePoint(x, y) 
                                                        withAngle:angle 
                                                    totalDataSize:0
                                                           element:e]];
    }
    
    return [NSArray arrayWithObjects:cachedData, roadCache, nil];
    
}

@end

float ocad_distance_between_points(float p1x, float p1y, float p2x, float p2y) {
    // According to purple-pen, OCAD does not calculate distance normally. Instead it is approximated using the 'Bizarro' (their name)
    // distance metric.
    
    float dx = p2x - p1x;
    float dy = p2y - p1y;
    float bd = fmaxf(dx, dy);
    float ld = fminf(dx, dy);
    return 0.5*(bd+ld);    
}

float regular_distance_between_points(float p1x, float p1y, float p2x, float p2y) {
    return sqrtf((p2x-p1x)*(p2x-p1x) + (p2y-p1y)*(p2y-p1y));
}

CGPoint bezierCurvePoint(float t, CGPoint p0, CGPoint cp1, CGPoint cp2, CGPoint p1) {
    CGPoint bp;
    bp.x = p1.x*t*t*t + cp2.x*t*t*(1.0-t) + cp1.x*t*(1.0-t)*(1.0-t) + p0.x*(1.0-t)*(1.0-t)*(1.0-t);
    bp.y = p1.y*t*t*t + cp2.y*t*t*(1.0-t) + cp1.y*t*(1.0-t)*(1.0-t) + p0.y*(1.0-t)*(1.0-t)*(1.0-t);
    return bp;
}

void splitBezier(float t, CGPoint p0, CGPoint cp1, CGPoint cp2, CGPoint p1, CGPoint *points) {
    float s = 1.0 - t;
    CGPoint f00t, f01t, f11t, f0tt, f1tt, fttt;
    
    f00t.x = s * p0.x + t * cp1.x;
    f00t.y = s * p0.y + t * cp1.y;
    f01t.x = s * cp1.x + t * cp2.x;
    f01t.y = s * cp1.y + t * cp2.y;
    f11t.x = s * cp2.x + t * p1.x;
    f11t.y = s * cp2.y + t * p1.y;
    f0tt.x = s * f00t.x + t * f01t.x;
    f0tt.y = s * f00t.y + t * f01t.y;
    f1tt.x = s * f01t.x + t * f11t.x;
    f1tt.y = s * f01t.y + t * f11t.y;
    fttt.x = s * f0tt.x + t * f1tt.x;
    fttt.y = s * f0tt.y + t * f1tt.y;
    
    points[0] = p0;
    points[1] = f00t;
    points[2] = f0tt;
    points[3] = fttt;
    points[4] = fttt;
    points[5] = f1tt;
    points[6] = f11t;
    points[7] = p1;
}


@implementation CoordinateTransverser

- (id)initWith:(int)num_coords coordinates:(struct TDPoly *)coords withPath:(CGMutablePathRef)path {
    if ((self = [super init])) {
        _coords = coords;
        _path = path;
        _num_coords = num_coords;
        
        if (_path != NULL) {
            CGPathRetain(_path);
        }
        
        currentIndex = 0;
        currentFraction = 0.0;
        nothingLeft = NO;
    }
    return self;
}

- (void)dealloc {
    if (_path != NULL) {
        CGPathRelease(_path);
    }
    [super dealloc];
}

- (BOOL)endHasBeenReached {
    return _num_coords == currentIndex;
}
    
- (BOOL)onFirstSegment {
    return currentIndex == 0;
}
    
- (BOOL)onLastSegment {
    int i;
    for (i = currentIndex + 1; i < _num_coords; i++) {
        if (_coords[i].x & 1) return NO;
    }
    return YES;
}

- (CGFloat)lengthOfElementAtIndex:(int)i nextElement:(int *)next {
    // Calculate the length of a single element (straight line or bezier curve).
    int steps;
    CGPoint p0, p1;
    CGFloat d;
    
    p0 = CGPointMake(_coords[i].x >> 8, _coords[i].y >> 8);
    p1 = CGPointMake(_coords[i + 1].x >> 8, _coords[i + 1].y >> 8);
  
    if (_coords[i].x & 1) {
        CGPoint cp1, cp2, pa, pb;
        float bezierParameter;
        
        pa = p0;
        d = 0;
        for (bezierParameter = 0.025; bezierParameter < 1.0; bezierParameter += 0.025) {
            pb = bezierCurvePoint(bezierParameter, p0, cp1, cp2, p1);
            d += regular_distance_between_points(pa.x, pa.y, pb.x, pb.y);
            pa = pb;
        }

        steps = 3;
    } else {
        d = regular_distance_between_points(p1.x, p1.y, p0.x, p0.y);
        steps = 1;
    }
    
    if (next != NULL) {
        *next = i + steps;
    }
    
    return d; 
}

                                                
- (CGFloat)lengthOfCurrentSegment {
    return [self lengthOfSegmentAtIndex:currentIndex nextSegment:NULL];
}

- (CGFloat)lengthOfSegmentAtIndex:(int)i nextSegment:(int *)next {
    // Calculate the length of a single segment (up until the next corner point).
    CGFloat d = 0.0;
    int j;
    
    do {
        d += [self lengthOfElementAtIndex:i nextElement:&j];
        i = j;
    } while (i != _num_coords && ((_coords[i].x & 1) == 0));
    
    if (next != NULL) {
        *next = i;
    }
    
    return d;
    
}

- (float)lengthOfEntirePath {
    int i, j;
    float d = 0.0;
    
    for (i = 0; i < _num_coords; i = j) {
        d += [self lengthOfElementAtIndex:i nextElement:&j];
    }
    
    return d;
}

- (CGPoint)advanceDistance:(CGFloat)distance {
    return [self advanceDistance:distance stroke:NO];
}

- (CGPoint)advanceDistance:(CGFloat)distance stroke:(BOOL)stroke {
    float remaining_distance = distance;
    float t;
    CGPoint p0, p1, cp1, cp2;
    CGPoint buffer1[8], buffer2[8];
    CGPoint stop;
    
    p0 = CGPointMake(_coords[currentIndex].x >> 8, _coords[currentIndex].y >> 8);
    
    while (remaining_distance > 0 && currentIndex < _num_coords) {
        if ((_coords[currentIndex].x & 1) == 0) {
            p1 = CGPointMake(_coords[currentIndex + 1].x >> 8, _coords[currentIndex + 1].y >> 8);
            CGFloat d = regular_distance_between_points(p1.x, p1.y, p0.x, p0.y);
            if ((1.0 - currentFraction)*d < remaining_distance) {
                // The entire segment will be consumed.
                if (_path != NULL) {
                    if (stroke) {
                        CGPathAddLineToPoint(_path, NULL, p1.x, p1.y);
                    } else {
                        CGPathMoveToPoint(_path, NULL, p1.x, p1.y);
                    }
                }
                remaining_distance -= (1.0 - currentFraction)*d;
                currentFraction = 0.0;
                currentIndex ++;
            } else {
                // There will be some left.
                float newFraction = remaining_distance / d + currentFraction;
                stop.x = p0.x*(1.0-newFraction) + p1.x*newFraction;
                stop.y = p0.y*(1.0-newFraction) + p1.y*newFraction;
                if (_path != NULL) {
                    if (stroke) {
                        CGPathAddLineToPoint(_path, NULL, stop.x, stop.y);
                    } else {
                        CGPathMoveToPoint(_path, NULL, stop.x, stop.y);
                    }
                }
                currentFraction = newFraction;
            }
        } else {
            p1 = CGPointMake(_coords[currentIndex + 3].x >> 8, _coords[currentIndex + 3].y >> 8);
            cp1 = CGPointMake(_coords[currentIndex + 1].x >> 8, _coords[currentIndex + 1].y >> 8);
            cp2 = CGPointMake(_coords[currentIndex + 2].x >> 8, _coords[currentIndex + 2].y >> 8);
            CGPoint bp, p;
            
            p = bezierCurvePoint(currentFraction, p0, cp1, cp2, p1);

            for (t = currentFraction + 0.025; t <= 1.0 && remaining_distance > 0.0; t++) {
                bp = bezierCurvePoint(t, p0, cp1, cp2, p1);
                remaining_distance -= regular_distance_between_points(p.x, p.y, bp.x, bp.y);
            }
            
            // ABSOLUTELY TODO: better handling of the case where remaining_distance is zero and when it is not zero.
            if (_path != NULL) {
                if (stroke) {
                    // Construct a new bezier curve from currentFraction to t.
                    splitBezier(currentFraction, p0, cp1, cp2, p1, buffer1);
                    splitBezier((t - currentFraction)/(1.0-currentFraction), buffer1[4], buffer1[5],buffer1[6],buffer1[7], buffer2);
                    CGPathAddCurveToPoint(_path, NULL, buffer2[1].x, buffer2[1].y, buffer2[2].x, buffer2[2].y, buffer2[3].x, buffer2[3].y);
                } else {
                    CGPathMoveToPoint(_path, NULL, bp.x, bp.y);
                }
            }
            if (remaining_distance == 0.0) {
                currentFraction = t;
            } else {
                currentFraction = 0.0;
                currentIndex += 3;
            }
        }
    }
    
    return stop;
}


@end

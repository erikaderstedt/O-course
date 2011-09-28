//
//  ASOCADController_Line.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-26.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOCADController_Line.h"
#import "CoordinateTransverser.h"

@implementation ASOCADController (ASOCADController_Line)

- (NSArray *)cachedDrawingInfoForLineObject:(struct ocad_element *)e {
    struct ocad_line_symbol *line = (struct ocad_line_symbol *)(e->symbol);
    int c;
	
    NSDictionary *roadCache = nil;
    NSMutableArray *cachedData = [NSMutableArray arrayWithCapacity:10];
    
    if (e->nCoordinates == 0 || (line != NULL && line->status == 2 /* Hidden */)) {
        return [NSArray array];
    }
    
    if (line != NULL && (line->dbl_width != 0)) {
		CGMutablePathRef left = CGPathCreateMutable();
		CGMutablePathRef right = CGPathCreateMutable();
		CGMutablePathRef road = CGPathCreateMutable();
        
        CGPoint p0 = CGPointMake(e->coords[0].x >> 8, e->coords[0].y >> 8), p1;
		CGPathMoveToPoint(road, NULL, p0.x, p0.y);
        
        // For each point
        float angle = 0.0, thisAngle, nextangle;
        float *angles = calloc(sizeof(float), e->nCoordinates);
        int angleIndex = 0;
       
        for (c = 1; c < e->nCoordinates; c++) {
            p1 = CGPointMake(e->coords[c].x >> 8, e->coords[c].y >> 8);
            thisAngle = angle_between_points(p0, p1);
            
            if (angleIndex > 0) {
                // We want to calculate the average between this angle and the last. If the angle "wraps"
                // (i.e., one angle is very small and the other is near 2*pi), we cannot take the arithmetic average.
                angles[angleIndex] = atan2f(sinf(thisAngle)+sinf(angles[angleIndex - 1]), cosf(thisAngle) + cosf(angles[angleIndex - 1]));
            } else {
                angles[angleIndex] = thisAngle;
            }
            
            if (e->coords[c].x & 1) {
                // Bezier curve.
                CGPoint p2 = CGPointMake(e->coords[c + 1].x >> 8, e->coords[c + 1].y >> 8);
                NSAssert(e->coords[c+1].x & 2, @"Next is not the second control point");
                CGPoint p3 = CGPointMake(e->coords[c+2].x >> 8, e->coords[c+2].y >> 8);

				CGPathAddCurveToPoint(road, NULL, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
                c += 2;
                // 3 coordinates consumed and 2 angles consumed.
                p0 = p3;
                angles[++angleIndex] = angle_between_points(p2, p3);
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
        CGMutablePathRef path = CGPathCreateMutable();        

        CoordinateTransverser *ct = [[CoordinateTransverser alloc] initWith:e->nCoordinates coordinates:e->coords withPath:path];
        CGPoint p0 = [ct currentPoint];
        CGPathMoveToPoint(path, NULL, p0.x, p0.y);

        if (line != NULL && line->main_gap != 0) { // A dashed line.

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
                if (distance_to_next_cornerpoint == 0.0) {
                    [ct advanceSegmentWhileStroking:NO];
                    continue;
                }
                
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
      
        } else {
            do {
                [ct advanceSegmentWhileStroking:YES];
            } while (![ct endHasBeenReached]);
        }

        NSMutableDictionary *mainLine = [NSMutableDictionary dictionaryWithCapacity:5];
        int colornum = (line != NULL)?line->line_color:e->color;
        float linewidth = (line != NULL)?line->line_width:e->linewidth;
        
        [mainLine setObject:(id)[self colorWithNumber:colornum] forKey:@"strokeColor"];
        [mainLine setObject:[NSNumber numberWithInt:colornum] forKey:@"colornum"];
        [mainLine setObject:[NSNumber numberWithFloat:linewidth] forKey:@"width"];
        [mainLine setObject:(id)path forKey:@"path"];
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
        [ct release];
        CGPathRelease(path);

    }
/*
    // Draw corner points (like symbol 516 for example).
    if (line != NULL && line->corner_d_size) {
        CoordinateTransverser *ct = [[CoordinateTransverser alloc] initWith:e->nCoordinates coordinates:e->coords withPath:NULL];
    
        CGPoint p;
        struct ocad_symbol_element *se = (struct ocad_symbol_element *)(line->coords + line->prim_d_size + line->sec_d_size);
        
        // Corner points are placed where coords[i].y & 1 in the interior of the path. At the ends the start and end symbols are placed instead.
        while (![ct endHasBeenReached]) {
            p = [ct advanceSegmentWhileStroking:NO];
            if ([ct atCornerPoint] && ![ct endHasBeenReached]) {
                [cachedData addObjectsFromArray:[self cacheSymbolElements:se 
                                                                  atPoint:p
                                                                withAngle:[ct currentAngle]
                                                            totalDataSize:(se->ncoords + 2)
                                                                  element:e]];
            }            
        }
    } */
    
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
                        angle = angle_between_points(CGPointMake(xp0,yp0), CGPointMake(xp, yp));
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
                        angle = angle_between_points(CGPointMake(x,y),CGPointMake(x2,y2));
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
        float angle = angle_between_points(CGPointMake(x,y), CGPointMake(x0,y0));
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
        float angle = angle_between_points(CGPointMake(x0,y0), CGPointMake(x,y));
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



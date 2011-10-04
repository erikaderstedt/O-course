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
    
    CoordinateTransverser *ct = [[CoordinateTransverser alloc] initWith:e->nCoordinates coordinates:e->coords withPath:NULL];

    // TODO: convert this to use CoordinateTransverser. Will enable dashed double lines (e.g. roads under construction).
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
    
    // Create the path for the main line. 
    if (e->linewidth != 0 || (line != NULL && line->line_width != 0)) {
        CGMutablePathRef path = CGPathCreateMutable();        
        
        [ct reset];
        [ct setPath:path];
        
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
        CGPathRelease(path);

    }

    // Draw corner points (like symbol 516 for example).
    if (line != NULL && line->corner_d_size) {
        [ct reset];
    
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
    } 
    
    // Symbol elements along the line.
    // TODO: add support for main_gap.
    if (line != NULL && line->prim_d_size) {
        [ct reset];
        CGFloat all = [ct lengthOfEntirePath];
        CGFloat distance, initial;

        // For double symbols, like 524. 
        CGFloat spacing = line->prim_sym_dist; 
        
        distance = line->main_length;
        initial = line->end_length;
        
        // Enforce at least one symbol.
        if (initial * 2.0 + distance + spacing > all) {
            initial = 0.5*all - 0.5*spacing;
            distance = all;
        }
        
        CGPoint p;
        int prim_sym_index = 0;
        
        p = [ct advanceDistance:initial];
        while (![ct endHasBeenReached]) {
            [cachedData addObjectsFromArray:[self cacheSymbolElements:(struct ocad_symbol_element *)line->coords 
                                                              atPoint:p 
                                                            withAngle:[ct currentAngle] 
                                                        totalDataSize:0
                                                              element:e]];
            if (prim_sym_index < line->nprim_sym - 1) {
                p = [ct advanceDistance:spacing];
                prim_sym_index ++;
            } else {
                p = [ct advanceDistance:distance];
                prim_sym_index = 0;
            }
        }
    }

    if (line != NULL && line->end_d_size != 0 && e->nCoordinates > 1) {
        [ct reset];
        
        CGPoint p0, p1;
        CGFloat angle;
        struct TDPoly *p = line->coords;
        p += line->prim_d_size + line->sec_d_size + line->corner_d_size + line->start_d_size;
       
        // Draw both starting and ending symbol elements using the end symbol. The start symbol is not used?
        p0 = [ct coordinateAtIndex:0];
        p1 = [ct coordinateAtIndex:1];
        angle = angle_between_points(p0, p1);
        [cachedData addObjectsFromArray:[self cacheSymbolElements:(struct ocad_symbol_element *)p
                                                          atPoint:p0 
                                                        withAngle:angle 
                                                    totalDataSize:0
                                                          element:e]];
        
        p0 = [ct coordinateAtIndex:e->nCoordinates - 1];
        p1 = [ct coordinateAtIndex:e->nCoordinates - 2];
        angle = angle_between_points(p1, p0);
        [cachedData addObjectsFromArray:[self cacheSymbolElements:(struct ocad_symbol_element *)p
                                                          atPoint:p0 
                                                        withAngle:angle 
                                                    totalDataSize:0
                                                           element:e]];
    }
    [ct release];
    
    return [NSArray arrayWithObjects:cachedData, roadCache, nil];
    
}

@end



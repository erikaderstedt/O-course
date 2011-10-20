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

- (void)traverse:(CoordinateTransverser *)ct distance:(float)length withSecondaryGapLength:(float)sec_gap {
    if (sec_gap > 0.0) {
        float d = 0.5*(length - sec_gap);
        if (d < 0) {
            [ct advanceDistance:length stroke:NO];
        } else {
            [ct advanceDistance:d stroke:YES];
            [ct advanceDistance:sec_gap stroke:NO];
            [ct advanceDistance:d stroke:YES];
        }
    } else {
        [ct advanceDistance:length stroke:YES];
    }
}

- (NSArray *)cachedDrawingInfoForLineObject:(struct ocad_element *)e {
    struct ocad_line_symbol *line = (struct ocad_line_symbol *)(e->symbol);
	
    NSDictionary *roadCache = nil;
    NSMutableArray *cachedData = [NSMutableArray arrayWithCapacity:10];
    
    if (e->nCoordinates == 0 || 
       // Höjder av hjälpkurvor, 103001, har status == 2. (line != NULL && line->status == 2 /* Hidden */) ||
        (line != NULL && line->selected == 512 /* Also hidden ? */)) {
        return [NSArray array];
    }
    
    CGLineCap capStyle = kCGLineCapButt;
    CGLineJoin joinStyle = kCGLineJoinBevel;

    if (line != NULL) {
        switch (line->line_style) {
            case 0:
                // Default, see above.
                break;
            case 1:
                capStyle = kCGLineCapRound;
                joinStyle = kCGLineJoinRound;
                break;
            case 2:
                capStyle = kCGLineCapButt;
                joinStyle = kCGLineJoinMiter;
                break;
        };
    }    
    
    CoordinateTransverser *ct = [[CoordinateTransverser alloc] initWith:e->nCoordinates coordinates:e->coords withPath:NULL];
    if (line != NULL) {
        ct.translateDistanceLeft = 0.5*((float)line->dbl_width) + 0.5*((float)line->dbl_left_width);
        ct.translateDistanceRight = 0.5*((float)line->dbl_width) + 0.5*((float)line->dbl_right_width);
    }

    // TODO: support dashed double lines. Requires a suitable file to test on.
    if (line != NULL && (line->dbl_width != 0)) {
        [ct reset];
        
		CGMutablePathRef left = CGPathCreateMutable();
		CGMutablePathRef right = CGPathCreateMutable();
		CGMutablePathRef road = CGPathCreateMutable();
        
        [ct setPath:road];
        [ct setLeftPath:left];
        [ct setRightPath:right];
        
        do {
            [ct advanceSegmentWhileStroking:YES];
        } while (![ct endHasBeenReached]);
        
        if (line->dbl_flags > 0) {
            CGPathRef strokedRoad = CGPathCreateCopyByStrokingPath(road, NULL, (float)line->dbl_width, capStyle, joinStyle, 0.5*((float)line->dbl_width));
            roadCache = [NSDictionary dictionaryWithObjectsAndKeys:(id)[self colorWithNumber:line->dbl_fill_color], @"fillColor", 
                         [NSNumber numberWithInt:line->dbl_fill_color],@"colornum",
                         [NSValue valueWithPointer:e], @"element",
                         strokedRoad, @"path", nil];
            CGPathRelease(strokedRoad);
        }
        CGPathRelease(road);
        CGPathRef strokedLeft = CGPathCreateCopyByStrokingPath(left, NULL, (float)line->dbl_left_width, capStyle, joinStyle, 0.5*((float)line->dbl_left_width));
        CGPathRef strokedRight = CGPathCreateCopyByStrokingPath(right, NULL, (float)line->dbl_right_width, capStyle, joinStyle, 0.5*((float)line->dbl_right_width));
        
        [cachedData addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)[self colorWithNumber:line->dbl_left_color], @"fillColor", 
                               [NSNumber numberWithInt:line->dbl_left_color],@"colornum",
                               [NSValue valueWithPointer:e], @"element",
							   strokedLeft, @"path", nil]];
        [cachedData addObject:[NSDictionary dictionaryWithObjectsAndKeys:(id)[self colorWithNumber:line->dbl_right_color], @"fillColor", 
                               [NSNumber numberWithInt:line->dbl_right_color],@"colornum",
                               [NSValue valueWithPointer:e], @"element",
							   strokedRight, @"path", nil]]; 
        CGPathRelease(strokedLeft);
        CGPathRelease(strokedRight);
        CGPathRelease(left);
        CGPathRelease(right);
    }
    
    // Create the path for the main line. 
    if (e->linewidth != 0 || (line != NULL && line->line_width != 0)) {
        CGMutablePathRef path = CGPathCreateMutable();        
        
        [ct reset];
        [ct setPath:path];
        
        if (line != NULL && line->main_gap != 0) { // A dashed line.
    
            while (![ct endHasBeenReached]) {
                
                int total_gaps = 0, gaps;
                float distance_to_next_cornerpoint;
                
                float first_dash;
                float last_dash;
                float actual_dash_length;
                float main_length = (float)line->main_length;
                float main_gap = (float)line->main_gap;
                float sec_gap = (float)line->sec_gap;
                
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
                
                if (gaps < 1) gaps = 1;
                
                // If the next corner point is the last coordinate, then we need to look at min_gap to know the number of gaps.
                if ([ct onLastSegment] && line->min_sym != -1 && line->min_sym >= total_gaps) {
                    if (gaps < line->min_sym + 1 - total_gaps)
                        gaps = line->min_sym + 1 - total_gaps;
                }
                
                if (gaps == 1) {
                    first_dash = last_dash = 0.5*(distance_to_next_cornerpoint - main_gap);
                } else {
                    // dist = gaps*gap_length + (gaps+1)*dash_length . Solved for the dash_length.
                    actual_dash_length = (distance_to_next_cornerpoint - gaps*main_gap)/(gaps + 1);
                    first_dash = actual_dash_length;
                    last_dash = actual_dash_length;
                }
                
                total_gaps += gaps;
                
                // Ok, the calculation is done for this segment. Now traverse it.
                int gaps_traversed;
                // Insert secondary gaps into the middle of the dashes.
                [self traverse:ct distance:first_dash withSecondaryGapLength:sec_gap];
                for (gaps_traversed = 0; gaps_traversed < gaps; gaps_traversed++) {
                    [ct advanceDistance:main_gap stroke:NO];
                    if (gaps_traversed != gaps - 1) {
                        [self traverse:ct distance:actual_dash_length withSecondaryGapLength:sec_gap];
                    }
                }
                [self traverse:ct distance:last_dash withSecondaryGapLength:sec_gap];
            }
      
        } else {
            do {
                [ct advanceSegmentWhileStroking:YES];
            } while (![ct endHasBeenReached]);
        }

        NSMutableDictionary *mainLine = [NSMutableDictionary dictionaryWithCapacity:5];
        int colornum = (line != NULL)?line->line_color:e->color;
        float linewidth = (line != NULL)?line->line_width:e->linewidth;
        
        [mainLine setObject:[NSNumber numberWithInt:colornum] forKey:@"colornum"];
        [mainLine setObject:[NSNumber numberWithFloat:linewidth] forKey:@"width"];
        [mainLine setObject:[NSValue valueWithPointer:e] forKey:@"element"];
            
        CGPathRef strokedPath = CGPathCreateCopyByStrokingPath(path, NULL, linewidth, capStyle, joinStyle, 0.5*linewidth);
        [mainLine setObject:(id)strokedPath forKey:@"path"];
        [mainLine setObject:(id)[self colorWithNumber:colornum] forKey:@"fillColor"];
        [cachedData addObject:mainLine];
        CGPathRelease(path);
        CGPathRelease(strokedPath);

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
    if (line != NULL && line->prim_d_size && (line->main_length != 0 || line->prim_sym_dist != 0)) {
        [ct reset];
        CGFloat all = [ct lengthOfEntirePath];
        if (all > 0) {
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
        if ([ct atCornerPoint])
            [cachedData addObjectsFromArray:[self cacheSymbolElements:(struct ocad_symbol_element *)p
                                                              atPoint:p0 
                                                            withAngle:angle 
                                                        totalDataSize:0
                                                              element:e]];
        [ct goToEnd];
        p0 = [ct coordinateAtIndex:e->nCoordinates - 1];
        p1 = [ct coordinateAtIndex:e->nCoordinates - 2];
        angle = angle_between_points(p1, p0);
        if ([ct atCornerPoint])
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


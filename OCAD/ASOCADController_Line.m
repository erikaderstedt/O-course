//
//  ASOCADController_Line.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-26.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOCADController_Line.h"


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
        
        angleIndex = 0;
		p1 = [[self class] translatePoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) distance:(line->dbl_width) angle:(angles[0] + pi/2)]; 
		CGPathMoveToPoint(left, NULL, p1.x, p1.y);
		p1 = [[self class] translatePoint:NSMakePoint(e->coords[0].x >> 8, e->coords[0].y >> 8) distance:(line->dbl_width) angle:(angles[0] - pi/2)];
		CGPathMoveToPoint(right, NULL, p1.x, p1.y);
        
        for (c = 1; c < e->nCoordinates; c++) {
            angle = angles[angleIndex];
            
            p1 = NSMakePoint(e->coords[c].x >> 8, e->coords[c].y >> 8);
            NSPoint p1l, p2l, p3l, p1r, p2r, p3r;
            p1l = [[self class] translatePoint:p1 distance:(line->dbl_width) angle:(angle + pi/2)];
            p1r = [[self class] translatePoint:p1 distance:(line->dbl_width) angle:(angle - pi/2)];
            
            if (e->coords[c].x & 1) {
                NSPoint p2 = NSMakePoint(e->coords[c + 1].x >> 8, e->coords[c + 1].y >> 8);
                NSPoint p3 = NSMakePoint(e->coords[c+2].x >> 8, e->coords[c+2].y >> 8);

                nextangle = angles[++angleIndex];
                // Bezier curve.
                p2l = [[self class] translatePoint:p2 distance:(line->dbl_width) angle:(nextangle + pi/2)];
                p3l = [[self class] translatePoint:p3 distance:(line->dbl_width) angle:(nextangle + pi/2)];
                p2r = [[self class] translatePoint:p2 distance:(line->dbl_width) angle:(nextangle - pi/2)];
                p3r = [[self class] translatePoint:p3 distance:(line->dbl_width) angle:(nextangle - pi/2)];
                
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
        
        roadCache = [NSDictionary dictionaryWithObjectsAndKeys:(id)[self colorWithNumber:line->dbl_fill_color], @"strokeColor", 
                     [NSNumber numberWithInt:line->dbl_fill_color],@"colornum",
                     [NSValue valueWithPointer:e], @"element",
					 road, @"path", [NSNumber numberWithFloat:line->dbl_width + line->dbl_left_width*0.5 + line->dbl_right_width*0.5], @"width", nil];
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
    if (e->linewidth != 0 || (line != NULL && line->line_width != 0)) {
		CGPathMoveToPoint(p, NULL, e->coords[0].x >> 8, e->coords[0].y >> 8);
        
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
        CGColorRef mainColor;
		NSMutableDictionary *mainLine = [NSMutableDictionary dictionaryWithCapacity:5];
        
        if (line != NULL && line->line_color < CFArrayGetCount(colors)) 
            mainColor = (CGColorRef)CFArrayGetValueAtIndex(colors, line->line_color);
        else if (e->color < CFArrayGetCount(colors))
            mainColor = (CGColorRef)CFArrayGetValueAtIndex(colors, e->color);
        else
            mainColor = blackColor;
        
        if (line != NULL && line->main_length != 0) {
			NSMutableArray *dashes = [NSMutableArray arrayWithCapacity:4];
			[dashes addObject:[NSNumber numberWithInt:line->main_length]];
			[dashes addObject:[NSNumber numberWithInt:line->main_gap]];
            if (line->sec_gap > 0) {
				[dashes addObject:[NSNumber numberWithInt:line->main_length]];
				[dashes addObject:[NSNumber numberWithInt:line->sec_gap]];
            }
			[mainLine setObject:dashes forKey:@"dashes"];
        }
        
        if (line != NULL) {
			[mainLine setObject:[NSNumber numberWithFloat:(CGFloat)(line->line_width)] forKey:@"width"];
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
        } else {
 			[mainLine setObject:[NSNumber numberWithFloat:(CGFloat)(e->linewidth)] forKey:@"width"];
        }
		[mainLine setObject:(id)mainColor forKey:@"strokeColor"];
		[mainLine setObject:(id)p forKey:@"path"];
        [mainLine setObject:[NSValue valueWithPointer:e] forKey:@"element"];
        [mainLine setObject:[NSNumber numberWithInt:e->color] forKey:@"colornum"];
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

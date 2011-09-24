//
//  ASOCADController_Text.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-06-26.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "ASOCADController_Text.h"

@implementation ASOCADController (ASOCADController_Text)

- (NSDictionary *)cachedDrawingInfoForTextObject:(struct ocad_element *)e {
    struct ocad_text_symbol *text = (struct ocad_text_symbol *)(e->symbol);
    
    // Load the actual string
	char *rawBuffer = (char *)&(e->coords[e->nCoordinates]);
    char buffer[4096];
    int i;
    for (i =0; rawBuffer[i*2] != 0; i++) {
        buffer[i] = rawBuffer[i*2];
    }
    buffer[i] = 0;
    NSString *string = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
    
    // Load the font name and size.
    rawBuffer = text->fontname;
    NSString *fontName = [NSString stringWithCString:rawBuffer encoding:NSASCIIStringEncoding];
    CGFloat fontSize = ((CGFloat)text->fontsize)*72.0/2.54 / 10.0;
    if (text->weight == 700) fontName = [fontName stringByAppendingString:@" Bold"];
    
    CTFontRef font = CTFontCreateWithName((CFStringRef)fontName, fontSize, NULL);
    if (font == NULL) {
        NSLog(@"Replacing '%@' with Lucida Grande", fontName);
        font = CTFontCreateWithName(CFSTR("Lucida Grande"), fontSize, NULL);
    }
    if (text->italic) {
        CTFontRef oldFont = font;
        font = CTFontCreateCopyWithSymbolicTraits(oldFont, fontSize, NULL, kCTFontItalicTrait, kCTFontItalicTrait);
        if (font != NULL) {
            CFRelease(oldFont);
        } else {
            font = oldFont;
        }
    }
    string = [string stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\r"];
    
    CTParagraphStyleSetting pss[20];
    CTTextAlignment align = kCTLeftTextAlignment;
    switch (text->alignment) {
        case 0:
        case 4:
        case 8:
            align = kCTLeftTextAlignment;
            break;
        case 1:
        case 5:
        case 9:
            align = kCTCenterTextAlignment;
            break;
        case 2:
        case 6:
        case 10:
            align = kCTRightTextAlignment;
            break;
        case 3:
            align = kCTJustifiedTextAlignment;
            break;
        default:
            NSLog(@"unknown alignment: %d", text->alignment);
            break;
    }
    i = 0;
    
    pss[i].spec = kCTParagraphStyleSpecifierAlignment;
    pss[i].valueSize = sizeof(CTTextAlignment);
    pss[i].value = &align;
    i++;
    
    CGFloat indent_first;
    pss[i].spec = kCTParagraphStyleSpecifierFirstLineHeadIndent;
    indent_first = text->indent_first;
    pss[i].valueSize = sizeof(CGFloat);
    pss[i].value = &indent_first;
    i++;
    
    CGFloat indent_other;
    pss[i].spec = kCTParagraphStyleSpecifierHeadIndent;
    indent_other = text->indent_other;
    pss[i].valueSize = sizeof(CGFloat);
    pss[i].value = &indent_other;
    i++;
    
    int j = 0;
    CTTextTabRef tabArray[32];
    for (j = 0; j < text->number_of_tabs; j++) {
        CTTextTabRef tt = CTTextTabCreate(kCTLeftTextAlignment, ((CGFloat)text->tabs[j]) + 80.0, NULL);
        tabArray[j] = tt;
    }
    CFArrayRef tabs = CFArrayCreate(NULL, (const void**) tabArray, text->number_of_tabs, NULL);
    if (j > 0) {
        pss[i].spec = kCTParagraphStyleSpecifierTabStops;
        pss[i].valueSize = sizeof(CFMutableArrayRef);
        pss[i].value = &tabs;
        i++;
    }

    CGFloat maxLineHeight = ((CGFloat)(text->linespacing)) *2.07; // TODO: fix this magic number.
    pss[i].spec = kCTParagraphStyleSpecifierMaximumLineHeight;
    pss[i].valueSize = sizeof(CGFloat);
    pss[i].value = &maxLineHeight;
    i++;
    
    CGFloat minLineHeight = maxLineHeight;
    pss[i].spec = kCTParagraphStyleSpecifierMinimumLineHeight;
    pss[i].valueSize = sizeof(CGFloat);
    pss[i].value = &minLineHeight;
    i++;
    
    CGFloat paraspacing = 0.0;
    pss[i].spec = kCTParagraphStyleSpecifierParagraphSpacing;
    pss[i].valueSize = sizeof(CGFloat);
    pss[i].value = &paraspacing;
    i++;
    
    CGFloat paraspacingBefore = 0.0;
    pss[i].spec = kCTParagraphStyleSpecifierParagraphSpacingBefore;
    pss[i].valueSize = sizeof(CGFloat);
    pss[i].value = &paraspacingBefore;
    i++;
    
    CGFloat leading = 0.0;
    pss[i].spec = kCTParagraphStyleSpecifierLineSpacing;
    pss[i].valueSize = sizeof(CGFloat);
    pss[i].value = &leading;
    i++;
    
    CTParagraphStyleRef pstyle = CTParagraphStyleCreate(pss, i);
    
    CGColorRef color = [self colorWithNumber:text->fontcolor];
    CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString (attrString, CFRangeMake(0, 0), (CFStringRef)string);
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength((CFStringRef)string)), kCTForegroundColorAttributeName, color);
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength((CFStringRef)string)), kCTFontAttributeName, font);
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength((CFStringRef)string)), kCTParagraphStyleAttributeName, pstyle);
    CFRelease(tabs);
    CFRelease(pstyle);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attrString);
    CFRelease(attrString);
    

    CGMutablePathRef p = CGPathCreateMutable();
    CGRect r;
    
    int midx = 0, midy = 0, x, y;
    for (i = 0; i < 4 && i < e->nCoordinates; i++) {
        x = e->coords[i].x >> 8;
        y = e->coords[i].y >> 8;
        midx += x;
        midy += y;
    }
    midy /= e->nCoordinates;
    midx /= e->nCoordinates;
    
    if (e->angle != 0 && e->angle != 3600) {
        // Look at the first 4 coordinates.
        // Transform each point by -angle.
        // Get the size of that rect.
        // Get the midpoint of that rect.
        // Translate the midpoint back +angle.
        // Calculate r from the midpoint + size.
        
        CGPoint midpoint = CGPointMake(midx, midy);
        CGFloat alpha = ((CGFloat)e->angle)*pi/180.0/10.0;
        alpha = -alpha;
        CGAffineTransform at = CGAffineTransformMake(cos(alpha), sin(alpha), -sin(alpha), cos(alpha), 
                                                     midpoint.x*(1.0-cos(alpha))  +midpoint.y*sin(alpha),
                                                     -midpoint.x*sin(alpha) + midpoint.y*(1.0-cos(alpha)));
        
        CGPathMoveToPoint(p, &at, e->coords[0].x >> 8, e->coords[0].y >> 8);
        for (i = 1; i < e->nCoordinates; i++) {
            CGPathAddLineToPoint(p, &at, e->coords[i].x >> 8, e->coords[i].y >> 8);
        }
        r = CGRectIntegral(CGPathGetBoundingBox(p));
            
        CGPathRelease(p);
        p = CGPathCreateMutable();
        CGPathAddRect(p, NULL, r);
    } else {  
        int xmin, xmax, ymin, ymax;
        xmin = xmax = e->coords[0].x >> 8;
        ymin = ymax = e->coords[0].y >> 8;
        for (i = 1; i < e->nCoordinates; i++) {
            x = e->coords[i].x >> 8;
            y = e->coords[i].y >> 8;
            if (x < xmin) xmin = x;
            if (x > xmax) xmax = x;
            if (y < ymin) ymin = y;
            if (y > ymax) ymax = y;
        }
        r.origin.x = xmin;
        r.origin.y = ymin;
        if (text->alignment == 0)
            r.size.width = (xmax-xmin) * 1.0;
        r.size.height = ymax-ymin;
        
        r.origin.y += ((CGFloat)text->paraspacing)*2.07;
        
        CGPathAddRect(p, NULL, r);
    }
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0,0), p, NULL);
    CFRelease(framesetter);
    
    CFRelease(font);
    
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:3];
    if (frame != NULL) {
        [d setObject:(id)frame forKey:@"frame"];
        CFRelease(frame);
    }
    [d setObject:(id)p forKey:@"path"];
    CGPathRelease(p);
    
    if (e->angle != 0 && e->angle != 3600) {
        [d setObject:[NSNumber numberWithDouble:((CGFloat)e->angle)/10.0] forKey:@"angle"];

        [d setObject:[NSNumber numberWithInt:midx] forKey:@"midX"];
        [d setObject:[NSNumber numberWithInt:midy] forKey:@"midY"];
    }
    if (e->symbol != NULL) {
        [d setObject:[NSValue valueWithPointer:e] forKey:@"element"];
    }
    [d setObject:[NSNumber numberWithInt:e->color] forKey:@"colornum"];
    
    return d;    
}

@end

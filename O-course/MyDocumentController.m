//
//  MyDocumentController.m
//  O-course
//
//  Created by Erik Aderstedt on 2011-09-24.
//  Copyright 2011 Aderstedt Software AB. All rights reserved.
//

#import "MyDocumentController.h"
#import "ASOcourseDocument.h"
#import "Project.h"

@implementation MyDocumentController

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
    if ([[url pathExtension] isEqualToString:@"ocd"]) {
        ASOcourseDocument *doc = [self openUntitledDocumentAndDisplay:displayDocument error:nil];
        [[doc project] setMap:[url path]];
        completionHandler(doc, NO, nil);
        return;
    }
    [super openDocumentWithContentsOfURL:url display:YES completionHandler:completionHandler];
}

@end

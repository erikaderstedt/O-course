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
#import "ocdimport.h"

@implementation MyDocumentController

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
    if ([[url pathExtension] isEqualToString:@"ocd"]) {
        NSString *path = [url path];
        NSError *e = nil;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            e = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"File not found.", nil) forKey:NSLocalizedDescriptionKey]];
        } else if (!supported_version([path cStringUsingEncoding:NSUTF8StringEncoding])) {
            e = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Invalid OCAD version. Only versions 9 and 10 are supported.", nil) forKey:NSLocalizedDescriptionKey]];
        }
        
        if (e != nil) {
            completionHandler(nil, NO, e);
        } else {
            ASOcourseDocument *doc = [self openUntitledDocumentAndDisplay:displayDocument error:nil];
            [doc setMapURL:url];
            completionHandler(doc, NO, nil);
        }
        return;
    }
    [super openDocumentWithContentsOfURL:url display:YES completionHandler:completionHandler];
}

- (id)makeUntitledDocumentOfType:(NSString *)typeName error:(NSError **)outError {
    ASOcourseDocument *doc = [super makeUntitledDocumentOfType:typeName error:outError];
    
    NSManagedObjectContext *moc = [doc managedObjectContext];
    [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:moc];
    [moc processPendingChanges];
    [[moc undoManager] removeAllActions];
    [doc updateChangeCount:NSChangeCleared];
    return doc;
}




@end

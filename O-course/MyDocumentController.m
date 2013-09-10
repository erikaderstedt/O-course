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
#import "OverprintObject.h"

@implementation MyDocumentController

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
    if ([[url pathExtension] isEqualToString:@"ocd"]) {
        NSString *path = [url path];
        NSError *e = nil;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            e = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"File not found.", nil)}];
        } else if (!supported_version([path cStringUsingEncoding:NSUTF8StringEncoding])) {
            e = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid OCAD version. Only versions 9 and 10 are supported.", nil)}];
        }
        
        if (e != nil) {
            completionHandler(nil, NO, e);
        } else {
            ASOcourseDocument *doc = [self makeUntitledDocumentOfType:[self defaultType] error:nil];
            [self addDocument:doc];
            
            if (displayDocument) {
                [doc makeWindowControllers];
                [doc showWindows];
                [doc setMapURL:url];
            } else {
                [doc setMapURL:url];
            }

            completionHandler(doc, NO, nil);
        }
        return;
    }
    [super openDocumentWithContentsOfURL:url display:YES completionHandler:completionHandler];
}

- (id)makeUntitledDocumentOfType:(NSString *)typeName error:(NSError **)outError {
    ASOcourseDocument *doc = [super makeUntitledDocumentOfType:typeName error:outError];
    
    NSManagedObjectContext *moc = [doc managedObjectContext];
    NSManagedObject *project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:moc];
    [project setValue:@"Vargarna" forKey:@"event"];
    [project setValue:[NSDate date] forKey:@"date"];
    NSManagedObject *layout = [NSEntityDescription insertNewObjectForEntityForName:@"Layout" inManagedObjectContext:moc];
    [layout setValue:project forKey:@"project"];
    [layout setValue:NSLocalizedString(@"layout.name.default", nil) forKey:@"name"];
    [layout setValue:@(YES) forKey:@"default"];

    [moc processPendingChanges];
    [[moc undoManager] removeAllActions];

    return doc;
}

+ (NSOpenPanel *)openPanelForBackgroundMap {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowedFileTypes:@[@"pdf",@"ocd", @"tiff",@"jpg",@"jpeg",@"gif",@"tif"]];
    [op setAllowsOtherFileTypes:YES];
    [op setAllowsMultipleSelection:NO];
    [op setTitle:NSLocalizedString(@"Select a background map", nil)];
    [op setMessage:NSLocalizedString(@"Please select a background map to use, in either OCAD 8-11 format or a bitmap file.", nil)];
    [op setPrompt:NSLocalizedString(@"Select", nil)];
    
    return op;
}

- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError {
    NSOpenPanel *op = [[self class] openPanelForBackgroundMap];
    
    if ([op runModal] == NSFileHandlingPanelOKButton) {
        ASOcourseDocument *doc = [self makeUntitledDocumentOfType:[self defaultType] error:outError];
        [self addDocument:doc];

        if (displayDocument) {
            [doc makeWindowControllers];
            [doc showWindows];
            [doc setMapURL:[op URL]];
        } else {
            [doc setMapURL:[op URL]];            
        }
        return doc;
    }

    if (outError != nil) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    }
    return nil;
}


@end

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
#import "CourseObject.h"

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
    NSManagedObject *project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:moc];
    [project setValue:@"Skinklopp" forKey:@"event"];
    NSManagedObject *course  = [NSEntityDescription insertNewObjectForEntityForName:@"Course" inManagedObjectContext:moc];
    [course setValue:@"Testbana" forKey:@"name"];
    [course setValue:project forKey:@"project"];
    NSMutableOrderedSet *mos = [course mutableOrderedSetValueForKey:@"controls"];
    
    CourseObject *obj;
    obj = [NSEntityDescription insertNewObjectForEntityForName:@"CourseObject" inManagedObjectContext:moc];
    obj.controlDescriptionItemType = kASStart;
    [mos addObject:obj];
    
    obj = [NSEntityDescription insertNewObjectForEntityForName:@"Control" inManagedObjectContext:moc];
    obj.controlDescriptionItemType = kASRegularControl;
    obj.controlCode = [NSNumber numberWithInt:31];
    [mos addObject:obj];
    
    obj = [NSEntityDescription insertNewObjectForEntityForName:@"Control" inManagedObjectContext:moc];
    obj.controlDescriptionItemType = kASRegularControl;
    obj.controlCode = [NSNumber numberWithInt:32];
    [mos addObject:obj];    
    
    obj = [NSEntityDescription insertNewObjectForEntityForName:@"Control" inManagedObjectContext:moc];
    obj.controlDescriptionItemType = kASRegularControl;
    obj.controlCode = [NSNumber numberWithInt:33];
    [mos addObject:obj];    
    
    obj = [NSEntityDescription insertNewObjectForEntityForName:@"Control" inManagedObjectContext:moc];
    obj.controlDescriptionItemType = kASRegularControl;
    obj.controlCode = [NSNumber numberWithInt:34];
    [mos addObject:obj];    
    
    
    obj = [NSEntityDescription insertNewObjectForEntityForName:@"CourseObject" inManagedObjectContext:moc];
    obj.controlDescriptionItemType = kASPartlyTapedRouteToFinish;
    obj.distance = [NSNumber numberWithFloat:0.23];
    [mos addObject:obj];
    
    
    [moc processPendingChanges];
    [[moc undoManager] removeAllActions];
    [doc updateChangeCount:NSChangeCleared];
    return doc;
}




@end

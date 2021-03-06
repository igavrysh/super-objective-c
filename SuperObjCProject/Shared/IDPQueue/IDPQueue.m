//
//  IDPQueue.m
//  SuperObjCProject
//
//  Created by Ievgen on 6/9/16.
//  Copyright © 2016 1mlndollarsasset. All rights reserved.
//

#import "IDPQueue.h"

#import "NSObject+IDPObject.h"

@interface IDPQueue ()
@property (nonatomic, retain) NSMutableArray  *objects;

@end

@implementation IDPQueue

@dynamic count;

#pragma mark -
#pragma mark Initializtions and Deallocations

- (void)dealloc {
    self.objects = nil;
    
    [super dealloc];
}

- (id)init {
    self = [super init];
    self.objects = [NSMutableArray object];
    
    return self;
}

#pragma mark -
#pragma mark Accessors Methods

- (NSUInteger)count {
    return [self.objects count];
}

#pragma mark -
#pragma mark Public Methods

- (void)enqueue:(id)object {
    if (!object) {
        return;
    }
    
    [self.objects addObject:object];
}

- (id)dequeue {
    if (self.count == 0) {
        return nil;
    }
    
    NSMutableArray *objects = self.objects;
    id object = [objects firstObject];
    [objects removeObject:object];
    
    return object;
}

@end

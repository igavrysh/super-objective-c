//
//  IDPWorkerDispatcher.m
//  SuperObjCProject
//
//  Created by Ievgen on 7/11/16.
//  Copyright © 2016 1mlndollarsasset. All rights reserved.
//

#import "IDPWorkerDispatcher.h"

#import "IDPThreadSafeQueue.h"

#import "NSObject+IDPObject.h"
#import "NSArray+IDPArrayEnumerator.h"
#import "IDPWorker.h"
#import "IDPGCDQueue.h"

#import "IDPDirector.h"
#import "IDPAccountant.h"
#import "IDPCarwasher.h"

@interface IDPWorkerDispatcher()
@property (nonatomic, retain)                           IDPThreadSafeQueue  *objectsQueue;
@property (nonatomic, retain)                           NSArray             *workers;
@property (nonatomic, readonly, getter=isQueueEmpty)    BOOL                queueEmpty;

- (void)cleanUpWorkersObservers;

- (IDPWorker *)freeWorker;
- (void)assignWorkToWorker:(IDPWorker *)worker;

- (void)workerInterimProcessing:(IDPWorker *)worker;

@end

@implementation IDPWorkerDispatcher

@dynamic queueEmpty;

#pragma mark -
#pragma mark Class Methods

+ (instancetype)dispatcherWithWorkers:(NSArray *)workers {    
    return [[[self alloc] initWithWorkers:workers] autorelease];
}

#pragma mark -
#pragma mark Accessors Methods

- (BOOL)isQueueEmpty {
    return self.objectsQueue.count == 0;
}

#pragma mark -
#pragma mark Initializations and Deallocations

- (void)dealloc {
    self.objectsQueue = nil;
    
    [self cleanUpWorkersObservers];
    self.workers = nil;
    
    [super dealloc];
}

- (instancetype)initWithWorkers:(NSArray *)workers {
    self = [super init];
    if (self) {
        self.objectsQueue = [IDPThreadSafeQueue object];
        self.workers = [[workers copy] autorelease];
        
        [self.workers performBlockWithEachObject:^(IDPWorker *worker) {
            [worker addObserver:self];
        }];
    }
    
    return self;
}

#pragma mark -
#pragma mark Public Methods

- (void)processObject:(id<IDPCashOwner>)object {
    [self.objectsQueue enqueue:object];
    
    [self assignWorkToWorker:[self freeWorker]];
}

- (BOOL)isWorkerInProcessors:(IDPWorker *)worker {
    return [self.workers containsObject:worker];
}

#pragma mark -
#pragma mark Private Methods

- (void)cleanUpWorkersObservers {
    [self.workers performBlockWithEachObject:^(IDPWorker *worker) {
        [worker removeObserver:self];
    }];
}

- (IDPWorker *)freeWorker {
    NSArray *freeWorkers = [self.workers filteredArrayUsingBlock:^(IDPWorker *worker) {
        return (BOOL)(IDPWorkerFree == worker.state);
    }];
    
    return [freeWorkers firstObject];
}

- (void)assignWorkToWorker:(IDPWorker *)worker {
    if (!worker || IDPWorkerFree != worker.state) {
        return;
    }
    
    worker.state = IDPWorkerBusy;
    
    id object = [self.objectsQueue dequeue];
    
    if (!object) {
        worker.state = IDPWorkerFree;
        return;
    }
    
    [worker log:@"was assigned" withObject:object];
    
    [worker processObject:object];
}

- (void)workerInterimProcessing:(IDPWorker *)worker {
    if (IDPWorkerFree == worker.state
        && ![self isQueueEmpty])
    {
        [self assignWorkToWorker:worker];
    }
}

#pragma mark -
#pragma mark IDPWorkerObserver

- (void)workerDidBecomeFree:(IDPWorker *)worker {
    if ([self isWorkerInProcessors:worker]) {
        IDPAsyncPerformInBackgroundQueue(^{
            [self workerInterimProcessing:worker];
        });
    }
}

- (void)workerDidBecomePending:(IDPWorker *)worker {
    if (![self isWorkerInProcessors:worker]) {
        [self processObject:worker];
    }
}

@end

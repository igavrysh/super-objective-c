//
//  IDPWorker.m
//  SuperObjCProject
//
//  Created by Student 104 on 6/1/16.
//  Copyright (c) 2016 1mlndollarsasset. All rights reserved.
//

#import "IDPWorker.h"

#import "IDPRandom.h"
#import "IDPThreadSafeQueue.h"

#import "NSObject+IDPObject.h"

static float const kIDPWorkerMaxSalary          = 100;
static float const kIDPWorkerMaxCapital         = 100000;

static NSUInteger const kIDPWorkerMaxExperience = 10;

@interface IDPWorker ()
@property (nonatomic, assign) float cash;
@property (nonatomic, retain) IDPThreadSafeQueue *objectsQueue;

- (void)finishProcessingObjectOnMainThread:(id<IDPCashOwner>)object;

@end

@implementation IDPWorker

#pragma mark -
#pragma mark Initializtions and Deallocations

- (void)dealloc {
    self.objectsQueue = nil;
    
    [super dealloc];
}

- (id)init {
    self = [super init];
    
    self.salary = IDPRandomFloatWithMinAndMaxValue(0, kIDPWorkerMaxSalary);
    self.capital = IDPRandomFloatWithMinAndMaxValue(0, kIDPWorkerMaxCapital);
    self.experience = IDPRandomUIntWithMaxValue(kIDPWorkerMaxExperience);
    
    self.objectsQueue = [IDPThreadSafeQueue object];
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setState:(NSUInteger)state {
    @synchronized(self) {
        if (state == IDPWorkerFree && [self.objectsQueue count] > 0) {
            [super setState:IDPWorkerBusy];
            
            [self performSelectorOnMainThread:@selector(finishProcessingObjectOnMainThread:)
                                   withObject:nil
                                waitUntilDone:NO];
        } else {
            [super setState:state];
        }
    }
}

#pragma mark -
#pragma mark Public Methods

- (void)processObject:(id<IDPCashOwner>)object {
    @synchronized(self) {
        [self performSelectorInBackground:@selector(performWorkInBackgroundWithObject:)
                               withObject:object];
    }
}

- (void)performWorkInBackgroundWithObject:(id<IDPCashOwner>)object {
    [self performWorkWithObject:object];
    
    [self performSelectorOnMainThread:@selector(finishProcessingObjectOnMainThread:)
                           withObject:object
                        waitUntilDone:NO];
}

- (void)finishProcessingObjectOnMainThread:(id<IDPCashOwner>)object {
    @synchronized(object) {
        [self finishProcessingObject:object];
    }
    
    @synchronized(self) {
        [self finishProcessing];
    }
}

- (void)performWorkWithObject:(IDPWorker *)worker {
    [self doesNotRecognizeSelector:_cmd];
}

- (void)finishProcessingObject:(IDPWorker *)worker {
    if ([worker isKindOfClass:[IDPWorker class]]) {
       worker.state = IDPWorkerFree;
    }
}

- (void)finishProcessing {
    self.state = IDPWorkerPending;
}

- (void)receiveCashFromCashOwner:(id<IDPCashOwner>)object {
    [self receiveCash:[object giveAllCash]];
}

- (void)receiveCash:(float)cash {
    @synchronized(self) {
        self.cash += cash;
    }
}

- (float)giveAllCash {
    @synchronized(self) {
        return [self giveCash:self.cash];
    }
}

- (float)giveCash:(float)cash {
    @synchronized(self) {
        float cashOwned = self.cash;
        float cashToGive = cashOwned > cash ? cash : cashOwned;
        self.cash = cashOwned - cashToGive;
        
        return cashToGive;
    }
}

- (void)log:(NSString *)info {
    NSLog(@"%@ :%@ %@", [self class], self, info);
}

- (void)log:(NSString *)info withObject:(id)object {
    NSLog(@"%@ :%@ %@ %@: %@ ", [self class], self, info, [object class], object);
}

#pragma mark -
#pragma mark IDPObservableObject

- (SEL)selectorForState:(NSUInteger)state {
    switch (state) {
        case IDPWorkerBusy:
            return @selector(workerDidBecomeBusy:);
            
        case IDPWorkerFree:
            return @selector(workerDidBecomeFree:);
            
        case IDPWorkerPending:
            return @selector(workerDidBecomePending:);
            
        default:
            return [super selectorForState:state];
    }
}

#pragma mark -
#pragma mark IDPWorkerObserver

- (void)workerDidBecomeFree:(IDPWorker *)worker {
    [worker log:@"did become free"];
}

- (void)workerDidBecomeBusy:(IDPWorker *)worker {
    [worker log:@"did become busy"];
}

- (void)workerDidBecomePending:(IDPWorker *)worker {
    [self performSelectorInBackground:@selector(processObject:) withObject:worker];
    
    [worker log:@"did become pending"];
}

@end

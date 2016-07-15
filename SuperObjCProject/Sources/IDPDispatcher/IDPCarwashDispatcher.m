//
//  IDPCarwashDispatcher.m
//  SuperObjCProject
//
//  Created by Ievgen on 7/13/16.
//  Copyright © 2016 1mlndollarsasset. All rights reserved.
//

#import "IDPCarwashDispatcher.h"

#import "IDPCarwash.h"
#import "IDPCar.h"

#import "NSObject+IDPObject.h"
#import "NSArray+IDPArrayEnumerator.h"

static const NSUInteger kIDPCarwashDispatcherCarsCount  = 25;
static const NSUInteger kIDPCarsInBatch                 = 10;
static const NSTimeInterval kIDPCarsDeliveryWaitTime    = 0.5;

@interface IDPCarwashDispatcher ()
@property (nonatomic, retain)   IDPCarwash      *carwash;
@property (nonatomic, retain)   NSMutableArray  *cars;
@property (nonatomic, readonly) NSUInteger      carsDelivered;
@property (nonatomic, assign)   NSTimer         *timer;
@property (nonatomic, assign, getter=isRunning) BOOL    running;

- (void)start;
- (void)stop;
- (void)onTimer:(NSTimer *)timer;

- (void)deliverCar;
- (NSArray *)dirtyCars;

@end

@implementation IDPCarwashDispatcher

@dynamic carsDelivered;

#pragma mark -
#pragma mark Class methods

+ (instancetype)dispatcherWithCarwash:(IDPCarwash *)carwash {
    return [[[self alloc] initWithCarwash:carwash] autorelease];
}

#pragma mark - 
#pragma mark Initializations and Deallocations

- (void)dealloc {
    self.carwash = nil;
    self.cars = nil;
    
    [self stop];
    
    [super dealloc];
}

- (instancetype)initWithCarwash:(IDPCarwash *)carwash {
    self = [super init];
    
    self.carwash = carwash;
    self.cars = [NSMutableArray object];
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setTimer:(NSTimer *)timer {
    if (_timer == timer) {
        return;
    }
    
    if (_timer && [_timer isValid]) {
        self.running = NO;
        [_timer invalidate];
    }
    
    _timer = timer;
}

- (NSUInteger)carsDelivered {
    return [self.cars count];
}

#pragma mark -
#pragma mark Public Methods

- (void)start {
    self.running = YES;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:kIDPCarsDeliveryWaitTime
                                                  target:self
                                                selector:@selector(onTimer:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stop {
    self.timer = nil;
}

#pragma mark -
#pragma mark Private Methods

- (void)onTimer:(NSTimer *)timer {
    [self deliverCar];
}

- (void)deliverCar {
    NSArray *cars = [self dirtyCars];
    if (cars) {
        [cars performBlockWithEachObject:^(IDPCar *car) {
            [self.carwash performSelectorInBackground:@selector(processCar:) withObject:car];
            [self.cars addObject:car];
        }];
    } else {
        [self stop];
    }
}

- (NSArray *)dirtyCars {
    NSUInteger count = MIN(kIDPCarsInBatch, kIDPCarwashDispatcherCarsCount - self.carsDelivered);
    
    return [NSArray objectsWithCount:count block:^id { return [IDPCar object]; }];
}

@end
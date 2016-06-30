//
//  IDPCarwashTest.m
//  SuperObjCProject
//
//  Created by Ievgen on 6/4/16.
//  Copyright © 2016 1mlndollarsasset. All rights reserved.
//

#import "IDPCarwashTest.h"

#import "IDPCarwash.h"
#import "IDPCar.h"

#import "NSObject+IDPObject.h"
#import "NSArray+IDPArrayEnumerator.h"

static const NSUInteger kIDPCarwashTestCarsCount = 25;

@interface IDPCarwashTest ()
@property (nonatomic, retain) IDPCarwash *carwash;

@end

@implementation IDPCarwashTest

#pragma mark -
#pragma mark Public Methods

- (void)execute {
    self.carwash = [IDPCarwash new];
    
    NSArray *cars = [NSArray objectsWithCount:kIDPCarwashTestCarsCount block:^id{
        return [IDPCar object];
    }];
    
    for (IDPCar *car in cars) {
        NSLog(@"->Car is being processed");
        
        [self.carwash performSelectorInBackground:@selector(processCar:) withObject:car];
    
        NSLog(@"Car was processed->");
    }
    
    self.carwash = nil;
}

@end

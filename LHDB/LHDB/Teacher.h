//
//  Teacher.h
//  LHDB
//
//  Created by 3wchina01 on 16/5/30.
//  Copyright © 2016年 3wchina01. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Teacher : NSObject

@property (nonatomic,strong) NSString* name;

@property (nonatomic,assign) NSInteger age;

@property (nonatomic,strong) NSDate* updateDate;

@property (nonatomic,strong) NSData* data;

@property (nonatomic,assign) float weight;

@end

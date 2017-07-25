//
//  Teacher.m
//  LHDB
//
//  Created by 3wchina01 on 16/5/30.
//  Copyright © 2016年 3wchina01. All rights reserved.
//

#import "Teacher.h"

@implementation Teacher

-(NSString*)description{
    return [NSString stringWithFormat:@"name:%@,age:%d,weight:%f",self.name,self.age,self.weight];
}
@end

//
//  ViewController.m
//  LHDB
//
//  Created by 3wchina01 on 16/5/30.
//  Copyright © 2016年 3wchina01. All rights reserved.
//

#import "ViewController.h"
#import "LHDB.h"
#import "Teacher.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /*
     * LHDB默认会给一个数据库路径   在NSObject+LHDB.m的宏里，如果你需要更换数据库路径可以使用   [LHDBPath instanceManagerWith:@"your dbPath"];
     */
    //建立一个Teacher表
    [self createTeacherTable];
   
    
    //直接将model插入数据库
    Teacher* teacher = [[Teacher alloc] init];
    teacher.name = @"tom";
    teacher.age = 18;
    teacher.data = [@"my name is tom" dataUsingEncoding:NSUTF8StringEncoding];
    teacher.updateDate = [NSDate date];
    [self insertDataWithModel:teacher];
    
    //将字典插入Teacher表
    NSDictionary* dic = @{@"name":@"jan",@"age":@18,@"data":[@"my name is jan" dataUsingEncoding:NSUTF8StringEncoding],@"updateDate":[NSDate date]};
    [self insertDataWithDic:dic];
    
    //查询所有数据
    LHPredicate* predicate = [LHPredicate predicateWithFormat:@"name = '%@'",@"tom"];

    NSArray* result = [Teacher selectWithPredicate:predicate];
    NSLog(@"result1 = %@",result);
    
    //数据更新 将tom的年龄修改成20岁 同时更新updateDate
    Teacher* teacher1 = [[Teacher alloc] init];
    teacher1.name = @"tom";
    teacher1.age = 20;
    teacher1.data = [@"my name is tom" dataUsingEncoding:NSUTF8StringEncoding];
    teacher1.updateDate = [NSDate date];
    //确定  表中name = tom 的数据  注意：字符串等 需要加上‘’  基本数据不需要
    predicate = [LHPredicate predicateWithFormat:@"name = '%@'",@"tom"];
    [self updateDataWithModel:teacher1 predicate:predicate];
    
    
    //将jan的名字改成marry 同时更新updateDate
    NSDictionary* dic1 = @{@"name":@"marry",@"updateDate":[NSDate date]};
    LHPredicate* predicate1 = [LHPredicate predicateWithFormat:@"name = '%@'",@"jan"];
    [self updateDataWithDic:dic1 predicate:predicate1];
    
    //再次查询所有数据
    NSLog(@"result2 = %@",[self selectDataWithPredicate:nil]);
    
    //删除数据 将name = tom 的数据从表中删除
    LHPredicate* deletePredicate = [LHPredicate predicateWithFormat:@"name = '%@'",@"tom"];
    [self deleteDataWithPredicate:deletePredicate];
    
    Teacher* teacher2 = [[Teacher alloc] init];
    teacher2.name = @"jianh";
    teacher2.age = 18;
    teacher2.data = [@"my name is jianh" dataUsingEncoding:NSUTF8StringEncoding];
    teacher2.updateDate = [NSDate date];
    teacher2.weight = 50;
    [self insertDataWithModel:teacher2];
    
    NSLog(@"result3 = %@",[self selectDataWithPredicate:nil]);
    
//    //删除所有数据
//    [self deleteDataWithPredicate:nil];
//    NSLog(@"result4 = %@",[self selectDataWithPredicate:nil]);
}

#pragma mark- 建表
- (void)createTeacherTable
{
    [Teacher createTable];
}

#pragma mark- insert
- (void)insertDataWithModel:(Teacher*)teacher
{
    [teacher save];
}

- (void)insertDataWithDic:(NSDictionary*)dic
{
    [Teacher saveWithDic:dic];
}

#pragma mark- update
- (void)updateDataWithModel:(Teacher*)teacher predicate:(LHPredicate*)predicate
{
    [teacher updateWithPredicate:predicate];
}

- (void)updateDataWithDic:(NSDictionary*)dic predicate:(LHPredicate*)predicate
{
    [Teacher updateWithDic:dic predicate:predicate];
}

#pragma mark- delete
- (void)deleteDataWithPredicate:(LHPredicate*)predicate
{
    [Teacher deleteWithPredicate:predicate];
}

#pragma mark- select
- (NSArray*)selectDataWithPredicate:(LHPredicate*)predicate
{
    return [Teacher selectWithPredicate:predicate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  NSObject+LHModelExecute.h
//  LHDBDemo
//
//  Created by 3wchina01 on 16/2/15.
//  Copyright © 2016年 李浩. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^executeError)(NSError* error);

@class LHSqlite,LHPredicate;
@interface NSObject (LHDB)


/**
 * @dis 建表
 */
+ (void)createTable;

/**
 * @dis  表增加字段
 * @para name  需要增加的字段名称
 */
+ (void)addColum:(NSString*)name;

/**
 * @dis 插入操作
 */
- (void)save;

/**
 * @dis  插入
 * @para dic 需要插入的字典  key必须和类的属性名称相同
 */
+ (void)saveWithDic:(NSDictionary*)dic;
/*
 * @dis 更新操作
 * @para predicate 谓词   表示需要更新的范围 类似NSPredicate
 */
- (void)updateWithPredicate:(LHPredicate*)predicate;

/**
 * @dis 更新操作
 * @para dic 更新数据库所需要的数据源 key必须和类的属性名称相同
 * @para predicate 谓词   表示需要更新的范围 类似NSPredicate
 */

+ (void)updateWithDic:(NSDictionary*)dic predicate:(LHPredicate*)predicate;

/**
 * @dis 删除操作
 * @para predicate 谓词   表示需要更新的范围 类似NSPredicate
 */

+ (void)deleteWithPredicate:(LHPredicate*)predicate;

/**
 * @dis 查询操作
 * @para predicate 希望查询的范围  并且包括排序等规则
 * @return  一个包含所有查询数据的数组  数组中包含的是查询的对象
 */
+ (NSArray*)selectWithPredicate:(LHPredicate*)predicate;

@end

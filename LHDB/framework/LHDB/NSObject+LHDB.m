//
//  NSObject+LHModelExecute.m
//  LHDBDemo
//
//  Created by 3wchina01 on 16/2/15.
//  Copyright © 2016年 李浩. All rights reserved.
//

#import "NSObject+LHDB.h"
#import "LHPredicate.h"
#import <objc/runtime.h>
#import "LHDBPath.h"
#import "LHSqlite.h"
#import "NSObject+LHModel.h"
#import "LHModelStateMent.h"


#define run_in_queue(...) dispatch_async([self executeQueue], ^{\
__VA_ARGS__; \
})

#define DatabasePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]stringByAppendingPathComponent:@"data.sqlite"]

static NSString* const DatabaseFilePath = @"DatabaseFilePath";
static NSString* const DataBaseExecute = @"DataBaseExecute";
static NSString* const DataBaseQueue = @"DataBaseQueue";

static LHSqlite* sqlite;

@implementation NSObject (LHDB)

- (dispatch_queue_t)executeQueue
{
    static dispatch_queue_t executeQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        executeQueue = dispatch_queue_create("com.sancai.lhdb", DISPATCH_QUEUE_SERIAL);
    });
    return executeQueue;
}

+ (dispatch_queue_t)executeQueue
{
    return [[self new] executeQueue];
}

- (NSString*)dbPath
{
    if ([LHDBPath instanceManagerWith:nil].dbPath.length == 0) {
        return DatabasePath;
    }else
        return [LHDBPath instanceManagerWith:nil].dbPath;
}

+ (NSString*)dbPath
{
    if ([LHDBPath instanceManagerWith:nil].dbPath.length == 0) {
        return DatabasePath;
    }else
        return [LHDBPath instanceManagerWith:nil].dbPath;
}

- (void)setFilePath:(NSString *)filePath
{
    objc_setAssociatedObject(self, &DatabaseFilePath, filePath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString*)filePath
{
    return objc_getAssociatedObject(self, &DatabaseFilePath);
}

+ (void)createTable
{
    LHSqlite* sqlite = [LHSqlite shareInstance];
    sqlite.sqlPath = [self dbPath];
    [sqlite executeUpdateWithSqlstring:createTableString(self) parameter:nil];
}

+ (void)addColum:(NSString*)name
{
    LHSqlite* sqlite = [LHSqlite shareInstance];
    sqlite.sqlPath = [self dbPath];
    [sqlite executeUpdateWithSqlstring:addColum(self, name) parameter:nil];
}

- (void)save
{
    LHSqlite* sqlite = [LHSqlite shareInstance];
    sqlite.sqlPath = [self dbPath];
    [sqlite executeUpdateWithSqlstring:insertString(self) parameter:[self lh_ModelToDictionary]];
}

+ (void)saveWithDic:(NSDictionary*)dic
{
    LHSqlite* sqlite = [LHSqlite shareInstance];
    sqlite.sqlPath = [self dbPath];
    [sqlite executeUpdateWithSqlstring:insertStringWithDic(self, dic) parameter:dic];
}

//
- (void)updateWithPredicate:(LHPredicate*)predicate
{
    LHSqlite* sqlite = [LHSqlite shareInstance];
    sqlite.sqlPath = [self dbPath];
    [sqlite executeUpdateWithSqlstring:updateString(self, predicate) parameter:[self lh_ModelToDictionary]];
}


//静态方法实际使用时，可以只修改某些字段的值，这个跟实例对象方法完全覆盖所有字段的方式不同
+ (void)updateWithDic:(NSDictionary*)dic predicate:(LHPredicate*)predicate
{
    LHSqlite* sqlite = [LHSqlite shareInstance];
    sqlite.sqlPath = [self dbPath];
    [sqlite executeUpdateWithSqlstring:updateStringWithDic(self, predicate, dic)  parameter:dic];
}

//删除某条记录不需要对象方法
+ (void)deleteWithPredicate:(LHPredicate*)predicate
{
    LHSqlite* sqlite = [LHSqlite shareInstance];
    sqlite.sqlPath = [self dbPath];
    [sqlite executeUpdateWithSqlstring:deleteString(self, predicate) parameter:nil];
}

//查询记录不需要对象方法
+ (NSArray*)selectWithPredicate:(LHPredicate*)predicate
{
    LHSqlite* sqlite = [LHSqlite shareInstance];
    sqlite.sqlPath = [self dbPath];
    NSArray* array = [sqlite executeQueryWithSqlstring:selectString(self, predicate)];
    NSMutableArray* resultArray = [NSMutableArray array];
    for (NSDictionary* dic in array) {
        [resultArray addObject:[self lh_ModelWithDictionary:dic]];
    }
    return resultArray;
}

@end

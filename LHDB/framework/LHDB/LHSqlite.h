//
//  LHSqlite.h
//  LHDBDemo
//
//  Created by 3wchina01 on 16/3/22.
//  Copyright © 2016年 李浩. All rights reserved.
//

#import <Foundation/Foundation.h>

//数据库底层处理类,真正执行指令的地方
@interface LHSqlite : NSObject

@property (nonatomic,strong) NSString* sqlPath;

@property (nonatomic,strong) NSDateFormatter* dateFormatter;

- (instancetype)initWithPath:(NSString*)dbPath;

+ (instancetype)sqliteWithPath:(NSString*)dbPath;

+ (instancetype)shareInstance;

- (void)executeUpdateWithSqlstring:(NSString *)sqlString parameter:(NSDictionary*)parameter;

- (NSArray*)executeQueryWithSqlstring:(NSString*)sqlString;

- (void)clearStmtCache;

@end

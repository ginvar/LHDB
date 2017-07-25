//
//  LHSqlite.m
//  LHDBDemo
//
//  Created by 3wchina01 on 16/3/22.
//  Copyright © 2016年 李浩. All rights reserved.
//

#import "LHSqlite.h"
#import <sqlite3.h>
#import <libkern/OSAtomic.h>
#import <UIKit/UIKit.h>
#import "NSObject+LHModel.h"

#define Lock OSSpinLockLock(&(self->_lock))
#define UnLock OSSpinLockUnlock(&(self->_lock))
#define TryLock OSSpinLockTry(&(self->_lock))

#ifdef DEBUG

#define LHSqliteLog(...) NSLog(__VA_ARGS__)

#else

#define LHSqliteLog(...)
#endif

@implementation LHSqlite{
    @package
    OSSpinLock _lock;
    sqlite3* _db;
    CFMutableDictionaryRef _stmtCache;
}

static NSError* errorForDataBase(NSString* sqlString,sqlite3* db)
{
    NSError* error = [NSError errorWithDomain:[NSString stringWithUTF8String:sqlite3_errmsg(db)] code:sqlite3_errcode(db) userInfo:@{@"sqlString":sqlString}];
    return error;
}

static NSObject* dataWithDataType(int type,sqlite3_stmt * statement,int index)
{
    if (type == SQLITE_INTEGER) {
        int value = sqlite3_column_int(statement, index);
        return [NSNumber numberWithInt:value];
    }else if (type == SQLITE_FLOAT) {
        float value = sqlite3_column_double(statement, index);
        return [NSNumber numberWithFloat:value];
    }else if (type == SQLITE_BLOB) {
        const void *value = sqlite3_column_blob(statement, index);
        int bytes = sqlite3_column_bytes(statement, index);
        return [NSData dataWithBytes:value length:bytes];
    }else if (type == SQLITE_NULL) {
        return nil;
    }else if (type == SQLITE_TEXT) {
        return [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, index)];
    }else {
        return nil;
    }
}

static inline void LHSqliteStmtCacheApplierFunction(const void *key, const void *value, void *context)
{
    sqlite3_stmt* stmt = (sqlite3_stmt*)value;
    if (stmt) {
        sqlite3_finalize(stmt);
        stmt = NULL;
    }
}

- (instancetype)initWithPath:(NSString*)dbPath
{
    self = [super init];
    if (self) {
        _sqlPath = dbPath;
        _lock = OS_SPINLOCK_INIT;
        CFDictionaryValueCallBacks valuesCallback = {0};
        _stmtCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFCopyStringDictionaryKeyCallBacks, &valuesCallback);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearStmtCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearStmtCache) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

+ (instancetype)sqliteWithPath:(NSString*)dbPath
{
    LHSqlite* sqlite = [[LHSqlite alloc] initWithPath:dbPath];
    return sqlite;
}

+ (instancetype)shareInstance
{
    static LHSqlite* sqlite = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sqlite = [LHSqlite sqliteWithPath:nil];
    });
    return sqlite;
}

- (sqlite3_stmt*)stmtWithCacheKey:(NSString*)sqlString
{
    //_stmtCache是一个CFMutableDictionaryRef类型，缓存
    sqlite3_stmt* stmt = (sqlite3_stmt*)CFDictionaryGetValue(_stmtCache, (__bridge const void *)([[self.sqlPath lastPathComponent] stringByAppendingString:sqlString]));
    if (stmt == 0x00) {
        if (sqlite3_prepare_v2(_db, sqlString.UTF8String, -1, &stmt, nil) == SQLITE_OK) {
            //缓存stmt
            CFDictionarySetValue(_stmtCache, (__bridge const void *)([[self.sqlPath lastPathComponent] stringByAppendingString:sqlString]), stmt);
            return stmt;
        }else {
            LHSqliteLog(@"error = %@",errorForDataBase(sqlString, _db));
            return nil;
        }
    }else
        sqlite3_reset(stmt);
    return stmt;
}

- (BOOL)openDB
{
    if (sqlite3_open([self.sqlPath UTF8String], &_db) == SQLITE_OK) {
        return YES;
    }else{
        sqlite3_close(_db);
        return NO;
    }
}

- (void)executeUpdateWithSqlstring:(NSString *)sqlString parameter:(NSDictionary*)parameter
{
    Lock;
    if ([self openDB]) {
        sqlite3_stmt* stmt = [self stmtWithCacheKey:sqlString];
        if (stmt) {
            for (int i=0; i<parameter.allKeys.count; i++) {
                [self bindObject:parameter[parameter.allKeys[i]] toColumn:i+1 inStatement:stmt];
            }
            if (sqlite3_step(stmt) != SQLITE_DONE) {
                LHSqliteLog(@"error = %@",errorForDataBase(sqlString, _db));
            }
        }
    }else {
        LHSqliteLog(@"打开数据库失败");
    }
    sqlite3_close(_db);
    UnLock;
}

- (NSArray*)executeQueryWithSqlstring:(NSString*)sqlString
{
    Lock;
    NSArray* resultArray = 0x00;
    if ([self openDB]) {
        sqlite3_stmt* stmt = [self stmtWithCacheKey:sqlString];
        if (stmt) {
            NSMutableArray* dataSource = [NSMutableArray array];
            int count = sqlite3_column_count(stmt);
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                NSMutableDictionary* dataDic = [NSMutableDictionary dictionary];
                for (int i=0; i<count; i++) {
                    int type = sqlite3_column_type(stmt, i);
                    NSString* propertyName = [NSString stringWithUTF8String:sqlite3_column_name(stmt, i)];
                    NSObject* value = dataWithDataType(type, stmt, i);
                    [dataDic setValue:value forKey:propertyName];
                }
                [dataSource addObject:dataDic];
            }
            resultArray = dataSource;
        }
    }
    sqlite3_close(_db);
    UnLock;
    return resultArray;
}

- (void)clearStmtCache
{
    CFDictionaryApplyFunction(_stmtCache, LHSqliteStmtCacheApplierFunction, NULL);
    CFDictionaryRemoveAllValues(_stmtCache);
}

- (void)bindObject:(id)obj toColumn:(int)idx inStatement:(sqlite3_stmt*)pStmt {
    
    if ((!obj) || ((NSNull *)obj == [NSNull null])) {
        sqlite3_bind_null(pStmt, idx);
    }
    
    else if ([obj isKindOfClass:[NSData class]]) {
        const void *bytes = [obj bytes];
        if (!bytes) {

            bytes = "";
        }
        sqlite3_bind_blob(pStmt, idx, bytes, (int)[obj length], SQLITE_STATIC);
    }
    else if ([obj isKindOfClass:[NSDate class]]) {
        if (self.dateFormatter)
            sqlite3_bind_text(pStmt, idx, [[self.dateFormatter stringFromDate:obj] UTF8String], -1, SQLITE_STATIC);
        else
            sqlite3_bind_text(pStmt, idx, [[self stringFromDate:obj] UTF8String],-1,SQLITE_STATIC);
    }
    else if ([obj isKindOfClass:[NSNumber class]]) {
        
        if (strcmp([obj objCType], @encode(char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj charValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedCharValue]);
        }
        else if (strcmp([obj objCType], @encode(short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj shortValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedShortValue]);
        }
        else if (strcmp([obj objCType], @encode(int)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj intValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned int)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedIntValue]);
        }
        else if (strcmp([obj objCType], @encode(long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongValue]);
        }
        else if (strcmp([obj objCType], @encode(long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longLongValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongLongValue]);
        }
        else if (strcmp([obj objCType], @encode(float)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj floatValue]);
        }
        else if (strcmp([obj objCType], @encode(double)) == 0) {
            NSLog(@"%f",[obj doubleValue]);
            sqlite3_bind_double(pStmt, idx, [obj doubleValue]);
        }
        else if (strcmp([obj objCType], @encode(BOOL)) == 0) {
            sqlite3_bind_int(pStmt, idx, ([obj boolValue] ? 1 : 0));
        }
        else {
            sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
        }
    }
    else if ([obj isKindOfClass:[NSArray class]]||[obj isKindOfClass:[NSDictionary class]]) {
        @try {
            NSData* data = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:nil];
            NSString* jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            sqlite3_bind_text(pStmt, idx, [[jsonStr description] UTF8String], -1, SQLITE_STATIC);
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
        
    }else if ([obj isKindOfClass:NSClassFromString(@"UIImage")]) {
        NSData* data = UIImagePNGRepresentation(obj);
        const void *bytes = [data bytes];
        if (!bytes) {
            bytes = "";
        }
        sqlite3_bind_blob(pStmt, idx, bytes, (int)[data length], SQLITE_STATIC);
    }
    else {
        sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
    }
}

- (NSString*)stringFromDate:(NSDate*)date
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-HH-dd HH:MM:ss";
    return [formatter stringFromDate:date];
}

@end

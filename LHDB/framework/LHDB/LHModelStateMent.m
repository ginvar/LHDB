//
//  LHModelStateMent.m
//  LHDBDemo
//
//  Created by 3wchina01 on 16/1/25.
//  Copyright © 2016年 李浩. All rights reserved.
//

#import "LHModelStateMent.h"
#import "LHPredicate.h"
#import "NSObject+LHModel.h"
#import <objc/runtime.h>

#define CREATE_TABLENAME_HEADER @"CREATE TABLE IF NOT EXISTS "
#define INSERT_HEADER @"INSERT INTO "
#define UPDATE_HEADER @"UPDATE "
#define DELETE_HEADER @"DELETE FROM "
#define SELECT_HEADER @"SELECT * FROM "


@implementation LHModelStateMent

static NSString* tableNameValueString(NSString* type,NSString* name)
{
    //将oc中的type字符串转换成sqlite能认识的类型type，组合成一个字符串，类似@"age INT,"返回，注意后面的","号
    
    NSString* finalStr = @",";
    NSString* typeStr = (NSString*)type;
    if ([typeStr isEqualToString:@"i"]) {
        return [NSString stringWithFormat:@"%@ %@%@",name,@"INT",finalStr];
    }else if ([typeStr isEqualToString:@"f"]) {
        return [NSString stringWithFormat:@"%@ %@%@",name,@"FLOAT",finalStr];
    }else if ([typeStr isEqualToString:@"B"]) {
        return [NSString stringWithFormat:@"%@ %@%@",name,@"BOOL",finalStr];
    }else if ([typeStr isEqualToString:@"d"]) {
        return [NSString stringWithFormat:@"%@ %@%@",name,@"DOUBLE",finalStr];
    }else if ([typeStr isEqualToString:@"q"]) {
        return [NSString stringWithFormat:@"%@ %@%@",name,@"LONG",finalStr];
    }else if ([typeStr isEqualToString:@"NSData"]||[typeStr isEqualToString:@"UIImage"]) {
        return [NSString stringWithFormat:@"%@ %@%@",name,@"BLOB",finalStr];
    }else if ([typeStr isEqualToString:@"NSNumber"]){
        return [NSString stringWithFormat:@"%@ %@%@",name,@"INT",finalStr];
    } else  //可见其他类型，将被当做TEXT类型处理，包括NSDictionary,NSArray
        return [NSString stringWithFormat:@"%@ %@%@",name,@"TEXT",finalStr];
}

static NSDictionary* insertValueString(NSString* name)
{
    return @{name:@"?"};
}

static NSString* updateSQL(NSArray* value)
{
    NSMutableString* string = [NSMutableString string];
    for (NSString* propertyName in value) {
        [string appendFormat:@" %@ = ?,",propertyName];
    }
    if (string.length>0) {
        [string deleteCharactersInRange:NSMakeRange(string.length-1, 1)];
    }
    return string;
}

NSString* createTableString(Class modelClass)
{
    NSMutableString* sqlString = [NSMutableString stringWithString:CREATE_TABLENAME_HEADER];
    NSDictionary* stateMentDic = [modelClass getAllPropertyNameAndType];  //key为属性名，value为属性类型字符串，如：NSString,i,Q,d等等
    [sqlString appendString:NSStringFromClass(modelClass)]; //类名做为表名
    NSMutableString* valueStr = [NSMutableString string];
    [stateMentDic enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* obj, BOOL* stop) {
        obj = [NSString stringWithFormat:@"%@",obj];
        [valueStr appendString:tableNameValueString(obj, key)];
    }];
    if (valueStr.length>0) {
        [valueStr deleteCharactersInRange:NSMakeRange(valueStr.length-1, 1)];
    }
    [sqlString appendFormat:@"(%@)",valueStr];
    return sqlString;
}

NSString* addColum(Class modelClass,NSString* propertyName)
{
    NSString* sqlString = [NSString stringWithFormat:@"alter table %@ add %@ %@",NSStringFromClass(modelClass),propertyName,[modelClass getTypeNameWith:propertyName]];
    return sqlString;
}

NSString* insertString(id model)
{
    NSMutableString* sqlString = [NSMutableString stringWithString:INSERT_HEADER];
    [sqlString appendString:NSStringFromClass([model class])];
    NSDictionary* valueDic = [model lh_ModelToDictionary];
    NSMutableString* keyStr = [NSMutableString string];
    NSMutableString* valueStr = [NSMutableString string];
    for (int i=0; i<valueDic.allKeys.count; i++) {
        NSDictionary* dic = insertValueString(valueDic.allKeys[i]);
        [keyStr appendFormat:@"%@,",dic.allKeys[0]];
        [valueStr appendFormat:@"%@,",dic[dic.allKeys[0]]];
    }
    [sqlString appendFormat:@"(%@) VALUES (%@)",[keyStr substringToIndex:keyStr.length-1],[valueStr substringToIndex:valueStr.length-1]];
    
    //这里sqlString的值类似于"insert into tablename (name,age) values (?,?)"，后面的值中的?将会在后面调用sqlite3_bind_xx绑定参数的时候，被相应参数值依次替代
    return sqlString;
}

NSString* insertStringWithDic(Class cls, NSDictionary* dic)
{
    NSMutableString* sqlString = [NSMutableString stringWithString:INSERT_HEADER];
    [sqlString appendString:NSStringFromClass(cls)];
    NSMutableString* keyStr = [NSMutableString string];
    NSMutableString* valueStr = [NSMutableString string];
    for (int i=0; i<dic.allKeys.count; i++) {
        NSDictionary* valueDic = insertValueString(dic.allKeys[i]);
        [keyStr appendFormat:@"%@,",valueDic.allKeys[0]];
        [valueStr appendFormat:@"%@,",valueDic[valueDic.allKeys[0]]];
    }
    [sqlString appendFormat:@"(%@) VALUES (%@)",[keyStr substringToIndex:keyStr.length-1],[valueStr substringToIndex:valueStr.length-1]];
    return sqlString;
}

NSString* updateString(id model,LHPredicate* predicate)
{
    NSMutableString* updateSql = [NSMutableString stringWithString:UPDATE_HEADER];
    [updateSql appendFormat:@"%@ set",NSStringFromClass([model class])];
    [updateSql appendFormat:@"%@",updateSQL([model lh_ModelToDictionary].allKeys)];
    [updateSql appendFormat:@" WHERE %@",predicate.predicateFormat];
    return updateSql;
}

NSString* updateStringWithDic(Class cls,LHPredicate* predicate,NSDictionary* valueDic)
{
    NSMutableString* updateSql = [NSMutableString stringWithString:UPDATE_HEADER];
    [updateSql appendFormat:@"%@ set",NSStringFromClass(cls)];
    [updateSql appendFormat:@"%@",updateSQL(valueDic.allKeys)];
    [updateSql appendFormat:@" WHERE %@",predicate.predicateFormat];
    return updateSql;
}


NSString* deleteString(Class modelClass,LHPredicate* predicate)
{
    NSMutableString* deleteStr = [NSMutableString stringWithString:DELETE_HEADER];
   
    [deleteStr appendString:NSStringFromClass(modelClass)];
    if (predicate.predicateFormat) {
        [deleteStr appendFormat:@" WHERE %@",predicate.predicateFormat];
    }
    return deleteStr;
}

NSString* selectString(Class modelClass,LHPredicate* predicate)
{
    NSMutableString* selectStr = [NSMutableString stringWithString:SELECT_HEADER];
    [selectStr appendString:NSStringFromClass(modelClass)];
    if (predicate.predicateFormat) {
        [selectStr appendFormat:@" WHERE %@",predicate.predicateFormat];
    }
    if (predicate.sortString) {
        [selectStr appendFormat:@" ORDER BY %@",predicate.sortString];
    }
    return selectStr;
}

@end

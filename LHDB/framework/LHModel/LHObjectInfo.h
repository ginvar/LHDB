//
//  LHObjectInfo.h
//  LHDBDemo
//
//  Created by 3wchina01 on 16/3/21.
//  Copyright © 2016年 李浩. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger,LHBaseTypeEcoding) {
    LHBaseTypeEcodingUnknow,
    LHBaseTypeEcodingINT,
    LHBaseTypeEcodingLONG,
    LHBaseTypeEcodingULONG,
    LHBaseTypeEcodingCHAR,
    LHBaseTypeEcodingFLOAT,
    LHBaseTypeEcodingBOOL,
    LHBaseTypeEcodingDOUBLE
};

typedef NS_ENUM(NSUInteger,LHNSTypeEcoding) {
    LHNSTypeUNknow,
    LHNSTypeNSString,
    LHNSTypeNSNumber,
    LHNSTypeNSDate,
    LHNSTypeNSData,
    LHNSTypeNSURL,
    LHNSTypeNSArray,
    LHNSTypeNSDictionary,
    LHNSTypeUIImage
};


//描述对象属性的结构
@interface LHObjectInfo : NSObject

@property (nonatomic) Class cls;    //当属性是OC对象时，　cls记录属性对象所属类，为基础类型时，值为nil

@property (nonatomic) objc_property_t property_t;   //属性

@property (nonatomic,copy) NSString* name;  //属性名

@property (nonatomic,assign) LHBaseTypeEcoding baseTypeEcoding; 　//自定义基础数据类型编码

@property (nonatomic,assign) LHNSTypeEcoding nsTypeEcoding; //自定义OC对象类型编码

@property (nonatomic) SEL set;  //属性的setter方法

@property (nonatomic) SEL get;  //属性的getter方法

@property (nonatomic,copy) NSString* type; //对象类型，如：NSString,i,Q,d等等

- (instancetype)initWithProperty:(objc_property_t)property;

@end

//对象类信息
@interface LHClassInfo : NSObject

@property (nonatomic)Class cls;

@property (nonatomic)Class superClass;

@property (nonatomic)Class metaClass;

@property (nonatomic,assign) BOOL isMetaClass;

@property (nonatomic,strong) NSMutableDictionary* objectInfoDic;

- (instancetype)initWithClass:(Class)cls;

+ (BOOL)isCacheWithClass:(Class)cls;

+ (LHClassInfo*)classInfoWithClass:(Class)cls;

- (LHObjectInfo*)objectInfoWithName:(NSString*)name;

@end

//
//  FRPPhotoImporter.h
//  FunctionReactivePixels
//
//  Created by mac on 15/5/5.
//  Copyright (c) 2015年 jiji. All rights reserved.
//
//  作为View Model

#import <Foundation/Foundation.h>

@class FRPPhotoModel;

@interface FRPPhotoImporter : NSObject

+ (RACSignal *)importPhotos;

/**
 *  使用photoModel数据请求详细图片数据
 *
 *  @param photoModel photo数据对象
 *
 *  @return 包含详情图片数据的RACReplaySubject对象
 */
+ (RACReplaySubject *)fetchPhotoDetails:(FRPPhotoModel *)photoModel;

@end

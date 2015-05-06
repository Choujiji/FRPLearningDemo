//
//  FRPPhotoModel.h
//  FunctionReactivePixels
//
//  Created by mac on 15/5/5.
//  Copyright (c) 2015年 jiji. All rights reserved.
//
//  作为data model

#import <Foundation/Foundation.h>

@interface FRPPhotoModel : NSObject

@property (nonatomic, strong) NSString *photoName;
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *photographerName;
/**
 *  评级
 */
@property (nonatomic, strong) NSString *rating;

/**
 *  缩略URL
 */
@property (nonatomic, strong) NSString *thumbnailURL;

/**
 *  缩略数据
 */
@property (nonatomic, strong) NSData *thumbnailData;

/**
 *  完整URL
 */
@property (nonatomic, strong) NSString *fullsizedURL;

/**
 *  完整数据
 */
@property (nonatomic, strong) NSData *fullsizedData;


@end

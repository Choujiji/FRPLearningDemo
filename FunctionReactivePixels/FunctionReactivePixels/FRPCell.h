//
//  FRPCell.h
//  FunctionReactivePixels
//
//  Created by mac on 15/5/6.
//  Copyright (c) 2015年 jiji. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FRPPhotoModel;

@interface FRPCell : UICollectionViewCell

/**
 *  添加数据模型属性，用于监听里面的字段
 */
@property (nonatomic, strong) FRPPhotoModel *photoModel;

//- (void)setPhotoModel:(FRPPhotoModel *)photoModel;

@end

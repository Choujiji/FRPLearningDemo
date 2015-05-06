//
//  FRPFullsizeViewController.h
//  FunctionReactivePixels
//
//  Created by mac on 15/5/6.
//  Copyright (c) 2015年 jiji. All rights reserved.
//
//  负责显示一个pageViewController，里面的元素为一个个的PhotoViewController的view

#import <UIKit/UIKit.h>

@class FRPFullsizeViewController;

@protocol FRPFullsizePhotoViewControllerDelegate <NSObject>

- (void)userDidScroll:(FRPFullsizeViewController *)viewController toPhotoAtIndex:(NSInteger)index;

@end

@interface FRPFullsizeViewController : UIViewController


@property (nonatomic, readonly) NSArray *photoModelArray;
@property (nonatomic, weak) id<FRPFullsizePhotoViewControllerDelegate> delegate;

- (instancetype)initWIthPhotoModels:(NSArray *)photoModelArray currentPhotoIndex:(NSInteger)photoIndex;


@end

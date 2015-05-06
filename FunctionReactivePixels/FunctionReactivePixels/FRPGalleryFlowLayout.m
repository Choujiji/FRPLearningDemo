//
//  FRPGalleryFlowLayout.m
//  FunctionReactivePixels
//
//  Created by mac on 15/5/5.
//  Copyright (c) 2015年 jiji. All rights reserved.
//

#import "FRPGalleryFlowLayout.h"

@implementation FRPGalleryFlowLayout

- (id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    self.itemSize = CGSizeMake(145, 145);//colletionView代理对象没实现cellSize方法时，会自动使用这个itemSize来配置cell的尺寸
    self.minimumInteritemSpacing = 10;//每行中itemCell的间距最小值
    self.minimumLineSpacing = 10;//组最小间距，也是在代理对象没实现方法时使用这个
    self.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    
    return self;
}

@end

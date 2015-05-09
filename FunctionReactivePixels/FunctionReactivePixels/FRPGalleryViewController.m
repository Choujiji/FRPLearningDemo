//
//  FRPGalleryViewController.m
//  FunctionReactivePixels
//
//  Created by mac on 15/5/5.
//  Copyright (c) 2015年 jiji. All rights reserved.
//

#import "FRPGalleryViewController.h"
#import "FRPGalleryFlowLayout.h"
#import "FRPPhotoImporter.h"
#import "FRPCell.h"
#import "FRPFullsizeViewController.h"

@interface FRPGalleryViewController () <FRPFullsizePhotoViewControllerDelegate>

@property (nonatomic, strong) NSArray *photosArray;

/**
 *  使用RAC对象作为collectionView的delegate
 */
@property (nonatomic, strong) id collectionViewDelegate;

@end

@implementation FRPGalleryViewController

static NSString * const reuseIdentifier = @"Cell";

- (id)init
{
    FRPGalleryFlowLayout *flowLayout = [[FRPGalleryFlowLayout alloc] init];//创建布局对象
    
    self = [self initWithCollectionViewLayout:flowLayout];//使用指定布局初始化自身
    if (!self)
    {
        return nil;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerClass:[FRPCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    
    self.title = @"Popular on 500px";
    
    
    //防止引用循环---racObserver --> nextblock --> self --> racobserver；所以使用weak的self防止block保留self
    @weakify(self);
    
    [RACObserve(self, photosArray) subscribeNext:^(id x) {
        
        @strongify(self);
        
        [self.collectionView reloadData];
        
    }];
    
    [self loadPopularPhotos];
    
    
    
    //以下是fullSizeViewController对象的代理对象及代理方法实现
    
    //声明遵循协议FullSizeVCDelegate的第三者代理对象（现在不是self了）
    RACDelegateProxy *viewControllerDelegate = [[RACDelegateProxy alloc] initWithProtocol:@protocol(FRPFullsizePhotoViewControllerDelegate)];
    
    //声明该第三者代理对象使用协议的协议方法生成RACSignal
    RACSignal *delegateSelectorSignal = [viewControllerDelegate rac_signalForSelector:@selector(userDidScroll:toPhotoAtIndex:) fromProtocol:@protocol(FRPFullsizePhotoViewControllerDelegate)];
    //用预定下一步的方式实现代理方法
    [delegateSelectorSignal subscribeNext:^(id x) {
        
        @strongify(self);//前面已经有@weakify(self)了
        
        RACTuple *value = (RACTuple *)x;//协议方法返回的是协议方法中的参数组：此参数组中参数的顺序即为从前到后（这里面就是第一个参数fullSizeViewController对象，第二个参数即为index包装的number对象），索引从0开始
        
        NSInteger row = [value.second integerValue];//second即为index参数
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:row inSection:0];
        
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        
    }];
    
    
    
    
    //以下是collectionView的代理对象及代理方法实现
    self.collectionViewDelegate = [[RACDelegateProxy alloc] initWithProtocol:@protocol(UICollectionViewDelegate)];
    RACSignal *collectionViewDelegateSignal = [self.collectionViewDelegate rac_signalForSelector:@selector(collectionView:didSelectItemAtIndexPath:)];
    [collectionViewDelegateSignal subscribeNext:^(id x) {
        
//        NSLog(@"asdasdasd");
        
        @strongify(self);
        
        RACTuple *value = (RACTuple *)x;
        
        NSIndexPath *indexPath = value.second;//取得indexPath参数（第二个）
        
        FRPFullsizeViewController *vc = [[FRPFullsizeViewController alloc] initWIthPhotoModels:self.photosArray currentPhotoIndex:indexPath.row];
        
        vc.delegate = (id<FRPFullsizePhotoViewControllerDelegate>)viewControllerDelegate;//声明上面的RACDelegateProxy对象为vc的代理对象
        
        
        [self.navigationController pushViewController:vc animated:YES];
        
    }];
    
    self.collectionView.delegate = self.collectionViewDelegate;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
//#warning Incomplete method implementation -- Return the number of sections
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
//#warning Incomplete method implementation -- Return the number of items in the section
    return self.photosArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FRPCell *cell = (FRPCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    [cell setPhotoModel:self.photosArray[indexPath.row]];
    
    return cell;
}


#pragma mark <UICollectionViewDelegate>

/*
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    FRPFullsizeViewController *vc = [[FRPFullsizeViewController alloc] initWIthPhotoModels:self.photosArray currentPhotoIndex:indexPath.row];
//    
//    vc.delegate = self;
//    
//    
//    [self.navigationController pushViewController:vc animated:YES];
    
}
*/

#pragma FRPFullSizeViewControllerDelegate
- (void)userDidScroll:(FRPFullsizeViewController *)viewController toPhotoAtIndex:(NSInteger)index
{
    /*
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    
    //自动定位到指定item的位置
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
     */
}



/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/


- (void)loadPopularPhotos
{
    /* basic
    [[FRPPhotoImporter importPhotos] subscribeNext:^(id x) {
        
        self.photosArray = x;
        
    } error:^(NSError *error) {
        
        NSLog(@"error--- %@", error);
        
    }];
    */
    
    
    /* 分解
    RACSignal *photoSignal = [FRPPhotoImporter importPhotos];
    RACSignal *photoLoaded = [photoSignal catch:^RACSignal *(NSError *error) {
        
        NSLog(@"errror: %@", error);
        
        return [RACSignal empty];
        
    }];//出错误即返回空
    
    RAC(self, photosArray) = photoLoaded;//使用此signal来自动更新photosArray
    
    @weakify(self);
    
    [photoLoaded subscribeNext:^(id x) {
        
        @strongify(self);
        
        [self.collectionView reloadData];
        
    }];
    */
    
    
    @weakify(self);
    RAC(self, photosArray) = [[[[FRPPhotoImporter importPhotos] doCompleted:^{
        
        @strongify(self);
        
        [self.collectionView reloadData];
        
    }] logError] catchTo:[RACSignal empty]];//用请求回的signal的doCompleted块来设置photosArray，出错误log出Error，且catch到错误后，返回空signal来使signal直接complete
    
    
    
}

@end

//
//  FRPPhotoImporter.m
//  FunctionReactivePixels
//
//  Created by mac on 15/5/5.
//  Copyright (c) 2015年 jiji. All rights reserved.
//

#import "FRPPhotoImporter.h"
#import "FRPPhotoModel.h"

@implementation FRPPhotoImporter

#pragma mark - 基本数据请求解析生成

/* 基本RAC调用
+ (RACSignal *)importPhotos
{
    //创建对象（是RACSignal的子类，可以作为异步对象返回）
    RACReplaySubject *subject = [RACReplaySubject new];
    
    //发送异步请求并解析处理数据
    NSURLRequest *request = [self popularURLRequest];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (data)
        {
            id results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            RACSequence *resultsSequence = [results[@"photos"] rac_sequence];//将结果解析转换成sequence（RACStream的子类），给sequence即可用RAC进行操作
            
            
            //使用map，遍历sequence内的每个对象（这里是字典对象），生成包含photoModel对象的新sequence
            RACSequence *photoModelSequence = [resultsSequence map:^id(NSDictionary *photoDictionary) {
                
                //用每个字典来转换成photoModel对象
                FRPPhotoModel *model = [FRPPhotoModel new];
                
                
                [self configPhotoModel:model withDictionary:photoDictionary];
                [self downloadThumbnailForPhotoModel:model];
                
                
                return model;
            }];
            
            //转换为OC数组
            NSArray *photoModelArray = [photoModelSequence array];
            
            //作为完成后的对象，发送给订阅者
            [subject sendNext:photoModelArray];
            
            //告知订阅者，此流完成
            [subject sendCompleted];
        }
        else
        {
            //发送错误消息
            [subject sendError:connectionError];
        }
        
        
    }];
    
    //异步返回对象
    return subject;
}
 */

+ (RACSignal *)importPhotos
{
    NSURLRequest *request = [self popularURLRequest];
    
    //reduceEach:^id(每一个参数){} = map:^id(RACTuple *value){}，区别是reduceEach可以在编译期直接对参数进行检查（其实就是把方法里面的形参可以依次写出来，写代码的时候就知道对应的是哪个参数），map那个需要通过RACTuple的first和second等指代形参，不明显

    
    return [[[[[[NSURLConnection rac_sendAsynchronousRequest:request] reduceEach:^id(NSURLResponse *response, NSData *data){
        return data;
    }] deliverOn:[RACScheduler mainThreadScheduler]] map:^id(NSData *data) {
        
        
        NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        RACSequence *photoDataSequence = [dataDic[@"photos"] rac_sequence];
        
        //将解析数据转换为数据模型对象，并包装成数组返回
        return [[photoDataSequence map:^id(NSDictionary *photoDic) {
            
            FRPPhotoModel *photoModel = [FRPPhotoModel new];
            
            [self configPhotoModel:photoModel withDictionary:photoDic];
            [self downloadThumbnailImageForPhotoModel:photoModel];
            
            return photoModel;
            
        }] array];
    }] publish] autoconnect];
}


+ (NSURLRequest *)popularURLRequest
{
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    NSURLRequest *request = [delegate.apiHelper urlRequestForPhotoFeature:PXAPIHelperPhotoFeaturePopular resultsPerPage:100 page:0 photoSizes:PXPhotoModelSizeThumbnail sortOrder:PXAPIHelperSortOrderRating except:PXPhotoModelCategoryNude];
    
    return request;
}

+ (void)configPhotoModel:(FRPPhotoModel *)photoModel withDictionary:(NSDictionary *)dictionary
{
    photoModel.photoName = dictionary[@"name"];
    photoModel.identifier = dictionary[@"id"];
    photoModel.photographerName = (dictionary[@"user"])[@"username"];
    photoModel.rating = dictionary[@"rating"];
    photoModel.thumbnailURL = [self urlFirImageSize:3 inDictionary:dictionary[@"images"]];
    
    if (dictionary[@"comments_count"])
    {
        photoModel.fullsizedURL = [self urlFirImageSize:4 inDictionary:dictionary[@"images"]];
    }
}

/* 原始方法
+ (void)downloadThumbnailForPhotoModel:(FRPPhotoModel *)photoModel
{
    NSAssert(photoModel.thumbnailURL, @"Thumb URL must not be nil");
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:photoModel.thumbnailURL]];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        photoModel.thumbnailData = data;
        
    }];
}
 */

+ (NSString *)urlFirImageSize:(NSInteger)size inDictionary:(NSArray *)array
{
    RACSequence *validSequence = [[array rac_sequence] filter:^BOOL(NSDictionary *value) {
        
        return ([value[@"size"] integerValue] == size);
    }];//过滤，得到指定size组成的字典数组
    
    RACSequence *validUrlSequence = [validSequence map:^id(NSDictionary *value) {
        return value[@"url"];
    }];//将其中每个字典的url组成数组返回
    
    return [[validUrlSequence array] firstObject];//调用firstObject可以防止空数组访问越界
}


#pragma mark - 图片详情数据请求

+ (NSURLRequest *)photoURLRequest:(FRPPhotoModel *)photoModel
{
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    
    return [delegate.apiHelper urlRequestForPhotoID:photoModel.identifier.integerValue];
}

/* 老方法，繁琐
+ (RACReplaySubject *)fetchPhotoDetails:(FRPPhotoModel *)photoModel
{
    RACReplaySubject *subject = [RACReplaySubject subject];
    
    NSURLRequest *request = [self photoURLRequest:photoModel];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (data)
        {
            id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            NSDictionary *photoDataDic = result[@"photo"];
            
            [self configPhotoModel:photoModel withDictionary:photoDataDic];
            
            //下载完整图数据
            [self downloadFullsizedImageForPhotoModel:photoModel];
            
            [subject sendNext:photoModel];
            
            [subject sendCompleted];
        }
        else
        {
            [subject sendError:connectionError];
        }
        
    }];
    
    return subject;
}
 */

+ (RACSignal *)fetchPhotoDetails:(FRPPhotoModel *)photoModel
{
    NSURLRequest *request = [self photoURLRequest:photoModel];
    
    /*  这个不对，publish autoConnect是包装网络请求信号用的
    //请求原始数据（json格式）
    RACSignal *originDataSignal = [[[NSURLConnection rac_sendAsynchronousRequest:request] map:^id(id value) {
        
        RACTuple *tuple = (RACTuple *)value;
        NSData *data = tuple.second;
        
        return data;//返回得到的NSData对象
    }] deliverOn:[RACScheduler mainThreadScheduler]];
    
    //解析数据
    return [[[originDataSignal map:^id(NSData *value) {
        
        NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:value options:NSJSONReadingMutableContainers error:nil];
        NSDictionary *photoDataDic = dataDic[@"photo"];
        
        //赋值
        [self configPhotoModel:photoModel withDictionary:photoDataDic];
        
        [self downloadFullsizedImageForPhotoModel:photoModel];
        
        return photoModel;
    }] publish] autoconnect];//publish--创建并返回一个广播连接对象，可以把单独的预订者注入到指定信号中，autoconnect--被第一个预订者预定时会创建此信号，没有预订者后回自动释放此信号
    */
    
    
    //publish--将网络请求的signal转换为muticastConnection，autoConnect--将muticastConnection对象转换成signal对象（这种signal对象在预订者预定后，连接成功时自动连接请求，完成后，当预订者结束预定后，signal自动释放）
    return [[[[[[NSURLConnection rac_sendAsynchronousRequest:request] map:^id(RACTuple *value) {
        
        return value.second;
        
    }] deliverOn:[RACScheduler mainThreadScheduler]] map:^id(NSData *data) {
        
        //解析数据，给photoModel赋值，并返回
        NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSDictionary *photoDataDic = dataDic[@"photo"];

        [self configPhotoModel:photoModel withDictionary:photoDataDic];
        [self downloadFullsizedImageForPhotoModel:photoModel];
        
        return photoModel;
    }] publish] autoconnect];
}

/* 非RAC方式
+ (void)download:(NSString *)urlString withCompletion:(void (^)(NSData *data))completion
{
    NSAssert(urlString, @"URL must not be nil!");
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (completion)
        {
            completion(data);
        }
        
    }];
}
 */

+ (RACSignal *)download:(NSString *)urlString type:(NSString *)type
{
    NSAssert(urlString, @"URL must not be nil!");
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    //异步请求数据，将返回值NSData对象包装成RACSignal在主线程中返回，方便其他人使用
    RACSignal *dataSignal = [[[[[NSURLConnection rac_sendAsynchronousRequest:request] map:^id(id value) {
        
        NSLog(@"%@", type);
        
        RACTuple *tuple = (RACTuple *)value;
        NSData *data = tuple.second;
        return data;
    }] logError] catch:^RACSignal *(NSError *error) {
        return [RACSignal empty];
    }] deliverOn:[RACScheduler mainThreadScheduler]];
    
    
    return dataSignal;
}


+ (void)downloadFullsizedImageForPhotoModel:(FRPPhotoModel *)photoModel
{
    /*
    [self download:photoModel.fullsizedURL withCompletion:^(NSData *data) {
        photoModel.fullsizedData = data;
    }];
     */
    
    //使用异步请求返回的signal来绑定数据模型的属性
    RAC(photoModel, fullsizedData) =  [self download:photoModel.fullsizedURL type:@"full"];
}

+ (void)downloadThumbnailImageForPhotoModel:(FRPPhotoModel *)photoModel
{
    /*
    [self download:photoModel.thumbnailURL withCompletion:^(NSData *data) {
        photoModel.thumbnailData = data;
    }];
     */
    
    RAC(photoModel, thumbnailData) = [self download:photoModel.thumbnailURL type:@"thumb"];
}
@end

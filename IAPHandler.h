//
//  StoreKit.h
//  store
//
//  Created by Rocket on 13-5-16.
//  Copyright (c) 2013年 Angell Echo. All rights reserved.
//
#import <StoreKit/StoreKit.h>

#ifdef __cplusplus
#define IAP_EXTERN   extern "C" __attribute__((visibility ("default")))
#else
#define IAP_EXTERN   extern __attribute__((visibility ("default")))
#endif

@class IAPHandler;

//  内购回调 block，所有的回掉全部集中在了这一块 transactions 为购买成功的所有产品信息
//  error 为购买失败的原因，通常error为nil时，内购才算成功
//  code == IAPHandleCodeNoNetWork:用户没有联网
//  code == IAPHandleCodeLimit:用户限制内置付费
//  code == IAPHandleCodeGetProductFail:获取产品信息失败
//  code == IAPHandleCodePurcharseFail:用户内购失败
//  code == IAPHandleCodePurcharseCancel:用户取消购买
//  code == IAPHandleCodeNoPurcharse:用户未内购任何产品
//  code == IAPHandleCodeErrorProductId:无效的产品id
//  code == IAPHandleCodePurcharing:这个product正在进行交易
//  code == IAPHandleCodeActiveFail:激活失败，通过Error.userInfo[]得到订单号
//  code == IAPHandleCodeSignError:激活签名错误

IAP_EXTERN NSInteger const IAPHandleCodeNoNetWork;
IAP_EXTERN NSInteger const IAPHandleCodeLimit;
IAP_EXTERN NSInteger const IAPHandleCodeGetProductFail;
IAP_EXTERN NSInteger const IAPHandleCodePurcharseFail;
IAP_EXTERN NSInteger const IAPHandleCodePurcharseCancel;
IAP_EXTERN NSInteger const IAPHandleCodeNoPurcharse;
IAP_EXTERN NSInteger const IAPHandleCodeErrorProductId;
IAP_EXTERN NSInteger const IAPHandleCodePurcharing;
IAP_EXTERN NSInteger const IAPHandleCodeActiveFail;

IAP_EXTERN NSString *const IAPHandleKeyTransaction;

typedef void(^IAPHandleResponse)(NSError *error);

@interface IAPHandler : NSObject
@property (nonatomic, copy) IAPHandleResponse response;

// 获取IAPHandler
+ (IAPHandler *)shareIAPHandlerWithProductId:(NSString *)productId;

// 购买产品
- (void)buyProductWithResponse:(IAPHandleResponse)response;

// 恢复购买
- (void)restoreProductWithResponse:(IAPHandleResponse)response;

// 停止请求
- (void)stopRequest;
@end

//
//  IAPHandler.m
//  store
//
//  Created by Rocket on 13-5-16.
//  Copyright (c) 2013年 Angell Echo. All rights reserved.
//

#if __has_feature(objc_arc)
#define PX_AUTORELEASE(expression) [expression self]
#define PX_RELEASE(expression) [expression self]
#define PX_RETAIN(expression) [expression self]
#define PX_DEALLOC /* */
#else
#define PX_AUTORELEASE(expression) [expression autorelease]
#define PX_RELEASE(expression) [expression release]
#define PX_RETAIN(expression) [expression retain]
#define PX_DEALLOC [super dealloc];
#endif

#import "IAPHandler.h"
#import <CommonCrypto/CommonDigest.h>
#import <SystemConfiguration/SystemConfiguration.h>

//#include <ifaddrs.h>
#include <arpa/inet.h>
//#include <sys/socket.h> // Per msqr
//#include <sys/sysctl.h>
//#include <net/if.h>
//#include <net/if_dl.h>

NSInteger const IAPHandleCodeNoNetWork = 377277;
NSInteger const IAPHandleCodeLimit = 377278;
NSInteger const IAPHandleCodeGetProductFail = 377279;
NSInteger const IAPHandleCodePurcharseFail = 377280;
NSInteger const IAPHandleCodePurcharseCancel = 377281;
NSInteger const IAPHandleCodeNoPurcharse = 377282;
NSInteger const IAPHandleCodeErrorProductId = 377283;
NSInteger const IAPHandleCodePurcharing = 377285;
NSInteger const IAPHandleCodeActiveFail = 377286;

NSString *const IAPHandleKeyTransaction = @"transaction";


@interface IAPHandler()<SKPaymentTransactionObserver,SKProductsRequestDelegate,UIAlertViewDelegate>
{
    SKProductsRequest *_request;

    BOOL _purcharsed;
}
@property (nonatomic, copy) NSString *productID;
@property (nonatomic, assign) BOOL isRestore;
@end

@implementation IAPHandler
@synthesize response = _response;
@synthesize productID = _productID;

#pragma mark - 
#pragma mark 静态变量申明

IAPHandler *_singleIAPHandler = nil;
/**
 *  静态声明一个IAP类
 *
 *  @param productId 设定该IAP的产品IP
 *
 *  @return 返回IAP类
 */
+ (IAPHandler *)shareIAPHandlerWithProductId:(NSString *)productId
{
    //判断设备是否可用
    if (_singleIAPHandler == nil) {
        _singleIAPHandler = [[IAPHandler alloc] init];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:_singleIAPHandler];
    }
    
    _singleIAPHandler.productID = productId;
    
    return _singleIAPHandler;
}

/**
 *  销毁时移除队列，通常该方法不会被调用
 */
- (void)dealloc
{
    PX_DEALLOC;
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark -
#pragma mark 判断该设备是否允许进行内置付费
/**
 *  判断该设备的条件是否允许内购
 *
 *  @param error 给予error的地址
 */
-(void)judgeUsefulWithError:(NSError **)error{
    if (![SKPaymentQueue canMakePayments]){
        //用户不允许内置付费
        *error = PX_AUTORELEASE([[NSError alloc] initWithDomain:@"用户不允许内置付费"
                                                           code:IAPHandleCodeLimit
                                                       userInfo:nil]);
		return ;
	}
    
    
    
    if (![IAPHandler isNetworkReachable]) {
        //用户无法联网
        *error = PX_AUTORELEASE([[NSError alloc] initWithDomain:@"用户无法连接到网络"
                                                           code:IAPHandleCodeNoNetWork
                                                       userInfo:nil]);
        return;
    }
}

+(BOOL)isNetworkReachable{
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    
    if (!didRetrieveFlags){
        return NO;
    }
    
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    return (isReachable && !needsConnection) ? YES : NO;
}



#pragma mark - 
#pragma mark 参数初始化
/**
 *  检查是否可以正常进行内购
 *
 *  @param response block 用户在用户关闭网络或者内购情况下，直接返回错误
 *
 *  @return 检查是否合格
 */
- (BOOL)checkRequestWithResponse:(IAPHandleResponse)response
{
    NSError *error = nil;
    
    [self judgeUsefulWithError:&error];
    
    if (error != nil) {
        if (response != nil) {
            response(error);
        }
        return NO;
    }
    
    if (self.response != nil) {
        PX_RELEASE(self.response);
        self.response = nil;
    }
    
    [self stopRequest];
    
    _purcharsed = NO;
    
    return YES;
}

#pragma mark -
#pragma mark 购买产品通过product id
/**
 *  购买产品
 *
 *  @param response 回调block
 */
- (void)buyProductWithResponse:(IAPHandleResponse)response
{
    if (![self checkRequestWithResponse:response]) {
        return;
    }
    
    self.response = response;
    
    self.isRestore = NO;
    
    [self requestProductData:[NSSet setWithObjects:self.productID.description, nil]];
}

#pragma mark -
#pragma mark 恢复购买
/**
 *  恢复购买
 *
 *  @param response 回调block
 */
-(void)restoreProductWithResponse:(IAPHandleResponse)response
{
    if (![self checkRequestWithResponse:response]) {
        return;
    }
    
    self.response = response;
    
    self.isRestore = YES;
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark -
#pragma mark 请求得到产品信息通过product id
/**
 *  请求产品
 *
 *  @param set 产品id合集
 */
- (void)requestProductData:(NSSet *)set
{
    _request= [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    _request.delegate = _singleIAPHandler;
    [_request start];
}

#pragma mark -
#pragma mark 请求得到产品信息的回调
/**
 *  得到产品信息失败后的回调
 *
 *  @param request 当前调用的request
 *  @param error   当前回调存在的错误
 */
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    PX_RELEASE(_request);
    _request = nil;
    
    [self responseWithError:[NSError errorWithDomain:@"获得该产品失败！"
                                                code:IAPHandleCodeGetProductFail
                                            userInfo:nil]];
}

/**
 *  得到产品信息后的回调
 *
 *  @param request  当前调用的request
 *  @param response 当前返回的response
 */
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    PX_RELEASE(_request);
    _request = nil;
    
    NSArray *myProducts = response.products;
    
    if (myProducts.count > 0) {
        for (int i = 0; i < myProducts.count ; i++) {
            SKProduct *skp = [myProducts objectAtIndex:i];
            //判读购买的产品id 和得到 请求产品的id相同
            if ([skp.productIdentifier isEqualToString:_productID]) {
                //存在购买的产品信息
                SKPayment *payment = [SKPayment paymentWithProduct:skp];
                
                [[SKPaymentQueue defaultQueue] addPayment:payment];
                return;
            }
        }
        
        [self responseWithError:[NSError errorWithDomain:@"无效的产品id"
                                                    code:IAPHandleCodeErrorProductId
                                                userInfo:nil]];
        
    }else if(myProducts.count == 0){
        //得不到产品信息
        [self responseWithError:[NSError errorWithDomain:@"无效的产品id"
                                                    code:IAPHandleCodeErrorProductId
                                                userInfo:nil]];
    }
}

#pragma mark -
#pragma mark 交易事件的所有回调
/**
 *  交易发生的回调
 *
 *  @param queue        当前队列
 *  @param transactions 返回的订单
 */
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        NSDictionary *userInfo = transaction.error ? @{@"error":transaction.error} : nil;
        switch (transaction.transactionState)
        {
                //产品购买失败
            case SKPaymentTransactionStateFailed:
            {
                if (transaction.error.code == SKErrorPaymentCancelled) {
                    [self responseWithError:[NSError errorWithDomain:@"产品取消购买"
                                                                code:IAPHandleCodePurcharseCancel
                                                            userInfo:userInfo]];
                } else {
                    [self responseWithError:[NSError errorWithDomain:@"产品购买失败"
                                                                code:IAPHandleCodePurcharseFail
                                                            userInfo:userInfo]];
                }
            }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                //产品购买成功
            case SKPaymentTransactionStatePurchased:
                //产品恢复购买成功
            case SKPaymentTransactionStateRestored:
            {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                if (![transaction.payment.productIdentifier isEqualToString:_productID]) {
                    continue;
                }
                
                NSString *transactionIdentifier = transaction.originalTransaction ? transaction.originalTransaction.transactionIdentifier : transaction.transactionIdentifier;
                
                NSLog(@"transactionIdentifier is %@", transactionIdentifier);
                
                [self responseWithError:nil];
                
                _purcharsed = YES;
            }
                break;
            default:
                break;
        }
        
    }
}

/**
 *  恢复购买队列完成时的回调
 *
 *  @param queue 当前购买队列
 */
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    if (self.isRestore && !_purcharsed) {
        [self responseWithError:[NSError errorWithDomain:@"用户没有购买该产品"
                                                    code:IAPHandleCodeNoPurcharse
                                                userInfo:nil]];
    }
}

#pragma mark - 
#pragma mark 停止请求
/**
 *  停止购买请求
 */
- (void)stopRequest
{
    if (_request != nil) {
        [_request cancel];
        
        PX_RELEASE(_request);
        _request = nil;
    }
}

#pragma mark -
#pragma mark block 回调 
/**
 *  统一回调处理
 *
 *  @param error 回调返回的错误
 */
- (void)responseWithError:(NSError *)error
{
    if (self.response != nil) {
        self.response (error);
    }
    
    PX_RELEASE(self.response);
    self.response = nil;
}
@end

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking/AFURLSessionManager.h>
#import <AFNetworking/AFCompatibilityMacros.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <AFNetworking/AFSecurityPolicy.h>
#import <AFNetworking/AFURLRequestSerialization.h>
#import <AFNetworking/AFURLResponseSerialization.h>
#import <AFNetworking/AFAutoPurgingImageCache.h>
#import <AFNetworking/AFImageDownloader.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworking/UIActivityIndicatorView+AFNetworking.h>
#import <AFNetworking/UIButton+AFNetworking.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <AFNetworking/UIKit+AFNetworking.h>
#import <AFNetworking/UIProgressView+AFNetworking.h>
#import <AFNetworking/UIRefreshControl+AFNetworking.h>
#import <AFNetworking/WKWebView+AFNetworking.h>

FOUNDATION_EXPORT double AFNetworkingVersionNumber;
FOUNDATION_EXPORT const unsigned char AFNetworkingVersionString[];


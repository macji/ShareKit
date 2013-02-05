//
//  ShareKit.h
//  iZhiHu
//
//  Created by xiao macji on 13-1-28.
//  Copyright (c) 2013年 iHu.im. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SinaWeibo.h"
#import "WXApi.h"
#import "QQApi/QQApi.h"


typedef enum {
    ShareKitWeChatSceneSession,
	ShareKitWeChatSceneTimeline
} ShareKitWeChatScene;

typedef enum {
    ShareKitWeChatMessageTypeText,
    ShareKitWeChatMessageTypeNews,
    ShareKitWeChatMessageTypeImage,
	ShareKitWeChatMessageTypeMusic,
	ShareKitWeChatMessageTypeVideo
} ShareKitWeChatMessageType;

typedef enum {
    ShareKitQQMessageTypeText,
    ShareKitQQMessageTypeNews,
    ShareKitQQMessageTypeImage,
	ShareKitQQMessageTypeMusic,
	ShareKitQQMessageTypeVideo
} ShareKitQQMessageType;

typedef void (^ShareKitSinaWeiboAuthCompletionHandler)(NSError *error);
typedef void (^ShareKitSinaWeiboSuccessHandler)(void);
typedef void (^ShareKitSinaWeiboFailureHandler)(NSError *error);

typedef void (^ShareKitWeChatSuccessHandler)(BaseResp *response);
typedef void (^ShareKitWeChatFailureHandler)(NSError *error);

typedef void (^ShareKitQQSuccessHandler)(void);
typedef void (^ShareKitQQFailureHandler)(NSError *error);

@interface ShareKit : NSObject <SinaWeiboDelegate, SinaWeiboRequestDelegate, WXApiDelegate>

@property (nonatomic, retain) SinaWeibo *sinaWeibo;
@property (nonatomic, copy) ShareKitSinaWeiboAuthCompletionHandler sinaWeiboAuthCompletionHandler;
@property (nonatomic, copy) ShareKitSinaWeiboSuccessHandler sinaWeiboSuccessHandler;
@property (nonatomic, copy) ShareKitSinaWeiboFailureHandler sinaWeiboFailureHandler;

@property (nonatomic, retain) NSString *weChatAppCallBackScheme;
@property (nonatomic, copy) ShareKitWeChatSuccessHandler weChatSuccessHandler;
@property (nonatomic, copy) ShareKitWeChatFailureHandler weChatFailureHandler;

@property (nonatomic, retain) NSString *qqAppCallBackScheme;
@property (nonatomic, copy) ShareKitQQSuccessHandler qqSuccessHandler;
@property (nonatomic, copy) ShareKitQQFailureHandler qqFailureHandler;

+ (ShareKit *)sharedInstance;

- (BOOL)handleOpenURL:(NSURL *)url;
- (void)applicationDidBecomeActive;


// sina weibo
- (void)sinaWeiboSetupWithAppKey:(NSString *)appKey
                       appSecret:(NSString *)appSecrect
                  appRedirectURI:(NSString *)appRedirectURI
               ssoCallbackScheme:(NSString *)ssoCallbackScheme;
- (BOOL)sinaWeiboIsAuthValid;
- (void)sinaWeiboLogout;
- (void)sinaWeiboSendWithText:(NSString *)text
                    imageData:(NSData *)imageData
               authCompletion:(ShareKitSinaWeiboAuthCompletionHandler)authCompletion
                      success:(ShareKitSinaWeiboSuccessHandler)success
                      failure:(ShareKitSinaWeiboFailureHandler)failure;

// wechat
- (void)weChatSetupWithAppKey:(NSString *)appKey;
- (BOOL)weChatIsInstalled;
- (void)weChatSendTextWithText:(NSString *)text
                         scene:(ShareKitWeChatScene)scene
                       success:(ShareKitWeChatSuccessHandler)success
                       failure:(ShareKitWeChatFailureHandler)failure;
- (void)weChatSendNewsWithTitle:(NSString *)title
                    description:(NSString *)description
                      thumbData:(NSData *)thumbData
                      targetURL:(NSString *)targetURL
                          scene:(ShareKitWeChatScene)scene
                        success:(ShareKitWeChatSuccessHandler)success
                        failure:(ShareKitWeChatFailureHandler)failure;
- (void)weChatSendWithTitle:(NSString *)title
                description:(NSString *)description
                  thumbData:(NSData *)thumbData
                  targetURL:(NSString *)targetURL
                  mediaData:(NSData *)mediaData
                messageType:(ShareKitWeChatMessageType)messageType
                      scene:(ShareKitWeChatScene)scene
                    success:(ShareKitWeChatSuccessHandler)success
                    failure:(ShareKitWeChatFailureHandler)failure;

// QQ
- (void)qqSetupWithAppKey:(NSString *)appKey;
- (BOOL)qqIsInstalled;
- (void)qqSendWithTitle:(NSString *)title
            description:(NSString *)description
              thumbData:(NSData *)thumbData
              targetURL:(NSString *)targetURL
              mediaData:(NSData *)mediaData
            messageType:(ShareKitQQMessageType)messageType
                success:(ShareKitQQSuccessHandler)success
                failure:(ShareKitQQFailureHandler)failure;


@end

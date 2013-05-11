//
//  ShareKit.m
//  iZhiHu
//
//  Created by xiao macji on 13-1-28.
//  Copyright (c) 2013年 iHu.im. All rights reserved.
//

#import "ShareKit.h"

#import <objc/runtime.h>

#define kShareKit @"ShareKit"
#define kShareKitSinaWeiboLoginErrorCode 10001
#define kShareKitWeChatSendContentErrorCode 10002
#define kShareKitDomain @"com.taobao.sharekit"

@implementation ShareKit

+ (ShareKit *)sharedInstance {
    static ShareKit *sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc {
    self.sinaWeibo = nil;
    self.sinaWeiboAuthCompletionHandler = nil;
    self.sinaWeiboSuccessHandler = nil;
    self.sinaWeiboFailureHandler = nil;
    
    self.weChatAppCallBackScheme = nil;
    self.weChatSuccessHandler = nil;
    self.weChatFailureHandler = nil;
    
    self.qqAppCallBackScheme = nil;
    self.qqSuccessHandler = nil;
    self.qqFailureHandler = nil;
    
    [super dealloc];
}

- (void)applicationDidBecomeActive {
    if (self.sinaWeibo) {
        [self.sinaWeibo applicationDidBecomeActive];
    }
}

- (BOOL)handleOpenURL:(NSURL *)url {
    NSLog(@"%@",[url absoluteString]);
    if (self.sinaWeibo && [[url scheme] isEqualToString:self.sinaWeibo.ssoCallbackScheme]) {
        return [self.sinaWeibo handleOpenURL:url];
    }
    
    if ([[url scheme] isEqualToString:self.weChatAppCallBackScheme]) {
        return [WXApi handleOpenURL:url delegate:self];
    }
    
    if ([[url scheme] isEqualToString:self.qqAppCallBackScheme]) {
        return [self qqHandleOpenURL:url];
    }
    
    return YES;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Weibo
////////////////////////////////////////////////////////////////////////

- (void)sinaWeiboSetupWithAppKey:(NSString *)appKey
                       appSecret:(NSString *)appSecrect
                  appRedirectURI:(NSString *)appRedirectURI
               ssoCallbackScheme:(NSString *)ssoCallbackScheme {
    SinaWeibo *weibo = [[SinaWeibo alloc] initWithAppKey:appKey
                                               appSecret:appSecrect
                                          appRedirectURI:appRedirectURI
                                       ssoCallbackScheme:ssoCallbackScheme
                                             andDelegate:self];
    self.sinaWeibo = weibo;
    [weibo release];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceNotificationBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)deviceNotificationBecomeActive {
    [self.sinaWeibo applicationDidBecomeActive];
}

- (BOOL)sinaWeiboIsAuthValid {
    return [self.sinaWeibo isAuthValid];
}

- (void)sinaWeiboLogout {
    if (self.sinaWeibo) {
        [self.sinaWeibo logOut];
    }
}

- (void)sinaWeiboLoginWithCompletionHandler:(ShareKitSinaWeiboAuthCompletionHandler)completionHandler {
    self.sinaWeiboAuthCompletionHandler = completionHandler;
    [self.sinaWeibo logIn];
}

- (void)sinaWeiboSendWithText:(NSString *)text
                withImageData:(NSData *)imageData
                      success:(ShareKitSinaWeiboSuccessHandler)success
                      failure:(ShareKitSinaWeiboFailureHandler)failure {
    
    self.sinaWeiboSuccessHandler = success;
    self.sinaWeiboFailureHandler = failure;
    [self.sinaWeibo requestWithURL:@"statuses/upload.json"
                            params:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    text, @"status", imageData, @"pic", nil]
                        httpMethod:@"POST"
                          delegate:self];
}

- (void)sinaWeiboSendWithText:(NSString *)text
                    imageData:(NSData *)imageData
               authCompletion:(ShareKitSinaWeiboAuthCompletionHandler)authCompletion
                      success:(ShareKitSinaWeiboSuccessHandler)success
                      failure:(ShareKitSinaWeiboFailureHandler)failure {
    if (![self sinaWeiboIsAuthValid]) {
        [self sinaWeiboLoginWithCompletionHandler:^(NSError *error) {
            if (error) {
                authCompletion(error);
            } else {
                authCompletion(nil);
                [self sinaWeiboSendWithText:text
                              withImageData:imageData
                                    success:success
                                    failure:failure];
            }
        }];
    } else {
        authCompletion(nil);
        [self sinaWeiboSendWithText:text
                      withImageData:imageData
                            success:success
                            failure:failure];
    }
}

#pragma mark - WBEngineDelegate Methods
#pragma mark Authorize

- (void)sinaweiboDidLogIn:(SinaWeibo *)sinaweibo {
    if (self.sinaWeiboAuthCompletionHandler) {
        self.sinaWeiboAuthCompletionHandler(nil);
        self.sinaWeiboAuthCompletionHandler = nil;
    }
}

- (void)sinaweibo:(SinaWeibo *)sinaweibo logInDidFailWithError:(NSError *)error {
    if (self.sinaWeiboAuthCompletionHandler) {
        self.sinaWeiboAuthCompletionHandler(error);
        self.sinaWeiboAuthCompletionHandler = nil;
    }
}

- (void)sinaweiboLogInDidCancel:(SinaWeibo *)sinaweibo {
    [self sinaweibo:sinaweibo logInDidFailWithError:
     [NSError errorWithDomain:kShareKit
                         code:kShareKitSinaWeiboLoginErrorCode
                     userInfo:[NSDictionary dictionaryWithObject:
                               @"Login Cancel" forKey:NSLocalizedDescriptionKey]]];
}

- (void)request:(SinaWeiboRequest *)request didFinishLoadingWithResult:(id)result {
    if (self.sinaWeiboSuccessHandler) {
        self.sinaWeiboSuccessHandler();
        self.sinaWeiboSuccessHandler = nil;
    }
}

- (void)request:(SinaWeiboRequest *)request didFailWithError:(NSError *)error {
    if (self.sinaWeiboFailureHandler) {
        self.sinaWeiboFailureHandler(error);
        self.sinaWeiboFailureHandler = nil;
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Wechat
////////////////////////////////////////////////////////////////////////

- (void)weChatSetupWithAppKey:(NSString *)appKey {
    self.weChatAppCallBackScheme = appKey;
    [WXApi registerApp:appKey];
}

- (BOOL)weChatIsInstalled {
    return [WXApi isWXAppInstalled];
}

- (void)weChatSendTextWithText:(NSString *)text
                         scene:(ShareKitWeChatScene)scene
                       success:(ShareKitWeChatSuccessHandler)success
                       failure:(ShareKitWeChatFailureHandler)failure {
    [self weChatSendWithTitle:nil description:text thumbData:nil targetURL:nil mediaData:nil
                  messageType:ShareKitWeChatMessageTypeText
                        scene:scene success:success failure:failure];
}

- (void)weChatSendNewsWithTitle:(NSString *)title
                    description:(NSString *)description
                      thumbData:(NSData *)thumbData
                      targetURL:(NSString *)targetURL
                          scene:(ShareKitWeChatScene)scene
                        success:(ShareKitWeChatSuccessHandler)success
                        failure:(ShareKitWeChatFailureHandler)failure {
    [self weChatSendWithTitle:title
                  description:description
                    thumbData:thumbData
                    targetURL:targetURL
                    mediaData:nil
                  messageType:ShareKitWeChatMessageTypeNews
                        scene:scene
                      success:success
                      failure:failure];
}

- (void)weChatSendWithTitle:(NSString *)title
                description:(NSString *)description
                  thumbData:(NSData *)thumbData
                  targetURL:(NSString *)targetURL
                  mediaData:(NSData *)mediaData
                messageType:(ShareKitWeChatMessageType)messageType
                      scene:(ShareKitWeChatScene)scene
                    success:(ShareKitWeChatSuccessHandler)success
                    failure:(ShareKitWeChatFailureHandler)failure {
    self.weChatSuccessHandler = success;
    self.weChatFailureHandler = failure;
    
    SendMessageToWXReq *req = [[[SendMessageToWXReq alloc] init] autorelease];
    req.scene = scene;
    req.bText = messageType == ShareKitWeChatMessageTypeText;

    if (messageType == ShareKitWeChatMessageTypeText) {
        req.text = description;
    } else {
        WXMediaMessage *message = [WXMediaMessage message];
        if (messageType == ShareKitWeChatMessageTypeImage) {
            WXImageObject *ext = [WXImageObject object];
            ext.imageData = mediaData;
            
            message.thumbData = thumbData;
            message.mediaObject = ext;
        } else if (messageType == ShareKitWeChatMessageTypeNews) {
            WXWebpageObject *ext = [WXWebpageObject object];
            ext.webpageUrl = targetURL;
            
            message.title = title;
            message.description = description;
            message.thumbData = thumbData;
            message.mediaObject = ext;
        } else if (messageType == ShareKitWeChatMessageTypeMusic) {
            WXMusicObject *ext = [WXMusicObject object];
            ext.musicDataUrl = targetURL;
            
            message.title = title;
            message.description = description;
            message.thumbData = thumbData;
            message.mediaObject = ext;
        } else if (messageType == ShareKitWeChatMessageTypeVideo) {
            WXVideoObject *ext = [WXVideoObject object];
            ext.videoUrl = targetURL;
            
            message.title = title;
            message.description = description;
            message.thumbData = thumbData;
            message.mediaObject = ext;
        }
        req.message = message;
    }
    
    [WXApi sendReq:req];
}

- (void)onReq:(BaseReq *)req {
    if([req isKindOfClass:[GetMessageFromWXReq class]]) {
        // TODO 微信请求内容，目前不需要回应
    }
    
    else if([req isKindOfClass:[ShowMessageFromWXReq class]]) {
        // TODO 微信发过来的内容
    }
}

- (void)onResp:(BaseResp *)resp {
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        SendMessageToWXResp *sResp = (SendMessageToWXResp *)resp;
        if (self.weChatFailureHandler && sResp.errCode != 0) {
            self.weChatFailureHandler([NSError errorWithDomain:kShareKitDomain
                                                          code:sResp.errCode
                                                      userInfo:[NSDictionary dictionaryWithObject:
                                                                @"User Canceled" forKey:NSLocalizedDescriptionKey]]);
        } else if (self.weChatSuccessHandler && sResp.errCode == 0) {
            self.weChatSuccessHandler(resp);
        }
    }
    
    else if ([resp isKindOfClass:[SendAuthResp class]]) {
        // TODO auth resp
    }
    
    self.weChatSuccessHandler = nil;
    self.weChatFailureHandler = nil;
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark QQ
////////////////////////////////////////////////////////////////////////

- (void)qqSetupWithAppKey:(NSString *)appKey {
    self.qqAppCallBackScheme = appKey;
    [QQApi registerPluginWithId:appKey];
}

- (BOOL)qqIsInstalled {
    return [QQApi isQQInstalled];
}

- (void)qqSendWithTitle:(NSString *)title
            description:(NSString *)description
              thumbData:(NSData *)thumbData
              targetURL:(NSString *)targetURL
              mediaData:(NSData *)mediaData
            messageType:(ShareKitQQMessageType)messageType
                success:(ShareKitQQSuccessHandler)success
                failure:(ShareKitQQFailureHandler)failure {
    
    self.qqSuccessHandler = success;
    self.qqFailureHandler = failure;
    
    id object;
    if (messageType == ShareKitQQMessageTypeNews) {
        object = [QQApiNewsObject objectWithURL:[NSURL URLWithString:targetURL]
                                          title:title
                                    description:description
                               previewImageData:thumbData];
    }
    
    else if (messageType == ShareKitQQMessageTypeImage) {
        object = [QQApiImageObject objectWithData:mediaData
                                 previewImageData:thumbData
                                            title:title
                                      description:description];
    }
    
    else if (messageType == ShareKitQQMessageTypeMusic) {
        object = [QQApiAudioObject objectWithURL:[NSURL URLWithString:targetURL]
                                           title:title
                                     description:description
                                previewImageData:thumbData];
    }
    
    else if (messageType == ShareKitQQMessageTypeVideo) {
        object = [QQApiVideoObject objectWithURL:[NSURL URLWithString:targetURL]
                                           title:title
                                     description:description
                                previewImageData:thumbData];
        
    } else {
        object = [QQApiTextObject objectWithText:title];
    }
    
    QQApiMessage *msg = [QQApiMessage messageWithObject:object];
    [QQApi sendMessage:msg];
}

- (BOOL)qqHandleOpenURL:(NSURL *)url {
    QQApiMessage *msg = [QQApi handleOpenURL:url];
    if (msg && msg.type == QQApiMessageTypeSendMessageToQQResponse) {
        QQApiResultObject* resultObject = (QQApiResultObject*)msg.object;
        if ([resultObject.error integerValue] == 0) {
            self.qqSuccessHandler();
        } else {
            self.qqFailureHandler([NSError errorWithDomain:kShareKitDomain
                                                      code:[resultObject.error integerValue]
                                                  userInfo:[NSDictionary dictionaryWithObject:
                                                            resultObject.errorDescription forKey:NSLocalizedDescriptionKey]]);
        }
        
        self.qqSuccessHandler = nil;
        self.qqFailureHandler = nil;
    }
    return YES;
}

@end

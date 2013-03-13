//
//  GSTwitPicEngine.h
//  TwitPic Uploader
//
//  Created by Gurpartap Singh on 19/06/10.
//  Copyright 2010 Gurpartap Singh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAToken.h"
#import "ASIHTTPRequest.h"
#import "Sharer.h"

@protocol GSTwitPicEngineDelegate

- (void)twitpicDidFinishUpload:(NSDictionary *)response;

- (void)twitpicDidFailUpload:(NSDictionary *)error;

@end

@class ASINetworkQueue;

@interface GSTwitPicEngine : NSObject < UIWebViewDelegate> {
  __weak id <GSTwitPicEngineDelegate> _delegate;
  
	OAToken *_accessToken;

	ASINetworkQueue *_queue;
}

@property (retain) ASINetworkQueue *_queue;

+ (GSTwitPicEngine *)twitpicEngineWithDelegate:(NSObject *)theDelegate;
- (GSTwitPicEngine *)initWithDelegate:(id)theDelegate;

- (void)uploadPicture:(UIImage *)picture;

- (void)uploadPicture:(UIImage *)picture withMessage:(NSString *)message;

- (void)uploadVideo:(NSData *)videoData withMessage:(NSString *)message;

- (void) cancelShare;

@end


@interface GSTwitPicEngine (OAuth)

- (void)setAccessToken:(OAToken *)token;

@end

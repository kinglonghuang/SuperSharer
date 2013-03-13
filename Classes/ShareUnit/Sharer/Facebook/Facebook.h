/*
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Main Facebook interface for interacting with the Facebook developer API.
 * Provides methods to log in and log out a user, make requests using the REST
 * and Graph APIs, and start user interface interactions (such as
 * pop-ups promoting for credentials, permissions, stream posts, etc.)
 */

#import "FBConnect.h"

@interface Facebook : Sharer <LoginDialogDelegate,FBRequestDelegate>{
	NSString		* _accessToken;
	NSDate			* _expirationDate;
	FBRequest		* _request;
	LoginDialog		* _fbDialog;
	NSString		* _appId;
	NSArray			* _permissions;

}

@property(nonatomic, copy) NSString* accessToken;

@property(nonatomic, copy) NSDate* expirationDate;

- (id)initWithAppId:(NSString *)app_id;

- (void)authorize:(NSArray *)permissions;

//- (BOOL)handleOpenURL:(NSURL *)url;

- (FBRequest*)postVideoWithMethodName:(NSString *)methodName
							andParams:(NSMutableDictionary *)params
						andHttpMethod:(NSString *)httpMethod
						  andDelegate:(id <FBRequestDelegate>)delegate;

- (FBRequest*)requestWithParams:(NSMutableDictionary *)params
                    andDelegate:(id <FBRequestDelegate>)delegate;

- (FBRequest*)requestWithMethodName:(NSString *)methodName
                          andParams:(NSMutableDictionary *)params
                      andHttpMethod:(NSString *)httpMethod
                        andDelegate:(id <FBRequestDelegate>)delegate;

- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
                       andDelegate:(id <FBRequestDelegate>)delegate;

- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
                         andParams:(NSMutableDictionary *)params
                       andDelegate:(id <FBRequestDelegate>)delegate;

- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
                         andParams:(NSMutableDictionary *)params
                     andHttpMethod:(NSString *)httpMethod
                       andDelegate:(id <FBRequestDelegate>)delegate;

- (void)dialog:(NSString *)action
      permission:(NSArray *)permission
   andDelegate:(id<LoginDialogDelegate>)delegate;

- (void)dialog:(NSString *)action
       permission:(NSArray *)permission
     andParams:(NSMutableDictionary *)params
   andDelegate:(id <LoginDialogDelegate>)delegate;

- (BOOL)isSessionValid;

//add by kinglong
- (void) setAndStoreAccessToken:(NSString *)token expirationDate:(NSDate *)expirationDate;

#pragma mark Interface

- (BOOL) isUserLogged;

- (void) login;

- (void) logout;

- (BOOL) canShareStatus;

- (BOOL) canShareLink;

- (BOOL) canShareImage;

- (BOOL) canShareVideo;

- (void) shareStatus:(NSString *)status;

- (void) shareLink:(NSString *)linkStr;

- (void) shareImage:(UIImage *)image withDescription:(NSString *)description;

- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description;

- (void) cancelShare;

- (NSInteger) maxStatusLength;

- (NSString *) itemName;

@end


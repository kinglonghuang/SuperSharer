//
//  KLProtocol.h
//  UcamShare
//
//  Created by kinglong on 11-2-22.
//  Copyright 2011 wondershare. All rights reserved.
//
@protocol LoginDelegate

- (void) itemLoginSucceed:(id)item;

@end

                      
//ReadItLater 
#define RIL_StoredUserName		@"storedReadItLaterUserName"
#define RIL_StoredPwd			@"storedReadItLaterPwd"

#define Instapaper_storedUserName	@"storedInstapaperUserNaem"
#define Instapaper_storedPwd		@"storedInstapaperPwd"

#define FLICKR_STORED_TOKEN_NAME    @"storedFlickrTokenName"

#define FACEBOOK_STORED_TOKEN_NAME  @"storedFacebookTokenName"
#define FACEBOOK_EXPIRATION_DATE    @"facebookTokenExpirationDate"

#define TWITTER_STORED_TOKEN_KEY	@"storedTwitterTokenName"
#define TWITTER_STORED_TOKEN_SECRET	@"storedTwitterTokenSecret"

#define SINA_MB_STORED_TOKEN_KEY	@"storedSinaMBTokenKey"
#define SINA_MB_STORED_TOKEN_SECRET	@"storedSinaMBTokenSecret"

#define TENCENT_MB_STORED_TOKEN_KEY		@"storedTencentMBTokenKey"
#define TENCENT_MB_STORED_TOKEN_SECRET	@"storedTencentMBTokenSecret"

#define SOHU_MB_STORED_TOKEN_KEY		@"storedSohuMBTokenKey"
#define SOHU_MB_STORED_TOKEN_SECRET		@"storedSohuMBTokenSecret"

#define INSTAPAPER_STORED_TOKEN_KEY		@"storedInstapaperTokenKey"
#define INSTAPAPER_STORED_TOKEN_SECRET	@"storedInstapaperTokenSecret"
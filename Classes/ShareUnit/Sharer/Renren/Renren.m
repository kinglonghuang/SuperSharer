//
//  Renren.m
//  tabDemo
//
//  Created by kinglong on 11-3-25.
//  Copyright 2011 Wondershare. All rights reserved.
//

#import "Renren.h"

@implementation Renren

- (id)init
{
	if (self = [super init]) {
		session_ = [[Session sessionForApplication:RENREN_API_KEY secret:RENREN_API_SECRET delegate:self] retain];
		[session_ resume];
	}
	return self;
}

#pragma mark -
#pragma mark Helper

- (NSURL*)generateURL:(NSString*)baseURL params:(NSDictionary*)params {
	if (params) {
		NSMutableArray* pairs = [NSMutableArray array];
		for (NSString* key in params.keyEnumerator) {
			NSString* value = [params objectForKey:key];
			NSString* val = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSString* pair = [NSString stringWithFormat:@"%@=%@", key, val];
			[pairs addObject:pair];
		}
		
		NSString* query = [pairs componentsJoinedByString:@"&"];
		NSString* url = [NSString stringWithFormat:@"%@?%@", baseURL, query];
		return [NSURL URLWithString:url];
	} else {
		return [NSURL URLWithString:baseURL];
	}
}

- (void)connectToGetSession:(NSString*)token {
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObject:token forKey:@"oauth_token"];
	[[Request requestWithSession:session_ delegate:self] getSessionKeyWithParams:params];
}

#pragma mark -
#pragma mark Interface

- (BOOL)isUserLogged
{
	return [session_ isConnected];
}


- (void)login
{
	NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							RENREN_API_KEY, @"client_id", @"touch", @"display",@"photo_upload status_update",@"scope",
							@"token", @"response_type",@"http://graph.renren.com/oauth/login_success.html", @"redirect_uri",nil];
	
	loginDialog_ = [[LoginDialog alloc] initWithURLStr:LOGIN_URL params:params delegate:self];
	[loginDialog_ setNeedWebView:YES];
	[loginDialog_ setConnectTitle:@"Connect to RenRen"];
	[loginDialog_ setIconImg:[UIImage imageNamed:@"LoginDialog.bundle/icons/renren.png"]];
	[loginDialog_ show];
	
	isAuthorizationStep = YES;
}


- (void) logout
{
	[session_ logout];
}


- (BOOL) canShareStatus
{
	return YES;
}


- (BOOL) canShareLink
{
	return NO;
}


- (BOOL) canShareImage
{
	return YES;
}


- (BOOL) canShareVideo
{
	return NO;
}


- (void) shareStatus:(NSString *)status
{
	if ([status length] > [self maxStatusLength]) {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Too many status words" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"RenrenErrDomain" code:toomanyWordsError userInfo:errorData];
		[delegate_ shareItem:self shareFailed:error];
	}else {
		[delegate_ shareItemShareBegin:self];
		isAuthorizationStep = NO;
		NSDictionary * dic = [NSDictionary dictionaryWithObject:status forKey:@"status"];
		request_ = [[Request alloc]initWithSession:nil];
		request_.delegate = self;
		[request_ call:@"status.set" params:dic];
	}
}


- (void) shareLink:(NSString *)linkStr
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"RenrenErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) shareImage:(UIImage *)image withDescription:(NSString *)description
{
	[delegate_ shareItemShareBegin:self];
	
	isAuthorizationStep = NO;
	NSDictionary * metaDic = [NSDictionary dictionaryWithObject:description forKey:@"caption"];
	NSString * picName = [NSString stringWithFormat:@"%@.png",DEFAULT_PIC_NAME];
	request_ = [[Request alloc]initWithSession:nil];
	request_.delegate = self;
	[request_ call:@"photos.upload" params:metaDic dataParam:image dataName:picName];
}


- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"RenrenErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) cancelShare
{
	if (request_) {
		[request_ cancel];
	}
	[delegate_ shareItemShareCancelled:self];
}

- (NSInteger) maxStatusLength
{
	return 140;
}

- (NSString *) itemName
{
	return @"renren";
}


#pragma mark -
#pragma mark LoginDialogDelegate

- (void)dialogCompleteWithUrl:(NSURL *)url
{
	NSString* urlStr = [NSString stringWithFormat:@"%@",url];
	NSRange start = [urlStr rangeOfString:@"access_token="];
	if (start.location != NSNotFound) {
		NSRange end = [urlStr rangeOfString:@"&"];
		NSUInteger offset = start.location+start.length;
		NSString* token = end.location == NSNotFound
		? [urlStr substringFromIndex:offset]
		: [urlStr substringWithRange:NSMakeRange(offset, end.location-offset)];
		if (token) {
			[self connectToGetSession:token];
		}else {
			NSDictionary * errorDic = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
			NSError * error = [NSError errorWithDomain:@"RenrenErrDomain" code:unknownError userInfo:errorDic];
			[delegate_ shareItem:self loginFailed:error];
		}
	}
}

//Called when the dialog get canceled by the user.

- (void)dialogDidNotCompleteWithUrl:(NSURL *)url
{
	if ([loginDialog_ alpha]) {
		[delegate_ shareItemLoginCancelled:self];
	}
}

// WebView Error

- (void)dialog:(LoginDialog*)dialog didFailWithError:(NSError *)error
{
	if ([loginDialog_ alpha]) {
		[delegate_ shareItem:self loginFailed:error];
	}
}


- (BOOL)dialog:(LoginDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url
{
	return NO;
}


- (BOOL)dialogShouldClose
{
	return YES;
}


- (BOOL)dialogShouldLoadLinkURL:(NSURL *)url
{
	return YES;
}

#pragma mark -
#pragma mark RequestDelegate

//request
- (void)request:(Request*)request didLoad:(id)result {
	if (isAuthorizationStep) {
		NSDictionary* object = result;
		RRUID uid = [[[object objectForKey:@"user"] objectForKey:@"id"] intValue];
		NSString* sessionKey = [[object objectForKey:@"renren_token"]objectForKey: @"session_key"];
		NSString* sessionSecret = [[object objectForKey:@"renren_token"] objectForKey:@"session_secret"];
		NSTimeInterval expires = [[[object objectForKey:@"renren_token"] objectForKey:@"expires_in"] floatValue];
		NSDate* expiration = expires ? [NSDate dateWithTimeIntervalSinceNow:expires] : nil;
		
		if (uid && sessionKey && sessionSecret && expiration) {
			
			[session_ begin:uid sessionKey:sessionKey sessionSecret:sessionSecret expires:expiration];
			[session_ resume];
			
			[loginDelegate_ itemLoginSucceed:self];//ask the delegate whether should upload after login
			
		}else {
			
			NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
			NSError * error = [NSError errorWithDomain:@"RenrenErrDomain" code:unknownError userInfo:errorData];
			[delegate_ shareItem:self loginFailed:error];
		}
		
	}else { 
		
		// this switch indicate that the feed is for photo_upload
		[delegate_ shareItemShareSucceed:self];
	}


}

- (void)request:(Request*)request didFailWithError:(NSError*)error {
	[delegate_ shareItem:self loginFailed:error];
}


- (void)requestWasCancelled:(Request*)request
{
	[delegate_ shareItemShareCancelled:self];
}

#pragma mark -
#pragma mark SessionDelegate

- (void)session:(Session*)session didLogin:(RRUID)uid {
	//when invoke the [session resume],it doesn't mean that the user is logged
}

- (void)sessionDidLogout:(Session*)session {
	[delegate_ shareItemLogoutSucceed:self];
}


- (void)dealloc
{
	[request_ release];request_ = nil;
	[session_ release];session_ = nil;
	[super dealloc];
}


@end

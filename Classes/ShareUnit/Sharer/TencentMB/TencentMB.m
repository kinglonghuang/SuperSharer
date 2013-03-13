//
//  TencentConnect.m
//  TwitterConnect
//
//  Created by kinglong on 10/11/30.
//  Copyright 2010 wondershare. All rights reserved.
//
#import "QAsyncHttp.h"
#import "QWeiboAsyncApi.h"
#import "TencentMB.h"
#import "JSON.h"
#import "OAuthConsumer.h"
#import "OASignatureProviding.h"
@interface TencentMB(Private)

- (void) getRequestToken;

- (NSString*)valueForIdentify:(NSString *)indentfy ofQuery:(NSString*)query;

@end

@implementation TencentMB

@synthesize responseData = responseData_;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}


- (OAToken *) accessToken {
	
	if (!accessToken_) {
		NSString * tokenKey = [[NSUserDefaults standardUserDefaults] objectForKey:TENCENT_MB_STORED_TOKEN_KEY];
		NSString * tokenSec = [[NSUserDefaults standardUserDefaults] objectForKey:TENCENT_MB_STORED_TOKEN_SECRET];
		if (tokenKey && tokenKey) {
			accessToken_ = [[OAToken alloc]initWithKey:tokenKey secret:tokenSec];
		}else {
			accessToken_ = nil;
		}
	}
	return accessToken_;
}


- (NSString*)valueForIdentify:(NSString *)indentfy ofQuery:(NSString*)query
{
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	for(NSString *aPair in pairs){
		NSArray *keyAndValue = [aPair componentsSeparatedByString:@"="];
		if([keyAndValue count] != 2) continue;
		if([[keyAndValue objectAtIndex:0] isEqualToString:indentfy]){
			return [keyAndValue objectAtIndex:1];
		}
	}
	return nil;
}

- (void) getRequestToken
{	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	QWeiboSyncApi *weiboEngine = [[QWeiboSyncApi alloc] init] ;
	NSString *retString = [weiboEngine getRequestTokenWithConsumerKey:TENCENT_CONSUMER_KEY consumerSecret:TENCENT_CONSUMER_SECRET];
	[weiboEngine release];
	requestToken_ = [[OAToken alloc] initWithHTTPResponseBody:retString];
	if (requestToken_) {
		NSString * verifyURLStr = [NSString stringWithFormat:@"%@%@",VERIFY_URL,requestToken_.key];
		[loginDialog_ setServerURL:verifyURLStr];
		[loginDialog_ load];
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"TencentErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error];
	}
	
	[pool release];
}


- (void)storeTencentMBToken:(OAToken *)access_token //this string contains the key and secret
{	
	NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
	if (access_token) {
		[defaults setObject: access_token.key forKey: TENCENT_MB_STORED_TOKEN_KEY];
		[defaults setObject:access_token.secret forKey: TENCENT_MB_STORED_TOKEN_SECRET];
	}else {
		[defaults removeObjectForKey: TENCENT_MB_STORED_TOKEN_KEY];
		[defaults removeObjectForKey: TENCENT_MB_STORED_TOKEN_SECRET];
	}
	[defaults synchronize];
}

#pragma mark -
#pragma mark Interface

- (BOOL)isUserLogged
{
	if (self.accessToken.key && self.accessToken.secret) {
		return YES;
	}else {
		return NO;
	}
}


- (void)login
{
	loginDialog_ = [[LoginDialog alloc] initWithURLStr:nil params:nil delegate:self];
	[loginDialog_ setNeedWebView:YES];
	[loginDialog_ setConnectTitle:@"Connect to Tencent"];
	[loginDialog_ setIconImg:[UIImage imageNamed:@"LoginDialog.bundle/icons/tencentweibo.png"]];
	[loginDialog_ show];
	
	[NSThread detachNewThreadSelector:@selector(getRequestToken) toTarget:self withObject:nil];
}


- (void)logout
{

	[self storeTencentMBToken:nil];// nil stands for removing the token from user Default
	[accessToken_ release];
	accessToken_ = nil;
	
	NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray* facebookCookies = [cookies cookiesForURL:
								[NSURL URLWithString:@"http://open.t.qq.com"]];
	
	for (NSHTTPCookie* cookie in facebookCookies) {
		[cookies deleteCookie:cookie];
	}
	
	[delegate_ shareItemLogoutSucceed:self];
}


- (BOOL) canShareStatus
{
	return YES;
}

- (BOOL) canShareLink
{
	return YES;
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
		NSError * error = [NSError errorWithDomain:@"TencentErrDomain" code:toomanyWordsError userInfo:errorData];
		[delegate_ shareItem:self shareFailed:error];
	}else {
		
		[delegate_ shareItemShareBegin:self];
		QWeiboAsyncApi *weiboClient = [[[QWeiboAsyncApi alloc] init] autorelease];
		connection_= [weiboClient publishMsgWithConsumerKey:TENCENT_CONSUMER_KEY 
											 consumerSecret:TENCENT_CONSUMER_SECRET 
											 accessTokenKey:accessToken_.key 
										  accessTokenSecret:accessToken_.secret
													content:status 
												  imageData:nil 
												 resultType:RESULTTYPE_JSON 
												   delegate:self];
	}

}


- (void) shareLink:(NSString *)linkStr
{
	[delegate_ shareItemShareBegin:self];
	QWeiboAsyncApi *weiboClient = [[[QWeiboAsyncApi alloc] init] autorelease];
	connection_= [weiboClient publishMsgWithConsumerKey:TENCENT_CONSUMER_KEY 
										 consumerSecret:TENCENT_CONSUMER_SECRET 
										 accessTokenKey:accessToken_.key 
									  accessTokenSecret:accessToken_.secret
												content:linkStr 
											  imageData:nil 
											 resultType:RESULTTYPE_JSON 
											   delegate:self];
}


- (void) shareImage:(UIImage *)image withDescription:(NSString *)description
{
	[delegate_ shareItemShareBegin:self];
	
	QWeiboAsyncApi *weiboClient = [[[QWeiboAsyncApi alloc] init] autorelease];
	
	connection_= [weiboClient publishMsgWithConsumerKey:TENCENT_CONSUMER_KEY 
								 consumerSecret:TENCENT_CONSUMER_SECRET 
								 accessTokenKey:accessToken_.key 
							  accessTokenSecret:accessToken_.secret
										content:description 
									  imageData:UIImagePNGRepresentation(image) 
									 resultType:RESULTTYPE_JSON 
									   delegate:self];
}


- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"TencentMBErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) cancelShare
{
	if (connection_) {
		[connection_ cancel];connection_ = nil;
	}
	[delegate_ shareItemShareCancelled:self];
}


- (NSInteger) maxStatusLength
{
	return 140;
}


- (NSString *) itemName
{
	return @"tencent microblog";
}

#pragma mark -
#pragma mark LoginDialogDelegate

- (void)dialogCompleteWithUrl:(NSURL *)url
{
	NSString * verify = [[self valueForIdentify:@"oauth_verifier" ofQuery:[url query]] autorelease];
	if (verify) {
		QWeiboSyncApi *api = [[QWeiboSyncApi alloc] init];
		NSString *retString = [api getAccessTokenWithConsumerKey:TENCENT_CONSUMER_KEY
												  consumerSecret:TENCENT_CONSUMER_SECRET 
												 requestTokenKey:requestToken_.key 
											  requestTokenSecret:requestToken_.secret
														  verify:verify];
		if (retString) {
			[accessToken_ release];
			accessToken_ = [[OAToken alloc] initWithHTTPResponseBody:retString];
			[self storeTencentMBToken:accessToken_];
			[loginDelegate_ itemLoginSucceed:self];//ask the delegate whether should upload after login
		}else {
			NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
			NSError * error = [NSError errorWithDomain:@"TencentErrDomain" code:unknownError userInfo:errorData];
			[delegate_ shareItem:self loginFailed:error]; //feedback unknown error
			accessToken_ = nil;
		}
		[api release];

	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"TencentErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error]; //feedback unknown error
		accessToken_ = nil;
	}
}

/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url
{
	accessToken_ = nil;
	[delegate_ shareItemLoginCancelled:self];
}

- (void)dialog:(LoginDialog*)dialog didFailWithError:(NSError *)error
{
	accessToken_ = nil;
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
#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
	self.responseData = [NSMutableData data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSString *str = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
	NSDictionary * dic = [str JSONValue];
	if (dic) {
		if ([[dic objectForKey:@"msg"] isEqualToString:@"ok"]) {
			[delegate_ shareItemShareSucceed:self];
		}else {
			NSDictionary * errorData = [NSDictionary dictionaryWithObject:[dic objectForKey:@"msg"] forKey:@"error"];
			NSError * error = [NSError errorWithDomain:@"TencentErrDomain" code:[[dic objectForKey:@"errcode"]intValue] userInfo:errorData];
			[delegate_ shareItem:self shareFailed:error];
		}
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"TencentErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self shareFailed:error];
	}
	[str release];
	connection_ = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[delegate_ shareItem:self shareFailed:error];
	connection_ = nil;
}

- (void)dealloc
{
	[responseData_ release];responseData_ = nil;
	[connection_ release];connection_ = nil;
	[accessToken_ release];accessToken_ = nil;
	[requestToken_ release];requestToken_ = nil;
	[super dealloc];
}
@end

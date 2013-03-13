//
//  SohuMB.m
//  SuperShare
//
//  Created by WS12316 on 4/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SohuMB.h"

@interface SohuMB(Private)

- (void) storeSohuMBToken:(OAToken *)access_token;

- (void) getRequestToken;

@end

#pragma mark -

@implementation SohuMB

- (id) init
{
	if (self = [super init]) {
	}
	return self;
}


- (void)dealloc
{
	[accessToken_ release];accessToken_ = nil;
	[requestToken_ release];requestToken_ = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark Private

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
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:SOHU_CONSUMER_KEY
													secret:SOHU_CONSUMER_SECRET];
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	
	NSURL *url = [NSURL URLWithString:@"http://api.t.sohu.com/oauth/request_token"];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:nil
																	  realm:nil
														  signatureProvider:nil];
	[request setHTTPMethod:@"POST"];
	
	NSLog(@"Getting request token...");
	
	[fetcher fetchDataWithRequest:request 
						 delegate:self
				didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];	
	
	[consumer release];
	[request release];
	[fetcher release];
	[pool release];
}


- (void) getAccessTokenWithVerifier:(NSString *)verify
{
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:SOHU_CONSUMER_KEY
													secret:SOHU_CONSUMER_SECRET];
	
	NSURL *url = [NSURL URLWithString:@"http://api.t.sohu.com/oauth/access_token"];
	
	requestToken_.verifier  = [verify copy];
	[verify release]; 
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:requestToken_
																	  realm:nil
														  signatureProvider:nil];
	[request setHTTPMethod:@"POST"];
	
	NSLog(@"Getting request token...");
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	[fetcher fetchDataWithRequest:request 
						 delegate:self
				didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(accessTokenTicket:didFailWithError:)];	
	
	[consumer release];
	[request release];
	[fetcher release];
}


- (OAToken *) accessToken {
	
	if (!accessToken_) {
		NSString * tokenKey = [[NSUserDefaults standardUserDefaults] objectForKey:SOHU_MB_STORED_TOKEN_KEY];
		NSString * tokenSec = [[NSUserDefaults standardUserDefaults] objectForKey:SOHU_MB_STORED_TOKEN_SECRET];
		if (tokenKey && tokenKey) {
			accessToken_ = [[OAToken alloc] initWithKey:tokenKey secret:tokenSec];
		}else {
			accessToken_ = nil;
		}
	}
	return accessToken_;
}


- (void) storeSohuMBToken:(OAToken *)access_token //this string contains the key and secret
{	
	NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
	if (access_token) {
		[defaults setObject: access_token.key forKey: SOHU_MB_STORED_TOKEN_KEY];
		[defaults setObject:access_token.secret forKey: SOHU_MB_STORED_TOKEN_SECRET];
	}else {
		[defaults removeObjectForKey: SOHU_MB_STORED_TOKEN_KEY];
		[defaults removeObjectForKey: SOHU_MB_STORED_TOKEN_SECRET];
	}
	[defaults synchronize];
}

#pragma mark -
#pragma mark Interface

- (BOOL) isUserLogged
{
	if (self.accessToken.key && self.accessToken.secret) {
		return YES;
	}else {
		return NO;
	}
}


- (void) login
{	
	loginDialog_ = [[LoginDialog alloc] initWithURLStr:nil params:nil delegate:self];
	[loginDialog_ setNeedWebView:YES];
	[loginDialog_ setConnectTitle:@"Connect to Sohu"];
	[loginDialog_ setIconImg:[UIImage imageNamed:@"LoginDialog.bundle/icons/sohuweibo.png"]];
	[loginDialog_ show];
	
	[NSThread detachNewThreadSelector:@selector(getRequestToken) toTarget:self withObject:nil];
}


- (void) logout
{
	[self storeSohuMBToken:nil];
	[accessToken_ release];
	accessToken_ = nil;
	
	NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray* facebookCookies = [cookies cookiesForURL:
								[NSURL URLWithString:@"http://api.t.sina.com.cn"]];
	
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
		NSError * error = [NSError errorWithDomain:@"SohuMBErrDomain" code:toomanyWordsError userInfo:errorData];
		[delegate_ shareItem:self shareFailed:error];
	}else {
		[delegate_ shareItemShareBegin:self];
		[self publishStatus:status];
	}
}


- (void) shareLink:(NSString *)linkStr
{
	// the status include the url is just the link
	[delegate_ shareItemShareBegin:self];
	[self publishLink:linkStr];
}


- (void) shareImage:(UIImage *)image withDescription:(NSString *)description
{
	[delegate_ shareItemShareBegin:self];
	[self uploadImage:image withDescription:description];
}


- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"SohuMBErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) cancelShare
{
	[self cancelSharing];
}


- (NSInteger) maxStatusLength
{
	return 100*100*100; //infinit
}


- (NSString *) itemName
{
	return @"sohu microblog";
}


#pragma mark -
#pragma mark LoginDialogDelegate

/**
 * Called when the dialog succeeds with a returning url.
 */

- (void)dialogCompleteWithUrl:(NSURL *)url
{
	NSString * verify = [self valueForIdentify:@"oauth_verifier" ofQuery:[url query]];
	if (verify) {
		[self getAccessTokenWithVerifier:verify];
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"SohuErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error]; //feedback unknown error
		accessToken_ = nil;
	}
}

//Called when the dialog get canceled by the user.

- (void)dialogDidNotCompleteWithUrl:(NSURL *)url
{
	if ([loginDialog_ alpha]) {
		[delegate_ shareItemLoginCancelled:self];
	}
}


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
#pragma mark AuthorizationDelegate

- (void) requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed)
	{
		NSString *responseBody = [[NSString alloc] initWithData:data 
													   encoding:NSUTF8StringEncoding];
		requestToken_ = [[OAToken alloc] initWithHTTPResponseBody:responseBody]; //it's the request token on this step
		[responseBody release];
		NSLog(@"Got request token. Redirecting to twitter auth page...");
		
		NSString *authorizeUrlStr = [NSString stringWithFormat:
									 @"http://api.t.sohu.com/oauth/authorize?oauth_token=%@",requestToken_.key];
		
		[loginDialog_ setServerURL:authorizeUrlStr];
		[loginDialog_ load];
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"SohuErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error];
	}

}


- (void) requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[loginDialog_ dismissWithError:error animated:YES];
}


- (void) accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed)
	{
		NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		[accessToken_ release];
		accessToken_ = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[responseBody release];
		[self storeSohuMBToken:accessToken_];
		NSLog(@"Got access token,Ready to use Sohu API.");
		[loginDelegate_ itemLoginSucceed:self];//ask the delegate whether should upload after login
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"SohuErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error];
	}

}

- (void) accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[delegate_ shareItem:self loginFailed:error];
}

@end

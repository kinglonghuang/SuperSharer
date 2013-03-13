//
//  TwitterConnect.m
//  TwitterConnect
//
//  Created by kinglong on 10/11/30.
//  Copyright 2010 wondershare. All rights reserved.
//

#import "Twitter.h"

@interface Twitter(Private)

- (void) getRequestToken;

- (NSString*)valueForIdentify:(NSString *)indentfy ofQuery:(NSString*)query;

- (GSTwitPicEngine *)twitterEngine;

- (void)startShare:(NSString *)shareStr;

- (void) storeTwitterMBToken:(OAToken *)access_token;

@end


@implementation Twitter

- (id) init
{
	if (self = [super init]) {
	}
	return self;
}


- (void) dealloc
{
	[accessToken_ release];accessToken_ = nil;
	[requestToken_ release];requestToken_ = nil;
	[super dealloc];
}


- (OAToken *) accessToken {
	
	if (!accessToken_) {
		NSString * tokenKey = [[NSUserDefaults standardUserDefaults] objectForKey:TWITTER_STORED_TOKEN_KEY];
		NSString * tokenSec = [[NSUserDefaults standardUserDefaults] objectForKey:TWITTER_STORED_TOKEN_SECRET];
		if (tokenKey && tokenKey) {
			accessToken_ = [[OAToken alloc] initWithKey:tokenKey secret:tokenSec];
		}else {
			accessToken_ = nil;
		}
	}
	return accessToken_;
}

#pragma mark -
#pragma mark Private

- (GSTwitPicEngine *) twitterEngine
{
	if (!twitterEngine_) {
		twitterEngine_ = [[GSTwitPicEngine alloc] initWithDelegate:self];
	}
	return twitterEngine_;
}

- (void)startShare:(NSString *)shareStr
{
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:TWITTER_CONSUMER_KEY
													secret:TWITTER_CONSUMER_SECRET];
	
	NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.xml"];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:accessToken_
																	  realm:nil
														  signatureProvider:nil];
	[request setHTTPMethod:@"POST"];
	[request setTimeoutInterval:NETWORK_TIMEOUT_INTERVAL];
	OARequestParameter * statusParam = [[OARequestParameter alloc] initWithName:@"status" value:shareStr];
	NSArray * paramArray = [NSArray arrayWithObject:statusParam];
	[statusParam release];
	[request setParameters:paramArray];
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	[fetcher fetchDataWithRequest:request 
						 delegate:self
				didFinishSelector:@selector(apiTicket:didFinishWithData:)
				  didFailSelector:@selector(apiTicket:didFailWithError:)];	
	
	[consumer release];
	[request release];
	[fetcher release];
}

- (void) getRequestToken
{
	NSAutoreleasePool  * pool = [[NSAutoreleasePool alloc] init];
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:TWITTER_CONSUMER_KEY
													secret:TWITTER_CONSUMER_SECRET];
		
	NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:nil
																	  realm:nil
														  signatureProvider:nil];
	[request setHTTPMethod:@"POST"];
	
	NSLog(@"Getting request token...");
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	[fetcher fetchDataWithRequest:request 
						 delegate:self
				didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
				  didFailSelector:@selector(requestTokenTicket:didFailWithError:)];	

	[consumer release];
	[request release];
	[fetcher release];
	
	[pool release];
}

- (void) storeTwitterMBToken:(OAToken *)access_token //this string contains the key and secret
{	
	NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
	if (access_token) {
		[defaults setObject: access_token.key forKey: TWITTER_STORED_TOKEN_KEY];
		[defaults setObject:access_token.secret forKey: TWITTER_STORED_TOKEN_SECRET];
	}else {
		[defaults removeObjectForKey: TWITTER_STORED_TOKEN_KEY];
		[defaults removeObjectForKey: TWITTER_STORED_TOKEN_SECRET];
	}
	[defaults synchronize];
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

#pragma mark -
#pragma mark Interface

- (BOOL) isUserLogged
{
	return (self.accessToken != nil);
}


- (void) login
{
	loginDialog_ = [[LoginDialog alloc] initWithURLStr:nil params:nil delegate:self];
	[loginDialog_ setNeedWebView:YES];
	[loginDialog_ setConnectTitle:@"Connect to Twitter"];
	[loginDialog_ setIconImg:[UIImage imageNamed:@"LoginDialog.bundle/icons/twitter.png"]];
	[loginDialog_ show];
	
	[NSThread detachNewThreadSelector:@selector(getRequestToken) toTarget:self withObject:nil];
}

- (void) logout
{
	[self storeTwitterMBToken:nil];
	[accessToken_ release];
	accessToken_ = nil;
	
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
	return YES;
}


- (void) shareStatus:(NSString *)status
{
	if ([status length] > [self maxStatusLength]) {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Too many status words" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"TwitterErrDomain" code:toomanyWordsError userInfo:errorData];
		[delegate_ shareItem:self shareFailed:error];
	}else {
		[self startShare:status];
	}
}


- (void) shareLink:(NSString *)linkStr
{
	[self startShare:linkStr];
}


- (void) shareImage:(UIImage *)image withDescription:(NSString *)description
{
	[[self twitterEngine]  uploadPicture:image withMessage:description];
}


- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description
{
	[[self twitterEngine]  uploadVideo:videoData withMessage:description];
}


- (void) cancelShare
{
	[[self twitterEngine] cancelShare];
	[delegate_ shareItemShareCancelled:self];
}


- (NSInteger) maxStatusLength
{
	return 140;
}


- (NSString *) itemName
{
	return @"twitter";
}


#pragma mark -
#pragma mark uploadDelegate

- (void)twitpicDidFinishUpload:(NSDictionary *)response {
	[delegate_ shareItemShareSucceed:self];
	
}

- (void)twitpicDidFailUpload:(NSDictionary *)errorDic {
	NSError * error = [errorDic objectForKey:@"error"];
	if (error) {
		[delegate_ shareItem:self shareFailed:error];
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"TwitterErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self shareFailed:error];
	}
}

#pragma mark -
#pragma mark AuthorizationDelegate

- (void) requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed)
	{
		NSString *responseBody = [[NSString alloc] initWithData:data 
													   encoding:NSUTF8StringEncoding];
		requestToken_ = [[OAToken alloc] initWithHTTPResponseBody:responseBody]; //it's the request token on thsi step
		[responseBody release];
		NSLog(@"Got request token. Redirecting to twitter auth page...");
		
		NSString *authorizeUrlStr = [NSString stringWithFormat:
									 @"https://api.twitter.com/oauth/authorize?oauth_token=%@&%@",
									 requestToken_.key,@"display=touch"];
		
		[loginDialog_ setServerURL:authorizeUrlStr];
		[loginDialog_ load];
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"TwitterErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error];
	}
}


- (void) requestTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[loginDialog_ dismissWithError:error animated:YES];
	[delegate_ shareItem:self loginFailed:error];
}


- (void) accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed)
	{
		NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		[accessToken_ release];
		accessToken_ = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[responseBody release];
		[self storeTwitterMBToken:accessToken_];
		[[self twitterEngine] setAccessToken:accessToken_];
		NSLog(@"Got access token. Ready to use Twitter API.");
		
		[loginDelegate_ itemLoginSucceed:self];//ask the delegate whether should upload after login
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"TwitterErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error];
	}

}


- (void) accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[delegate_ shareItem:self loginFailed:error];
}

#pragma mark -
#pragma mark APIDelegate

- (void) apiTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed)
	{
		[delegate_ shareItemShareSucceed:self];
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"TwitterErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self shareFailed:error];
	}
}

- (void) apiTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[delegate_ shareItem:self shareFailed:error];	
}


#pragma mark -
#pragma mark LoginDialogDelegate

- (void)dialogCompleteWithUrl:(NSURL *)url
{
	NSString * verify = [self valueForIdentify:@"oauth_verifier" ofQuery:[url query]];
	if (verify) {
		requestToken_.verifier = [verify copy];
		NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
		OAConsumer *consumer = [[OAConsumer alloc] initWithKey:TWITTER_CONSUMER_KEY
														secret:TWITTER_CONSUMER_SECRET];
		OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																	   consumer:consumer
																		  token:requestToken_
																		  realm:nil
															  signatureProvider:nil];
		
		[request setHTTPMethod:@"POST"];
		
		NSLog(@"Getting access token...");
		OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
		[fetcher fetchDataWithRequest:request 
							 delegate:self
					didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
					  didFailSelector:@selector(accessTokenTicket:didFailWithError:)];	
		[request release];
		[consumer release];
		
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"TencentErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error]; 
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

@end

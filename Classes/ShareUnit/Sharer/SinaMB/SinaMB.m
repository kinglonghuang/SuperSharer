//
//  SinaMBEngine.m
//  SuperShare
//
//  Created by WS12316 on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SinaMB.h"
#import "JSON.h"

@interface SinaMB(Private)

- (void)storeSinaMBToken:(OAToken *)access_token;

- (void) getRequestToken;

- (void) getAccessTokenWithAuthorizeCode:(NSString *)code;

@end

#pragma mark -

@implementation SinaMB

- (id) init
{
	if (self = [super init]) {
	}
	return self;
}

- (OAToken *) accessToken {
	
	if (!accessToken_) {
//		NSString * tokenKey = [[NSUserDefaults standardUserDefaults] objectForKey:SINA_MB_STORED_TOKEN_KEY];
//		NSString * tokenSec = [[NSUserDefaults standardUserDefaults] objectForKey:SINA_MB_STORED_TOKEN_SECRET];
//		if (tokenKey && tokenKey) {
//			accessToken_ = [[OAToken alloc] initWithKey:tokenKey secret:tokenSec];
//		}else {
//			accessToken_ = nil;
//		}
        accessToken_ = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"SuperSharer" prefix:@"KLStudio"];
	}
	return accessToken_;
}

- (WeiboClient*)sinaMBClient
{
	if (!sinaMBClient_) {
		sinaMBClient_ = [[WeiboClient alloc] initWithTarget:self 
													 token:self.accessToken
													 action:@selector(postStatusDidSucceed:obj:)];
	}
	return sinaMBClient_;
}


- (void)dealloc
{
	[accessToken_ release];accessToken_ = nil;
	[requestToken_ release];requestToken_ = nil;
	[sinaMBClient_ release];sinaMBClient_ = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark Private

- (void)storeSinaMBToken:(OAToken *)access_token //this string contains the key and secret
{
    if (access_token) {
        [access_token storeInUserDefaultsWithServiceProviderName:@"SuperSharer" prefix:@"KLStudio"];
    }else {
        [OAToken signOutWithServiceProviderName:@"SuperSharer" prefix:@"KLStudio"];
    }

}


- (void) getRequestToken
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:SINA_CONSUMER_KEY
													secret:SINA_CONSUMER_SECRET];
	
	NSURL *url = [NSURL URLWithString:@"http://api.t.sina.com.cn/oauth/request_token"];
	
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


- (void) getAccessTokenWithAuthorizeCode:(NSString *)code
{
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:SINA_CONSUMER_KEY, @"client_id",
                            SINA_CONSUMER_SECRET, @"client_secret",
                            @"authorization_code", @"grant_type",
                            SINA_CALLBACK_ADD, @"redirect_uri",
                            code, @"code", nil];
    
    NSString *urlString = [SinaMB serializeURL:kWBAccessTokenURL
                                        params:params
                                    httpMethod:@"POST"];
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    NSMutableData * body = [NSMutableData dataWithCapacity:0];
    [body appendData:[[SinaMB stringFromDictionary:params] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:body];
    [request setHTTPMethod:@"POST"];
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    NSString *dataString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    id accessTokenInfo = [dataString JSONValue];
    if ([accessTokenInfo isKindOfClass:[NSDictionary class]] && [(NSDictionary *)accessTokenInfo allKeys])
	{
        NSDictionary * dic = (NSDictionary *)accessTokenInfo;
        NSTimeInterval expirateSeconds = [[dic objectForKey:@"expires_in"] doubleValue];
        NSDate * expirateDate = [NSDate dateWithTimeIntervalSinceNow:expirateSeconds];
        NSString * token = [dic objectForKey:@"access_token"];
        [accessToken_ release];
        accessToken_ = [[OAToken alloc] init];
        accessToken_.key = token;
        accessToken_.expirationDate = expirateDate;
        [self storeSinaMBToken:accessToken_];
        [[self sinaMBClient] setAccessToken:accessToken_.key];
        [loginDelegate_ itemLoginSucceed:self];//ask the delegate whether should upload after login
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"SinaMBErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error];
	}
}

+ (NSString *)stringFromDictionary:(NSDictionary *)dict
{
    NSMutableArray *pairs = [NSMutableArray array];
	for (NSString *key in [dict keyEnumerator])
	{
		if (!([[dict valueForKey:key] isKindOfClass:[NSString class]]))
		{
			continue;
		}
		
		[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, [[dict objectForKey:key] URLEncodedString]]];
	}
	
	return [pairs componentsJoinedByString:@"&"];
}

+ (NSString *)serializeURL:(NSString *)baseURL params:(NSDictionary *)params httpMethod:(NSString *)httpMethod
{
    if (![httpMethod isEqualToString:@"GET"])
    {
        return baseURL;
    }
    
    NSURL *parsedURL = [NSURL URLWithString:baseURL];
	NSString *queryPrefix = parsedURL.query ? @"&" : @"?";
	NSString *query = [self stringFromDictionary:params];
	
	return [NSString stringWithFormat:@"%@%@%@", baseURL, queryPrefix, query];
}

#pragma mark -
#pragma mark Interface

- (BOOL)isUserLogged
{
    BOOL isSessionValid = (self.accessToken && self.accessToken.expirationDate != nil
                           && NSOrderedDescending == [self.accessToken.expirationDate compare:[NSDate date]]);
	return isSessionValid;
}


- (void) login
{	
	loginDialog_ = [[LoginDialog alloc] initWithURLStr:nil params:nil delegate:self];
	[loginDialog_ setNeedWebView:YES];
	[loginDialog_ setConnectTitle:@"Connect to Sina"];
	[loginDialog_ setIconImg:[UIImage imageNamed:@"LoginDialog.bundle/icons/sinaweibo.png"]];
	[loginDialog_ show];
	
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:SINA_CONSUMER_KEY, @"client_id",
                            @"code", @"response_type",
                            @"http://www.sinafeedback.com", @"redirect_uri",
                            @"mobile", @"display", nil];
    NSString *urlString = [SinaMB serializeURL:kWBAuthorizeURL
                                           params:params
                                       httpMethod:@"GET"];
    [loginDialog_ setServerURL:urlString];
    [loginDialog_ load];
    
	//[NSThread detachNewThreadSelector:@selector(getRequestToken) toTarget:self withObject:nil];
}


- (void) logout
{
	[self storeSinaMBToken:nil];
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
		NSError * error = [NSError errorWithDomain:@"SinaMBErrDomain" code:toomanyWordsError userInfo:errorData];
		[delegate_ shareItem:self shareFailed:error];
	}else {
		[delegate_ shareItemShareBegin:self];
		[self.sinaMBClient post:status];
	}
}


- (void) shareLink:(NSString *)linkStr
{
	// the status include the url is just the link
	[delegate_ shareItemShareBegin:self];
	[self.sinaMBClient post:linkStr];
}


- (void) shareImage:(UIImage *)image withDescription:(NSString *)description
{
	[delegate_ shareItemShareBegin:self];
	
	NSData * imageData = UIImageJPEGRepresentation(image, 1.0);
	[self.sinaMBClient upload:imageData status:description];
}


- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"SinaMBErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}

- (void) cancelShare
{
	[self.sinaMBClient cancel];
	[delegate_ shareItemShareCancelled:self];
}

- (NSInteger) maxStatusLength
{
	return 140;
}

- (NSString *) itemName
{
	return @"sina microblog";
}


#pragma mark -
#pragma mark LoginDialogDelegate

- (void)dialog:(LoginDialog*)dialog getAccessTokenWithAuthorizeCode:(NSString *)code;
{
	[self getAccessTokenWithAuthorizeCode:code];
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
#pragma mark APIDelegate

- (void)postStatusDidSucceed:(WeiboClient*)sender obj:(NSObject*)obj
{
	if (!obj) {
		[delegate_ shareItemShareSucceed:self];
	}else if ([obj isKindOfClass:[NSError class]]) {
		[delegate_ shareItem:self shareFailed:(NSError*)obj];
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
		
		requestToken_ = [[OAToken alloc] initWithHTTPResponseBody:responseBody]; //it's the request token on this step
		
		[responseBody release];
		
		NSLog(@"Got request token. Redirecting to twitter auth page...");
		
		NSString *authorizeUrlStr = [NSString stringWithFormat:
									 @"http://api.t.sina.com.cn/oauth/authorize?oauth_token=%@&%@",
									 requestToken_.key,@"display=touch"];		
		[loginDialog_ setServerURL:authorizeUrlStr];
		[loginDialog_ load];
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"SinaMBErrDomain" code:unknownError userInfo:errorData];
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
		
		[self storeSinaMBToken:accessToken_];
		NSLog(@"Got access token,Ready to use Twitter API.");
		
		[loginDelegate_ itemLoginSucceed:self];//ask the delegate whether should upload after login
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"SinaMBErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error];
	}

}

- (void) accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[delegate_ shareItem:self loginFailed:error];
}

@end

//
//  Instapaper.m
//  SuperShare
//
//  Created by WS12316 on 4/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Instapaper.h"
@interface Instapaper (Private)

- (void) storeInstapaperToken:(OAToken *)access_token;

- (void) getXAuthAccessTokenWithUserInfo:(NSDictionary *)userInfoDic;

@end


@implementation Instapaper

- (OAToken *) accessToken {
	
	if (!accessToken_) {
		NSString * tokenKey = [[NSUserDefaults standardUserDefaults] objectForKey:INSTAPAPER_STORED_TOKEN_KEY];
		NSString * tokenSec = [[NSUserDefaults standardUserDefaults] objectForKey:INSTAPAPER_STORED_TOKEN_SECRET];
		if (tokenKey && tokenKey) {
			accessToken_ = [[OAToken alloc] initWithKey:tokenKey secret:tokenSec];
		}else {
			accessToken_ = nil;
		}
	}
	return accessToken_;
}


- (void) dealloc
{
	[accessToken_ release];accessToken_ = nil;
	[super dealloc];
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
	[loginDialog_ setNeedWebView:NO];
	[loginDialog_ setConnectTitle:@"Instapaper Login"];
	[loginDialog_ setIconImg:[UIImage imageNamed:@"LoginDialog.bundle/icons/instapaper.png"]];
	[loginDialog_ setLoginViewBgImage:[UIImage imageNamed:@"instapaperLoginBgImage.png"]];
	[loginDialog_ show];
}


- (void) logout
{
	[self storeInstapaperToken:nil];
	[accessToken_ release];
	accessToken_ = nil;
	
	[delegate_ shareItemLogoutSucceed:self];
}


- (BOOL) canShareStatus
{
	return NO;
}


- (BOOL) canShareLink
{
	return YES;
}


- (BOOL) canShareImage
{
	return NO;
}


- (BOOL) canShareVideo
{
	return NO;
}


- (void) shareStatus:(NSString *)status
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"InstapaperErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) shareLink:(NSString *)linkStr
{
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:INSTAPAPER_CONSUMER_KEY
													secret:INSTAPAPER_CONSUMER_SECRET];
	
	NSURL *url = [NSURL URLWithString:@"http://www.instapaper.com/api/1/bookmarks/add"];

	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:accessToken_
																	  realm:nil
														  signatureProvider:nil];
	
	NSLog(@"beginToPublish...");
	
	[request setHTTPMethod:@"POST"];
	
	OARequestParameter * linkURLParam = [[OARequestParameter alloc] initWithName:@"url" value:linkStr];
	NSArray *params = [NSArray arrayWithObjects:linkURLParam,nil];
	[request setParameters:params];
	[linkURLParam release];
	
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
	[fetcher fetchDataWithRequest:request 
						 delegate:self
				didFinishSelector:@selector(apiTicket:didFinishWithData:)
				  didFailSelector:@selector(apiTicket:didFailWithError:)];
	
	[consumer release];
	[request release];
	[fetcher release];
}


- (void) shareImage:(UIImage *)image withDescription:(NSString *)description
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"InstapaperErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) shareVideo:(NSData *)videoData withDescription:(NSString *)description
{
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Data type not supported by the Specific item" forKey:@"error"];
	NSError * error = [NSError errorWithDomain:@"InstapaperErrDomain" code:dataTypeNotSupportedError userInfo:errorData];
	[delegate_ shareItem:self shareFailed:error];
}


- (void) cancelShare
{
	
}


- (NSInteger) maxStatusLength
{
	return -1;
}


- (NSString *) itemName
{
	return @"Instapaper";
}

#pragma mark -
#pragma mark Private

- (void) storeInstapaperToken:(OAToken *)access_token //this string contains the key and secret
{	
	NSUserDefaults*defaults = [NSUserDefaults standardUserDefaults];
	if (access_token) {
		[defaults setObject: access_token.key forKey: INSTAPAPER_STORED_TOKEN_KEY];
		[defaults setObject:access_token.secret forKey: INSTAPAPER_STORED_TOKEN_SECRET];
	}else {
		[defaults removeObjectForKey: INSTAPAPER_STORED_TOKEN_KEY];
		[defaults removeObjectForKey: INSTAPAPER_STORED_TOKEN_SECRET];
	}
	[defaults synchronize];
}


- (void) getXAuthAccessTokenWithUserInfo:(NSDictionary *)userInfoDic
{
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:INSTAPAPER_CONSUMER_KEY
													secret:INSTAPAPER_CONSUMER_SECRET];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://www.instapaper.com/api/1/oauth/access_token"]
																   consumer:consumer
																	  token:nil // xAuth needs no request token?
																	  realm:nil   // our service provider doesn't specify a realm
														  signatureProvider:nil]; // use the default method, HMAC-SHA1
	
	[request setHTTPMethod:@"POST"];
	[request setParameters:[NSArray arrayWithObjects:
							[OARequestParameter requestParameterWithName:@"x_auth_mode" value:@"client_auth"],
							[OARequestParameter requestParameterWithName:@"x_auth_username" value:[userInfoDic objectForKey:@"userName"]],
							[OARequestParameter requestParameterWithName:@"x_auth_password" value:[userInfoDic objectForKey:@"pwd"]],nil]];	
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



#pragma mark -
#pragma mark AuthorizationDelegate

- (void) accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed) {
		NSString *responseBody = [[NSString alloc] initWithData:data 
													   encoding:NSUTF8StringEncoding];
		[accessToken_ release];
		accessToken_ = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[self storeInstapaperToken:accessToken_];
		[responseBody release];
		[loginDelegate_ itemLoginSucceed:self];//ask the delegate whether should upload after login
	}else {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
		NSError * error = [NSError errorWithDomain:@"InstapaperErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self loginFailed:error];
	}
	[loginDialog_ authrizeFeedbackStatus:YES error:nil];
}


- (void) accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	//if the authorization failed,we think it as the user input the incorrect name/password,feedback to the loginView's lable
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Invalid UserName or Password?" forKey:@"error"];
	NSError * customizeError = [NSError errorWithDomain:@"InstapaperErrDomain" code:unknownError userInfo:errorData];
	[loginDialog_ authrizeFeedbackStatus:NO error:customizeError];
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
		NSError * error = [NSError errorWithDomain:@"InstapaperErrDomain" code:unknownError userInfo:errorData];
		[delegate_ shareItem:self shareFailed:error];
	}
}

- (void) apiTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[delegate_ shareItem:self shareFailed:error];
}

#pragma mark -
#pragma mark LoginDialogDelegate
/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url
{
	[delegate_ shareItemLoginCancelled:self];
}


- (void)dialog:(LoginDialog*)dialog loginWithUserName:(NSString*)userName andPwd:(NSString*)pwd
{
	NSDictionary * userInfoDic = [NSDictionary dictionaryWithObjectsAndKeys:userName,@"userName",pwd,@"pwd",nil];
	[self performSelector:@selector(getXAuthAccessTokenWithUserInfo:) withObject:userInfoDic afterDelay:0.0];	
}


- (void)dialogCancelBtnClicked;
{
	[delegate_ shareItemLoginCancelled:self];
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

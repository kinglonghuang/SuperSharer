//
//  ReadItLaterEngine.m
//  ReadItLaterAPI
//  Version 1.0
//
//  Created by Nathan Weiner on 5/9/09.
//  Copyright 2009 Idea Shower. All rights reserved.
//

#import "ReadItLaterEngine.h"

@implementation ReadItLaterEngine

static NSString *apikey = @"c25dej75T0958b7e1cAq159A48gPQb21";			//Enter your apikey here : get one at http://readitlaterlist.com/api/ 
//static NSString *nameOfYourApp = @"";		//Enter the name of your application here (optional - for user-agent string)




@synthesize delegate, method, apiResponse, requestData, stringResponse;

/* -----------------
 
	SEE THE ReadItLaterLite.h FILE FOR COMMENTS/DOCUMENTATION
	ADDITIONAL DOCUMENTATION, SCREENSHOTS, EXAMPLES ARE AVAILABLE AT:
	http://readitlaterlist.com/api_iphone/
 
-------------------- */


- (void)dealloc {
	[method release];
	[apiResponse release];
	[requestData release];
	[stringResponse release];
	[connection_ cancel];
	[connection_ release];connection_ = nil;
    [super dealloc];
}


/* ----------------------------------- */

// Saving Methods, see ReadItLaterLite.h for comments/documentation

- (void)save:(NSURL *)url title:(NSString *)title delegate:(id)RILdelegate {
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	NSString * storedUserName = [prefs objectForKey:RIL_StoredUserName];
	NSString * storedPwd	  = [prefs objectForKey:RIL_StoredPwd];
	NSString * userName       = [DES_Base64Helper tripleDES:storedUserName encryptOrDecrypt:kCCDecrypt key:RIL_EncryptKey];
	NSString * pwd			  = [DES_Base64Helper tripleDES:storedPwd encryptOrDecrypt:kCCDecrypt key:RIL_EncryptKey];
	
	
	[self save:url title:title delegate:RILdelegate username:userName password:pwd];

	
}


- (void)save:(NSURL *)url title:(NSString *)title delegate:(id)RILdelegate username:(NSString *)username password:(NSString *)password {
	
	self.delegate = RILdelegate;
//	[self sendRequest:@"add" username:username password:password params:[NSString stringWithFormat:@"url=%@&title=%@", [ReadItLaterEngine encode:[url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], [ReadItLaterEngine encode:[title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] ]];
// We don't set the title.let the server use default process;	
	[self sendRequest:@"add" username:username password:password params:[NSString stringWithFormat:@"url=%@", [ReadItLaterEngine encode:[url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
}

- (void)authWithUsername:(NSString *)username password:(NSString *)password delegate:(id)RILdelegate {
	
	self.delegate = RILdelegate;
	[self sendRequest:@"auth" username:username password:password params:nil];
	
}

- (void)signupWithUsername:(NSString *)username password:(NSString *)password delegate:(id)RILdelegate {
	
	self.delegate = RILdelegate;
	[self sendRequest:@"signup" username:username password:password params:nil];
	
}


- (void)cancelUpload
{
	[connection_ cancel];
	[connection_ release];connection_ = nil;
	[delegate readItLaterShareCancelled];
}

@end

#pragma mark -

@implementation ReadItLaterEngine (Private)

-(void)sendRequest:(NSString *)newMethod username:(NSString *)username password:(NSString *)password params:(NSString *)additionalParams {
	
	self.method = newMethod;
	requestData = [[NSMutableData alloc] initWithLength:0];
	
	// Create Request
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://readitlaterlist.com/v2/%@", method]];
	NSMutableURLRequest *request =  [ [NSMutableURLRequest alloc] initWithURL:url
												  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
											  timeoutInterval:90];
	

	// Setup Request Data/Params
	NSMutableString *params = [NSMutableString stringWithFormat:@"apikey=%@&username=%@&password=%@", apikey, [ReadItLaterEngine encode:username], [ReadItLaterEngine encode:password]];
	if (additionalParams != nil) {
		[params appendFormat:@"&%@", additionalParams];
	}
	NSData *paramsData = [ NSData dataWithBytes:[params UTF8String] length:[params length] ];
	
	// Fill Request
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:paramsData];
	[request setTimeoutInterval:NETWORK_TIMEOUT_INTERVAL];
	
	// Start Connection
	connection_ = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
	
	[request release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	
	self.apiResponse = [[response allHeaderFields] mutableCopy];
	[apiResponse setObject:[NSNumber numberWithInt:[response statusCode]] forKey:@"statusCode"];
	[apiResponse release];
	
	[requestData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[requestData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

	self.stringResponse = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
	[requestData release]; requestData = nil;
	[self.stringResponse release];
	
	[self finishConnection];
	[connection_ release];connection_ = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.apiResponse = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:@"X-Error"];
	self.apiResponse = nil;
	[self finishConnection];
	[connection_ release];connection_ = nil;
}

-(void)finishConnection {
	
	// Determine Result
	NSNumber * code = [apiResponse objectForKey:@"statusCode"];
	NSInteger statusCode = [code intValue];

	NSError * error = nil;
	if (statusCode != 200) {
		NSDictionary * errorData = [NSDictionary dictionaryWithObject:[apiResponse objectForKey:@"X-Error"] forKey:@"error"];
		error = [NSError errorWithDomain:@"ReadItLaterErrDomain" code:statusCode userInfo:errorData];
	}
	
	// Send to delegate
	SEL selector;
	
	if ([method isEqualToString:@"auth"]) 
	{
		selector = @selector(readItLaterLoginFinished:error:);
	}
	else if ([method isEqualToString:@"signup"]) 
	{
		selector = @selector(readItLaterSignupFinished:error:);
	}
	else if ([method isEqualToString:@"add"]) 
	{
		selector = @selector(readItLaterSaveFinished:error:);
	}
	
	if ([delegate respondsToSelector:selector]) {
		[delegate performSelector:selector withObject:stringResponse withObject:error];
	}
	
}

/* --- */

+(NSString *)encode:(NSString *)string {
	CFStringRef encoded = CFURLCreateStringByAddingPercentEscapes(
															  kCFAllocatorDefault, 
															  (CFStringRef) string, 
															  nil, 
															  (CFStringRef)@"&#38;+", 
															  kCFStringEncodingUTF8);  
	return [((NSString*) encoded) autorelease];
}

@end

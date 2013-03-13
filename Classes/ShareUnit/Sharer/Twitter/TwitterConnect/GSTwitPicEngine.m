//
//  GSTwitPicEngine.m
//  TwitPic Uploader
//
//  Created by Gurpartap Singh on 19/06/10.
//  Copyright 2010 Gurpartap Singh. All rights reserved.
//

#import "GSTwitPicEngine.h"
#import "JSON.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

#import "OAConsumer.h"

@implementation GSTwitPicEngine

@synthesize _queue;

+ (GSTwitPicEngine *)twitpicEngineWithDelegate:(NSObject *)theDelegate {
  return [[[self alloc] initWithDelegate:theDelegate] autorelease];
}


- (GSTwitPicEngine *)initWithDelegate:(id)delegate {
  if (self = [super init]) {
    _delegate = delegate;
    _queue = [[ASINetworkQueue alloc] init];
    [_queue setMaxConcurrentOperationCount:1];
    [_queue setShouldCancelAllRequestsOnFailure:NO];
    [_queue setDelegate:self];
    [_queue setRequestDidFinishSelector:@selector(requestFinished:)];
    [_queue setRequestDidFailSelector:@selector(requestFailed:)];
  }
  
  return self;
}


- (void)dealloc {
     _delegate = nil;
	[_queue release];_queue = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Instance methods

- (BOOL)_isValidDelegateForSelector:(SEL)selector {
	return ((_delegate != nil) && [(NSObject*)_delegate respondsToSelector:selector]);
}


- (void)uploadPicture:(UIImage *)picture {
  [self uploadPicture:picture withMessage:@""];
}


- (void)uploadPicture:(UIImage *)picture withMessage:(NSString *)message {
  
	NSURL *url = [NSURL URLWithString:@"http://api.twitpic.com/1/uploadAndPost.json"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];

	[request setPostValue:TWITPIC_API_KEY forKey:@"key"];
	[request setPostValue:TWITTER_CONSUMER_KEY forKey:@"consumer_token"];
	[request setPostValue:TWITTER_CONSUMER_SECRET forKey:@"consumer_secret"];
	[request setPostValue:[_accessToken key] forKey:@"oauth_token"];
	[request setPostValue:[_accessToken secret] forKey:@"oauth_secret"];
	[request setPostValue:message forKey:@"message"];
	[request setData:UIImageJPEGRepresentation(picture, 0.8) forKey:@"media"];
	request.requestMethod = @"POST";
	[request setTimeOutSeconds:NETWORK_TIMEOUT_INTERVAL];

	[_queue addOperation:request];
	[_queue go];
}


- (void)uploadVideo:(NSData *)videoData withMessage:(NSString *)message
{
	NSURL *url = [NSURL URLWithString:@"http://api.twitpic.com/1/uploadAndPost.json"];
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	
	[request setPostValue:TWITPIC_API_KEY forKey:@"key"];
	[request setPostValue:TWITTER_CONSUMER_KEY forKey:@"consumer_token"];
	[request setPostValue:TWITTER_CONSUMER_SECRET forKey:@"consumer_secret"];
	[request setPostValue:[_accessToken key] forKey:@"oauth_token"];
	[request setPostValue:[_accessToken secret] forKey:@"oauth_secret"];
	[request setPostValue:message forKey:@"message"];
	[request setData:videoData forKey:@"media"];
	request.requestMethod = @"POST";
	[request setTimeOutSeconds:NETWORK_TIMEOUT_INTERVAL];
	[_queue addOperation:request];
	[_queue go];
}


- (void) cancelShare
{
	[_queue reset];
}

#pragma mark -
#pragma mark OAuth

- (void)setAccessToken:(OAToken *)token {
	[_accessToken autorelease];
	_accessToken = [token retain];
}


#pragma mark -
#pragma mark ASIHTTPRequestDelegate methods

- (void)requestFinished:(ASIHTTPRequest *)request {
  // TODO: Pass values as individual parameters to delegate methods instead of wrapping in NSDictionary.
  NSMutableDictionary *delegateResponse = [[[NSMutableDictionary alloc] init] autorelease];
  
  [delegateResponse setObject:request forKey:@"request"];
  
  switch ([request responseStatusCode]) {
    case 200:
    {
      NSDictionary *response;
      NSString *responseString = nil;
      responseString = [request responseString];
      response = [responseString JSONValue];
		
      if ([response count]) {
		  [delegateResponse setObject:response forKey:@"resultDic"];
	  }
      
      if ([self _isValidDelegateForSelector:@selector(twitpicDidFinishUpload:)]) {
        [_delegate twitpicDidFinishUpload:delegateResponse];
      }
      break;
    }
    case 400:
	  {
		  // Failed.
		  NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Bad request" forKey:@"error_msg"];
		  NSError * error = [NSError errorWithDomain:@"twitterErrDomain"
												code:604
											userInfo:errorData];
		  [delegateResponse setObject:error forKey:@"error"];
      
		  if ([self _isValidDelegateForSelector:@selector(twitpicDidFailUpload:)]) {
			  [_delegate twitpicDidFailUpload:delegateResponse];
		  }
      
      break;
	  }
    default:
	  {
		  NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error_msg"];
		  NSError * error = [NSError errorWithDomain:@"twitterErrDomain"
											code:606
										userInfo:errorData];
		  [delegateResponse setObject:error forKey:@"error"];

		  if ([self _isValidDelegateForSelector:@selector(twitpicDidFailUpload:)]) {
			  [_delegate twitpicDidFailUpload:delegateResponse];
		  }
		  break;
	  }
  }
}


- (void)requestFailed:(ASIHTTPRequest *)request {
  NSMutableDictionary *delegateResponse = [[[NSMutableDictionary alloc] init] autorelease];
  
  [delegateResponse setObject:request forKey:@"request"];

  switch ([request responseStatusCode]) {
		  
	  case 401:
	  {
		  NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Authentication Failed" forKey:@"error_msg"];
		  NSError * error = [NSError errorWithDomain:@"twitterErrDomain"
												code:601
											userInfo:errorData];
		  
		  [delegateResponse setObject:error forKey:@"error"];
		  
		  break;
	  }
		  
	  case 0:
	  {
		  NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Connection Failed" forKey:@"error_msg"];
		  NSError * error = [NSError errorWithDomain:@"twitterErrDomain"
												code:607
											userInfo:errorData];
		  
		  [delegateResponse setObject:error forKey:@"error"];
		  
		  break;
	  }
	  
	  default:
	  {
		  NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error_msg"];
		  NSError * error = [NSError errorWithDomain:@"twitterErrDomain"
												code:606
											userInfo:errorData];
		  
		  [delegateResponse setObject:error forKey:@"error"];
		  
		  break;
	  }

  }
  
	if ([self _isValidDelegateForSelector:@selector(twitpicDidFailUpload:)]) {
		[_delegate twitpicDidFailUpload:delegateResponse];
  }

}


@end

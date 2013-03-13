//
//  Connection.m
//  TwitterFon
//
//  Created by kaz on 7/25/08.
//  Copyright 2008 naan studio. All rights reserved.
//

#import "URLConnection.h"
#import "StringUtil.h"
#import "JSON.h"

@implementation URLConnection

@synthesize buf;
@synthesize statusCode;
@synthesize accesstoken = accesstoken_;

NSString *TWITTERFON_FORM_BOUNDARY = @"0194784892923";

- (id)initWithDelegate:(id)aDelegate token:(OAToken *)token
{
	self = [super init];
	delegate = aDelegate;
	accesstoken_ = token;
    statusCode = 0;
	return self;
}

- (void)dealloc
{
	[connection cancel];
	[connection release];
	[buf release];
	[super dealloc];
}


- (void)get:(NSString*)aURL
{
	[connection cancel];
    [connection release];
	[buf release];
    statusCode = 0;
    
    NSString *URL = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)aURL, (CFStringRef)@"%", NULL, kCFStringEncodingUTF8);
    [URL autorelease];
	NSURL *finalURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@source=%@", 
											URL,
											([URL rangeOfString:@"?"].location != NSNotFound) ? @"&" : @"?" , 
											SINA_CONSUMER_KEY]];
	
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:SINA_CONSUMER_KEY
													secret:SINA_CONSUMER_SECRET];
	OAMutableURLRequest* request = [[[OAMutableURLRequest alloc] initWithURL:finalURL
										   consumer:consumer 
											  token:self.accesstoken 
											  realm: nil
								  signatureProvider:nil] autorelease];
	[consumer release];
	[request setTimeoutInterval:NETWORK_TIMEOUT_INTERVAL];

	[request setHTTPShouldHandleCookies:NO];

	[request prepare];

 	buf = [[NSMutableData data] retain];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)post:(NSString*)aURL body:(NSString*)body
{
	[connection cancel];
    [connection release];
	[buf release];
    statusCode = 0;
    
    NSString *URL = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)aURL, (CFStringRef)@"%", NULL, kCFStringEncodingUTF8);
	[URL autorelease];
	NSURL *finalURL = [NSURL URLWithString:URL];
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:SINA_CONSUMER_KEY
													secret:SINA_CONSUMER_SECRET];
	OAMutableURLRequest * request = [[[OAMutableURLRequest alloc] initWithURL:finalURL
											 consumer:consumer
												token:self.accesstoken 
												realm: nil
									signatureProvider:nil] autorelease];
	[consumer release];
	
	[request setTimeoutInterval:NETWORK_TIMEOUT_INTERVAL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    int contentLength = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    [request setValue:[NSString stringWithFormat:@"%d", contentLength] forHTTPHeaderField:@"Content-Length"];
	NSString *finalBody = @"";
	if (body) {
		finalBody = [finalBody stringByAppendingString:body];
	}
	finalBody = [finalBody stringByAppendingString:[NSString stringWithFormat:@"%@source=%@", 
													(body) ? @"&" : @"?" , 
													SINA_CONSUMER_KEY]];
	
	[request setHTTPBody:[finalBody dataUsingEncoding:NSUTF8StringEncoding]];

	[request prepare];
	
	buf = [[NSMutableData data] retain];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)post:(NSString*)aURL data:(NSData*)data
{
	[connection cancel];
    [connection release];
	[buf release];
    statusCode = 0;

    NSString *URL = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)aURL, (CFStringRef)@"%", NULL, kCFStringEncodingUTF8);
    [URL autorelease];
	NSURL *finalURL = [NSURL URLWithString:URL];
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:SINA_CONSUMER_KEY
													secret:SINA_CONSUMER_SECRET];
	
	OAMutableURLRequest* requeset = [[[OAMutableURLRequest alloc] initWithURL:finalURL
											 consumer:consumer 
												token:self.accesstoken 
												realm: nil
									signatureProvider:nil] autorelease];
	[consumer release];
	[requeset setTimeoutInterval:NETWORK_TIMEOUT_INTERVAL];

	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", TWITTERFON_FORM_BOUNDARY];
    [requeset setHTTPShouldHandleCookies:NO];
    [requeset setHTTPMethod:@"POST"];
    [requeset setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [requeset setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
    [requeset setHTTPBody:data];
	
	buf = [[NSMutableData data] retain];
	connection = [[NSURLConnection alloc] initWithRequest:requeset delegate:self];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)cancel
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;    
    if (connection) {
        [connection cancel];
        [connection autorelease];
        connection = nil;
    }
}

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)aResponse
{
    NSHTTPURLResponse *resp = (NSHTTPURLResponse*)aResponse;
    if (resp) {
        statusCode = resp.statusCode;
    }
	[buf setLength:0];
}

- (void)connection:(NSURLConnection *)aConn didReceiveData:(NSData *)data
{
	[buf appendData:data];
}

- (void)connection:(NSURLConnection *)aConn didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
	[connection autorelease];
	connection = nil;
	[buf autorelease];
	buf = nil;
    
    [self URLConnectionDidFailWithError:error];
    
}


- (void)URLConnectionDidFailWithError:(NSError*)error
{
    // To be implemented in subclass
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConn
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
	NSDictionary * errorData = nil;
	NSString* resultStr = nil;
	switch (statusCode) {
		case 200: // OK: everything went awesome.
			[self URLConnectionDidFinishLoading:nil];
			break;
        case 401: // Not Authorized: either you need to provide authentication credentials, or the credentials provided aren't valid.
            errorData = [NSDictionary dictionaryWithObject:@"Authentication Failed" forKey:@"error"];
			NSError * error = [NSError errorWithDomain:@"SinaMBErrDomain" code:401 userInfo:errorData];
			[self URLConnectionDidFailWithError:error];  
            break;
        case 400: // as request ,we should parse the error,feedback the detail errorcode
			resultStr = [[[NSString alloc] initWithData:buf encoding:NSUTF8StringEncoding] autorelease];
			id paraseDic = [resultStr JSONValue];
			if ([paraseDic isKindOfClass:[NSDictionary class]]) {
				if ([paraseDic objectForKey:@"error"]) {
					NSString * errorInfo = [paraseDic objectForKey:@"error"];
					NSArray * errorArr = [errorInfo componentsSeparatedByString:@":"];
					if ([errorArr count] > 1) {
						int errorCode = [[errorArr objectAtIndex:0] intValue];
						NSString * errorMsg = [errorArr objectAtIndex:1];
						NSDictionary * errorData = [NSDictionary dictionaryWithObject:errorMsg forKey:@"error"];
						NSError * error = [NSError errorWithDomain:@"SinaMBErrDomain" code:errorCode userInfo:errorData];
						[self  URLConnectionDidFailWithError:error];
					}else {
						NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"error"];
						NSError * error = [NSError errorWithDomain:@"SinaMBErrDomain" code:unknownError
														  userInfo:errorData];
						[self  URLConnectionDidFailWithError:error];
					}
				}
			}
			break;
        case 403: // Forbidden: we understand your request, but are refusing to fulfill it.  An accompanying error message should explain why.
        case 404: // Not Found: either you're requesting an invalid URI or the resource in question doesn't exist (ex: no such user). 
        case 500: // Internal Server Error: we did something wrong.  Please post to the group about it and the Weibo team will investigate.
        case 502: // Bad Gateway: returned if Weibo is down or being upgraded.
        case 503: // Service Unavailable: the Weibo servers are up, but are overloaded with requests.  Try again later.
        case 304: // Not Modified: there was no new data to return.
		default:
        {
			errorData = [NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:statusCode] forKey:@"error"];
			error = [NSError errorWithDomain:@"SinaMBErrDomain" code:statusCode userInfo:errorData];
            [self URLConnectionDidFailWithError:error];
			break;
        }
    }
	
    [connection autorelease];
    connection = nil;
    [buf autorelease];
    buf = nil;
}

- (void)URLConnectionDidFinishLoading:(NSDictionary*)contentDic
{
    // To be implemented in subclass
}

@end

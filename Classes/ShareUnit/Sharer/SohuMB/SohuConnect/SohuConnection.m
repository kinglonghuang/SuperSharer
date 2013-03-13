//
//  SohuConnection.m
//  SuperShare
//
//  Created by WS12316 on 4/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import "SohuConnection.h"
#import "StringUtil.h"
#import "JSON.h"

@interface SohuConnection (Private)

- (void) uploadImageWithURLPath:(NSString *)urlStr imageData:(NSData *)postBody;

@end

@implementation SohuConnection

static NSString * SOHU_FORM_BOUNDARY = @"129212780100";

- (id) init
{
	if (self = [super init]) {
		receivedData_ = [[NSMutableData alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[connection_ cancel];
	[connection_ release];
	[receivedData_ release];
	[accessToken_ release];
	[super dealloc];
}

#pragma mark -
#pragma mark Helper

- (NSString*) nameValString: (NSDictionary*) dict {
	NSArray* keys = [dict allKeys];
	NSString* result = [NSString string];
	int i;
	for (i = 0; i < [keys count]; i++) {
        result = [result stringByAppendingString:
                  [@"--" stringByAppendingString:
                   [SOHU_FORM_BOUNDARY stringByAppendingString:
                    [@"\r\nContent-Disposition: form-data; name=\"" stringByAppendingString:
                     [[keys objectAtIndex: i] stringByAppendingString:
                      [@"\"\r\n\r\n" stringByAppendingString:
                       [[dict valueForKey: [keys objectAtIndex: i]] stringByAppendingString: @"\r\n"]]]]]]];
	}
	
	return result;
}


- (NSString *)_encodeString:(NSString *)string
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, 
																		   (CFStringRef)string, 
																		   NULL, 
																		   (CFStringRef)@";/?:@&=$+{}<>,",
																		   kCFStringEncodingUTF8);
    return [result autorelease];
}


- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed
{
    NSMutableString *str = [NSMutableString stringWithCapacity:0];
    if (base) {
        [str appendString:base];
    }
    if (params) {
        int i;
        NSArray *names = [params allKeys];
        for (i = 0; i < [names count]; i++) {
            if (i == 0 && prefixed) {
                [str appendString:@"?"];
            } else if (i > 0) {
                [str appendString:@"&"];
            }
            NSString *name = [names objectAtIndex:i];
            [str appendString:[NSString stringWithFormat:@"%@=%@", 
							   name, [self _encodeString:[params objectForKey:name]]]];
        }
    }
    
    return str;
}


- (NSString *)getURL:(NSString *)path 
	 queryParameters:(NSMutableDictionary*)params {
    NSString* fullPath = [NSString stringWithFormat:@"http://api.t.sohu.com/%@", path];
	if (params) {
        fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
    }
	return fullPath;
}

#pragma mark -
#pragma mark ShareInterface

- (void) publishStatus:(NSString *)status
{
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:SOHU_CONSUMER_KEY
													secret:SOHU_CONSUMER_SECRET];
	
	NSURL *url = [NSURL URLWithString:@"http://api.t.sohu.com/statuses/update.json"];
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:accessToken_
																	  realm:nil
														  signatureProvider:nil];
	[request setTimeoutInterval:NETWORK_TIMEOUT_INTERVAL];
	[request setHTTPMethod:@"POST"];
	
	OARequestParameter * statusParam = [[OARequestParameter alloc] initWithName:@"status" value:status];
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


- (void) publishLink:(NSString *)linkStr
{
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:SOHU_CONSUMER_KEY
													secret:SOHU_CONSUMER_SECRET];
	
	NSURL *url = [NSURL URLWithString:@"http://api.t.sohu.com/statuses/update.json"];
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																   consumer:consumer
																	  token:accessToken_
																	  realm:nil
														  signatureProvider:nil];
	[request setTimeoutInterval:NETWORK_TIMEOUT_INTERVAL];
	[request setHTTPMethod:@"POST"];
	
	OARequestParameter * statusParam = [[OARequestParameter alloc] initWithName:@"status" value:linkStr];
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


- (void) uploadImage:(UIImage *)image withDescription:(NSString *)description
{
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:description, @"status",nil];
    
    NSString *param = [self nameValString:dic];
    NSString *footer = [NSString stringWithFormat:@"\r\n--%@--\r\n", SOHU_FORM_BOUNDARY];
    
    param = [param stringByAppendingString:[NSString stringWithFormat:@"--%@\r\n", SOHU_FORM_BOUNDARY]];
    param = [param stringByAppendingString:@"Content-Disposition: form-data; name=\"pic\";filename=\"image.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n"];
	
	NSData * imageData = UIImagePNGRepresentation(image);
    NSMutableData * postBody = [NSMutableData data];
    [postBody appendData:[param dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:imageData];
    [postBody appendData:[footer dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSString *urlPath = [NSString stringWithFormat:@"statuses/upload.json"];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
	[params setObject:description forKey:@"status"];
	NSString * urlStr = [self getURL:urlPath queryParameters:params];
    [self uploadImageWithURLPath:urlStr imageData:postBody];
}


- (void)get:(NSString*)aURL
{
	[connection_ cancel];
    [connection_ release];
    
	NSURL * finalURL = [NSURL URLWithString:aURL];
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:SOHU_CONSUMER_KEY
													secret:SOHU_CONSUMER_SECRET];
	
	OAMutableURLRequest * request = [[OAMutableURLRequest alloc] initWithURL:finalURL
																	consumer:consumer
																	   token:accessToken_
																	   realm:nil
														   signatureProvider:nil];
	
	[request prepare];
	[request setTimeoutInterval:NETWORK_TIMEOUT_INTERVAL];
	
	connection_ = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	[request release];
	[consumer release];
}


- (void)cancelSharing
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;    
    if (connection_) {
        [connection_ cancel];
        [connection_ autorelease];
        connection_ = nil;
    }
	[delegate_ shareItemShareCancelled:self];
}

#pragma mark -
#pragma mark Private

- (void) uploadImageWithURLPath:(NSString *)urlStr imageData:(NSData *)postBody
{
	[connection_ cancel];
    [connection_ release];
	
	OAConsumer *consumer = [[OAConsumer alloc] initWithKey:SOHU_CONSUMER_KEY
													secret:SOHU_CONSUMER_SECRET];

	OAMutableURLRequest* request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]
												    consumer:consumer
													token:accessToken_ 
													realm: nil
													signatureProvider:nil];
	
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", SOHU_FORM_BOUNDARY];
    [request setHTTPShouldHandleCookies:NO];
	[request setTimeoutInterval:NETWORK_TIMEOUT_INTERVAL];
    [request setHTTPMethod:@"POST"];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [postBody length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postBody];
	[request prepare];
	
	connection_ = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	[request release];
	[consumer release];
}


- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)aResponse
{
	[receivedData_ setLength:0];
	NSHTTPURLResponse *resp = (NSHTTPURLResponse*)aResponse;
    if (resp) {
		statusCode_ = [resp statusCode];
    }
}


- (void)connection:(NSURLConnection *)aConn didReceiveData:(NSData *)data
{
	[receivedData_ appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)aConn
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	NSDictionary * errorData = nil;
	NSError * error = nil;
	
	switch (statusCode_) {
		case 200: // OK: everything went awesome.
			[delegate_ shareItemShareSucceed:self];
			break;
		default:
        {
			errorData = [NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:statusCode_] forKey:@"error"];
			error = [NSError errorWithDomain:@"SohuMBErrDomain" code:statusCode_ userInfo:errorData];
            [delegate_ shareItem:self shareFailed:error];
			break;
        }
    }
	
    [connection_ autorelease];
    connection_ = nil;
    [receivedData_ autorelease];
    receivedData_ = nil;
}


- (void)connection:(NSURLConnection *)aConn didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
	[connection_ autorelease];
	connection_ = nil;
	[receivedData_ autorelease];
	receivedData_ = nil;
    
    [delegate_ shareItem:self shareFailed:error];
    
}


#pragma mark -
#pragma mark APIDelegate

- (void) apiTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed)
	{
		[delegate_ shareItemShareSucceed:self];
	}
}

- (void) apiTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[delegate_ shareItem:self shareFailed:error];	
}


@end

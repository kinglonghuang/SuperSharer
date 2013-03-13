//
//  WeiboClient.m
//  WeiboFon
//
//  Created by kaz on 7/13/08.
//  Copyright naan studio 2008. All rights reserved.
//

#import "WeiboClient.h"
#import "StringUtil.h"
#import "JSON.h"

@implementation WeiboClient

@synthesize request;
@synthesize context;
@synthesize hasError;
@synthesize errorMessage;
@synthesize errorDetail;
@synthesize accessToken;

- (id)initWithTarget:(id)aDelegate token:(OAToken *)token action:(SEL)anAction
{
    [super initWithDelegate:aDelegate token:token];
    action = anAction;
    hasError = false;
    return self;
}

- (void)dealloc
{
    [errorMessage release];errorMessage = nil;
    [errorDetail release];errorDetail = nil;
    [accessToken release];accessToken = nil;
    [super dealloc];
}


- (NSString*) nameValString: (NSDictionary*) dict {
	NSArray* keys = [dict allKeys];
	NSString* result = [NSString string];
	int i;
	for (i = 0; i < [keys count]; i++) {
        result = [result stringByAppendingString:
                  [@"--" stringByAppendingString:
                   [TWITTERFON_FORM_BOUNDARY stringByAppendingString:
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
    // Append base if specified.
    NSMutableString *str = [NSMutableString stringWithCapacity:0];
    if (base) {
        [str appendString:base];
    }
    
    // Append each name-value pair.
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
    NSString* fullPath = [NSString stringWithFormat:@"%@://%@/%@", 
						  (1) ? @"https" : @"http",
						  UPLOAD_APIDOMAIN, path];//oauth2 use secureConnection
	if (params) {
        fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
    }
	return fullPath;
}

#pragma mark -
#pragma mark REST API methods
#pragma mark -
- (void)getUser:(int)userId
{
    NSString *path = [NSString stringWithFormat:@"users/show.%@", API_FORMAT];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
	[params setObject:[NSString stringWithFormat:@"%d", userId] forKey:@"user_id"];
	[super get:[self getURL:path queryParameters:params]];
}

- (void)getUserByScreenName:(NSString *)screenName {
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
	[params setObject:[NSString stringWithFormat:@"%@", screenName] forKey:@"screen_name"];
	
    NSString *path = [NSString stringWithFormat:@"users/show.%@", API_FORMAT];
	[super get:[self getURL:path queryParameters:params]];
}

- (void)post:(NSString*)tweet
{
    NSString *path = [NSString stringWithFormat:@"statuses/update.%@", API_FORMAT];
    NSString *postString = [NSString stringWithFormat:@"status=%@",
                            [tweet encodeAsURIComponent]];
	
    [self post:[self getURL:path queryParameters:nil]
		  body:postString];
}


- (void)upload:(NSData*)jpeg status:(NSString *)status
{
	NSString *path = [NSString stringWithFormat:@"statuses/upload.%@", API_FORMAT];
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
						 status, @"status",
						 SINA_CONSUMER_KEY, @"source",
                         nil];
    
    NSString *param = [self nameValString:dic];
    NSString *footer = [NSString stringWithFormat:@"\r\n--%@--\r\n", TWITTERFON_FORM_BOUNDARY];
    
    param = [param stringByAppendingString:[NSString stringWithFormat:@"--%@\r\n", TWITTERFON_FORM_BOUNDARY]];
    param = [param stringByAppendingString:@"Content-Disposition: form-data; name=\"pic\";filename=\"image.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n"];
	
    NSMutableData *data = [NSMutableData data];
    [data appendData:[param dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:jpeg];
    [data appendData:[footer dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
	[params setObject:self.accessToken forKey:@"access_token"];
	[params setObject:status forKey:@"status"];

    [self post:[self getURL:path queryParameters:params] data:data];
}


- (void)repost:(long long)statusId
		 tweet:(NSString*)tweet {
    NSString *path = [NSString stringWithFormat:@"statuses/repost.%@", API_FORMAT];
    NSString *postString = [NSString stringWithFormat:@"id=%lld&status=%@",
							statusId,
                            [tweet encodeAsURIComponent]];
	
    [self post:[self getURL:path queryParameters:nil]
		  body:postString];
}


- (void)authError
{
    self.errorMessage = @"Authentication Failed";
    self.errorDetail  = @"Wrong username/Email and password combination."; 
	NSDictionary * errorData = [NSDictionary dictionaryWithObject:@"Authentication Failed" forKey:@"error_msg"];
	NSError * error = [NSError errorWithDomain:@"SinaMBErrDomain" code:401 userInfo:errorData];
    [delegate performSelector:action withObject:self withObject:error];    
}

- (void)URLConnectionDidFailWithError:(NSError*)error
{
    hasError = true;
	[delegate performSelector:action withObject:self withObject:error];
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	hasError = true;
	[self authError];
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    hasError = true;
    [self authError];
}

- (void)URLConnectionDidFinishLoading:(NSDictionary*)contentDic
{
	hasError = false;
	[delegate performSelector:action withObject:self withObject:nil];
}

- (void)alert
{
	UIAlertView *sAlert = [[[UIAlertView alloc] initWithTitle:errorMessage
                                        message:errorDetail
									   delegate:self
							  cancelButtonTitle:@"Close"
							  otherButtonTitles:nil] autorelease];
    [sAlert show];
}

@end

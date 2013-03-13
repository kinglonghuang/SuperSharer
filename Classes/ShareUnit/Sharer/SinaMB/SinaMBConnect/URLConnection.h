#import <Foundation/Foundation.h>
#import "OAToken.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "ShareConfig.h"

#define API_FORMAT          @"json"
#define UPLOAD_APIDOMAIN	@"upload.api.weibo.com/2"

extern NSString *TWITTERFON_FORM_BOUNDARY;

@interface URLConnection : NSObject
{
	id                  delegate;
	NSURLConnection*    connection;
	NSMutableData*      buf;
    int                 statusCode;
    OAToken				* accesstoken_;
}

@property (nonatomic, readonly) NSMutableData* buf;
@property (nonatomic, assign) int statusCode;
@property (nonatomic, copy) OAToken * accesstoken;

- (id)initWithDelegate:(id)delegate token:(OAToken *)token;
- (void)get:(NSString*)URL;
- (void)post:(NSString*)aURL body:(NSString*)body;
- (void)post:(NSString*)aURL data:(NSData*)data;
- (void)cancel;

- (void)URLConnectionDidFailWithError:(NSError*)error;
- (void)URLConnectionDidFinishLoading:(NSDictionary*)contentDic;

@end

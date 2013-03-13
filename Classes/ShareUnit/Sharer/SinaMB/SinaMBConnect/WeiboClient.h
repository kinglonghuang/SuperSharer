#import <UIKit/UIKit.h>
#import "URLConnection.h"
//#import "Status.h"


typedef enum {
    WEIBO_REQUEST_TIMELINE,
    WEIBO_REQUEST_REPLIES,
    WEIBO_REQUEST_MESSAGES,
    WEIBO_REQUEST_SENT,
    WEIBO_REQUEST_FAVORITE,
    WEIBO_REQUEST_DESTROY_FAVORITE,
    WEIBO_REQUEST_CREATE_FRIENDSHIP,
    WEIBO_REQUEST_DESTROY_FRIENDSHIP,
    WEIBO_REQUEST_FRIENDSHIP_EXISTS,
} RequestType;

@interface WeiboClient : URLConnection
{
    RequestType request;
    id          context;
    SEL         action;
    BOOL        hasError;
    NSString*   errorMessage;
    NSString*   errorDetail;

    BOOL _secureConnection;
}

@property(nonatomic, readonly) RequestType request;
@property(nonatomic, assign) id context;
@property(nonatomic, assign) BOOL hasError;
@property(nonatomic, copy) NSString* errorMessage;
@property(nonatomic, copy) NSString* errorDetail;
@property(nonatomic, copy) NSString* accessToken;

- (id)initWithTarget:(id)aDelegate token:(OAToken *)token action:(SEL)anAction;



- (void)getUser:(int)userId;

- (void)getUserByScreenName:(NSString *)screenName;

- (void)post:(NSString*)tweet;

- (void)upload:(NSData*)jpeg status:(NSString *)status;

- (void)repost:(long long)statusId
		 tweet:(NSString*)tweet;

- (NSString *)getURL:(NSString *)path 
	 queryParameters:(NSMutableDictionary*)params;

- (void)alert;

@end

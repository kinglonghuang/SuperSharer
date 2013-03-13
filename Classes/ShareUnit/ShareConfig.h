
// ShareItem Identifier

#define FacebookID							@"Facebook"
#define TwitterID							@"Twitter"
#define FlickrID							@"Flickr"
#define SinaMBID							@"SinaMB"
#define TencentMBID							@"TencentMB"
#define RenRenID							@"RenRen"
#define SohuMBID							@"SohuMB"
#define ReadItLaterID						@"ReadItLater"
#define InstapaperID						@"Instapaper"


// These keys should be replaced by the official keys before Release
#define FLICKR_API_KEY						@"06cdb25c60d0e5888225f4c5f0416143"
#define FLICKR_API_SECRET					@"681bcb9940faf0d5"
#define FLICKR_WEB_DOMAIN					@"picShare" //need help?refer to ReadMe.rtf

#define FACEBOOK_APP_ID						@"165300323517027"


#define TWITTER_CONSUMER_KEY				@"AIYibH1iTNpJb5VZdK7ECA"
#define TWITTER_CONSUMER_SECRET				@"2DiWelLKoMIZ0wKKMl69PXGUTrEIIjtrZew1y2hKJp0"
#define TWITPIC_API_KEY						@"5f5e3cabc90d4bc6f191cd0bcee1555c"	//this key is from twitpic
#define TWITTER_WEB_DOMAIN					@"twitterLoginSucceed.com"////need help?refer to ReadMe.rtf

#define SINA_CONSUMER_KEY					@"4228159573"
#define SINA_CONSUMER_SECRET				@"dec4cacb4fddeb73a9cf150081d6921f"
#define kWBAuthorizeURL                     @"https://api.weibo.com/oauth2/authorize"
#define kWBAccessTokenURL                   @"https://api.weibo.com/oauth2/access_token"
#define SINA_CALLBACK_ADD                   @"http://www.sinafeedback.com"
#define SINA_CALLBACK_HOST                  @"www.sinafeedback.com"

//#define TENCENT_CONSUMER_KEY				@"5a0cffea8b234c4eb0d7e9959ad7b384"
//#define TENCENT_CONSUMER_SECRET				@"4e4d21ba16dd1c1bf5e270ba84aafcf8"
#define TENCENT_CONSUMER_KEY				@"801000540"
#define TENCENT_CONSUMER_SECRET				@"147f8bb465f45156f43cdefe46acc4a3"

//#define SOHU_CONSUMER_KEY					@"G3o772E8i34i5yWBzW6d"
//#define SOHU_CONSUMER_SECRET				@"I)DSa1TymY1cCiuHgH1gnfS0O30JNA$X(Xxojw0B"

#define SOHU_CONSUMER_KEY					@"HmyGxXgOsWOacsQxn4gU"
#define SOHU_CONSUMER_SECRET				@"z8)VNF*0FO1)PXJFBfPMeqPT%ig7P*wKUHso7YD8"


#define RENREN_API_KEY						@"65ffa97b5dc641e7877aed63e7811bbe"
#define RENREN_API_SECRET					@"aa6dfcedb5e54a29a0f25839bf07cd1f"

#define INSTAPAPER_CONSUMER_KEY				@"ltLUyFhAQGc0RClPVTlXHqfA54YW8kFKgJTFyat6EkECced5Gw"
#define INSTAPAPER_CONSUMER_SECRET			@"jZO5AYzGMBISmI1tsHjPbFV2HQfMvV4uXlPE2bDNzi9ak8LLjG"


#define NETWORK_TIMEOUT_INTERVAL			30.0

#define DEFAULT_PIC_NAME					@"myPhoto"
#define DEFAULT_VIDEO_NAME					@"myVideo"


//You can receive msg from these delegate method

@protocol ShareDelegate

- (void) shareItemLoginSucceed:(id)item;

- (void) shareItemLoginCancelled:(id)item;

- (void) shareItem:(id)item loginFailed:(NSError *)error;

- (void) shareItemLogoutSucceed:(id)item;

- (void) shareItemShareBegin:(id)item;

- (void) shareItemShareSucceed:(id)item;

- (void) shareItemShareCancelled:(id)item;

- (void) shareItem:(id)item shareFailed:(NSError*)error;

- (void) shareItem:(id)item feedbackStatus:(NSString *)status;

@end

typedef enum customizeErrorCode_ {
	toomanyWordsError			= 6011,
	dataTypeNotSupportedError	= 6012,
	unknownError				= 6013,
	userDeniedError				= 6014
}customizeErrorCode;

/*
 6011  Too many status words 
 6012  Data type not supported by the Specific item
 6013  Unknown Error
 6014  User Denied to authorize your app
*/

SuperSharer
===========

关于项目
*********************************************************************************************************************

SuperSharer功能介绍：

1.支持分享 文字，图片，视频，链接，支持保存网页到书签网站

2.分享项采用OAuth授权，保护用户帐号安全

3.统一的应用程序内授权界面，无需切换到Safari授权，提升了用户体验

4.模块定制简单，可轻松增减分享项目

已支持的分享项目：

facebook , twitter ,flickr ,YouTube , Instapaper , ReadItLater , 新浪微博，腾讯微博，搜狐微博，人人网 


关于使用
*********************************************************************************************************************

环境配置：

1.将 shareUnit文件夹导入到你的工程

2.添加以下Framework到你的工程中：
  						MobileCoreServices.framework
							SystemConfiguration.framework
							CFNetwork.framework
							Security.framework
							libz.dylib
							
3. 工程Target Info 中的 Other Linker Flags 添加 -lxml2
							
4.如果你的项目中包含了Youtube分享项，则需要在 Target Info 中的Header search path添加 /usr/include/libxml2


开始使用：

1.引入头文件：

#import "ShareConfig.h"
#import "ShareItem.h"

2.初始化分享项的实例，例如：

shareItem  = [[ShareItem alloc] initForItem:FacebookID delegate:self];

3.开始分享：

[shareItem shareImage:image withDescription:@"my new photo"];

4.你的类通过实现 ShareDelegate 协议来处理 SuperSharer的回馈信息（具体接口请参考ShareConfig.h中的ShareDelegate协议），例如:

- (void) shareItemShareSucceed:(id)item
{
	NSLog(@"shareItemShareSucceed: %@",item);
}

5.注意：

如果只需要登录，可以调用：
[shareItem login];

如果需要分享，可直接调用分享方法，SuperSharer 会确保用户先登录，然后自动开始上传 

[shareItem shareImage:image withDescription:@"my new photo"];

因为登录过程没有阻塞，所以不能出现以下顺序调用：
[shareItem login];
[shareItem shareImage:image withDescription:@"my new photo"];

某些分享项由于官方授权实现不同，用户在授权页面点击取消授权时，SuperSharer不能收到取消消息(例如人人的取消操作定义为刷新登录界面)，只有当用户点击界面关闭按钮时才能关闭界面并返回状态


自定义：

1.登录界面的Logo图标资源位置： ShareUnit /Sharer /Common /LoginDialog /LoginDialog.bundle /icons，你可以替换成你自己设计的图标，但请保持名字不变（登录界面的背景图大小：278*393 ，icon图标大小：14*14） 更多登录界面的配置，请参考各个分享项的login 方法。

2.当用户在登录界面点击链接时（除登录和取消按钮），superSharer默认的配置是：1.不使用Safari 打开该链接. 2.在登录界面加载该链接,你可以在每个分享项的LoginDialogDelegate代理方法中改变这些配置：

- (BOOL)dialog:(LoginDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url
{
	return NO;  //不使用Safari 打开该链接
}
- (BOOL)dialogShouldLoadLinkURL:(NSURL *)url
{
	return YES; //在登录界面加载该链接
}

3.当用户取消授权时（点击取消按钮或点击关闭按钮），你将有机会收到该消息，执行关闭前的动作 并决定是否可以关闭登录窗口

- (BOOL)dialogShouldClose
{
	return YES;  //可以关闭窗口
}

4.去除不需要的分享项：
 
删除对应项的文件夹，在ShareConfig.h文件中删除对应项ID的宏定义

说明：

1. 在分享前请检查是否有网络链接，SuperSharer没有这么做是为了给你的应用统一检查网路的机会，ShareUnit中有一个Common文件夹，你可以使用其中的Reachability.h 和 Reachability.m 文件来检查网路


3.各个分享平台可分享的媒介都有一定的限制，在开始分享前请参考 媒体限制（免费赠送 -_-）
不支持的分享类型，SuperSharer返回6012错误（dataTypeNotSupportedError），更多错误码请参考配置文件ShareConfig.h中的customizeErrorCode

4.你可以使用SuperSharer的 cancelShare 来取消分享动作，但SuperSharer不保证取消有效（取消动作太晚导致文件实际已上传完成）

5. 对于分享的链接URL，如果过长（超过了maxStringLength），你可以进行网址缩略后再发表.


关于授权
********************************************************************************************************************

Facebook 

1.登录 http://www.facebook.com/developers/  ,点击  Set Up New App

2.填写注册信息，获得App ID ，用此App ID 替换 工程文件ShareConfig.h中的FACEBOOK_APP_ID宏



Twitter

1.登录https://dev.twitter.com/apps ,点击 Register a new app

2. 填写注册信息 ，注意：
Application type 栏选择 Browser ,callback url 填上回调的地址（例如 http://twitterLoginSucceed.com）,Default Access type必须选择 Read&write

3.用刚注册的app的 Consumer key 和 Consumer sercret 替换工程文件ShareConfig.h中的 TWITTER_CONSUMER_KEY和TWITTER_CONSUMER_SECRET

4.用刚填写的callback url中的主机地址（例如以上url中的twitterLoginSucceed.com）  替换Shareconfig.h中的TWITTER_WEB_DOMAIN

4.登录 http://dev.twitpic.com/apps/new，填写注册信息，获得TwitPic API KEY，用来替换工程文件Shareconfig.h中的TWITPIC_API_KEY



Flickr 

1.登录 http://www.flickr.com/services/ ,在 Your apps 栏 点击 Get an api key,根据需要注册app.

2. 注册完成后即可看到appkey 和 appsecret.点击Edit auth flow for this app, App type选择 web application,在callback ulr 栏输入yourAppDomain://auth? (例如输入picShare://auth?) 

3.打开工程文件shareConfig.h
用刚注册的app获得的apply 和 appsecret替换FLICKR_API_KEY和FLICKR_API_SECRET两个宏，用刚填入的callback url中的appDomain字段（例如以上的picShare）替换 FLICKR_WEB_DOMAIN



SinaMB

1.登录 http://open.t.sina.com.cn/，点击“我的应用”，进入后再点击右下角的“创建应用”

2.填写注册信息，完成后可获得app key  和 app secret,用这两个值替换工程文件ShareConfig.h中的SIINA_CONSUMER_KEY 和 SINA_CONSUMER_SECRET



TencentMB

1.登录 http://open.t.qq.com/ ，点击“创建应用”，填写注册信息，类型可以默认或者选择“手机应用”，完成后保存

2.在“已创建的应用”页面，点击“查看详情”可看到应用的 App key 和 App Secret,用来替换工程文件ShareConfig.h中的 TENCENT_CONSUMER_KEY 和 TENCENT_CONSUMER_SECRET



SohuMB

1.登录 http://open.t.sohu.com/ ，进入“我的应用”一栏，点击“创建应用”。

2.填写注册信息，注意：应用类型选择 客户端，xAuth 默认不申请

3.完成注册后用获得的 consumer key 和 consumer secret替换工程文件 ShareConfig.h中的 SOHU_CONSUMER_KEY 和 SOHU_CONSUMER_SECRET



RenRen

1.登录 http://app.renren.com/developers ，点击 “创建新应用”,填写注册信息

2.注册完成，获得Api key 和 secret ，用来替换工程文件 ShareConfig.h中的 RENREN_API_KEY 和 RENREN_API_SECRET

3.人人网的照片上传和消息发布接口都属于“高级API” ,需要申请才能使用，你可以登录 http://wiki.dev.renren.com/wiki/Apply_Renren_API查看详情


YouTube

1. 登录 http://code.google.com/apis/youtube/dashboard ，点击 “New Product”, 完成注册信息

2.用获得的Developer Key 替换工程文件ShareConfig.h中的 YOUTUBE_DEVKEY



Instapaper

1. 登录 http://www.instapaper.com/main/request_oauth_consumer_token ，填写注册信息，等待 Instapaper 审核通过，会以邮件的方式发送认证信息

2.用获得的 OAuth consumer key 和 OAuth consumer secret替换工程文件 ShareConfig.h中的 INSTAPAPER_CONSUMER_KEY和 INSTAPAPER_CONSUMER_SECRET


注：ReadItLater官方不支持OAuth 授权，youtube则采用了ClientLogin 的授权方式


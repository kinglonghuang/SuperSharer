//
//  3DES+Base64Helper.h
//  Base64Test
//
//  Created by kinglong on 11-3-1.
//  Copyright 2011 wondershare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>

@interface DES_Base64Helper : NSObject {

}

+ (NSString*)tripleDES:(NSString*)plainText encryptOrDecrypt:(CCOperation)encryptOrDecrypt key:(NSString*)key;

@end

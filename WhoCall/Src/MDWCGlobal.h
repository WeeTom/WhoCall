//
//  MDWCGlobal.h
//  WhoCall
//
//  Created by Wee Tom on 14-8-11.
//  Copyright (c) 2014年 Wang Xiaolei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDAPICategory.h"
#import "MDAuthenticator.h"
#import "MDAuthPanel.h"

@interface MDWCGlobal : NSObject
+ (BOOL)authed;
+ (NSDictionary *)authInfo;
+ (void)saveAuthInfo:(NSDictionary *)dic;

+ (NSArray *)savedContacts;
+ (void)saveContacts:(NSArray *)contacts;

+ (MDUser *)userWithNumber:(NSString *)number;
@end

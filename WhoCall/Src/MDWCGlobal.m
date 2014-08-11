//
//  MDWCGlobal.m
//  WhoCall
//
//  Created by Wee Tom on 14-8-11.
//  Copyright (c) 2014年 Wang Xiaolei. All rights reserved.
//

#import "MDWCGlobal.h"

#define kMDWCAuthInfoKey @"md.wc.authinfo"
#define kMDWCContactsKey @"md.wc.contacts"


@implementation MDWCGlobal
+ (BOOL)authed
{
    NSDictionary *dic = [self authInfo];
    if (!dic) {
        return NO;
    } else {
        NSString *accessToken = dic[@"access_token"];
        if (!accessToken) {
            return NO;
        }
        // TODO: expire...
        return YES;
    }
}

+ (NSDictionary *)authInfo
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kMDWCAuthInfoKey];
}

+ (void)saveAuthInfo:(NSDictionary *)dic
{
    if (dic) {
        [[NSUserDefaults standardUserDefaults] setObject:dic forKey:kMDWCAuthInfoKey];
    }
}

+ (NSArray *)savedContacts
{
    return [self unarchiveArray:[[NSUserDefaults standardUserDefaults] objectForKey:kMDWCContactsKey]];
}

+ (void)saveContacts:(NSArray *)contacts
{
    if (contacts) {
        [[NSUserDefaults standardUserDefaults] setObject:[self archiveArray:contacts] forKey:kMDWCContactsKey];
    }
}

+ (MDUser *)userWithNumber:(NSString *)number
{
    NSArray *users = [self savedContacts];
    for (MDUser *u in users) {
        if ([u.workPhoneNumber isEqualToString:number]) {
            return u;
        }
        if ([u.mobilePhoneNumber isEqualToString:number]) {
            return u;
        }
        if (NSMaxRange([u.mobilePhoneNumber rangeOfString:number]) < u.mobilePhoneNumber.length) {
            return u;
        }
        if (NSMaxRange([u.workPhoneNumber rangeOfString:number]) < u.workPhoneNumber.length) {
            return u;
        }
    }
    return nil;
}

+ (NSArray *)archiveArray:(NSArray *)array
{
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:array.count];
    for (id object in array) {
        NSData *data = [self archiveObject:object];
        [returnArray addObject:data];
    }
    return returnArray;
}

+ (NSData *)archiveObject:(id)object
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    return data;
}

+ (NSArray *)unarchiveArray:(NSArray *)array
{
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:array.count];
    for (NSData *data in array) {
        id object = [self unarchiveObject:data];
        [returnArray addObject:object];
    }
    return returnArray;
}

+ (id)unarchiveObject:(NSData *)data
{
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return object;
}

@end

/************************************************************
 *  * EaseMob CONFIDENTIAL
 * __________________
 * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of EaseMob Technologies.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from EaseMob Technologies.
 */

#import "InvitationManager.h"


@interface InvitationManager (){
    NSUserDefaults *_defaults;
}

@end

static InvitationManager *sharedInstance = nil;
@implementation InvitationManager


+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init{
    if (self = [super init]) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    
    return self;
}

#define NewInviteUnreadKey @"NewInviteUnreadKey"

//增加未读
- (void)addUnread
{
    NSString * countStr = [_defaults objectForKey:NewInviteUnreadKey];
    NSString * newStr = [NSString stringWithFormat:@"%ld", countStr.integerValue+1];
    [_defaults setObject:newStr forKey:NewInviteUnreadKey];
}

//清空未读
- (void)clearUnread
{
    [_defaults setObject:@"" forKey:NewInviteUnreadKey];
}
//获取未读
- (NSInteger)getUnread
{
    return [[_defaults objectForKey:NewInviteUnreadKey] integerValue];
}

-(void)addInvitation:(ApplyEntity *)applyEntity loginUser:(NSString *)username{
    NSData *defalutData = [_defaults objectForKey:username];
    NSArray *ary = [NSKeyedUnarchiver unarchiveObjectWithData:defalutData];
    NSMutableArray *appleys = [[NSMutableArray alloc] initWithArray:ary];
//    [appleys addObject:applyEntity];
    [appleys insertObject:applyEntity atIndex:0];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:appleys];
    [_defaults setObject:data forKey:username];
}

-(void)removeInvitation:(ApplyEntity *)applyEntity loginUser:(NSString *)username{
    NSData *defalutData = [_defaults objectForKey:username];
    NSArray *ary = [NSKeyedUnarchiver unarchiveObjectWithData:defalutData];
    NSMutableArray *appleys = [[NSMutableArray alloc] initWithArray:ary];
    ApplyEntity *needDelete;
    for (ApplyEntity *entity in appleys) {
        if ([entity.groupId isEqualToString:applyEntity.groupId] &&
            [entity.receiverUsername isEqualToString:applyEntity.receiverUsername]) {
            needDelete = entity;
            break;
        }
    }
    [appleys removeObject:needDelete];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:appleys];
    [_defaults setObject:data forKey:username];
}

-(NSArray *)applyEmtitiesWithloginUser:(NSString *)username{
    NSData *defalutData = [_defaults objectForKey:username];
    NSArray *ary = [NSKeyedUnarchiver unarchiveObjectWithData:defalutData];
    return ary;
}

@end


@interface ApplyEntity ()<NSCoding>

@end

@implementation ApplyEntity

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_applicantUsername forKey:@"applicantUsername"];
    [aCoder encodeObject:_applicantNick forKey:@"applicantNick"];
    [aCoder encodeObject:_reason forKey:@"reason"];
    [aCoder encodeObject:_receiverUsername forKey:@"receiverUsername"];
    [aCoder encodeObject:_receiverNick forKey:@"receiverNick"];
    [aCoder encodeObject:_style forKey:@"style"];
    [aCoder encodeObject:_groupId forKey:@"groupId"];
    [aCoder encodeObject:_groupSubject forKey:@"groupSubject"];
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super init]){
        _applicantUsername = [aDecoder decodeObjectForKey:@"applicantUsername"];
        _applicantNick = [aDecoder decodeObjectForKey:@"applicantNick"];
        _reason = [aDecoder decodeObjectForKey:@"reason"];
        _receiverUsername = [aDecoder decodeObjectForKey:@"receiverUsername"];
        _receiverNick = [aDecoder decodeObjectForKey:@"receiverNick"];
        _style = [aDecoder decodeObjectForKey:@"style"];
        _groupId = [aDecoder decodeObjectForKey:@"groupId"];
        _groupSubject = [aDecoder decodeObjectForKey:@"groupSubject"];
        
    }
    
    return self;
}

@end


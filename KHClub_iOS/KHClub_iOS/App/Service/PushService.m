//
//  PushService.m
//  JLXCSNS_iOS
//
//  Created by 李晓航 on 15/5/26.
//  Copyright (c) 2015年 JLXC. All rights reserved.
//

#import "PushService.h"
#import "YunBaService.h"
#import "ApplyViewController.h"

@implementation PushService

static PushService *_shareInstance=nil;

+(PushService *) sharedInstance
{
    if(!_shareInstance) {
        _shareInstance=[[PushService alloc] init];
    }
    
    return _shareInstance;
}

-(id)init
{
    self = [super init];
    if (self) {

        [self registerNotify];
        
//        [self initYunBa];
    }
    return self;
}
- (void)pushReconnect
{
    [self initYunBa];
}

#pragma mark- 通知部分
- (void)registerNotify
{
    NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
    [defaultNC addObserver:self selector:@selector(onConnectionStateChanged:) name:kYBConnectionStatusChangedNotification object:nil];
    [defaultNC addObserver:self selector:@selector(onMessageReceived:) name:kYBDidReceiveMessageNotification object:nil];
}

- (void)onConnectionStateChanged:(NSNotification *)notification {
    if ([YunBaService isConnected]) {
        debugLog(@"didConnect");
    } else {
        debugLog(@"didDisconnected");
    }
}

- (void)onMessageReceived:(NSNotification *)notification {
    YBMessage *message = [notification object];
    //如果不是自己订阅的则不接收
    if (![[message topic] isEqualToString:[ToolsManager getCommonTargetId:[UserService sharedService].user.uid]]) {
        return;
    }
    
    debugLog(@"new message, %zu bytes, topic=%@", (unsigned long)[[message data] length], [message topic]);
    NSString *payloadString = [[NSString alloc] initWithData:[message data] encoding:NSUTF8StringEncoding];
    debugLog(@"data: %@", payloadString);
    @try {
        NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:message.data options:NSJSONReadingMutableContainers error:nil];
        if (dic == nil || ![dic isKindOfClass:[NSDictionary class]]) {
            return;
        }
        
        NSInteger type = [dic[@"type"] intValue];
        
        switch (type) {
                //如果是添加好友信息
            case PushAddFriend:
                [self handleNewFriend:dic];
                break;
                //如果是状态回复消息
            case PushNewsAnwser:
                [self handleNewsPush:dic];
                break;
                //如果是二级回复消息
            case PushSecondComment:
                [self handleNewsPush:dic];
                break;
                //如果是点赞
            case PushLikeNews:
                [self handleNewsPush:dic];
                break;
                //群组邀请
            case PushGroupInvite:
                [self handleGroupPush:dic];
                break;
                //公告中的评论
            case PushNoticeComment:
                [self handleNewsPush:dic];
                break;
            default:
                break;
        }
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
    
}

#pragma mark- private method
//初始化 订阅消息
- (void)initYunBa
{
    
    //订阅自己
    NSString * topic = [ToolsManager getCommonTargetId:[UserService sharedService].user.uid];
    [YunBaService subscribe:topic resultBlock:^(BOOL succ, NSError *error) {
        debugLog(@"==================================yunba Subscribe:%d %@", succ, topic);
//        [YunBaService getTopicList:^(NSArray *res, NSError *error) {
//            debugLog(@"yunba topic: %@", res);
//        }];
    }];
}

- (void)logout
{
    [YunBaService close];
}

/*!
 @brief 回复状态消息通知
 @param topic 要推送的对象
 */
-(void)pushNewsAnwserMessageWithTargetID:(NSString *)topic
{

}


//通知处理
//处理新好友通知
- (void)handleNewFriend:(NSDictionary *)dic
{
    
//    NSDictionary * pushDic = dic[@"content"];
//    IMGroupModel * group = [IMGroupModel findByGroupId:pushDic[@"uid"]];
//    
//    if (group) {
//        //如果没加好友 但是有新朋友
//        if (group.isNew == NO) {
//            group.groupTitle = pushDic[@"name"];
//            group.avatarPath = pushDic[@"avatar"];
//            group.addDate    = pushDic[@"time"];
//            group.isNew      = YES;
//            group.isRead     = NO;
//            [group update];
//            //发送通知
//            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_NEW_GROUP object:group];
//            //顶部刷新
//            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_MESSAGE_REFRESH object:nil];
//        }
//    }else{
//        //保存群组信息
//        group = [[IMGroupModel alloc] init];
//        group.type           = [pushDic[@"type"] intValue];
//        //targetId
//        group.groupId        = pushDic[@"uid"];
//        group.groupTitle     = pushDic[@"name"];
//        group.avatarPath     = pushDic[@"avatar"];
//        group.addDate        = pushDic[@"time"];
//        group.isNew          = YES;
//        group.currentState   = GroupNotAdd;
//        group.isRead         = NO;
//        group.owner          = [UserService sharedService].user.uid;
//        [group save];
//        //发送通知
//        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_NEW_GROUP object:group];
//        //顶部刷新
//        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_MESSAGE_REFRESH object:nil];
//    }
//
//    //徽标跟新
//    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_TAB_BADGE object:nil];

}

//新闻回复点赞到来 处理消息
- (void)handleNewsPush:(NSDictionary *)dic
{
    NSDictionary * pushDic = dic[@"content"];
    
    //存储
    NewsPushModel * push = [[NewsPushModel alloc] init];
    push.uid             = [pushDic[@"uid"] integerValue];
    push.name            = pushDic[@"name"];
    push.head_image      = pushDic[@"head_image"];
    push.comment_content = pushDic[@"comment_content"];
    push.type            = [dic[@"type"] integerValue];
    push.news_id         = [pushDic[@"news_id"] integerValue];
    push.news_content    = pushDic[@"news_content"];
    push.news_image      = pushDic[@"news_image"];
    push.news_user_name  = pushDic[@"news_user_name"];
    push.is_read         = NO;
    push.push_time       = pushDic[@"push_time"];
    push.owner           = [UserService sharedService].user.uid;
    
    if (![push isExist]) {
        
        [push save];
        //发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_NEWS_PUSH object:nil];
        //徽标跟新
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_TAB_BADGE object:nil];
    }

}

/**
 *  群组邀请消息处理
 *
 *  @param dic 推送内容
 */
- (void)handleGroupPush:(NSDictionary *)dic
{
    NSDictionary * pushDic = dic[@"content"];
    
    
    NSDictionary * applyDic = @{@"title":pushDic[@"groupname"], @"groupId":pushDic[@"groupid"], @"username":pushDic[@"targetid"], @"groupname":pushDic[@"groupname"], @"applyMessage":[NSString stringWithFormat:@"%@%@", pushDic[@"name"], KHClubString(@"IM_Push_PushInvite")], @"applyStyle":[NSNumber numberWithInteger:ApplyStyleJoinGroup]};
    [[ApplyViewController shareController] addNewApply:applyDic];
    [[CusTabBarViewController sharedService] setUnread];
    [[CusTabBarViewController sharedService] newMessageSound];
}

////处理消息回复
//- (void)handleNewsAnwser:(NSDictionary *)dic
//{
//    //发送通知
//    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_NEWS_PUSH object:nil];
//}
//
////二级评论推送
//- (void)handleSecondComment:(NSDictionary *)dic
//{
//    //发送通知
//    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_NEWS_PUSH object:nil];
//}
//
////点赞推送
//- (void)handleLikeNews:(NSDictionary *)dic
//{
//    //发送通知
//    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_NEWS_PUSH object:nil];
//}

- (void)pushGroupInviteMessageWith:(NSDictionary *)content andTarget:(NSString *)targetID success:(PushSuccess)success fail:(PushFail)fail
{

    NSData * data =[NSJSONSerialization dataWithJSONObject:content options:NSJSONWritingPrettyPrinted error:nil];

//    [YunBaService publish:targetID data:data option:[YBPublishOption optionWithQos:kYBQosLevel2 retained:YES] resultBlock:^(BOOL succ, NSError *error) {
//
//    }];
    
    YBPublish2Option *option = [[YBPublish2Option alloc] init];
    NSString *alert = KHClubString(@"IM_Push_ANewMessage");
    NSNumber *badge = [NSNumber numberWithInt:1];
    NSString *sound = @"bingbong.aiff";
    YBApnOption *apnOption = [YBApnOption optionWithAlert:alert badge:badge sound:sound contentAvailable:nil extra:@{@"1":@"一个消息extra"}];
    [option setApnOption:apnOption];
    
    [YunBaService publish2:targetID data:data option:option resultBlock:^(BOOL succ, NSError *error) {
        if (succ) {
            if (success) {
                success();
            }
        }else{
            if (fail) {
                fail();
            }
        }
    }];
}

@end

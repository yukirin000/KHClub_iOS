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

#import "ChatGroupDetailViewController.h"
#import "OtherPersonalViewController.h"
#import "IMUtils.h"
#import "ContactSelectionViewController.h"
#import "GroupSettingViewController.h"
#import "EMGroup.h"
#import "ContactView.h"
#import "GroupBansViewController.h"
#import "GroupSubjectChangingViewController.h"
#import "QRcodeCardView.h"
#import "ShareAlertPopView.h"
#import "ShareUtils.h"
#import "PushService.h"
#import "CardChooseUserViewController.h"

#pragma mark - ChatGroupDetailViewController

#define kColOfRow 5
#define kContactSize 60

@interface ChatGroupDetailViewController ()<IChatManagerDelegate, EMChooseViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

- (void)unregisterNotifications;
- (void)registerNotifications;

@property (nonatomic        ) GroupOccupantType            occupantType;
@property (strong, nonatomic) EMGroup                      * chatGroup;

@property (nonatomic, strong) UITableView                  * tableView;
@property (strong, nonatomic) NSMutableArray               * dataSource;
@property (strong, nonatomic) UIScrollView                 * scrollView;
@property (strong, nonatomic) UIButton                     * addButton;

@property (strong, nonatomic) UIView                       * footerView;
@property (strong, nonatomic) UIButton                     * clearButton;
@property (strong, nonatomic) UIButton                     * exitButton;
@property (strong, nonatomic) UIButton                     * dissolveButton;
@property (strong, nonatomic) UIButton                     * configureButton;
@property (strong, nonatomic) UILongPressGestureRecognizer * longPress;
@property (strong, nonatomic) ContactView                  * selectedContact;

@property (nonatomic, strong) CustomImageView              * coverImageView;

//分享按钮
@property (nonatomic, strong) ShareAlertPopView            * shareAlertPopView;

- (void)dissolveAction;
- (void)clearAction;
- (void)exitAction;
- (void)configureAction;

@end

@implementation ChatGroupDetailViewController

- (void)registerNotifications {
    [self unregisterNotifications];
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
}

- (void)unregisterNotifications {
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
}

- (void)dealloc {
    [self unregisterNotifications];
}

- (instancetype)initWithGroup:(EMGroup *)chatGroup
{
    self = [super init];
    if (self) {
        // Custom initialization
        _chatGroup    = chatGroup;
        _dataSource   = [NSMutableArray array];
        _occupantType = GroupOccupantTypeMember;
        [self registerNotifications];
    }
    return self;
}

- (instancetype)initWithGroupId:(NSString *)chatGroupId
{
    EMGroup *chatGroup  = nil;
    NSArray *groupArray = [[EaseMob sharedInstance].chatManager groupList];
    for (EMGroup *group in groupArray) {
        if ([group.groupId isEqualToString:chatGroupId]) {
            chatGroup = group;
            break;
        }
    }
    
    if (chatGroup == nil) {
        chatGroup = [EMGroup groupWithId:chatGroupId];
    }
    
    self = [self initWithGroup:chatGroup];
    if (self) {
        //
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
//    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
//    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
//    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
//    [self.navigationItem setLeftBarButtonItem:backItem];
    
    [[IMUtils shareInstance] setGroupNameWith:_chatGroup.groupId and:self.navBar.titleLabel andGroupTitle:_chatGroup.groupSubject];
    
    self.tableView                 = [[UITableView alloc] initWithFrame:CGRectMake(0, kNavBarAndStatusHeight, self.viewWidth, self.viewHeight-kNavBarAndStatusHeight) style:UITableViewStylePlain];
    self.tableView.delegate        = self;
    self.tableView.dataSource      = self;
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];

    self.tableView.tableFooterView = self.footerView;

    UITapGestureRecognizer *tap    = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)];
    tap.cancelsTouchesInView       = NO;
    [self.view addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupBansChanged) name:@"GroupBansChanged" object:nil];
    
    [self fetchGroupInfo];
    
    __weak typeof(self) sself = self;
    self.shareAlertPopView = [[ShareAlertPopView alloc] initWithIsFriend:NO];
    [self.shareAlertPopView setShareBlock:^(ShareAlertType type) {
        switch (type) {
            case ShareAlertFriend:
            {
                [sself sendToFriend];
            }
                break;
            case ShareAlertWechat:
            {
                [ShareUtils shareWechatWithTitle:sself.chatGroup.groupSubject];
            }
                break;
            case ShareAlertWechatMoment:
            {
                [ShareUtils shareWechatMomentsWithTitle:sself.chatGroup.groupSubject];
            }
                break;
            case ShareAlertSina:
            {
                [ShareUtils shareSinaWithTitle:sself.chatGroup.groupSubject];
            }
                break;
            case ShareAlertQQ:
            {
                [ShareUtils shareQQWithTitle:sself.chatGroup.groupSubject];
            }
                break;
            case ShareAlertQzone:
            {
                [ShareUtils shareQzoneWithTitle:sself.chatGroup.groupSubject];
            }
                break;
            default:
                break;
        }
        
        [sself.shareAlertPopView cancelPop];
    }];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - getter

- (UIScrollView *)scrollView
{
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, kContactSize)];
        _scrollView.tag = 0;
        
        _addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kContactSize - 10, kContactSize - 10)];
        [_addButton setImage:[UIImage imageNamed:@"group_participant_add"] forState:UIControlStateNormal];
        [_addButton setImage:[UIImage imageNamed:@"group_participant_addHL"] forState:UIControlStateHighlighted];
        [_addButton addTarget:self action:@selector(addContact:) forControlEvents:UIControlEventTouchUpInside];
        
        _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteContactBegin:)];
        _longPress.minimumPressDuration = 0.5;
    }
    
    return _scrollView;
}

- (UIButton *)clearButton
{
    if (_clearButton == nil) {
        _clearButton = [[UIButton alloc] init];
        [_clearButton setTitle:NSLocalizedString(@"group.removeAllMessages", @"remove all messages") forState:UIControlStateNormal];
        [_clearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_clearButton addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
        [_clearButton setBackgroundColor:[UIColor colorWithHexString:ColorGold]];
    }
    
    return _clearButton;
}

- (UIButton *)dissolveButton
{
    if (_dissolveButton == nil) {
        _dissolveButton = [[UIButton alloc] init];
        [_dissolveButton setTitle:NSLocalizedString(@"group.destroy", @"dissolution of the group") forState:UIControlStateNormal];
        [_dissolveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_dissolveButton addTarget:self action:@selector(dissolveAction) forControlEvents:UIControlEventTouchUpInside];
        [_dissolveButton setBackgroundColor: [UIColor colorWithRed:191 / 255.0 green:48 / 255.0 blue:49 / 255.0 alpha:1.0]];
    }
    
    return _dissolveButton;
}

- (UIButton *)exitButton
{
    if (_exitButton == nil) {
        _exitButton = [[UIButton alloc] init];
        [_exitButton setTitle:NSLocalizedString(@"group.leave", @"quit the group") forState:UIControlStateNormal];
        [_exitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_exitButton addTarget:self action:@selector(exitAction) forControlEvents:UIControlEventTouchUpInside];
        [_exitButton setBackgroundColor:[UIColor colorWithRed:191 / 255.0 green:48 / 255.0 blue:49 / 255.0 alpha:1.0]];
    }
    
    return _exitButton;
}

- (UIView *)footerView
{
    if (_footerView == nil) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 160)];
        _footerView.backgroundColor = [UIColor clearColor];
        
        self.clearButton.frame = CGRectMake(20, 40, _footerView.frame.size.width - 40, 35);
        [_footerView addSubview:self.clearButton];
        
        self.dissolveButton.frame = CGRectMake(20, CGRectGetMaxY(self.clearButton.frame) + 30, _footerView.frame.size.width - 40, 35);
        
        self.exitButton.frame = CGRectMake(20, CGRectGetMaxY(self.clearButton.frame) + 30, _footerView.frame.size.width - 40, 35);
    }
    
    return _footerView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.occupantType == GroupOccupantTypeOwner)
    {
        return 8;
    }
    else
    {
        return 6;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    if (indexPath.row == 0) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.contentView addSubview:self.scrollView];
    }
    else if (indexPath.row == 1)
    {
        cell.textLabel.text = NSLocalizedString(@"group.id", @"group ID");
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = _chatGroup.groupId;
    }
    else if (indexPath.row == 2)
    {
        cell.textLabel.text = NSLocalizedString(@"group.occupantCount", @"members count");
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%i / %i", (int)[_chatGroup.occupants count], (int)_chatGroup.groupSetting.groupMaxUsersCount];
    }
    else if (indexPath.row == 3)
    {
        cell.textLabel.text = NSLocalizedString(@"title.groupSetting", @"Group Setting");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 4)
    {
        cell.textLabel.text = KHClubString(@"Message_GroupDetail_Share");
        cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    }else if (indexPath.row == 5){
        cell.textLabel.text = KHClubString(@"Message_GroupDetail_QRcode");
        cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 6)
    {
        cell.textLabel.text = NSLocalizedString(@"title.groupSubjectChanging", @"Change group name");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }else if (indexPath.row == 7){
        cell.textLabel.text = KHClubString(@"IM_Group_Cover");
        if (self.coverImageView == nil) {
            self.coverImageView       = [[CustomImageView alloc] init];
            self.coverImageView.frame = CGRectMake(self.viewWidth - 60, 5, 40, 40);
            
            [cell.contentView addSubview:self.coverImageView];
            [[IMUtils shareInstance] setGroupImageWith:_chatGroup.groupId and:self.coverImageView];
        }
    }
//    else if (indexPath.row == 5)
//    {
//        cell.textLabel.text = NSLocalizedString(@"title.groupBlackList", @"Group black list");
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//    }
    
    [[cell.contentView viewWithTag:100] removeFromSuperview];
    UIView * line        = [[UIView alloc] initWithFrame:CGRectMake(5, 49, self.viewWidth-10, 1)];
    if (indexPath.row == 0) {
        line.y = self.scrollView.frame.size.height + 39;
    }
    line.tag = 100;
    line.backgroundColor = [UIColor colorWithHexString:ColorLightGary];
    [cell.contentView addSubview:line];

    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = (int)indexPath.row;
    if (row == 0) {
        return self.scrollView.frame.size.height + 40;
    }
    else {
        return 50;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 3) {
        GroupSettingViewController *settingController = [[GroupSettingViewController alloc] initWithGroup:_chatGroup];
        [self.navigationController pushViewController:settingController animated:YES];
    }
    else if (indexPath.row == 4)
    {
        [self.shareAlertPopView show];
    }
    else if (indexPath.row == 5) {
        QRcodeCardView * qcv = [[QRcodeCardView alloc] init];
        [[IMUtils shareInstance] setGroupQrCodeWith:_chatGroup.groupId and:qcv.imageView];
        [qcv show];
    }
    else if (indexPath.row == 6)
    {
        GroupSubjectChangingViewController *changingController = [[GroupSubjectChangingViewController alloc] initWithGroup:_chatGroup];
        [self.navigationController pushViewController:changingController animated:YES];
    }
    else if (indexPath.row == 7) {
//        GroupBansViewController *bansController = [[GroupBansViewController alloc] initWithGroup:_chatGroup];
//        [self.navigationController pushViewController:bansController animated:YES];
        UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:StringCommonCancel destructiveButtonTitle:nil otherButtonTitles:KHClubString(@"Common_Camera"),KHClubString(@"Common_Gallery"), nil];
        sheet.tag             = 50;
        [sheet showInView:self.view];
    }
}

#pragma mark- UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage * image           = [ImageHelper getBigImage:info[UIImagePickerControllerOriginalImage]];

    //上传
    [self showHudInView:self.view hint:@""];
    NSDictionary * params = @{@"group_id": _chatGroup.groupId};
    NSString * fileName   = [ToolsManager getUploadImageName];
    NSArray * files       = @[@{FileDataKey:UIImageJPEGRepresentation(image, 0.9),FileNameKey:fileName}];
    [HttpService postFileWithUrlString:kUpdateGroupCoverPath params:params files:files andCompletion:^(AFHTTPRequestOperation *operation, id responseData) {
        [self hideHud];
        int status = [responseData[@"status"] intValue];
        if (status == HttpStatusCodeSuccess) {
            self.coverImageView.image = image;            
            NSDictionary * topicDic = responseData[HttpResult];
            //缓存二维码和图片
            [[IMUtils shareInstance] saveGroupImage:topicDic[@"group_cover"] groupName:topicDic[@"group_id"]];
            [[IMUtils shareInstance] saveQrCode:topicDic[@"group_qr_code"] groupName:topicDic[@"group_id"]];
            
        }else{
            [self showHint:StringCommonNetException];
        }
    } andFail:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self hideHud];
        [self showHint:StringCommonNetException];
    }];    
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EMChooseViewDelegate
- (void)viewController:(EMChooseViewController *)viewController didFinishSelectedSources:(NSArray *)selectedSources
{
    
    if (selectedSources.count < 1) {
        return;
    }
    
    if (self.occupantType == GroupOccupantTypeMember) {
        //发送邀请推送
        EMBuddy * buddy               = selectedSources[0];
        NSMutableDictionary * pushDic = [[NSMutableDictionary alloc] init];
        [pushDic setObject:[NSString stringWithFormat:@"%ld", PushGroupInvite] forKey:@"type"];
        [pushDic setObject:@{@"uid":[NSString stringWithFormat:@"%ld", [UserService sharedService].user.uid],
                             @"name":[UserService sharedService].user.name,
                             @"targetid":buddy.username,
                             @"groupid":self.chatGroup.groupId,
                             @"groupname":self.chatGroup.groupSubject} forKey:@"content"];
        
        [[PushService sharedInstance] pushGroupInviteMessageWith:pushDic andTarget:self.chatGroup.owner success:^{
            [self showHint:KHClubString(@"IM_Push_InviteSuccess")];
        } fail:^{
            [self showHint:StringCommonNetException];
        }];
        return;
    }
    
    NSInteger maxUsersCount = _chatGroup.groupSetting.groupMaxUsersCount;
    if (([selectedSources count] + _chatGroup.groupOccupantsCount) > maxUsersCount) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"group.maxUserCount", nil) message:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    [self showHudInView:self.view hint:NSLocalizedString(@"group.addingOccupant", @"add a group member...")];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *source = [NSMutableArray array];
        for (EMBuddy *buddy in selectedSources) {
            [source addObject:buddy.username];
        }
        
        NSDictionary *loginInfo = [[[EaseMob sharedInstance] chatManager] loginInfo];
        NSString *username      = [loginInfo objectForKey:kSDKUsername];
        NSString *messageStr    = [NSString stringWithFormat:NSLocalizedString(@"group.somebodyInvite", @"%@ invite you to join group \'%@\'"), username, weakSelf.chatGroup.groupSubject];
        EMError *error          = nil;
        weakSelf.chatGroup      = [[EaseMob sharedInstance].chatManager addOccupants:source toGroup:weakSelf.chatGroup.groupId welcomeMessage:messageStr error:&error];
        if (!error) {
            [weakSelf reloadDataSource];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf hideHud];
                [weakSelf showHint:error.description];
            });
        }
    });
    
}

- (void)groupBansChanged
{
    [self.dataSource removeAllObjects];
    [self.dataSource addObjectsFromArray:self.chatGroup.occupants];
    [self refreshScrollView];
}

#pragma mark - data

- (void)fetchGroupInfo
{
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    [[EaseMob sharedInstance].chatManager asyncFetchGroupInfo:_chatGroup.groupId completion:^(EMGroup *group, EMError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (!error) {
                weakSelf.chatGroup = group;
                [weakSelf reloadDataSource];
            }
            else{
                [weakSelf showHint:NSLocalizedString(@"group.fetchInfoFail", @"failed to get the group details, please try again later")];
            }
        });
    } onQueue:nil];
}

- (void)reloadDataSource
{
    [self.dataSource removeAllObjects];
    
    self.occupantType = GroupOccupantTypeMember;
    NSDictionary *loginInfo = [[[EaseMob sharedInstance] chatManager] loginInfo];
    NSString *loginUsername = [loginInfo objectForKey:kSDKUsername];
    if ([self.chatGroup.owner isEqualToString:loginUsername]) {
        self.occupantType = GroupOccupantTypeOwner;
    }
    
    if (self.occupantType != GroupOccupantTypeOwner) {
        for (NSString *str in self.chatGroup.members) {
            if ([str isEqualToString:loginUsername]) {
                self.occupantType = GroupOccupantTypeMember;
                break;
            }
        }
    }
    
    [self.dataSource addObjectsFromArray:self.chatGroup.occupants];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshScrollView];
        [self refreshFooterView];
        [self hideHud];
    });
}

- (void)refreshScrollView
{
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.scrollView removeGestureRecognizer:_longPress];
    [self.addButton removeFromSuperview];
    
    BOOL showAddButton = NO;
    if (self.occupantType == GroupOccupantTypeOwner) {
        [self.scrollView addGestureRecognizer:_longPress];
        [self.scrollView addSubview:self.addButton];
        showAddButton = YES;
    }
    else if (self.chatGroup.groupSetting.groupStyle == eGroupStyle_PrivateMemberCanInvite && self.occupantType == GroupOccupantTypeMember) {
        [self.scrollView addSubview:self.addButton];
        showAddButton = YES;
    }else if (self.occupantType == GroupOccupantTypeMember) {
        //如果是成员也提供邀请功能
        [self.scrollView addSubview:self.addButton];
        showAddButton = YES;
    }
    
    int tmp = ([self.dataSource count] + 1) % kColOfRow;
    int row = (int)([self.dataSource count] + 1) / kColOfRow;
    row += tmp == 0 ? 0 : 1;
    self.scrollView.tag = row;
    self.scrollView.frame = CGRectMake(10, 20, self.tableView.frame.size.width - 20, row * kContactSize);
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, row * kContactSize);
    
    NSDictionary *loginInfo = [[[EaseMob sharedInstance] chatManager] loginInfo];
    NSString *loginUsername = [loginInfo objectForKey:kSDKUsername];
    
    int i = 0;
    int j = 0;
    BOOL isEditing = self.addButton.hidden ? YES : NO;
    BOOL isEnd = NO;
    for (i = 0; i < row; i++) {
        for (j = 0; j < kColOfRow; j++) {
            NSInteger index = i * kColOfRow + j;
            if (index < [self.dataSource count]) {
                NSString *username = [self.dataSource objectAtIndex:index];
                ContactView *contactView = [[ContactView alloc] initWithFrame:CGRectMake(j * kContactSize, i * kContactSize, kContactSize, kContactSize)];
                contactView.index = i * kColOfRow + j;
                contactView.image = [UIImage imageNamed:@"chatListCellHead.png"];
                contactView.remark = username;
                
                UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headPress:)];
                [contactView addGestureRecognizer:tap];
                
                if (![username isEqualToString:loginUsername]) {
                    contactView.editing = isEditing;
                }
                
                __weak typeof(self) weakSelf = self;
                [contactView setDeleteContact:^(NSInteger index) {
                    [weakSelf showHudInView:weakSelf.view hint:NSLocalizedString(@"group.removingOccupant", @"deleting member...")];
                    NSArray *occupants = [NSArray arrayWithObject:[weakSelf.dataSource objectAtIndex:index]];
                    [[EaseMob sharedInstance].chatManager asyncRemoveOccupants:occupants fromGroup:weakSelf.chatGroup.groupId completion:^(EMGroup *group, EMError *error) {
                        [weakSelf hideHud];
                        if (!error) {
                            weakSelf.chatGroup = group;
                            [weakSelf.dataSource removeObjectAtIndex:index];
                            [weakSelf refreshScrollView];
                        }
                        else{
                            [weakSelf showHint:error.description];
                        }
                    } onQueue:nil];
                }];
                
                [self.scrollView addSubview:contactView];
                
            }
            else{
                if(showAddButton && index == self.dataSource.count)
                {
                    self.addButton.frame = CGRectMake(j * kContactSize + 5, i * kContactSize + 10, kContactSize - 10, kContactSize - 10);
                }
                
                isEnd = YES;
                break;
            }
        }
        
        if (isEnd) {
            break;
        }
    }
    
    [self.tableView reloadData];
}

- (void)refreshFooterView
{
    if (self.occupantType == GroupOccupantTypeOwner) {
        [_exitButton removeFromSuperview];
        [_footerView addSubview:self.dissolveButton];
    }
    else{
        [_dissolveButton removeFromSuperview];
        [_footerView addSubview:self.exitButton];
    }
}

#pragma mark - action
- (void)sendToFriend
{
    CardChooseUserViewController * ccuvc = [[CardChooseUserViewController alloc] init];
    
    NSDictionary * cardDic = @{@"type":[@(eConversationTypeGroupChat) stringValue],
                               @"id":self.chatGroup.groupId,
                               @"title":self.chatGroup.groupSubject,
                               @"avatar":@""};
    NSString * cardJson = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:cardDic options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
    ccuvc.cardMessage   = [@"###card^card###" stringByReplacingOccurrencesOfString:@"^" withString:cardJson];
    [self presentViewController:ccuvc animated:YES completion:nil];
}

- (void)headPress:(UITapGestureRecognizer *)tap
{
    ContactView * contact = (ContactView *)tap.view;
    if (contact.remark.length > 0) {
        OtherPersonalViewController * opvc = [[OtherPersonalViewController alloc] init];
        opvc.uid                           = [[contact.remark stringByReplacingOccurrencesOfString:KH withString:@""] integerValue];
        [self pushVC:opvc];
    }
}

- (void)tapView:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateEnded)
    {
        if (self.addButton.hidden) {
            [self setScrollViewEditing:NO];
        }
    }
}

- (void)deleteContactBegin:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan)
    {
        NSDictionary *loginInfo = [[[EaseMob sharedInstance] chatManager] loginInfo];
        NSString *loginUsername = [loginInfo objectForKey:kSDKUsername];
        for (ContactView *contactView in self.scrollView.subviews)
        {
            CGPoint locaton = [longPress locationInView:contactView];
            if (CGRectContainsPoint(contactView.bounds, locaton))
            {
                if ([contactView isKindOfClass:[ContactView class]]) {
                    if ([contactView.remark isEqualToString:loginUsername]) {
                        return;
                    }
                    _selectedContact = contactView;
                    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"delete", @"deleting member..."), nil];
                    [sheet showInView:self.view];
                }
            }
        }
    }
}

- (void)setScrollViewEditing:(BOOL)isEditing
{
    NSDictionary *loginInfo = [[[EaseMob sharedInstance] chatManager] loginInfo];
    NSString *loginUsername = [loginInfo objectForKey:kSDKUsername];
    
    for (ContactView *contactView in self.scrollView.subviews)
    {
        if ([contactView isKindOfClass:[ContactView class]]) {
            if ([contactView.remark isEqualToString:loginUsername]) {
                continue;
            }
            [contactView setEditing:isEditing];
        }
    }
    
    self.addButton.hidden = isEditing;
}

- (void)addContact:(id)sender
{
    ContactSelectionViewController *selectionController = [[ContactSelectionViewController alloc] initWithBlockSelectedUsernames:_chatGroup.occupants];
    if (self.occupantType == GroupOccupantTypeMember) {
        selectionController.isInvite = YES;
    }
    selectionController.delegate = self;
    [self.navigationController pushViewController:selectionController animated:YES];
}

//清空聊天记录
- (void)clearAction
{
    __weak typeof(self) weakSelf = self;
    [EMAlertView showAlertWithTitle:NSLocalizedString(@"prompt", @"Prompt")
                            message:NSLocalizedString(@"sureToDelete", @"please make sure to delete")
                    completionBlock:^(NSUInteger buttonIndex, EMAlertView *alertView) {
                        if (buttonIndex == 1) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveAllMessages" object:weakSelf.chatGroup.groupId];
                        }
                    } cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel")
                  otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
    
}

//解散群组
- (void)dissolveAction
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"group.dismissed", @"The group will be dismissed after exiting") message:nil delegate:self cancelButtonTitle:StringCommonCancel otherButtonTitles:StringCommonConfirm, nil];
    [alert show];
    //    [[EaseMob sharedInstance].chatManager asyncLeaveGroup:_chatGroup.groupId];
}

//设置群组
- (void)configureAction {
    // todo
    [[[EaseMob sharedInstance] chatManager] asyncIgnoreGroupPushNotification:_chatGroup.groupId
                                                                    isIgnore:_chatGroup.isPushNotificationEnabled];
    
//    return;
//    UIViewController *viewController = [[UIViewController alloc] init];
//    [self.navigationController pushViewController:viewController animated:YES];
}

//退出群组
- (void)exitAction
{
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"group.leave", @"quit the group")];
    [[EaseMob sharedInstance].chatManager asyncLeaveGroup:_chatGroup.groupId completion:^(EMGroup *group, EMGroupLeaveReason reason, EMError *error) {
        [weakSelf hideHud];
        if (error) {
            [weakSelf showHint:NSLocalizedString(@"group.leaveFail", @"exit the group failure")];
        }
        else{
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"ExitGroup" object:nil];
            [self popToTabBarViewController];
        }
    } onQueue:nil];
    
    //    [[EaseMob sharedInstance].chatManager asyncLeaveGroup:_chatGroup.groupId];
}

//- (void)group:(EMGroup *)group didLeave:(EMGroupLeaveReason)reason error:(EMError *)error {
//    __weak ChatGroupDetailViewController *weakSelf = self;
//    [weakSelf hideHud];
//    if (error) {
//        if (reason == eGroupLeaveReason_UserLeave) {
//            [weakSelf showHint:@"退出群组失败"];
//        } else {
//            [weakSelf showHint:@"解散群组失败"];
//        }
//    }
//}

- (void)didIgnoreGroupPushNotification:(NSArray *)ignoredGroupList error:(EMError *)error {
    // todo
    NSLog(@"ignored group list:%@.", ignoredGroupList);
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 50) {
        //选照片
        if (buttonIndex != 2) {
            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
            if (buttonIndex == 0) {
                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                    [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
                }
            }
            if (buttonIndex == 1) {
                [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            }
            picker.delegate = self;
            [self presentViewController:picker animated:YES completion:nil];
        }
        
        return;
    }
    
    NSInteger index = _selectedContact.index;
    if (buttonIndex == 0)
    {
        //delete
        _selectedContact.deleteContact(index);
    }
//    else if (buttonIndex == 1)
//    {
//        //add to black list
//        [self showHudInView:self.view hint:NSLocalizedString(@"group.ban.adding", @"Adding to black list..")];
//        NSArray *occupants = [NSArray arrayWithObject:[self.dataSource objectAtIndex:_selectedContact.index]];
//        __weak ChatGroupDetailViewController *weakSelf = self;
//        [[EaseMob sharedInstance].chatManager asyncBlockOccupants:occupants fromGroup:self.chatGroup.groupId completion:^(EMGroup *group, EMError *error) {
//            if (weakSelf)
//            {
//                __weak ChatGroupDetailViewController *strongSelf = weakSelf;
//                [strongSelf hideHud];
//                if (!error) {
//                    strongSelf.chatGroup = group;
//                    [strongSelf.dataSource removeObjectAtIndex:index];
//                    [strongSelf refreshScrollView];
//                }
//                else{
//                    [strongSelf showHint:error.description];
//                }
//            }
//        } onQueue:nil];
//    }
    _selectedContact = nil;
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
    _selectedContact = nil;
}
#pragma mark- UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        __weak typeof(self) weakSelf = self;
        [self showHudInView:self.view hint:NSLocalizedString(@"group.destroy", @"dissolution of the group")];
        [[EaseMob sharedInstance].chatManager asyncDestroyGroup:_chatGroup.groupId completion:^(EMGroup *group, EMGroupLeaveReason reason, EMError *error) {
            [weakSelf hideHud];
            if (error) {
                [weakSelf showHint:NSLocalizedString(@"group.destroyFail", @"dissolution of group failure")];
            }
            else{
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExitGroup" object:nil];
                [self popToTabBarViewController];
            }
        } onQueue:nil];
    }
    
}

@end

//
//  NewsListViewController.m
//  KHClub_iOS
//
//  Created by 李晓航 on 15/11/3.
//  Copyright © 2015年 JLXC. All rights reserved.
//

#import "NewsListViewController.h"
#import "NewsDetailViewController.h"
#import "PublishNewsViewController.h"
#import "NewsModel.h"
#import "ImageModel.h"
#import "CommentModel.h"
#import "LikeModel.h"
#import "BrowseImageListViewController.h"
#import "NewsListCell.h"
#import "HttpCache.h"
#import "NewsUtils.h"
#import "NotifyNewsViewController.h"

@interface NewsListViewController ()<NewsListDelegate>

//需要复制的字符串
@property (nonatomic, copy) NSString * pasteStr;
/**
 *  左上角未读红点
 */
//@property (nonatomic, strong) UIView * unreadView;

@end

@implementation NewsListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initWidget];
    [self configUI];
    
    [self refreshData];
    [self registerNotify];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.view sendSubviewToBack:self.navigationController.navigationBar];
    
}

#pragma mark- layout
- (void)initWidget
{
//    self.unreadView = [[UIView alloc] init];
//    [self.navBar addSubview:self.unreadView];
}

- (void)configUI
{
//    [self setNavBarTitle:KHClubString(@"Common_Main_Home")];
//    
//    __weak typeof(self) sself = self;
//    //左上角通知
//    [self.navBar setLeftBtnWithContent:@"" andBlock:^{
//        NotifyNewsViewController * nnvc = [[NotifyNewsViewController alloc] init];
//        [sself pushVC:nnvc];
//    }];
//    //右上角发布
//    [self.navBar setRightBtnWithContent:@"" andBlock:^{
//        PublishNewsViewController * pnvc = [[PublishNewsViewController alloc] init];
//        [sself pushVC:pnvc];
//    }];
//    
//    
//    self.navBar.leftBtn.hidden = NO;
//    self.navBar.leftBtn.imageEdgeInsets        = UIEdgeInsetsMake(2, 6, 0, 16);
//    self.navBar.leftBtn.imageView.contentMode  = UIViewContentModeScaleAspectFit;
//    self.navBar.rightBtn.imageEdgeInsets       = UIEdgeInsetsMake(12, 26, 12, 0);
//    self.navBar.rightBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
//    
//    [self.navBar.leftBtn setImage:[UIImage imageNamed:@"news_notice_normal"] forState:UIControlStateNormal];
//    [self.navBar.rightBtn setImage:[UIImage imageNamed:@"news_publish_normal"] forState:UIControlStateNormal];
//    
//    //未读
//    self.unreadView.frame              = CGRectMake(30, 29, 6, 6);
//    self.unreadView.layer.cornerRadius = 3;
//    self.unreadView.backgroundColor    = [UIColor redColor];
    self.navBar.hidden          = YES;
    self.refreshTableView.frame = CGRectMake(0, 0, self.viewWidth, self.viewHeight-kNavBarAndStatusHeight-kTabBarHeight);
}

#pragma mark- override
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

//下拉刷新
- (void)refreshData
{
    [super refreshData];
    [self loadAndhandleData];
}
//加载更多
- (void)loadingData
{
    [super loadingData];
    [self loadAndhandleData];
}

#pragma mark- UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewsDetailViewController * ndvc = [[NewsDetailViewController alloc] init];
    NewsModel * news                = self.dataArr[indexPath.row];
    ndvc.newsId                     = news.nid;
    [self pushVC:ndvc];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString * cellid   = [NSString stringWithFormat:@"%@%ld", @"newsList", indexPath.row];
    NewsListCell * cell = [self.refreshTableView dequeueReusableCellWithIdentifier:cellid];
    if (!cell) {
        cell          = [[NewsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid];
        cell.delegate = self;
    }
    [cell setConentWithModel:self.dataArr[indexPath.row]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewsModel * news          = self.dataArr[indexPath.row];
    
    return [self getCellHeightWith:news];
}

#pragma mark- NewsListDelegate
- (void)longPressContent:(NewsModel *)news andGes:(UILongPressGestureRecognizer *)ges
{
    [self becomeFirstResponder];
    self.pasteStr                    = news.content_text;
    UIView * view                    = ges.view;
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem * copyItem            = [[UIMenuItem alloc] initWithTitle:KHClubString(@"Common_Copy") action:@selector(copyContnet)];
    UIMenuItem * cancelItem          = [[UIMenuItem alloc] initWithTitle:StringCommonCancel action:@selector(cancel)];
    [menuController setMenuItems:@[copyItem,cancelItem]];
    [menuController setArrowDirection:UIMenuControllerArrowDown];
    [menuController setTargetRect:view.frame inView:view.superview];
    [menuController setMenuVisible:YES animated:YES];
}

//图片点击
- (void)imageClick:(NewsModel *)news index:(NSInteger)index
{
    
    BrowseImageListViewController * bilvc = [[BrowseImageListViewController alloc] init];
    bilvc.num                             = index;
    bilvc.dataSource                      = news.image_arr;
    [self presentViewController:bilvc animated:YES completion:nil];
    
}

//发送评论
- (void)sendCommentClick:(NewsModel *)news
{
    NewsDetailViewController * ndvc = [[NewsDetailViewController alloc] init];
    ndvc.newsId                     = news.nid;
    [self pushVC:ndvc];
}
//点赞
- (void)likeClick:(NewsModel *)news likeOrCancel:(BOOL)flag
{
    //news_id=23&user_id=1&is_second=0&isLike=1
    NSDictionary * params = @{@"user_id":[NSString stringWithFormat:@"%ld", [UserService sharedService].user.uid],
                              @"news_id":[NSString stringWithFormat:@"%ld", news.nid],
                              @"isLike":[NSString stringWithFormat:@"%d", flag],
                              @"is_second":@"0"};
    debugLog(@"%@ %@", kLikeOrCancelPath, params);
    
    //成功失败都没反应
    [HttpService postWithUrlString:kLikeOrCancelPath params:params andCompletion:^(AFHTTPRequestOperation *operation, id responseData) {
        //        debugLog(@"%@", responseData);
    } andFail:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}


#pragma mark- method response
//复制
- (void)copyContnet
{
    //得到剪切板
    UIPasteboard *board = [UIPasteboard generalPasteboard];
    board.string        = self.pasteStr;
    self.pasteStr       = @"";
    debugLog(@"%@",[UIPasteboard generalPasteboard].string);
}
//取消menu
- (void)cancel
{}

#pragma mark- private method
- (void)loadAndhandleData
{
    
    //最后一次时间
    NSString * first_time = @"0";
    if (!self.isReloading && self.dataArr.count > 0) {
        NewsModel * news = self.dataArr.firstObject;
        first_time        = news.publish_time;
    }
    
    NSString * url = [NSString stringWithFormat:@"%@?page=%d&user_id=%ld&frist_time=%@", kNewsListPath, self.currentPage, [UserService sharedService].user.uid, first_time];
    debugLog(@"%@", url);
    [HttpService getWithUrlString:url andCompletion:^(AFHTTPRequestOperation *operation, id responseData) {
        //        debugLog(@"%@", responseData);
        int status = [responseData[HttpStatus] intValue];
        if (status == HttpStatusCodeSuccess) {
            
            //下拉刷新清空数组
            if (self.isReloading) {
                [self.dataArr removeAllObjects];
            }
            self.isLastPage = [responseData[HttpResult][@"is_last"] boolValue];
            NSArray * list = responseData[HttpResult][HttpList];
            //注入数据刷新页面
            [self injectDataSourceWith:list];
            
        }else{
            self.isReloading = NO;
            [self.refreshTableView refreshFinish];
            [self showWarn:StringCommonNetException];
        }
        
    } andFail:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.isReloading = NO;
        [self.refreshTableView refreshFinish];
        [self showWarn:StringCommonNetException];
    }];
    
}

//数据注入
- (void)injectDataSourceWith:(NSArray *)list
{
    //数据处理
    for (NSDictionary * newsDic in list) {
        NewsModel * news      = [[NewsModel alloc] init];
        [news setContentWithDic:newsDic];
        [self.dataArr addObject:news];
    }
    
    [self reloadTable];
}

//注册通知
- (void)registerNotify
{
    //刷新页面
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newNewsPublish:) name:NOTIFY_PUBLISH_NEWS object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshNotify:) name:NOTIFY_NEWS_PUSH object:nil];
//    [self refreshNotify:nil];
}

//- (void)refreshNotify:(id)sender
//{
//    
//    //徽标 最多显示99
//    //未读推送
//    NSInteger newsUnreadCount = [NewsPushModel findUnreadCount].count;
//    if (newsUnreadCount > 0) {
//        self.unreadView.hidden = NO;
//    }else{
//        self.unreadView.hidden = YES;
//    }
//
//}

//新消息发布成功刷新页面
- (void)newNewsPublish:(NSNotification *)notify
{
    
    self.refreshTableView.contentOffset = CGPointZero;
    [self refreshData];
}

- (CGFloat)getCellHeightWith:(NewsModel *)news
{
    CGSize contentSize        = [ToolsManager getSizeWithContent:news.content_text andFontSize:15 andFrame:CGRectMake(0, 0, self.viewWidth-30, MAXFLOAT)];
    if (news.content_text == nil || news.content_text.length < 1) {
        contentSize.height = 0;
    }
    //头像55 评论按钮30 还有10的底线
    NSInteger cellOtherHeight = 55+30+10;
    
    CGFloat height;
    if (news.image_arr.count < 1) {
        //没有图片
        height = cellOtherHeight+contentSize.height+5;
    }else if (news.image_arr.count == 1) {
        //一张图片 大图
        ImageModel * imageModel = news.image_arr[0];
        CGSize size             = CGSizeMake(imageModel.width, imageModel.height);
        CGRect rect             = [NewsUtils getRectWithSize:size];
        height                  = cellOtherHeight+contentSize.height+rect.size.height+10;
    }else{
        //多张图片九宫格
        NSInteger lineNum   = news.image_arr.count/3;
        NSInteger columnNum = news.image_arr.count%3;
        if (columnNum > 0) {
            lineNum++;
        }
        CGFloat itemWidth = [DeviceManager getDeviceWidth]/5.0;
        height            = cellOtherHeight+contentSize.height+lineNum*(itemWidth+10);
    }
    
    //地址
    if (news.location.length > 0) {
        height += 25;
    }
    //点赞列表
    if (news.like_arr.count > 0) {
        CGFloat width = ([DeviceManager getDeviceWidth]-53-27)/8;
        height += width+5;
    }
    
    //评论
    for (int i=0; i<news.comment_arr.count; i++) {
        CommentModel * comment = news.comment_arr[i];
        NSString * commentStr  = [NSString stringWithFormat:@"%@:%@", comment.name, comment.comment_content];
        CGSize nameSize        = [ToolsManager getSizeWithContent:commentStr andFontSize:14 andFrame:CGRectMake(0, 0, self.viewWidth-30, MAXFLOAT)];
        height                 = height + nameSize.height+5;
    }
    
    return height;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

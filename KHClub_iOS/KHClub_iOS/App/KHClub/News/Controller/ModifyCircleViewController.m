//
//  ModifyCircleViewController.m
//  KHClub_iOS
//
//  Created by 李晓航 on 15/12/11.
//  Copyright © 2015年 JLXC. All rights reserved.
//

#import "ModifyCircleViewController.h"
#import "UIImageView+WebCache.h"

@interface ModifyCircleViewController ()<UITextFieldDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIScrollView    * backScrollView;
//封面
@property (nonatomic, strong) CustomImageView * circleImageView;
//封面上的提示label
@property (nonatomic, strong) CustomLabel     * coverLabel;
//圈子昵称
@property (nonatomic, strong) UITextField     * circleNameTextField;
//圈子介绍
@property (nonatomic, strong) UITextField     * circleIntroTextField;
//圈子地址
@property (nonatomic, strong) UITextField     * circleAddressTextField;
//圈子电话
@property (nonatomic, strong) UITextField     * circlePhoneTextField;
//圈子公众号
@property (nonatomic, strong) UITextField     * wxTextField;
//二维码图片
@property (nonatomic, strong) CustomImageView * wxQRcodeImageView;
//圈子网址
@property (nonatomic, strong) UITextField     * circleWebTextField;
//当前图片类型 1是封面 2是二维码
@property (nonatomic, assign) NSInteger       currentImageType;
//封面修改
@property (nonatomic, assign) BOOL            coverChanged;
//二维码修改
@property (nonatomic, assign) BOOL            qrcodeChanged;

@end

@implementation ModifyCircleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor colorWithHexString:ColorLightWhite];
    
    __weak typeof(self) sself = self;
    [self.navBar setRightBtnWithContent:StringCommonSubmit andBlock:^{
        [sself createCircleVerify];
    }];
    
    [self initWidget];
    [self configUI];
    [self setData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- layout
- (void)initWidget
{
    self.backScrollView     = [[UIScrollView alloc] init];
    self.circleImageView    = [[CustomImageView alloc] init];
    self.coverLabel         = [[CustomLabel alloc] init];
    self.wxQRcodeImageView  = [[CustomImageView alloc] init];
    
    [self.view addSubview:self.backScrollView];
    [self.circleImageView addSubview:self.coverLabel];
    [self.backScrollView addSubview:self.circleImageView];
    [self.backScrollView addSubview:self.wxQRcodeImageView];
    
    //选择图片手势
    UITapGestureRecognizer * tap   = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleImageTap:)];
    [self.circleImageView addGestureRecognizer:tap];
    
    //选择图片手势
    UITapGestureRecognizer * qrTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(qrImageTap:)];
    [self.wxQRcodeImageView addGestureRecognizer:qrTap];
    
    //收键盘
    UITapGestureRecognizer * scrollTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollTap:)];
    [self.backScrollView addGestureRecognizer:scrollTap];
}

- (void)configUI
{
    
    self.navBar.rightBtn.titleLabel.font             = [UIFont systemFontOfSize:13];
    [self setNavBarTitle:KHClubString(@"Circle_CreateCircle_Title")];
    //背景
    self.backScrollView.frame                        = CGRectMake(0, kNavBarAndStatusHeight, self.viewWidth, self.viewHeight-kNavBarAndStatusHeight);
    self.backScrollView.showsVerticalScrollIndicator = NO;
    //图片
    self.circleImageView.frame                        = CGRectMake(kCenterOriginX(100), 40, 100, 100);
    self.circleImageView.backgroundColor              = [UIColor colorWithHexString:ColorGary];
    self.circleImageView.userInteractionEnabled       = YES;
    self.circleImageView.layer.masksToBounds          = YES;
    self.circleImageView.contentMode                  = UIViewContentModeScaleAspectFill;
    
    self.coverLabel.backgroundColor                  = [UIColor colorWithWhite:0.3 alpha:0.5];
    self.coverLabel.frame                            = CGRectMake(0, 70, 100, 30);
    self.coverLabel.font                             = [UIFont systemFontOfSize:13];
    self.coverLabel.textAlignment                    = NSTextAlignmentCenter;
    self.coverLabel.text                             = KHClubString(@"Message_Create_Cover");
    self.coverLabel.textColor                        = [UIColor colorWithHexString:ColorWhite];
    
    //圈子昵称
    self.circleNameTextField                      = [self getCommonTextFieldWithPlaceHolder:@"昵称"];
    //圈子介绍
    self.circleIntroTextField                     = [self getCommonTextFieldWithPlaceHolder:@"介绍"];
    //圈子地址
    self.circleAddressTextField                   = [self getCommonTextFieldWithPlaceHolder:@"地址"];
    //圈子电话
    self.circlePhoneTextField                     = [self getCommonTextFieldWithPlaceHolder:@"电话"];
    //圈子公众号
    self.wxTextField                              = [self getCommonTextFieldWithPlaceHolder:@"公众号"];
    //圈子网址
    self.circleWebTextField                       = [self getCommonTextFieldWithPlaceHolder:@"网址"];
    //布局
    self.circleNameTextField.y                    = self.circleImageView.bottom+30;
    self.circleIntroTextField.y                   = self.circleNameTextField.bottom+10;
    self.circleAddressTextField.y                 = self.circleIntroTextField.bottom+10;
    self.circlePhoneTextField.y                   = self.circleAddressTextField.bottom+10;
    self.wxTextField.y                            = self.circlePhoneTextField.bottom+10;
    
    self.wxQRcodeImageView.frame                  = CGRectMake(30, self.wxTextField.bottom+10, 50, 50);
    self.wxQRcodeImageView.backgroundColor        = [UIColor colorWithHexString:ColorGary];
    self.wxQRcodeImageView.userInteractionEnabled = YES;
    self.wxQRcodeImageView.layer.masksToBounds    = YES;
    self.wxQRcodeImageView.contentMode            = UIViewContentModeScaleAspectFill;
    
    self.circleWebTextField.y                     = self.wxQRcodeImageView.bottom+10;
    
    if (self.circleWebTextField.bottom > self.backScrollView.height) {
        self.backScrollView.contentSize = CGSizeMake(0, self.circleWebTextField.bottom+30);
    }else{
        self.backScrollView.contentSize = CGSizeMake(0, self.backScrollView.height+1);
    }
    
    __weak typeof(self) sself = self;
    [self.navBar setLeftBtnWithContent:@"" andBlock:^{
        [sself dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)setData
{
    //封面
    [self.circleImageView sd_setImageWithURL:[NSURL URLWithString:[ToolsManager completeUrlStr:self.circleModel.circle_cover_sub_image]]];
    //公众号二维码
    [self.wxQRcodeImageView sd_setImageWithURL:[NSURL URLWithString:[ToolsManager completeUrlStr:self.circleModel.wx_qrcode]]];
    //名字
    self.circleNameTextField.text    = self.circleModel.circle_name;
    //详情
    self.circleIntroTextField.text   = self.circleModel.circle_detail;
    //地址
    self.circleAddressTextField.text = self.circleModel.address;
    //电话
    self.circlePhoneTextField.text   = self.circleModel.phone_num;
    //公众号
    self.wxTextField.text            = self.circleModel.wx_num;
    //网址
    self.circleWebTextField.text     = self.circleModel.circle_web;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        
        
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark- UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.currentImageType = actionSheet.tag;
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
    
}

#pragma mark- UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage * image           = [ImageHelper getBigImage:info[UIImagePickerControllerOriginalImage]];
    if (self.currentImageType == 1) {
        self.coverLabel.hidden     = YES;
        self.circleImageView.image = image;
        //封面修改
        self.coverChanged          = YES;
    }else{
        self.wxQRcodeImageView.image = image;
        //二维码修改
        self.qrcodeChanged           = YES;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - method response

- (void)circleImageTap:(UITapGestureRecognizer *)sender
{
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:StringCommonCancel destructiveButtonTitle:nil otherButtonTitles:KHClubString(@"Common_Camera"),KHClubString(@"Common_Gallery"), nil];
    sheet.tag             = 1;
    [sheet showInView:self.view];
}

- (void)qrImageTap:(UITapGestureRecognizer *)sender
{
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:StringCommonCancel destructiveButtonTitle:nil otherButtonTitles:KHClubString(@"Common_Camera"),KHClubString(@"Common_Gallery"), nil];
    sheet.tag             = 2;
    [sheet showInView:self.view];
}

- (void)scrollTap:(UITapGestureRecognizer *)sender
{
    [self.circleNameTextField resignFirstResponder];
    [self.circleIntroTextField resignFirstResponder];
    [self.circleAddressTextField resignFirstResponder];
    [self.circlePhoneTextField resignFirstResponder];
    [self.wxTextField resignFirstResponder];
    [self.circleWebTextField resignFirstResponder];
}

#pragma mark- private method
- (UITextField *)getCommonTextFieldWithPlaceHolder:(NSString *)placeHolder
{
    
    UITextField * textField            = [[UITextField alloc] initWithFrame:CGRectMake(kCenterOriginX(300), 0, 300, 40)];
    textField.layer.borderColor        = [[UIColor lightGrayColor] CGColor];
    textField.layer.borderWidth        = 0.5;
    textField.layer.cornerRadius       = 3;
    textField.leftView                 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 30)];
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.leftViewMode             = UITextFieldViewModeAlways;
    textField.clearButtonMode          = UITextFieldViewModeWhileEditing;
    textField.font                     = [UIFont systemFontOfSize:15.0];
    textField.backgroundColor          = [UIColor whiteColor];
    textField.placeholder              = placeHolder;
    textField.delegate                 = self;
    
    [self.backScrollView addSubview:textField];
    
    return textField;
}

/**
 *  创建圈子验证
 */
- (void)createCircleVerify
{
    
    //标题不能为空
    if (self.circleNameTextField.text.length < 1) {
        [self showHint:KHClubString(@"Circle_CreateCircle_NameNotNull")];
        return;
    }
    //不能超过7位
    if (self.circleNameTextField.text.length > 7) {
        [self showHint:KHClubString(@"Circle_CreateCircle_NameTooLong")];
        return;
    }
    
    if (self.circleIntroTextField.text.length > 200) {
        [self showHint:KHClubString(@"Circle_CreateCircle_DetailTooLong")];
        return;
    }
    if (self.circleAddressTextField.text.length > 50) {
        [self showHint:KHClubString(@"Circle_CreateCircle_AddressTooLong")];
        return;
    }
    if (self.circlePhoneTextField.text.length > 50) {
        [self showHint:KHClubString(@"Circle_CreateCircle_PhoneTooLong")];
        return;
    }
    if (self.wxTextField.text.length > 50) {
        [self showHint:KHClubString(@"Circle_CreateCircle_WxTooLong")];
        return;
    }
    if (self.circleWebTextField.text.length > 50) {
        [self showHint:KHClubString(@"Circle_CreateCircle_WebTooLong")];
        return;
    }
    
    [self modifyCircle];
    
}

/**
 *  创建圈子提交
 */
- (void)modifyCircle
{
    
//    NSDictionary * params = @{@"user_id":[NSString stringWithFormat:@"%ld", [UserService sharedService].user.uid],
//                              @"circle_name":self.circleNameTextField.text,
//                              @"circle_detail":self.circleIntroTextField.text,
//                              @"address":self.circleAddressTextField.text,
//                              @"wx_num":self.wxTextField.text,
//                              @"phone_num":self.circlePhoneTextField.text,
//                              @"circle_web":self.circleWebTextField.text};
//    
//    //封面和二维码处理
//    NSString * fileName = [ToolsManager getUploadImageName];
//    NSArray * files     = @[@{FileDataKey:UIImageJPEGRepresentation(self.circleImageView.image,0.9),FileNameKey:fileName}];
//    if (self.wxQRcodeImageView.image != nil) {
//        files = @[@{FileDataKey:UIImageJPEGRepresentation(self.circleImageView.image,0.9),FileNameKey:fileName},
//                  @{FileDataKey:UIImageJPEGRepresentation(self.wxQRcodeImageView.image,0.9),FileNameKey:[NSString stringWithFormat:@"qrcode%@", fileName]}];
//    }
//    
//    debugLog(@"%@ %@", kPostNewCirclePath, params);
//    //创建中
//    [self showHudInView:self.view hint:KHClubString(@"Circle_CreateCircle_CreateHUD")];
//    
//    [HttpService postFileWithUrlString:kPostNewCirclePath params:params files:files andCompletion:^(AFHTTPRequestOperation *operation, id responseData) {
//        int status = [responseData[@"status"] intValue];
//        if (status == HttpStatusCodeSuccess) {
//            [self showSuccess:KHClubString(@"Circle_CreateCircle_CreateSuccess")];
//            //创建成功 进入圈子
//            CircleHomeViewController * chvc = [[CircleHomeViewController alloc] init];
//            chvc.circleId                   = [responseData[HttpResult][@"id"] integerValue];
//            chvc.isCreate                   = YES;
//            [(UINavigationController *)[self presentingViewController] pushViewController:chvc animated:YES];
//            [self dismissViewControllerAnimated:YES completion:nil];
//        }else{
//            [self showFail:KHClubString(@"Circle_CreateCircle_CreateFail")];
//        }
//    } andFail:^(AFHTTPRequestOperation *operation, NSError *error) {
//        [self showFail:StringCommonNetException];
//    }];
    
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
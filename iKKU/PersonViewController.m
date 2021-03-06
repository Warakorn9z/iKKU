//
//  PersonViewController.m
//  iKKU
//
//  Created by Warakorn9z on 11/28/2556 BE.
//  Copyright (c) 2556 Zenin. All rights reserved.
//

#import "PersonViewController.h"
#import "API.h"
#import "PersonCell.h"
#import "YouTubePlayerViewController.h"
#import "UIImageView+AFNetworking.h"
#import <MessageUI/MFMailComposeViewController.h>

#define isiPhone5  ([[UIScreen mainScreen] bounds].size.height == 568) ? YES:NO

@interface PersonViewController () <APIDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation PersonViewController
{
    API *api;
    NSArray *pickerList, *DATA;
    UIImage *navigationBG;
}

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
    
    navigationBG = [[[self navigationController] navigationBar] backgroundImageForBarMetrics:UIBarMetricsDefault];
    
    DATA = nil;
    
    api = [API new];
    [api setDelegate:self];
    
    pickerList = @[ @"Firstname", @"Lastname", @"Department" ];
    
    [_picker setDataSource:self];
    [_picker setDelegate:self];
    [_picker setHidden:YES];
    
    [_textFieldType setEnabled:YES];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapType:)];
    [tap setCancelsTouchesInView:YES];
    [tap setNumberOfTapsRequired:1];
    [tap setNumberOfTouchesRequired:1];
    
    [_textFieldType addGestureRecognizer:tap];
    [_textFieldType setText:@"Firstname"];
    
    [_textFieldKeyword setDelegate:self];

    [_tableViewPerson setDataSource:self];
    [_tableViewPerson setDelegate:self];
    
    [_labelNotFound setHidden:YES];
    
    [_textFieldKeyword setText:@""];
    [_tableViewPerson reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (UIViewController *vc in self.tabBarController.childViewControllers) {
        if ([vc isKindOfClass:[YouTubePlayerViewController new].class]) {
            [(YouTubePlayerViewController *)vc stopVideo];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"Person Memory Warning");
}

- (void)onTapType:(UIGestureRecognizer *)sender {
    [_picker setHidden:NO];
}
- (IBAction)onClickSearch:(UIButton *)sender {
    NSString *type = [_textFieldType text];
    if ([type isEqualToString:@"Firstname"]) {
        type = @"fname";
    } else if ([type isEqualToString:@"Lastname"]) {
        type = @"lname";
    } else if ([type isEqualToString:@"Department"]) {
        type = @"dept";
    }
    [api searchPersonWith:type keyword:[_textFieldKeyword text]];
    [_textFieldKeyword endEditing:YES];
    
}
- (IBAction)onClickRefresh:(UIButton *)sender {
    [self viewDidLoad];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self onClickSearch:nil];
    return YES;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [pickerList count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return pickerList[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [_textFieldType setText:pickerList[row]];
    [_picker setHidden:YES];
}

- (void)searchPersonCompleted:(NSObject *)result
{
    DATA = [result valueForKey:@"result"];
    if ((NSNull *)DATA == [NSNull null]) {
        DATA = nil;
    }
    if ((DATA == nil) || ([DATA count]==0)) {
        [_labelNotFound setHidden:NO];
    } else {
        [_labelNotFound setHidden:YES];
    }
    [_tableViewPerson reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [DATA count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PersonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PersonCell" forIndexPath:indexPath];
    
    NSDictionary *dict = DATA[indexPath.row];
    
    [cell configCell:dict];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = DATA[indexPath.row];
    if ([[dict valueForKey:@"email"] isEqualToString:@""] || dict == nil) {
        return;
    }
    if ([MFMailComposeViewController canSendMail]) {
        [[UINavigationBar appearance] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        
        MFMailComposeViewController *controller = [MFMailComposeViewController new];
        [controller setMailComposeDelegate:self];
        [controller setToRecipients:@[[dict valueForKey:@"email"]]];
        [controller setTitle:@""];
        [self presentViewController:controller animated:YES completion:^{
//            [controller.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];

        }];
    } else {
        NSLog(@"ERROR to Open Mail");
        [API showDialog:@"Error to open mail"];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [[UINavigationBar appearance] setBackgroundImage:navigationBG forBarMetrics:UIBarMetricsDefault];
    [controller dismissViewControllerAnimated:YES completion:^{
        if(result == MFMailComposeResultSent) {
            [API showDialog:@"Mail sent"];
        } else if(result == MFMailComposeResultFailed) {
            [API showDialog:@"Fail to send mail"];
        }
    }];
    NSLog(@"Mail Result : %@", error);
}

@end

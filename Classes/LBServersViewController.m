//
//  LBServersViewController.m
//  OpenStack
//
//  Created by Mike Mayo on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LBServersViewController.h"
#import "OpenStackAccount.h"
#import "AccountManager.h"
#import "LoadBalancer.h"
#import "Server.h"
#import "Flavor.h"
#import "Image.h"
#import "UIViewController+Conveniences.h"
#import "ActivityIndicatorView.h"
#import "APICallback.h"


@implementation LBServersViewController

@synthesize account, loadBalancer;

- (id)initWithAccount:(OpenStackAccount *)a loadBalancer:(LoadBalancer *)lb {
    self = [super initWithNibName:@"LBServersViewController" bundle:nil];
    if (self) {
        self.account = a;
        self.loadBalancer = lb;
    }
    return self;
}

- (void)dealloc {
    [account release];
    [loadBalancer release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Cloud Servers";
    [self addDoneButton];
    
    if ([self.account.servers count] == 0) {
        // we may not have loaded the servers yet, so load them now
        
        NSString *activityMessage = @"Loading...";
        ActivityIndicatorView *activityIndicatorView = [[ActivityIndicatorView alloc] initWithFrame:[ActivityIndicatorView frameForText:activityMessage] text:activityMessage];
        [activityIndicatorView addToView:self.view];
        
        [[self.account.manager getServersWithCallback] success:^(OpenStackRequest *request) {
            [activityIndicatorView removeFromSuperviewAndRelease];
            [self.tableView reloadData];
        } failure:^(OpenStackRequest *request) {
            [activityIndicatorView removeFromSuperviewAndRelease];
            [self alert:@"There was a problem loading your servers." request:request];
        }];
        
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.account.sortedServers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    Server *server = [self.account.sortedServers objectAtIndex:indexPath.row];
    cell.textLabel.text = server.name;
    cell.detailTextLabel.text = server.flavor.name;
    if ([[server.image logoPrefix] isEqualToString:@"custom"]) {
        cell.imageView.image = [UIImage imageNamed:@"cloud-servers-icon.png"];
    } else {
        cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@-icon.png", [server.image logoPrefix]]];
    }
    
    if ([self.loadBalancer.cloudServerNodes containsObject:server]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Server *server = [self.account.sortedServers objectAtIndex:indexPath.row];
    if ([self.loadBalancer.cloudServerNodes containsObject:server]) {
        [self.loadBalancer.cloudServerNodes removeObject:server];
    } else {
        [self.loadBalancer.cloudServerNodes addObject:server];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [NSTimer scheduledTimerWithTimeInterval:0.35 target:self.tableView selector:@selector(reloadData) userInfo:nil repeats:NO];
}

#pragma mark - Button Handlers

- (void)doneButtonPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

@end

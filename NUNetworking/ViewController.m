//
//  ViewController.m
//  NUNetworking
//
//  Created by 黄安华 on 22/9/18.
//  Copyright © 2018年 nuclear. All rights reserved.
//

#import "ViewController.h"
#import "TestAPI.h"
#import "TestAPI2.h"
#import "CityViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong) NSArray *dataSource;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"城市列表";
    _dataSource = @[
                    @"北京",
                    @"上海",
                    @"深圳",
                    @"广州",
                    @"重庆",
                    @"西安",
                    ];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"used"];
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"used" forIndexPath:indexPath];
    cell.textLabel.text = self.dataSource[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CityViewController *city = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"city"];
    NSLog(@"%@", self.storyboard);
    
    city.city = self.dataSource[indexPath.row];
    [self.navigationController pushViewController:city animated:YES];
}



@end

//
//  CityViewController.m
//  NUNetworking
//
//  Created by Huang,Anhua on 2018/11/6.
//  Copyright © 2018年 nuclear. All rights reserved.
//

#import "CityViewController.h"
#import "TestAPI2.h"
#import "TestAPI.h"

@interface CityViewController ()<UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong) UIActivityIndicatorView *actView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation CityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.backgroundColor = [UIColor whiteColor];
    self.title = self.city;
    self.dataSource = [NSMutableArray array];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reused"];
    
    _actView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _actView.hidesWhenStopped = YES;
    _actView.center = self.view.center;
    [_actView startAnimating];
    [self startReq];
}

- (void)startReq {
    
    if ([self.city isEqualToString:@"北京"]) {
        TestAPI *api = TestAPI.new;
        api.city = self.city;
        [api startWithSuccess:^(id  _Nonnull responseObject) {
            [self.actView stopAnimating];
            NSDictionary *dict = (NSDictionary *)responseObject;
            
            [self.dataSource addObject:dict[@"code"]?:@""];
            
            NSDictionary *data = dict[@"data"];
            [self.dataSource addObject:data[@"city"]];
            [self.dataSource addObject:data[@"aqi"]];
            
            [self.tableView reloadData];
            
        } failure:^(NSError * _Nonnull error) {
            [self.actView stopAnimating];
        }];
    }
    
    if ([self.city isEqualToString:@"上海"]) {
        TestAPI2 *api = TestAPI2.new;
        api.city = self.city;
        [api startWithSuccess:^(id  _Nonnull responseObject) {
            [self.actView stopAnimating];
            NSDictionary *dict = (NSDictionary *)responseObject;
            
            [self.dataSource addObject:dict[@"code"]?:@""];
            
            NSDictionary *data = dict[@"data"];
            [self.dataSource addObject:data[@"city"]];
            [self.dataSource addObject:data[@"aqi"]];
            
            [self.tableView reloadData];
        } failure:^(NSError * _Nonnull error) {
            [self.actView stopAnimating];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reused" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", self.dataSource[indexPath.row]];
    return cell;
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

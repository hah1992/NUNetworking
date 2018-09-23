//
//  ViewController.m
//  NUNetworking
//
//  Created by 黄安华 on 22/9/18.
//  Copyright © 2018年 nuclear. All rights reserved.
//

#import "ViewController.h"
#import "TestAPI.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [TestAPI.new startWithSuccess:^(id  _Nonnull responseObject) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
}


@end

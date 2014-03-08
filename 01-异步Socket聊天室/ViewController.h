//
//  ViewController.h
//  01-异步Socket聊天室
//
//  Created by apple on 14-3-3.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ViewContollerDelegate <NSObject>

- (void)test;

@end

@interface ViewController : UIViewController

@property (nonatomic, weak) id<ViewContollerDelegate> delegate;

@end

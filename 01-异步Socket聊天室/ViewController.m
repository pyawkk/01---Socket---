//
//  ViewController.m
//  01-异步Socket聊天室
//
//  Created by apple on 14-3-3.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

/**
 runtime运行时机制，clang OC的代码实际是先编译成C++的代码，然后再变成机器指令
 
 id就是在运行时判断对象类型的一种机制，这种机制能够增加程序的灵活度
 
 在编码时，不遵守协议，只要实现了协议方法，同样能够正常运行。
 
 那么遵守协议的用处，是为了简化程序员开发的编码过程，减少程序员出错的机会。
 */
@interface ViewController ()
// <GCDAsyncSocketDelegate, UITextFieldDelegate, UITableViewDataSource>
{
    GCDAsyncSocket *_socket;
    
    // 聊天数据
    NSMutableArray *_dataList;
    
    id obj;
}

@property (weak, nonatomic) IBOutlet UITextField *hostName;
@property (weak, nonatomic) IBOutlet UITextField *portText;
@property (weak, nonatomic) IBOutlet UITextField *nickNameText;
@property (weak, nonatomic) IBOutlet UITextField *messageText;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 判断代理是否实现了协议中的方法
    if ([_delegate respondsToSelector:@selector(test)]) {
        [_delegate test];
    }

	// 1. Socket通讯的第一件事情——先创建一个长连接
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    _dataList = [NSMutableArray array];
}

#pragma mark - TextField代理方法
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length > 0) {
        // 发送消息给服务器
        // 长连接建立完成后，给服务器发送 msg:聊天内容 通知服务器聊天的内容
        NSString *str = [NSString stringWithFormat:@"msg:%@", textField.text];
        // 网络通讯中，所有的数据都是以二进制流的模式传输的
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        
        // 将数据写入到输出流，告诉服务器聊天内容
        [_socket writeData:data withTimeout:-1 tag:101];
    }
    
    return YES;
}

#pragma mark - 数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    cell.textLabel.text = _dataList[indexPath.row];
    
    return cell;
}

#pragma mark - Socket代理方法
#pragma mark 连接到主机
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"连接建立 %@ %@", host, [NSThread currentThread]);
    
    // 长连接建立完成后，给服务器发送 iam:昵称 通知服务器用户登录
    NSString *str = [NSString stringWithFormat:@"iam:%@", _nickNameText.text];
    // 网络通讯中，所有的数据都是以二进制流的模式传输的
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    // 将数据写入到输出流，告诉服务器用户登录
    [_socket writeData:data withTimeout:-1 tag:100];
}

#pragma mark 读数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (tag == 100) {
        NSLog(@"登录消息 %@", str);
    } else {
        NSLog(@"聊天消息 %@->%ld", str, tag);
    }
    
    NSLog(@"%@", [NSThread currentThread]);
    
    // 剩下的工作 绑定表格数据
    [_dataList addObject:str];
    
    // 在主线程刷新表格
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadData];
    });
}

#pragma mark 写数据
#pragma mark Socket已经把数据写给了服务器
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    // 通过Log，我们发现在给服务器写入数据时，如果指定了tag，根据tag就知道发送（写给）的是哪一类的数据
    // 发现了读数据的代理方法没有被触发
    NSLog(@"写数据 %ld", tag);
    
    // 尝试让socket读一下数据，读取服务器返回的内容
    [_socket readDataWithTimeout:-1 tag:tag];
}

#pragma mark - Action
- (IBAction)connect:(id)sender
{
    NSString *hostName = _hostName.text;
    int port = [[_portText text] intValue];
    
    // 连接到主机
    NSError *error = nil;
    if (![_socket connectToHost:hostName onPort:port error:&error]) {
        NSLog(@"%@", error.localizedDescription);
    } else {
        NSLog(@"OK");
    }
}

@end

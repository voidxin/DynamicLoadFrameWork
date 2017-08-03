//
//  ViewController.m
//  VXFrameWorkDemoMainPro
//
//  Created by voidxin on 17/8/2.
//  Copyright © 2017年 voidxin. All rights reserved.
//
/*
   在真机上运行的时候frameWork的签名必须和主工程的签名一致，由于iOS10之后系统不允许从documents读取文件，所以iOS10之后动态加载frameWork的通道被堵死。iOS10之前亲测是可用的
   详情可见这篇博客:http://nixwang.com/2015/11/09/ios-dynamic-update/
 */
#import "ViewController.h"
#import "ZipArchive.h"
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


- (IBAction)clickedBtn:(id)sender {
   // [self testFramework];
    [self downLoadFile];
}


#pragma mark - 解压文件
- (void)unEncodeZipFile {
    NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *docsPath =[paths objectAtIndex:0];
    NSString *zipPath = [docsPath stringByAppendingPathComponent:@"myframework.zip"];
    //
    ZipArchive *za = [[ZipArchive alloc]init];
    //在内存中解压文件
    if ([za UnzipOpenFile:zipPath]) {
        //将解压的内容写到磁盘中
        BOOL success = [za UnzipFileTo:docsPath overWrite:YES];
        if (!success) {
            
            NSLog(@"解压失败");
        }else{
            //关闭压缩文件
            [za UnzipCloseFile];
             NSLog(@"解压成功");
            [self showAlertView];
        }
    }else{
       
          NSLog(@"压缩文件不存在");
    }
}


- (void)showAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"解压成功，执行解压文件代码?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //执行下载的frameWork代码
        [self testFramework];
    }];
    [alertVC addAction:confirm];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - 下载压缩文件并解压
- (void)downLoadFile
{
    // 1. 创建url
    NSString *urlStr =[NSString stringWithFormat:@"%@", @"http://app.wgmf.com/mkt-front/yxgj-native/iOSFrameWork/VXFrameDemo.framework.zip"];
    urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *Url = [NSURL URLWithString:urlStr];
    
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:Url];
    
    // 创建会话
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDownloadTask *downLoadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            // 下载成功
            // 注意 location是下载后的临时保存路径, 需要将它移动到需要保存的位置
            NSError *saveError;
            // 创建一个自定义存储路径
            NSArray *paths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
            NSString *documentsDirectory =[paths objectAtIndex:0];
            NSString *savePath = [documentsDirectory stringByAppendingPathComponent:@"myframework.zip"];
            NSURL *saveURL = [NSURL fileURLWithPath:savePath];
            
            // 文件复制到cache路径中
            [[NSFileManager defaultManager] copyItemAtURL:location toURL:saveURL error:&saveError];
            if (!saveError) {
                NSLog(@"保存成功");
                //解压
                [self unEncodeZipFile];
            } else {
                NSLog(@"error is %@", saveError.localizedDescription);
            }
        } else {
            NSLog(@"error is : %@", error.localizedDescription);
        }
    }];
    // 恢复线程, 启动任务
    [downLoadTask resume];
    
}

#pragma mark - 从document中读取framework
-(void)testFramework
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentDirectory = nil;
    if ([paths count] != 0)
        documentDirectory = [paths objectAtIndex:0];
    
    //拼接我们放到document中的framework路径
    NSString *libName = @"VXFrameDemo.framework";
    NSString *destLibPath = [documentDirectory stringByAppendingPathComponent:libName];
    
    //判断一下有没有这个文件的存在　如果没有直接跳出
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:destLibPath]) {
        NSLog(@"There isn't have the file");
        return;
    }
    
    //复制到程序中
    NSError *error = nil;
    
    //加载方式一：使用dlopen加载动态库的形式　使用此种方法的时候注意头文件的引入
    //    void* lib_handle = dlopen([destLibPath cStringUsingEncoding:NSUTF8StringEncoding], RTLD_LOCAL);
    //    if (!lib_handle) {
    //        NSLog(@"Unable to open library: %s\n", dlerror());
    //        return;
    //    }
    //加载方式一　关闭的方法
    // Close the library.
    //    if (dlclose(lib_handle) != 0) {
    //        NSLog(@"Unable to close library: %s\n",dlerror());
    //    }
    
    //加载方式二：使用NSBundle加载动态库
    NSBundle *frameworkBundle = [NSBundle bundleWithPath:destLibPath];
    if (frameworkBundle && [frameworkBundle load]) {
        NSLog(@"bundle load framework success.");
    }else {
        NSLog(@"bundle load framework err:%@",error);
        return;
    }
    
    /*
     *通过NSClassFromString方式读取类
     *PacteraFramework　为动态库中入口类
     */
    Class pacteraClass = NSClassFromString(@"VXFrameDemo");
    if (!pacteraClass) {
        NSLog(@"Unable to get TestDylib class");
        return;
    }
    
    /*
     *初始化方式采用下面的形式
     　alloc　init的形式是行不通的
     　同样，直接使用PacteraFramework类初始化也是不正确的
     *通过- (id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;
     　方法调用入口方法（showView:withBundle:），并传递参数（withObject:self withObject:frameworkBundle）
     */
    NSObject *pacteraObject = [pacteraClass new];
    [pacteraObject performSelector:@selector(printMyLog) withObject:self withObject:frameworkBundle];
    
}

@end

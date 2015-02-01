//
//  ViewController.m
//  AMTXFParser
//
//  Created by Anoop Mohandas on 01/02/15.
//  Copyright (c) 2015 Anoop Mohandas. All rights reserved.
//

#import "ViewController.h"
#import "NSString+TXFParser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (NSString *)txfStringForName:(NSString *)fileName{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName
                                                         ofType:@"txf"];
    return  [[NSString alloc] initWithContentsOfFile:filePath
                                            encoding:NSUTF8StringEncoding
                                               error:nil];
}

- (IBAction)parseButtonClick:(UIButton *)sender {
    NSString *txfString = [self txfStringForName:nil];
    id object = [txfString TXFObject];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

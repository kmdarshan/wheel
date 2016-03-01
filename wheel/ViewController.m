//
//  ViewController.m
//  wheel
//
//  Created by katruman on 2/29/16.
//  Copyright © 2016 redflower. All rights reserved.
//

#import "ViewController.h"
#import "RRWheelController.h"
@interface ViewController () <RRWheelDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self showWheel];
}

-(void) showWheel
{
    
    CGRect standardSize = CGRectMake(0, 0, [[UIScreen mainScreen] applicationFrame].size.width, [[UIScreen mainScreen] applicationFrame].size.height);
    CGPoint centerPoint = CGPointMake(standardSize.size.width, standardSize.size.height);
    NSInteger radius;
    NSInteger cutOffAngle;
    NSInteger bufferHeight;
    UIColor* wheelBgColor;
    UIColor* selFontColor;
    RRWheelController *filterWheel;
    NSMutableArray* filterWheels;

    NSMutableArray* reverseFilters = [NSMutableArray array];
    NSArray *occasion = [NSArray arrayWithObjects:@[@"apple", @"orange", @"pineapple", @"jackfruit", @"strawberry", @"pine", @"guava", @"berry"], @[@"apple", @"orange", @"pineapple", @"jackfruit", @"strawberry", @"pine", @"guava", @"berry"], @[@"apple", @"orange", @"pineapple", @"jackfruit", @"strawberry", @"pine", @"guava", @"berry"], nil];
    for (int i = [occasion count]-1; i>=0; i--) {
        if ([reverseFilters count] > 2) {
            break;
        }
        
        [reverseFilters addObject:[occasion objectAtIndex:i]];
    }

    for (int i=0; i<[reverseFilters count]; i++) {
        NSString *selectedFilter = @"apple";
        if (i==0) {
            radius = 185;
            cutOffAngle = 40;
            bufferHeight = 60;
            wheelBgColor = [UIColor colorWithRed:161.0/255.0 green:157.0/255.0 blue:206.0/255.0 alpha:1];
            selFontColor = [UIColor colorWithRed:255/255 green:255/255 blue:255/255 alpha:1.0];
        } else if (i==1) {
            bufferHeight = 75;
            radius = 245;
            cutOffAngle = 45;
            wheelBgColor = [UIColor colorWithRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1];
            selFontColor = [UIColor colorWithRed:54.0/255.0 green:25.0/255.0 blue:70.0/255.0 alpha:1.0];
        } else {
            cutOffAngle = 50;
            bufferHeight = 90;
            radius = 310;
            wheelBgColor = [UIColor colorWithRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1];
            selFontColor = [UIColor colorWithRed:54.0/255.0 green:25.0/255.0 blue:70.0/255.0 alpha:1.0];
        }
        
        filterWheel = [[RRWheelController alloc] initWithFrame:CGRectMake(0, 0, radius*2, radius*2)];
        filterWheel.wheelName = [NSString stringWithFormat:@"%d", [reverseFilters count] - i - 1];
        filterWheel.delegate = self;
        filterWheel.backgroundColor = [UIColor clearColor];
        [filterWheel setWords:[occasion objectAtIndex:i]];
        [filterWheel setCenterForBaseView:centerPoint];
        [filterWheel setSelectedWord:selectedFilter];
        [filterWheel setAddSpacesBetweenWords:YES];
        [filterWheel setRadius:radius];
        [filterWheel setFontForText:@"Avenir-Medium"];
        [filterWheel setCutOffAngle:cutOffAngle];
        [filterWheel setBufferHeightForClippingViews:bufferHeight];
        [filterWheel setFontForSelectedText:@"Avenir-Heavy"];
        [filterWheel setFontSize:25];
        [filterWheel setSelectedFontColor:selFontColor];
        [filterWheel setWheelBackgroundColor:wheelBgColor];
        [filterWheels addObject:filterWheel];
        [filterWheel setAccessibilityLabel:filterWheel.wheelName];
    }
    
    for (int i=[filterWheels count]-1; i>=0; i--) {
        filterWheel = [filterWheels objectAtIndex:i];
        [self.view addSubview:filterWheel];
        [filterWheel setCenter:CGPointMake(standardSize.size.width + filterWheel.radius, standardSize.size.height + filterWheel.radius)];
    }

}

-(void)wheelController:(RRWheelController *)wheelController didSelectFilter:(NSString *)filter {
    NSLog(@"filter selected");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

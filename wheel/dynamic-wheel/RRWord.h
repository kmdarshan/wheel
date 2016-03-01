//
//  TPWord.h
//
//  Created by Darshan Katrumane on 11/30/12.
//  Copyright (c) 2012 Darshan Katrumane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RRWord : UIView

@property (nonatomic, assign) CGFloat startingAngle;
@property (nonatomic, assign) CGFloat endingAngle;
@property (nonatomic, assign) CGFloat arcLength;
@property (nonatomic, strong) NSString* textPresentInView;
@property (nonatomic) NSInteger position;
@property (nonatomic, assign) CGFloat centerAngle;

@end

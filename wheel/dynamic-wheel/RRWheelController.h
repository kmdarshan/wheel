#import <UIKit/UIKit.h>
#import "RRWord.h"

@protocol RRWheelDelegate;

@interface RRWheelController : UIView{
    UIBezierPath *aPath;
    CGFloat radius;
    NSMutableArray *words;
    CGFloat rotation;
    CGPoint centerForBaseView;
    NSString* selectedWord;
    // very important, this must be set by the user depending on the radius and
    // placement of the views in the circle
    CGFloat bufferHeightForClippingViews;
    NSString* fontForText;
    NSString* fontForSelectedText;
    CGFloat originalRadius;
    CGFloat fontSize;
    CGFloat cutOffAngle;
    BOOL addSpacesBetweenWords;
    
}
@property (nonatomic, copy) NSString* wheelName;
@property (nonatomic, assign) BOOL addSpacesBetweenWords;
@property (nonatomic, assign) CGFloat cutOffAngle;
@property (nonatomic, assign) CGFloat originalRadius;
@property (nonatomic, copy) NSString* fontForSelectedText;
@property (nonatomic, copy) NSString* fontForText;
@property (nonatomic, assign) CGPoint centerForBaseView;
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, strong) NSMutableArray* words;
@property (nonatomic, copy) NSString* selectedWord;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat bufferHeightForClippingViews;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, strong) UIColor* selectedFontColor;
@property (nonatomic, strong) UIColor* wheelBackgroundColor;
@property (nonatomic, weak) id<RRWheelDelegate> delegate;
@end

@protocol RRWheelDelegate <NSObject>
@optional
- (void)wheelController:(RRWheelController*)wheelController didSelectFilter:(NSString*) filter;
@end

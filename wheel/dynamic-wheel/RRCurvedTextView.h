//
//  RRCurvedTextView.h
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@interface RRCurvedTextView : UIView {
    
    BOOL            setupRequired;
	
    CGFloat         red;
    CGFloat         green;
    CGFloat         blue;
    CGFloat         alpha;
    CTLineRef       line;
    
    NSAttributedString* attString;
    NSMutableArray*     widthArray;
    NSMutableArray*     angleArray;
    
    CGFloat             textRadius;
    NSString*           text;
    UIColor*            textColor;
    NSString*           textFont;
    CGFloat             textSize;
    
}

@property (nonatomic, retain) NSString* textFont;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) NSString* text;
@property (nonatomic) CGFloat textRadius;
@property (nonatomic) CGFloat textSize;
@property (nonatomic, strong) NSMutableArray* widthArray;

-(void)doInitialSetup;

@end


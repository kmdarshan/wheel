#import "RRBackgroundImageView.h"

@implementation RRBackgroundImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.image = [self imageNameInBundle:[NSObject imageNameForCurrentScreenSize:@"imgMatrix_ip5_tile1"] withExtension:@"png"];
        self.userInteractionEnabled = YES;
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    // do nothin
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    // do nothin
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    // do nothin
}

@end

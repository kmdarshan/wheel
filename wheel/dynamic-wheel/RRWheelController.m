#import "RRWheelController.h"
#import "RRCurvedTextView.h"
#import <QuartzCore/QuartzCore.h>

#import "UIView+MTReady.h"
#import "MTCommandEvent.h"
#import "MonkeyTalk.h"

@interface RRWheelController(){
    
    int wordPositionCounter;
    int clockwisePositionOfWord;
    BOOL viewSelectedByTap;
    CGFloat gTotalAnglesMovedByWheelClockwise;
    CGFloat gTotalAnglesMovedByWheelAnticlockwise;
    CGPoint initialTouchPoint;
    CGPoint previousPoint;
    CGFloat  gAngleToCenterWord;
    RRWord* gNearestViewToCenter;
    BOOL touchesMoved;
    
    CGFloat fromAngleInDegrees;
    CGFloat anticlockwiseEndAngle;
    CGFloat clockwiseEndAngleInDegrees;
    CGFloat previousHalfArcLength;
    CGFloat previousAngleInDegrees;
    BOOL didWheelDrawAtleastOneFilter;
    int cntr;
    NSMutableArray* viewsCurrentlyDisplayedArray;
    BOOL calculateToAngleOnlyOnceForClockwise;
    BOOL initialAntiClockwise ; // when the circle is initialized
    BOOL setClockwiseRotationAngleFirstTime;
    UIColor* colorNotSelected;
    NSMutableArray* cacheForViewsAlreadyCreated;
}
@end

@implementation RRWheelController
@synthesize wheelName;
@synthesize rotation;
@synthesize words;
@synthesize centerForBaseView;
@synthesize selectedWord;
@synthesize radius;
@synthesize bufferHeightForClippingViews;
@synthesize fontForSelectedText;
@synthesize fontForText;
@synthesize originalRadius;
@synthesize fontSize;
@synthesize cutOffAngle;
@synthesize addSpacesBetweenWords;
@synthesize selectedFontColor;
@synthesize wheelBackgroundColor;

#pragma mark - setup
-(void) setupView{
    
    wordPositionCounter = 0;
    clockwisePositionOfWord = 0;
    viewSelectedByTap = FALSE;
    gTotalAnglesMovedByWheelClockwise = 0;
    gTotalAnglesMovedByWheelAnticlockwise = 0;
    gAngleToCenterWord = 225;
    touchesMoved = NO;
    
    
    fromAngleInDegrees = 90.0;
    anticlockwiseEndAngle = 360.0;
    clockwiseEndAngleInDegrees = 0;
    previousHalfArcLength = 0.0;
    previousAngleInDegrees = 0.0;
    didWheelDrawAtleastOneFilter = NO;
    cntr = 1;
    calculateToAngleOnlyOnceForClockwise = YES;
    initialAntiClockwise = YES; // when the circle is initialized
    setClockwiseRotationAngleFirstTime = YES;
    gAngleToCenterWord = 225;
    colorNotSelected = [UIColor colorWithRed:0.39 green:0.36 blue:0.48 alpha:1.0];;
    
    cacheForViewsAlreadyCreated = [[NSMutableArray alloc] init];
    [self setOriginalRadius:radius];
    [self setMultipleTouchEnabled:NO];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedOnView:)];
    [tapGestureRecognizer setNumberOfTouchesRequired:1];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doDoubleTap:)] ;
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *multipleTapsAndTouches = [[UITapGestureRecognizer alloc] initWithTarget: self action:@selector(doDoubleTap:)] ;
    multipleTapsAndTouches.numberOfTapsRequired = 2;
    multipleTapsAndTouches.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:doubleTap];
    
    [tapGestureRecognizer requireGestureRecognizerToFail:doubleTap];
}

-(void) setupCircle{
    
    aPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, radius*2, radius*2) cornerRadius:radius];
    // Set the render colors.
    [[UIColor whiteColor] setStroke];
    [wheelBackgroundColor setFill];
    [aPath addClip];
    
    // Adjust the drawing options as needed.
    aPath.lineWidth = 0;
    
    // Fill the path before stroking it so that the fill
    // color does not obscure the stroked line.
    [aPath fill];
    [aPath stroke];
    
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
	[self.layer setShadowOpacity:1.0f];
	[self.layer setShadowRadius:10.0f];
	[self.layer setShadowOffset:CGSizeMake(0, 0)];
    [self.layer setShadowPath:[aPath CGPath]];
    
//    UIImage *backgroundImage = [self imageNameInBundle:@"bg_menuoutercircle" withExtension:@"png"];
//    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
//    backgroundView.frame = self.bounds;
//    [self addSubview:backgroundView];
}

-(void) setupWordsToDisplay{
    CGFloat cutOffForCircle = cutOffAngle;
	radius = self.bounds.size.width / 2 - cutOffForCircle;
	
    if (addSpacesBetweenWords) {
        NSMutableArray *delimitedWordsArray = [self addSeparatorsBetweenWordsForArray:words];
        [words removeAllObjects];
        [words addObjectsFromArray:delimitedWordsArray];
        
        NSString* modifiedSelectedWord = [@" " stringByAppendingString:selectedWord];
        modifiedSelectedWord = [modifiedSelectedWord stringByAppendingString:@" "];
        [self setSelectedWord:modifiedSelectedWord];
    }
}

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    return self;
}

- (void)drawRect:(CGRect)rect{
    [self setupCircle];
    [self setupView];
    [self setupWordsToDisplay];
    [self drawWordsOnView];
}

-(void) drawWordsOnView{
    if ([self wordsCanFitInSingleQuadrant]) {
        [self drawWheelAsNeededForSingleQuadrant];
    }else{
        [self drawWheelAsNeeded];
    }
    
    int cntrForCenteringViews = 0;
    if ([self wordsCanFitInSingleQuadrant]) {
        
        for (TPWord* view in [self subviews]) {
            if ([view isKindOfClass:[TPWord class]]) {
                if ([view.textPresentInView isEqualToString:selectedWord]) {
                    
                    //[self.wheelName setAccessibilityLabel:self.wheelName];
                    //NSLog(@"draw %@",view.textPresentInView);
                    //NSLog(@"draw wheel %@",self.wheelName);
                    
                    if(gAngleToCenterWord > view.centerAngle){
                        while (![self verifyIfWordIsCentered:selectedWord forCenterAngle:gAngleToCenterWord]) {
                            
                            gTotalAnglesMovedByWheelClockwise = gTotalAnglesMovedByWheelClockwise + 1;
                            gAngleToCenterWord = gAngleToCenterWord - 1;
                            self.transform = CGAffineTransformRotate(self.transform, [self toRadians:+1]);
                            // random value
                            if (cntrForCenteringViews++ > 1000) {
                                break;
                            }
                        }
                    }else{
                        while (![self verifyIfWordIsCentered:selectedWord forCenterAngle:gAngleToCenterWord]) {
                            
                            gTotalAnglesMovedByWheelAnticlockwise = gTotalAnglesMovedByWheelAnticlockwise + 1;
                            gAngleToCenterWord = gAngleToCenterWord + 1;
                            self.transform = CGAffineTransformRotate(self.transform, [self toRadians:-1]);
                            // random value
                            if (cntrForCenteringViews++ > 1000) {
                                break;
                            }
                        }
                    }
                }
            }
        }
    }else{
        cntrForCenteringViews=0;
        // initial this to the last word in the word array
        clockwisePositionOfWord = [words count]-1;
        while (![self verifyIfWordIsCentered:selectedWord forCenterAngle:gAngleToCenterWord]) {
            
            gTotalAnglesMovedByWheelClockwise = gTotalAnglesMovedByWheelClockwise + 1;
            gAngleToCenterWord = gAngleToCenterWord - 1;
            self.transform = CGAffineTransformRotate(self.transform, [self toRadians:+1]);
            [self drawWheelAsNeeded];
            
            // random value
            if (cntrForCenteringViews++ > 1000) {
                break;
            }
        }
    }
    [self redrawSelectedWord];
}

#pragma mark - compare and verify

- (BOOL)compareColors:(UIColor *)firstColor toSecondColor:(UIColor *)toSecondColor {
	BOOL areColorsEqual = CGColorEqualToColor(firstColor.CGColor, toSecondColor.CGColor);
	return areColorsEqual;
}

-(BOOL) wordsCanFitInSingleQuadrant{
    // calculate the angles needed for the words
    // lets keep the cutoff angle as 90 degrees, if the ending
    // angle is cumulatively less than 90, than we would need to
    // draw these views as a edge case
    CGFloat cumulativeAngle = 0;
    for (NSString* word in words) {
        cumulativeAngle = cumulativeAngle + [self anglesNeededToDisplayEachWordForText:word textSize:20];
    }
    
    if (cumulativeAngle < 75) {
        // we need a special case to draw these words
        return YES;
    }
    return NO;
}

// useful for checking when diff is greater than a single quadrant
// lets just reset to 0, if it is. Acts like a fail safe.
-(CGFloat) verifyAngleIsWithinSingleQuadrantForGivenLength:(CGFloat)diff{
    CGFloat oneByFourArcLength = (2 * M_PI * radius ) / 4;
    CGFloat anglesToMoveForArcLength = [self angleInDegreesForArcLength:oneByFourArcLength];
    if (diff > anglesToMoveForArcLength) {
        diff = 0;
        return diff;
    }
    return diff;
}

-(BOOL) verifyIfWordIsCentered:(NSString*) word forCenterAngle:(CGFloat) centerAngle{
    TPWord* circleView;
    for (id view in [self subviews]) {
        
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        circleView = view;
       // NSLog(@"text %@", circleView.textPresentInView);
        
        CGFloat diff = 0;
        
        if ([circleView.textPresentInView isEqualToString:word]) {
            if(circleView.centerAngle > gAngleToCenterWord){
                diff = circleView.centerAngle - gAngleToCenterWord;
            }else{
                diff = gAngleToCenterWord - circleView.centerAngle;
            }
            if (diff < 1) {
                return YES;
            }
        }
    }
    return NO;
}

-(NSMutableArray*) addSeparatorsBetweenWordsForArray:(NSMutableArray*) array
{
    // under the assumption that the given array always contains
    // more than zero elements
    NSMutableArray* delimitedArray = [[NSMutableArray alloc] init];
    for (NSString* word in array) {
        NSString* string = [@" " stringByAppendingString:word];
        string = [string stringByAppendingString:@" "];
        [delimitedArray addObject:string];
    }
    return delimitedArray;
}

#pragma mark -getters
-(TPWord*) checkIfViewExistsInCacheForText:(NSString*) text{
    for (TPWord* view in cacheForViewsAlreadyCreated) {
        if ([view.textPresentInView isNull]) {
            continue;
        }
        
        if ([[view.textPresentInView uppercaseString] isEqualToString:[text uppercaseString]]) {
            return view;
        }
    }
    return NULL;
}

-(TPCurvedTextView*) getViewWithCurvedText:(NSString*) text{
    
    TPCurvedTextView *curvedView = [[TPCurvedTextView alloc] init];
    curvedView.text = [text uppercaseString];
    curvedView.textFont = fontForText;
    curvedView.textRadius = radius;
    curvedView.textColor = colorNotSelected;
    curvedView.textSize = fontSize;
    [curvedView setBackgroundColor:[UIColor clearColor]];
	[curvedView doInitialSetup];
    [curvedView setUserInteractionEnabled:NO];
    curvedView.layer.shouldRasterize = YES;
    curvedView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    NSNumber* num;
    CGFloat widthOfView = 0;
	for (num in curvedView.widthArray) {
		widthOfView += [num floatValue];
	}
    
    [curvedView setFrame:CGRectMake(self.bounds.origin.x,
                                    self.bounds.origin.y,
                                    widthOfView,
                                    radius * 2 + bufferHeightForClippingViews )];
    return curvedView;
}

-(TPWord*) getCurvedViewForGivenWord:(NSString*) text
{
    
//    if (self.wheelName == @"0" ) {
//        if (!initialAntiClockwise && !setClockwiseRotationAngleFirstTime) {
//            TPWord* curvedWordView = [self checkIfViewExistsInCacheForText:text];
//            NSString* textPresentInsideCurvedView = curvedWordView.textPresentInView;
//            if ([textPresentInsideCurvedView length] > 0 ) {
//                return curvedWordView;
//            }else{
//                NSLog(@"nulll val");
//            }
//        }
//    }
    
    TPCurvedTextView *curvedView = [self getViewWithCurvedText:text];
    CGFloat widthOfView = 0;
    NSNumber* num;
    for (num in curvedView.widthArray) {
		widthOfView += [num floatValue];
	}

    [curvedView setFrame:CGRectMake(self.bounds.origin.x,
                                  self.bounds.origin.y,
                                  widthOfView,
                                  radius * 2 + bufferHeightForClippingViews )];
    
    TPWord *topView = [[TPWord alloc] initWithFrame:CGRectOffset(curvedView.frame, 0, -100)];
    topView.layer.masksToBounds = TRUE;
    [topView setFrame:CGRectMake(0, 0, widthOfView, radius / 2)];
	topView.arcLength = widthOfView;
    [topView setBackgroundColor:[UIColor clearColor]];
    [topView addSubview:curvedView];
    //[topView setClipsToBounds:YES];
    [topView setUserInteractionEnabled:YES];
    [topView setTextPresentInView:text];
    //[topView setAccessibilityLabel:text];
    topView.layer.shouldRasterize = YES;
    topView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    // add it to the cache
    if (![topView isNull]) {
        TPWord* wordView = topView;
        [cacheForViewsAlreadyCreated addObject:wordView];
    }
    return topView;
}

-(TPWord*) getNextViewToDisplayInClockwise:(NSMutableArray*) array
{
    TPWord* tpcircleView = [self findLowestView:array];
    NSString *word = tpcircleView.textPresentInView;
    int index = [words indexOfObject:word];
    index--;
    if (index < 0) {
        index = [words count] - 1;
    }
    
    NSString *text = [words objectAtIndex:index];
    TPWord *clippedView = [self getCurvedViewForGivenWord:text];
	clippedView.textPresentInView = text;
    return clippedView;
}

-(TPWord*) getNextViewToDisplayInAntiClockwise:(NSMutableArray*) array
{
    TPWord* tpcircleView = [self findHighestView:array];
    NSString *word = tpcircleView.textPresentInView;
    int index = [words indexOfObject:word];
    index++;
    if (index >= [words count]) {
        index = 0;
    }
    
    NSString *text = [words objectAtIndex:index];
    TPWord *clippedView = [self getCurvedViewForGivenWord:text];
	clippedView.textPresentInView = text;
    return clippedView;
}

-(TPWord*) getNextViewWithWordsAndIncreasePositionCounter:(BOOL)increaseCounter {
	
	static int positionOfWord = 0;
	if (positionOfWord >= [words count]) {
        positionOfWord = 0;
    }
    
    NSString *text = [words objectAtIndex:positionOfWord];
    
    TPWord *clippedView = [self getCurvedViewForGivenWord:text];
    clippedView.tag = positionOfWord;
	clippedView.textPresentInView = text;
	if (increaseCounter) {
		positionOfWord++;
	}
    
    return clippedView;
}

-(BOOL) checkIfViewIsPresentInTheSubViews:(TPWord*) checkView
{
    for (id view in [self subviews]) {
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        TPWord* cview = view;
        if (cview.position == checkView.position) {
            return YES;
        }
    }
    return NO;
}

#pragma mark -draw
-(void)drawWheelAsNeededForSingleQuadrant{
    
	TPWord* textView;
	
	CGFloat rotationCutOffAngleInDegrees = 90.0;
	CGFloat currentHalfArcWidth = 0.0;
	int cntrSingleQuadrant = 1;
    CGFloat fromAngleInDegreesSingleQuadrant = 180.0;
    
    for (NSString* word in words) {
        
        textView = [self getCurvedViewForGivenWord:word];
        currentHalfArcWidth  = textView.arcLength / 2;
        CGFloat angleInDegreesForArcLength = [self angleInDegreesForArcLength:currentHalfArcWidth];
        
        textView.center = [self pointOnCircleForAngleInDegrees:fromAngleInDegreesSingleQuadrant+angleInDegreesForArcLength];
        textView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        textView.transform = CGAffineTransformMakeRotation([self toRadians:((fromAngleInDegreesSingleQuadrant+angleInDegreesForArcLength) + rotationCutOffAngleInDegrees)]);
        [self addSubview:textView];
        
        textView.textPresentInView = word;
        textView.startingAngle = fromAngleInDegreesSingleQuadrant;
        textView.endingAngle = fromAngleInDegreesSingleQuadrant + [self angleInDegreesForArcLength:textView.arcLength];
        //textView.accessibilityLabel=NSLocalizedString(@"wheel1", @"");
        
        textView.centerAngle = fromAngleInDegreesSingleQuadrant+angleInDegreesForArcLength;
        textView.position = cntrSingleQuadrant++;
        fromAngleInDegreesSingleQuadrant = textView.endingAngle;
    }
    
}


// method to draw the views on the circle
// initially the wheel is drawn from 90 - 360. Every 90 degrees of rotation, we draw additional views
// and remove views when needed.

-(void)drawWheelAsNeeded{
    
	TPWord* textView;
	
	CGFloat rotationCutOffAngleInDegrees = 90.0;
	CGFloat currentHalfArcWidth = 0.0;
	CGPoint centerPointOfCurrentView;
	CGFloat totalArcWidth;
	CGFloat currentAngleInDegrees = 0.0;
    int degreeOfRotationOnWheel = 0;
    CGFloat diff = 0;
    CGFloat overflowAngleAbove90Degrees = 0;
	BOOL clockwise = NO;
    
    
	if (didWheelDrawAtleastOneFilter) {
        
        if (gTotalAnglesMovedByWheelAnticlockwise > gTotalAnglesMovedByWheelClockwise) {
            diff = gTotalAnglesMovedByWheelAnticlockwise - gTotalAnglesMovedByWheelClockwise;
        }else{
            diff = gTotalAnglesMovedByWheelClockwise - gTotalAnglesMovedByWheelAnticlockwise;
        }
        
        if (rotation < 0) {
            clockwise = NO;
        }else{
            clockwise = YES;
        }
        overflowAngleAbove90Degrees = overflowAngleAbove90Degrees + (diff - 90);
      
        // lets reset it, if the angles moved greater than 90 degrees
        if (diff >= 90) {
            
            gTotalAnglesMovedByWheelAnticlockwise = 0;
            gTotalAnglesMovedByWheelClockwise = 0;
            
        } else if(gTotalAnglesMovedByWheelAnticlockwise > 90 || gTotalAnglesMovedByWheelClockwise > 90){
            gTotalAnglesMovedByWheelAnticlockwise = 0;
            gTotalAnglesMovedByWheelClockwise = 0;
        }else{
            return;
        }
        
		static int previousDegreeOfRotationOfWheel = 0;
		
		degreeOfRotationOnWheel = roundf([self toDegree:atan2f(self.transform.b, self.transform.a)]);
        degreeOfRotationOnWheel = [self giveMeTheAngleWithin360Degrees:degreeOfRotationOnWheel];
        if (degreeOfRotationOnWheel < 0) {
			degreeOfRotationOnWheel = -1 * degreeOfRotationOnWheel;
		} else if (degreeOfRotationOnWheel > 0) {
			degreeOfRotationOnWheel = 360 - degreeOfRotationOnWheel;
		} else {
			if (previousDegreeOfRotationOfWheel > 180) {
				degreeOfRotationOnWheel = 360; //edge case
			}
		}
        
		if (degreeOfRotationOnWheel > 0 && degreeOfRotationOnWheel < 180 && previousDegreeOfRotationOfWheel == 360) {
			previousDegreeOfRotationOfWheel = 0;
		}
		if (degreeOfRotationOnWheel >= 180 && degreeOfRotationOnWheel <= 360 && previousDegreeOfRotationOfWheel == 0) {
			previousDegreeOfRotationOfWheel = 360;
		}
        
		previousDegreeOfRotationOfWheel = degreeOfRotationOnWheel;
        
		TPWord* circleView;
		CGFloat removeAngle;
        NSMutableArray *newArray = [[NSMutableArray alloc] init];
        
		for (id view in [self subviews]) {
			if (![view isKindOfClass:[TPWord class]]) {
				continue;
			}
			circleView = view;
            
			if (clockwise) {
				removeAngle = circleView.startingAngle - degreeOfRotationOnWheel;
                removeAngle = [self giveMeTheAngleWithin360Degrees:removeAngle];
			} else {
				removeAngle = circleView.endingAngle - degreeOfRotationOnWheel;
                removeAngle = [self giveMeTheAngleWithin360Degrees:removeAngle];
			}
            
			if(removeAngle >= 0 && removeAngle <= 105){
                [newArray addObject:circleView];
                [circleView removeFromSuperview];
			}
		}
        
        // remove all the views which have been removed
        // and we don't want
        for (TPWord *view in newArray) {
            
            int index = 0;
            for (TPWord *innerView in viewsCurrentlyDisplayedArray) {
                // if ([view.textPresentInView isEqualToString:innerView.textPresentInView]) {
                if (view.position == innerView.position){
                    break;
                }
                index++;
            }
            if (index < [viewsCurrentlyDisplayedArray count]) {
                [viewsCurrentlyDisplayedArray removeObjectAtIndex:index];
            }
        }
        
	} else {
        
        //base condition - shud happen only once
        textView = [self getNextViewWithWordsAndIncreasePositionCounter:YES];
        
        textView.center = [self pointOnCircleForAngleInDegrees:fromAngleInDegrees];
        textView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        textView.transform = CGAffineTransformMakeRotation([self toRadians:(fromAngleInDegrees + rotationCutOffAngleInDegrees)]);
        [self addSubview:textView];
        
        textView.startingAngle = fromAngleInDegrees - [self angleInDegreesForArcLength:textView.arcLength/2];
        textView.endingAngle = fromAngleInDegrees + [self angleInDegreesForArcLength:textView.arcLength/2];
        textView.centerAngle = fromAngleInDegrees;
        previousAngleInDegrees = fromAngleInDegrees;
        previousHalfArcLength = textView.arcLength / 2;
        
        didWheelDrawAtleastOneFilter = YES;
        
        // add the tag
        textView.position = cntr++;
        
        // array to store currently displayed views
        viewsCurrentlyDisplayedArray = [[NSMutableArray alloc] init];
        [viewsCurrentlyDisplayedArray addObject:textView];
        
        // set the clockwise end angle in the base case
        clockwiseEndAngleInDegrees = textView.endingAngle - 90;
	}
    
    BOOL firstClockwiseAngleDrawn = YES;
    if (!initialAntiClockwise) {
        if (clockwise) {
            clockwiseEndAngleInDegrees = clockwiseEndAngleInDegrees - overflowAngleAbove90Degrees;
            anticlockwiseEndAngle = anticlockwiseEndAngle - overflowAngleAbove90Degrees;
        }else{
            clockwiseEndAngleInDegrees = clockwiseEndAngleInDegrees + overflowAngleAbove90Degrees;
            anticlockwiseEndAngle = anticlockwiseEndAngle + overflowAngleAbove90Degrees;
        }
    }
    
	while (YES) {
        
        CGFloat startingAngle = 0;
        CGFloat endingAngle = 0;
        
        if (clockwise) {
            
            // clockwise
            textView = [self getNextViewToDisplayInClockwise:viewsCurrentlyDisplayedArray];
            
            // get the length of the arc
            currentHalfArcWidth = textView.arcLength / 2;
            totalArcWidth = textView.arcLength;
            
            TPWord* lowestView = [self findLowestView:viewsCurrentlyDisplayedArray];
            
            // lets calculate the to angle
            // get the lowest view and then minus degrees from the starting angle
            
            if (calculateToAngleOnlyOnceForClockwise) {
                
                calculateToAngleOnlyOnceForClockwise = NO;
                currentAngleInDegrees = lowestView.startingAngle - [self angleInDegreesForArcLength:currentHalfArcWidth];
                startingAngle = currentAngleInDegrees - [self angleInDegreesForArcLength:currentHalfArcWidth];
                endingAngle = lowestView.startingAngle;
                
            }else{
                currentAngleInDegrees = lowestView.startingAngle - [self angleInDegreesForArcLength:currentHalfArcWidth];
                startingAngle = lowestView.startingAngle - [self angleInDegreesForArcLength:totalArcWidth];
                endingAngle = lowestView.startingAngle;
                if (firstClockwiseAngleDrawn) {
                    firstClockwiseAngleDrawn=NO;
                }
            }
            
            // check if the startingAngle crossed from angle
            // in clockwise its opposite e.g. -30 < 0
            if (endingAngle < clockwiseEndAngleInDegrees) {
                clockwiseEndAngleInDegrees = clockwiseEndAngleInDegrees - 90.0;
                anticlockwiseEndAngle = anticlockwiseEndAngle - 90.0;
                break;
                
            }
            
        }else{
            
            // anticlockwise
            textView = [self getNextViewToDisplayInAntiClockwise:viewsCurrentlyDisplayedArray];
            currentHalfArcWidth = textView.arcLength / 2;
            
            TPWord* highestView = [self findHighestView:viewsCurrentlyDisplayedArray];
            if (initialAntiClockwise) {
                
                // base case when circle is initialized
                totalArcWidth = currentHalfArcWidth + previousHalfArcLength;
                currentAngleInDegrees = previousAngleInDegrees + [self angleInDegreesForArcLength:totalArcWidth];
                startingAngle = currentAngleInDegrees - [self angleInDegreesForArcLength:currentHalfArcWidth];
                endingAngle = currentAngleInDegrees + [self angleInDegreesForArcLength:currentHalfArcWidth];
                
            }else{
                totalArcWidth = textView.arcLength;
                currentAngleInDegrees = highestView.endingAngle + [self angleInDegreesForArcLength:currentHalfArcWidth];
                startingAngle = highestView.endingAngle;
                endingAngle = highestView.endingAngle + [self angleInDegreesForArcLength:totalArcWidth];
            }
            
            if ( startingAngle > anticlockwiseEndAngle) {
                anticlockwiseEndAngle = anticlockwiseEndAngle + 90.0;
                
                if (setClockwiseRotationAngleFirstTime) {
                    clockwiseEndAngleInDegrees = 0;
                }else{
                    clockwiseEndAngleInDegrees = clockwiseEndAngleInDegrees + 90.0;
                }
                break;
            }
        }
		centerPointOfCurrentView = [self pointOnCircleForAngleInDegrees:currentAngleInDegrees];
    	textView.center = centerPointOfCurrentView;
		textView.layer.anchorPoint = CGPointMake(0.5, 0.5);
		textView.transform = CGAffineTransformMakeRotation([self toRadians:(currentAngleInDegrees + rotationCutOffAngleInDegrees)]);
		
        textView.startingAngle = startingAngle;
		textView.endingAngle = endingAngle;
		textView.centerAngle = currentAngleInDegrees;
        
		[self addSubview:textView];
		
        if (clockwise) {
            textView.position = -1 * cntr++;
            [viewsCurrentlyDisplayedArray insertObject:textView atIndex:0];
        }else{
            textView.position = cntr++;
            [viewsCurrentlyDisplayedArray addObject:textView];
        }
        
		previousAngleInDegrees = currentAngleInDegrees;
		previousHalfArcLength = currentHalfArcWidth;
	}
    
    initialAntiClockwise = NO;
    setClockwiseRotationAngleFirstTime = NO;
    [self removeOverlappingViews:viewsCurrentlyDisplayedArray];
    //textView.accessibilityLabel=NSLocalizedString(@"wheel1", @"");
}

-(void) redrawSelectedWord {
    
    // we need to get the word at the center and
    // change its color
    TPWord* selectedWordView;
    [self getDifferenceAnglesToCenterWord];
    selectedWordView = gNearestViewToCenter;
    
    TPWord* circleView;
    UIColor *colorSelected = selectedFontColor;
    

    // remove the centered view
    for (id view in [self subviews]) {
        
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        circleView = view;
		
        if (circleView.position == selectedWordView.position) {
            for (id innerView in [circleView subviews]) {
                TPCurvedTextView* curvedTextView = innerView;
				NSString* wordSelected;
				if (addSpacesBetweenWords) {
					wordSelected = [curvedTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				} else {
					wordSelected = curvedTextView.text;
				}
				if (self.delegate && [self.delegate respondsToSelector:@selector(wheelController:didSelectFilter:)]) {
					[self.delegate performSelector:@selector(wheelController:didSelectFilter:) withObject:self withObject:wordSelected];
				}
                if (![self compareColors:[curvedTextView textColor] toSecondColor:colorSelected]){
                    [curvedTextView setTextFont:fontForSelectedText];
                    [curvedTextView setTextColor:colorSelected];
                }
            }
        }else{
            for (id innerView in [circleView subviews]) {
                TPCurvedTextView* curvedTextView = innerView;
                // we should not be over writing the selected word again
                if (![curvedTextView.text isEqualToString:selectedWordView.textPresentInView]) {
                    if (![self compareColors:[curvedTextView textColor] toSecondColor:colorNotSelected]){
                        [curvedTextView setTextFont:fontForText];
                        [curvedTextView setTextColor:colorNotSelected];
                    }
                }
            }
        }
    }
    
}

-(void) centerSelectedWord
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    CGFloat adjustmentAngle = [self getDifferenceAnglesToCenterWord];
    if ([self giveMeTheAngleWithin360Degrees:gNearestViewToCenter.centerAngle] > [self giveMeTheAngleWithin360Degrees:gAngleToCenterWord]) {
        self.transform = CGAffineTransformRotate(self.transform, [self toRadians:-adjustmentAngle]);
        
        gAngleToCenterWord = gAngleToCenterWord + adjustmentAngle;
        gTotalAnglesMovedByWheelAnticlockwise = gTotalAnglesMovedByWheelAnticlockwise + adjustmentAngle;
        [self setRotation:-1];
    }else{
        self.transform = CGAffineTransformRotate(self.transform, [self toRadians:+adjustmentAngle]);
        
        // its moved clockwise here
        gTotalAnglesMovedByWheelClockwise = gTotalAnglesMovedByWheelClockwise + adjustmentAngle;
        gAngleToCenterWord = gAngleToCenterWord - adjustmentAngle;
        [self setRotation:+1];
    }
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [UIView commitAnimations];
}

#pragma mark -remove
-(void)removeOverlappingViews:(NSMutableArray*) viewsCurrentlyDisplayedArrayLocal
{
    NSMutableArray *viewsToBeRemoved = [[NSMutableArray alloc] init];
    for (TPWord* outerView in viewsCurrentlyDisplayedArrayLocal) {
        if (![outerView isKindOfClass:[TPWord class]]) {
            continue;
        }
        
        BOOL viewDisplayeCorrectly = NO;
        for (TPWord* innerView in viewsCurrentlyDisplayedArrayLocal) {
            if (![innerView isKindOfClass:[TPWord class]]) {
                continue;
            }
            
            if (round(outerView.endingAngle) == round(innerView.startingAngle)) {
                viewDisplayeCorrectly = YES;
                break;
            }
        }
        
        for (TPWord* innerView in viewsCurrentlyDisplayedArrayLocal) {
            if (![innerView isKindOfClass:[TPWord class]]) {
                continue;
            }
            
            if (round(outerView.startingAngle) == round(innerView.endingAngle)) {
                viewDisplayeCorrectly = YES;
                break;
            }
        }
        
        if (!viewDisplayeCorrectly) {
            NSNumber *val = [[NSNumber alloc] initWithInt:outerView.position];
            [viewsToBeRemoved addObject:val];
        }
    }
    
    
    // lets remove the views which are overlapping
    TPWord* circleView;
    for (id view in [self subviews]) {
        
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        circleView = view;
        NSNumber *position = [[NSNumber alloc] initWithInt:circleView.position];
        if ([viewsToBeRemoved count] > 0) {
            NSUInteger val = [viewsToBeRemoved indexOfObject:position];
            if (val != NSNotFound) {
                // remove this view from superview
                [circleView removeFromSuperview];
            }
        }
    }
    
}

#pragma mark -finders
- (TPWord*) findViewWhoseStartingAngleClosestToCenter{
    
    TPWord* circleView;
    TPWord* startingAngleClosestToCenter = [[TPWord alloc] init];
    
    CGFloat minDiff = 1000000000;
    for (id view in [self subviews]) {
        
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        circleView = view;
        CGFloat diff = 0;
        
        if(circleView.startingAngle > gAngleToCenterWord){
            diff = circleView.startingAngle - gAngleToCenterWord;
        }else{
            diff = gAngleToCenterWord - circleView.startingAngle;
        }
        if (diff < minDiff) {
            startingAngleClosestToCenter = circleView;
            minDiff = diff;
        }
    }
    
    return startingAngleClosestToCenter;
}

- (TPWord*) findViewWhoseEndingAngleClosestToCenter{
    
    TPWord* circleView;
    TPWord* endingAngleClosestToCenter = [[TPWord alloc] init];
    
    CGFloat minDiff = 1000000000;
    for (id view in [self subviews]) {
        
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        circleView = view;
        CGFloat diff = 0;
        
        if(circleView.endingAngle > gAngleToCenterWord){
            diff = circleView.endingAngle - gAngleToCenterWord;
        }else{
            diff = gAngleToCenterWord - circleView.endingAngle;
        }
        if (diff < minDiff) {
            endingAngleClosestToCenter = circleView;
            minDiff = diff;
        }
    }
    
    return endingAngleClosestToCenter;
}

-(TPWord*) findLowestView:(NSMutableArray*)array
{
    int min = 1000000;
    TPWord* circleView;
    TPWord* minView = [[TPWord alloc] init];
    
    for (id view in array) {
        
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        
        circleView = view;
        if ([self checkIfViewIsPresentInTheSubViews:circleView] == YES) {
            if (circleView.position < min) {
                minView = circleView;
                min = minView.position;
            }
        }
    }
    return minView;
}

-(TPWord*) findHighestView:(NSMutableArray*) array
{
    int max = -1000000;
    TPWord* circleView;
    TPWord* maxView = [[TPWord alloc] init];
    
    for (id view in [self subviews]) {
        
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        
        circleView = view;
        if ([self checkIfViewIsPresentInTheSubViews:circleView] == YES) {
            if (circleView.position > max) {
                maxView = circleView;
                max = maxView.position;
            }
        }
    }
    
    return maxView;
}


#pragma mark - angles
#pragma mark - angles
-(CGFloat) getWidthForAngles:(CGFloat) startAngle endAngle:(CGFloat)endAngle
{
    CGFloat diffAngles = endAngle - startAngle;
	if (diffAngles < 0 ) {
		diffAngles = -1 * diffAngles;
	}
    
    CGFloat lengthOfArc = ( 2*M_PI*radius) *( diffAngles / 360);
    return lengthOfArc;
	
}

-(CGPoint)pointOnCircleForAngleInDegrees:(CGFloat)angleInDegrees {
	CGFloat angle = [self toRadians:(angleInDegrees)];
	CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
	CGFloat x = center.x + radius * cosf(angle);
	CGFloat y = center.y + radius * sinf(angle);
	return CGPointMake(x, y);
}

-(CGFloat)angleInDegreesForArcLength:(CGFloat)arcLength {
	return (arcLength * 180) / (M_PI * radius);
}

-(CGFloat) giveMeTheAngleWithin360Degrees:(CGFloat) angle
{
    CGFloat returnValue = 0;
    
    // e.g. > 360 , 361
    if (angle >= 360) {
        int remainder = angle / 360;
        CGFloat productVal = remainder * 360;
        returnValue = angle - productVal;
        return returnValue;
    }
    
    // e.g. -1,-2 -358, -359
    if (angle < 0 && angle > -360) {
        return 360 + angle;
    }
    
    if (angle <= -360) {
        int remainder = angle / 360;
        CGFloat productVal = remainder * 360;
        returnValue = angle - productVal;
        
        // make this positive
        if (returnValue < 0) {
            returnValue = 360 + returnValue;
            return returnValue;
        }
    }
    
    // e.g 1 - 359
    if (angle > 0 && angle < 360) {
        return angle;
    }
    return returnValue;
}

-(CGFloat)getWidthForAngleFrom:(CGFloat) startAngleInDegrees endAngle:(CGFloat)endAngleInDegrees {
    CGFloat diffAngles = endAngleInDegrees - startAngleInDegrees;
	if (diffAngles < 0 ) {
		diffAngles = -1 * diffAngles;
	}
    
    CGFloat lengthOfArc = ( 2*M_PI*radius) *( diffAngles / 360);
    return lengthOfArc;
	
}

-(CGFloat)toRadians:(CGFloat)degree {
	return degree * M_PI / 180;
}

-(CGFloat)toDegree:(CGFloat)radians {
	return radians * 180 / M_PI;
}

-(CGFloat) getDifferenceAnglesToCenterWord
{
    TPWord* circleView;
    gNearestViewToCenter = [[TPWord alloc] init];
    
    CGFloat minDiff = 1000000000;
    for (id view in [self subviews]) {
        
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        circleView = view;
        CGFloat diff = 0;
        
        if(circleView.centerAngle > gAngleToCenterWord){
            diff = circleView.centerAngle - gAngleToCenterWord;
        }else{
            diff = gAngleToCenterWord - circleView.centerAngle;
        }
        if (diff < minDiff) {
            minDiff = diff;
            gNearestViewToCenter = circleView;
        }
    }
    return minDiff;
}

-(CGFloat) anglesNeededToDisplayEachWordForText:(NSString*) text textSize:(CGFloat) textSize{
    TPCurvedTextView *labelOne = [[TPCurvedTextView alloc] init];
    labelOne.text = text;
    labelOne.textFont = fontForText;
    labelOne.textRadius = 200;
    labelOne.textSize = textSize;
    [labelOne setBackgroundColor:[UIColor clearColor]];
	[labelOne doInitialSetup];
    [labelOne setUserInteractionEnabled:NO];
    
    NSNumber* num;
    CGFloat widthOfView = 0;
	for (num in labelOne.widthArray) {
		widthOfView += [num floatValue];
	}
    CGFloat angle = [self angleInDegreesForArcLength:widthOfView];
    return angle;
}

#pragma mark -distance
- (float) calculateDistanceFromCenter:(CGPoint)point {
    CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    float dx = point.x - center.x;
    float dy = point.y - center.y;
    return sqrt(dx*dx + dy*dy);
}

-(CGFloat)calculateDistFrom:(CGPoint)p1 to:(CGPoint)p2 {
    CGFloat distance = ((p2.x - p1.x) * (p2.x - p1.x)) + ((p2.y - p1.y) * (p2.y - p1.y));
    return sqrtf(distance);
}

-(BOOL) shouldTheWheelMoveInAnyDirectionForPoint:(CGPoint) point
{
    // assuming all the wheels will have radius greater than 100
    if ([self calculateDistanceFromCenter:point] < 100) {
        return NO;
    }
    return YES;
}

-(UIView*)previousView {
	NSArray* subviews = self.superview.subviews;
	int i;
	for (i=0; i < [subviews count]; i++) {
		if (self == subviews[i]) {
			break;
		}
	}
	i--;
	if (i < 0) {
		return nil;
	}
	return subviews[i];
}

-(float)distanceWithCenter:(CGPoint)current with:(CGPoint)SCCenter
{
    CGFloat dx=current.x-SCCenter.x;
    CGFloat dy=current.y-SCCenter.y;
    
    return sqrt(dx*dx + dy*dy);
}

#pragma mark - touch delegates

-(BOOL)didTouchHappenOnThisView : (CGPoint)pt {
	if (((pt.x-self.bounds.size.width/2) * (pt.x-self.bounds.size.width/2) + (pt.y - self.bounds.size.height/2) * (pt.y - self.bounds.size.height/2))  <  (self.bounds.size.width/2 * self.bounds.size.width/2)) {
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return [aPath containsPoint:point];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch* touch =  [touches anyObject];
	CGPoint currentTouchPoint = [touch locationInView:self];
    if (![self pointInside:currentTouchPoint withEvent:event]) {
        return;
    }
    
	touchesMoved = YES;
    
    NSUInteger tapCount = [[touches anyObject] tapCount];
    NSUInteger touchesCount = [[event allTouches] count];
    
    if ( touchesCount > 1 || tapCount > 1) {
        if ([self wordsCanFitInSingleQuadrant]){
            return;
        }
        [self drawWheelAsNeeded];
        return;
    }
	
    CGPoint center = CGPointMake(CGRectGetMidX([self bounds]), CGRectGetMidY([self bounds]));
    
    
    /*
     if (![self shouldTheWheelMoveInAnyDirectionForPoint:currentTouchPoint]) {
     [self drawWheelAsNeeded];
     return;
     }
     */
    CGPoint previousTouchPoint = [touch previousLocationInView:self];
    CGFloat angleInRadians = atan2f(currentTouchPoint.y - center.y, currentTouchPoint.x - center.x) - atan2f(previousTouchPoint.y - center.y, previousTouchPoint.x - center.x);
    [self setRotation:angleInRadians];
    
    // darshan changed this to originalRadius from radius
    CGFloat oneByFourArcLength = (2 * M_PI * originalRadius ) / 4;
    CGPoint currentPoint = [touch locationInView:self];
    // darshan changed this
    // CGFloat movingAngle = [self calculateDistFrom:currentPoint to:previousPoint] / (oneByFourArcLength);
    CGFloat movingAngle = [self calculateDistFrom:currentPoint to:previousTouchPoint] / (oneByFourArcLength);
    
    if (rotation < 0) {
        
        // anti clockwise
        gTotalAnglesMovedByWheelAnticlockwise = gTotalAnglesMovedByWheelAnticlockwise + [self toDegree:movingAngle];
        gAngleToCenterWord = gAngleToCenterWord + [self toDegree:movingAngle];
        self.transform = CGAffineTransformRotate(self.transform, -movingAngle);
    }else{
        
        gTotalAnglesMovedByWheelClockwise = gTotalAnglesMovedByWheelClockwise + [self toDegree:movingAngle];
        gAngleToCenterWord = gAngleToCenterWord - [self toDegree:movingAngle];
        self.transform = CGAffineTransformRotate(self.transform, movingAngle);
    }
    
    previousPoint = currentPoint;
    if ([self wordsCanFitInSingleQuadrant]) {
        // dont worry about redrawing
        return;
    }
    [self drawWheelAsNeeded];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch* touch =  [touches anyObject];
    initialTouchPoint = [touch locationInView:self];
    
    touchesMoved = NO;
    viewSelectedByTap = FALSE;
    previousPoint = initialTouchPoint;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch* touch =  [touches anyObject];
	if (![self didTouchHappenOnThisView:[touch locationInView:self]]) {
		UIView* previousView = [self previousView];
		if (previousView) {
			[previousView touchesEnded:touches withEvent:event];
		}
	}
    
    if (viewSelectedByTap) {
        DLog(@"touchesEnded: View selected by tap. Return");
        return;
    }
    
    NSUInteger tapCount = [[touches anyObject] tapCount];
    NSUInteger touchesCount = [[event allTouches] count];
    if ( touchesCount > 1 || tapCount > 1) {
        if (![self wordsCanFitInSingleQuadrant]) {
            DLog(@"touchesEnded: More than two touches detected %@ ", self.wheelName);
            [self drawWheelAsNeeded];
        }
        return;
    }
    
    CGPoint currentTouchPoint = [touch locationInView:self];
    CGFloat totalAnglesMoved = [self calculateDistFrom:initialTouchPoint to:currentTouchPoint];
    
    if (totalAnglesMoved < 5 || !touchesMoved) {
        
        id hitView = [self hitTest:currentTouchPoint withEvent:event];
        if (![hitView isKindOfClass:[TPWord class]]) {
            // return if we cant find the view
            // with the center angle
            return;
        }
        TPWord* selectedWordView = hitView;
        [self userWantsToSelectFilter:selectedWordView];
        return;
    }
    
    if (rotation < 0) {
        CGFloat adjustmentAngle = [self getDifferenceAnglesToCenterWord];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        TPWord* viewWithStartingAngleClosestToCenter = [self findViewWhoseStartingAngleClosestToCenter];
        if (gNearestViewToCenter.position != viewWithStartingAngleClosestToCenter.position) {
            gNearestViewToCenter = viewWithStartingAngleClosestToCenter;
            
            // set the adjustment angle
            CGFloat diff = 0;
            
            if(viewWithStartingAngleClosestToCenter.centerAngle > gAngleToCenterWord){
                diff = viewWithStartingAngleClosestToCenter.centerAngle - gAngleToCenterWord;
            }else{
                diff = gAngleToCenterWord - viewWithStartingAngleClosestToCenter.centerAngle;
            }
            adjustmentAngle = diff;
            self.transform = CGAffineTransformRotate(self.transform, [self toRadians:-adjustmentAngle]);
            
            gAngleToCenterWord = gAngleToCenterWord + adjustmentAngle;
            gTotalAnglesMovedByWheelAnticlockwise = gTotalAnglesMovedByWheelAnticlockwise + adjustmentAngle;
            [self setRotation:-1];
            
        }else{
            if ([self giveMeTheAngleWithin360Degrees:gNearestViewToCenter.centerAngle] > [self giveMeTheAngleWithin360Degrees:gAngleToCenterWord]) {
                self.transform = CGAffineTransformRotate(self.transform, [self toRadians:-adjustmentAngle]);
                
                gAngleToCenterWord = gAngleToCenterWord + adjustmentAngle;
                gTotalAnglesMovedByWheelAnticlockwise = gTotalAnglesMovedByWheelAnticlockwise + adjustmentAngle;
                [self setRotation:-1];
            }else{
                self.transform = CGAffineTransformRotate(self.transform, [self toRadians:+adjustmentAngle]);
                
                // its moved clockwise here
                gTotalAnglesMovedByWheelClockwise = gTotalAnglesMovedByWheelClockwise + adjustmentAngle;
                gAngleToCenterWord = gAngleToCenterWord - adjustmentAngle;
                [self setRotation:+1];
            }
        }
        [UIView commitAnimations];
        
    }else{
        CGFloat adjustmentAngle = [self getDifferenceAnglesToCenterWord];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        TPWord* viewWithEndingAngleClosestToCenter = [self findViewWhoseEndingAngleClosestToCenter];
        if (gNearestViewToCenter.position != viewWithEndingAngleClosestToCenter.position) {
            gNearestViewToCenter = viewWithEndingAngleClosestToCenter;
            
            // set the adjustment angle
            CGFloat diff = 0;
            
            if(viewWithEndingAngleClosestToCenter.centerAngle > gAngleToCenterWord){
                diff = viewWithEndingAngleClosestToCenter.centerAngle - gAngleToCenterWord;
            }else{
                diff = gAngleToCenterWord - viewWithEndingAngleClosestToCenter.centerAngle;
            }
            adjustmentAngle = diff;
            self.transform = CGAffineTransformRotate(self.transform, [self toRadians:+adjustmentAngle]);
            gAngleToCenterWord = gAngleToCenterWord - adjustmentAngle;
            gTotalAnglesMovedByWheelClockwise = gTotalAnglesMovedByWheelClockwise + adjustmentAngle;
            [self setRotation:+1];
            
        }else{
            if ([self giveMeTheAngleWithin360Degrees:gNearestViewToCenter.centerAngle] < [self giveMeTheAngleWithin360Degrees:gAngleToCenterWord]) {
                self.transform = CGAffineTransformRotate(self.transform, [self toRadians:adjustmentAngle]);
                
                gAngleToCenterWord = gAngleToCenterWord - adjustmentAngle;
                gTotalAnglesMovedByWheelClockwise = gTotalAnglesMovedByWheelClockwise + adjustmentAngle;
                [self setRotation:+1];
            }else{
                self.transform = CGAffineTransformRotate(self.transform, [self toRadians:-adjustmentAngle]);
                
                // its moved anticlockwise here
                gTotalAnglesMovedByWheelAnticlockwise = gTotalAnglesMovedByWheelAnticlockwise + adjustmentAngle;
                gAngleToCenterWord = gAngleToCenterWord + adjustmentAngle;
                [self setRotation:-1];
            }
        }
        
        [UIView commitAnimations];
    }
    
    if (![self wordsCanFitInSingleQuadrant]) {
        [self drawWheelAsNeeded];
    }
    
    [self centerSelectedWord];
    [self redrawSelectedWord];
    
}

-(NSMutableArray*) viewsWithAnglesBetweenAngle:(CGFloat) startAngle endAngle:(CGFloat) endAngle{
    NSMutableArray* viewsInBetween = [[NSMutableArray alloc] init];
    TPWord* circleView;
    for (id view in [self subviews]) {
        
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        circleView = view;
        if (circleView.centerAngle > startAngle && circleView.centerAngle < endAngle) {
            [viewsInBetween addObject:circleView];
        }
    }
    return viewsInBetween;
}

-(CGFloat) differenceToCenterAngleFromView:(TPWord*) selectedView forDirection:(BOOL) clockwise{
    CGFloat oneByFourArcLength = (2 * M_PI * originalRadius ) / 4;
    CGFloat anglesToMoveForArcLength = [self angleInDegreesForArcLength:oneByFourArcLength];
    CGFloat diff = 0;
    
    if (clockwise) {
        diff = gAngleToCenterWord - selectedView.centerAngle;
    }else{
        diff = selectedView.centerAngle - gAngleToCenterWord;
    }
    if (diff < 0) {
        diff = -1 * diff;
    }
    if (diff > anglesToMoveForArcLength) {
        diff = 0;
    }
    return diff;
}

#pragma mark -Tap
- (void) doDoubleTap: (UITapGestureRecognizer *)recognizer{
    viewSelectedByTap = TRUE;
}

- (void) userTappedOnView: (UITapGestureRecognizer *)recognizer{
    viewSelectedByTap = TRUE;
}
- (void) userWantsToSelectFilter:(TPWord*) selectedView
{
    CGFloat diff = 0;
    BOOL clockwise = YES;
    if(gAngleToCenterWord > selectedView.centerAngle){
        clockwise = YES;
        NSMutableArray* viewsInBetween = [self viewsWithAnglesBetweenAngle:selectedView.centerAngle endAngle:gAngleToCenterWord];
        if ([viewsInBetween count] > 0) {
            for (TPWord* view in viewsInBetween) {
                diff = [self differenceToCenterAngleFromView:view forDirection:clockwise];
                [self rotateWheelWhenTappedForAngles:diff];
                gAngleToCenterWord = gAngleToCenterWord - diff;
                gTotalAnglesMovedByWheelClockwise = gTotalAnglesMovedByWheelClockwise + diff;
                [self setRotation:+1];
                
                if ([self wordsCanFitInSingleQuadrant]) {
                    
                    [self centerSelectedWord];
                    [self redrawSelectedWord];
                    return;
                }
                
                if (diff > 0) {
                    // draw the angles only if there is any change
                    // e.g. user keeps tapping on the center word
                    [self drawWheelAsNeeded];
                    // [self centerSelectedWord];
                    [self redrawSelectedWord];
                }
            }
        }
        
        diff = [self differenceToCenterAngleFromView:selectedView forDirection:clockwise];
        [self rotateWheelWhenTappedForAngles:diff];
        
        gAngleToCenterWord = gAngleToCenterWord - diff;
        gTotalAnglesMovedByWheelClockwise = gTotalAnglesMovedByWheelClockwise + diff;
        [self setRotation:+1];
    }else{
        //DLog(@"anti clockwise ");
        clockwise = NO;
        NSMutableArray* viewsInBetween = [self viewsWithAnglesBetweenAngle:gAngleToCenterWord endAngle:selectedView.centerAngle];
        if ([viewsInBetween count] > 0) {
            for (TPWord* view in viewsInBetween) {
                
                diff = [self differenceToCenterAngleFromView:view forDirection:clockwise];
                [self rotateWheelWhenTappedForAngles:-diff];
                gAngleToCenterWord = gAngleToCenterWord + diff;
                gTotalAnglesMovedByWheelAnticlockwise = gTotalAnglesMovedByWheelAnticlockwise + diff;
                [self setRotation:-1];
                
                if ([self wordsCanFitInSingleQuadrant]) {
                    [self centerSelectedWord];
                    [self redrawSelectedWord];
                    return;
                }
                
                if (diff > 0) {
                    // draw the angles only if there is any change
                    // e.g. user keeps tapping on the center word
                    [self drawWheelAsNeeded];
                    // [self centerSelectedWord];
                    [self redrawSelectedWord];
                }
            }
        }
        
        diff = [self differenceToCenterAngleFromView:selectedView forDirection:clockwise];
        [self rotateWheelWhenTappedForAngles:-diff];
        gAngleToCenterWord = gAngleToCenterWord + diff;
        gTotalAnglesMovedByWheelAnticlockwise = gTotalAnglesMovedByWheelAnticlockwise + diff;
        [self setRotation:-1];
    }
    
    if ([self wordsCanFitInSingleQuadrant]) {
        [self centerSelectedWord];
        [self redrawSelectedWord];
        return;
    }
    
    if (diff > 0) {
        // draw the angles only if there is any change
        // e.g. user keeps tapping on the center word
        [self drawWheelAsNeeded];
        // [self centerSelectedWord];
        [self redrawSelectedWord];
    }
}

-(void) rotateWheelWhenTappedForAngles:(CGFloat) diff{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    self.transform = CGAffineTransformRotate(self.transform, [self toRadians:diff]);
    [UIView commitAnimations];
}

-(TPWord*) getSelectedFrame:(CGPoint) point
{
    // careful - this is used in draw wheel as needed method too.
    TPWord* circleView;
    TPWord* selectedView = [[TPWord alloc] init];
    NSMutableArray *viewsInSelectedPoint = [[NSMutableArray alloc] init];
    
    for (id view in [self subviews]) {
        
        if (![view isKindOfClass:[TPWord class]]) {
            continue;
        }
        circleView = view;
        if(CGRectContainsPoint(circleView.frame, point)){
            //DLog(@"circleView %@ ",circleView.textPresentInView);
            selectedView = circleView;
            return selectedView;
            [viewsInSelectedPoint addObject:selectedView];
        }
    }
    
    
    if ([viewsInSelectedPoint count] > 1) {
        // two views contain the same point
        // get the difference between the angle to be centered
        // and selected view
        CGFloat minDiff = 100000000;
        for (TPWord* view in viewsInSelectedPoint) {
            CGFloat diff = [self calculateDistFrom:point to:view.center];
            if (diff < minDiff) {
                minDiff = diff;
                selectedView = view;
            }
        }
    }
    
    // there will always be one selected view
    return selectedView;
    
}

#pragma mark - monkeytalk

-(void)playbackMonkeyEvent:(MTCommandEvent *)event{
    
    // limitation: selectWord (Arguments)  should be visible on the wheel to be recognized by the method.

    if ([event.command isEqualToString:@"tapWord"]){
        if (![event.args objectAtIndex:0]) {  //the first arg is filter word
            event.lastResult =@"tapWord requires one argment (word to be selected)";
            return;
        }
        NSString* selectWord =(NSString*)[event.args objectAtIndex:0];
        //NSLog(@"argumnt value *** %@ ", selectWord);
        for (TPWord* view in [self subviews]) {
            if ([view isKindOfClass:[TPWord class]]) {
                //NSLog(@"wheel **** %@ values **** %@ ", self.wheelName, view.textPresentInView);
                NSString* textInView = [[NSString alloc] initWithFormat:@"%@", view.textPresentInView];
                NSString *trimmed = [textInView stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ([trimmed isEqualToString:selectWord]) {
                    //NSLog(@"view IS selected");
                    
                    [self userWantsToSelectFilter:view];
                }
            }
        }
    }
    
}

@end

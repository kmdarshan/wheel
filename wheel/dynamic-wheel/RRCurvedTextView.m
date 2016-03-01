#import "RRCurvedTextView.h"

@interface RRCurvedTextView ()
@property (readonly) NSAttributedString* attString;
@property (readonly) NSMutableArray* angleArray;
@end

@implementation RRCurvedTextView
@synthesize widthArray;

- (NSMutableArray*) angleArray {
    if (!angleArray){
        angleArray = [[NSMutableArray alloc] init];
    }
    return angleArray;
}

- (NSMutableArray*) widthArray {
    if (!widthArray){
        widthArray = [[NSMutableArray alloc] init];
    }
    return widthArray;
}

- (void)setupAttributedString {
    CTFontRef fontRef = CTFontCreateWithName((CFStringRef)(self.textFont), self.textSize, NULL); //1
    NSDictionary *attrDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (id)fontRef, kCTFontAttributeName, nil];
    CFRelease(fontRef);
    
    if (attString){
        [attString release];
    }
    attString = [[NSAttributedString alloc] initWithString:self.text attributes:attrDictionary]; //2
    
}


-(void)doInitialSetup{
	[self setupAttributedString];
	[self setupDrawRectParameters];
	setupRequired = NO;
}

- (UIColor*) textColor {
    if (!textColor) {
        self.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    }
    return textColor;
}

- (void) setTextColor:(UIColor *)newColor {
    if (textColor){
        [textColor release];
    }
    textColor = newColor;
    [textColor retain];
	
    const CGFloat*  components = CGColorGetComponents([textColor CGColor]);
    red = components[0];
    green = components[1];
    blue = components[2];
    alpha = components[3];
    
    [self setNeedsDisplay];
}

- (void)dealloc {
    [attString release];
    [text release];
    [textColor release];
    [textFont release];
    [widthArray release];
    [angleArray release];
    if (line) {
        CFRelease(line);
    }
    [super dealloc];
}

// Utility method to invert context
- (void)invertContext:(CGContextRef) context {
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, self.bounds.size.width/2, self.bounds.size.height/2);
    CGContextScaleCTM(context, 1.0, -1.0);
}

- (void)setupDrawRectParameters {
    
    CGFloat         lineLength;
    CGFloat         localTextRadius;
    CFIndex         glyphCount;
    CFArrayRef      runArray;
    CFIndex         runCount;
    CTRunRef        run;
    CFIndex         runGlyphCount;
    NSNumber*       widthValue;
    CFIndex         glyphOffset = 0;
    CGFloat         prevHalfWidth;
    NSNumber*       angleValue;
    CGFloat         halfWidth;
    CGFloat         prevCenterToCenter;
	
    if (line){
        CFRelease(line);
    }
    line = CTLineCreateWithAttributedString((CFAttributedStringRef)(self.attString));
    lineLength = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
    
    if (!lineLength){
        return;
    }
    
    localTextRadius = self.textRadius;
    
    // Get the line, glyphs, runs
    glyphCount = CTLineGetGlyphCount(line);
    runArray = CTLineGetGlyphRuns(line);
    runCount = CFArrayGetCount(runArray);
    
    // Make array of width of all
    glyphOffset = 0;
    for (CFIndex i = 0; i < runCount; i++) {
        run = (CTRunRef)CFArrayGetValueAtIndex(runArray, i);
        runGlyphCount = CTRunGetGlyphCount((CTRunRef)run);
        
        for (CFIndex j = 0; j < runGlyphCount; j++) {
            
            widthValue = [NSNumber numberWithDouble:CTRunGetTypographicBounds((CTRunRef)run, CFRangeMake(j, 1), NULL, NULL, NULL)];
            [self.widthArray insertObject:widthValue atIndex:(j + glyphOffset)];
        }
        glyphOffset = runGlyphCount + 1;
        
    }
    
    // Store angles of glyphs in an array
    prevHalfWidth =  [[self.widthArray objectAtIndex:0] floatValue] / 2.0;
    angleValue = [NSNumber numberWithDouble:(prevHalfWidth / lineLength) * (lineLength/localTextRadius)];
    [self.angleArray insertObject:angleValue atIndex:0];
    
    for (CFIndex i = 1; i < glyphCount; i++) {
        halfWidth = [[self.widthArray objectAtIndex:i] floatValue] / 2.0;
        prevCenterToCenter = prevHalfWidth + halfWidth;
        angleValue = [NSNumber numberWithDouble:(prevCenterToCenter / lineLength) * (lineLength/localTextRadius)];
        [self.angleArray insertObject:angleValue atIndex:i]; //13
        prevHalfWidth = halfWidth;
    }
    
	
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect]; //1
	
    CGFloat         localTextRadius;
    CFArrayRef      runArray;
    CFIndex         runCount;
    CGContextRef    context;
    CGFloat         lineLength;
    CFIndex         glyphOffset;
    CTRunRef        run;
    CFIndex         runGlyphCount;
    CGPoint         textPosition;
    CTFontRef       runFont;
    CFRange         glyphRange;
    CGFloat         glyphWidth;
    CGFloat         halfGlyphWidth;
    CGPoint         positionForThisGlyph;
    CGGlyph         glyph;
    CGPoint         position;
    CGAffineTransform textMatrix;
    CGFontRef       cgFont;
    NSMutableArray* localWidthArray;
    NSMutableArray* localAngleArray;
    
    if (setupRequired) {
        [self setupAttributedString];
        [self setupDrawRectParameters];
        setupRequired = NO;
    }
    
    lineLength = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
    
    if (!lineLength){
        return;
    }
    
    localTextRadius = self.textRadius;
    
    // Get the line, glyphs, runs
    runArray = CTLineGetGlyphRuns(line);
    runCount = CFArrayGetCount(runArray);
    
    // Inverting the reference frame to work with iOS
    context = UIGraphicsGetCurrentContext();
    [self invertContext:context];
    
    // Move the origin from the lower left of the view nearer to its center.
    CGContextSaveGState(context);
    
    // Rotate half way to the left so text aligns in the center!
    CGContextRotateCTM(context, (lineLength/2)/localTextRadius);
    
	// draw the glyphs
    textPosition = CGPointMake(0.0, localTextRadius - 10);
    CGContextSetTextPosition(context, textPosition.x, textPosition.y);
    glyphOffset = 0;
    
    localWidthArray = self.widthArray;
    localAngleArray = self.angleArray;
    
    for (CFIndex i = 0; i < runCount; i++) {
        run = (CTRunRef)CFArrayGetValueAtIndex(runArray, i);
        runGlyphCount = CTRunGetGlyphCount(run);
        runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
        
        for (CFIndex j = 0; j < runGlyphCount; j++) {
            
			glyphRange = CFRangeMake(j, 1);
            
            CGContextRotateCTM(context, -[[localAngleArray objectAtIndex:(j + glyphOffset)] floatValue]);
            
            glyphWidth = [[localWidthArray objectAtIndex:(j + glyphOffset)] floatValue];
            
            halfGlyphWidth = glyphWidth / 2.0;
            
            positionForThisGlyph = CGPointMake(textPosition.x - halfGlyphWidth, textPosition.y);
            
            textPosition.x -= glyphWidth;
            textMatrix = CTRunGetTextMatrix(run);
            textMatrix.tx = positionForThisGlyph.x;
            textMatrix.ty = positionForThisGlyph.y;
            
            CGContextSetTextMatrix(context, textMatrix);
            
            cgFont = CTFontCopyGraphicsFont(runFont, NULL);
            CTRunGetGlyphs(run, glyphRange, &glyph);
            CTRunGetPositions(run, glyphRange, &position);
            CGContextSetFont(context, cgFont);
            CGContextSetFontSize(context, CTFontGetSize(runFont));
            CGContextSetRGBFillColor(context, red, green, blue, alpha);
            CGContextShowGlyphsAtPositions(context, &glyph, &position, 1);
            CFRelease(cgFont);
            
        }
        glyphOffset += runGlyphCount;
    }
}

- (void)setText:(NSString*) newText {
    if (!text) [text release];
    
    text = newText;
    [text retain];
    
    setupRequired = YES;
    [self setNeedsDisplay];
}

- (CGFloat) textRadius {
    if (!textRadius) {
        textRadius = 100.0;
        setupRequired = YES;
        [self setNeedsDisplay];
    }
    return textRadius;
}

- (void) setTextRadius:(CGFloat)newRadius {
    textRadius = newRadius;
    setupRequired = YES;
    [self setNeedsDisplay];
}

- (CGFloat) textSize {
    if (!textSize) {
        textSize = 14.0f;
        setupRequired = YES;
        [self setNeedsDisplay];
    }
    return textSize;
}

- (void) setTextSize:(CGFloat)newTextSize {
    textSize = newTextSize;
    setupRequired = YES;
    [self setNeedsDisplay];
}

- (NSString*) textFont {
    if (!textFont) {
        self.textFont = @"Arial Rounded MT Bold";
        setupRequired = YES;
        [self setNeedsDisplay];
    }
    return textFont;
}

- (void) setTextFont:(NSString *)newFontName {
    if (textFont) [textFont release];
    textFont = newFontName;
    [textFont retain];
    setupRequired = YES;
    [self setNeedsDisplay];
}

- (NSAttributedString*) attString {
    if (!attString) {
        [self setupAttributedString];
        setupRequired = YES;
        [self setNeedsDisplay];
		
    }
    return attString;
}

- (NSString*) text {
    if (!text) {
        text = [[NSString alloc] initWithString:@""];
        setupRequired = YES;
        [self setNeedsDisplay];
    }
    return text;
}




@end

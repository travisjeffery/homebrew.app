
//  TSPProgressIndicator.m
//  TSPProgressIndicator
//
//
//  Created by Synapse on 25.06.2010.
//  Copyright 2010 TheSynapseProject. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSBezierPath+PXRoundedRectangleAdditions.h"
#import "NSBezierPath+MCAdditions.h"

@interface TSPProgressIndicator : NSView {
	double doubleValue;
	double maxValue;
	double cornerRadius;
	
	BOOL isIndeterminate;
	BOOL usesThreadedAnimation;

	NSThread *_animationThread;
	
	float fontSize;
	float shadowBlur;
	int position;
	NSString *progressText;
	
	NSColor *progressHolderColor;
	NSColor *progressColor;
	NSColor *backgroundTextColor;
	NSColor *frontTextColor;
	NSColor *shadowColor;
	NSRect indeterminateRect;

@private
	int _step;
	NSTimer *_timer;
	NSImage *_indeterminateImage, *_indeterminateImage2;
	BOOL _animationStarted;
	BOOL _animationStartedThreaded;
	float _gradientWidth;
}

@property (readwrite,assign) double doubleValue;
@property (readwrite,assign) double maxValue;
@property (readwrite,assign) double cornerRadius;
@property (readwrite,assign) float fontSize;
@property (readwrite,assign) float shadowBlur;
@property (readwrite,assign) BOOL isIndeterminate;
@property (readwrite,assign) BOOL usesThreadedAnimation;
@property (readwrite,retain) NSString *progressText;
@property (readwrite,retain) NSColor *progressHolderColor;
@property (readwrite,retain) NSColor *progressColor;
@property (readwrite,retain) NSColor *backgroundTextColor;
@property (readwrite,retain) NSColor *frontTextColor;
@property (readwrite,retain) NSColor *shadowColor;


- (void)setIsIndeterminate:(BOOL)aBool;
- (BOOL)isIndeterminate;

- (void)setProgressTextAlign:(int)pos;
- (int)progressTextAlignt;
- (float)alignTextOnProgress:(NSRect)rect fontSize:(NSSize)size;
- (IBAction)startAnimation:(id)sender;
- (IBAction)stopAnimation:(id)sender;
- (void)animateInBackgroundThread;
@end

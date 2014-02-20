/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@interface TVCTextFieldWithValueValidation ()
/* Maintain cached value so that the drawing does not call 
 the validaton block every time that it is called. */
@property (nonatomic, assign) BOOL cachedValidValue;
@end

@implementation TVCTextFieldWithValueValidation;

#pragma mark -
#pragma mark Public API

- (NSString *)value
{
	if (self.stringValueUsesOnlyFirstToken) {
		return [self firstTokenStringValue];
	} else {
		return [self stringValue];
	}
}

- (BOOL)valueIsEmpty
{
	return NSObjectIsEmpty([self value]);
}

- (BOOL)valueIsValid
{
	return self.cachedValidValue;
}

#pragma mark -
#pragma mark Interval Validation

- (void)textDidChange:(NSNotification *)notification
{
	[self performValidation];
	[self informCallbackTextDidChange];
}

- (void)setStringValue:(NSString *)aString
{
	[super setStringValue:aString];

	[self performValidation];
	[self informCallbackTextDidChange];
}

- (void)informCallbackTextDidChange
{
	if (self.textDidChangeCallback) {
		if ([self.textDidChangeCallback respondsToSelector:@selector(validatedTextFieldTextDidChange:)]) {
			[self.textDidChangeCallback performSelector:@selector(validatedTextFieldTextDidChange:) withObject:self];
		}
	}
}

- (void)performValidation
{
	if ([self valueIsEmpty] == NO) {
		if (self.validationBlock) {
			self.cachedValidValue = self.validationBlock([self stringValue]);
		} else {
			self.cachedValidValue = YES;
		}
	} else {
		self.cachedValidValue = (self.stringValueIsInvalidOnEmpty == NO);
	}

	[self setNeedsDisplay:YES];
}

@end

#pragma mark -
#pragma mark Text Field Cell

@implementation TVCTextFieldWithValueValidationCell

- (NSRect)correctedDrawingRect:(NSRect)aRect
{
	/* Update size. */
	aRect.size.width -= 12;

	/* Return frame. */
	return aRect;
}

- (NSColor *)erroneousValueBackgroundColor
{
	return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.05];
}

- (NSRect)erroneousValueBadgeIconRectInParentRect:(NSRect)aRect
{
	NSInteger rightEdge = (NSMaxX(aRect) - 22);

	return NSMakeRect(rightEdge, 4, 15, 15);
}

- (BOOL)isEditing
{
	return NSDissimilarObjects([[self parentField] currentEditor], nil);
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	/* Draw a background color. */
	if ([self parentValueIsValid] == NO) {
		NSRect backgroundFrame = cellFrame;

		backgroundFrame.origin.x += 1;
		backgroundFrame.origin.y += 1;

		backgroundFrame.size.width -= 2;
		backgroundFrame.size.height -= 2;

		[[self erroneousValueBackgroundColor] set];

		[[NSBezierPath bezierPathWithRect:backgroundFrame] fill];
	}

	/* Draw rest of text field. */
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	/* Draw to super. */
	[super drawWithFrame:cellFrame inView:controlView];

	/* Draw status image badge. */
	NSImage *statusImage;

	if ([self parentValueIsValid] == NO) {
		statusImage = [NSImage imageNamed:@"ErroneousTextFieldValueIndicator"];
	} else {
		if ([self parentValueIsEmpty] == NO) {
			statusImage = [NSImage imageNamed:@"ProperlyFormattedTextFieldValueIndicator"];
		}
	}

	if (statusImage) {
		NSRect statusImageDrawRect = [self erroneousValueBadgeIconRectInParentRect:cellFrame];

		[statusImage drawInRect:statusImageDrawRect
					   fromRect:NSZeroRect
					  operation:NSCompositeSourceOver
					   fraction:1.0
				 respectFlipped:YES
						  hints:nil];
	}
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
	[super editWithFrame:[self correctedDrawingRect:aRect] inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	[super selectWithFrame:[self correctedDrawingRect:aRect] inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
	return [self correctedDrawingRect:[super drawingRectForBounds:theRect]];
}

- (BOOL)parentsAllowsEmptyValue
{
	return ([[self parentField] stringValueIsInvalidOnEmpty] == NO);
}

- (BOOL)parentValueIsEmpty
{
	return [[self parentField] valueIsEmpty];
}

- (BOOL)parentValueIsValid
{
	return [[self parentField] valueIsValid];
}

@end

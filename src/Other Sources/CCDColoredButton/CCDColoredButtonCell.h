//  Found at http://danieldickison.com/blog/index.php?/archives/10-Making-Cocoa-buttons-look-happy.html

#import <Cocoa/Cocoa.h>


@interface CCDColoredButtonCell : NSButtonCell {
	NSColor *buttonColor;
}

- (NSColor *)buttonColor;
- (void)setButtonColor:(NSColor *)color;

- (NSColor *)titleColor;
- (void)setTitleColor:(NSColor *)color;

@end

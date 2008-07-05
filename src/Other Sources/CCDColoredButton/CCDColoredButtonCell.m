//
//  CCDColoredButtonCell.m
//
//  Adapted from CocoaDevCentral
//  http://www.cocoadev.com/index.pl?CCDColoredButtonCell
//
//  Found at http://danieldickison.com/blog/index.php?/archives/10-Making-Cocoa-buttons-look-happy.html

#import "CCDColoredButtonCell.h"

    
    @implementation CCDColoredButtonCell
    
    - (NSColor *)buttonColor
    {
		if (buttonColor)
			return buttonColor;
		else
			return [NSColor clearColor];
    }
    
    - (void)setButtonColor:(NSColor *)color
    {   
        [buttonColor release];
        buttonColor = [color copy];
		[[self controlView] setNeedsDisplay:YES];
    }
    


	- (NSColor *)titleColor
	{
		NSAttributedString *attrStr = [self attributedTitle];
		if ([attrStr length] > 0)
		{
			NSColor *color =  [[attrStr attributesAtIndex:0 effectiveRange:NULL]
								objectForKey:NSForegroundColorAttributeName];
			if (color)
				return color;
		}
		return [NSColor blackColor];
	}

    - (void)setTitleColor:(NSColor *)color
    {
        NSMutableAttributedString *attrStr = [[self attributedTitle] mutableCopy];
        [attrStr addAttributes:[NSDictionary dictionaryWithObject:color
                                                           forKey:NSForegroundColorAttributeName]
                         range:NSMakeRange(0, [attrStr length])];
        [self setAttributedTitle:attrStr];
        [attrStr release];
		[[self controlView] setNeedsDisplay:YES];
    }
    
    
    - (void)drawBezelWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
    {
        if (!buttonColor || ([buttonColor isEqualTo:[NSColor clearColor]])) {
            [super drawBezelWithFrame:cellFrame inView:controlView];
            return;
        }
        
        NSRect canvasFrame = NSMakeRect(0, 0, cellFrame.size.width, cellFrame.size.height);
        
        NSImage *finalImage = [[NSImage alloc] initWithSize:cellFrame.size];
        NSImage *colorImage = [[NSImage alloc] initWithSize:cellFrame.size];
        NSImage *cellImage = [[NSImage alloc] initWithSize:cellFrame.size];
        
        [finalImage setFlipped:[controlView isFlipped]];
        
        // Draw the cell into an image
        [cellImage lockFocus];
        [super drawBezelWithFrame:canvasFrame inView:[NSView focusView]];
        [cellImage unlockFocus];
        
        // Draw the color but only over the opaque parts of the cell image
        [colorImage lockFocus];
        [cellImage drawAtPoint:NSZeroPoint fromRect:canvasFrame operation:NSCompositeSourceOver fraction:1];
        [buttonColor set];
        NSRectFillUsingOperation(canvasFrame, NSCompositeSourceIn);
        [colorImage unlockFocus];
        
        // Mix the colored overlay with the cell image using CompositePlusDarker
        [finalImage lockFocus];
        [colorImage drawAtPoint:NSZeroPoint fromRect:canvasFrame operation:NSCompositeSourceOver fraction:1];
        [cellImage drawAtPoint:NSZeroPoint fromRect:canvasFrame operation:NSCompositePlusDarker fraction:1];
        [finalImage unlockFocus];
        
        // Draw the final image to the screen
        [finalImage drawAtPoint:cellFrame.origin fromRect:canvasFrame operation:NSCompositeSourceOver fraction:1];
        
        [cellImage release];
        [colorImage release];
        [finalImage release];
    }
    
    @end

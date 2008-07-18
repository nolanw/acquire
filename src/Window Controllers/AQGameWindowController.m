// AQGameWindowController.m
//
// Created May 28, 2008 by nwaite

#import "AQGameWindowController.h"
#import "AQGame.h"

@implementation AQGameWindowController
- (id)init;
{
	if (![super init])
		return nil;
	
	

	return self;
}

- (void)dealloc;
{
	// Should probably have something whereby closing the game window sends a leave game directive, etc.
	[_gameWindow close];
	[_gameWindow release];
	
	[_game endGame];
	
	[super dealloc];
}

// NSObject (NSNibAwakening)
- (void)awakeFromNib;
{
	// Tell the Game about us
	[(AQGame *)_game registerGameWindowController:self];
	[[_gameChatTextView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	[[_gameLogTextView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
}


- (void)updateScoreboard;
{
	
}

- (void)tilesChanged:(NSArray *)changedTiles;
{
	
}

- (void)incomingGameMessage:(NSString *)gameMessage;
{
	if ([[_gameChatTextView textStorage] length] > 0)
		[[_gameChatTextView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];

	NSAttributedString *attributedGameMessage = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", gameMessage]] autorelease];
	[[_gameChatTextView textStorage] appendAttributedString:attributedGameMessage];
	
	// Scroll to bottom found in Cocoa docs
	// http://developer.apple.com/documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/Scrolling.html
	NSPoint newScrollOrigin;

    if ([[_gameChatScrollView documentView] isFlipped]) {
        newScrollOrigin = NSMakePoint(0.0, NSHeight([[_gameChatScrollView documentView] frame]) - NSHeight([[_gameChatScrollView contentView] bounds]));
    } else {
        newScrollOrigin=NSMakePoint(0.0, 0.0);
    }

    [[_gameChatScrollView documentView] scrollPoint:newScrollOrigin];
}

- (IBAction)sendGameMessage:(id)sender;
{
	NSString *trimmedGameChatMessage = [[_messageToGameTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if ([trimmedGameChatMessage length] == 0)
		return;

	[_messageToGameTextField setStringValue:@""];

	[_game outgoingGameChatMessage:trimmedGameChatMessage];
}


// Window visibility
- (void)closeGameWindow;
{
	[_gameWindow close];
}

- (void)bringGameWindowToFront;
{
	[_gameWindow makeKeyAndOrderFront:self];
}

- (void)setWindowTitle:(NSString *)windowTitle;
{
	[_gameWindow setTitle:windowTitle];
}

- (void)removeGameChatTabViewItem;
{
	[_gameChatAndLogTabView removeTabViewItem:[_gameChatAndLogTabView tabViewItemAtIndex:0]];
}
@end

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
@end

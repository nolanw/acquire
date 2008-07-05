// AQGame.h
//
// Created May 28, 2008 by nwaite

#import "AQGame.h"

@interface AQGame (Private)
// Nib loaders
- (void)_loadGameWindow;
@end

@implementation AQGame
- (id)init;
{
	if (![super init])
		return nil;
	
	_gameWindowController = nil;

	return self;
}

- (void)dealloc;
{
	// GameWindowController releases the game window it's responsible for, and there's nothing else in any nibs we open to release.
	[_gameWindowController release];
	_gameWindowController = nil;
	
	[super dealloc];
}


// Allow objects in loaded nibs to say hi
- (void)registerGameWindowController:(AQGameWindowController *)gameWindowController;
{
	if (_gameWindowController != nil) {
		NSLog(@"%s another GameWindowController is already registered", _cmd);
		return;
	}

	_gameWindowController = gameWindowController;
}
@end

@implementation AQGame (Private)
// Nib loaders
- (void)_loadGameWindow;
{
	if (_gameWindowController != nil) {
		NSLog(@"%s WelcomeWindow already loaded", _cmd);
		return;
	}
	
	if (![NSBundle loadNibNamed:@"GameWindow" owner:self]) {
		NSLog(@"%s failed to load GameWindow.nib", _cmd);
	}
}
@end

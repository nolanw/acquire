// AQGame.h
// Game represents a game of Acquire.
//
// Created May 28, 2008 by nwaite

#import "AQGameWindowController.h"

@interface AQGame : NSObject
{
	AQGameWindowController	*_gameWindowController;
}

- (id)init;
- (void)dealloc;

// Allow objects in loaded nibs to say hi
- (void)registerGameWindowController:(AQGameWindowController *)gameWindowController;
@end

// AQGameWindowController.h
// GameWindowController handles the connection between the game window and the game.
//
// Created May 28, 2008 by nwaite

@interface AQGameWindowController : NSObject
{
	IBOutlet id			_game;
	IBOutlet NSWindow	*_gameWindow;
}

- (id)init;
- (void)dealloc;

// NSObject (NSNibAwakening)
- (void)awakeFromNib;

// Window visibility
- (void)closeGameWindow;
- (void)bringGameWindowToFront;
@end

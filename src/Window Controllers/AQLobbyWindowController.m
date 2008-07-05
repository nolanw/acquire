#import "AQLobbyWindowController.h"
#import "AQAcquireController.h"

@interface AQLobbyWindowController (Private)
- (void)_populateGameListDrawerWithGames:(NSArray *)games;
@end

@implementation AQLobbyWindowController
- (id)init;
{
	if (![super init])
		return nil;
	
	

	return self;
}

- (void)dealloc;
{
	[_gameListUpdateTimer invalidate];
	[_gameListUpdateTimer release];
	_gameListUpdateTimer = nil;
	[_lobbyWindow release];
	
	[super dealloc];
}


// NSObject (NSNibAwakening)
- (void)awakeFromNib;
{
	[(AQAcquireController *)_acquireController registerLobbyWindowController:self];
	
	[_lobbyWindow setTitle:@"Acquire – Connected to server"];
	
	[_messageToLobbyTextField selectText:self];
	[[_lobbyChatTextView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	
	[_gameListDrawer setPreferredEdge:NSMaxXEdge];
	[self _populateGameListDrawerWithGames:nil];
	[_gameListDrawer open];
	
	_gameListUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(requestGameListUpdate:) userInfo:nil repeats:YES] retain];
}


// Window visibility
- (void)closeLobbyWindow;
{
	[_lobbyWindow close];
	_lobbyWindow = nil;
}

- (void)bringLobbyWindowToFront;
{
	[_lobbyWindow makeKeyAndOrderFront:self];
}


// UI button actions
- (IBAction)sendLobbyMessage:(id)sender;
{
	NSString *trimmedLobbyMessage = [[_messageToLobbyTextField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if ([trimmedLobbyMessage length] == 0)
		return;

	[_messageToLobbyTextField setStringValue:@""];

	[_acquireController outgoingLobbyMessage:trimmedLobbyMessage];
}

- (IBAction)createNewGame:(id)sender;
{
	
}

- (IBAction)joinGame:(id)sender;
{
	
}


- (void)incomingLobbyMessage:(NSString *)lobbyMessage;
{
	NSAttributedString *attributedLobbyMessage = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", lobbyMessage]] autorelease];
	[[_lobbyChatTextView textStorage] appendAttributedString:attributedLobbyMessage];
	
	// Scroll to bottom found in Cocoa docs
	// http://developer.apple.com/documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/Scrolling.html
	
	NSPoint newScrollOrigin;

    if ([[_lobbyChatScrollView documentView] isFlipped]) {
        newScrollOrigin = NSMakePoint(0.0,NSMaxY([[_lobbyChatScrollView documentView] frame]) - NSHeight([[_lobbyChatScrollView contentView] bounds]));
    } else {
        newScrollOrigin=NSMakePoint(0.0,0.0);
    }

    [[_lobbyChatScrollView documentView] scrollPoint:newScrollOrigin];
}

- (void)requestGameListUpdate:(NSTimer *)theTimer;
{
	[_acquireController updateGameListFor:self];
}

- (void)updatedGameList:(NSArray *)gameList;
{
	[self _populateGameListDrawerWithGames:gameList];
}
@end

@implementation AQLobbyWindowController (Private)
- (void)_populateGameListDrawerWithGames:(NSArray *)games;
{
	NSButtonCell *prototype = [[[NSButtonCell alloc] init] autorelease];
	[prototype setButtonType:NSRadioButton];
	
	[_gameListMatrix setPrototype:prototype];
	[_gameListMatrix setAllowsEmptySelection:NO];
	[_gameListMatrix setIntercellSpacing:NSMakeSize(4.0f, 2.0f)];
	[_gameListMatrix setCellSize:NSMakeSize(122.0f, 18.0f)];
	[_gameListMatrix setMode:NSRadioModeMatrix];
	
	[_gameListMatrix renewRows:4 columns:1];
	
	[[_gameListMatrix cellAtRow:0 column:0] setTitle:@"Game #1"];
	[[_gameListMatrix cellAtRow:1 column:0] setTitle:@"Game #2"];
	[[_gameListMatrix cellAtRow:2 column:0] setTitle:@"Game #3"];
	[[_gameListMatrix cellAtRow:3 column:0] setTitle:@"Game #4"];
	
	[_gameListMatrix sizeToCells];
}
@end

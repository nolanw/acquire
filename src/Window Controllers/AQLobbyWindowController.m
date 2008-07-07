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
	
	[_lobbyWindow setTitle:[NSString stringWithFormat:@"Acquire – %@ – %@", NSLocalizedStringFromTable(@"Lobby", @"Acquire", @"The word 'lobby'."), [_acquireController connectedHostOrIPAddress]]];
	
	[_messageToLobbyTextField selectText:self];
	[[_lobbyChatTextView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	
	[_gameListDrawer setPreferredEdge:NSMaxXEdge];
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
	[_gameListMatrix setEnabled:NO];
	[(AQAcquireController *)_acquireController joinGame:[sender tag]];
}

- (void)leftGame:(id)sender;
{
	[_gameListMatrix setEnabled:YES];
}


- (void)incomingLobbyMessage:(NSString *)lobbyMessage;
{
	if ([[_lobbyChatTextView textStorage] length] > 0)
		[[_lobbyChatTextView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];

	NSAttributedString *attributedLobbyMessage = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", lobbyMessage]] autorelease];
	[[_lobbyChatTextView textStorage] appendAttributedString:attributedLobbyMessage];
	
	// Scroll to bottom found in Cocoa docs
	// http://developer.apple.com/documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/Scrolling.html
	NSPoint newScrollOrigin;

    if ([[_lobbyChatScrollView documentView] isFlipped]) {
        newScrollOrigin = NSMakePoint(0.0,NSHeight([[_lobbyChatScrollView documentView] frame]) - NSHeight([[_lobbyChatScrollView contentView] bounds]));
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
- (void)_gameListMatrixSetEnabled:(BOOL)flag;
{
	int i;
	for (i = 1; i < [_gameListMatrix numberOfRows]; ++i)
		[[_gameListMatrix cellAtRow:i column:0] setEnabled:flag];
}

- (void)_populateGameListDrawerWithGames:(NSArray *)games;
{
	NSTextFieldCell *gameListTitle = [[[NSTextFieldCell alloc] init] autorelease];
	if ([games count] == 0)
		[gameListTitle setStringValue:NSLocalizedStringFromTable(@"No games", @"Acquire", @"Says there are 'no games'.")];
	else
		[gameListTitle setStringValue:[NSString stringWithFormat:@"%@:", NSLocalizedStringFromTable(@"Game List", @"Acquire", @"The words 'game list'")]];
	[gameListTitle setEnabled:NO];
	NSButtonCell *prototype = [[[NSButtonCell alloc] init] autorelease];
	[prototype setTarget:self];
	[prototype setAction:@selector(joinGame:)];
	
	[_gameListMatrix setPrototype:prototype];
	[_gameListMatrix setAllowsEmptySelection:NO];
	[_gameListMatrix setIntercellSpacing:NSMakeSize(4.0f, 2.0f)];
	[_gameListMatrix setCellSize:NSMakeSize(80.0f, 18.0f)];
	[_gameListMatrix setMode:NSRadioModeMatrix];
	
	[_gameListMatrix renewRows:([games count] + 1) columns:1];
	
	[_gameListMatrix putCell:gameListTitle atRow:0 column:0];
	int i;
	for (i = 0; i < [games count]; ++i) {
		[[_gameListMatrix cellAtRow:(i + 1) column:0] setTitle:[NSString stringWithFormat:@"%@%@", NSLocalizedStringFromTable(@"Game #", @"Acquire", @"The words 'game number', with a symbol for the word 'number' if possible."), [games objectAtIndex:i]]];
		[[_gameListMatrix cellAtRow:(i + 1) column:0] setTag:[[games objectAtIndex:i] intValue]];
	}
	
	[_gameListMatrix sizeToCells];
}
@end

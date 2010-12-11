#import "AQLobbyWindowController.h"
#import "AQAcquireController.h"

@interface AQLobbyWindowController (Private)
- (void)_populateGameListDrawerWithGames:(NSArray *)games;
@end

@implementation AQLobbyWindowController
- (id)initWithAcquireController:(id)acquireController;
{
	if (![super init])
		return nil;
	
	_acquireController = [acquireController retain];
	
	if (!_lobbyWindow) {
		if (![NSBundle loadNibNamed:@"LobbyWindow" owner:self]) {
			NSLog(@"%@ failed to load LobbyWindow.nib", NSStringFromSelector(_cmd));
			return nil;
		}
		
		[_messageToLobbyTextField setTarget:self];
		[_messageToLobbyTextField setAction:@selector(sendLobbyMessage:)];
	}
	
	[_messageToLobbyTextField selectText:self];
	[[_lobbyChatTextView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
	
	[_gameListDrawer setPreferredEdge:NSMaxXEdge];
	
	_gameListUpdateTimer = nil;
	[self beginScheduledGameListUpdates];

	return self;
}

- (void)dealloc;
{
	[_gameListUpdateTimer invalidate];
	[_gameListUpdateTimer release];
	_gameListUpdateTimer = nil;
	[_lobbyWindow release];
	_lobbyWindow = nil;
	[_acquireController release];
	_acquireController = nil;
	
	[super dealloc];
}


// NSObject (NSNibAwakening)
- (void)awakeFromNib;
{
	NSButtonCell *newGameButton = [[[NSButtonCell alloc] init] autorelease];
	[newGameButton setTarget:_acquireController];
	[newGameButton setAction:@selector(createGame:)];
	[newGameButton setTitle:NSLocalizedStringFromTable(@"Create Game", @"Acquire", @"The text 'create game' on the topmost button on the games drawer in the lobby window.")];
	[_gameListMatrix putCell:newGameButton atRow:0 column: 0];
	[_gameListMatrix putCell:[[[NSCell alloc] init] autorelease] atRow:1 column:0];
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
	int desiredGameNumber = [sender tag];
	if (sender == _gameListMatrix)
		desiredGameNumber = [[_gameListMatrix selectedCell] tag];
	
	[_gameListMatrix setEnabled:NO];
	[(AQAcquireController *)_acquireController joinGame:desiredGameNumber];
}

- (void)leftGame;
{
	[_gameListMatrix setEnabled:YES];
}


- (void)incomingLobbyMessage:(NSString *)lobbyMessage;
{
	if ([[_lobbyChatTextView textStorage] length] > 0)
		[[_lobbyChatTextView textStorage] appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];

	NSAttributedString *attributedLobbyMessage = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", lobbyMessage]] autorelease];
	[[_lobbyChatTextView textStorage] appendAttributedString:attributedLobbyMessage];
	
	[_lobbyChatTextView scrollRangeToVisible:NSMakeRange([[_lobbyChatTextView string] length], 0)];
}

- (void)requestGameListUpdate:(NSTimer *)theTimer;
{
	[_acquireController updateGameListFor:self];
}

- (void)beginScheduledGameListUpdates;
{
	if (_gameListUpdateTimer != nil)
		return;
	
	_gameListUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(requestGameListUpdate:) userInfo:nil repeats:YES] retain];
}

- (void)invalidateGameListUpdateTimer;
{
	[_gameListUpdateTimer invalidate];
	[_gameListUpdateTimer release];
	_gameListUpdateTimer = nil;
}

- (void)updatedGameList:(NSArray *)gameList;
{
	[self _populateGameListDrawerWithGames:gameList];
	[_gameListDrawer open];
}

- (void)updateWindowTitle;
{
	if (!_lobbyWindow)
		return;
	
	[_lobbyWindow setTitle:[NSString stringWithFormat:@"Acquire – %@ – %@", NSLocalizedStringFromTable(@"Lobby", @"Acquire", @"The word 'lobby'."), [_acquireController connectedHostOrIPAddress]]];
}

- (void)resetLobbyMessages;
{
	[[_lobbyChatTextView textStorage] setAttributedString:[[[NSAttributedString alloc] initWithString:@""] autorelease]];
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
	NSButtonCell *newGameButton = [[[NSButtonCell alloc] init] autorelease];
	[newGameButton setTarget:_acquireController];
	[newGameButton setAction:@selector(createGame:)];
	[newGameButton setTitle:NSLocalizedStringFromTable(@"Create Game", @"Acquire", @"The text 'create game' on the topmost button on the games drawer in the lobby window.")];
	
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
	[_gameListMatrix setCellSize:NSMakeSize(100.0f, 18.0f)];
	[_gameListMatrix setMode:NSRadioModeMatrix];
	
	[_gameListMatrix renewRows:([games count] + 3) columns:1];
	
	[_gameListMatrix putCell:newGameButton atRow:0 column: 0];
	[_gameListMatrix putCell:[[[NSCell alloc] init] autorelease] atRow:1 column:0];
	[_gameListMatrix putCell:gameListTitle atRow:2 column:0];
	int i;
	for (i = 0; i < [games count]; ++i) {
		[[_gameListMatrix cellAtRow:(i + 3) column:0] setTitle:[NSString stringWithFormat:@"%@%@", NSLocalizedStringFromTable(@"Game #", @"Acquire", @"The words 'game number', with a symbol for the word 'number' if possible."), [games objectAtIndex:i]]];
		[[_gameListMatrix cellAtRow:(i + 3) column:0] setTag:[[games objectAtIndex:i] intValue]];
	}
	
	[_gameListMatrix sizeToCells];
}
@end

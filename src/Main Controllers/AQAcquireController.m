// AQAcquireController.m
//
// Created May 26, 2008 by nwaite

#import "AQAcquireController.h"

@interface AQAcquireController (Private)
- (void)_updateMenuItemTargetsAndActions;
@end

@implementation AQAcquireController
- (id)init;
{
	if (![super init])
		return nil;
	
	_localPlayerName = nil;
	
	_gameArrayController = [[AQGameArrayController alloc] init];
	_connectionArrayController = [[AQConnectionArrayController alloc] init];
	
	_preferencesWindowController = nil;
	_welcomeWindowController = [[AQWelcomeWindowController alloc] initWithAcquireController:self];
	_lobbyWindowController = [[AQLobbyWindowController alloc] initWithAcquireController:self];

	return self;
}

- (void)dealloc;
{
	[_gameArrayController release];
	_gameArrayController = nil;
	[_connectionArrayController release];
	_connectionArrayController = nil;
	[_welcomeWindowController release];
	_welcomeWindowController = nil;
	
	[super dealloc];
}


// Accessors
- (NSString *)localPlayerName;
{
	return _localPlayerName;
}


// NSObject (NSNibAwakening)
- (void)awakeFromNib;
{
	[self _updateMenuItemTargetsAndActions];
	[_welcomeWindowController bringWelcomeWindowToFront:nil];
}


// NSObject (NSMenuValidation)
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
{
	if ([[menuItem title] isEqualToString:@"Show Lobby Window"])
		return ([_connectionArrayController serverConnection] != nil && [[_connectionArrayController serverConnection] isConnected]);
	
	if ([[menuItem title] isEqualToString:@"Disconnect From Server"])
		return ([_connectionArrayController serverConnection] != nil && [[_connectionArrayController serverConnection] isConnected]);
	
	if ([[menuItem title] isEqualToString:@"Leave Game"] || [[menuItem title] isEqualToString:@"End Game"])
		return ([_gameArrayController activeGame] != nil);
	
	if ([menuItem action] == @selector(showPreferencesWindow:))
		return YES;
	
	return NO;
}


// Start games
- (void)connectToServer:(NSString *)hostOrIPAddress port:(int)port withLocalDisplayName:(NSString *)localDisplayName sender:(id)sender;
{
	[_connectionArrayController connectToServer:hostOrIPAddress port:port for:self];
	_localPlayerName = [localDisplayName copy];
}

- (void)connectedToServer;
{
	[_welcomeWindowController saveNetworkGameDefaults];
	[_welcomeWindowController closeWelcomeWindow];
	[_welcomeWindowController release];
	_welcomeWindowController = nil;
	[[_connectionArrayController serverConnection] registerAssociatedObject:_lobbyWindowController];
	[_lobbyWindowController resetLobbyMessages];
	[_lobbyWindowController updateWindowTitle];
	[self updateGameListFor:_lobbyWindowController];
	[_lobbyWindowController bringLobbyWindowToFront];
}

- (void)cancelConnectingToServer;
{
	[_connectionArrayController closeConnection:[_connectionArrayController serverConnection]];
	[_welcomeWindowController stopConnectingToAServer];
}

- (void)joinGame:(int)gameNumber;
{
	[[_connectionArrayController serverConnection] joinGame:gameNumber];
}

- (void)joiningGame;
{
	[_lobbyWindowController invalidateGameListUpdateTimer];
	[_gameArrayController startNewNetworkGameAndMakeActiveWithAssociatedConnection:[_connectionArrayController serverConnection]];
	[[_connectionArrayController serverConnection] registerAssociatedObjectAndPrioritize:[_gameArrayController activeGame]];
	[[_gameArrayController activeGame] setLocalPlayerName:_localPlayerName];
	[[_gameArrayController activeGame] loadGameWindow];
	[[_gameArrayController activeGame] bringGameWindowToFront];
}

- (void)leaveGame;
{
	[[_connectionArrayController serverConnection] deregisterAssociatedObject:[_gameArrayController activeGame]];
	[[_connectionArrayController serverConnection] leaveGame];
	[_gameArrayController removeGame:[_gameArrayController activeGame]];
	
	if (_lobbyWindowController == nil)
		_lobbyWindowController = [[AQLobbyWindowController alloc] initWithAcquireController:self];
	else
		[_lobbyWindowController leftGame];

	[_lobbyWindowController bringLobbyWindowToFront];
}

- (void)disconnectFromServer;
{
	[[_connectionArrayController serverConnection] disconnectFromServer];
	if (_gameArrayController != nil)
		[_gameArrayController removeGame:[_gameArrayController activeGame]];
	
	[_lobbyWindowController closeLobbyWindow];
	[_lobbyWindowController release];
	_lobbyWindowController = nil;
	
	if (_welcomeWindowController == nil)
		_welcomeWindowController = [[AQWelcomeWindowController alloc] initWithAcquireController:self];
	
	[_welcomeWindowController bringWelcomeWindowToFront:nil];
}

- (void)connection:(AQConnectionController *)connection willDisconnectWithError:(NSError *)err;
{
	if ([connection isServerConnection])
		[_welcomeWindowController networkGameConnectionFailed];
}

- (void)startNewLocalGameWithPlayersNamed:(NSArray *)playerNames;
{
	[_welcomeWindowController saveLocalGameDefaults];
	[_welcomeWindowController closeWelcomeWindow];
	
	[_gameArrayController startNewLocalGameAndMakeActive];
	[[_gameArrayController activeGame] loadGameWindow];
	[[_gameArrayController activeGame] bringGameWindowToFront];
	
	NSEnumerator *playerNameEnumerator = [playerNames objectEnumerator];
	id curPlayerName;
	while (curPlayerName = [playerNameEnumerator nextObject])
		[[_gameArrayController activeGame] addPlayerNamed:curPlayerName];
	
	[[_gameArrayController activeGame] startGame];
	
	[[NSNotificationCenter defaultCenter] addObserver:_welcomeWindowController selector:@selector(bringWelcomeWindowToFront:) name:@"LocalGameWindowClosed" object:nil];
}


// Passthrus
/*
- (void)incomingLobbyMessage:(NSString *)lobbyMessage;
{
	[_lobbyWindowController incomingLobbyMessage:lobbyMessage];
}

- (void)outgoingLobbyMessage:(NSString *)lobbyMessage;
{
	[[_connectionArrayController serverConnection] outgoingLobbyMessage:lobbyMessage];
}

- (void)incomingGameMessage:(NSString *)gameMessage;
{
	[[_gameArrayController activeGame] incomingGameMessage:gameMessage];
}
*/
- (void)updateGameListFor:(id)anObject;
{
	[[_connectionArrayController serverConnection] updateGameListFor:anObject];
}

- (void)showLobbyWindow;
{
	[_lobbyWindowController bringLobbyWindowToFront];
}

- (NSString *)connectedHostOrIPAddress;
{
	return [[_connectionArrayController serverConnection] connectedHostOrIPAddress];
}

- (void)displayNameAlreadyInUse;
{
	[_welcomeWindowController displayNameAlreadyInUse];
}

- (IBAction)showPreferencesWindow:(id)sender;
{
	if (_preferencesWindowController == nil)
		_preferencesWindowController = [[AQPreferencesWindowController alloc] init];
	[_preferencesWindowController openPreferencesWindowAndBringToFront];
}
/*
- (void)boardTileAtNetacquireID:(int)netacquireID isNetacquireChainID:(int)netacquireChainID;
{
	if ([_gameArrayController activeGame] == nil)
		return;
	
	[[_gameArrayController activeGame] boardTileAtNetacquireID:netacquireID isNetacquireChainID:netacquireChainID];
}

- (void)rackTileAtIndex:(int)index isNetacquireID:(int)netacquireID netacquireChainID:(int)netacquireChainID;
{
	if ([_gameArrayController activeGame] == nil)
		return;
	
	[[_gameArrayController activeGame] rackTileAtIndex:index isNetacquireID:netacquireID netacquireChainID:netacquireChainID];
}

- (void)playerAtIndex:(int)playerIndex isNamed:(NSString *)name;
{
	[[_gameArrayController activeGame] playerAtIndex:playerIndex isNamed:name];
}
*/
@end

@implementation AQAcquireController (Private)
- (void)_updateMenuItemTargetsAndActions;
{
	NSMenu *serverMenu = [[[NSApp mainMenu] itemWithTitle:@"Server"] submenu];
	NSMenu *gameMenu = [[[NSApp mainMenu] itemWithTitle:@"Game"] submenu];
	
	[[serverMenu itemWithTitle:@"Show Lobby Window"] setTarget:self];
	[[serverMenu itemWithTitle:@"Show Lobby Window"] setAction:@selector(showLobbyWindow)];
	[[serverMenu itemWithTitle:@"Disconnect From Server"] setTarget:self];
	[[serverMenu itemWithTitle:@"Disconnect From Server"] setAction:@selector(disconnectFromServer)];
	[[gameMenu itemWithTitle:@"Leave Game"] setTarget:self];
	[[gameMenu itemWithTitle:@"Leave Game"] setAction:@selector(leaveGame)];
}
@end

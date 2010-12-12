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
	_lobbyWindowController = nil;

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
	
	if ([menuItem action] == @selector(disconnectFromServer))
		return ([_connectionArrayController serverConnection] != nil && [[_connectionArrayController serverConnection] isConnected]);
	
	if ([[menuItem title] isEqualToString:@"Leave Game"] || [[menuItem title] isEqualToString:@"End Game"])
		return ([_gameArrayController activeGame] != nil);
	
	if ([menuItem action] == @selector(showPreferencesWindow:))
		return YES;
	
	if ([menuItem action] == @selector(showActiveGameWindow) && [_gameArrayController activeGame] != nil)
		return YES;
	
	if ([menuItem action] == @selector(startActiveGame))
		return [[_gameArrayController activeGame] isReadyToStart];
	
	return NO;
}


// Start games
- (void)connectToServer:(NSString *)hostOrIPAddress port:(int)port withLocalDisplayName:(NSString *)localDisplayName sender:(id)sender;
{
	[_connectionArrayController connectToServer:hostOrIPAddress port:port for:self];
	[[_connectionArrayController serverConnection] registerAssociatedObject:self];
	_localPlayerName = [localDisplayName copy];
}

- (void)connectedToServer;
{
	[_welcomeWindowController saveNetworkGameDefaults];
	[_welcomeWindowController closeWelcomeWindow];
	[_welcomeWindowController release];
	_welcomeWindowController = nil;
	if (_lobbyWindowController == nil)
		_lobbyWindowController = [[AQLobbyWindowController alloc] initWithAcquireController:self];
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

- (void)joiningGame:(BOOL)createdGame;
{
	[_gameArrayController startNewNetworkGameAndMakeActiveWithAssociatedConnection:[_connectionArrayController serverConnection]];
	id activeGame = [_gameArrayController activeGame];
	[[_connectionArrayController serverConnection] registerAssociatedObjectAndPrioritize:activeGame];
	[activeGame setLocalPlayerName:_localPlayerName];
	if (createdGame)
		[activeGame setIsReadyToStart:YES];
	[activeGame loadGameWindow];
	[activeGame bringGameWindowToFront];
}

- (void)canStartActiveGame
{
  [[_gameArrayController activeGame] setIsReadyToStart:YES];
  [[NSApp mainMenu] update];
}

- (void)createGame:(id)sender;
{
	[[_connectionArrayController serverConnection] createGame];
}

- (void)startActiveGame;
{
	[[_connectionArrayController serverConnection] startActiveGame];
	[[_gameArrayController activeGame] setIsReadyToStart:NO];
}

- (void)leaveGame;
{
	if ([[_gameArrayController activeGame] isLocalGame]) {
		[[_gameArrayController activeGame] closeGameWindow];
		[_gameArrayController removeGame:[_gameArrayController activeGame]];
		if (_welcomeWindowController == nil)
			_welcomeWindowController = [[AQWelcomeWindowController alloc] initWithAcquireController:self];
		[_welcomeWindowController bringWelcomeWindowToFront:nil];
		
		return;
	}
	
	[[_gameArrayController activeGame] closeGameWindow];
	[[_connectionArrayController serverConnection] deregisterAssociatedObject:[_gameArrayController activeGame]];
	[[_connectionArrayController serverConnection] leaveGame];
	
	if (_lobbyWindowController == nil)
		_lobbyWindowController = [[AQLobbyWindowController alloc] initWithAcquireController:self];
	else
		[_lobbyWindowController leftGame];

	[_lobbyWindowController bringLobbyWindowToFront];
}

- (void)disconnectFromServer;
{
	[[_connectionArrayController serverConnection] disconnectFromServer];
}

- (void)disconnectedFromServer:(BOOL)connectionWasLost;
{
	if (_gameArrayController != nil) {
		[[_gameArrayController activeGame] closeGameWindow];
		[_gameArrayController removeGame:[_gameArrayController activeGame]];
	}
	
	[_lobbyWindowController closeLobbyWindow];
	[_lobbyWindowController release];
	_lobbyWindowController = nil;
	
	if (_welcomeWindowController == nil)
		_welcomeWindowController = [[AQWelcomeWindowController alloc] initWithAcquireController:self];
	
	[_welcomeWindowController bringWelcomeWindowToFront:nil];
	if (connectionWasLost)
		[_welcomeWindowController lostServerConnection];
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
}


// Passthrus
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

- (void)showActiveGameWindow;
{
	if ([_gameArrayController activeGame] == nil)
		return;
	
	[[_gameArrayController activeGame] bringGameWindowToFront];
}

- (void)outgoingLobbyMessage:(NSString *)message;
{
	[[_connectionArrayController serverConnection] outgoingLobbyMessage:message];
}
@end

@implementation AQAcquireController (Private)
- (void)_updateMenuItemTargetsAndActions;
{
	NSMenu *serverMenu = [[[NSApp mainMenu] itemWithTitle:@"Server"] submenu];
	NSMenu *gameMenu = [[[NSApp mainMenu] itemWithTitle:@"Game"] submenu];
	
  NSMenuItem *showLobbyWindow = [serverMenu itemWithTitle:@"Show Lobby Window"];
	[showLobbyWindow setTarget:self];
	[showLobbyWindow setAction:@selector(showLobbyWindow)];
  NSMenuItem *disconnect = [serverMenu itemWithTitle:@"Disconnect From Server"];
	[disconnect setTarget:self];
	[disconnect setAction:@selector(disconnectFromServer)];
  NSMenuItem *showGameWindow = [gameMenu itemWithTitle:@"Show Game Window"];
	[showGameWindow setTarget:self];
	[showGameWindow setAction:@selector(showActiveGameWindow)];
  NSMenuItem *startGame = [gameMenu itemWithTitle:@"Start Game"];
	[startGame setTarget:self];
	[startGame setAction:@selector(startActiveGame)];
  NSMenuItem *leaveGame = [gameMenu itemWithTitle:@"Leave Game"];
	[leaveGame setTarget:self];
	[leaveGame setAction:@selector(leaveGame)];
}
@end

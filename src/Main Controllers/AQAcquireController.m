// AQAcquireController.m
//
// Created May 26, 2008 by nwaite

#import "AQAcquireController.h"

@interface AQAcquireController (Private)
- (void)_setMenuItemTargetsAndActions;

// Nib loaders
- (void)_loadWelcomeWindow;
- (void)_loadLobbyWindow;
@end

@implementation AQAcquireController
- (id)init;
{
	if (![super init])
		return nil;
	
	_localPlayerName = nil;
	
	_gameArrayController = [[AQGameArrayController alloc] init];
	_connectionArrayController = [[AQConnectionArrayController alloc] init];
	
	_welcomeWindowController = nil;
	_lobbyWindowController = nil;

	return self;
}

- (void)dealloc;
{
	[_gameArrayController release];
	_gameArrayController = nil;
	[_connectionArrayController release];
	_connectionArrayController = nil;
	
	// WelcomeWindowController came from a nib. It releases the WelcomeWindow in its dealloc, and there are no other top level objects in the nib, so we're good to go for memory management.
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
	[self _setMenuItemTargetsAndActions];
	[self _loadWelcomeWindow];
	[_welcomeWindowController bringWelcomeWindowToFront];
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
	[self _loadLobbyWindow];
	[_welcomeWindowController saveNetworkGameDefaults];
	[_welcomeWindowController closeWelcomeWindow];
	[_welcomeWindowController release];
	_welcomeWindowController = nil;
	[_lobbyWindowController bringLobbyWindowToFront];
	[self updateGameListFor:_lobbyWindowController];
}

- (void)cancelConnectingToServer;
{
	NSLog(@"%s", _cmd);
	[_connectionArrayController closeConnection:[_connectionArrayController serverConnection]];
	[_welcomeWindowController stopConnectingToAServer];
}

- (void)joinGame:(int)gameNumber;
{
	NSLog(@"AcquireController %s called", _cmd);
	[[_connectionArrayController serverConnection] joinGame:gameNumber];
}

- (void)joiningGame;
{
	NSLog(@"AcquireController %s called", _cmd);
	[_gameArrayController startNewNetworkGameAndMakeActiveWithAssociatedConnection:[_connectionArrayController serverConnection]];
	[[_gameArrayController activeGame] setLocalPlayerName:_localPlayerName];
	[[_gameArrayController activeGame] loadGameWindow];
	[[_gameArrayController activeGame] bringGameWindowToFront];
}

- (void)leaveGame;
{
	[[_connectionArrayController serverConnection] leaveGame];
	[[_gameArrayController activeGame] endGame];
	
	if (_lobbyWindowController == nil)
		[self _loadLobbyWindow];
	else
		[_lobbyWindowController leftGame];

	[_lobbyWindowController bringLobbyWindowToFront];
}

- (void)disconnectFromServer;
{
	[[_connectionArrayController serverConnection] disconnectFromServer];
	if (_gameArrayController != nil)
		[[_gameArrayController activeGame] endGame];
	
	[_lobbyWindowController closeLobbyWindow];
	[_lobbyWindowController release];
	_lobbyWindowController = nil;
	
	if (_welcomeWindowController == nil)
		[self _loadWelcomeWindow];
	
	[_welcomeWindowController bringWelcomeWindowToFront];
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
	[_welcomeWindowController release];
	_welcomeWindowController = nil;
	
	[_gameArrayController startNewLocalGameAndMakeActive];
	[[_gameArrayController activeGame] loadGameWindow];
	[[_gameArrayController activeGame] bringGameWindowToFront];
}


// Passthrus
- (void)incomingLobbyMessage:(NSString *)lobbyMessage;
{
	[_lobbyWindowController incomingLobbyMessage:lobbyMessage];
}

- (void)outgoingLobbyMessage:(NSString *)lobbyMessage;
{
	[[_connectionArrayController serverConnection] outgoingLobbyMessage:lobbyMessage];
}

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


// Allow objects in loaded nibs to say hi
- (void)registerWelcomeWindowController:(AQWelcomeWindowController *)welcomeWindowController;
{
	if (_welcomeWindowController != nil) {
		NSLog(@"%s another WelcomeWindowController is already registered", _cmd);
		return;
	}
	
	_welcomeWindowController = welcomeWindowController;
}

- (void)registerLobbyWindowController:(AQLobbyWindowController *)lobbyWindowController;
{
	if (_lobbyWindowController != nil) {
		NSLog(@"%s another LobbyWindowController is already registered", _cmd);
		return;
	}
	
	_lobbyWindowController = lobbyWindowController;
}
@end

@implementation AQAcquireController (Private)
- (void)_setMenuItemTargetsAndActions;
{
	[[[[[NSApp mainMenu] itemWithTitle:@"Server"] submenu] itemWithTitle:@"Show Lobby Window"] setTarget:self];
	[[[[[NSApp mainMenu] itemWithTitle:@"Server"] submenu] itemWithTitle:@"Show Lobby Window"] setAction:@selector(showLobbyWindow:)];
	[[[[[NSApp mainMenu] itemWithTitle:@"Server"] submenu] itemWithTitle:@"Disconnect From Server"] setTarget:self];
	[[[[[NSApp mainMenu] itemWithTitle:@"Server"] submenu] itemWithTitle:@"Disconnect From Server"] setAction:@selector(disconnectFromServer:)];
	[[[[[NSApp mainMenu] itemWithTitle:@"Game"] submenu] itemWithTitle:@"Leave Game"] setTarget:self];
	[[[[[NSApp mainMenu] itemWithTitle:@"Game"] submenu] itemWithTitle:@"Leave Game"] setAction:@selector(leaveGame:)];
}


// Nib loaders
- (void)_loadWelcomeWindow;
{
	if (_welcomeWindowController != nil)
		return;
	
	if (![NSBundle loadNibNamed:@"WelcomeWindow" owner:self]) {
		NSLog(@"%s failed to load WelcomeWindow.nib", _cmd);
	}
}

- (void)_loadLobbyWindow;
{
	if (_lobbyWindowController != nil)
		return;
	
	if (![NSBundle loadNibNamed:@"LobbyWindow" owner:self]) {
		NSLog(@"%s failed to load LobbyWindow.nib", _cmd);
	}
}
@end

// AQAcquireController.m
//
// Created May 26, 2008 by nwaite

#import "AQAcquireController.h"
#import "AQConnectionController.h"
#import "AQGame.h"
#import "AQLobbyWindowController.h"
#import "AQWelcomeWindowController.h"


@interface AQAcquireController (Private)

- (void)_updateMenuItemTargetsAndActions;

@end

@implementation AQAcquireController

- (id)init;
{
	if (![super init])
		return nil;
	
	_welcomeWindowController = [[AQWelcomeWindowController alloc] initWithAcquireController:self];

	return self;
}

- (void)dealloc;
{
  [_localPlayerName release], _localPlayerName = nil;
  [_game release], _game = nil;
  [_connection release], _connection = nil;
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
		return [_connection isConnected];
	
	if ([menuItem action] == @selector(disconnectFromServer))
		return [_connection isConnected];
	
	if ([[menuItem title] isEqualToString:@"Leave Game"] || 
	    [[menuItem title] isEqualToString:@"End Game"])
		return (_game != nil);
	
	if ([menuItem action] == @selector(showPreferencesWindow:))
		return YES;
	
	if ([menuItem action] == @selector(showActiveGameWindow) && _game != nil)
		return YES;
	
	if ([menuItem action] == @selector(startActiveGame))
		return [_game isReadyToStart];
	
	return NO;
}


// Start games
- (void)connectToServer:(NSString*)hostOrIPAddress
                   port:(int)port
   withLocalDisplayName:(NSString*)localDisplayName
                 sender:(id)sender;
{
  if (port < 1 || port > 65535)
		return;
	if ([hostOrIPAddress length] == 0)
		return;
  [_connection autorelease];
  _connection = [[AQConnectionController alloc] initWithHost:hostOrIPAddress
                                                        port:port
                                                         for:sender];
	[_connection registerAssociatedObject:self];
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
	[_connection registerAssociatedObject:_lobbyWindowController];
	[_lobbyWindowController resetLobbyMessages];
	[_lobbyWindowController updateWindowTitle];
	[self updateGameListFor:_lobbyWindowController];
	[_lobbyWindowController bringLobbyWindowToFront];
}

- (void)cancelConnectingToServer;
{
  [_connection close];
  [_connection release], _connection = nil;
	[_welcomeWindowController stopConnectingToAServer];
}

- (void)joinGame:(int)gameNumber;
{
	[_connection joinGame:gameNumber];
}

- (void)joiningGame:(BOOL)createdGame;
{
  _game = [[AQGame alloc] initWithConnection:_connection];
	[_connection registerAssociatedObjectAndPrioritize:_game];
	[_game setLocalPlayerName:_localPlayerName];
	if (createdGame)
		[_game setIsReadyToStart:YES];
	[_game loadGameWindow];
	[_game bringGameWindowToFront];
}

- (void)canStartActiveGame
{
  [_game setIsReadyToStart:YES];
  [[NSApp mainMenu] update];
}

- (void)createGame:(id)sender;
{
	[_connection createGame];
}

- (void)startActiveGame;
{
	[_connection startActiveGame];
	[_game setIsReadyToStart:NO];
}

- (void)leaveGame;
{	
	[_game closeGameWindow];
	[_connection deregisterAssociatedObject:_game];
	[_connection leaveGame];
	
	if (_lobbyWindowController == nil)
		_lobbyWindowController = [[AQLobbyWindowController alloc] initWithAcquireController:self];
	else
		[_lobbyWindowController leftGame];

	[_lobbyWindowController bringLobbyWindowToFront];
}

- (void)disconnectFromServer;
{
	[_connection disconnectFromServer];
}

- (void)disconnectedFromServer:(BOOL)connectionWasLost;
{
	[_game closeGameWindow];
	
	[_lobbyWindowController closeLobbyWindow];
	[_lobbyWindowController release];
	_lobbyWindowController = nil;
	
	if (_welcomeWindowController == nil)
		_welcomeWindowController = [[AQWelcomeWindowController alloc] initWithAcquireController:self];
	
	[_welcomeWindowController bringWelcomeWindowToFront:nil];
	if (connectionWasLost)
		[_welcomeWindowController lostServerConnection];
}

- (void)connection:(AQConnectionController *)connection 
  willDisconnectWithError:(NSError *)err;
{
  if ([_connection isEqual:connection])
		[_welcomeWindowController gameConnectionFailed];
}


// Passthrus
- (void)updateGameListFor:(id)anObject;
{
	[_connection updateGameListFor:anObject];
}

- (void)showLobbyWindow;
{
	[_lobbyWindowController bringLobbyWindowToFront];
}

- (NSString *)connectedHostOrIPAddress;
{
	return [_connection connectedHostOrIPAddress];
}

- (void)displayNameAlreadyInUse;
{
	[_welcomeWindowController displayNameAlreadyInUse];
}

- (void)showActiveGameWindow;
{
	[_game bringGameWindowToFront];
}

- (void)outgoingLobbyMessage:(NSString *)message;
{
	[_connection outgoingLobbyMessage:message];
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

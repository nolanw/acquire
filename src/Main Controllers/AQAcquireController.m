// AQAcquireController.m
//
// Created May 26, 2008 by nwaite

#import "AQAcquireController.h"

@interface AQAcquireController (Private)
// Nib loaders
- (void)_loadWelcomeWindow;
- (void)_loadLobbyWindow;
@end

@implementation AQAcquireController
- (id)init;
{
	if (![super init])
		return nil;
	
	_localPlayersName = nil;
	
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
- (NSString *)localPlayersName;
{
	return _localPlayersName;
}


// NSObject (NSNibAwakening)
- (void)awakeFromNib;
{
	[self _loadWelcomeWindow];
	[_welcomeWindowController bringWelcomeWindowToFront];
}


// Start games
- (void)connectToServer:(NSString *)hostOrIPAddress port:(int)port withLocalDisplayName:(NSString *)localDisplayName sender:(id)sender;
{
	[_connectionArrayController connectToServer:hostOrIPAddress port:port for:self];
	_localPlayersName = [localDisplayName copy];
}

- (void)connectedToServer;
{
	[self _loadLobbyWindow];
	[_welcomeWindowController release];
	_welcomeWindowController = nil;
	[_lobbyWindowController bringLobbyWindowToFront];
}

- (void)cancelConnectingToServer;
{
	[_connectionArrayController closeConnection:[_connectionArrayController serverConnection]];
}

- (void)connection:(AQConnectionController *)connection willDisconnectWithError:(NSError *)err;
{
	if ([connection isServerConnection])
		[_welcomeWindowController networkGameConnectionFailed];
}

- (void)startNewLocalGameWithPlayersNamed:(NSArray *)playerNames;
{
	
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

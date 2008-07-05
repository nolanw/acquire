// AQAcquireController.h
// AcquireController is loaded at application start in MainMenu.nib; it manages game controllers and the network controller, as well as the welcome window.
//
// Created May 26, 2008 by nwaite

#import "AQGameArrayController.h"
#import "AQConnectionArrayController.h"
#import "AQWelcomeWindowController.h"
#import "AQLobbyWindowController.h"

@interface AQAcquireController : NSObject
{
	NSString *_localPlayersName;

	AQGameArrayController 		*_gameArrayController;
	AQConnectionArrayController	*_connectionArrayController;
	AQLobbyWindowController		*_lobbyWindowController;
	AQWelcomeWindowController	*_welcomeWindowController;
}

- (id)init;
- (void)dealloc;

// Accessors
- (NSString *)localPlayersName;

// NSObject (NSNibAwakening)
- (void)awakeFromNib;

// NSObject (NSMenuValidation)
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

// Start games
- (void)connectToServer:(NSString *)hostOrIPAddress port:(int)port withLocalDisplayName:(NSString *)localDisplayName sender:(id)sender;
- (void)connectedToServer;
- (void)cancelConnectingToServer;
- (void)leaveGame:(id)sender;
- (void)disconnectFromServer:(id)sender;
- (void)connection:(AQConnectionController *)connection willDisconnectWithError:(NSError *)err;
- (void)startNewLocalGameWithPlayersNamed:(NSArray *)playerNames;

// Passthrus
- (void)incomingLobbyMessage:(NSString *)lobbyMessage;
- (void)outgoingLobbyMessage:(NSString *)lobbyMessage;
- (void)updateGameListFor:(id)anObject;
- (void)showLobbyWindow:(id)sender;

// Allow objects in loaded nibs to say hi
- (void)registerWelcomeWindowController:(AQWelcomeWindowController *)welcomeWindowController;
- (void)registerLobbyWindowController:(AQLobbyWindowController *)lobbyWindowController;
@end

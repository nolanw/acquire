// AQAcquireController.h
// AcquireController is loaded at application start in MainMenu.nib; it manages game controllers and the network controller, as well as the welcome window.
//
// Created May 26, 2008 by nwaite

#import "AQGameArrayController.h"
#import "AQConnectionArrayController.h"
#import "AQWelcomeWindowController.h"
#import "AQLobbyWindowController.h"
#import "AQPreferencesWindowController.h"

@interface AQAcquireController : NSObject
{
	AQGameArrayController 			*_gameArrayController;
	AQConnectionArrayController		*_connectionArrayController;
	AQLobbyWindowController			*_lobbyWindowController;
	AQPreferencesWindowController	*_preferencesWindowController;
	AQWelcomeWindowController		*_welcomeWindowController;
	
	NSString *_localPlayerName;
}

- (id)init;
- (void)dealloc;

// Accessors
- (NSString *)localPlayerName;

// NSObject (NSNibAwakening)
- (void)awakeFromNib;

// NSObject (NSMenuValidation)
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

// Start games
- (void)connectToServer:(NSString*)hostOrIPAddress
                   port:(int)port
   withLocalDisplayName:(NSString*)localDisplayName
                 sender:(id)sender;
- (void)connectedToServer;
- (void)cancelConnectingToServer;
- (void)joinGame:(int)gameNumber;
- (void)joiningGame:(BOOL)createdGame;
- (void)canStartActiveGame;
- (void)createGame:(id)sender;
- (void)startActiveGame;
- (void)leaveGame;
- (void)disconnectFromServer;
- (void)disconnectedFromServer:(BOOL)connectionWasLost;
- (void)connection:(AQConnectionController *)connection 
  willDisconnectWithError:(NSError *)err;

// Passthrus
- (void)updateGameListFor:(id)anObject;
- (void)showLobbyWindow;
- (NSString *)connectedHostOrIPAddress;
- (IBAction)showPreferencesWindow:(id)sender;
- (void)showActiveGameWindow;
- (void)outgoingLobbyMessage:(NSString *)message;
@end

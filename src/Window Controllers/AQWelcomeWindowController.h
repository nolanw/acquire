// AQWelcomeWindowController.h
// WelcomeWindowController handles the welcome window, used to start local or online games of Acquire and to enter relevant settings (player name, host, etc.)
//
// Created May 26, 2008 by nwaite

@interface AQWelcomeWindowController : NSObject
{
	id	_acquireController;
	
	IBOutlet NSWindow	*_welcomeWindow;
	IBOutlet NSTabView 	*_gameTypeTabView;
	
	// Network game stuff
	IBOutlet NSTextField			*_hostOrIPAddressTextField;
	IBOutlet NSTextField			*_portTextField;
	IBOutlet NSTextField			*_displayNameTextField;
	IBOutlet NSProgressIndicator	*_networkProgressIndicator;
	IBOutlet NSButton				*_connectToServerButton;
	
	// Local game stuff
	IBOutlet NSForm			*_localPlayerNamesForm;
	IBOutlet NSTextField	*_localNumberOfPlayersTextField;
	IBOutlet NSStepper		*_localNumberOfPlayersStepper;
	IBOutlet NSButton		*_startLocalGameButton;
	
	BOOL _quitOnNextWindowClose;
	BOOL _displayNameInUseErrorShown;
}

- (id)initWithAcquireController:(id)acquireController;
- (void)dealloc;

// Accessors
- (NSString *)hostOrIPAddress;

- (void)saveNetworkGameDefaults;
- (void)saveLocalGameDefaults;

// NSTabView delegate selectors
- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem;

// Window visibility
- (void)closeWelcomeWindow;
- (void)bringWelcomeWindowToFront:(NSNotification *)notification;

// Window delegate
- (void)windowWillClose:(NSNotification *)notification;

// UI widget actions
- (IBAction)connectToServer:(id)sender;
- (void)cancelConnectingToServer:(id)sender;
- (IBAction)startLocalGame:(id)sender;
- (void)localNumberOfPlayersStepperHasChanged:(id)sender;
- (void)networkErrorAlertDismissed:(id)sender;
- (void)stopConnectingToAServer;

// Button action responses
- (void)networkGameConnectionFailed;
- (void)displayNameAlreadyInUse;
- (void)duplicateLocalPlayerNamesEntered;
- (void)lostServerConnection;
@end

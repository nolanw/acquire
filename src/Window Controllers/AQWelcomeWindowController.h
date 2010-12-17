// AQWelcomeWindowController.h
// WelcomeWindowController handles the welcome window, used to start local or online games of Acquire and to enter relevant settings (player name, host, etc.)
//
// Created May 26, 2008 by nwaite

@class AQAcquireController;


@interface AQWelcomeWindowController : NSObject
{
	AQAcquireController *_acquireController;
	
	IBOutlet NSWindow *_welcomeWindow;
	
  IBOutlet NSComboBox *_serverComboBox;
	IBOutlet NSTextField *_portTextField;
	IBOutlet NSTextField *_displayNameTextField;
	IBOutlet NSProgressIndicator *_networkProgressIndicator;
	IBOutlet NSButton *_connectToServerButton;
	
	BOOL _quitOnNextWindowClose;
	BOOL _displayNameInUseErrorShown;
	
  NSMutableArray *_recentServers;
}

- (id)initWithAcquireController:(id)acquireController;
- (void)dealloc;

// Accessors
- (NSString *)hostOrIPAddress;

- (void)saveNetworkGameDefaults;

// Window visibility
- (void)closeWelcomeWindow;
- (void)bringWelcomeWindowToFront:(NSNotification *)notification;

// Window delegate
- (void)windowWillClose:(NSNotification *)notification;

// UI widget actions
- (IBAction)separateHostAndPort:(id)sender;
- (IBAction)connectToServer:(id)sender;
- (void)cancelConnectingToServer:(id)sender;
- (void)networkErrorAlertDismissed:(id)sender;
- (void)stopConnectingToAServer;

// Button action responses
- (void)gameConnectionFailed;
- (void)displayNameAlreadyInUse;
- (void)lostServerConnection;

@end

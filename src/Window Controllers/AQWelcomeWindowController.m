// AQWelcomeWindowController.m
//
// Created May 26, 2008 by nwaite

#import "AQWelcomeWindowController.h"
#import "AQAcquireController.h"

@interface AQWelcomeWindowController (Private)

// Make sure the names and numbers given for a network game are sensible
- (NSString *)_verifyNetworkGameParameters;

// Connecting to server state changes
- (void)_startConnectingToAServer;

@end


@implementation AQWelcomeWindowController

- (id)initWithAcquireController:(id)acquireController;
{
	if (![super init])
		return nil;
	
	_acquireController = [acquireController retain];
	_quitOnNextWindowClose = YES;
	
	if (_welcomeWindow == nil) {
		if (![NSBundle loadNibNamed:@"WelcomeWindow" owner:self]) {
			NSLog(@"%@ failed to load WelcomeWindow.nib", NSStringFromSelector(_cmd));
      [self release];
			return nil;
		}
	}
	
	NSString *lastHostOrIPAddress = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastHostOrIPAddress"];
	if (lastHostOrIPAddress != nil)
		[_hostOrIPAddressTextField setStringValue:lastHostOrIPAddress];
	
	NSString *lastPort = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastPort"];
	if (lastPort != nil)
		[_portTextField setStringValue:lastPort];
	
	NSString *lastDisplayName = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastDisplayName"];
	if (lastDisplayName != nil)
		[_displayNameTextField setStringValue:lastDisplayName];
	
	return self;
}

- (void)dealloc;
{
	[_welcomeWindow close];
	[_welcomeWindow release];
	_welcomeWindow = nil;
	[_acquireController release];
	_acquireController = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}


// Accessors
- (NSString *)hostOrIPAddress;
{
	return [_hostOrIPAddressTextField stringValue];
}


- (void)saveNetworkGameDefaults;
{
	[[NSUserDefaults standardUserDefaults] setObject:[_hostOrIPAddressTextField stringValue] forKey:@"LastHostOrIPAddress"];
	[[NSUserDefaults standardUserDefaults] setObject:[_portTextField stringValue] forKey:@"LastPort"];
	[[NSUserDefaults standardUserDefaults] setObject:[_displayNameTextField stringValue] forKey:@"LastDisplayName"];
}


// Window visibility
- (void)closeWelcomeWindow;
{
	_quitOnNextWindowClose = NO;
	[_welcomeWindow close];
}

- (void)bringWelcomeWindowToFront:(NSNotification *)notification;
{
	[_welcomeWindow makeKeyAndOrderFront:self];
}


// Window delegate
- (void)windowWillClose:(NSNotification *)notification;
{
	if ([notification object] != _welcomeWindow)
		return;
	
	if (_quitOnNextWindowClose)
		[NSApp terminate:self];
	else
		_quitOnNextWindowClose = YES;
}

// UI widget actions
- (IBAction)connectToServer:(id)sender;
{
	NSString *verificationErrorString = [self _verifyNetworkGameParameters];
	if (verificationErrorString != nil) {
		NSAlert *verificationErrorAlert = [[[NSAlert alloc] init] autorelease];
		[verificationErrorAlert addButtonWithTitle:@"OK"];
		[verificationErrorAlert setMessageText:NSLocalizedStringFromTable(@"Some settings need correction.", @"Acquire", @"Error shown when settings on the welcome screen are invalid.")];
		[verificationErrorAlert setInformativeText:verificationErrorString];
		[verificationErrorAlert setAlertStyle:NSWarningAlertStyle];

		[verificationErrorAlert beginSheetModalForWindow:_welcomeWindow modalDelegate:self didEndSelector:@selector(networkErrorAlertDismissed:) contextInfo:nil];
		
		if ([verificationErrorString isEqualToString:NSLocalizedStringFromTable(@"Please enter a host or IP address.", @"Acquire", @"String asking user to enter a hostname or IP address.")])
			[_hostOrIPAddressTextField selectText:self];
		else if ([verificationErrorString isEqualToString:NSLocalizedStringFromTable(@"Please enter a port number in the range 1-65535.", @"Acquire", @"String asking user to enter a port number from 1-65535 inclusive.")])
			[_portTextField selectText:self];
		else if ([verificationErrorString isEqualToString:NSLocalizedStringFromTable(@"Please enter a display name.", @"Acquire", @"String asking user to enter a display name.")])
			[_displayNameTextField selectText:self];
		
		return;
	}
	
	_displayNameInUseErrorShown = NO;
	
	[self _startConnectingToAServer];
	
	[_acquireController connectToServer:[_hostOrIPAddressTextField stringValue]
                                 port:[_portTextField intValue]
                 withLocalDisplayName:[_displayNameTextField stringValue]
                               sender:self];
}

- (IBAction)cancelConnectingToServer:(id)sender;
{
	[_acquireController cancelConnectingToServer];
}

- (void)networkErrorAlertDismissed:(id)sender;
{
	[self stopConnectingToAServer];
}

- (void)stopConnectingToAServer;
{
	[_networkProgressIndicator setHidden:YES];
	[_hostOrIPAddressTextField setEnabled:YES];
	[_portTextField setEnabled:YES];
	[_displayNameTextField setEnabled:YES];
	[_connectToServerButton setEnabled:YES];
	[_connectToServerButton setTitle:NSLocalizedStringFromTable(@"Connect to Server", @"Acquire", @"Button text saying 'connect to server'")];
	[_connectToServerButton setAction:@selector(connectToServer:)];
}


// Button action responses
- (void)networkGameConnectionFailed;
{
	if (_displayNameInUseErrorShown)
		return;
	
	[_networkProgressIndicator stopAnimation:self];
	
	NSAlert *networkErrorAlert = [[[NSAlert alloc] init] autorelease];
	[networkErrorAlert addButtonWithTitle:@"OK"];
	[networkErrorAlert setMessageText:NSLocalizedStringFromTable(@"A network error occurred.", @"Acquire", @"Alert box title saying that a network error has occurred.")];
	[networkErrorAlert setInformativeText:NSLocalizedStringFromTable(@"Acquire couldn't connect to the server. Please double-check the host or IP address and the port you entered, then try again.", @"Acquire", @"Explain that Acquire couldn't connect to the server, and recommend checking host/IP/port info entered.")];
	[networkErrorAlert setAlertStyle:NSWarningAlertStyle];

	[networkErrorAlert beginSheetModalForWindow:_welcomeWindow modalDelegate:self didEndSelector:@selector(networkErrorAlertDismissed:) contextInfo:nil];
}

- (void)displayNameAlreadyInUse;
{
	[_networkProgressIndicator stopAnimation:self];
	
	NSAlert *duplicateDisplayNameAlert = [[[NSAlert alloc] init] autorelease];
	[duplicateDisplayNameAlert addButtonWithTitle:@"OK"];
	[duplicateDisplayNameAlert setMessageText:NSLocalizedStringFromTable(@"Display name already in use.", @"Acquire", @"Alert box title saying that the chosen display name is already in use.")];
	[duplicateDisplayNameAlert setInformativeText:NSLocalizedStringFromTable(@"The display name you chose is already in use on the server.\n\nIf you are reconnecting to a server you recently disconnected from, try connecting again. Otherwise, choose a different display name.\n\nNote that display names are not case sensitive.", @"Acquire", @"Explain that the user's chosen display name is already in use, and they need to pick a new case-insensitive one (or wait a minute if they just disconnected from the same server).")];
	[duplicateDisplayNameAlert setAlertStyle:NSWarningAlertStyle];
	
	_displayNameInUseErrorShown = YES;

	[duplicateDisplayNameAlert beginSheetModalForWindow:_welcomeWindow modalDelegate:self didEndSelector:@selector(networkErrorAlertDismissed:) contextInfo:nil];
}

- (void)duplicateLocalPlayerNamesEntered;
{
	NSAlert *duplicateLocalPlayerNamesEnteredAlert = [[[NSAlert alloc] init] autorelease];
	[duplicateLocalPlayerNamesEnteredAlert addButtonWithTitle:@"OK"];
	[duplicateLocalPlayerNamesEnteredAlert setMessageText:NSLocalizedStringFromTable(@"Every local player needs their own name.", @"Acquire", @"Alert box title saying that every local player needs their own name.")];
	[duplicateLocalPlayerNamesEnteredAlert setInformativeText:NSLocalizedStringFromTable(@"Please ensure each local player has a unique name.", @"Acquire", @"Ask to ensure each local player has a unique name.")];
	[duplicateLocalPlayerNamesEnteredAlert setAlertStyle:NSWarningAlertStyle];

	[duplicateLocalPlayerNamesEnteredAlert beginSheetModalForWindow:_welcomeWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)lostServerConnection;
{
	if (_displayNameInUseErrorShown)
		return;
	
	NSAlert *lostServerConnectionAlert = [[[NSAlert alloc] init] autorelease];
	[lostServerConnectionAlert addButtonWithTitle:@"OK"];
	[lostServerConnectionAlert setMessageText:NSLocalizedStringFromTable(@"Server connection lost", @"Acquire", @"Alert box title saying the server's connection was lost.")];
	[lostServerConnectionAlert setInformativeText:NSLocalizedStringFromTable(@"The connection to the server was unexpectedly lost. If the server's still up, any games being played should still exist. You can rejoin any game you were a part of so long as your display name doesn't change.", @"Acquire", @"Alert informative text saying the server connection was unexpectedly lost, but games will be safe if the server didn't crash, and to leave the display name unchanged in order to join a new game.")];
	[lostServerConnectionAlert setAlertStyle:NSWarningAlertStyle];
	
	[lostServerConnectionAlert beginSheetModalForWindow:_welcomeWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}
@end

@implementation AQWelcomeWindowController (Private)

// Make sure the names and numbers given for a network game are sensible
- (NSString *)_verifyNetworkGameParameters;
{
	if ([[_hostOrIPAddressTextField stringValue] length] == 0)
		return NSLocalizedStringFromTable(@"Please enter a host or IP address.", @"Acquire", @"String asking user to enter a hostname or IP address.");
	
	if ([_portTextField intValue] < 1 || [_portTextField intValue] > 65535)
		return NSLocalizedStringFromTable(@"Please enter a port number in the range 1-65535.", @"Acquire", @"String asking user to enter a port number from 1-65535 inclusive.");
	
	if ([[_displayNameTextField stringValue] length] == 0)
		return NSLocalizedStringFromTable(@"Please enter a display name.", @"Acquire", @"String asking user to enter a display name.");
	
	return nil;;
}

// Connecting to server state changes
- (void)_startConnectingToAServer;
{
	[_networkProgressIndicator startAnimation:self];
	[_networkProgressIndicator setHidden:NO];
	[_hostOrIPAddressTextField setEnabled:NO];
	[_portTextField setEnabled:NO];
	[_displayNameTextField setEnabled:NO];
	[_connectToServerButton setTitle:NSLocalizedStringFromTable(@"Cancel Connection", @"Acquire", "Button text saying 'cancel connection'.")];
	[_connectToServerButton setAction:@selector(cancelConnectingToServer:)];
}

@end
// AQWelcomeWindowController.m
//
// Created May 26, 2008 by nwaite

#import "AQWelcomeWindowController.h"
#import "AQAcquireController.h"

@interface AQWelcomeWindowController (Private)
// Sync local player names form with number of players stepper and text field
- (void)_updateLocalPlayerNamesForm;

// Make sure the names and numbers given for a network game are sensible
- (NSString *)_verifyNetworkGameParameters;

// Connecting to server state changes
- (void)_startConnectingToAServer;
@end

@implementation AQWelcomeWindowController
- (id)init;
{
	if (![super init])
		return nil;
	
	_quitOnNextWindowClose = YES;

	return self;
}

- (void)dealloc;
{
	[_welcomeWindow close];
	[_welcomeWindow release];
	_welcomeWindow = nil;
	
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
	[[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"MostRecentGameWasLocalGame"];
}

- (void)saveLocalGameDefaults;
{
	NSMutableArray *localPlayerNames = [NSMutableArray arrayWithCapacity:[_localPlayerNamesForm numberOfRows]];
	int i;
	for (i = 0; i < [_localPlayerNamesForm numberOfRows]; ++i)
		[localPlayerNames addObject:[[[_localPlayerNamesForm cellAtIndex:i] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
	[[NSUserDefaults standardUserDefaults] setObject:localPlayerNames forKey:@"LastLocalPlayerNames"];
	[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"MostRecentGameWasLocalGame"];
}


// NSObject (NSNibAwakening)
- (void)awakeFromNib;
{
	[(AQAcquireController *)_acquireController registerWelcomeWindowController:self];
	[_localNumberOfPlayersStepper setTarget:self];
	[_localNumberOfPlayersStepper setAction:@selector(localNumberOfPlayersStepperHasChanged:)];
	[self _updateLocalPlayerNamesForm];
	
	NSString *lastHostOrIPAddress = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastHostOrIPAddress"];
	if (lastHostOrIPAddress != nil)
		[_hostOrIPAddressTextField setStringValue:lastHostOrIPAddress];
	
	NSString *lastPort = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastPort"];
	if (lastPort != nil)
		[_portTextField setStringValue:lastPort];
	
	NSString *lastDisplayName = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastDisplayName"];
	if (lastDisplayName != nil)
		[_displayNameTextField setStringValue:lastDisplayName];
	
	NSArray *lastLocalPlayerNames = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastLocalPlayerNames"];
	if (lastLocalPlayerNames != nil) {
		[_localNumberOfPlayersStepper setIntValue:[lastLocalPlayerNames count]];
		[self localNumberOfPlayersStepperHasChanged:self];
		
		int i;
		for (i = 0; i < [lastLocalPlayerNames count]; ++i)
			[[_localPlayerNamesForm cellAtIndex:i] setStringValue:[lastLocalPlayerNames objectAtIndex:i]];
	}
	
	BOOL mostRecentGameWasLocalGame = [[NSUserDefaults standardUserDefaults] boolForKey:@"MostRecentGameWasLocalGame"];
	if (mostRecentGameWasLocalGame)
		[_gameTypeTabView selectTabViewItemAtIndex:1];
	else
		[_hostOrIPAddressTextField selectText:self];
}


// NSTabView delegate selectors
- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem;
{
	if (tabView != _gameTypeTabView)
		return YES;
	
	if ([_hostOrIPAddressTextField isEnabled] == NO)
		return NO;
	
	return YES;
}


// Window visibility
- (void)closeWelcomeWindow;
{
	_quitOnNextWindowClose = NO;
	[_welcomeWindow close];
}

- (void)bringWelcomeWindowToFront:(NSNotification *)notification;
{
	NSLog(@"%s called with notification=%@", _cmd, notification);
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
	
	[self _startConnectingToAServer];
	
	[_acquireController connectToServer:[_hostOrIPAddressTextField stringValue] port:[_portTextField intValue] withLocalDisplayName:[_displayNameTextField stringValue] sender:self];
}

- (IBAction)cancelConnectingToServer:(id)sender;
{
	[_acquireController cancelConnectingToServer];
}

- (IBAction)startLocalGame:(id)sender;
{
	int numberOfPlayers = [_localNumberOfPlayersTextField intValue];
	NSMutableArray *playersNames = [NSMutableArray arrayWithCapacity:numberOfPlayers];
	int i;
	for (i = 0; i < numberOfPlayers; ++i) {
		if ([playersNames containsObject:[[_localPlayerNamesForm cellAtIndex:i] stringValue]]) {
			[self duplicateLocalPlayerNamesEntered];
			return;
		}
		
		[playersNames addObject:[[[_localPlayerNamesForm cellAtIndex:i] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
	}
	
	[_acquireController startNewLocalGameWithPlayersNamed:playersNames];
}

- (void)localNumberOfPlayersStepperHasChanged:(id)sender;
{
	[_localNumberOfPlayersTextField setIntValue:[_localNumberOfPlayersStepper intValue]];
	
	[self _updateLocalPlayerNamesForm];
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
@end

@implementation AQWelcomeWindowController (Private)
// Sync local player names form with number of players stepper and text field
- (void)_updateLocalPlayerNamesForm;
{
	int rowsNeeded = [_localNumberOfPlayersStepper intValue];
	
	while ([_localPlayerNamesForm numberOfRows] > rowsNeeded)
		[_localPlayerNamesForm removeEntryAtIndex:rowsNeeded];
	
	while ([_localPlayerNamesForm numberOfRows] < rowsNeeded)
		[_localPlayerNamesForm addEntry:NSLocalizedStringFromTable(@"Player", @"Acquire", @"The word 'player'.")];
	
	int i;
	for (i = 0; i < rowsNeeded; ++i) {
		[[_localPlayerNamesForm cellAtIndex:i] setTitle:[NSString stringWithFormat:@"%@ %d", NSLocalizedStringFromTable(@"Player", @"Acquire", @"The word 'player'."), (i + 1)]];
		[[_localPlayerNamesForm cellAtIndex:i] setPlaceholderString:NSLocalizedStringFromTable(@"Enter name", @"Acquire", @"Prompt user to enter name.")];
	}
}

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
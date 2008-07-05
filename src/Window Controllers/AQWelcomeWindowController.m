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
- (void)_stopConnectingToAServer;
@end

@implementation AQWelcomeWindowController
- (id)init;
{
	if (![super init])
		return nil;

	return self;
}

- (void)dealloc;
{
	if (_welcomeWindow != nil) {
		[_welcomeWindow close];
		_welcomeWindow = nil;
	}
	
	[super dealloc];
}


// Accessors
- (NSString *)hostOrIPAddress;
{
	return [_hostOrIPAddressTextField stringValue];
}


- (void)saveDefaults:(id)sender;
{
	[[NSUserDefaults standardUserDefaults] setObject:[_hostOrIPAddressTextField stringValue] forKey:@"LastHostOrIPAddress"];
	[[NSUserDefaults standardUserDefaults] setObject:[_portTextField stringValue] forKey:@"LastPort"];
	[[NSUserDefaults standardUserDefaults] setObject:[_displayNameTextField stringValue] forKey:@"LastDisplayName"];
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
	[_welcomeWindow close];
	_welcomeWindow = nil;
}

- (void)bringWelcomeWindowToFront;
{
	[_welcomeWindow makeKeyAndOrderFront:self];
}


// UI widget actions
- (IBAction)connectToServer:(id)sender;
{
	NSString *verificationErrorString = [self _verifyNetworkGameParameters];
	if (verificationErrorString != nil) {
		NSAlert *verificationErrorAlert = [[[NSAlert alloc] init] autorelease];
		[verificationErrorAlert addButtonWithTitle:@"OK"];
		[verificationErrorAlert setMessageText:@"Some settings need correction."];
		[verificationErrorAlert setInformativeText:verificationErrorString];
		[verificationErrorAlert setAlertStyle:NSWarningAlertStyle];

		[verificationErrorAlert beginSheetModalForWindow:_welcomeWindow modalDelegate:self didEndSelector:@selector(networkErrorAlertDismissed) contextInfo:nil];
		
		if ([verificationErrorString isEqualToString:@"Please enter a host or IP address."])
			[_hostOrIPAddressTextField selectText:self];
		else if ([verificationErrorString isEqualToString:@"Please enter a port number in the range 1-65535."])
			[_portTextField selectText:self];
		else if ([verificationErrorString isEqualToString:@"Please enter a display name."])
			[_displayNameTextField selectText:self];
		
		return;
	}
	
	[self _startConnectingToAServer];
	
	[_acquireController connectToServer:[_hostOrIPAddressTextField stringValue] port:[_portTextField intValue] withLocalDisplayName:[_displayNameTextField stringValue] sender:self];
}

- (IBAction)cancelConnectingToServer:(id)sender;
{
	[_acquireController cancelConnectingToServer];
	[self _stopConnectingToAServer];
}

- (IBAction)startLocalGame:(id)sender;
{
	int numberOfPlayers = [_localNumberOfPlayersTextField intValue];
	NSMutableArray *playersNames = [NSMutableArray arrayWithCapacity:numberOfPlayers];
	int i;
	for (i = 0; i < numberOfPlayers; ++i) {
		[playersNames addObject:[[_localPlayerNamesForm cellAtIndex:i] stringValue]];
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
	[self _stopConnectingToAServer];
}


// Button action responses
- (void)networkGameConnectionFailed;
{
	[_networkProgressIndicator stopAnimation:self];
	
	NSAlert *networkErrorAlert = [[[NSAlert alloc] init] autorelease];
	[networkErrorAlert addButtonWithTitle:@"OK"];
	[networkErrorAlert setMessageText:@"A network error occurred."];
	[networkErrorAlert setInformativeText:@"Acquire couldn't connect to the server. Please double-check the host or IP address and the port you entered, then try again."];
	[networkErrorAlert setAlertStyle:NSWarningAlertStyle];

	[networkErrorAlert beginSheetModalForWindow:_welcomeWindow modalDelegate:self didEndSelector:@selector(networkErrorAlertDismissed:) contextInfo:nil];
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
		[_localPlayerNamesForm addEntry:@"Player"];
	
	int i;
	for (i = 0; i < rowsNeeded; ++i) {
		[[_localPlayerNamesForm cellAtIndex:i] setTitle:[NSString stringWithFormat:@"Player %d", (i + 1)]];
		[[_localPlayerNamesForm cellAtIndex:i] setPlaceholderString:@"Enter name"];
	}
}

// Make sure the names and numbers given for a network game are sensible
- (NSString *)_verifyNetworkGameParameters;
{
	if ([[_hostOrIPAddressTextField stringValue] length] == 0)
		return @"Please enter a host or IP address.";
	
	if ([_portTextField intValue] < 1 || [_portTextField intValue] > 65535)
		return @"Please enter a port number in the range 1-65535.";
	
	if ([[_displayNameTextField stringValue] length] == 0)
		return @"Please enter a display name.";
	
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
	[_connectToServerButton setTitle:@"Cancel Connection"];
	[_connectToServerButton setAction:@selector(cancelConnectingToServer:)];
}

- (void)_stopConnectingToAServer;
{
	[_networkProgressIndicator setHidden:YES];
	[_hostOrIPAddressTextField setEnabled:YES];
	[_portTextField setEnabled:YES];
	[_displayNameTextField setEnabled:YES];
	[_connectToServerButton setEnabled:YES];
	[_connectToServerButton setTitle:@"Connect to Server"];
	[_connectToServerButton setAction:@selector(connectToServer:)];
}
@end
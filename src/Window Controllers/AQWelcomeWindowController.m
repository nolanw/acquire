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

// Set the string value of the recent server combo box to the given recent 
// server.
- (void)_placeRecentServerInComboBox:(NSInteger)index;

@end


@implementation AQWelcomeWindowController

- (id)initWithAcquireController:(id)acquireController;
{
	if (![super init])
		return nil;
	
	_acquireController = [acquireController retain];
	_quitOnNextWindowClose = YES;
	
	if (_welcomeWindow == nil)
	{
		if (![NSBundle loadNibNamed:@"WelcomeWindow" owner:self])
		{
			NSLog(@"%@ failed to load WelcomeWindow.nib", NSStringFromSelector(_cmd));
      [self release];
			return nil;
		}
	}
	
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray *recentServers = [defaults objectForKey:@"RecentServers"];
  if (recentServers)
    _recentServers = [recentServers mutableCopy];
  else
  {
    NSString *initialRecent;
    NSString *oldLastServer = [defaults objectForKey:@"LastHostOrIPAddress"];
    NSString *oldLastPort = [defaults objectForKey:@"LastPort"];
    if (oldLastServer && oldLastPort)
      initialRecent = [NSString stringWithFormat:@"%@:%@", oldLastServer, oldLastPort];
    else
      initialRecent = @"acquire.game-host.org:1001";
    if (oldLastServer)
      [defaults removeObjectForKey:@"LastHostOrIPAddress"];
    if (oldLastPort)
      [defaults removeObjectForKey:@"LastPort"];
    _recentServers = [[NSMutableArray alloc] initWithObjects:initialRecent, nil];
  }
  if ([_recentServers count] > 0)
    [self _placeRecentServerInComboBox:0];
	
	NSString *lastDisplayName = [defaults objectForKey:@"LastDisplayName"];
	if (lastDisplayName != nil)
		[_displayNameTextField setStringValue:lastDisplayName];
	
	return self;
}

- (void)dealloc;
{
  [_recentServers release], _recentServers = nil;
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
	return [_serverComboBox stringValue];
}


- (void)saveNetworkGameDefaults;
{
  NSString *nameAndPort;
  NSString *server = [_serverComboBox stringValue];
  int port = [_portTextField intValue];
  if (port == 1001 && [_recentServers containsObject:server])
    nameAndPort = server;
  else
    nameAndPort = [NSString stringWithFormat:@"%@:%d", server, port];
  if ([_recentServers containsObject:nameAndPort])
    [_recentServers removeObject:nameAndPort];
  [_recentServers insertObject:nameAndPort atIndex:0];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:_recentServers forKey:@"RecentServers"];
	[defaults setObject:[_displayNameTextField stringValue]
               forKey:@"LastDisplayName"];
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
- (IBAction)separateHostAndPort:(id)sender;
{
  NSString *server = [_serverComboBox stringValue];
  NSArray *nameAndPort = [server componentsSeparatedByString:@":"];
  if ([nameAndPort count] >= 1)
    [_serverComboBox setStringValue:[nameAndPort objectAtIndex:0]];
  if ([nameAndPort count] > 1)
    [_portTextField setStringValue:[nameAndPort objectAtIndex:1]];
}

- (IBAction)connectToServer:(id)sender;
{
	NSString *verificationErrorString = [self _verifyNetworkGameParameters];
	if (verificationErrorString != nil)
	{
		NSAlert *verificationErrorAlert = [[[NSAlert alloc] init] autorelease];
		[verificationErrorAlert addButtonWithTitle:@"OK"];
		[verificationErrorAlert setMessageText:NSLocalizedStringFromTable(@"Some settings need correction.", @"Acquire", @"Error shown when settings on the welcome screen are invalid.")];
		[verificationErrorAlert setInformativeText:verificationErrorString];
		[verificationErrorAlert setAlertStyle:NSWarningAlertStyle];

		[verificationErrorAlert beginSheetModalForWindow:_welcomeWindow modalDelegate:self didEndSelector:@selector(networkErrorAlertDismissed:) contextInfo:nil];
		
		if ([verificationErrorString isEqualToString:NSLocalizedStringFromTable(@"Please enter a host or IP address.", @"Acquire", @"String asking user to enter a hostname or IP address.")])
			[_serverComboBox selectText:self];
		else if ([verificationErrorString isEqualToString:NSLocalizedStringFromTable(@"Please enter a port number in the range 1-65535.", @"Acquire", @"String asking user to enter a port number from 1-65535 inclusive.")])
			[_portTextField selectText:self];
		else if ([verificationErrorString isEqualToString:NSLocalizedStringFromTable(@"Please enter a display name.", @"Acquire", @"String asking user to enter a display name.")])
			[_displayNameTextField selectText:self];
		
		return;
	}
	
	_displayNameInUseErrorShown = NO;
	
	[self _startConnectingToAServer];
	
	[_acquireController connectToServer:[_serverComboBox stringValue]
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
	[_serverComboBox setEnabled:YES];
	[_portTextField setEnabled:YES];
	[_displayNameTextField setEnabled:YES];
	[_connectToServerButton setEnabled:YES];
	[_connectToServerButton setTitle:NSLocalizedStringFromTable(@"Connect to Server", @"Acquire", @"Button text saying 'connect to server'")];
	[_connectToServerButton setAction:@selector(connectToServer:)];
}


// Button action responses
- (void)gameConnectionFailed;
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

- (void)lostServerConnection;
{
	if (_displayNameInUseErrorShown)
		return;
	
	NSAlert *lostServerConnectionAlert = [[[NSAlert alloc] init] autorelease];
	[lostServerConnectionAlert addButtonWithTitle:@"OK"];
	[lostServerConnectionAlert setMessageText:NSLocalizedStringFromTable(@"Server connection lost", @"Acquire", @"Alert box title saying the server's connection was lost.")];
	[lostServerConnectionAlert setInformativeText:NSLocalizedStringFromTable(@"The connection to the server was unexpectedly lost. If the server's still up, any games being played should still exist. You can rejoin any game you were a part of so long as your display name doesn't change.", @"Acquire", @"Alert informative text saying the server connection was unexpectedly lost, but games will be safe if the server didn't crash, and to leave the display name unchanged in order to join a new game.")];
	[lostServerConnectionAlert setAlertStyle:NSWarningAlertStyle];
	
	[lostServerConnectionAlert beginSheetModalForWindow:_welcomeWindow
                                        modalDelegate:self
                                       didEndSelector:nil
                                          contextInfo:nil];
}

#if 0
#pragma mark -
#pragma mark NSComboBoxDataSource
#endif

- (NSString*)comboBox:(NSComboBox*)aComboBox
      completedString:(NSString*)uncompletedString
{
  NSEnumerator *serverEnumerator = [_recentServers objectEnumerator];
  NSString *curServer;
  while ((curServer = [serverEnumerator nextObject]))
  {
    if ([curServer hasPrefix:uncompletedString])
      return curServer;
  }
  return uncompletedString;
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox
  indexOfItemWithStringValue:(NSString *)aString
{
  return [_recentServers indexOfObject:aString];
}

- (id)comboBox:(NSComboBox *)aComboBox 
  objectValueForItemAtIndex:(NSInteger)index
{
  if (index < 0)
  {
    if ([_recentServers count] > 0)
      return [_recentServers objectAtIndex:0];
    else
      return nil;
  }
  else
  {
    return [_recentServers objectAtIndex:index];
  }
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
  return [_recentServers count];
}

#if 0
#pragma mark -
#pragma mark NSComboBoxDelegate
#endif

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
  NSUInteger selectedIndex = [_serverComboBox indexOfSelectedItem];
  if (selectedIndex == -1)
    return;
  [_serverComboBox deselectItemAtIndex:selectedIndex];
  [self _placeRecentServerInComboBox:selectedIndex];
}

@end

@implementation AQWelcomeWindowController (Private)

// Make sure the names and numbers given for a network game are sensible
- (NSString *)_verifyNetworkGameParameters;
{
	if ([[_serverComboBox stringValue] length] == 0)
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
	[_serverComboBox setEnabled:NO];
	[_portTextField setEnabled:NO];
	[_displayNameTextField setEnabled:NO];
	[_connectToServerButton setTitle:NSLocalizedStringFromTable(@"Cancel Connection", @"Acquire", "Button text saying 'cancel connection'.")];
	[_connectToServerButton setAction:@selector(cancelConnectingToServer:)];
}

- (void)_placeRecentServerInComboBox:(NSInteger)index;
{
  NSString *server = [_recentServers objectAtIndex:index];
  [_serverComboBox setStringValue:server];
  [self separateHostAndPort:self];
}

@end
// AQConnectionController.m
//
// Created May 27, 2008 by nwaite

#import "AQConnectionController.h"
#import "AQConnectionArrayController.h"
#import "AQAcquireController.h"
#import "AQNetacquireDirective.h"

@interface AQConnectionController (Private)
// Netacquire directive handling
// Incoming directives
- (void)_receivedDirective:(AQNetacquireDirective *)directive;
- (NSArray *)_parseMultipleDirectives:(AQNetacquireDirective *)bunchOfDirectives;
- (void)_receivedATDirective:(AQNetacquireDirective *)activateTileDirective;
- (void)_receivedGMDirective:(AQNetacquireDirective *)gameMessageDirective;
- (void)_receivedGMDirective:(AQNetacquireDirective *)gameMessageDirective isFirstPass:(BOOL)isFirstPass;
- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective;
- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective isFirstPass:(BOOL)isFirstPass;
- (void)_receivedFirstLMDirectives:(AQNetacquireDirective *)bunchOfLMDirectives;
- (void)_receivedGameListDirective:(AQNetacquireDirective *)gameListDirective;
- (void)_receivedMDirective:(AQNetacquireDirective *)messageDirective;
- (void)_receivedPIDirective:(AQNetacquireDirective *)pingDirective;
- (void)_receivedSPDirective:(AQNetacquireDirective *)startPlayerDirective;
- (void)_receivedSSDirective:(AQNetacquireDirective *)setStateDirective;

// And outgoing directives
- (void)_sendDirectiveData:(NSData *)data;
- (void)_sendDirectiveWithCode:(NSString *)directiveCode;
- (void)_sendBMDirectiveToLobbyWithMessage:(NSString *)message;
- (void)_sendBMDirectiveToGameRoomWithMessage:(NSString *)message;
- (void)_sendJGDirectiveWithGameNumber:(int)gameNumber;
- (void)_sendPLDirectiveWithDisplayName:(NSString *)displayName versionStrings:(NSArray *)versionStrings;
- (void)_sendPRDirectiveWithTimestamp:(NSString *)timestamp;

// And their supporting cast
- (void)_incomingLobbyMessage:(NSString *)lobbyMessage;
@end

@implementation AQConnectionController
- (id)initWithHost:(NSString *)host port:(UInt16)port for:(id)sender arrayController:(id)arrayController;
{
	if (![super init])
		return nil;
	
	if ([host length] == 0)
		return nil;
	
	if (sender == nil || arrayController == nil)
		return nil;
	
	_associatedObject = [sender retain];
	_arrayController = [arrayController retain];
	_error = [NSError alloc];
	_handshakeComplete = NO;
	_haveSeenFirstLMDirectives = NO;
	_objectRequestingGameListUpdate = nil;
	
	_socket = [[AsyncSocket alloc] initWithDelegate:self];
	
	if (![_socket connectToHost:host onPort:port error:&_error])
		if ([_associatedObject respondsToSelector:@selector(connection:willDisconnectWithError:)])
			[_associatedObject connection:self willDisconnectWithError:_error];

	return self;
}

- (void)dealloc;
{
	[_associatedObject release];
	[_arrayController release];
	[_socket release];
	[_error release];
	
	[super dealloc];
}


// Accessors/setters/etc.
- (id)associatedObject;
{
	return _associatedObject;
}

- (NSError *)error;
{
	return _error;
}

- (BOOL)isServerConnection;
{
	return ([(AQConnectionArrayController *)_arrayController serverConnection] == self);
}

- (void)close;
{
	[_socket disconnectAfterWriting];
}

- (BOOL)isConnected;
{
	return [_socket isConnected];
}

- (NSString *)connectedHostOrIPAddress;
{
	return [_socket connectedHost];
}

- (void)joinGame:(int)gameNumber;
{
	[self _sendJGDirectiveWithGameNumber:gameNumber];
}

- (void)leaveGame;
{
	[self _sendDirectiveWithCode:@"LV"];
}

- (void)disconnectFromServer;
{
//	[self _sendDirectiveWithCode:@"CL"];
	[self close];
}


// Sending some outgoing mail
- (void)outgoingLobbyMessage:(NSString *)lobbyMessage;
{
	if ([lobbyMessage length] == 0)
		return;
	
	[self _sendBMDirectiveToLobbyWithMessage:lobbyMessage];
}

- (void)outgoingGameMessage:(NSString *)gameMessage;
{
	if ([gameMessage length] == 0)
		return;
	
	[self _sendBMDirectiveToGameRoomWithMessage:gameMessage];
}

- (void)updateGameListFor:(id)anObject;
{
	if (!_handshakeComplete) {
		[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(retryUpdateGameList:) userInfo:anObject repeats:NO];
		return;
	}
	
	_objectRequestingGameListUpdate = anObject;
	[self _sendDirectiveWithCode:@"LG"];
}

- (void)retryUpdateGameList:(NSTimer *)aTimer;
{
	[self updateGameListFor:[aTimer userInfo]];
}


// AsyncSocket delegate selectors
- (void)onSocket:(AsyncSocket *)socket willDisconnectWithError:(NSError *)err;
{
	[_error release];
	_error = [err retain];
	
	if ([_associatedObject respondsToSelector:@selector(connection:willDisconnectWithError:)])
		[_associatedObject connection:self willDisconnectWithError:err];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)socket;
{
	[(AQConnectionArrayController *)_arrayController connectionClosed:self];
}

- (void)onSocket:(AsyncSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port;
{
	if (socket != _socket)
		return;
	
	if ([self isServerConnection])
		[_socket readDataWithTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)socket didReadData:(NSData *)data withTag:(long)tag;
{
	[self _receivedDirective:[AQNetacquireDirective directiveWithData:data]];
	[_socket readDataWithTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)socket didWriteDataWithTag:(long)tag;
{
	[_socket readDataWithTimeout:-1 tag:0];
}
@end

@implementation AQConnectionController (Private)
// Netacquire directive handling
// Incoming directives
- (void)_receivedDirective:(AQNetacquireDirective *)directive;
{
	NSString *directiveCode = [directive directiveCode];
	
	if ([directiveCode isEqualToString:@"AT"]) {
		[self _receivedATDirective:directive];
		return;
	}
	
	if ([directiveCode isEqualToString:@"GM"]) {
		[self _receivedGMDirective:directive];
		return;
	}
	
	if ([directiveCode isEqualToString:@"LM"]) {
		if (_haveSeenFirstLMDirectives)
			[self _receivedLMDirective:directive];
		else
			[self _receivedFirstLMDirectives:directive];
		
		return;
	}
	
	if ([directiveCode isEqualToString:@"M"]) {
		[self _receivedMDirective:directive];
		return;
	}
	
	if ([directiveCode isEqualToString:@"PI"]) {
		[self _receivedPIDirective:directive];
		return;
	}
	
	if ([directiveCode isEqualToString:@"SP"]) {
		[self _receivedSPDirective:directive];
		return;
	}
	
	if ([directiveCode isEqualToString:@"SS"]) {
		[self _receivedSSDirective:directive];
		return;
	}
}

- (NSArray *)_parseMultipleDirectives:(AQNetacquireDirective *)bunchOfDirectives;
{
	NSString *directives = [[NSString alloc] initWithData:[bunchOfDirectives protocolData] encoding:NSASCIIStringEncoding];
	NSMutableArray *separatedDirectives = [NSMutableArray arrayWithCapacity:4];
	
	NSRange endOfFirstDirective;
	while ([directives length] > 0) {
		endOfFirstDirective = [directives rangeOfString:@";:"];
		if (endOfFirstDirective.location == NSNotFound)
			break;
		
		endOfFirstDirective.length = endOfFirstDirective.location + 2;
		endOfFirstDirective.location = 0;
		[separatedDirectives addObject:[AQNetacquireDirective directiveWithString:[directives substringWithRange:endOfFirstDirective]]];
		NSLog(@"%s %@", _cmd, [separatedDirectives lastObject]);
		if ([directives length] <= endOfFirstDirective.length + 1)
			break;
		
		[directives autorelease];
		directives = [[directives substringFromIndex:endOfFirstDirective.length] retain];
	}
	
	[directives release];
	return separatedDirectives;
}

- (void)_receivedATDirective:(AQNetacquireDirective *)activateTileDirective;
{
	NSArray *parameters = [activateTileDirective parameters];
	if ([parameters count] != 3)
		return;
	
	NSLog(@"%s index: %d; netacquireID: %@", _cmd, ([[parameters objectAtIndex:0] intValue] - 1), [parameters objectAtIndex:1]);
	[_associatedObject rackTileAtIndex:([[parameters objectAtIndex:0] intValue] - 1) isNetacquireID:[[parameters objectAtIndex:1] intValue] netacquireChainID:[[parameters objectAtIndex:2] intValue]];
}

- (void)_receivedGMDirective:(AQNetacquireDirective *)gameMessageDirective;
{
	[self _receivedGMDirective:gameMessageDirective isFirstPass:YES];
}

- (void)_receivedGMDirective:(AQNetacquireDirective *)gameMessageDirective isFirstPass:(BOOL)isFirstPass;
{
	if ([[gameMessageDirective parameters] count] != 1)
		return;
	
	NSString *messageText = [[gameMessageDirective parameters] objectAtIndex:0];
	
	if (isFirstPass && [messageText characterAtIndex:1] == '*') {
		NSArray *directives = [self _parseMultipleDirectives:gameMessageDirective];
		NSEnumerator *directiveEnumerator = [directives objectEnumerator];
		id curDirective;
		while (curDirective = [directiveEnumerator nextObject]) {
			if ([[curDirective directiveCode] isEqualToString:@"LM"])
				[self _receivedLMDirective:curDirective isFirstPass:NO];
			else if ([[curDirective directiveCode] isEqualToString:@"GM"])
				[self _receivedGMDirective:curDirective isFirstPass:NO];
			else
				[self _receivedDirective:curDirective];
		}
		return;
	}
	
	[_associatedObject incomingGameMessage:[[[gameMessageDirective parameters] objectAtIndex:0] substringWithRange:NSMakeRange(1, [[[gameMessageDirective parameters] objectAtIndex:0] length] - 2)]];
}

- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective;
{
	[self _receivedLMDirective:lobbyMessageDirective isFirstPass:YES];
}

- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective isFirstPass:(BOOL)isFirstPass;
{
	// The server's response to LG and LU directives come in chunks of LM directives.
	NSString *messageText = [[lobbyMessageDirective parameters] objectAtIndex:0];
	if ([[messageText substringToIndex:15] isEqualToString:@"\"# Active games"]) {
		[self _receivedGameListDirective:lobbyMessageDirective];
		return;
	}
	
	// Messages starting with an asterisk are server information, so they're safe to parse for multiple directives.
	if (isFirstPass && [messageText characterAtIndex:1] == '*') {
		NSArray *directives = [self _parseMultipleDirectives:lobbyMessageDirective];
		NSEnumerator *directiveEnumerator = [directives objectEnumerator];
		id curDirective;
		while (curDirective = [directiveEnumerator nextObject]) {
			if ([[curDirective directiveCode] isEqualToString:@"LM"])
				[self _receivedLMDirective:curDirective isFirstPass:NO];
			else if ([[curDirective directiveCode] isEqualToString:@"GM"])
				[self _receivedGMDirective:curDirective isFirstPass:NO];
			else
				[self _receivedDirective:curDirective];
		}
		return;
	}
	
	[self _incomingLobbyMessage:[messageText substringWithRange:NSMakeRange(1, [messageText length] - 2)]];
}

- (void)_receivedFirstLMDirectives:(AQNetacquireDirective *)bunchOfLMDirectives;
{
	if ([_associatedObject respondsToSelector:@selector(connectedToServer)])
		[_associatedObject connectedToServer];
	NSArray *directives = [self _parseMultipleDirectives:bunchOfLMDirectives];
	NSEnumerator *directivesEnumerator = [directives objectEnumerator];
	id curDirective;
	while (curDirective = [directivesEnumerator nextObject]) {
		if ([[curDirective directiveCode] isEqualToString:@"LM"])
			[self _receivedLMDirective:curDirective isFirstPass:NO];
		else
			[self _receivedDirective:curDirective];
	}
	_haveSeenFirstLMDirectives = YES;
	_handshakeComplete = YES;
}

- (void)_receivedGameListDirective:(AQNetacquireDirective *)gameListDirective;
{
	if (_objectRequestingGameListUpdate == nil)
		return;
	
	NSString *gameListString = [[gameListDirective parameters] objectAtIndex:0];
	NSMutableArray *gameList = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
	NSRange gameListStartRange = NSMakeRange(0, 1);	
	NSRange gameListEndRange = NSMakeRange(1, 1);
	while (gameListStartRange.location != gameListEndRange.location) {
		NSRange gameListStartRange = [gameListString rangeOfString:@";:LM;"];
		if (gameListStartRange.location == NSNotFound)
			break;
		NSRange gameListRange = NSMakeRange(gameListStartRange.location, [gameListString length] - gameListStartRange.location);
		gameListString = [gameListString substringWithRange:gameListRange];
		if ([gameListString length] < 13)
			break;
	
		gameListString = [gameListString substringFromIndex:12];
		NSRange gameNumberStartRange = [gameListString rangeOfString:@"#"];
		NSRange gameNumberEndRange = [gameListString rangeOfString:@"->"];
		if (gameNumberStartRange.location == NSNotFound || gameNumberEndRange.location == NSNotFound)
			break;
		NSRange gameNumberRange = NSMakeRange(gameNumberStartRange.location + 1, gameNumberEndRange.location - gameNumberStartRange.location - 1);
		[gameList addObject:[gameListString substringWithRange:gameNumberRange]];
	}
	
	if ([_objectRequestingGameListUpdate respondsToSelector:@selector(updatedGameList:)]) {
		[_objectRequestingGameListUpdate updatedGameList:gameList];
	}
	
	_objectRequestingGameListUpdate = nil;
}

- (void)_receivedMDirective:(AQNetacquireDirective *)messageDirective;
{
	if ([[messageDirective parameters] count] != 1)
		return;
	
	if ([[[[messageDirective parameters] objectAtIndex:0] substringToIndex:26] isEqualToString:@"\"E;Duplicate user Nickname"])
		if ([_associatedObject respondsToSelector:@selector(displayNameAlreadyInUse)])
			[_associatedObject displayNameAlreadyInUse];
		else
			NSLog(@"%s desired nickname already in use on server and not dealt with", _cmd);
	else if ([[[[messageDirective parameters] objectAtIndex:0] substringToIndex:30] isEqualToString:@"\"E;Invalid game number entered"])
		NSLog(@"%s an invalid game number was entered and not dealt with", _cmd);
		
}

- (void)_receivedPIDirective:(AQNetacquireDirective *)pingDirective;
{
	if ([[pingDirective parameters] count] != 1)
		return;
	
	[self _sendPRDirectiveWithTimestamp:[[pingDirective parameters] objectAtIndex:0]];
}

- (void)_receivedSPDirective:(AQNetacquireDirective *)startPlayerDirective;
{
	if ([[startPlayerDirective parameters] count] == 0) {
		NSLog(@"%s version string was empty!", _cmd);
		return;
	}
	
	NSRange versionInfoRange = NSMakeRange(0, [[startPlayerDirective parameters] count] - 1);
	[self _sendPLDirectiveWithDisplayName:[(AQAcquireController *)_associatedObject localPlayerName] versionStrings:[[startPlayerDirective parameters] subarrayWithRange:versionInfoRange]];
}

- (void)_receivedSSDirective:(AQNetacquireDirective *)setStateDirective;
{
	if ([[setStateDirective parameters] count] != 1) {
		return;
	}
	
	if ([[[setStateDirective parameters] objectAtIndex:0] intValue] == 4)
		if ([_associatedObject respondsToSelector:@selector(joiningGame)])
			[_associatedObject joiningGame];
}



// And outgoing directives
- (void)_sendDirectiveData:(NSData *)data;
{
	[_socket writeData:data withTimeout:20.0 tag:0];
}

- (void)_sendDirectiveWithCode:(NSString *)directiveCode;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:directiveCode];
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendBMDirectiveToLobbyWithMessage:(NSString *)message;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"BM"];
	[directive addParameter:@"Lobby"];
	[directive addParameter:[NSString stringWithFormat:@"\"%@\"", message]];
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendBMDirectiveToGameRoomWithMessage:(NSString *)message;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"BM"];
	[directive addParameter:@"Game Room"];
	[directive addParameter:[NSString stringWithFormat:@"\"%@\"", message]];
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendJGDirectiveWithGameNumber:(int)gameNumber;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"JG"];
	[directive addParameter:[NSString stringWithFormat:@"%d", gameNumber]];
	[directive addParameter:@"-1"];
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendPLDirectiveWithDisplayName:(NSString *)displayName versionStrings:(NSArray *)versionStrings;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"PL"];
	[directive addParameter:displayName];
	[directive addParameters:versionStrings];
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendPRDirectiveWithTimestamp:(NSString *)timestamp;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"PR"];
	[directive addParameter:timestamp];
	[self _sendDirectiveData:[directive protocolData]];
}


// And their supporting cast
- (void)_incomingLobbyMessage:(NSString *)lobbyMessage;
{
	if ([_associatedObject respondsToSelector:@selector(incomingLobbyMessage:)])
		[_associatedObject incomingLobbyMessage:lobbyMessage];
}
@end

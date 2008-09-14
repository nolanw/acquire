// AQConnectionController.m
//
// Created May 27, 2008 by nwaite

#import "AQConnectionController.h"
#import "AQConnectionArrayController.h"
#import "AQAcquireController.h"
#import "AQNetacquireDirective.h"
#import "AQGame.h"

@interface AQConnectionController (Private)
- (id)_firstAssociatedObjectThatRespondsToSelector:(SEL)selector;
- (NSArray *)_associatedObjectsThatRespondToSelector:(SEL)selector;
- (BOOL)_objectIsAssociated:(id)objectToCheck;

// Netacquire directive handling
// Incoming directives
- (void)_receivedDirective:(AQNetacquireDirective *)directive;
- (void)_handleDirective:(AQNetacquireDirective *)directive;
- (void)_parseMultipleDirectives:(AQNetacquireDirective *)bunchOfDirectives;
- (void)_receivedATDirective:(AQNetacquireDirective *)activateTileDirective;
- (void)_receivedGCDirective:(AQNetacquireDirective *)getChainDirective;
- (void)_receivedGDDirective:(AQNetacquireDirective *)getDispositionDirective;
- (void)_receivedGMDirective:(AQNetacquireDirective *)gameMessageDirective;
- (void)_receivedGMDirective:(AQNetacquireDirective *)gameMessageDirective isFirstPass:(BOOL)isFirstPass;
- (void)_receivedGPDirective:(AQNetacquireDirective *)getPurchaseDirective;
- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective;
- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective isFirstPass:(BOOL)isFirstPass;
- (void)_receivedFirstLMDirectives:(AQNetacquireDirective *)bunchOfLMDirectives;
- (void)_receivedGameListDirective:(AQNetacquireDirective *)gameListDirective;
- (void)_receivedMDirective:(AQNetacquireDirective *)messageDirective;
- (void)_receivedPIDirective:(AQNetacquireDirective *)pingDirective;
- (void)_receivedSBDirective:(AQNetacquireDirective *)setBoardStatusDirective;
- (void)_receivedSPDirective:(AQNetacquireDirective *)startPlayerDirective;
- (void)_receivedSSDirective:(AQNetacquireDirective *)setStateDirective;
- (void)_receivedSVDirective:(AQNetacquireDirective *)setValueDirective;

// And outgoing directives
- (void)_sendDirectiveData:(NSData *)data;
- (void)_sendDirectiveWithCode:(NSString *)directiveCode;
- (void)_sendBMDirectiveToLobbyWithMessage:(NSString *)message;
- (void)_sendBMDirectiveToGameRoomWithMessage:(NSString *)message;
- (void)_sendCSDirectiveWithChainID:(int)chainID selectionType:(int)selectionType;
- (void)_sendJGDirectiveWithGameNumber:(int)gameNumber;
- (void)_sendMDDirectiveWithSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
- (void)_sendPDirectiveWithParameters:(NSArray *)parameters;
- (void)_sendPLDirectiveWithDisplayName:(NSString *)displayName versionStrings:(NSArray *)versionStrings;
- (void)_sendPRDirectiveWithTimestamp:(NSString *)timestamp;
- (void)_sendPTDirectiveWithIndex:(int)index;
- (void)_sendSGDirectiveWithMaximumPlayers:(int)maximumPlayers;

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
	
	_associatedObjects = [[NSMutableArray arrayWithObject:sender] retain];
	_arrayController = [arrayController retain];
	_error = [NSError alloc];
	_handshakeComplete = NO;
	_haveSeenFirstLMDirectives = NO;
	_objectRequestingGameListUpdate = nil;
	_creatingGame = NO;
	
	_socket = [[AsyncSocket alloc] initWithDelegate:self];
	
	if (![_socket connectToHost:host onPort:port error:&_error])
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(connection:willDisconnectWithError:)] connection:self willDisconnectWithError:_error];

	return self;
}

- (void)dealloc;
{
	[_associatedObjects release];
	[_arrayController release];
	[_socket release];
	[_error release];
	
	[super dealloc];
}


// Accessors/setters/etc.
- (void)registerAssociatedObject:(id)newAssociatedObject;
{
	if (newAssociatedObject == nil)
		return;
	
	if ([self _objectIsAssociated:newAssociatedObject])
		return;
	
	[_associatedObjects addObject:newAssociatedObject];
}

- (void)registerAssociatedObjectAndPrioritize:(id)newPriorityAssociatedObject;
{
	if (newPriorityAssociatedObject == nil)
		return;
	
	[_associatedObjects insertObject:newPriorityAssociatedObject atIndex:0];
}

- (void)deregisterAssociatedObject:(id)oldAssociatedObject;
{
	if (oldAssociatedObject == nil)
		return;
	
	if (![self _objectIsAssociated:oldAssociatedObject])
		return;
	
	[_associatedObjects removeObject:oldAssociatedObject];
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

- (void)createGame;
{
	[self _sendSGDirectiveWithMaximumPlayers:6];
	_creatingGame = YES;
}

- (void)startActiveGame;
{
	[self _sendDirectiveWithCode:@"PG"];
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

- (void)playTileAtRackIndex:(int)rackIndex;
{
	[self _sendPTDirectiveWithIndex:rackIndex];
}

- (void)choseHotelToCreate:(int)newHotelNetacquireID;
{
	[self _sendCSDirectiveWithChainID:newHotelNetacquireID selectionType:4];
}

- (void)purchaseShares:(NSArray *)sharesPurchasedAsParameters;
{
	NSMutableArray *pDirectiveParameters = [NSMutableArray arrayWithArray:sharesPurchasedAsParameters];
	[pDirectiveParameters addObject:@"0"];
	[self _sendPDirectiveWithParameters:pDirectiveParameters];
}

- (void)purchaseSharesAndEndGame:(NSArray *)sharesPurchasedAsParameters;
{
	NSMutableArray *pDirectiveParameters = [NSMutableArray arrayWithArray:sharesPurchasedAsParameters];
	[pDirectiveParameters addObject:@"1"];
	[self _sendPDirectiveWithParameters:pDirectiveParameters];
}

- (void)mergerSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
{
	[self _sendMDDirectiveWithSharesSold:sharesSold sharesTraded:sharesTraded];
}

- (void)selectedMergeSurvivor:(int)survivingHotelNetacquireID;
{
	[self _sendCSDirectiveWithChainID:survivingHotelNetacquireID selectionType:6];
}


// AsyncSocket delegate selectors
- (void)onSocket:(AsyncSocket *)socket willDisconnectWithError:(NSError *)err;
{
	[_error release];
	_error = [err retain];
	
	[[self _firstAssociatedObjectThatRespondsToSelector:@selector(connection:willDisconnectWithError:)] connection:self willDisconnectWithError:err];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)socket;
{
	NSEnumerator *associatedObjectEnumerator = [[self _associatedObjectsThatRespondToSelector:@selector(disconnectedFromServer:)] objectEnumerator];
	id curObject;
	while (curObject = [associatedObjectEnumerator nextObject])
		[curObject disconnectedFromServer:YES];
	
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
- (id)_firstAssociatedObjectThatRespondsToSelector:(SEL)selector;
{
	NSEnumerator *associatedObjectEnumerator = [_associatedObjects objectEnumerator];
	id curAssociatedObject;
	while (curAssociatedObject = [associatedObjectEnumerator nextObject])
		if ([curAssociatedObject respondsToSelector:selector])
			return curAssociatedObject;
	
	return nil;
}

- (NSArray *)_associatedObjectsThatRespondToSelector:(SEL)selector;
{
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity:5];
	NSEnumerator *associatedObjectEnumerator = [_associatedObjects objectEnumerator];
	id curAssociatedObject;
	while (curAssociatedObject = [associatedObjectEnumerator nextObject])
		if ([curAssociatedObject respondsToSelector:selector])
			[ret addObject:curAssociatedObject];
	
	return ret;
}

- (BOOL)_objectIsAssociated:(id)objectToCheck;
{
	NSEnumerator *associatedObjectEnumerator = [_associatedObjects objectEnumerator];
	id curAssociatedObject;
	while (curAssociatedObject = [associatedObjectEnumerator nextObject])
		if (curAssociatedObject == objectToCheck)
			return YES;
	
	return NO;
}

// Netacquire directive handling
// Incoming directives
- (void)_receivedDirective:(AQNetacquireDirective *)directive;
{	
	if ([[directive directiveCode] isEqualToString:@"LM"]) {
		if (_haveSeenFirstLMDirectives)
			[self _receivedLMDirective:directive isFirstPass:YES];
		else
			[self _receivedFirstLMDirectives:directive];
		
		return;
	}
	
	if ([[directive directiveCode] isEqualToString:@"GM"]) {
		[self _receivedGMDirective:directive];
		return;
	}
	
	[self _parseMultipleDirectives:directive];
}

- (void)_handleDirective:(AQNetacquireDirective *)directive;
{
	NSString *directiveCode = [directive directiveCode];
	
	if ([directiveCode isEqualToString:@"AT"]) {
		[self _receivedATDirective:directive];
		return;
	}
	
	if ([directiveCode isEqualToString:@"GC"]) {
		[self _receivedGCDirective:directive];
		return;
	}
	
	if ([directiveCode isEqualToString:@"GD"]) {
		[self _receivedGDDirective:directive];
		return;
	}
	
	if ([directiveCode isEqualToString:@"GM"]) {
		[self _receivedGMDirective:directive isFirstPass:NO];
		return;
	}
	
	if ([directiveCode isEqualToString:@"GP"]) {
		[self _receivedGPDirective:directive];
		return;
	}
	
	if ([directiveCode isEqualToString:@"LM"]) {
		[self _receivedLMDirective:directive isFirstPass:NO];
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
	
	if ([directiveCode isEqualToString:@"SB"]) {
		[self _receivedSBDirective:directive];
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
	
	if ([directiveCode isEqualToString:@"SV"]) {
		[self _receivedSVDirective:directive];
		return;
	}
}

- (void)_parseMultipleDirectives:(AQNetacquireDirective *)bunchOfDirectives;
{
	NSString *directives = [[[NSString alloc] initWithData:[bunchOfDirectives protocolData] encoding:NSASCIIStringEncoding] autorelease];
	NSMutableArray *separatedDirectives = [NSMutableArray arrayWithCapacity:4];
	
	NSRange endOfFirstDirective;
	while ([directives length] > 0) {
		endOfFirstDirective = [directives rangeOfString:@";:"];
		if (endOfFirstDirective.location == NSNotFound)
			break;
		
		endOfFirstDirective.length = endOfFirstDirective.location + 2;
		endOfFirstDirective.location = 0;
		[separatedDirectives addObject:[AQNetacquireDirective directiveWithString:[directives substringWithRange:endOfFirstDirective]]];
		
		directives = [directives substringFromIndex:endOfFirstDirective.length];
	}
	
	NSEnumerator *directivesEnumerator = [separatedDirectives objectEnumerator];
	id curDirective;
	while (curDirective = [directivesEnumerator nextObject])
		[self _handleDirective:curDirective];
}

- (void)_receivedATDirective:(AQNetacquireDirective *)activateTileDirective;
{
	NSArray *parameters = [activateTileDirective parameters];
	if ([parameters count] != 3)
		return;
	
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(rackTileAtIndex:isNetacquireID:netacquireChainID:)];
	
	[associatedObject rackTileAtIndex:[[parameters objectAtIndex:0] intValue] isNetacquireID:[[parameters objectAtIndex:1] intValue] netacquireChainID:[[parameters objectAtIndex:2] intValue]];
}

- (void)_receivedGCDirective:(AQNetacquireDirective *)getChainDirective;
{
	NSArray *parameters = [getChainDirective parameters];
	if ([parameters count] == 1 && [[parameters objectAtIndex:0] intValue] == 4) {
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(showCreateNewHotelSheet)] showCreateNewHotelSheet];
		return;
	}
	
	if ([parameters count] <= 1 || [parameters count] > 8)
		return;
	
	int selectionType = [[parameters objectAtIndex:0] intValue];
	if (selectionType != 4 && selectionType != 6)
		return;
	
	NSMutableArray *hotelIndexes = [NSMutableArray arrayWithCapacity:7];
	int i;
	for (i = 1; i < [parameters count]; ++i)
		[hotelIndexes addObject:[NSNumber numberWithInt:([[parameters objectAtIndex:i] intValue] - 1)]];
	
	if (selectionType == 4) {
		id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(getChainFromHotelIndexes:)];
		[associatedObject getChainFromHotelIndexes:hotelIndexes];
		return;
	}
	
	if (selectionType == 6) {
		id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(chooseMergeSurvivorFromHotelIndexes:)];
		[associatedObject chooseMergeSurvivorFromHotelIndexes:hotelIndexes];
		return;
	}
}

- (void)_receivedGDDirective:(AQNetacquireDirective *)getDispositionDirective;
{
	NSArray *parameters = [getDispositionDirective parameters];
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(showAllocateMergingHotelSharesSheetForHotelWithNetacquireID:survivingHotelNetacquireID:)];
	[associatedObject showAllocateMergingHotelSharesSheetForHotelWithNetacquireID:[[parameters objectAtIndex:4] intValue] survivingHotelNetacquireID:[[parameters objectAtIndex:5] intValue]];
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
	
	if (isFirstPass && ([messageText characterAtIndex:1] == '*' || [messageText characterAtIndex:1] == '>')) {
		[self _parseMultipleDirectives:gameMessageDirective];
		return;
	}
	
	if ([messageText characterAtIndex:1] == '*' && [messageText length] > 13 && [[messageText substringToIndex:14] isEqualToString:@"\"*Waiting for "]) {
		id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(setActivePlayerName:)];
		[associatedObject setActivePlayerName:[messageText substringWithRange:NSMakeRange(14, [messageText length] - 29)]];
	}
	
	if ([messageText characterAtIndex:1] == '*' && [messageText length] > 19 && [[messageText substringWithRange:NSMakeRange(1, ([messageText length] - 2))] isEqualToString:@"*>>>>GAME OVER<<<<"]) {
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(determineAndCongratulateWinner)] determineAndCongratulateWinner];
	}
	
	if ([messageText characterAtIndex:1] == '>' && [messageText length] > 20 && [[messageText substringWithRange:NSMakeRange(1, 19)] isEqualToString:@"> This game is over"]) {
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(disableBoardAndTileRack)] disableBoardAndTileRack];
	}
	
	if ([messageText characterAtIndex:1] == '*' || [messageText characterAtIndex:1] == '>') {
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(incomingGameLogEntry:)] incomingGameLogEntry:[[[gameMessageDirective parameters] objectAtIndex:0] substringWithRange:NSMakeRange(1, [[[gameMessageDirective parameters] objectAtIndex:0] length] - 2)]];
		return;
	}
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(incomingGameMessage:)];
	[associatedObject incomingGameMessage:[[[gameMessageDirective parameters] objectAtIndex:0] substringWithRange:NSMakeRange(1, [[[gameMessageDirective parameters] objectAtIndex:0] length] - 2)]];
}

- (void)_receivedGPDirective:(AQNetacquireDirective *)getPurchaseDirective;
{
	if ([[getPurchaseDirective parameters] count] != 2)
		return;
	
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(getPurchaseWithGameEndFlag:cash:)];
	[associatedObject getPurchaseWithGameEndFlag:[[[getPurchaseDirective parameters] objectAtIndex:0] intValue] cash:[[[getPurchaseDirective parameters] objectAtIndex:1] intValue]];
}

- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective;
{
	[self _receivedLMDirective:lobbyMessageDirective isFirstPass:YES];
}

- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective isFirstPass:(BOOL)isFirstPass;
{
	// The server's response to LG and LU directives come in chunks of LM directives.
	NSString *messageText = [[lobbyMessageDirective parameters] objectAtIndex:0];
	if ([messageText length] > 14 && [[messageText substringToIndex:15] isEqualToString:@"\"# Active games"]) {
		[self _receivedGameListDirective:lobbyMessageDirective];
		return;
	}
	
	// Messages starting with an asterisk are server information, so they're safe to parse for multiple directives.
	if (isFirstPass && ([messageText characterAtIndex:1] == '*' || [messageText characterAtIndex:1] == '>')) {
		[self _parseMultipleDirectives:lobbyMessageDirective];
		return;
	}
	
	[self _incomingLobbyMessage:[messageText substringWithRange:NSMakeRange(1, [messageText length] - 2)]];
}

- (void)_receivedFirstLMDirectives:(AQNetacquireDirective *)bunchOfLMDirectives;
{
	[[self _firstAssociatedObjectThatRespondsToSelector:@selector(connectedToServer)] connectedToServer];
	
	_haveSeenFirstLMDirectives = YES;
	_handshakeComplete = YES;
	
	[self _parseMultipleDirectives:bunchOfLMDirectives];
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
	
	NSString *message = [[messageDirective parameters] objectAtIndex:0];
	
	if ([[message substringToIndex:26] isEqualToString:@"\"E;Duplicate user Nickname"]) {
		id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(displayNameAlreadyInUse)];
		if (associatedObject != nil)
			[associatedObject displayNameAlreadyInUse];
		else
			NSLog(@"%s desired nickname already in use on server and not dealt with", _cmd);
		
		return;
	}
	
	if ([[message substringToIndex:30] isEqualToString:@"\"E;Invalid game number entered"]) {
		NSLog(@"%s an invalid game number was entered and not dealt with", _cmd);
		return;
	}
	
	if ([[message substringToIndex:23] isEqualToString:@"\"W;Test mode turned on."]) {
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(enteringTestMode)] enteringTestMode];
		return;
	}
	
	if ([[message substringToIndex:24] isEqualToString:@"\"W;Test mode turned off."]) {
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(exitingTestMode)] exitingTestMode];
		return;
	}
}

- (void)_receivedPIDirective:(AQNetacquireDirective *)pingDirective;
{
	if ([[pingDirective parameters] count] != 1)
		return;
	
	[self _sendPRDirectiveWithTimestamp:[[pingDirective parameters] objectAtIndex:0]];
}

- (void)_receivedSBDirective:(AQNetacquireDirective *)setBoardStatusDirective;
{
	NSLog(@"%s called", _cmd);
	if ([[setBoardStatusDirective parameters] count] != 2)
		return;

	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(boardTileAtNetacquireID:isNetacquireChainID:)];
	[associatedObject boardTileAtNetacquireID:[[[setBoardStatusDirective parameters] objectAtIndex:0] intValue] isNetacquireChainID:[[[setBoardStatusDirective parameters] objectAtIndex:1] intValue]];
}

- (void)_receivedSPDirective:(AQNetacquireDirective *)startPlayerDirective;
{
	if ([[startPlayerDirective parameters] count] == 0) {
		NSLog(@"%s version string was empty!", _cmd);
		return;
	}
	
	NSRange versionInfoRange = NSMakeRange(0, [[startPlayerDirective parameters] count] - 1);
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(localPlayerName)];
	if (associatedObject == nil)
		return;
	
	[self _sendPLDirectiveWithDisplayName:[associatedObject localPlayerName] versionStrings:[[startPlayerDirective parameters] subarrayWithRange:versionInfoRange]];
}

- (void)_receivedSSDirective:(AQNetacquireDirective *)setStateDirective;
{
	if ([[setStateDirective parameters] count] != 1) {
		return;
	}
	
	if ([[[setStateDirective parameters] objectAtIndex:0] intValue] == 4) {
		id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(joiningGame:)];
		[associatedObject joiningGame:_creatingGame];
		_creatingGame = NO;
	}
}

- (void)_receivedSVDirective:(AQNetacquireDirective *)setValueDirective;
{
	NSString *netacquireForm = [[setValueDirective parameters] objectAtIndex:0];
	int netacquireTableIndex = [[[setValueDirective parameters] objectAtIndex:2] intValue];
	NSString *netacquireValueType = [[setValueDirective parameters] objectAtIndex:3];
	NSString *netacquireCaption = ([[setValueDirective parameters] count] >= 5) ? [[setValueDirective parameters] objectAtIndex:4] : @"";
	
	if (![netacquireForm isEqualToString:@"frmScoreSheet"])
		return;
	
	if (![netacquireValueType isEqualToString:@"Caption"])
		return;
	
	if (netacquireTableIndex < 7) {
		// Player name
		if ([netacquireCaption length] == 0)
			return;
		
		id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:isNamed:)];
		[associatedObject playerAtIndex:netacquireTableIndex isNamed:netacquireCaption];
		
		return;
	}
	
	if (netacquireTableIndex >= 33 && netacquireTableIndex <= 80) {
		// Shares in a hotel
		if ([netacquireCaption length] <= 0)
			return;
		
		id associatedObject;
		
		if (netacquireTableIndex >= 33 && netacquireTableIndex <= 38) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasSacksonShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 33) hasSacksonShares:[netacquireCaption intValue]];
			return;			
		}
		
		if (netacquireTableIndex >= 40 && netacquireTableIndex <= 45) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasZetaShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 40) hasZetaShares:[netacquireCaption intValue]];
			return;			
		}
		
		if (netacquireTableIndex >= 47 && netacquireTableIndex <= 52) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasAmericaShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 47) hasAmericaShares:[netacquireCaption intValue]];
			return;			
		}
		
		if (netacquireTableIndex >= 54 && netacquireTableIndex <= 59) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasFusionShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 54) hasFusionShares:[netacquireCaption intValue]];
			return;			
		}
		
		if (netacquireTableIndex >= 61 && netacquireTableIndex <= 66) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasHydraShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 61) hasHydraShares:[netacquireCaption intValue]];
			return;			
		}
		
		if (netacquireTableIndex >= 68 && netacquireTableIndex <= 73) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasQuantumShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 68) hasQuantumShares:[netacquireCaption intValue]];
			return;			
		}
		
		if (netacquireTableIndex >= 75 && netacquireTableIndex <= 80) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasPhoenixShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 75) hasPhoenixShares:[netacquireCaption intValue]];
			return;			
		}
	}
	
	if (netacquireTableIndex >= 82 && netacquireTableIndex <= 87) {
		// Amount of cash
		if ([netacquireCaption length] <= 0)
			return;
		
		id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasCash:)];
		[associatedObject playerAtIndex:(netacquireTableIndex - 82) hasCash:[netacquireCaption intValue]];
		
		return;
	}
	
	// NSLog(@"%s %@", _cmd, setValueDirective);
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

- (void)_sendCSDirectiveWithChainID:(int)chainID selectionType:(int)selectionType;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"CS"];
	[directive addParameter:[NSString stringWithFormat:@"%d", chainID]];
	[directive addParameter:[NSString stringWithFormat:@"%d", selectionType]];
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

- (void)_sendMDDirectiveWithSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"MD"];
	[directive addParameter:[NSString stringWithFormat:@"%d", sharesSold]];
	[directive addParameter:[NSString stringWithFormat:@"%d", sharesTraded]];
	
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendPDirectiveWithParameters:(NSArray *)parameters;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"P"];
	[directive addParameters:parameters];
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

- (void)_sendPTDirectiveWithIndex:(int)index;
{
	NSLog(@"%s called", _cmd);
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"PT"];
	[directive addParameter:[NSString stringWithFormat:@"%d", index]];
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendSGDirectiveWithMaximumPlayers:(int)maximumPlayers;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"SG"];
	[directive addParameter:[NSString stringWithFormat:@"%d", maximumPlayers]];
	[self _sendDirectiveData:[directive protocolData]];
}


// And their supporting cast
- (void)_incomingLobbyMessage:(NSString *)lobbyMessage;
{
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(incomingLobbyMessage:)];
	[associatedObject incomingLobbyMessage:lobbyMessage];
}
@end

// AQConnectionController.m
//
// Created May 27, 2008 by nwaite

#import "AQConnectionController.h"
#import "AQConnectionArrayController.h"
#import "AQAcquireController.h"
#import "AQNetacquireDirective.h"
#import "AQGame.h"
#import "RegexKitLite.h"

#pragma mark -

@interface AQConnectionController (Private)
#pragma mark Private interface

#pragma mark 
#pragma mark Associated object handlers.

- (id)_firstAssociatedObjectThatRespondsToSelector:(SEL)selector;
- (NSArray *)_associatedObjectsThatRespondToSelector:(SEL)selector;
- (BOOL)_objectIsAssociated:(id)objectToCheck;

#pragma mark 
#pragma mark Incoming Netacquire directive handling

- (void)_receivedDirective:(AQNetacquireDirective *)directive;
- (void)_handleDirective:(AQNetacquireDirective *)directive;
- (void)_receivedATDirective:(AQNetacquireDirective *)activateTileDirective;
- (void)_receivedGCDirective:(AQNetacquireDirective *)getChainDirective;
- (void)_receivedGDDirective:(AQNetacquireDirective *)getDispositionDirective;
- (void)_receivedGMDirective:(AQNetacquireDirective *)gameMessageDirective;
- (void)_receivedGPDirective:(AQNetacquireDirective *)getPurchaseDirective;
- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective;
- (void)_receivedFirstLMDirectives:(AQNetacquireDirective *)bunchOfLMDirectives;
- (void)_receivedGameListDirective:(AQNetacquireDirective *)gameListDirective;
- (void)_receivedMDirective:(AQNetacquireDirective *)messageDirective;
- (void)_receivedPIDirective:(AQNetacquireDirective *)pingDirective;
- (void)_receivedSBDirective:(AQNetacquireDirective *)setBoardStatusDirective;
- (void)_receivedSPDirective:(AQNetacquireDirective *)startPlayerDirective;
- (void)_receivedSSDirective:(AQNetacquireDirective *)setStateDirective;
- (void)_receivedSVDirective:(AQNetacquireDirective *)setValueDirective;

#pragma mark 
#pragma mark Outoing Netacquire directive handling

- (void)_sendDirectiveData:(NSData *)data;
- (void)_sendDirectiveWithCode:(NSString *)directiveCode;
- (void)_sendBMDirectiveToLobbyWithMessage:(NSString *)message;
- (void)_sendBMDirectiveToGameRoomWithMessage:(NSString *)message;
- (void)_broadcastMessage:(NSString *)message to:(NSString *)destination;
- (void)_sendCSDirectiveWithChainID:(int)chainID selectionType:(int)selectionType;
- (void)_sendJGDirectiveWithGameNumber:(int)gameNumber;
- (void)_sendMDDirectiveWithSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
- (void)_sendPDirectiveWithParameters:(NSArray *)parameters;
- (void)_sendPLDirectiveWithDisplayName:(NSString *)displayName versionStrings:(NSArray *)versionStrings;
- (void)_sendPRDirectiveWithTimestamp:(NSString *)timestamp;
- (void)_sendPTDirectiveWithIndex:(int)index;
- (void)_sendSGDirectiveWithMaximumPlayers:(int)maximumPlayers;
- (void)_incomingLobbyMessage:(NSString *)lobbyMessage;
@end

#pragma mark -

@implementation AQConnectionController
#pragma mark Implementation

#pragma mark 
#pragma mark init/dealloc
- (id)initWithHost:(NSString *)host port:(UInt16)port for:(id)sender arrayController:(id)arrayController;
{
	if (![super init])
		return nil;
	
    NSAssert([host length] > 0, @"No host given.");
    NSAssert(sender != nil, @"No associated object provided.");
    NSAssert(arrayController != nil, @"No array controller provided.");
	
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


#pragma mark 
#pragma mark Accessors/setters/etc.

- (NSError *)error;
{
	return _error;
}

- (BOOL)isServerConnection;
{
	return ([(AQConnectionArrayController *)_arrayController serverConnection] == self);
}

- (BOOL)isConnected;
{
	return [_socket isConnected];
}

- (NSString *)connectedHostOrIPAddress;
{
	return [_socket connectedHost];
}

- (void)disconnectFromServer;
{
	[self close];
}

- (void)close;
{
	[_socket disconnectAfterWriting];
}


#pragma mark 
#pragma mark Associated object management

- (void)registerAssociatedObject:(id)newAssociatedObject;
{
    NSAssert(newAssociatedObject != nil, @"Passed nil object.");
	
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


#pragma mark 
#pragma mark Outgoing server-processed actions.

- (void)updateGameListFor:(id)anObject;
{
    NSAssert(anObject != nil, @"Passed in nil object.");
    
	if (!_handshakeComplete) {
		[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(retryUpdateGameList:) userInfo:anObject repeats:NO];
		return;
	}
	
    _objectRequestingGameListUpdate = [anObject retain];
	[self _sendDirectiveWithCode:@"LG"];
}

- (void)retryUpdateGameList:(NSTimer *)aTimer;
{
	[self updateGameListFor:[aTimer userInfo]];
}

- (void)outgoingLobbyMessage:(NSString *)lobbyMessage;
{
    NSAssert(lobbyMessage != nil, @"Passed in nil object.");
    
	if ([lobbyMessage length] == 0)
		return;
	
	[self _sendBMDirectiveToLobbyWithMessage:lobbyMessage];
}

- (void)joinGame:(int)gameNumber;
{
    NSAssert(gameNumber > 0, @"Game number must be > 0.");
	[self _sendJGDirectiveWithGameNumber:gameNumber];
}

- (void)createGame;
{
	[self _sendSGDirectiveWithMaximumPlayers:6];
	_creatingGame = YES;
}

- (void)outgoingGameMessage:(NSString *)gameMessage;
{
    NSAssert(gameMessage != nil, @"Passed in nil object.");
    
	if ([gameMessage length] == 0)
		return;
	
	[self _sendBMDirectiveToGameRoomWithMessage:gameMessage];
}

- (void)startActiveGame;
{
	[self _sendDirectiveWithCode:@"PG"];
}

- (void)playTileAtRackIndex:(int)rackIndex;
{
    NSAssert(rackIndex > 0 && rackIndex <= 6, @"Rack index out of bounds.");
	[self _sendPTDirectiveWithIndex:rackIndex];
}

- (void)choseHotelToCreate:(int)newHotelNetacquireID;
{
	[self _sendCSDirectiveWithChainID:newHotelNetacquireID selectionType:4];
}

- (void)purchaseShares:(NSArray *)sharesPurchasedAsParameters;
{
    NSAssert(sharesPurchasedAsParameters != nil, @"Passed in nil object.");
    
	NSMutableArray *pDirectiveParameters = [NSMutableArray arrayWithArray:sharesPurchasedAsParameters];
	[pDirectiveParameters addObject:@"0"];
	[self _sendPDirectiveWithParameters:pDirectiveParameters];
}

- (void)selectedMergeSurvivor:(int)survivingHotelNetacquireID;
{
    NSAssert(survivingHotelNetacquireID >= 0, @"Hotel Netacquire ID cannot be negative.");
	[self _sendCSDirectiveWithChainID:survivingHotelNetacquireID selectionType:6];
}

- (void)mergerSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
{
    NSAssert(sharesSold >= 0, @"Number of share sold cannot be negative.");
    NSAssert(sharesTraded >= 0, @"Number of share sold cannot be negative.");
    
	[self _sendMDDirectiveWithSharesSold:sharesSold sharesTraded:sharesTraded];
}

- (void)purchaseSharesAndEndGame:(NSArray *)sharesPurchasedAsParameters;
{
    NSAssert(sharesPurchasedAsParameters != nil, @"Passed in nil object.");
    
	NSMutableArray *pDirectiveParameters = [NSMutableArray arrayWithArray:sharesPurchasedAsParameters];
	[pDirectiveParameters addObject:@"1"];
	[self _sendPDirectiveWithParameters:pDirectiveParameters];
}

- (void)leaveGame;
{
	[self _sendDirectiveWithCode:@"LV"];
}

#pragma mark 
#pragma mark AsyncSocket delegate selectors

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

- (void)onSocket:(AsyncSocket*)socket
didConnectToHost:(NSString*)host
            port:(UInt16)port;
{
	if (socket != _socket)
		return;
	
	if ([self isServerConnection])
		[_socket readDataWithTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket*)socket
     didReadData:(NSData*)data
         withTag:(long)tag;
{
  NSMutableString *dataString = [[NSMutableString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding];
  [dataString autorelease];
  // There's a weird bug in (I think) ICU that appears when the end of the data 
  // is not the end of a directive (";:"). The bug causes ICU to take a 
  // *really* long time to parse out the components. To combat that, if the 
  // data doesn't end with ";:", we only parse up to and including the last 
  // whole directive. Anything that gets left off is saved for later, when it's 
  // prepended to the new incoming data.
  // (Well, this is what we should do, but at the moment we just look for the 
  // most recent ";:". This could in theory come in the middle of a quoted 
  // parameter, but that's a risk I'm willing to take at the moment.)
  if (_partOfLastDataString)
  {
    [dataString insertString:_partOfLastDataString atIndex:0];
    [_partOfLastDataString release];
    _partOfLastDataString = nil;
  }
  NSRange lastEndish = [dataString rangeOfString:@";:"
                                         options:NSBackwardsSearch];
  NSUInteger lastEnd = lastEndish.location + lastEndish.length;                                    
  if (lastEnd != [dataString length])
  {
    _partOfLastDataString = [[dataString substringFromIndex:lastEnd] retain];
    NSRange chopRange = NSMakeRange(lastEnd, [dataString length] - lastEnd);
    [dataString deleteCharactersInRange:chopRange];
  }
  NSArray *directives;
  directives = [AQNetacquireDirective directivesWithDataString:dataString];
  NSEnumerator *directiveEnumerator = [directives objectEnumerator];
  AQNetacquireDirective *curDirective;
  while ((curDirective = [directiveEnumerator nextObject]))
    [self _receivedDirective:curDirective];
	[_socket readDataWithTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)socket didWriteDataWithTag:(long)tag;
{
	[_socket readDataWithTimeout:-1 tag:0];
}
@end

#pragma mark -

@implementation AQConnectionController (Private)
#pragma mark Private implementation

#pragma mark 
#pragma mark Associated object handlers.

- (id)_firstAssociatedObjectThatRespondsToSelector:(SEL)selector;
{
    NSAssert(selector != NULL, @"Passed in null object.");
    
	NSEnumerator *associatedObjectEnumerator = [_associatedObjects objectEnumerator];
	id curAssociatedObject;
	while (curAssociatedObject = [associatedObjectEnumerator nextObject])
		if ([curAssociatedObject respondsToSelector:selector])
			return curAssociatedObject;
	
	return nil;
}

- (NSArray *)_associatedObjectsThatRespondToSelector:(SEL)selector;
{
    NSAssert(selector != NULL, @"Passed in null object.");
    
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
    NSAssert(objectToCheck != nil, @"Passed in nil object.");
    
	NSEnumerator *associatedObjectEnumerator = [_associatedObjects objectEnumerator];
	id curAssociatedObject;
	while (curAssociatedObject = [associatedObjectEnumerator nextObject])
		if (curAssociatedObject == objectToCheck)
			return YES;
	
	return NO;
}

#pragma mark 
#pragma mark Incoming Netacquire directive handling

- (void)_receivedDirective:(AQNetacquireDirective *)directive;
{
    NSAssert(directive != nil, @"Passed in nil object.");
    
	if ([[directive directiveCode] isEqualToString:@"LM"]) {
		if (_haveSeenFirstLMDirectives)
			[self _receivedLMDirective:directive];
		else
			[self _receivedFirstLMDirectives:directive];
		
		return;
	}
	
	if ([[directive directiveCode] isEqualToString:@"GM"]) {
		[self _receivedGMDirective:directive];
		return;
	}
	
	[self _handleDirective:directive];
}

- (void)_handleDirective:(AQNetacquireDirective *)directive;
{
    NSAssert(directive != nil, @"Passed in nil object.");
    
	NSString *directiveCode = [directive directiveCode];
	
	if ([directiveCode isEqualToString:@"AT"])
		[self _receivedATDirective:directive];
	
	else if ([directiveCode isEqualToString:@"GC"])
		[self _receivedGCDirective:directive];
    
	else if ([directiveCode isEqualToString:@"GD"])
		[self _receivedGDDirective:directive];
	
	else if ([directiveCode isEqualToString:@"GM"])
		[self _receivedGMDirective:directive];
	
	else if ([directiveCode isEqualToString:@"GP"])
		[self _receivedGPDirective:directive];
	
	else if ([directiveCode isEqualToString:@"LM"])
		[self _receivedLMDirective:directive];
	
	else if ([directiveCode isEqualToString:@"M"])
		[self _receivedMDirective:directive];
	
	else if ([directiveCode isEqualToString:@"PI"])
		[self _receivedPIDirective:directive];
	
	else if ([directiveCode isEqualToString:@"SB"])
		[self _receivedSBDirective:directive];
	
	else if ([directiveCode isEqualToString:@"SP"])
		[self _receivedSPDirective:directive];
	
	else if ([directiveCode isEqualToString:@"SS"])
		[self _receivedSSDirective:directive];
	
	else if ([directiveCode isEqualToString:@"SV"])
		[self _receivedSVDirective:directive];
}

- (void)_receivedATDirective:(AQNetacquireDirective *)activateTileDirective;
{
    NSAssert(activateTileDirective != nil, @"Passed in nil object.");
    
	NSArray *parameters = [activateTileDirective parameters];
	if ([parameters count] != 3)
		return;
	
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(rackTileAtIndex:isNetacquireID:netacquireChainID:)];
	
	[associatedObject rackTileAtIndex:[[parameters objectAtIndex:0] intValue] isNetacquireID:[[parameters objectAtIndex:1] intValue] netacquireChainID:[[parameters objectAtIndex:2] intValue]];
}

- (void)_receivedGCDirective:(AQNetacquireDirective *)getChainDirective;
{
    NSAssert(getChainDirective != nil, @"Passed in nil object.");
    
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
    NSAssert(getDispositionDirective != nil, @"Passed in nil object.");
    
	NSArray *parameters = [getDispositionDirective parameters];
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(showAllocateMergingHotelSharesSheetForHotelWithNetacquireID:survivingHotelNetacquireID:)];
	[associatedObject showAllocateMergingHotelSharesSheetForHotelWithNetacquireID:[[parameters objectAtIndex:4] intValue] survivingHotelNetacquireID:[[parameters objectAtIndex:5] intValue]];
}

- (void)_receivedGMDirective:(AQNetacquireDirective *)gameMessageDirective;
{
    NSAssert(gameMessageDirective != nil, @"Passed in nil object.");
    
	if ([[gameMessageDirective parameters] count] != 1)
		return;
	
	NSString *messageText = [[gameMessageDirective parameters] objectAtIndex:0];
  if ([messageText length] == 0)
    return;
  
  unichar first = [messageText characterAtIndex:1];
  NSString *tilePlayingRegex = @"\"?\\*Waiting for (.+) to play tile";
  NSString *tilePlayer = [messageText stringByMatching:tilePlayingRegex
                                               capture:1];
  if ([messageText isMatchedByRegex:@"\"?Waiting for "])
  {
    SEL selector = @selector(setActivePlayerName:isPurchasing:);
		id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:selector];
    if (tilePlayer)
			[associatedObject setActivePlayerName:tilePlayer isPurchasing:NO];
		else if ([messageText rangeOfString:@"make purchase" options:NSBackwardsSearch].location != NSNotFound)
			[associatedObject setActivePlayerName:[messageText substringWithRange:NSMakeRange(14, [messageText length] - 33)] isPurchasing:YES];
	}
	
  if (first == '*' && [messageText isMatchedByRegex:@"has ended the game."])
  {
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(determineAndCongratulateWinner)] determineAndCongratulateWinner];
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(disableBoardAndTileRack)] disableBoardAndTileRack];
	}
	
  NSRange chopRange = NSMakeRange(1, [messageText length] - 2);
  NSString *unquoted = [messageText substringWithRange:chopRange];
  NSString *unescaped = [unquoted stringByReplacingOccurrencesOfRegex:@"\"\""
                                                           withString:@"\""];
  SEL selector = @selector(incomingGameMessage:);
	if (first == '*' || first == '>')
    selector = @selector(incomingGameLogEntry:);
  id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:selector];
  [associatedObject performSelector:selector withObject:unescaped];
}

- (void)_receivedGPDirective:(AQNetacquireDirective *)getPurchaseDirective;
{
    NSAssert(getPurchaseDirective != nil, @"Passed in nil object.");
    
	if ([[getPurchaseDirective parameters] count] != 2)
		return;
	
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(getPurchaseWithGameEndFlag:cash:)];
	[associatedObject getPurchaseWithGameEndFlag:[[[getPurchaseDirective parameters] objectAtIndex:0] intValue] cash:[[[getPurchaseDirective parameters] objectAtIndex:1] intValue]];
}

- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective;
{
    NSAssert(lobbyMessageDirective != nil, @"Passed in nil object.");
    
	// The server's response to LG and LU directives come in chunks of LM directives.
	NSString *messageText = [[lobbyMessageDirective parameters] objectAtIndex:0];
  if (_objectRequestingGameListUpdate && [messageText hasPrefix:@"\"#"]) {
		[self _receivedGameListDirective:lobbyMessageDirective];
		return;
	}
	
  NSRange chopRange = NSMakeRange(1, [messageText length] - 2);
  NSString *unquoted = [messageText substringWithRange:chopRange];
  NSString *unescaped = [unquoted stringByReplacingOccurrencesOfRegex:@"\"\""
                                                           withString:@"\""];
	[self _incomingLobbyMessage:unescaped];
}

- (void)_receivedFirstLMDirectives:(AQNetacquireDirective *)bunchOfLMDirectives;
{
    NSAssert(bunchOfLMDirectives != nil, @"Passed in nil object.");
    
	[[self _firstAssociatedObjectThatRespondsToSelector:@selector(connectedToServer)] connectedToServer];
	
	_haveSeenFirstLMDirectives = YES;
	_handshakeComplete = YES;
	
	[self _handleDirective:bunchOfLMDirectives];
}

- (void)_receivedGameListDirective:(AQNetacquireDirective *)gameListDirective;
{
    NSAssert(gameListDirective != nil, @"Passed in nil object.");
    
	if (_objectRequestingGameListUpdate == nil)
		return;
	
	if (!_updatingGameList)
    _updatingGameList = [[NSMutableArray alloc] init];
  
	NSString *gameListString = [[gameListDirective parameters] objectAtIndex:0];
  NSString *regex = @"\"?\\s*->\\s*Game\\s*#([0-9]+)";
  NSString *gameNumber = [gameListString stringByMatching:regex capture:1];
  if (gameNumber)
    [_updatingGameList addObject:gameNumber];
  else if ([gameListString isMatchedByRegex:@"\"?# End of game list."])
  {
  	if ([_objectRequestingGameListUpdate respondsToSelector:@selector(updatedGameList:)]) {
  		[_objectRequestingGameListUpdate updatedGameList:_updatingGameList];
  	}
    [_updatingGameList release];
    _updatingGameList = nil;
		_objectRequestingGameListUpdate = nil;
  }
}

- (void)_receivedMDirective:(AQNetacquireDirective *)messageDirective;
{
    NSAssert(messageDirective != nil, @"Passed in nil object.");
    
	if ([[messageDirective parameters] count] != 1)
		return;
	
	NSString *message = [[messageDirective parameters] objectAtIndex:0];
	
	if ([message length] < 17)
		return;
	
	if ([[message substringToIndex:17] isEqualToString:@"\"W;Test Mode Used"]) {
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(enteringTestMode)] enteringTestMode];
		return;
	}
	
	if ([message length] < 23)
		return;
	
	if ([[message substringToIndex:23] isEqualToString:@"\"W;Test mode turned on."]) {
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(enteringTestMode)] enteringTestMode];
		return;
	}
	
	if ([message length] < 24)
		return;
	
	if ([[message substringToIndex:24] isEqualToString:@"\"W;Test mode turned off."]) {
		[[self _firstAssociatedObjectThatRespondsToSelector:@selector(exitingTestMode)] exitingTestMode];
		return;
	}
	
	if ([message length] < 26)
		return;
	
	if ([[message substringToIndex:26] isEqualToString:@"\"E;Duplicate user Nickname"]) {
		id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(displayNameAlreadyInUse)];
		if (associatedObject != nil)
			[associatedObject displayNameAlreadyInUse];
		
		return;
	}
}

- (void)_receivedPIDirective:(AQNetacquireDirective *)pingDirective;
{
    NSAssert(pingDirective != nil, @"Passed in nil object.");
    
	if ([[pingDirective parameters] count] != 1)
		return;
	
	// In theory, we should pull current time and so on. I think.
	// In reality, screw it.
	[self _sendPRDirectiveWithTimestamp:[[pingDirective parameters] objectAtIndex:0]];
}

- (void)_receivedSBDirective:(AQNetacquireDirective *)setBoardStatusDirective;
{
    NSAssert(setBoardStatusDirective != nil, @"Passed in nil object.");
    
	if ([[setBoardStatusDirective parameters] count] != 2)
		return;

	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(boardTileAtNetacquireID:isNetacquireChainID:)];
	[associatedObject boardTileAtNetacquireID:[[[setBoardStatusDirective parameters] objectAtIndex:0] intValue] isNetacquireChainID:[[[setBoardStatusDirective parameters] objectAtIndex:1] intValue]];
}

- (void)_receivedSPDirective:(AQNetacquireDirective *)startPlayerDirective;
{
    NSAssert(startPlayerDirective != nil, @"Passed in nil object.");
    
	if ([[startPlayerDirective parameters] count] == 0)
		return;
	
	NSRange versionInfoRange = NSMakeRange(0, [[startPlayerDirective parameters] count] - 1);
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(localPlayerName)];
	if (associatedObject == nil)
		return;
	
	[self _sendPLDirectiveWithDisplayName:[associatedObject localPlayerName] versionStrings:[[startPlayerDirective parameters] subarrayWithRange:versionInfoRange]];
}

- (void)_receivedSSDirective:(AQNetacquireDirective *)setStateDirective;
{
    NSAssert(setStateDirective != nil, @"Passed in nil object.");
    
	if ([[setStateDirective parameters] count] != 1)
		return;
	
	if ([[[setStateDirective parameters] objectAtIndex:0] intValue] == 4) {
		id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(joiningGame:)];
		[associatedObject joiningGame:_creatingGame];
		_creatingGame = NO;
	}
}

- (void)_receivedSVDirective:(AQNetacquireDirective *)setValueDirective;
{
    NSAssert(setValueDirective != nil, @"Passed in nil object.");
    
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
		int shares = [netacquireCaption length] == 0 ? 0 : [netacquireCaption intValue];
		
		id associatedObject;
		
		if (netacquireTableIndex >= 33 && netacquireTableIndex <= 38) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasSacksonShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 33) hasSacksonShares:shares];
			return;			
		}
		
		if (netacquireTableIndex >= 40 && netacquireTableIndex <= 45) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasZetaShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 40) hasZetaShares:shares];
			return;			
		}
		
		if (netacquireTableIndex >= 47 && netacquireTableIndex <= 52) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasAmericaShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 47) hasAmericaShares:shares];
			return;			
		}
		
		if (netacquireTableIndex >= 54 && netacquireTableIndex <= 59) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasFusionShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 54) hasFusionShares:shares];
			return;			
		}
		
		if (netacquireTableIndex >= 61 && netacquireTableIndex <= 66) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasHydraShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 61) hasHydraShares:shares];
			return;			
		}
		
		if (netacquireTableIndex >= 68 && netacquireTableIndex <= 73) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasQuantumShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 68) hasQuantumShares:shares];
			return;			
		}
		
		if (netacquireTableIndex >= 75 && netacquireTableIndex <= 80) {
			associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(playerAtIndex:hasPhoenixShares:)];
			[associatedObject playerAtIndex:(netacquireTableIndex - 75) hasPhoenixShares:shares];
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
}

#pragma mark 
#pragma mark Outoing Netacquire directive handling

- (void)_sendDirectiveData:(NSData *)data;
{
    NSAssert(data != nil, @"Passed in nil object.");
    
	[_socket writeData:data withTimeout:20.0 tag:0];
}

- (void)_sendDirectiveWithCode:(NSString *)directiveCode;
{
    NSAssert(directiveCode != nil, @"Passed in nil object.");
    
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:directiveCode];
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendBMDirectiveToLobbyWithMessage:(NSString *)message;
{
    NSAssert(message != nil, @"Passed in nil object.");
  
  [self _broadcastMessage:message to:@"Lobby"];
}

- (void)_sendBMDirectiveToGameRoomWithMessage:(NSString *)message;
{
    NSAssert(message != nil, @"Passed in nil object.");
    
  [self _broadcastMessage:message to:@"Game Room"];
}

- (void)_broadcastMessage:(NSString *)message to:(NSString *)destination
{
  NSAssert(message && destination, @"Passed in nil object.");
  
  NSString *escaped = [message stringByReplacingOccurrencesOfRegex:@"\""
                                                        withString:@"\"\""];
  AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"BM"];
	[directive addParameter:destination];
	[directive addParameter:[NSString stringWithFormat:@"\"%@\"", escaped]];
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
    NSAssert(parameters != nil, @"Passed in nil object.");
    
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"P"];
	[directive addParameters:parameters];
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendPLDirectiveWithDisplayName:(NSString *)displayName versionStrings:(NSArray *)versionStrings;
{
    NSAssert(displayName != nil && versionStrings != nil, @"Passed in nil object.");
    
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"PL"];
	[directive addParameter:displayName];
	[directive addParameters:versionStrings];
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendPRDirectiveWithTimestamp:(NSString *)timestamp;
{
    NSAssert(timestamp != nil, @"Passed in nil object.");
    
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"PR"];
	[directive addParameter:timestamp];
	[self _sendDirectiveData:[directive protocolData]];
}

- (void)_sendPTDirectiveWithIndex:(int)index;
{
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

- (void)_incomingLobbyMessage:(NSString *)lobbyMessage;
{
    NSAssert(lobbyMessage != nil, @"Passed in nil object.");
    
	id associatedObject = [self _firstAssociatedObjectThatRespondsToSelector:@selector(incomingLobbyMessage:)];
	[associatedObject incomingLobbyMessage:lobbyMessage];
}
@end

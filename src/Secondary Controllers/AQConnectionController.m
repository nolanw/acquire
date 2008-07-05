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
- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective;
- (void)_receivedFirstLMDirectives:(AQNetacquireDirective *)bunchOfLMDirectives;
- (void)_receivedSPDirective:(AQNetacquireDirective *)startPlayerDirective;

// And outgoing directives
- (void)_sendBMDirectiveWithMessage:(NSString *)message;
- (void)_sendPLDirectiveWithDisplayName:(NSString *)displayName versionStrings:(NSArray *)versionStrings;

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
	_haveSeenFirstLMDirectives = NO;
	
	_socket = [[AsyncSocket alloc] initWithDelegate:self];
	
	if (![_socket connectToHost:host onPort:port error:&_error])
		if ([_associatedObject respondsToSelector:@selector(connection:willDisconnectWithError:)])
			[_associatedObject connection:self willDisconnectWithError:_error];

	return self;
}

- (void)dealloc;
{
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


// Sending some outgoing mail
- (void)outgoingLobbyMessage:(NSString *)lobbyMessage;
{
	if ([lobbyMessage length] == 0)
		return;
	
	[self _sendBMDirectiveWithMessage:lobbyMessage];
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
	
	if ([_associatedObject respondsToSelector:@selector(connectedToServer)])
		[_associatedObject connectedToServer];
	
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
	if ([[directive directiveCode] isEqualToString:@"SP"]) {
		[self _receivedSPDirective:directive];
		return;
	}
	
	if ([[directive directiveCode] isEqualToString:@"LM"]) {
		if (_haveSeenFirstLMDirectives)
			[self _receivedLMDirective:directive];
		else {
			[self _receivedFirstLMDirectives:directive];
			_haveSeenFirstLMDirectives = YES;
		}
		
		return;
	}
}

- (void)_receivedLMDirective:(AQNetacquireDirective *)lobbyMessageDirective;
{
	[self _incomingLobbyMessage:[[[lobbyMessageDirective parameters] objectAtIndex:0] substringWithRange:NSMakeRange(1, [[[lobbyMessageDirective parameters] objectAtIndex:0] length] - 2)]];
}

- (void)_receivedFirstLMDirectives:(AQNetacquireDirective *)bunchOfLMDirectives;
{
	NSLog(@"%s %@", _cmd, bunchOfLMDirectives);
	NSString *bunchOfLMDirectivesString = [[bunchOfLMDirectives parameters] objectAtIndex:0];
	bunchOfLMDirectivesString = [bunchOfLMDirectivesString substringFromIndex:1];
	NSRange firstLobbyMessageRange = [bunchOfLMDirectivesString rangeOfString:@"\""];
	firstLobbyMessageRange.length = firstLobbyMessageRange.location - 1;
	firstLobbyMessageRange.location = 0;
	
	[self _incomingLobbyMessage:[bunchOfLMDirectivesString substringWithRange:firstLobbyMessageRange]];
	
	NSRange secondLobbyMessageRange = [bunchOfLMDirectivesString rangeOfString:@"LM"];
	secondLobbyMessageRange.location += 4;
	secondLobbyMessageRange.length = [bunchOfLMDirectivesString length] - secondLobbyMessageRange.location - 1;
	bunchOfLMDirectivesString = [bunchOfLMDirectivesString substringWithRange:secondLobbyMessageRange];
	
	secondLobbyMessageRange = [bunchOfLMDirectivesString rangeOfString:@"\""];
	secondLobbyMessageRange.length = secondLobbyMessageRange.location - 1;
	secondLobbyMessageRange.location = 0;
	
	[self _incomingLobbyMessage:[bunchOfLMDirectivesString substringWithRange:secondLobbyMessageRange]];
}

- (void)_receivedSPDirective:(AQNetacquireDirective *)startPlayerDirective;
{
	if ([[startPlayerDirective parameters] count] == 0) {
		NSLog(@"%s version string was empty!", _cmd);
		return;
	}
	
	NSRange versionInfoRange = NSMakeRange(0, [[startPlayerDirective parameters] count] - 1);
	[self _sendPLDirectiveWithDisplayName:[(AQAcquireController *)_associatedObject localPlayersName] versionStrings:[[startPlayerDirective parameters] subarrayWithRange:versionInfoRange]];
}



// And outgoing directives
- (void)_sendBMDirectiveWithMessage:(NSString *)message;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"BM"];
	[directive addParameter:@"Lobby"];
	[directive addParameter:[NSString stringWithFormat:@"\"%@\"", message]];
	
	[_socket writeData:[directive protocolData] withTimeout:20.0 tag:0];
}
- (void)_sendPLDirectiveWithDisplayName:(NSString *)displayName versionStrings:(NSArray *)versionStrings;
{
	AQNetacquireDirective *directive = [[[AQNetacquireDirective alloc] init] autorelease];
	[directive setDirectiveCode:@"PL"];
	[directive addParameter:displayName];
	[directive addParameters:versionStrings];
	
	[_socket writeData:[directive protocolData] withTimeout:20.0 tag:0];
}


// And their supporting cast
- (void)_incomingLobbyMessage:(NSString *)lobbyMessage;
{
	NSLog(@"%s %@", _cmd, lobbyMessage);
	if ([_associatedObject respondsToSelector:@selector(incomingLobbyMessage:)])
		[_associatedObject incomingLobbyMessage:lobbyMessage];
}
@end

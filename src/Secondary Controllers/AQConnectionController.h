// AQConnectionController.h
// ConnectionController manages a single AsyncSocket instance and keeps its associated ConnectionArrayController apprised of its status.
//
// Created May 27, 2008 by nwaite

#import "AsyncSocket.h"

@interface AQConnectionController : NSObject
{
	AsyncSocket	*_socket;
	id			_arrayController;
	id			_associatedObject;
	NSError		*_error;
	BOOL		_haveSeenFirstLMDirectives;
}

- (id)initWithHost:(NSString *)host port:(UInt16)port for:(id)sender arrayController:(id)arrayController;
- (void)dealloc;

// Accessors/setters/etc.
- (id)associatedObject;
- (NSError *)error;
- (BOOL)isServerConnection;
- (void)close;

// Sending some outgoing mail
- (void)outgoingLobbyMessage:(NSString *)lobbyMessage;

// AsyncSocket delegate selectors
- (void)onSocket:(AsyncSocket *)socket willDisconnectWithError:(NSError *)err;
- (void)onSocketDidDisconnect:(AsyncSocket *)socket;
- (void)onSocket:(AsyncSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)onSocket:(AsyncSocket *)socket didReadData:(NSData *)data withTag:(long)tag;
- (void)onSocket:(AsyncSocket *)socket didWriteDataWithTag:(long)tag;
@end

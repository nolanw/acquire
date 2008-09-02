// AQConnectionController.h
// ConnectionController manages a single AsyncSocket instance and keeps its associated ConnectionArrayController apprised of its status.
//
// Created May 27, 2008 by nwaite

#import "AsyncSocket.h"

@interface AQConnectionController : NSObject
{
	AsyncSocket	*_socket;
	id			_arrayController;
	NSError		*_error;
	BOOL		_handshakeComplete;
	BOOL		_haveSeenFirstLMDirectives;
	id			_objectRequestingGameListUpdate;
	
	NSMutableArray	*_associatedObjects;
}

- (id)initWithHost:(NSString *)host port:(UInt16)port for:(id)sender arrayController:(id)arrayController;
- (void)dealloc;

// Accessors/setters/etc.
- (void)registerAssociatedObject:(id)newAssociatedObject;
- (void)registerAssociatedObjectAndPrioritize:(id)newPriorityAssociatedObject;
- (void)deregisterAssociatedObject:(id)oldAssociatedObject;
- (NSError *)error;
- (BOOL)isServerConnection;
- (void)close;
- (BOOL)isConnected;
- (NSString *)connectedHostOrIPAddress;

- (void)joinGame:(int)gameNumber;
- (void)leaveGame;
- (void)disconnectFromServer;

// Sending some outgoing mail
- (void)outgoingLobbyMessage:(NSString *)lobbyMessage;
- (void)outgoingGameMessage:(NSString *)gameMessage;
- (void)updateGameListFor:(id)anObject;
- (void)retryUpdateGameList:(NSTimer *)aTimer;
- (void)playTileAtRackIndex:(int)rackIndex;
- (void)choseChainID:(int)chainID selectionType:(int)selectionType;
- (void)purchaseShares:(NSArray *)pDirectiveParameters;

// AsyncSocket delegate selectors
- (void)onSocket:(AsyncSocket *)socket willDisconnectWithError:(NSError *)err;
- (void)onSocketDidDisconnect:(AsyncSocket *)socket;
- (void)onSocket:(AsyncSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)onSocket:(AsyncSocket *)socket didReadData:(NSData *)data withTag:(long)tag;
- (void)onSocket:(AsyncSocket *)socket didWriteDataWithTag:(long)tag;
@end

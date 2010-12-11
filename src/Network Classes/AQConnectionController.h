/// A class that controls a single connection to a Netacquire server or client.
/**
 * ConnectionController knows about nearly all of the Netacquire protocol. It 
 * reacts to incoming directives by calling a given selector on the first 
 * associated object that responds to this selector.
 * A full list of those selectors and directives would be handy.
 */

#import "AsyncSocket.h"

#pragma mark -

@interface AQConnectionController : NSObject
#pragma mark Interface

{
	AsyncSocket	    *_socket;
	id		    	_arrayController;
	NSError	    	*_error;
	BOOL	    	_handshakeComplete;
	BOOL	    	_haveSeenFirstLMDirectives;
	id		    	_objectRequestingGameListUpdate;
  NSMutableArray *_updatingGameList;
	BOOL		    _creatingGame;
	NSMutableArray	*_associatedObjects;
}

#pragma mark 
#pragma mark init/dealloc

/**
 * Init method for connecting to a server.
 * @param host the server's hostname or IP (v4 or v6) address.
 * @param port the port on which the server is listening
 * @param sender an initial associated object; cannot be nil.
 * @param arrayController the array controller that handles this connection.
 * @return a nicely set up connection controller.
 */
- (id)initWithHost:(NSString *)host port:(UInt16)port for:(id)sender arrayController:(id)arrayController;

- (void)dealloc;

#pragma mark 
#pragma mark Accessors/setters/etc.

- (NSError *)error;
- (BOOL)isServerConnection;
- (BOOL)isConnected;
- (NSString *)connectedHostOrIPAddress;
- (void)disconnectFromServer;
- (void)close;

#pragma mark 
#pragma mark Associated object management

- (void)registerAssociatedObject:(id)newAssociatedObject;
- (void)registerAssociatedObjectAndPrioritize:(id)newPriorityAssociatedObject;
- (void)deregisterAssociatedObject:(id)oldAssociatedObject;

#pragma mark 
#pragma mark Outgoing server-processed actions.

- (void)updateGameListFor:(id)anObject;
- (void)retryUpdateGameList:(NSTimer *)aTimer;
- (void)outgoingLobbyMessage:(NSString *)lobbyMessage;
- (void)joinGame:(int)gameNumber;
- (void)createGame;
- (void)outgoingGameMessage:(NSString *)gameMessage;
- (void)startActiveGame;
- (void)playTileAtRackIndex:(int)rackIndex;
- (void)choseHotelToCreate:(int)newHotelNetacquireID;
- (void)purchaseShares:(NSArray *)sharesPurchasedAsParameters;
- (void)selectedMergeSurvivor:(int)survivingHotelNetacquireID;
- (void)mergerSharesSold:(int)sharesSold sharesTraded:(int)sharesTraded;
- (void)purchaseSharesAndEndGame:(NSArray *)sharesPurchasedAsParameters;
- (void)leaveGame;

#pragma mark 
#pragma mark AsyncSocket delegate selectors

- (void)onSocket:(AsyncSocket *)socket willDisconnectWithError:(NSError *)err;
- (void)onSocketDidDisconnect:(AsyncSocket *)socket;
- (void)onSocket:(AsyncSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)onSocket:(AsyncSocket *)socket didReadData:(NSData *)data withTag:(long)tag;
- (void)onSocket:(AsyncSocket *)socket didWriteDataWithTag:(long)tag;
@end

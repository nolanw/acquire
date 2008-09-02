@interface AQLobbyWindowController : NSObject
{
	id	_acquireController;
	
	IBOutlet NSWindow	*_lobbyWindow;
	IBOutlet NSDrawer	*_gameListDrawer;
	
	// Lobby chat
	IBOutlet NSTextView		*_lobbyChatTextView;
	IBOutlet NSTextField	*_messageToLobbyTextField;
	
	// Game list
	IBOutlet NSMatrix	*_gameListMatrix;
	
	NSTimer	*_gameListUpdateTimer;
}

- (id)initWithAcquireController:(id)acquireController;
- (void)dealloc;

// Window visibility
- (void)closeLobbyWindow;
- (void)bringLobbyWindowToFront;

// UI button actions
- (IBAction)sendLobbyMessage:(id)sender;
- (IBAction)createNewGame:(id)sender;
- (IBAction)joinGame:(id)sender;
- (void)leftGame;

- (void)incomingLobbyMessage:(NSString *)LobbyMessage;
- (void)requestGameListUpdate:(NSTimer *)theTimer;
- (void)beginScheduledGameListUpdates;
- (void)invalidateGameListUpdateTimer;
- (void)updatedGameList:(NSArray *)gameList;
- (void)updateWindowTitle;
- (void)resetLobbyMessages;
@end

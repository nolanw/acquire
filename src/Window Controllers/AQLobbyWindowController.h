@interface AQLobbyWindowController : NSObject
{
	IBOutlet id			_acquireController;
	IBOutlet NSWindow	*_lobbyWindow;
	IBOutlet NSDrawer	*_gameListDrawer;
	
	// Lobby chat
	IBOutlet NSTextView		*_lobbyChatTextView;
	IBOutlet NSTextField	*_messageToLobbyTextField;
	
	// Game list
	IBOutlet NSMatrix	*_gameListMatrix;
	
	NSTimer	*_gameListUpdateTimer;
}

- (id)init;
- (void)dealloc;

// NSObject (NSNibAwakening)
- (void)awakeFromNib;

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
- (void)updatedGameList:(NSArray *)gameList;
@end

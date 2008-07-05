@interface AQLobbyWindowController : NSObject
{
	IBOutlet id			_acquireController;
	IBOutlet NSWindow	*_lobbyWindow;
	IBOutlet NSDrawer	*_gameListDrawer;
	
	// Lobby chat
	IBOutlet NSTextView		*_lobbyChatTextView;
	IBOutlet NSScrollView	*_lobbyChatScrollView;
	IBOutlet NSTextField	*_messageToLobbyTextField;
	
	// Game list
	IBOutlet NSMatrix	*_gameListMatrix;
}

- (id)init;

// NSObject (NSNibAwakening)
- (void)awakeFromNib;

// Window visibility
- (void)closeLobbyWindow;
- (void)bringLobbyWindowToFront;

// UI button actions
- (IBAction)sendLobbyMessage:(id)sender;
- (IBAction)createNewGame:(id)sender;
- (IBAction)joinGame:(id)sender;

- (void)incomingLobbyMessage:(NSString *)chatMessage;
@end

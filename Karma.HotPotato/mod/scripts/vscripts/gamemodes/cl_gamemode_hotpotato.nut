global function ClGamemodeHotPotato_Init
global function ServerCallback_ShowHotPotatoCountdown
global function ServerCallback_AnnounceFirstMarked

struct {
	var countdownRui
} file

void function ClGamemodeHotPotato_Init()
{
	ClGameState_RegisterGameStateAsset( $"ui/gamestate_info_lts.rpak" )
}

void function ServerCallback_ShowHotPotatoCountdown( float endTime )
{
	file.countdownRui = CreateCockpitRui( $"ui/dropship_intro_countdown.rpak", 0 )
	RuiSetResolutionToScreenSize( file.countdownRui )
	RuiSetGameTime( file.countdownRui, "gameStartTime", endTime )
}

void function ServerCallback_AnnounceNewMark( int survivorEHandle )
{
    entity player = GetEntityFromEncodedEHandle( survivorEHandle )

	AnnouncementData announcement = Announcement_Create( Localize("#HOTPOTATO_NEWMARK", player.GetPlayerName() ) )
	Announcement_SetSubText( announcement, "#HOTPOTATO_RUN" )
	Announcement_SetTitleColor( announcement, <1,0,0> )
	Announcement_SetPurge( announcement, true )
	Announcement_SetPriority( announcement, 200 ) //Be higher priority than Titanfall ready indicator etc
	Announcement_SetSoundAlias( announcement, SFX_HUD_ANNOUNCE_QUICK )
	Announcement_SetStyle( announcement, ANNOUNCEMENT_STYLE_QUICK )
	AnnouncementFromClass( GetLocalViewPlayer(), announcement )
}


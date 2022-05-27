global function GamemodeHotPotato_Init

struct
{
    bool firstmarked
    float hotpotatobegin
    float hotpotatoend
    entity marked
} file

void function GamemodeHotPotato_Init()
{
	SetSpawnpointGamemodeOverride( FFA )

	SetShouldUseRoundWinningKillReplay( true )
	SetLoadoutGracePeriodEnabled( false ) // prevent modifying loadouts with grace period
	SetWeaponDropsEnabled( false )
	SetRespawnsEnabled( false )
	Riff_ForceTitanAvailability( eTitanAvailability.Never )
	Riff_ForceBoostAvailability( eBoostAvailability.Disabled )
	ClassicMP_ForceDisableEpilogue( true )

	AddCallback_OnClientConnected( HotPotatoInitPlayer )
	AddCallback_OnPlayerRespawned( UpdateLoadout )
    AddCallback_GameStateEnter( eGameState.Playing, HotPotatoInit )

    AddDamageCallback( "player", MarkNewPlayer )
}

void function HotPotatoInit()
{
    thread HotPotatoInitCountdown()
}

void function HotPotatoInitCountdown()
{
    wait 10
    
    entity player = GetPlayerArray()[ RandomInt( 0, GetPlayerArray().length - 1 ) ]
    thread MarkRandomPlayer(player)
}

// give them a red outline to indicate they have the potato, also give them the ability to melee other players to pass the outline
void function MarkRandomPlayer(entity player)
{
    if (!IsAlive(player) && !IsValid(player))
    {
        MarkRandomPlayer( GetPlayerArray()[ RandomInt( 0, GetPlayerArray().length - 1 ) ] )
        return
    }

    file.hotpotatobegin() = Time()

    foreach ( entity p in GetPlayerArray() )
    {
		Highlight_ClearEnemyHighlight(p)
	    Remote_CallFunction_NonReplay( p, "ServerCallback_ShowHotPotatoCountdown", file.hotpotatobegin + file.hotpotatoend )
	    Remote_CallFunction_NonReplay( p, "ServerCallback_AnnounceNewMark", player.GetEncodedEHandle() )
    }

	Highlight_SetEnemyHighlight( player, "enemy_boss_bounty" ) // red outline
    file.marked = player
    thread HotPotatoCountdown()
}

void function HotPotatoCountdown()
{
    // wait until Time() reaches file.hotpotatoend
    while ( Time() < file.hotpotatobegin + file.hotpotatoend )
    {
        wait 1
    }
    
    // kill player once timer runs out
    entity player = file.marked
    if (!IsValid(player) && !IsAlive(player))
    {
        wait 10
        MarkRandomPlayer( GetPlayerArray()[ RandomInt( 0, GetPlayerArray().length - 1 ) ] )
        return
    }

    player.Die( null, null, { scriptType = DF_GIB } )
    wait 10
    MarkRandomPlayer( GetPlayerArray()[ RandomInt( 0, GetPlayerArray().length - 1 ) ] )
}

void function MarkNewPlayer( entity victim, var damageInfo )
{
    entity attacker = DamageInfo_GetAttacker( damageInfo )
    if (!IsValid(attacker) && !IsValid(victim) && victim == attacker)
        return

    float damage = DamageInfo_GetDamage( damageInfo )
    damage = 0
    DamageInfo_SetDamage( damageInfo, damage )

    if (attacker == file.marked)
    {
        file.marked = victim
        foreach ( entity p in GetPlayerArray() )
		    Highlight_ClearEnemyHighlight(p)
        Highlight_SetEnemyHighlight( victim, "enemy_boss_bounty" )
        SetRoundWinningKillReplayAttacker(attacker)
    }
}

void function HotPotatoInitPlayer( entity player )
{
	UpdateLoadout( player )
}

void function UpdateLoadout( entity player )
{
	if (IsAlive(player) && player != null)
	{
		// set loadout
		foreach ( entity weapon in player.GetMainWeapons() )
			player.TakeWeaponNow( weapon.GetWeaponClassName() )

		foreach ( entity weapon in player.GetOffhandWeapons() )
			player.TakeWeaponNow( weapon.GetWeaponClassName() )

		player.GiveOffhandWeapon( "melee_pilot_emptyhanded", OFFHAND_MELEE, [ "allow_as_primary" ])

		player.SetActiveWeaponByName( "melee_pilot_emptyhanded" )
	}
}

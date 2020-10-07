#include <sourcemod>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "Show DMG",
	author = "-_- (Karol Skupień)",
	description = "Show DMG",
	version = "1.0",
	url = "https://forum.cs-classic.pl/"
};

int g_Mode[ MAXPLAYERS ], g_HUD[ MAXPLAYERS ];
Handle gc_ClientMode;

public void OnPluginStart(/*void*/) {
	LoadTranslations("t_showdamage.phrases");
	RegConsoleCmd("sm_dmg", cmd_ShowDamage, "Menu Show Damage");
	HookEvent("player_hurt", ev_PlayerHurt, EventHookMode_Post);

	gc_ClientMode = RegClientCookie("showdamage_mode", "Show Damage Mode", CookieAccess_Private);
	for(int i = 1; i <= MaxClients; i++)
	{
		if ( !IsClientInGame(i) || !AreClientCookiesCached(i) )
			continue;
		
		OnClientCookiesCached(i);
	}
}

public void OnClientCookiesCached(int iClient) {
	char sValue[4];
	GetClientCookie(iClient, gc_ClientMode, sValue, sizeof(sValue));
	g_Mode[iClient] = StringToInt(sValue);
}


public Action cmd_ShowDamage(int iClient, int iArgs) {
	if ( !IsValidClient(iClient) )
		return Plugin_Continue;

	MenuShowDamage(iClient);
	return Plugin_Continue;
}

public void MenuShowDamage(int iClient) {
	char sMenu[128];
	Menu mMenu = new Menu(MenuShowDamage_H);

	mMenu.SetTitle("%t", "SHOWDAMAGE_TITLE");

	FormatEx(sMenu, sizeof(sMenu), "%t", "SHOWDAMAGE_HUD");
	mMenu.AddItem("0", sMenu, !g_Mode[iClient] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(sMenu, sizeof(sMenu), "%t", "SHOWDAMAGE_CHAT");
	mMenu.AddItem("1", sMenu, g_Mode[iClient] == 1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	FormatEx(sMenu, sizeof(sMenu), "%t", "SHOWDAMAGE_HINT");
	mMenu.AddItem("2", sMenu, g_Mode[iClient] == 2 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	mMenu.Display(iClient, 30);
}
public int MenuShowDamage_H(Menu mMenu, MenuAction mAction, int iClient, int iParam) {
	if ( mAction == MenuAction_End ) {
		delete mMenu;
	} else if ( mAction == MenuAction_Select ) {
		char sInfo[4];
		mMenu.GetItem(iParam, sInfo, sizeof(sInfo));
		int iValue = StringToInt(sInfo);

		SetClientCookie(iClient, gc_ClientMode, sInfo);
		g_Mode[iClient] = iValue;
	}
	return 0;
}


public Action ev_PlayerHurt(Event eEvent, const char[] sName, bool bDontBroadcast) {
	int iVictim = GetClientOfUserId(eEvent.GetInt("userid"));
	int iAttacker = GetClientOfUserId(eEvent.GetInt("attacker"));
	int iDamage = eEvent.GetInt("dmg_health");
	int iDamageArmor = eEvent.GetInt("dmg_armor");

	if ( !IsValidClient(iAttacker) || !IsValidClient(iVictim) || GetClientTeam(iVictim) == GetClientTeam(iAttacker) || iDamage <= 0 )
		return Plugin_Continue;

	switch(g_Mode[iAttacker])
	{
		case 0 :
		{
			float x = -1.0, y = -1.0;
			switch(g_HUD[iAttacker])
			{
				case 0 : { x = -1.0; y = 0.4; }
				case 1 : { x = 0.55; y = 0.4; }
				case 2 : { x = 0.55; y = 0.45; }
				case 3 : { x = 0.55; y = 0.5; }
				case 4 : { x = 0.55; y = 0.55; }
				case 5 : { x = -1.0; y = 0.55; }
				case 6 : { x = 0.4; y = 0.55; }
				case 7 : { x = 0.4; y = 0.5; }
				case 8 : { x = 0.4; y = 0.45; }
				case 9 : { x = 0.4; y = 0.4; }
			}

			int iHP = GetClientHealth(iVictim);
			if ( iHP < 0 ) iHP = 0;

			if ( iHP > 60 ) SetHudTextParams(x, y, 1.3, 0, 255, 0, 200, 1);
			else if ( iHP > 30 ) SetHudTextParams(x, y, 1.3, 255, 138, 0, 200, 1);
			else SetHudTextParams(x, y, 1.3, 255, 0, 0, 200, 1);

			ShowHudText(iAttacker, -1, "%i", iDamage);

			if ( ++g_HUD[iAttacker] >= 9 ) g_HUD[iAttacker] = 0;
		}
		case 1 : PrintToChat(iAttacker, "-\x04%i HP (-%d armor) %N", iDamage, iDamageArmor, iVictim);
		case 2 : PrintHintText(iAttacker, "-%i HP (-%d armor) %N", iDamage, iDamageArmor, iVictim);
	}
	return Plugin_Continue;
}

bool IsValidClient(int iClient) {
	return iClient > 0 && iClient <= MaxClients && IsClientConnected(iClient) && IsClientInGame(iClient);
}

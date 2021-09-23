#include <sourcemod>
#include <movementapi>
#include <gokz/core>
#include <clientprefs>
#include <more-stats>

#include "more-stats/globals.sp"
#include "more-stats/helpers.sp"
#include "more-stats/bhopstats.sp"
#include "more-stats/resetstats.sp"
#include "more-stats/airstats.sp"
#include "more-stats/databases.sp"
#include "more-stats/commands.sp"
#include "more-stats/natives.sp"

#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "More Stats",
	author = "Szwagi, zer0.k",
	description = "Tracks various KZ related statistics",
	version = "v2.3.0",
	url = "https://github.com/zer0k-z/more-stats"
};

// ===== [ PLUGIN EVENTS ] =====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("more-stats");
	gB_LateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	gH_MoreStatsCookie = RegClientCookie("morestats-cookie", "cookie for more-stats", CookieAccess_Private);
	RegisterCommands();
	SetupDatabase();
	SetupConVars();
	// Late-loading support
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && AreClientCookiesCached(client))
		{
			OnClientCookiesCached(client);
			InitializeClientStats(client);
			LoadClientStats(client);
		}
	}
}

public void OnPluginEnd()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			EndPerfStreak(client);
			SaveClientBhopStats(client);
			SaveClientResetStats(client);
			SaveClientAirStats(client);
		}
	}
}


// ===== [ CLIENT EVENTS ] =====

public void OnClientConnected(int client)
{
	InitializeClientStats(client);
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (IsFakeClient(client))
	{
		return;
	}

	LoadClientStats(client);
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}

	EndPerfStreak(client);
	SaveClientBhopStats(client);
	SaveClientResetStats(client);
	SaveClientAirStats(client);
}

public void OnClientCookiesCached(int client)
{
	InitializeClientStats(client);
	char buffer[2];
	GetClientCookie(client, gH_MoreStatsCookie, buffer, sizeof(buffer));
	gB_PostRunStats[client] = !!StringToInt(buffer[0]); // "a hack to convert the char to boolean"
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	OnPlayerRunCmd_BhopStats(client, buttons, cmdnum, tickcount);
	
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	OnPlayerRunCmdPost_AirStats(client, buttons, vel, angles);
	gB_OldOnGround[client] = Movement_GetOnGround(client);
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	GOKZ_OnOptionChanged_BhopStats(client, option);
}

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
	if (!gB_BhopStatsLoaded[client] || IsFakeClient(client))
	{
		return;
	}

	Movement_OnPlayerJump_BhopStats(client, jumpbug);
}

public Action GOKZ_OnTimerStart(int client, int course)
{
	GOKZ_OnTimerStart_ResetStats(client, course);
	return Plugin_Continue;
}

public void GOKZ_OnTimerStart_Post(int client, int course)
{
	GOKZ_OnTimerStart_Post_BhopStats(client);
	GOKZ_OnTimerStart_Post_AirStats(client);
}

public Action GOKZ_OnTimerEnd(int client, int course, float time, int teleportsUsed)
{
	GOKZ_OnTimerEnd_ResetStats(client, course, teleportsUsed);
	return Plugin_Continue;
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	if (gB_PostRunStats[client])
	{
		PrintToConsole(client, "Player: %N, Course: %i, Time: %f, TPs: %i", client, course, time, teleportsUsed);
		GOKZ_OnTimerEnd_Post_BhopStats(client);
		GOKZ_OnTimerEnd_Post_AirStats(client);
	}
}

// ===== [ HELPERS ] =====

void InitializeClientStats(int client)
{
	gB_SegmentPaused[client] = false;
	InitializeBhopStats(client);
	InitializeResetStats(client);
	InitializeAirStats(client);
}

void SetupConVars()
{
	gCV_sv_autobunnyhopping = FindConVar("sv_autobunnyhopping");
}
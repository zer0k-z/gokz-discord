#include <sourcemod>

#include <SteamWorks>
#include <json>
#include <discord>
#include <gokz/core>
#include <record>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

#include <gokz/localdb>
#include <gokz/localranks>
#include <gokz/global>
#include <updater>

#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN

#include "gokz-discord/globals.sp"
#include "gokz-discord/gokz-forwards.sp"
#include "gokz-discord/embeds.sp"

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "gokz-discord",
	author = "zer0.k",
	description = "",
	version = "1.0.7",
	url = "https://github.com/zer0k-z/gokz-discord"
};

#define UPDATER_URL "https://raw.githubusercontent.com/zer0k-z/gokz-discord2/updater/updatefile.txt"

public void OnPluginStart()
{
	InitGlobals();
	InitAnnounceTimer();
	RegConsoleCmd("sm_testdiscord", DiscordInit);
}

void InitGlobals()
{
	gA_Records = new ArrayList(sizeof(Record));
	gI_MinRankLocal = 10;
	gI_MinRankGlobal = 20;
	gB_AnnounceBonus = true;
}

public void OnAllPluginsLoaded()
{
	if (!LibraryExists("gokz-core"))
	{
		SetFailState("Missing required plugin: gokz-core");
	}

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}

	if (LibraryExists("gokz-global"))
	{
		gB_GOKZGlobal = true;
	}
	if (LibraryExists("gokz-localranks"))
	{
		gB_GOKZLocal = true;
	}
	
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	if (LibraryExists("gokz-global"))
	{
		gB_GOKZGlobal = true;
	}
	if (LibraryExists("gokz-localranks"))
	{
		gB_GOKZLocal = true;
	}
}

public Action Test(int client, int argc)
{
	return Plugin_Handled;
}

public Action DiscordInit(int client, int argc)
{
	Record record;
	record.Init(client, 1, 133333.37, 0);
	record.InitLocal(158416176, 1, 1, GOKZ_GetCoreOption(client, Option_Mode), 0, 133333.37, 0, false, 5.0, 1, 2, false, -5.0, 1, 2);
	record.InitGlobal(client, 1, GOKZ_GetCoreOption(client, Option_Mode), TimeType_Pro, 2, 2, 133333.37);
	gA_Records.PushArray(record, sizeof(Record));
	return Plugin_Handled;
}

void InitAnnounceTimer()
{
	CreateTimer(5.0, Timer_CheckRecord, INVALID_HANDLE, TIMER_REPEAT);
}

public Action Timer_CheckRecord(Handle timer)
{
	Record record;
	for (int i = 0; i < gA_Records.Length; i++)
	{
		gA_Records.GetArray(i, record, sizeof(Record));
		if (!gB_AnnounceBonus && record.course != 0)
		{
			gA_Records.Erase(i);
		}
		else if (record.matchedLocal && record.matchedGlobal)
		{
			DiscordAnnounceRecord(record);
			gA_Records.Erase(i);
		}
		else if (record.matchedLocal)
		{
			// Wait for timeout, or don't wait at all if there's no global plugin
			if (!gB_GOKZGlobal || record.timestamp + STEAMWORKS_HTTP_TIMEOUT_DURATION < GetTime())
			{
				// LocalDB: Only announce PB
				if (record.pbDiff < 0.0 || record.pbDiffPro < 0.0)
				{
					DiscordAnnounceRecord(record);
				}
				gA_Records.Erase(i);
			}
		}
		else if (record.matchedGlobal)
		{
			// Wait for some duration or don't wait at all if there's no local ranking
			if (!gB_GOKZLocal || record.timestamp + LOCAL_MAX_WAIT_TIME < GetTime())
			{
				DiscordAnnounceRecord(record);
				gA_Records.Erase(i);
			}
		}
		else if (record.timestamp + IntMax(LOCAL_MAX_WAIT_TIME, STEAMWORKS_HTTP_TIMEOUT_DURATION) < GetTime())
		{
			// This won't ever get announced, erase it
			gA_Records.Erase(i);
		}
	}
}
void DiscordAnnounceRecord(Record record)
{
	DiscordWebHook webHook = new DiscordWebHook("https://discord.com/api/webhooks/745258540490293268/IYPmFLixIdNuZf00jx_rD3sDvHoXApZ-_vSrCF3UNNVnOSetXutS_GTzfeDPZ38w_K3A");
	webHook.Embed(CreateEmbed(record));
	webHook.Send();
	webHook.Dispose();
}
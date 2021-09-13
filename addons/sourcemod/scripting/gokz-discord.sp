#include <sourcemod>

#include <SteamWorks>
#include <json>
#include <discord>
#include <gokz/core>
#include <record>
#include <autoexecconfig>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

#include <gokz/localdb>
#include <gokz/localranks>
#include <gokz/global>
#include <updater>

#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN

#include "gokz-discord/globals.sp"
#include "gokz-discord/helpers.sp"
#include "gokz-discord/gokz-forwards.sp"
#include "gokz-discord/embeds.sp"

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "gokz-discord",
	author = "zer0.k",
	description = "",
	version = "0.0.2",
	url = "https://github.com/zer0k-z/gokz-discord"
};

#define UPDATER_URL "https://raw.githubusercontent.com/zer0k-z/gokz-discord2/updater/updatefile.txt"

public void OnPluginStart()
{
	LoadTranslations("gokz-discord.phrases");
	CreateConVars();
	InitGlobals();
	InitAnnounceTimer();

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
}

static void CreateConVars()
{
	AutoExecConfig_SetFile("gokz-discord", "sourcemod/gokz");
	AutoExecConfig_SetCreateFile(true);
	
	gCV_UseLocalRank = AutoExecConfig_CreateConVar("gokz_discord_use_local", "1", "Whether local ranking is used.", _, true, 0.0, true, 1.0);

	gCV_UseGlobalRank = AutoExecConfig_CreateConVar("gokz_discord_use_global", "1", "Whether global ranking is used.", _, true, 0.0, true, 1.0);
	gCV_AnnounceBonus = AutoExecConfig_CreateConVar("gokz_discord_announce_bonus", "1", "Whether bonus runs are announced.", _, true, 0.0, true, 1.0);
	gCV_MinRankGlobal = AutoExecConfig_CreateConVar("gokz_discord_min_rank_global", "20", "Minimum rank for top time announcement (Global)", _, true, 1.0);
	gCV_MinRankLocal = AutoExecConfig_CreateConVar("gokz_discord_min_rank_local", "10", "Minimum rank for top time announcement (Local)", _, true, 1.0);
	gCV_MinRecordType = AutoExecConfig_CreateConVar("gokz_discord_min_record_type", "5", "Minimum record type for announcement", _, true, 1.0, true, float(RecordType_GlobalProWR));

	gCV_ShowCourse = AutoExecConfig_CreateConVar("gokz_discord_show_course", "1", "Show course id in the announcement", _, true, 0.0, true, 1.0);
	gCV_ShowRunTime = AutoExecConfig_CreateConVar("gokz_discord_show_run_time", "2", "Show run time in the announcement (0 = Disabled, 1 = Enable without Local PB Diff, 2 = Enable with Local PB Diff)", _, true, 0.0, true, 2.0);
	gCV_ShowThumbnail = AutoExecConfig_CreateConVar("gokz_discord_show_thumbnail", "1", "Show thumbnail in the announcement", _, true, 0.0, true, 1.0);
	gCV_ShowRank = AutoExecConfig_CreateConVar("gokz_discord_show_rank", "1", "Show rank in the announcement", _, true, 0.0, true, 1.0);
	gCV_ShowServer = AutoExecConfig_CreateConVar("gokz_discord_show_server", "1", "Show server in the announcement", _, true, 0.0, true, 1.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();	
}
static void InitGlobals()
{
	gA_Records = new ArrayList(sizeof(Record));

	gKV_DiscordConfig = new KeyValues("Discord");
	
	char sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/gokz-discord.cfg");

	if (!FileExists(sFile))
	{
		SetFailState("[GOKZ-Discord] \"%s\" not found!", sFile);
	}

	gKV_DiscordConfig.ImportFromFile(sFile);
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
		if (!gCV_AnnounceBonus.BoolValue && record.course != 0)
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
			if (!gB_GOKZGlobal || !gCV_UseGlobalRank.BoolValue || record.timestamp + STEAMWORKS_HTTP_TIMEOUT_DURATION < GetTime())
			{
				DiscordAnnounceRecord(record);
				gA_Records.Erase(i);
			}
		}
		else if (record.matchedGlobal)
		{
			// Wait for some duration or don't wait at all if there's no local ranking
			if (!gB_GOKZLocal || !gCV_UseLocalRank.BoolValue || record.timestamp + LOCAL_MAX_WAIT_TIME < GetTime())
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
	int recordType = record.GetRecordType(gCV_MinRankLocal.IntValue, gCV_MinRankGlobal.IntValue);
	if (recordType == RecordType_Default || recordType < gCV_MinRecordType.IntValue)
	{
		return;
	}
	char webHookURL[2048];
	GetWebHook(webHookURL, sizeof(webHookURL));
	DiscordWebHook webHook = new DiscordWebHook(webHookURL);
	webHook.Embed(CreateEmbed(record));
	webHook.Send();
	webHook.Dispose();
}
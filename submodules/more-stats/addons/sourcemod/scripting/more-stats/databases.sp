// ===== [ DATABASE ] =====

void SetupDatabase()
{
	char error[512];

	gH_DB = SQL_Connect("more-stats", true, error, sizeof(error));

	if (gH_DB == null)
	{
		SetFailState("Database connection failed. Error: \"%s\".", error);
	}

	Transaction txn = new Transaction();

	// Setup tables
	txn.AddQuery("CREATE TABLE IF NOT EXISTS BhopStats (" ...
		"SteamID32 INTEGER NOT NULL, " ...
		"Mode INTEGER NOT NULL, " ...
		"StatType1 INTEGER NOT NULL, " ...
		"StatType2 INTEGER NOT NULL, " ...
		"StatCount INTEGER NOT NULL, " ...
		"PRIMARY KEY(SteamID32, Mode, StatType1, StatType2))");

	txn.AddQuery("CREATE TABLE IF NOT EXISTS ResetStats (" ...
		"SteamID32 INTEGER NOT NULL, " ...
		"Map VARCHAR(128) NOT NULL, " ...
		"Course INTEGER NOT NULL, " ...
		"Mode INTEGER NOT NULL, " ...
		"ResetType INTEGER NOT NULL, " ...
		"ResetCount INTEGER NOT NULL, " ...
		"PRIMARY KEY(SteamID32, Course, Mode, Map, ResetType))");

	txn.AddQuery("CREATE TABLE IF NOT EXISTS AirStats (" ...
		"SteamID32 INTEGER NOT NULL, " ...
		"Mode INTEGER NOT NULL, " ...
		"AirType INTEGER NOT NULL, " ...
		"Count INTEGER NOT NULL, " ...
		"PRIMARY KEY(SteamID32, Mode, AirType))");

	gH_DB.Execute(txn, _, SQLTxnFailure_LogError, _, DBPrio_High);
}

void LoadClientStats(int client)
{
	int userid = GetClientUserId(client);
	int steamid = GetSteamAccountID(client);
	if (steamid == 0)
	{
		return;
	}

	LoadClientBhopStats(userid, steamid);
	LoadClientResetStats(userid, steamid);
	LoadClientAirStats(userid, steamid);
}

void LoadClientBhopStats(int userid, int steamid)
{
	char query[256];
	Transaction txn = new Transaction();

	FormatEx(query, sizeof(query), 
		"SELECT Mode, StatType1, StatType2, StatCount " ...
		"FROM BhopStats " ...
		"WHERE SteamID32 = %d", steamid);
	txn.AddQuery(query);

	gH_DB.Execute(txn, SQLTxnSuccess_LoadClientBhopStats, SQLTxnFailure_LogError, userid, DBPrio_Normal);
}

void LoadClientResetStats(int userid, int steamid)
{
	char query[256];
	Transaction txn = new Transaction();

	char map[32];
	GetCurrentMapDisplayName(map, sizeof(map));

	FormatEx(query, sizeof(query),
		"SELECT Course, Mode, ResetType, ResetCount " ...
		"FROM ResetStats " ...
		"WHERE SteamID32 = %d " ...
		"AND Map = '%s'", steamid, map);
	txn.AddQuery(query);
	gH_DB.Execute(txn, SQLTxnSuccess_LoadClientResetStats, SQLTxnFailure_LogError, userid, DBPrio_Normal);
}

void LoadClientResetStatsForMap(int userid, int steamid, char[] map, int course, int mode, int resetType)
{
	char query[256];
	Transaction txn = new Transaction();

	FormatEx(query, sizeof(query),
		"SELECT ResetCount, ResetType, Map " ...
		"FROM ResetStats " ...
		"WHERE SteamID32 = %d " ...
		"AND Course = %d " ...
		"AND Mode = %d " ...
		"AND Map LIKE '%%%s%%' "...
		"ORDER BY (Map='%s') DESC, LENGTH(Map) " ...
    	"LIMIT 1", steamid, course, mode, map, map);

	txn.AddQuery(query);
	if (resetType == ResetType_ResetCount)
	{
		gH_DB.Execute(txn, SQLTxnSuccess_LoadClientResetCountForMap, SQLTxnFailure_LogError, userid, DBPrio_Normal);
	}
	else if (resetType == ResetType_ResetCount)
	{
		gH_DB.Execute(txn, SQLTxnSuccess_LoadClientCompletionCountForMap, SQLTxnFailure_LogError, userid, DBPrio_Normal);
	}
	else
	{
		gH_DB.Execute(txn, SQLTxnSuccess_LoadClientProCompletionCountForMap, SQLTxnFailure_LogError, userid, DBPrio_Normal);
	}
}

void LoadClientAirStats(int userid, int steamid)
{
	char query[256];
	Transaction txn = new Transaction();

	FormatEx(query, sizeof(query), 
		"SELECT Mode, AirType, Count " ...
		"FROM AirStats " ...
		"WHERE SteamID32 = %d", steamid);
	txn.AddQuery(query);

	gH_DB.Execute(txn, SQLTxnSuccess_LoadClientAirStats, SQLTxnFailure_LogError, userid, DBPrio_Normal);
}

void SaveClientBhopStats(int client)
{
	int steamid = GetSteamAccountID(client);
	if (steamid == 0 || !gB_BhopStatsLoaded[client])
	{
		return;
	}

	char query[8192];
	char buffer[128];
	Transaction txn = new Transaction();

	FormatEx(query, sizeof(query), "DELETE FROM BhopStats WHERE SteamID32 = %d", steamid);
	txn.AddQuery(query);

	FormatEx(query, sizeof(query), "INSERT INTO BhopStats (SteamID32, Mode, StatType1, StatType2, StatCount) VALUES ");
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		for (int i = 0; i < MAX_BHOP_TICKS; i++)
		{
			FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d,%d),", steamid, mode, StatType_BhopStats, i, gI_BhopTicks[client][mode][i][Scope_AllTime]);
			StrCat(query, sizeof(query), buffer);
		}

		for (int i = 0; i < MAX_PERF_STREAK; i++)
		{
			FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d,%d),", steamid, mode, StatType_PerfStreaks, i, gI_PerfStreaks[client][mode][i][Scope_AllTime]);
			StrCat(query, sizeof(query), buffer);
		}

		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d,%d),", steamid, mode, StatType_ScrollEff, ScrollEff_RegisteredScrolls, gI_SumRegisteredScrolls[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d,%d),", steamid, mode, StatType_ScrollEff, ScrollEff_FastScrolls, gI_SumFastScrolls[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d,%d),", steamid, mode, StatType_ScrollEff, ScrollEff_SlowScrolls, gI_SumSlowScrolls[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d,%d),", steamid, mode, StatType_ScrollEff, ScrollEff_TimingTotal, gI_TimingTotal[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d,%d),", steamid, mode, StatType_ScrollEff, ScrollEff_TimingSamples, gI_TimingSamples[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);		
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d,%d),", steamid, mode, StatType_GOKZPerfCount, 0, gI_GOKZPerfCount[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);

	}

	query[strlen(query) - 1] = 0; // Remove last comma...
	txn.AddQuery(query);

	gH_DB.Execute(txn, _, SQLTxnFailure_LogError, _, DBPrio_Normal);
}

void SaveClientResetStats(int client)
{
	int steamid = GetSteamAccountID(client);
	if (steamid == 0 || !gB_BhopStatsLoaded[client])
	{
		return;
	}

	char query[2048];
	char buffer[128];
	Transaction txn = new Transaction();
	
	char map[32];
	GetCurrentMapDisplayName(map, sizeof(map));
	bool emptyQuery = true;

	FormatEx(query, sizeof(query), "DELETE FROM ResetStats WHERE SteamID32 = %d AND Map = '%s'", steamid, map);
	txn.AddQuery(query);

	FormatEx(query, sizeof(query), "INSERT INTO ResetStats (SteamID32, Map, Course, Mode, ResetType, ResetCount) VALUES ");

	for (int course = 0; course < GOKZ_MAX_COURSES - 1; course++)
	{
		for (int mode = 0; mode < MODE_COUNT; mode++)
		{
			if (gI_ResetCount[client][course][mode][Scope_AllTime] > 0)
			{
				emptyQuery = false;
				FormatEx(buffer, sizeof(buffer), "(%d,'%s',%d,%d,%d,%d),", steamid, map, course, mode, ResetType_ResetCount, gI_ResetCount[client][course][mode][Scope_AllTime]);
				StrCat(query, sizeof(query), buffer);
			}
			if (gI_CompletionCount[client][course][mode][Scope_AllTime] > 0)
			{
				emptyQuery = false;
				FormatEx(buffer, sizeof(buffer), "(%d,'%s',%d,%d,%d,%d),", steamid, map, course, mode, ResetType_CompletionCount, gI_CompletionCount[client][course][mode][Scope_AllTime]);
				StrCat(query, sizeof(query), buffer);
			}
			if (gI_ProCompletionCount[client][course][mode][Scope_AllTime] > 0)
			{
				emptyQuery = false;
				FormatEx(buffer, sizeof(buffer), "(%d,'%s',%d,%d,%d,%d),", steamid, map, course, mode, ResetType_ProCompletionCount, gI_ProCompletionCount[client][course][mode][Scope_AllTime]);
				StrCat(query, sizeof(query), buffer);
			}
		}
	}
	query[strlen(query) - 1] = 0;
	txn.AddQuery(query);
	if (!emptyQuery)
	{
		gH_DB.Execute(txn, _, SQLTxnFailure_LogError, _, DBPrio_Normal);
	}
}

void SaveClientAirStats(int client)
{
	int steamid = GetSteamAccountID(client);
	if (steamid == 0 || !gB_BhopStatsLoaded[client])
	{
		return;
	}

	char query[8192];
	char buffer[128];
	Transaction txn = new Transaction();

	FormatEx(query, sizeof(query), "DELETE FROM AirStats WHERE SteamID32 = %d", steamid);
	txn.AddQuery(query);

	FormatEx(query, sizeof(query), "INSERT INTO AirStats (SteamID32, Mode, AirType, Count) VALUES ");
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, mode, AirType_AirTime, gI_AirTime[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, mode, AirType_Strafes, gI_Strafes[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, mode, AirType_OverLap, gI_Overlap[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, mode, AirType_DeadAir, gI_DeadAir[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, mode, AirType_BadAngles, gI_BadAngles[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, mode, AirType_AirAccelTime, gI_AirAccelTime[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, mode, AirType_AirVelChangeTime, gI_AirVelChangeTime[client][mode][Scope_AllTime]);
		StrCat(query, sizeof(query), buffer);
	}

	query[strlen(query) - 1] = 0; // Remove last comma...
	txn.AddQuery(query);

	gH_DB.Execute(txn, _, SQLTxnFailure_LogError, _, DBPrio_Normal);
}

void DeleteStats(int uid, char[] stats)
{
	int client = 0;
	for (int i = 1; i < MAXPLAYERS + 1; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetSteamAccountID(i) == uid)
		{
			client = i;
			break;
		}
	}
	Transaction txn = new Transaction();
	char query[1024];
	if (StrEqual(stats, "all", false))
	{
		FormatEx(query, sizeof(query), "DELETE FROM BhopStats WHERE SteamID32 = %d", uid);
		txn.AddQuery(query);
		FormatEx(query, sizeof(query), "DELETE FROM ResetStats WHERE SteamID32 = %d", uid);
		txn.AddQuery(query);
		FormatEx(query, sizeof(query), "DELETE FROM AirStats WHERE SteamID32 = %d", uid);
		txn.AddQuery(query);
		if (client)
		{
			InitializeBhopStats(client);
			InitializeResetStats(client);
			InitializeAirStats(client);
			gB_BhopStatsLoaded[client] = true;
			gB_ResetStatsLoaded[client] = true;
			gB_AirStatsLoaded[client] = true;
		}
	}
	else if (StrEqual(stats, "bhop", false))
	{
		if (client)
		{
			InitializeBhopStats(client);
			gB_BhopStatsLoaded[client] = true;
		}
		FormatEx(query, sizeof(query), "DELETE FROM BhopStats WHERE SteamID32 = %d", uid);
		txn.AddQuery(query);
	}
	else if (StrEqual(stats, "reset", false))
	{
		if (client)
		{
			InitializeResetStats(client);
			gB_ResetStatsLoaded[client] = true;
		}
		FormatEx(query, sizeof(query), "DELETE FROM ResetStats WHERE SteamID32 = %d", uid);
		txn.AddQuery(query);
	}
	else if (StrEqual(stats, "air", false))
	{
		if (client)
		{
			InitializeAirStats(client);
			gB_AirStatsLoaded[client] = true;
		}
		FormatEx(query, sizeof(query), "DELETE FROM AirStats WHERE SteamID32 = %d", uid);
		txn.AddQuery(query);
	}
	gH_DB.Execute(txn, _, SQLTxnFailure_LogError, _, DBPrio_Normal);
}

void SQLTxnFailure_LogError(Database db, any unused, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("[MoreStats] %s", error);
}

void SQLTxnSuccess_LoadClientResetStats(Database db, int userid, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}

	while (results[0].FetchRow())
	{
		int course = results[0].FetchInt(0);
		int mode = results[0].FetchInt(1);
		int resetType = results[0].FetchInt(2);
		int count = results[0].FetchInt(3);

		switch (resetType) {
			case ResetType_ResetCount:
			{
				gI_ResetCount[client][course][mode][Scope_AllTime] = count;
			}
			case ResetType_CompletionCount:
			{
				gI_CompletionCount[client][course][mode][Scope_AllTime] = count;
			}
			case ResetType_ProCompletionCount:
			{
				gI_ProCompletionCount[client][course][mode][Scope_AllTime] = count;
			}
		}		
	}

	gB_BhopStatsLoaded[client] = true;
}

void SQLTxnSuccess_LoadClientResetCountForMap(Database db, int userid, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}
	bool success = false;
	int resetCount;
	char map[128];
	while (results[0].FetchRow())
	{
		success = true;
		int count = results[0].FetchInt(0);
		int resetType = results[0].FetchInt(1);
		
		results[0].FetchString(2, map, sizeof(map));
		switch (resetType) {
			case ResetType_ResetCount:
			{
				resetCount = count;
			}
		}
	}
	if (success)
	{
		GOKZ_PrintToChat(client, true, "Reset count for {blue}%s{grey} : {lime}%i", map, resetCount);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "Failed to retrieve reset statistics.");
	}
}

void SQLTxnSuccess_LoadClientCompletionCountForMap(Database db, int userid, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}
	bool success = false;
	int resetCount, completionCount;
	char map[128];
	while (results[0].FetchRow())
	{
		success = true;
		int count = results[0].FetchInt(0);
		int resetType = results[0].FetchInt(1);
		results[0].FetchString(2, map, sizeof(map));
		switch (resetType) {
			case ResetType_ResetCount:
			{
				resetCount = count;
			}
			case ResetType_CompletionCount:
			{
				completionCount = count;
			}
		}
	}
	if (success)
	{	
		float percent = resetCount == 0 ? 0.0 : float(completionCount) / resetCount * 100;
		GOKZ_PrintToChat(client, true, "Completion count for {blue}%s{grey}: {lime}%i {grey}/ {lime}%i {grey}| {lime}%.2f{grey}%%", map, completionCount, resetCount, percent);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "Failed to retrieve reset statistics.");
	}
}

void SQLTxnSuccess_LoadClientProCompletionCountForMap(Database db, int userid, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}
	bool success = false;
	int resetCount, proCompletionCount;
	char map[128];
	while (results[0].FetchRow())
	{
		success = true;
		int count = results[0].FetchInt(0);
		int resetType = results[0].FetchInt(1);
		results[0].FetchString(2, map, sizeof(map));
		switch (resetType) {
			case ResetType_ResetCount:
			{
				resetCount = count;
			}
			case ResetType_ProCompletionCount:
			{
				proCompletionCount = count;
			}
		}
	}
	if (success)
	{	
		float percent = resetCount == 0 ? 0.0 : float(proCompletionCount) / resetCount * 100;
		GOKZ_PrintToChat(client, true, "Pro completion count for {blue}%s{grey}: {lime}%i {grey}/ {lime}%i {grey}| {lime}%.2f{grey}%%", map, proCompletionCount, resetCount, percent);
	}
	else
	{
		GOKZ_PrintToChat(client, true, "Failed to retrieve reset statistics.");
	}
}

void SQLTxnSuccess_LoadClientBhopStats(Database db, int userid, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}

	while (results[0].FetchRow())
	{
		int mode = results[0].FetchInt(0);
		int type1 = results[0].FetchInt(1);
		int type2 = results[0].FetchInt(2);
		int count = results[0].FetchInt(3);

		switch (type1)
		{
			case StatType_BhopStats:
			{
				if (type2 >= 0 && type2 < MAX_BHOP_TICKS)
				{
					gI_BhopTicks[client][mode][type2][Scope_AllTime] = count;
				}
			}
			case StatType_PerfStreaks:
			{
				if (type2 >= 0 && type2 < MAX_PERF_STREAK)
				{
					gI_PerfStreaks[client][mode][type2][Scope_AllTime] = count;
				}
			}
			case StatType_ScrollEff:
			{
				if (type2 == ScrollEff_RegisteredScrolls)
				{
					gI_SumRegisteredScrolls[client][mode][Scope_AllTime] = count;
				}
				else if (type2 == ScrollEff_FastScrolls)
				{
					gI_SumFastScrolls[client][mode][Scope_AllTime] = count;
				}
				else if (type2 == ScrollEff_SlowScrolls)
				{
					gI_SumSlowScrolls[client][mode][Scope_AllTime] = count;
				}
				else if (type2 == ScrollEff_TimingTotal)
				{
					gI_TimingTotal[client][mode][Scope_AllTime] = count;
				}
				else if (type2 == ScrollEff_TimingSamples)
				{
					gI_TimingSamples[client][mode][Scope_AllTime] = count;
				}
			}
			case StatType_GOKZPerfCount:
			{
				gI_GOKZPerfCount[client][mode][Scope_AllTime] = count;
			}
		}
	}

	gB_BhopStatsLoaded[client] = true;
}

void SQLTxnSuccess_LoadClientAirStats(Database db, int userid, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}

	while (results[0].FetchRow())
	{
		int mode = results[0].FetchInt(0);
		int airType = results[0].FetchInt(1);
		int count = results[0].FetchInt(2);

		switch (airType) {
			case AirType_AirTime:
			{
				gI_AirTime[client][mode][Scope_AllTime] = count;
			}
			case AirType_Strafes:
			{
				gI_Strafes[client][mode][Scope_AllTime] = count;
			}
			case AirType_OverLap:
			{
				gI_Overlap[client][mode][Scope_AllTime] = count;
			}
			case AirType_DeadAir:
			{
				gI_DeadAir[client][mode][Scope_AllTime] = count;
			}
			case AirType_BadAngles:
			{
				gI_BadAngles[client][mode][Scope_AllTime] = count;
			}
			case AirType_AirAccelTime:
			{
				gI_AirAccelTime[client][mode][Scope_AllTime] = count;
			}
			case AirType_AirVelChangeTime:
			{
				gI_AirVelChangeTime[client][mode][Scope_AllTime] = count;
			}
		}		
	}

	gB_AirStatsLoaded[client] = true;
}

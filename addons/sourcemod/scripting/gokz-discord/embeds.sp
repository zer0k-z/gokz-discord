DiscordEmbed CreateEmbed(Record record)
{
	DiscordEmbed e = new DiscordEmbed();
	e.WithTitle(RunType(record));
	e.AddField(PlayerField(record));
	e.AddField(MapField(record));
	e.AddField(CourseField(record));
	e.AddField(RunTimeField(record));
	e.AddField(RankField(record));
	e.AddField(ServerField());
	e.WithThumbnail(Thumbnail(record));
	return e;
}

DiscordEmbedField PlayerField(Record record)
{
	char value[MAX_FIELD_VALUE_LENGTH];
	FormatEx(value, MAX_FIELD_VALUE_LENGTH, "[%s](https://steamcommunity.com/profiles/%s)", record.playerName, record.steamID64);
	return new DiscordEmbedField("Player", value, false);	
}

DiscordEmbedField MapField(Record record)
{
	char value[MAX_FIELD_VALUE_LENGTH];
	FormatEx(value, MAX_FIELD_VALUE_LENGTH, "[%s](https://www.kzstats.com/maps/%s?mode=kz_timer)", record.mapName, record.mapName);
	return new DiscordEmbedField("Map", value, true);
}

DiscordEmbedField CourseField(Record record)
{
	if (record.course == 0) return new DiscordEmbedField("Course", "Main", true);
	else
	{
		char value[MAX_FIELD_VALUE_LENGTH];
		FormatEx(value, sizeof(value), "Bonus %i", record.course);
		return new DiscordEmbedField("Course", value, true);
	}
}

DiscordEmbedThumbnail Thumbnail(Record record)
{
	char url[2048];
	FormatEx(url, sizeof(url), "https://github.com/KZGlobalTeam/map-images/raw/public/thumbnails/%s.jpg", record.mapName);
	return new DiscordEmbedThumbnail(url, 200, 113);
}

DiscordEmbedField RunTimeField(Record record)
{
	char value[MAX_FIELD_VALUE_LENGTH];
	char teleports[16];
	Format(teleports, sizeof(teleports), " (%i %s)", record.teleportsUsed, record.teleportsUsed == 1 ? "TP" : "TPs");
	value = GOKZ_FormatTime(record.runTime);
	if (record.teleportsUsed != 0)
	{
		StrCat(value, MAX_FIELD_VALUE_LENGTH, teleports);
	}
	if (record.matchedLocal)
	{
		if (!record.firstTime)
		{
			char improve[32];
			FormatEx(improve, sizeof(improve), "\n(%s%.2f NUB SPB)",
				record.pbDiff > 0.0 ? "+" : "", record.pbDiff);
			StrCat(value, MAX_FIELD_VALUE_LENGTH, improve);
		}
		if (!record.firstTimePro)
		{
			char improve[32];
			FormatEx(improve, sizeof(improve), "\n(%s%.2f PRO SPB)",
				record.pbDiffPro > 0.0 ? "+" : "", record.pbDiffPro);
			StrCat(value, MAX_FIELD_VALUE_LENGTH, improve);
		}
	}
	return new DiscordEmbedField("Runtime", value, true);	
}

DiscordEmbedField RankField(Record record)
{
	// Rank
	// Overall #1/2 (Global #12)
	// Pro #1/2 (Global #12)
	char value[MAX_FIELD_VALUE_LENGTH];
	if (record.matchedLocal)
	{
		Format(value, MAX_FIELD_VALUE_LENGTH, "Overall #%i/%i", record.rank, record.maxRank);
		char globalRank[16];		
		if (record.matchedGlobal) FormatEx(globalRank, sizeof(globalRank), " (Global #%i)", record.rankGlobal);
		StrCat(value, MAX_FIELD_VALUE_LENGTH, globalRank);
		if (record.teleportsUsed == 0)
		{
			char proRank[16];
			FormatEx(proRank, sizeof(proRank), "\nPro #%i/%i", record.rankPro, record.maxRankPro);
			StrCat(value, MAX_FIELD_VALUE_LENGTH, proRank);
			if (record.matchedGlobal)
			{
				FormatEx(globalRank, sizeof(globalRank), " (Global #%i)", record.rankGlobal);
				StrCat(value, MAX_FIELD_VALUE_LENGTH, globalRank);
			}

		}
	}
	else if (record.matchedGlobal)
	{
		Format(value, MAX_FIELD_VALUE_LENGTH, "Overall Global #%i", record.rankOverallGlobal);
		if (record.teleportsUsed == 0)
		{
			char proRank[16];
			FormatEx(proRank, sizeof(proRank), "\nPro Global #%i", record.rankGlobal);
			StrCat(value, MAX_FIELD_VALUE_LENGTH, proRank);

		}
	}
	return new DiscordEmbedField("Rank", value, true);
}

DiscordEmbedField ServerField()
{
	char serverName[128];
	GetConVarString(FindConVar("hostname"), serverName, sizeof(serverName));
	return new DiscordEmbedField("Server", serverName, false);
}

/* 
	Priorities are described as below:
	- Pro WR
	- Overall WR 
	- SR/First completion 
	- Top time global
	- Top time local
*/
static char[] RunType(Record record)
{
	char ret[32];
	if (record.matchedGlobal)
	{
		// Pro WR
		if (record.rankGlobal == 1 && record.timeType == TimeType_Pro)
		{
			ret = "New PRO World Record!";
			return ret;
		}
		// Overall WR
		else if (record.rankOverallGlobal == 1)
		{
			ret = "New NUB World Record!";
			return ret;
		}
	}
	// Server record takes priority over global top time
	if (record.matchedLocal)
	{
		if (record.rankPro == 1)
		{
			if (record.maxRankPro == 1 && record.firstTime) 
			{
				ret = "First Server PRO Completion!";
				return ret;
			}
			else if (record.pbDiffPro < 0.0)
			{
				ret = "New PRO Server Record!";
				return ret;
			}			
		}
		else if (record.rank == 1)
		{
			if (record.maxRank == 1 && record.firstTime) 
			{
				ret = "First Server NUB Completion!";
				return ret;
			}
			else if (record.pbDiff < 0.0)
			{
				ret = "New NUB Server Record!";
				return ret;
			}
		}
	}
	// Back to global, now check for top time
	if (record.matchedGlobal)
	{
		if (record.rankGlobal <= gI_MinRankGlobal || record.rankOverallGlobal <= gI_MinRankGlobal)
		{
			ret = "New Global Top Time!";
			return ret;
		}
	}
	if (record.matchedLocal)
	{
		if (record.pbDiff < 0.0 || record.pbDiffPro < 0.0 || record.firstTime)
		{
			if (record.rankPro <= gI_MinRankLocal || record.rank <= gI_MinRankLocal)
			{
				ret = "New Server Top Time!";
				return ret;
			}
		}
	}
	return ret;
}
DiscordEmbed CreateEmbed(Record record)
{
	DiscordEmbed embed = new DiscordEmbed();
	embed.WithTitle(TitleField(record));
	embed.AddField(PlayerField(record));
	embed.AddField(MapField(record));
	if (gCV_ShowCourse.BoolValue)
	{
		embed.AddField(CourseField(record));
	}
	if (gCV_ShowRunTime.IntValue > 0)
	{
		embed.AddField(RunTimeField(record));
	}	
	if (gCV_ShowRank.BoolValue)
	{
		embed.AddField(RankField(record));
	}
	if (gCV_ShowServer.BoolValue)
	{
		embed.AddField(ServerField());
	}
	if (gCV_ShowThumbnail.BoolValue)
	{
		embed.WithThumbnail(Thumbnail(record));
	}
	embed.SetColor(Color(record));
	return embed;
}

DiscordEmbedField PlayerField(Record record)
{
	char value[MAX_FIELD_VALUE_LENGTH];
	FormatEx(value, MAX_FIELD_VALUE_LENGTH, "[%s](https://steamcommunity.com/profiles/%s)", record.playerName, record.steamID64);
	return new DiscordEmbedField("Player", value, false);	
}

DiscordEmbedField MapField(Record record)
{
	char buffer[64];
	gKV_DiscordConfig.Rewind();
	if (!gKV_DiscordConfig.JumpToKey("Map"))
	{
		SetFailState("[GOKZ-Discord] Failed to obtain Discord Map config!");
	}
	
	gKV_DiscordConfig.GetString("url", buffer, sizeof(buffer));

	DiscordReplaceString(record, buffer, sizeof(buffer));
	
	char value[MAX_FIELD_VALUE_LENGTH];
	FormatEx(value, MAX_FIELD_VALUE_LENGTH, "[%s](%s)", record.mapName, buffer);
	LogMessage("value = %s", value);
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
	if (record.matchedLocal && gCV_ShowRunTime.IntValue >= 2)
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

static DiscordEmbedField ServerField()
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
static char[] TitleField(Record record)
{
	int recType = record.GetRecordType(gCV_MinRankLocal.IntValue, gCV_MinRankGlobal.IntValue);
	char title[32];
	Format(title, sizeof(title), "%T", gC_RecordType_Names[recType], LANG_SERVER);

	return title;
}

static char[] Color(Record record)
{
	char buffer[64];
	gKV_DiscordConfig.Rewind();
	if (!gKV_DiscordConfig.JumpToKey("EmbedColors"))
	{
		SetFailState("[GOKZ-Discord] Failed to obtain Discord EmbedColors config!");
	}

	gKV_DiscordConfig.GotoFirstSubKey();
	int recType = record.GetRecordType(gCV_MinRankLocal.IntValue, gCV_MinRankGlobal.IntValue);
	gKV_DiscordConfig.GetSectionName(buffer, sizeof(buffer));
	gKV_DiscordConfig.GetString(gC_RecordType_Names[recType], buffer, sizeof(buffer));
	LogMessage("Color chosen: %s", buffer);
	return buffer;
}
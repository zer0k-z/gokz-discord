DiscordEmbed CreateEmbed(Record record)
{
	DiscordEmbed embed = new DiscordEmbed();
	embed.WithTitle(TitleField(record));
	embed.AddField(PlayerField(record));
	embed.AddField(ModeField(record));
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
		embed.AddField(ServerField(record));
	}
	if (gCV_ShowThumbnail.BoolValue)
	{
		embed.WithThumbnail(Thumbnail(record));
	}
	if (gCV_ShowTimestamp.BoolValue)
	{
		char timestampString[256];
		FormatTime(timestampString, sizeof(timestampString), "%Y-%m-%d %H:%M:%S%z", record.timestamp);
		embed.SetString("timestamp", timestampString);
	}
	if (gCV_UseMoreStats.BoolValue && gB_MoreStats)
	{

		embed.AddField(MoreStatsField(record));
	}
	embed.SetColor(Color(record));
	return embed;
}

static DiscordEmbedField PlayerField(Record record)
{
	char buffer[768];
	gKV_DiscordConfig.Rewind();
	if (!gKV_DiscordConfig.JumpToKey("Player"))
	{
		SetFailState("[GOKZ-Discord] Failed to obtain Discord Player config!");
	}
	
	gKV_DiscordConfig.GetString("url", buffer, sizeof(buffer));
	DiscordReplaceString(record, buffer, sizeof(buffer));

	char value[MAX_FIELD_VALUE_LENGTH];
	FormatEx(value, MAX_FIELD_VALUE_LENGTH, "[%s](%s)", record.playerName, buffer);
	return new DiscordEmbedField("Player", value, true);
}

static DiscordEmbedField ModeField(Record record)
{
	return new DiscordEmbedField("Mode", gC_ModeNames[record.mode], true);
}

static DiscordEmbedField MapField(Record record)
{
	char buffer[768];
	gKV_DiscordConfig.Rewind();
	if (!gKV_DiscordConfig.JumpToKey("Map"))
	{
		SetFailState("[GOKZ-Discord] Failed to obtain Discord Map config!");
	}
	
	gKV_DiscordConfig.GetString("url", buffer, sizeof(buffer));

	DiscordReplaceString(record, buffer, sizeof(buffer));
	
	char value[MAX_FIELD_VALUE_LENGTH];
	FormatEx(value, MAX_FIELD_VALUE_LENGTH, "[%s](%s)", record.mapName, buffer);
	return new DiscordEmbedField("Map", value, true);
}

static DiscordEmbedField CourseField(Record record)
{
	if (record.course == 0) return new DiscordEmbedField("Course", "Main", true);
	else
	{
		char value[MAX_FIELD_VALUE_LENGTH];
		FormatEx(value, sizeof(value), "Bonus %i", record.course);
		return new DiscordEmbedField("Course", value, true);
	}
}

static DiscordEmbedThumbnail Thumbnail(Record record)
{
	char url[2048];
	gKV_DiscordConfig.Rewind();
	if (!gKV_DiscordConfig.JumpToKey("Thumbnail"))
	{
		SetFailState("[GOKZ-Discord] Failed to obtain Discord Thumbnail config!");
	}
	
	gKV_DiscordConfig.GetString("url", url, sizeof(url));
	DiscordReplaceString(record, url, sizeof(url));
	int height = gKV_DiscordConfig.GetNum("height");
	int width = gKV_DiscordConfig.GetNum("width");
	return new DiscordEmbedThumbnail(url, height, width);
}

static DiscordEmbedField RunTimeField(Record record)
{
	char value[MAX_FIELD_VALUE_LENGTH];
	if (gCV_ShowTeleports.BoolValue)
	{
		char teleports[16];
		Format(teleports, sizeof(teleports), " (%i %s)", record.teleportsUsed, record.teleportsUsed == 1 ? "TP" : "TPs");
		value = GOKZ_FormatTime(record.runTime);
		if (record.teleportsUsed != 0)
		{
			StrCat(value, MAX_FIELD_VALUE_LENGTH, teleports);
		}
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
		if (!record.firstTimePro && record.teleportsUsed == 0)
		{
			char improve[32];
			FormatEx(improve, sizeof(improve), "\n(%s%.2f PRO SPB)",
				record.pbDiffPro > 0.0 ? "+" : "", record.pbDiffPro);
			StrCat(value, MAX_FIELD_VALUE_LENGTH, improve);
		}
	}
	return new DiscordEmbedField("Runtime", value, true);	
}

static DiscordEmbedField RankField(Record record)
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

static DiscordEmbedField ServerField(Record record)
{
	// Max field length is 1024.
	char url[768];
	char name[32];
	gKV_DiscordConfig.Rewind();
	if (!gKV_DiscordConfig.JumpToKey("Server"))
	{
		SetFailState("[GOKZ-Discord] Failed to obtain Discord Server config!");
	}
	gKV_DiscordConfig.GetString("Name", name, sizeof(name));
	gKV_DiscordConfig.GetString("url", url, sizeof(url));
	
	char value[MAX_FIELD_VALUE_LENGTH];
	FormatEx(value, MAX_FIELD_VALUE_LENGTH, "[%s](%s)", name, url);
	DiscordReplaceString(record, value, sizeof(value));

	
	return new DiscordEmbedField("Server", value, false);
}

static char[] TitleField(Record record)
{
	int recType = record.GetRecordType(gCV_MinRankLocal.IntValue, gCV_MinRankGlobal.IntValue);
	char title[32];
	Format(title, sizeof(title), "%T", gC_RecordType_Names[recType], LANG_SERVER);

	return title;
}

static DiscordEmbedField MoreStatsField(Record record)
{
	char value[MAX_FIELD_VALUE_LENGTH];
	char buffer[64];
	float percent;
	float percent2;	
	
	if (gCV_ShowPerfCount.BoolValue)
	{
		percent = record.perfCount == 0 ? 0.0 : float(record.perfCount) / record.bhopCount * 100;
		FormatEx(buffer, sizeof(buffer), "Perfect Bhops: %i/%i (%.2f%%)\n", record.perfCount, record.bhopCount, percent);
		StrCat(value, MAX_FIELD_VALUE_LENGTH, buffer);
	}
	if (gCV_ShowStrafeCount.BoolValue)
	{
		FormatEx(buffer, sizeof(buffer), "Air Strafes: %i\n", record.strafeCount);
		StrCat(value, MAX_FIELD_VALUE_LENGTH, buffer);
	}
	if (gCV_ShowAirTicks.BoolValue)
	{
		FormatEx(buffer, sizeof(buffer), "Air Time: %i tick%s (%s)\n", record.airTime, record.airTime <= 1 ? "" : "s", GOKZ_FormatTime(record.airTime * GetTickInterval()));
		StrCat(value, MAX_FIELD_VALUE_LENGTH, buffer);
	}
	if (gCV_ShowAASync.BoolValue || gCV_ShowVelChangeSync.BoolValue)
	{
		if (gCV_ShowAASync.BoolValue && gCV_ShowVelChangeSync.BoolValue)
		{
			percent = record.aaTime == 0 ? 0.0 : float(record.aaTime) / float(record.airTime) * 100;
			percent2 = record.velChangeTime == 0 ? 0.0 : float(record.velChangeTime) / record.airTime * 100;
			FormatEx(buffer, sizeof(buffer), "Air Accel Sync: %.2f%% | Vel Change Sync: %.2f%%\n", percent, percent2);
		}
		else if (gCV_ShowAASync.BoolValue)
		{
			percent = record.aaTime == 0 ? 0.0 : float(record.aaTime) / record.airTime * 100;
			FormatEx(buffer, sizeof(buffer), "Air Accel Sync: %.2f%%\n", percent);
		}
		else
		{
			percent = record.velChangeTime == 0 ? 0.0 : float(record.velChangeTime) / record.airTime * 100;
			FormatEx(buffer, sizeof(buffer), "Vel Change Sync: %.2f%%\n", percent);
		}
		StrCat(value, MAX_FIELD_VALUE_LENGTH, buffer);
	}
	if (gCV_ShowOverlap.BoolValue)
	{
		percent = record.overlap == 0 ? 0.0 : float(record.overlap) / record.airTime * 100;
		FormatEx(buffer, sizeof(buffer), "Overlap: %i tick%s (%.2f%%)\n", record.overlap, record.overlap <= 1 ? "" : "s", percent);
		StrCat(value, MAX_FIELD_VALUE_LENGTH, buffer);
	}
	if (gCV_ShowDeadAir.BoolValue)
	{
		percent = record.deadAir == 0 ? 0.0 : float(record.deadAir) / record.airTime * 100;
		FormatEx(buffer, sizeof(buffer), "Dead Air: %i tick%s (%.2f%%)\n", record.deadAir, record.deadAir <= 1 ? "" : "s", percent);
		StrCat(value, MAX_FIELD_VALUE_LENGTH, buffer);
	}
	if (gCV_ShowBadAngles.BoolValue)
	{
		percent = record.badAngles == 0 ? 0.0 : float(record.badAngles) / record.airTime * 100;
		FormatEx(buffer, sizeof(buffer), "Bad Angles: %i tick%s (%.2f%%)\n", record.badAngles, record.badAngles <= 1 ? "" : "s", percent);
		StrCat(value, MAX_FIELD_VALUE_LENGTH, buffer);
	}
	if (gCV_ShowScrollStats.BoolValue)
	{
		float efficiency;
		int registeredScrolls = record.scrollStats[ScrollEff_RegisteredScrolls];
		int fastScrolls = record.scrollStats[ScrollEff_FastScrolls];
		int slowScrolls = record.scrollStats[ScrollEff_SlowScrolls];
		int timingTotal = record.scrollStats[ScrollEff_TimingTotal];
		int timingSamples = record.scrollStats[ScrollEff_TimingSamples];
		int badScrolls = fastScrolls + slowScrolls;
		if (registeredScrolls + badScrolls == 0)
		{
			efficiency = 0.0;
		}
		else 
		{
			efficiency = registeredScrolls / (float(registeredScrolls) + (float(badScrolls) / 1.5)) * 100.0;
		}
		float timingOffset = (timingSamples == 0) ? 0.0 : timingTotal / float(timingSamples);
		FormatEx(buffer, sizeof(buffer), "Scroll Efficiency: %.2f%% | Average Timing: %s%.2f\n", efficiency, timingOffset >= 0.0 ? "+" : "", timingOffset);
		StrCat(value, MAX_FIELD_VALUE_LENGTH, buffer);
	}
	return new DiscordEmbedField("More Stats", value, false);
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
	return buffer;
}
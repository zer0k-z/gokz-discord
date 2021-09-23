public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	if (teleportsUsed != 0 && gCV_ProOnly.BoolValue)
	{
		return;
	}
	if (course != 0 && !gCV_AnnounceBonus.BoolValue)
	{
		return;
	}
	Record record;
	record.Init(client, course, time, teleportsUsed);
	if (gB_MoreStats && gCV_UseMoreStats.BoolValue)
	{
		int mode = GOKZ_GetCoreOption(client, Option_Mode);
		int scrollStats[5];
		for (int i = 0; i < 5; i++)
		{
			scrollStats[i] = MoreStats_GetScrollStats(client, mode, i, Scope_Run);
		}
		int bhopCount;
		for (int i = 0; i < MAX_BHOP_TICKS; i++)
		{
			bhopCount += MoreStats_GetBhopTicks(client, mode, i, Scope_Run);
		}
		record.InitMoreStats(bhopCount, 
			MoreStats_GetPerfCount(client, mode, Scope_Run),
			MoreStats_GetAirTime(client, mode, Scope_Run),
			MoreStats_GetStrafeCount(client, mode, Scope_Run),
			MoreStats_GetOverlap(client, mode, Scope_Run),
			MoreStats_GetDeadAir(client, mode, Scope_Run),
			MoreStats_GetBadAngles(client, mode, Scope_Run),
			MoreStats_GetAirAccelTime(client, mode, Scope_Run),
			MoreStats_GetAirVelChangeTime(client, mode, Scope_Run),
			scrollStats);
	}
	gA_Records.PushArray(record);
}

public void GOKZ_GL_OnNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall, float runTime)
{
	if (!gCV_UseLocalRank.BoolValue)
	{
		return;
	}
	if (timeType != TimeType_Pro && gCV_ProOnly.BoolValue)
	{
		return;
	}
	if (course != 0 && !gCV_AnnounceBonus.BoolValue)
	{
		return;
	}
	Record record;
	for (int i = 0; i < gA_Records.Length; i++)
	{
		gA_Records.GetArray(i, record);
		if (record.InitGlobal(client, course, mode, timeType, rank, rankOverall, runTime))
		{
			break;
		}
	}
}

public void GOKZ_LR_OnTimeProcessed(int client, int steamID, int mapID, int course, int mode, int style, float runTime, int teleportsUsed, 
	bool firstTime, float pbDiff, int rank, int maxRank, bool firstTimePro, float pbDiffPro, int rankPro, int maxRankPro)
{
	if (!gCV_UseGlobalRank.BoolValue)
	{
		return;
	}
	if (teleportsUsed != 0 && gCV_ProOnly.BoolValue)
	{
		return;
	}
	if (course != 0 && !gCV_AnnounceBonus.BoolValue)
	{
		return;
	}
	Record record;
	for (int i = 0; i < gA_Records.Length; i++)
	{
		gA_Records.GetArray(i, record);
		if (record.InitLocal(steamID, mapID, course, mode, style, runTime, teleportsUsed, 
			firstTime, pbDiff, rank, maxRank, firstTimePro, pbDiffPro, rankPro, maxRankPro))
		{
			gA_Records.SetArray(i, record);
			break;
		}
	}
}

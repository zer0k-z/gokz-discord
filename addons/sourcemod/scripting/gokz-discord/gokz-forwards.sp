public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	Record record;
	record.Init(client, course, time, teleportsUsed);
	gA_Records.PushArray(record);
}

public void GOKZ_GL_OnNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall, float runTime)
{
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

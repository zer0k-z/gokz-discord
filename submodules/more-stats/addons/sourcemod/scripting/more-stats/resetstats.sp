void InitializeResetStats(int client)
{
	gB_ResetStatsLoaded[client] = false;
	for (int i = 0; i < GOKZ_MAX_COURSES; i++)
	{
		for (int mode = 0; mode < MODE_COUNT; mode++)
		{
			ResetVariable(gI_ResetCount[client][i][mode], sizeof(gI_ResetCount[][][]));
			ResetVariable(gI_CompletionCount[client][i][mode], sizeof(gI_CompletionCount[][][]));
			ResetVariable(gI_ProCompletionCount[client][i][mode], sizeof(gI_ProCompletionCount[][][]));
		}
	}
}

void GOKZ_OnTimerStart_ResetStats(int client, int course)
{
	// Only increment if the player starts the timer for the first time or the previous run was longer than a certain duration
	if (GOKZ_GetTime(client) == 0.0 || GOKZ_GetTime(client) > 0.5)
	{
		IncrementVariable(client, gI_ResetCount[client][course][GOKZ_GetCoreOption(client, Option_Mode)]);
	}
}

void GOKZ_OnTimerEnd_ResetStats(int client, int course, int teleports)
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	
	IncrementVariable(client, gI_CompletionCount[client][course][mode]);

	if (teleports == 0)	
	{
		IncrementVariable(client, gI_ProCompletionCount[client][course][mode]);
	}
}


int GetResetCount(int client, int course, int mode, int scope)
{
	return gI_ResetCount[client][course][mode][scope];
}

int GetCompletionCount(int client, int course, int mode, int scope, bool pro = false)
{
	if (pro)
	{
		return gI_ProCompletionCount[client][course][mode][scope];
	}
	else return gI_CompletionCount[client][course][mode][scope];
}

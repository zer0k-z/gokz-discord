void InitializeBhopStats(int client)
{
	ResetBhopTrackingVariables(client);
	gB_BhopStatsLoaded[client] = false;	
	gB_ChatScrollStats[client] = false;
	
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		for (int scope = Scope_AllTime; scope < SCOPE_COUNT; scope++)
		{
			FillArray(gI_BhopTicks[client][mode], sizeof(gI_BhopTicks[][]), scope, 0);
			FillArray(gI_PerfStreaks[client][mode], sizeof(gI_PerfStreaks[][]), scope, 0);
		}
		ResetVariable(gI_SumRegisteredScrolls[client][mode], sizeof(gI_SumRegisteredScrolls[][]));
		ResetVariable(gI_SumFastScrolls[client][mode], sizeof(gI_SumFastScrolls[][]));
		ResetVariable(gI_SumSlowScrolls[client][mode], sizeof(gI_SumSlowScrolls[][]));
		ResetVariable(gI_TimingTotal[client][mode], sizeof(gI_TimingTotal[][]));
		ResetVariable(gI_TimingSamples[client][mode], sizeof(gI_TimingSamples[][]));
		ResetVariable(gI_GOKZPerfCount[client][mode], sizeof(gI_GOKZPerfCount[][]));
	}
}

void ResetBhopTrackingVariables(int client)
{
	gI_TickCount[client] = 0;
	gI_CmdNum[client] = 0;
	gI_LastPlusJumpCmdNum[client] = 0;
	gB_Scrolling[client] = false;
	gI_ScrollGroundTicks[client] = -1;
	gI_ScrollBhopCmdNum[client] = 0;
	gI_ScrollStartCmdNum[client] = 0;
	gI_RegisteredScrolls[client] = 0;
	gI_FastScrolls[client] = 0;
	gI_SlowScrolls[client] = 0;
	gI_LastButtons[client] = 0;
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		ResetVariable(gI_CurrentPerfStreak[client][mode], sizeof(gI_CurrentPerfStreak[][]));
	}
}

void OnPlayerRunCmd_BhopStats(int client, int &buttons, int &cmdnum, int &tickcount)
{
	gI_TickCount[client] = tickcount;
	gI_CmdNum[client] = cmdnum;

	if (!gB_BhopStatsLoaded[client])
	{
		return;
	}

	if (gCV_sv_autobunnyhopping.BoolValue)
	{
		gB_Scrolling[client] = false;
		gI_LastButtons[client] = buttons;
		return;
	}

	// Scroll stats, we eating spaghettios tonight
	int lastButtons = gI_LastButtons[client];

	bool inJump = (buttons & IN_JUMP) != 0;
	bool lastInJump = (lastButtons & IN_JUMP) != 0;

	if (gB_Scrolling[client])
	{
		if (inJump && !lastInJump)
		{
			gI_RegisteredScrolls[client]++;
		}
		else if (inJump && lastInJump)
		{
			gI_FastScrolls[client]++;
		}
		else if (!inJump && !lastInJump)
		{
			gI_SlowScrolls[client]++;
		}
	}

	if (inJump)
	{
		if (cmdnum > gI_LastPlusJumpCmdNum[client] + MAX_SCROLL_TICKS)
		{
			// Started scrolling
			gB_Scrolling[client] = true;
			gI_ScrollGroundTicks[client] = -1;
			gI_ScrollStartCmdNum[client] = cmdnum;
			gI_RegisteredScrolls[client] = 1;
			gI_FastScrolls[client] = 0;
			gI_SlowScrolls[client] = 0;
		}
		gI_LastPlusJumpCmdNum[client] = cmdnum;
	}
	else if (gB_Scrolling[client])
	{
		if (cmdnum > gI_LastPlusJumpCmdNum[client] + MAX_SCROLL_TICKS)
		{
			// Stopped scrolling
			gB_Scrolling[client] = false;

			bool scrollCausedBhop = (gI_ScrollGroundTicks[client] >= 0);
			int registeredScrolls = gI_RegisteredScrolls[client];
			if (registeredScrolls > 2 && scrollCausedBhop)
			{
				int fastScrolls = gI_FastScrolls[client];
				int slowScrolls = gI_SlowScrolls[client] - MAX_SCROLL_TICKS;

				int timingOffset = GetScrollTimingOffset(gI_ScrollStartCmdNum[client], gI_LastPlusJumpCmdNum[client], gI_ScrollBhopCmdNum[client]);

				if (gB_ChatScrollStats[client])
				{
					float effectivenessPercent = GetScrollEffectivenessPercent(registeredScrolls, fastScrolls, slowScrolls);
					int groundTicks = gI_ScrollGroundTicks[client];
					GOKZ_PrintToChat(client, true, "{lime}%d {grey}Scrolls ({lime}%0.0f%%%%{grey}) | {lime}%d {grey}/ {lime}%d {grey}Speed | {lime}%s%d {grey}Time | {lime}%d {grey}Ground",
						registeredScrolls, effectivenessPercent,
						slowScrolls, fastScrolls,
						timingOffset >= 0 ? "+" : "", timingOffset,
						groundTicks);
				}

				int mode = GOKZ_GetCoreOption(client, Option_Mode);
				AddToVariable(client, gI_SumRegisteredScrolls[client][mode], registeredScrolls);
				AddToVariable(client, gI_SumFastScrolls[client][mode], fastScrolls);
				AddToVariable(client, gI_SumSlowScrolls[client][mode], slowScrolls);
				AddToVariable(client, gI_TimingTotal[client][mode], timingOffset);
				IncrementVariable(client, gI_TimingSamples[client][mode]);
			}
		}
	}

	gI_LastButtons[client] = buttons;
}

float GetScrollEffectivenessPercent(int registeredScrolls, int fastScrolls, int slowScrolls)
{
	int badScrolls = fastScrolls + slowScrolls;
	if (registeredScrolls + badScrolls == 0)
	{
		return 0.0;
	}

	float effectiveness = registeredScrolls / (float(registeredScrolls) + (float(badScrolls) / 1.5));
	return effectiveness * 100.0;
}

int GetScrollTimingOffset(int begin, int end, int bhop)
{
	int middle = RoundFloat((begin + end) / 2.0);
	int rawOffset = (middle - bhop);
	if (rawOffset >= -1 && rawOffset <= 1)
	{
		return 0;
	}
	return (rawOffset > 1) ? rawOffset - 1 : rawOffset + 1;
}

void EndPerfStreak(int client, int scope = 0)
{
	if (IsFakeClient(client) || !IsClientInGame(client))
	{
		return;
	}
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int streak;
	if (scope)
	{
		streak = gI_CurrentPerfStreak[client][mode][scope];
		if (streak > 0 && streak <= MAX_PERF_STREAK)
		{
			int index = streak - 1;
			gI_PerfStreaks[client][mode][index][scope]++;
		}
		gI_CurrentPerfStreak[client][mode][scope] = 0;
		
	}
	else
	{
		for (scope = 0; scope < BHOPSTATS_MAXSCOPE; scope++)
		{
			streak = gI_CurrentPerfStreak[client][mode][scope];
			if (streak > 0 && streak <= MAX_PERF_STREAK)
			{
				int index = streak - 1;
				gI_PerfStreaks[client][mode][index][scope]++;
			}
		}
		ResetVariable(gI_CurrentPerfStreak[client][mode], sizeof(gI_CurrentPerfStreak[][]));
	}
}


void PrintBhopStats(int client, const int[][] bhopTicks, int length, int mode, int scope)
{
	int sum = 0;
	for (int i = 0; i < length; i++)
	{
		sum += bhopTicks[i][scope];
	}
	float percent = (gI_GOKZPerfCount[client][mode][scope] == 0) ? 0.0 : float(gI_GOKZPerfCount[client][mode][scope]) / sum * 100;
	PrintToConsole(client, "-----------------------");
	PrintToConsole(client, "Bhop Stats (%d bhops)", sum);
	PrintToConsole(client, "-----------------------");
	PrintToConsole(client, "Perfs: %7d | %.2f%%", gI_GOKZPerfCount[client][mode][scope], percent);

	for (int i = 0; i < length; i++)
	{
		int tick = i + 1;
		int count = bhopTicks[i][scope];
		percent = (sum == 0) ? 0.0 : count / float(sum) * 100.0;
		PrintToConsole(client, "Tick %d: %6d | %.2f%%", tick, count, percent);
	}
}

void PrintShortBhopStats(int client, const int[][][] bhopTicks, int length, int mode, int scope)
{
	int sum = 0;
	for (int i = 0; i < length; i++)
	{
		sum += bhopTicks[mode][i][scope];
	}
	int count = gI_GOKZPerfCount[client][mode][scope];
	float percent = (sum == 0) ? 0.0: count / float(sum) * 100.0;
	GOKZ_PrintToChat(client, true, "{lime}%N{grey}: {lime}%.2f{grey}%%%% Perfs (%d/%d)", client, percent, count, sum);
}

void PrintPerfStreaks(int client, const int[][] perfStreaks, int length, int scope)
{
	int sum = 0;
	for (int i = 0; i < MAX_PERF_STREAK; i++)
	{
		sum += perfStreaks[i][scope];
	}

	PrintToConsole(client, "Perf Streaks (%d streaks)", sum);
	PrintToConsole(client, "-------------------------");
	for (int i = 0; i < length; i++)
	{
		int streak = i + 1;
		int count = perfStreaks[i][scope];
		float percent = (sum == 0) ? 0.0 : count / float(sum) * 100.0;
		if (count != 0)
		{
			if (streak < 10)
			{
				PrintToConsole(client, "Perfs %1d: %7d | %5.2f%%", streak, count, percent);
			}
			else
			{
				PrintToConsole(client, "Perfs %2d: %6d | %5.2f%%", streak, count, percent);
			}
		}		
	}
}

void PrintScrollStats(int client, int registeredScrolls, int fastScrolls, int slowScrolls, int timingTotal, int timingSamples)
{
	PrintToConsole(client, "Scroll Stats (%d scrolls)", registeredScrolls);
	PrintToConsole(client, "-------------------------");
	PrintToConsole(client, "Effectiveness: %0.2f%%", GetScrollEffectivenessPercent(registeredScrolls, fastScrolls, slowScrolls));
	PrintToConsole(client, "Speed: %d / %d", slowScrolls, fastScrolls);

	float timingOffset = (timingSamples == 0) ? 0.0 : timingTotal / float(timingSamples);
	PrintToConsole(client, "Time: %s%0.2f", timingOffset >= 0.0 ? "+" : "", timingOffset);
}

void GOKZ_OnTimerEnd_Post_BhopStats(int client)
{
	EndPerfStreak(client, Scope_Run);
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	PrintBhopStats(client, gI_BhopTicks[client][mode], sizeof(gI_BhopTicks[][]), mode, Scope_Run);
	PrintToConsole(client, "-----------------------");
	PrintPerfStreaks(client, gI_PerfStreaks[client][mode], sizeof(gI_PerfStreaks[][]), Scope_Run);
	PrintToConsole(client, "-----------------------");
	PrintScrollStats(client, gI_SumRegisteredScrolls[client][mode][Scope_Run], 
		gI_SumFastScrolls[client][mode][Scope_Run],
		gI_SumSlowScrolls[client][mode][Scope_Run], 
		gI_TimingTotal[client][mode][Scope_Run], 
		gI_TimingSamples[client][mode][Scope_Run]);

}

void GOKZ_OnTimerStart_Post_BhopStats(int client)
{
	EndPerfStreak(client, Scope_Run);
	int mode = GOKZ_GetCoreOption(client, Option_Mode)
	FillArray(gI_BhopTicks[client][mode], sizeof(gI_BhopTicks[][]), Scope_Run, 0);
	FillArray(gI_PerfStreaks[client][mode], sizeof(gI_PerfStreaks[][]), Scope_Run, 0);
	gI_SumRegisteredScrolls[client][mode][Scope_Run] = 0;
	gI_SumFastScrolls[client][mode][Scope_Run] = 0;
	gI_SumSlowScrolls[client][mode][Scope_Run] = 0;
	gI_TimingTotal[client][mode][Scope_Run] = 0;
	gI_TimingSamples[client][mode][Scope_Run] = 0;
	gI_GOKZPerfCount[client][mode][Scope_Run] = 0;

}

void Movement_OnPlayerJump_BhopStats(int client, int jumpbug)
{
	if (gCV_sv_autobunnyhopping.BoolValue)
	{
		EndPerfStreak(client);
		return;
	}
	int userid = GetClientUserId(client);
	RequestFrame(CheckPerf, userid);

	int landingTick = Movement_GetLandingTick(client);
	int groundTicks = gI_TickCount[client] - landingTick - 1;
	if (jumpbug)
	{
		groundTicks = 0;
	}
	// Scroll stats
	if (groundTicks >= 0 && groundTicks < MAX_BHOP_TICKS)
	{
		gI_ScrollGroundTicks[client] = groundTicks;
		gI_ScrollBhopCmdNum[client] = gI_CmdNum[client];
	}

	// Bhop stats
	if (groundTicks >= 0 && groundTicks < MAX_BHOP_TICKS)
	{
		IncrementVariable(client, gI_BhopTicks[client][GOKZ_GetCoreOption(client, Option_Mode)][groundTicks]);
	}

	// Perf streaks
	if (groundTicks == 0)
	{
		IncrementVariable(client, gI_CurrentPerfStreak[client][GOKZ_GetCoreOption(client, Option_Mode)], false, MAX_PERF_STREAK);
	}
	else
	{
		EndPerfStreak(client);
	}
}

public void CheckPerf(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client != 0 && GOKZ_GetHitPerf(client) && !gCV_sv_autobunnyhopping.BoolValue)
	{
		IncrementVariable(client, gI_GOKZPerfCount[client][GOKZ_GetCoreOption(client, Option_Mode)]);
	}
}

void GOKZ_OnOptionChanged_BhopStats(int client, const char[] option)
{
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]))
	{
		ResetBhopTrackingVariables(client);
	}
}

int GetBhopTicks(int client, int mode, int tick, int scope)
{
	return gI_BhopTicks[client][mode][tick][scope];
}

int GetPerfStreaks(int client, int mode, int streak, int scope)
{
	return gI_PerfStreaks[client][mode][streak][scope];
}

int GetScrollStats(int client, int mode, int type, int scope)
{
	switch (type)
	{
		case 0:
		{
			return gI_SumRegisteredScrolls[client][mode][scope];
		}
		case 1:
		{
			return gI_SumFastScrolls[client][mode][scope];
		}
		case 2:
		{
			return gI_SumSlowScrolls[client][mode][scope];
		}
		case 3:
		{
			return gI_TimingTotal[client][mode][scope];
		}
		case 4:
		{
			return gI_TimingSamples[client][mode][scope];
		}
	}
	// Should not happen
	return -1;
}

int GetPerfCount(int client, int mode, int scope)
{
	return gI_GOKZPerfCount[client][mode][scope];
}
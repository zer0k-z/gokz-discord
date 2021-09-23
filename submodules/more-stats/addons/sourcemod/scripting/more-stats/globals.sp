public bool gB_LateLoaded;
// BhopStats variables
public Database gH_DB;
public ConVar gCV_sv_autobunnyhopping;
public bool gB_BhopStatsLoaded[MAXPLAYERS + 1];
public int gI_TickCount[MAXPLAYERS + 1];
public int gI_CmdNum[MAXPLAYERS + 1];
public int gI_LastPlusJumpCmdNum[MAXPLAYERS + 1];
public bool gB_ChatScrollStats[MAXPLAYERS + 1];
public bool gB_Scrolling[MAXPLAYERS + 1];
public int gI_ScrollGroundTicks[MAXPLAYERS + 1];
public int gI_ScrollBhopCmdNum[MAXPLAYERS + 1];
public int gI_ScrollStartCmdNum[MAXPLAYERS + 1];
public int gI_RegisteredScrolls[MAXPLAYERS + 1];
public int gI_FastScrolls[MAXPLAYERS + 1];
public int gI_SlowScrolls[MAXPLAYERS + 1];
public int gI_LastButtons[MAXPLAYERS + 1];
public int gI_CurrentPerfStreak[MAXPLAYERS + 1][MODE_COUNT][BHOPSTATS_MAXSCOPE];
public Handle gH_MoreStatsCookie;

public int gI_BhopTicks[MAXPLAYERS + 1][MODE_COUNT][MAX_BHOP_TICKS][BHOPSTATS_MAXSCOPE];
public int gI_PerfStreaks[MAXPLAYERS + 1][MODE_COUNT][MAX_PERF_STREAK][BHOPSTATS_MAXSCOPE];
public int gI_SumRegisteredScrolls[MAXPLAYERS + 1][MODE_COUNT][BHOPSTATS_MAXSCOPE];
public int gI_SumFastScrolls[MAXPLAYERS + 1][MODE_COUNT][BHOPSTATS_MAXSCOPE];
public int gI_SumSlowScrolls[MAXPLAYERS + 1][MODE_COUNT][BHOPSTATS_MAXSCOPE];
public int gI_TimingTotal[MAXPLAYERS + 1][MODE_COUNT][BHOPSTATS_MAXSCOPE];
public int gI_TimingSamples[MAXPLAYERS + 1][MODE_COUNT][BHOPSTATS_MAXSCOPE];

public int gI_GOKZPerfCount[MAXPLAYERS + 1][MODE_COUNT][BHOPSTATS_MAXSCOPE];

// Run related BhopStats variables
public bool gB_PostRunStats[MAXPLAYERS + 1];

// Segment related BhopStats variables
public bool gB_SegmentPaused[MAXPLAYERS + 1];

// Reset counter variables
public bool gB_ResetStatsLoaded[MAXPLAYERS + 1];
public int gI_ResetCount[MAXPLAYERS + 1][GOKZ_MAX_COURSES][MODE_COUNT][RESETSTATS_MAXSCOPE];
public int gI_CompletionCount[MAXPLAYERS + 1][GOKZ_MAX_COURSES][MODE_COUNT][RESETSTATS_MAXSCOPE];
public int gI_ProCompletionCount[MAXPLAYERS + 1][GOKZ_MAX_COURSES][MODE_COUNT][RESETSTATS_MAXSCOPE];

// Airstrafe variables

public bool gB_AirStatsLoaded[MAXPLAYERS + 1];
public float gF_OldVelocity[MAXPLAYERS + 1][3];
public bool gB_OldOnGround[MAXPLAYERS + 1];
public int gI_StrafeDirection[MAXPLAYERS + 1];

public int gI_AirTime[MAXPLAYERS + 1][MODE_COUNT][AIRSTATS_MAXSCOPE];
public int gI_Strafes[MAXPLAYERS + 1][MODE_COUNT][AIRSTATS_MAXSCOPE];
public int gI_Overlap[MAXPLAYERS + 1][MODE_COUNT][AIRSTATS_MAXSCOPE];
public int gI_DeadAir[MAXPLAYERS + 1][MODE_COUNT][AIRSTATS_MAXSCOPE];
public int gI_BadAngles[MAXPLAYERS + 1][MODE_COUNT][AIRSTATS_MAXSCOPE];
public int gI_AirAccelTime[MAXPLAYERS + 1][MODE_COUNT][AIRSTATS_MAXSCOPE];
public int gI_AirVelChangeTime[MAXPLAYERS + 1][MODE_COUNT][AIRSTATS_MAXSCOPE];

public int gB_ChatAirStats[MAXPLAYERS + 1];
#if defined _morestats_included_
  #endinput
#endif
#define _morestats_included_

// Enums

enum
{
	StrafeDirection_None, 
	StrafeDirection_Left, 
	StrafeDirection_Right
};

enum
{
	Scope_AllTime,	// Tracked across sessions
	Scope_Session,	// Tracked in this session only
	Scope_Run,		// Tracked only in current active run
	Scope_Segment,	// Tracked only during a segement
	Scope_InAir,	// Tracked only when in the air
	SCOPE_COUNT
};

enum
{
	StatType_BhopStats,
	StatType_PerfStreaks,
	StatType_ScrollEff,
	StatType_StrafeCount,
	StatType_GOKZPerfCount
};

enum
{
	ResetType_ResetCount,
	ResetType_CompletionCount,
	ResetType_ProCompletionCount
};

enum
{
	AirType_AirTime,
	AirType_Strafes,
	AirType_OverLap,
	AirType_DeadAir,
	AirType_BadAngles,
	AirType_AirAccelTime,
	AirType_AirVelChangeTime
};

enum
{
	ScrollEff_RegisteredScrolls,
	ScrollEff_FastScrolls,
	ScrollEff_SlowScrolls,
	ScrollEff_TimingTotal,
	ScrollEff_TimingSamples	
};


// Constants
#define MAX_BHOP_TICKS 8
#define MAX_PERF_STREAK 24
#define MAX_SCROLL_TICKS 16
#define RESETSTATS_MAXSCOPE 4
#define BHOPSTATS_MAXSCOPE 4
#define AIRSTATS_MAXSCOPE 5


/**
 * Gets a player's reset count.
 *
 * @param client		Client index.
 * @param course		Client course.
 * @param mode			Client mode.
 * @param scope			Tracker scope.
 * @return				Player's reset count on current map with the specified scope, course, and mode.
 */
native int MoreStats_GetResetCount(int client, int course, int mode, int scope);

/**
 * Gets a player's reset count.
 *
 * @param client		Client index.
 * @param course		Client course.
 * @param mode			Client mode.
 * @param scope			Tracker scope.
 * @param pro			True to get PRO completions only.
 * @return				Player's completion count on the specified course and mode on the current map.
 */
native int MoreStats_GetCompletionCount(int client, int course, int mode, int scope, bool pro);

/**
 * Gets a player's bhop count.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param tick			Number of ticks on the ground before jumping.
 * @param scope			Tracker scope.
 * @return				Number of bhops done on the specified mode and after the specified number of ticks on the ground.
 */
native int MoreStats_GetBhopTicks(int client, int mode, int tick, int scope);

/**
 * Gets a player's 1-tick bhop streak count.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param streak		Length of bhop streak.
 * @param scope			Tracker scope.
 * @return				Number of 1-tick perf streaks with the specified length done on the specified mode.
 */
native int MoreStats_GetPerfStreaks(int client, int mode, int streak, int scope);

/**
 * Gets a player's scroll statistics.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param type			Scroll statistics type. (RegisteredScrolls/FastScrolls/SlowScrolls/TimingTotal/TimingSamples)
 * @param scope			Tracker scope.
 * @return				Player's scroll statistics of specified type on the specified mode.
 */
native int MoreStats_GetScrollStats(int client, int mode, int type, int scope);

/**
 * Gets a player's perfect bhop (GOKZ) count.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param scope			Tracker scope.
 * @return				Player's perf count on the specified mode.
 */
native int MoreStats_GetPerfCount(int client, int mode, int scope);

/**
 * Gets a player's number of ticks spent in the air.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param scope			Tracker scope.
 * @return				Player's number of ticks spent in the air on the specified mode.
 */
native int MoreStats_GetAirTime(int client, int mode, int scope);

/**
 * Gets a player's airstrafe count.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param scope			Tracker scope.
 * @return				Player's airstrafe count on the specified mode.
 */
native int MoreStats_GetStrafeCount(int client, int mode, int scope);

/**
 * Gets a player's number of ticks with overlapped strafes.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param scope			Tracker scope.
 * @return				Player's tick count with overlapped strafes on the specified mode.
 */
native int MoreStats_GetOverlap(int client, int mode, int scope);

/**
 * Gets a player's number of deadair ticks.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param scope			Tracker scope.
 * @return				Player's deadair tick count on the specified mode.
 */
native int MoreStats_GetDeadAir(int client, int mode, int scope);

/**
 * Gets a player's number of airstrafe ticks with bad angles.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param scope			Tracker scope.
 * @return				Player's number of airstrafe ticks with bad angles on the specified mode.
 */
native int MoreStats_GetBadAngles(int client, int mode, int scope);

/**
 * Gets a player's tick count in the air where player accelerated horizontally.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param scope			Tracker scope.
 * @return				Player's accelerated tick count on the specified mode.
 */
native int MoreStats_GetAirAccelTime(int client, int mode, int scope);

/**
 * Gets a player's tick count where player air acceleration would result in a velocity change.
 *
 * @param client		Client index.
 * @param mode			Client mode.
 * @param scope			Tracker scope.
 * @return				Player's tick count on the specified mode.
 */
native int MoreStats_GetAirVelChangeTime(int client, int mode, int scope);

// Dependency

public SharedPlugin __pl_more_stats = 
{
	name = "more-stats", 
	file = "more-stats.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_more_stats_SetNTVOptional()
{
	MarkNativeAsOptional("MoreStats_GetResetCount");
	MarkNativeAsOptional("MoreStats_GetCompletionCount");
	MarkNativeAsOptional("MoreStats_GetBhopTicks");
	MarkNativeAsOptional("MoreStats_GetPerfStreaks");
	MarkNativeAsOptional("MoreStats_GetScrollStats");
	MarkNativeAsOptional("MoreStats_GetPerfCount");
	MarkNativeAsOptional("MoreStats_GetAirTime");
	MarkNativeAsOptional("MoreStats_GetStrafeCount");
	MarkNativeAsOptional("MoreStats_GetOverlap");
	MarkNativeAsOptional("MoreStats_GetDeadAir");
	MarkNativeAsOptional("MoreStats_GetBadAngles");
	MarkNativeAsOptional("MoreStats_GetAirAccelTime");
	MarkNativeAsOptional("MoreStats_GetAirVelChangeTime");	
}
#endif
#define STEAMWORKS_HTTP_TIMEOUT_DURATION 60
#define RUNTIME_MAX_DEVIATION 0.01
#define LOCAL_MAX_WAIT_TIME 30

enum
{
	RunAnnounceType_LocalOnly,
	RunAnnounceType_GlobalOnly,
	RunAnnounceType_Both,
	RunAnnounceType_LocalFallback, // Fallback to local ranking is the map is not global or API is down
	RunAnnounceType_Count
};

enum
{
	RecordType_Default = 0,
	RecordType_LocalNubPB,
	RecordType_LocalProPB,
	RecordType_LocalNubTop,
	RecordType_LocalProTop,
	RecordType_GlobalNubTop,
	RecordType_GlobalProTop,
	RecordType_LocalNubSR,
	RecordType_LocalProSR,
	RecordType_GlobalNubWR,
	RecordType_GlobalProWR
};

stock char gC_RecordType_Names[RecordType_GlobalProWR + 1][] = 
{
	"Default",
	"Local Nub PB",
	"Local Pro PB",
	"Local Nub Top",
	"Local Pro Top",
	"Global Nub Top",
	"Global Pro Top",
	"Nub SR",
	"Pro SR",
	"Nub WR",
	"Pro WR"
};

enum struct Record {
	char playerName[MAX_NAME_LENGTH];
	int accountID;
	char fullAccountID[32];
	char steamID32[32];
	char steamID64[32];
	char mapName[64];
	int course;
	int mode;
	float runTime;
	int teleportsUsed;

	// Local ranking variables	
	int style;
	bool firstTime;
	float pbDiff;
	int rank;
	int maxRank;
	bool firstTimePro;
	float pbDiffPro;
	int rankPro;
	int maxRankPro;	

	// Global ranking variables
	int rankGlobal;
	int rankOverallGlobal;
	int timeType;

	// Run timestamp
	int timestamp;

	// Don't compare matched runs
	bool matchedLocal;
	bool matchedGlobal;

	// more-stats integration
	int bhopCount;
	int perfCount;
	int airTime;
	int strafeCount;
	int overlap;
	int deadAir;
	int badAngles;
	int aaTime;
	int velChangeTime;
	int scrollStats[5];
	
	// Core methods
	void Init(int client, int course, float time, int teleportsUsed)
	{
		GetClientName(client, this.playerName, MAX_NAME_LENGTH);
		this.accountID = GetSteamAccountID(client);
		GetClientAuthId(client, AuthId_Steam2, this.steamID32, sizeof(Record::steamID32));
		GetClientAuthId(client, AuthId_Steam3, this.fullAccountID, sizeof(Record::fullAccountID));
		GetClientAuthId(client, AuthId_SteamID64, this.steamID64, sizeof(Record::steamID64));
		this.course = course;
		this.mode = GOKZ_GetCoreOption(client, Option_Mode);
		this.runTime = time;
		this.teleportsUsed = teleportsUsed;
		this.timestamp = GetTime();
		GetCurrentMapDisplayName(this.mapName, sizeof(Record::mapName));
	}

	// Local ranking methods
	bool InitLocal(int accountID, int mapID, int course, int mode, int style, float runTime, int teleportsUsed, 
		bool firstTime, float pbDiff, int rank, int maxRank, bool firstTimePro, float pbDiffPro, int rankPro, int maxRankPro)
	{
		
		// We don't try to match maps, this can cause a very unlikely problem that runs on different maps are matched.
		if (!this.matchedLocal
			&& this.accountID == accountID
			&& this.course == course
			&& this.mode == mode
			&& this.teleportsUsed == teleportsUsed
			&& FloatAbs(this.runTime - runTime) <= RUNTIME_MAX_DEVIATION
			&& this.timestamp + LOCAL_MAX_WAIT_TIME > GetTime()) // It is extremely unlikely that a SQL query takes 30 seconds.
		{
			this.matchedLocal = true;
			this.style = style;
			this.firstTime = firstTime;
			this.pbDiff = pbDiff;
			this.rank = rank;
			this.maxRank = maxRank;
			this.firstTimePro = firstTimePro;
			this.pbDiffPro = pbDiffPro;
			this.rankPro = rankPro;
			this.maxRankPro = maxRankPro;
			return true;
		}
		else 
		{
			return false;
		}
	}

	// Global ranking methods
	bool InitGlobal(int client, int course, int mode, int timeType, int rank, int rankOverall, float runTime)
	{
		if (!this.matchedGlobal
			&& this.accountID == GetSteamAccountID(client)
			&& this.course == course
			&& this.mode == mode
			&& ((this.teleportsUsed != 0 && timeType == TimeType_Nub) || (this.teleportsUsed == 0 && timeType == TimeType_Pro))
			&& FloatAbs(this.runTime - runTime) <= RUNTIME_MAX_DEVIATION
			&& this.timestamp + STEAMWORKS_HTTP_TIMEOUT_DURATION > GetTime())
		{
			this.rankGlobal = rank;
			this.rankOverallGlobal = rankOverall;
			this.matchedGlobal = true;
			this.timeType = timeType;
			return true;
		}
		else
		{
			return false;
		}
	}

	int GetRecordType(int minTopRank, int minTopRankGlobal)
	{
		int recordType = RecordType_Default;
		if (this.matchedGlobal)
		{
			if (this.timeType == TimeType_Nub && this.rankOverallGlobal != 0)
			{
				if (this.rankOverallGlobal == 1)
				{
					recordType = IntMax(recordType, RecordType_GlobalNubWR);
				}
				else if (this.rankOverallGlobal <= minTopRankGlobal)
				{
					recordType = IntMax(recordType, RecordType_GlobalNubTop);
				}
			}
			else if (this.timeType == TimeType_Pro)
			{
				if (this.rankOverallGlobal != 0)
				{
					if (this.rankOverallGlobal == 1)
					{
						recordType = IntMax(recordType, RecordType_GlobalProWR);
					}
					else if (this.rankOverallGlobal <= minTopRankGlobal)
					{
						recordType = IntMax(recordType, RecordType_GlobalProTop);
					}
				}
				if (this.rankGlobal == 1)
				{
					recordType = IntMax(recordType, RecordType_GlobalProWR);
				}
				else if (this.rankGlobal <= minTopRankGlobal)
				{
					recordType = IntMax(recordType, RecordType_GlobalProTop);
				}
			}
		}
		if (this.matchedLocal)
		{
			if ((this.firstTime || this.pbDiff < 0) && this.rank == 1)
			{
				recordType = IntMax(recordType, RecordType_LocalNubSR);
			}
			if ((this.firstTimePro || this.pbDiffPro < 0) && this.rankPro == 1)
			{
				recordType = IntMax(recordType, RecordType_LocalProSR);
			}
			if (this.teleportsUsed == 0)
			{
				if (this.firstTimePro)
				{
					recordType = IntMax(recordType, RecordType_LocalProPB);
				}
				else if (this.pbDiffPro < 0)
				{
					recordType = IntMax(recordType, RecordType_LocalProPB);
				}
				if (recordType == RecordType_LocalProPB && this.rankPro <= minTopRank)
				{
					recordType = IntMax(recordType, RecordType_LocalProTop);
				}
			}
			else
			{
				if (this.firstTime)
				{
					recordType = IntMax(recordType, RecordType_LocalNubPB);
				}
				else if (this.pbDiff < 0)
				{
					recordType = IntMax(recordType, RecordType_LocalNubPB);
				}
				if (recordType == RecordType_LocalNubPB && this.rank < minTopRank)
				{
					recordType = IntMax(recordType, RecordType_LocalNubTop)
				}
			}
		}
		return recordType;
	}

	void InitMoreStats(int bhopCount, int perfCount, int airTime, int strafeCount, 
		int overlap, int deadAir, int badAngles, int aaTime, int velChangeTime, int scrollStats[5])
	{
		this.bhopCount = bhopCount;
		this.perfCount = perfCount;
		this.airTime = airTime;
		this.strafeCount = strafeCount;
		this.overlap = overlap;
		this.deadAir = deadAir;
		this.badAngles = badAngles;
		this.aaTime = aaTime;
		this.velChangeTime = velChangeTime;
		this.scrollStats = scrollStats;
	}
}
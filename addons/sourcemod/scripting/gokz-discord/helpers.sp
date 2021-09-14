void GetWebHook(char[] url, int size)
{
	gKV_DiscordConfig.Rewind();
	if (!gKV_DiscordConfig.JumpToKey("Webhook"))
	{
		SetFailState("[GetWebHook] Failed to obtain Discord webhook!");
	}
	gKV_DiscordConfig.GetString("url", url, size);
}

void DiscordReplaceString(Record record, char[] input, int size)
{
	char buffer[128];
	ReplaceString(input, size, "MAP_NAME", record.mapName);

	IntToString(record.course, buffer, sizeof(buffer));
	ReplaceString(input, size, "COURSE_NUMBER", buffer);

	ReplaceString(input, size, "PLAYER_STEAM2", record.steamID32);
	ReplaceString(input, size, "PLAYER_STEAM3", record.fullAccountID);
	ReplaceString(input, size, "PLAYER_FULLACCOUNTID", record.fullAccountID);
	IntToString(record.accountID, buffer, sizeof(buffer));
	ReplaceString(input, size, "PLAYER_ACCOUNTID", buffer);
	ReplaceString(input, size, "PLAYER_STEAM64", record.steamID64);

	GetConVarString(FindConVar("hostname"), buffer, sizeof(buffer));
	ReplaceString(input, size, "HOST_NAME", buffer);	
	int ip[4];
	SteamWorks_GetPublicIP(ip);
	FormatEx(buffer, sizeof(buffer), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
	ReplaceString(input, size, "HOST_IP", buffer);
	IntToString(FindConVar("hostport").IntValue, buffer, sizeof(buffer));
	ReplaceString(input, size, "HOST_PORT", buffer);

	gKV_DiscordConfig.Rewind();
	if (!gKV_DiscordConfig.JumpToKey("Modes"))
	{
		SetFailState("[GOKZ-Discord] Failed to obtain Discord Modes config!");
	}
	gKV_DiscordConfig.GetString(gC_ModeNames[record.mode], buffer, sizeof(buffer));
	ReplaceString(input, size, "MODE_NAME", buffer);
}
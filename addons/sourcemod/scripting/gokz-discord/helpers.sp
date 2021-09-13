void GetWebHook(char[] url, int size)
{
	gKV_DiscordConfig.Rewind();
	if (!gKV_DiscordConfig.JumpToKey("Webhook"))
	{
		SetFailState("[GetWebHook] Failed to obtain Discord webhook!");
	}
	gKV_DiscordConfig.GetString("url", url, size);
}

void DiscordReplaceString(Record record, char[] url, int size)
{
	ReplaceString(url, size, "MAP_NAME", record.mapName);
	ReplaceString(url, size, "PLAYER_STEAM2", record.steamID32);
	ReplaceString(url, size, "PLAYER_STEAM3", record.fullAccountID);
	ReplaceString(url, size, "PLAYER_FULLACCOUNTID", record.fullAccountID);
	char accountIDString[16];
	IntToString(record.accountID, accountIDString, sizeof(accountIDString));
	ReplaceString(url, size, "PLAYER_ACCOUNTID", accountIDString);
	ReplaceString(url, size, "PLAYER_STEAM64", record.steamID64);
	
	char buffer[128];
	GetConVarString(FindConVar("hostname"), buffer, sizeof(buffer));
	ReplaceString(url, size, "HOST_NAME", buffer);
	
	int ip[4];
	SteamWorks_GetPublicIP(ip);
	FormatEx(buffer, sizeof(buffer), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
	ReplaceString(url, size, "HOST_IP", buffer);
	IntToString(FindConVar("hostport").IntValue, buffer, sizeof(buffer));
	ReplaceString(url, size, "HOST_PORT", buffer);
}
#include <sourcemod>
#include <SteamWorks>
Database gH_DB;
public void OnPluginStart()
{
	char error[512];

	gH_DB = SQL_Connect("gokz", true, error, sizeof(error));

	if (gH_DB == null)
	{
		SetFailState("Database connection failed. Error: \"%s\".", error);
	}
	RegConsoleCmd("sm_test", CommandTest);
	RegConsoleCmd("sm_test2", CommandTest2);
}

public Action CommandTest(int client, int argc)
{
	SendPlayerData();
	ServerCommand("map baxter");
}

public Action CommandTest2(int client, int argc)
{
	return Plugin_Handled;
}
void SendPlayerData()
{
	char[] url = "https://csrd.science/";
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, url);

	bool settimeout = SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
	bool setcallback = SteamWorks_SetHTTPCallbacks(hRequest, POSTCallback);

	if(!hRequest || !settimeout || !setcallback) 
	{
		LogError("Error in setting request properties, cannot send request");
		CloseHandle(hRequest);
		return;
	}

	if (!SteamWorks_SendHTTPRequest(hRequest))
	{
		LogError("Error sending request!");
		CloseHandle(hRequest);
		return;
	}
	
}

public void POSTCallback( Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	if(!bRequestSuccessful || bFailure) 
	{
		// Putting this in comments because we don't want to flood the server log if the prestrafe backend is down.
		// LogError("There was an error in the request");
		CloseHandle(hRequest);
		return;
	}

	if(eStatusCode != k_EHTTPStatusCode200OK) 
	{
		PrintToServer("Expected status 200, but got %d instead!", eStatusCode);
		CloseHandle(hRequest);
		return;
	}
}

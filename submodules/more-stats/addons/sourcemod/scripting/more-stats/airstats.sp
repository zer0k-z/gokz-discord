void InitializeAirStats(int client)
{
	gB_AirStatsLoaded[client] = false;

	for (int i = 0; i < sizeof(gF_OldVelocity[]); i++)
	{
		gF_OldVelocity[client][i] = 0.0;
	}
	gB_OldOnGround[client] = false;	
	gI_StrafeDirection[client] = 0;

	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		ResetVariable(gI_AirTime[client][mode], sizeof(gI_AirTime[][]));
		ResetVariable(gI_Strafes[client][mode], sizeof(gI_Strafes[][]));
		ResetVariable(gI_Overlap[client][mode], sizeof(gI_Overlap[][]));
		ResetVariable(gI_DeadAir[client][mode], sizeof(gI_DeadAir[][]));
		ResetVariable(gI_BadAngles[client][mode], sizeof(gI_BadAngles[][]));
		ResetVariable(gI_AirAccelTime[client][mode], sizeof(gI_AirAccelTime[][]));
		ResetVariable(gI_AirVelChangeTime[client][mode], sizeof(gI_AirVelChangeTime[][]));
	}

}

void OnPlayerRunCmdPost_AirStats(int client, int buttons, const float vel[3], const float angles[3])
{
	if (Movement_GetMovetype(client) == MOVETYPE_WALK && !Movement_GetOnGround(client))
	{
		UpdateAirStats(client, buttons, vel, angles);
		UpdateStrafes(client);
	}
	else
	{
		int mode = GOKZ_GetCoreOption(client, Option_Mode);

		gI_StrafeDirection[client] = StrafeDirection_None;
		if (gB_ChatAirStats[client] && gI_AirTime[client][mode][Scope_InAir] != 0)
		{
			PrintChatAirStats(client);
		}
		gI_AirTime[client][mode][Scope_InAir] = 0;
		gI_Strafes[client][mode][Scope_InAir] = 0;
		gI_Overlap[client][mode][Scope_InAir] = 0;
		gI_DeadAir[client][mode][Scope_InAir] = 0;
		gI_BadAngles[client][mode][Scope_InAir] = 0;
		gI_AirAccelTime[client][mode][Scope_InAir] = 0;
		gI_AirVelChangeTime[client][mode][Scope_InAir] = 0;
	}

	Movement_GetVelocity(client, gF_OldVelocity[client]);
}
void UpdateAirStats(int client, int buttons, const float vel[3], const float angles[3])
{
	IncrementVariable(client, gI_AirTime[client][GOKZ_GetCoreOption(client, Option_Mode)], true);

	// Sync2 is ratio between ticks where horizontal speed is increased over tick in air
	// Sync3 is ratio between ticks where client air acceleration would have an impact on velocity over ticks in air.
	// Most of the time, Sync2 would be smaller than Sync3...
	// ... except for the first tick acceleration, where you can still gain speed from previous tick's ground acceleration.
	// Sync3 doesn't decrease if player's air accleration doesn't ultimately cause a velocity change (airstrafing into wall).

	// CalculateSync3 also calculates dead air, overlaps and bad angles.
	CalculateSync2(client);
	CalculateSync3(client, buttons, vel, angles);
}

void CalculateSync2(int client)
{	
	if (Movement_GetSpeed(client) > GetVectorHorizontalLength(gF_OldVelocity[client]))
	{
		IncrementVariable(client, gI_AirAccelTime[client][GOKZ_GetCoreOption(client, Option_Mode)], true);
	}
}
void CalculateSync3(int client, int buttons, const float vel[3], const float angles[3])
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	// Mirrored from the SDK, but we don't care how much the acceleration value is, we only care if there is any acceleration (or deceleration) at all.
	
	float wishvel[3];
	float fmove, smove;
	float fwrd[3];
	float right[3];

	fmove = vel[0];
	smove = vel[1];

	GetAngleVectors(angles, fwrd, right, NULL_VECTOR);
	fwrd[2] = 0.0;
	right[2] = 0.0;
	NormalizeVector(fwrd, fwrd);
	NormalizeVector(right, right);

	for (int i = 0; i < 2; i++)
	{
		wishvel[i] = fwrd[i] * fmove + right[i] * smove;
	}
	wishvel[2] = 0.0;
	float wishspeed = NormalizeVector(wishvel, wishvel);

	float maxSpeed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");

	if ( wishspeed != 0 && (wishspeed > maxSpeed))
	{
		ScaleVector(wishvel, maxSpeed/wishspeed);
		wishspeed = maxSpeed;
	}
	if (wishspeed > 30.0) wishspeed = 30.0;
	// If player tries to accelerate
	
	float currentspeed = GetVectorDotProduct(gF_OldVelocity[client], wishvel);
	float addspeed = wishspeed - currentspeed;
	if (addspeed > 0) 
	{
		IncrementVariable(client, gI_AirVelChangeTime[client][mode], true);
	}
	else
	{
		if (wishspeed > 0)
		{
			// There is acceleration applied, but due to bad angles it has no effect.
			// Example: late W release causes acceleration direction to be incorrect.
			IncrementVariable(client, gI_BadAngles[client][mode], true);
		}
		else
		{
			if (buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || buttons & IN_FORWARD || buttons & IN_BACK)
			{
				// The player is pressing at least one strafe key
				// But since their acceleration value is 0, it must be overlapping with another key.
				IncrementVariable(client, gI_Overlap[client][mode], true);
			}
			else
			{
				// No movement key, dead air
				IncrementVariable(client, gI_DeadAir[client][mode], true);
			}
		}
	}
}

void UpdateStrafes(client)
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	if (Movement_GetTurningLeft(client) && gI_StrafeDirection[client] != StrafeDirection_Left)
	{
		gI_StrafeDirection[client] = StrafeDirection_Left;
		IncrementVariable(client, gI_Strafes[client][mode], true);
	}
	else if (Movement_GetTurningRight(client) && gI_StrafeDirection[client] != StrafeDirection_Right)
	{
		gI_StrafeDirection[client] = StrafeDirection_Right;
		IncrementVariable(client, gI_Strafes[client][mode], true);
	}
}

void PrintChatAirStats(int client)
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	float sync2 = gI_AirTime[client][mode][Scope_InAir] == 0 ? 0.0 : float(gI_AirAccelTime[client][mode][Scope_InAir]) / gI_AirTime[client][mode][Scope_InAir] * 100;	
	float sync3 = gI_AirTime[client][mode][Scope_InAir] == 0 ? 0.0 : float(gI_AirVelChangeTime[client][mode][Scope_InAir]) / gI_AirTime[client][mode][Scope_InAir] * 100;

	GOKZ_PrintToChat(client, true, "{lime}%i {grey}Strafes | Sync: {lime}%.2f{grey}%%%% / {lime}%.2f{grey}%%%% | Air: {lime}%i {grey}| OL: {lime}%i {grey}| DA: {lime}%i {grey}| BA: {lime}%i",
		gI_Strafes[client][mode][Scope_InAir],
		sync2,
		sync3,
		gI_AirTime[client][mode][Scope_InAir],
		gI_Overlap[client][mode][Scope_InAir],
		gI_DeadAir[client][mode][Scope_InAir],
		gI_BadAngles[client][mode][Scope_InAir]);
}

void PrintAirStats(int client, int mode, int scope)
{
	PrintToConsole(client, "-----------------------");
	PrintToConsole(client, "Airstats (%i ticks, %i strafes)", gI_AirTime[client][mode][scope], gI_Strafes[client][mode][scope]);
	PrintToConsole(client, "-----------------------");

	float sync2 = gI_AirTime[client][mode][scope] == 0 ? 0.0 : float(gI_AirAccelTime[client][mode][scope]) / gI_AirTime[client][mode][scope] * 100;
	PrintToConsole(client, "Acceleration Sync: %11i ticks (%.2f%%)", gI_AirAccelTime[client][mode][scope], sync2);

	float sync3 = gI_AirTime[client][mode][scope] == 0 ? 0.0 : float(gI_AirVelChangeTime[client][mode][scope]) / gI_AirTime[client][mode][scope] * 100;
	PrintToConsole(client, "Velocity Change Sync: %8i ticks (%.2f%%)", gI_AirVelChangeTime[client][mode][scope], sync3);

	PrintToConsole(client, "Overlap: %21i ticks (%.2f%%)", gI_Overlap[client][mode][scope], 
		gI_AirTime[client][mode][scope] == 0 ? 0.0 : float(gI_Overlap[client][mode][scope]) / gI_AirTime[client][mode][scope] * 100);
	PrintToConsole(client, "Dead Airtime: %16i ticks (%.2f%%)",	gI_DeadAir[client][mode][scope],
		gI_AirTime[client][mode][scope] == 0 ? 0.0 : float(gI_DeadAir[client][mode][scope]) / gI_AirTime[client][mode][scope] * 100);
	PrintToConsole(client, "Bad Angles: %18i ticks (%.2f%%)", gI_BadAngles[client][mode][scope],
		gI_AirTime[client][mode][scope] == 0 ? 0.0 : float(gI_BadAngles[client][mode][scope]) / gI_AirTime[client][mode][scope] * 100);
}

void GOKZ_OnTimerStart_Post_AirStats(int client)
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	gI_AirTime[client][mode][Scope_Run] = 0;
	gI_Strafes[client][mode][Scope_Run] = 0;
	gI_Overlap[client][mode][Scope_Run] = 0;
	gI_DeadAir[client][mode][Scope_Run] = 0;
	gI_BadAngles[client][mode][Scope_Run] = 0;
	gI_AirAccelTime[client][mode][Scope_Run] = 0;
	gI_AirVelChangeTime[client][mode][Scope_Run] = 0;
}

void GOKZ_OnTimerEnd_Post_AirStats(int client)
{
	PrintAirStats(client, GOKZ_GetCoreOption(client, Option_Mode), Scope_Run);
}

int GetAirTime(int client, int mode, int scope)
{
	return gI_AirTime[client][mode][scope];
}

int GetStrafeCount(int client, int mode, int scope)
{
	return gI_Strafes[client][mode][scope];
}

int GetOverlap(int client, int mode, int scope)
{
	return gI_Overlap[client][mode][scope];
}

int GetDeadAir(int client, int mode, int scope)
{
	return gI_DeadAir[client][mode][scope];
}

int GetBadAngles(int client, int mode, int scope)
{
	return gI_BadAngles[client][mode][scope];
}

int GetAirAccelTime(int client, int mode, int scope)
{
	return gI_AirAccelTime[client][mode][scope];
}

int GetAirVelChangeTime(int client, int mode, int scope)
{
	return gI_AirVelChangeTime[client][mode][scope];
}
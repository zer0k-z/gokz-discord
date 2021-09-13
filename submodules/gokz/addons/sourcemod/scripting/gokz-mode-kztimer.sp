#include <sourcemod>

#include <sdkhooks>
#include <sdktools>

#include <movementapi>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <gokz/core>
#include <updater>

#include <gokz/kzplayer>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Mode - KZTimer", 
	author = "DanZay", 
	description = "KZTimer mode for GOKZ", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-mode-kztimer.txt"

#define MODE_VERSION 208
#define DUCK_SPEED_NORMAL 8.0
#define PRE_VELMOD_MAX 1.104 // Calculated 276/250
#define PERF_SPEED_CAP 380.0

float gF_ModeCVarValues[MODECVAR_COUNT] = 
{
	6.5,  // sv_accelerate
	0.0,  // sv_accelerate_use_weapon_speed
	100.0,  // sv_airaccelerate
	30.0,  // sv_air_max_wishspeed
	1.0,  // sv_enablebunnyhopping
	5.0,  // sv_friction
	800.0,  // sv_gravity
	301.993377,  // sv_jump_impulse
	1.0,  // sv_ladder_scale_speed
	0.0,  // sv_ledge_mantle_helper
	320.0,  // sv_maxspeed
	2000.0,  // sv_maxvelocity
	0.0,  // sv_staminajumpcost
	0.0,  // sv_staminalandcost
	0.0,  // sv_staminamax
	0.0,  // sv_staminarecoveryrate
	0.7,  // sv_standable_normal
	0.0,  // sv_timebetweenducks
	0.7,  // sv_walkable_normal
	10.0,  // sv_wateraccelerate
	0.8,  // sv_water_movespeed_multiplier
	0.0,  // sv_water_swim_mode 
	0.0,  // sv_weapon_encumbrance_per_item
	0.0 // sv_weapon_encumbrance_scale
};

bool gB_GOKZCore;
ConVar gCV_ModeCVar[MODECVAR_COUNT];
float gF_PreVelMod[MAXPLAYERS + 1];
float gF_PreVelModLastChange[MAXPLAYERS + 1];
int gI_PreTickCounter[MAXPLAYERS + 1];
int gI_OldButtons[MAXPLAYERS + 1];
int gI_OldFlags[MAXPLAYERS + 1];
bool gB_OldOnGround[MAXPLAYERS + 1];
float gF_OldAngles[MAXPLAYERS + 1][3];
float gF_OldVelocity[MAXPLAYERS + 1][3];
bool gB_Jumpbugged[MAXPLAYERS + 1];



// =====[ PLUGIN EVENTS ]=====

public void OnPluginStart()
{
	if (FloatAbs(1.0 / GetTickInterval() - 128.0) > EPSILON)
	{
		SetFailState("gokz-mode-kztimer only supports 128 tickrate servers.");
	}
	
	CreateConVars();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	if (LibraryExists("gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_KZTimer, true, MODE_VERSION);
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public void OnPluginEnd()
{
	if (gB_GOKZCore)
	{
		GOKZ_SetModeLoaded(Mode_KZTimer, false);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	else if (StrEqual(name, "gokz-core"))
	{
		gB_GOKZCore = true;
		GOKZ_SetModeLoaded(Mode_KZTimer, true, MODE_VERSION);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	gB_GOKZCore = gB_GOKZCore && !StrEqual(name, "gokz-core");
}



// =====[ CLIENT EVENTS ]=====

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThinkPost, SDKHook_OnClientPreThink_Post);
	SDKHook(client, SDKHook_PostThink, SDKHook_OnClientPostThink);
	if (IsUsingMode(client))
	{
		ReplicateConVars(client);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return Plugin_Continue;
	}
	
	KZPlayer player = KZPlayer(client);
	RemoveCrouchJumpBind(player, buttons);
	TweakVelMod(player);
	ReduceDuckSlowdown(player);
	FixWaterBoost(player, buttons);
	FixDisplacementStuck(player);
	if (gB_Jumpbugged[player.ID])
	{
		TweakJumpbug(player);
	}
	
	gB_Jumpbugged[player.ID] = false;
	gI_OldButtons[player.ID] = buttons;
	gI_OldFlags[player.ID] = GetEntityFlags(client);
	gB_OldOnGround[player.ID] = Movement_GetOnGround(client);
	gF_OldAngles[player.ID] = angles;
	Movement_GetVelocity(client, gF_OldVelocity[client]);
	
	return Plugin_Continue;
}

public void SDKHook_OnClientPreThink_Post(int client)
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return;
	}
	
	// Don't tweak convars if GOKZ isn't running
	if (gB_GOKZCore)
	{
		TweakConVars();
	}
}

public void Movement_OnStopTouchGround(int client, bool jumped)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = KZPlayer(client);
	if (jumped)
	{
		TweakJump(player);
	}
	else if (gB_GOKZCore)
	{
		player.GOKZHitPerf = false;
		player.GOKZTakeoffSpeed = player.TakeoffSpeed;
	}
}

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	if (jumpbug)
	{
		gB_Jumpbugged[client] = true;
	}
}

public void SDKHook_OnClientPostThink(int client)
{
	if (!IsPlayerAlive(client) || !IsUsingMode(client))
	{
		return;
	}
	
	/*
		Why are we using PostThink for slope boost fix?
		
		MovementAPI measures landing speed, calls forwards etc. during 
		PostThink_Post. We want the slope fix to apply it's speed before 
		MovementAPI does this, so that we can apply tweaks based on the 
		'fixed' landing speed.
	*/
	SlopeFix(client);
}

public void Movement_OnChangeMovetype(int client, MoveType oldMovetype, MoveType newMovetype)
{
	if (!IsUsingMode(client))
	{
		return;
	}
	
	KZPlayer player = KZPlayer(client);
	if (gB_GOKZCore && newMovetype == MOVETYPE_WALK)
	{
		player.GOKZHitPerf = false;
		player.GOKZTakeoffSpeed = player.TakeoffSpeed;
	}
}

public void GOKZ_OnOptionChanged(int client, const char[] option, any newValue)
{
	if (StrEqual(option, gC_CoreOptionNames[Option_Mode]) && newValue == Mode_KZTimer)
	{
		ReplicateConVars(client);
	}
}

public void GOKZ_OnCountedTeleport_Post(int client)
{
	KZPlayer player = KZPlayer(client);
	ResetPrestrafeVelMod(player);
}



// =====[ GENERAL ]=====

bool IsUsingMode(int client)
{
	// If GOKZ core isn't loaded, then apply mode at all times
	return !gB_GOKZCore || GOKZ_GetCoreOption(client, Option_Mode) == Mode_KZTimer;
}



// =====[ CONVARS ]=====

void CreateConVars()
{
	for (int cvar = 0; cvar < MODECVAR_COUNT; cvar++)
	{
		gCV_ModeCVar[cvar] = FindConVar(gC_ModeCVars[cvar]);
	}
}

void TweakConVars()
{
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i].FloatValue = gF_ModeCVarValues[i];
	}
}

void ReplicateConVars(int client)
{
	// Replicate convars only when player changes mode in GOKZ
	// so that lagg isn't caused by other players using other
	// modes, and also as an optimisation.
	
	if (IsFakeClient(client))
	{
		return;
	}
	
	for (int i = 0; i < MODECVAR_COUNT; i++)
	{
		gCV_ModeCVar[i].ReplicateToClient(client, FloatToStringEx(gF_ModeCVarValues[i]));
	}
}



// =====[ VELOCITY MODIFIER ]=====

void TweakVelMod(KZPlayer player)
{
	player.VelocityModifier = CalcPrestrafeVelMod(player) * CalcWeaponVelMod(player);
}

// Adapted from KZTimerGlobal
float CalcPrestrafeVelMod(KZPlayer player)
{
	if (!player.OnGround)
	{
		return gF_PreVelMod[player.ID];
	}
	
	if (!player.Turning)
	{
		if (GetEngineTime() - gF_PreVelModLastChange[player.ID] > 0.2)
		{
			gF_PreVelMod[player.ID] = 1.0;
			gF_PreVelModLastChange[player.ID] = GetEngineTime();
		}
		else if (gF_PreVelMod[player.ID] > PRE_VELMOD_MAX + 0.007)
		{
			return PRE_VELMOD_MAX - 0.001; // Returning without setting the variable is intentional
		}
	}
	else if ((player.Buttons & IN_MOVELEFT || player.Buttons & IN_MOVERIGHT) && player.Speed > 248.9)
	{
		float increment = 0.0009;
		if (gF_PreVelMod[player.ID] > 1.04)
		{
			increment = 0.001;
		}
		
		bool forwards = GetClientMovingDirection(player.ID, false) > 0.0;
		
		if ((player.Buttons & IN_MOVERIGHT && player.TurningRight || player.TurningLeft && !forwards)
			 || (player.Buttons & IN_MOVELEFT && player.TurningLeft || player.TurningRight && !forwards))
		{
			gI_PreTickCounter[player.ID]++;
			
			if (gI_PreTickCounter[player.ID] < 75)
			{
				gF_PreVelMod[player.ID] += increment;
				if (gF_PreVelMod[player.ID] > PRE_VELMOD_MAX)
				{
					if (gF_PreVelMod[player.ID] > PRE_VELMOD_MAX + 0.007)
					{
						gF_PreVelMod[player.ID] = PRE_VELMOD_MAX - 0.001;
					}
					else
					{
						gF_PreVelMod[player.ID] -= 0.007;
					}
				}
				gF_PreVelMod[player.ID] += increment;
			}
			else
			{
				gF_PreVelMod[player.ID] -= 0.0045;
				gI_PreTickCounter[player.ID] -= 2;
				
				if (gF_PreVelMod[player.ID] < 1.0)
				{
					gF_PreVelMod[player.ID] = 1.0;
					gI_PreTickCounter[player.ID] = 0;
				}
			}
		}
		else
		{
			gF_PreVelMod[player.ID] -= 0.04;
			
			if (gF_PreVelMod[player.ID] < 1.0)
			{
				gF_PreVelMod[player.ID] = 1.0;
			}
		}
		
		gF_PreVelModLastChange[player.ID] = GetEngineTime();
	}
	else
	{
		gI_PreTickCounter[player.ID] = 0;
		return 1.0; // Returning without setting the variable is intentional
	}
	
	return gF_PreVelMod[player.ID];
}

// Adapted from KZTimerGlobal
float GetClientMovingDirection(int client, bool ladder)
{
	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVelocity);
	
	float fEyeAngles[3];
	GetClientEyeAngles(client, fEyeAngles);
	
	if (fEyeAngles[0] > 70.0)fEyeAngles[0] = 70.0;
	if (fEyeAngles[0] < -70.0)fEyeAngles[0] = -70.0;
	
	float fViewDirection[3];
	
	if (ladder)
	{
		GetEntPropVector(client, Prop_Send, "m_vecLadderNormal", fViewDirection);
	}
	else
	{
		GetAngleVectors(fEyeAngles, fViewDirection, NULL_VECTOR, NULL_VECTOR);
	}
	
	NormalizeVector(fVelocity, fVelocity);
	NormalizeVector(fViewDirection, fViewDirection);
	
	float direction = GetVectorDotProduct(fVelocity, fViewDirection);
	if (ladder)
	{
		direction = direction * -1;
	}
	return direction;
}

void ResetPrestrafeVelMod(KZPlayer player)
{
	gF_PreVelMod[player.ID] = 1.0;
	gI_PreTickCounter[player.ID] = 0;
}

float CalcWeaponVelMod(KZPlayer player)
{
	return SPEED_NORMAL / player.MaxSpeed;
}



// =====[ SLOPEFIX ]=====

// ORIGINAL AUTHORS : Mev & Blacky
// URL : https://forums.alliedmods.net/showthread.php?p=2322788
// NOTE : Modified by DanZay for this plugin

void SlopeFix(int client)
{
	// Check if player landed on the ground
	if (Movement_GetOnGround(client) && !gB_OldOnGround[client])
	{
		// Set up and do tracehull to find out if the player landed on a slope
		float vPos[3];
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);
		
		float vMins[3];
		GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
		
		float vMaxs[3];
		GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);
		
		float vEndPos[3];
		vEndPos[0] = vPos[0];
		vEndPos[1] = vPos[1];
		vEndPos[2] = vPos[2] - gF_ModeCVarValues[ModeCVar_MaxVelocity];
		
		TR_TraceHullFilter(vPos, vEndPos, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceRayDontHitSelf, client);
		
		if (TR_DidHit())
		{
			// Gets the normal vector of the surface under the player
			float vPlane[3], vLast[3];
			TR_GetPlaneNormal(null, vPlane);
			
			// Make sure it's not flat ground and not a surf ramp (1.0 = flat ground, < 0.7 = surf ramp)
			if (0.7 <= vPlane[2] < 1.0)
			{
				/*
					Copy the ClipVelocity function from sdk2013 
					(https://mxr.alliedmods.net/hl2sdk-sdk2013/source/game/shared/gamemovement.cpp#3145)
					With some minor changes to make it actually work
				*/
				vLast[0] = gF_OldVelocity[client][0];
				vLast[1] = gF_OldVelocity[client][1];
				vLast[2] = gF_OldVelocity[client][2];
				vLast[2] -= (gF_ModeCVarValues[ModeCVar_Gravity] * GetTickInterval() * 0.5);
				
				float fBackOff = GetVectorDotProduct(vLast, vPlane);
				
				float change, vVel[3];
				for (int i; i < 2; i++)
				{
					change = vPlane[i] * fBackOff;
					vVel[i] = vLast[i] - change;
				}
				
				float fAdjust = GetVectorDotProduct(vVel, vPlane);
				if (fAdjust < 0.0)
				{
					for (int i; i < 2; i++)
					{
						vVel[i] -= (vPlane[i] * fAdjust);
					}
				}
				
				vVel[2] = 0.0;
				vLast[2] = 0.0;
				
				// Make sure the player is going down a ramp by checking if they actually will gain speed from the boost
				if (GetVectorLength(vVel) > GetVectorLength(vLast))
				{
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
				}
			}
		}
	}
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return entity != data && !(0 < entity <= MaxClients);
}



// =====[ JUMPING ]=====

void TweakJump(KZPlayer player)
{
	if (player.HitPerf)
	{
		if (player.TakeoffSpeed > PERF_SPEED_CAP)
		{
			// Note that resulting velocity has same direction as landing velocity, not current velocity
			float velocity[3], baseVelocity[3], newVelocity[3];
			player.GetVelocity(velocity);
			player.GetBaseVelocity(baseVelocity);
			player.GetLandingVelocity(newVelocity);
			newVelocity[2] = velocity[2];
			SetVectorHorizontalLength(newVelocity, PERF_SPEED_CAP);
			AddVectors(newVelocity, baseVelocity, newVelocity);
			player.SetVelocity(newVelocity);
			if (gB_GOKZCore)
			{
				player.GOKZHitPerf = true;
				player.GOKZTakeoffSpeed = player.Speed;
			}
		}
		else if (gB_GOKZCore)
		{
			player.GOKZHitPerf = true;
			player.GOKZTakeoffSpeed = player.TakeoffSpeed;
		}
	}
	else if (gB_GOKZCore)
	{
		player.GOKZHitPerf = false;
		player.GOKZTakeoffSpeed = player.TakeoffSpeed;
	}
}

void TweakJumpbug(KZPlayer player)
{
	if (player.Speed > PERF_SPEED_CAP)
	{
		Movement_SetSpeed(player.ID, PERF_SPEED_CAP, true);
	}
	if (gB_GOKZCore)
	{
		player.GOKZHitPerf = true;
		player.GOKZTakeoffSpeed = player.Speed;
	}
}



// =====[ OTHER ]=====

void FixWaterBoost(KZPlayer player, int buttons)
{
	if (GetEntProp(player.ID, Prop_Send, "m_nWaterLevel") >= 2) // WL_Waist = 2
	{
		// If duck is being pressed and we're not already ducking or on ground
		if (GetEntityFlags(player.ID) & (FL_DUCKING | FL_ONGROUND) == 0
			&& buttons & IN_DUCK && ~gI_OldButtons[player.ID] & IN_DUCK)
		{
			float newOrigin[3];
			Movement_GetOrigin(player.ID, newOrigin);
			newOrigin[2] += 9.0;
			
			TR_TraceHullFilter(newOrigin, newOrigin, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 54.0}), MASK_PLAYERSOLID, TraceEntityFilterPlayers);
			if (!TR_DidHit())
			{
				TeleportEntity(player.ID, newOrigin, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

void FixDisplacementStuck(KZPlayer player)
{
	int flags = GetEntityFlags(player.ID);
	bool unducked = ~flags & FL_DUCKING && gI_OldFlags[player.ID] & FL_DUCKING;
	
	float standingMins[] = {-16.0, -16.0, 0.0};
	float standingMaxs[] = {16.0, 16.0, 72.0};
	
	if (unducked)
	{
		// check if we're stuck after unducking and if we're stuck then force duck
		float origin[3];
		Movement_GetOrigin(player.ID, origin);
		TR_TraceHullFilter(origin, origin, standingMins, standingMaxs, MASK_PLAYERSOLID, TraceEntityFilterPlayers);
		
		if (TR_DidHit())
		{
			player.SetVelocity(gF_OldVelocity[player.ID]);
			SetEntProp(player.ID, Prop_Send, "m_bDucking", true);
		}
	}
}

void RemoveCrouchJumpBind(KZPlayer player, int &buttons)
{
	if (player.OnGround && buttons & IN_JUMP && !(gI_OldButtons[player.ID] & IN_JUMP) && !(gI_OldButtons[player.ID] & IN_DUCK))
	{
		buttons &= ~IN_DUCK;
	}
}

void ReduceDuckSlowdown(KZPlayer player)
{
	if (GetEntProp(player.ID, Prop_Data, "m_afButtonReleased") & IN_DUCK)
	{
		Movement_SetDuckSpeed(player.ID, DUCK_SPEED_NORMAL);
	}
} 
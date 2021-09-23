stock void FillArray(any[][] array, int length, int scope, any value)
{
	for (int i = 0; i < length; i++)
	{
		array[i][scope] = value;
	}
}

stock void SetVariable(int client, int[] variable, int val)
{
    variable[Scope_AllTime] = val;
    variable[Scope_Session] = val;
    if (GOKZ_GetTimerRunning(client))
    {
        variable[Scope_Run] = val;
    }
    if (!gB_SegmentPaused[client])
    {
        variable[Scope_Segment] = val;
    }
    if (Movement_GetMovetype(client) == MOVETYPE_WALK && !Movement_GetOnGround(client))
    {
        variable[Scope_InAir] = val;
    }
}

stock void AddToVariable(int client, int[] variable, int val, bool jump = false, int cap = 2147483647)
{
    if (variable[Scope_AllTime] <= (cap - val))
    {
        variable[Scope_AllTime] += val;
    }
    if (variable[Scope_Session] <= (cap - val))
    {
        variable[Scope_Session] += val;
    }
    if (GOKZ_GetTimerRunning(client) && variable[Scope_Run] <= (cap - val))
    {
        variable[Scope_Run] += val;
    }
    if (!gB_SegmentPaused[client] && variable[Scope_Segment] <= (cap - val))
    {
        variable[Scope_Segment] += val;
    }
    if (Movement_GetMovetype(client) == MOVETYPE_WALK && !Movement_GetOnGround(client) && jump && variable[Scope_InAir] <= (cap - val))
    {
        variable[Scope_InAir] += val;
    }
    
}

stock void IncrementVariable(int client, int[] variable, bool jump = false, int cap = 2147483647)
{
    AddToVariable(client, variable, 1, jump, cap);
}

stock void ResetVariable(int[] variable, int length)
{
    for (int i = 0; i < length; i++)
    {
        variable[i] = 0;
    }
}

void PrintCheckConsole(int client)
{
	GOKZ_PrintToChat(client, true, "Check console for results!");
}
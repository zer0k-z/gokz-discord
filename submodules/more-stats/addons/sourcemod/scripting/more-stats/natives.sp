void CreateNatives()
{
    CreateNative("MoreStats_GetResetCount", Native_GetResetCount);
    CreateNative("MoreStats_GetCompletionCount", Native_GetCompletionCount);

    CreateNative("MoreStats_GetBhopTicks", Native_GetBhopTicks);
    CreateNative("MoreStats_GetPerfStreaks", Native_GetPerfStreaks);
    CreateNative("MoreStats_GetScrollStats", Native_GetScrollStats);
    CreateNative("MoreStats_GetPerfCount", Native_GetPerfCount);
    
    CreateNative("MoreStats_GetAirTime", Native_GetAirTime);
    CreateNative("MoreStats_GetStrafeCount", Native_GetStrafeCount);
    CreateNative("MoreStats_GetOverlap", Native_GetOverlap);
    CreateNative("MoreStats_GetDeadAir", Native_GetDeadAir);
    CreateNative("MoreStats_GetBadAngles", Native_GetBadAngles);
    CreateNative("MoreStats_GetAirAccelTime", Native_GetAirAccelTime);
    CreateNative("MoreStats_GetAirVelChangeTime", Native_GetAirVelChangeTime);
}

public int Native_GetResetCount(Handle plugin, int numParams)
{
    return view_as<int>(GetResetCount(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4)));
}

public int Native_GetCompletionCount(Handle plugin, int numParams)
{
    return view_as<int>(GetCompletionCount(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5)));
}

public int Native_GetBhopTicks(Handle plugin, int numParams)
{
    return view_as<int>(GetBhopTicks(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4)));
}

public int Native_GetPerfStreaks(Handle plugin, int numParams)
{
    return view_as<int>(GetPerfStreaks(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4)));
}

public int Native_GetScrollStats(Handle plugin, int numParams)
{
    return view_as<int>(GetScrollStats(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4)));
}

public int Native_GetPerfCount(Handle plugin, int numParams)
{
    return view_as<int>(GetPerfCount(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3)));
}

public int Native_GetAirTime(Handle plugin, int numParams)
{
    return view_as<int>(GetAirTime(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3)));
}

public int Native_GetStrafeCount(Handle plugin, int numParams)
{
    return view_as<int>(GetStrafeCount(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3)));
}

public int Native_GetOverlap(Handle plugin, int numParams)
{
    return view_as<int>(GetOverlap(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3)));
}

public int Native_GetDeadAir(Handle plugin, int numParams)
{
    return view_as<int>(GetDeadAir(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3)));
}
public int Native_GetBadAngles(Handle plugin, int numParams)
{
    return view_as<int>(GetBadAngles(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3)));
}
public int Native_GetAirAccelTime(Handle plugin, int numParams)
{
    return view_as<int>(GetAirAccelTime(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3)));
}
public int Native_GetAirVelChangeTime(Handle plugin, int numParams)
{
    return view_as<int>(GetAirVelChangeTime(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3)));
}
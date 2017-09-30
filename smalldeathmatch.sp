#include <sourcemod>
#include <tf2>
#include <dynamic>
#include <sdktools_functions>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "SmallDeathmatch",
	author      = "mały",
	description = "A deathmatch plugin for TF2",
	version     = "1.0.0",
	url         = ""
};

ArrayList spawnsRed, spawnsBlue;

ConVar cvRandomSpawns;

public void OnPluginStart()
{
	spawnsRed = new ArrayList();
	spawnsBlue = new ArrayList();

	HookEvent("player_death", onPlayerDeath);
	cvRandomSpawns = CreateConVar("smalldm_random_spawns", "1", "Specifies whether random spawns (i.e. team-independent) are enabled or not", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public void OnPluginEnd()
{
	delete spawnsRed;
	delete spawnsBlue;
}

public void OnMapStart()
{
	char mapName[128];
	GetCurrentMap(mapName, sizeof(mapName));

	char mapCfgPath[256];
	BuildPath(Path_SM, mapCfgPath, sizeof(mapCfgPath), "configs/smalldm/%s.cfg", mapName);

	if (!loadSpawns(mapCfgPath)) {
		SetFailState("Failed loading deathmatch spawns for %s", mapName);
	}
}

public void OnMapEnd()
{
	for (int i = 0; i < spawnsRed.Length; ++i) {
		Dynamic s = spawnsRed.Get(i);
		s.Dispose();
	}
	spawnsRed.Clear();

	for (int i = 0; i < spawnsBlue.Length; ++i) {
		Dynamic s = spawnsBlue.Get(i);
		s.Dispose();
	}
	spawnsBlue.Clear();
}

void onPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	char attackerName[256];
	if (GetClientName(attacker, attackerName, sizeof(attackerName))) {
		if (attacker != victim) {
			int hp = GetClientHealth(attacker);
			PrintToChat(victim, "%s: %d", attackerName, hp);
		}

		CreateTimer(1.0, respawnPlayer, victim);
	}
}

bool loadSpawns(char[] cfgPath)
{
	if (!FileExists(cfgPath)) {
		LogError("File not found: %s", cfgPath);
		return false;
	}

	KeyValues kv = new KeyValues("Spawns");
	kv.ImportFromFile(cfgPath);

	if (kv.JumpToKey("red", false) && kv.GotoFirstSubKey(true)) {
		do {
			float origin[3], angles[3];
			kv.GetVector("origin", origin);
			kv.GetVector("angles", angles);

			Dynamic spawn = Dynamic();
			spawn.SetVector("origin", origin);
			spawn.SetVector("angles", angles);
			spawnsRed.Push(spawn);
		} while (kv.GotoNextKey(true));

		kv.GoBack(); kv.GoBack();
		LogMessage("Loaded %d RED spawns", spawnsRed.Length);
	} else {
		LogError("Missing RED spawns in %s", cfgPath);
		return false;
	}

	if (kv.JumpToKey("blue", false) && kv.GotoFirstSubKey(true)) {
		do {
			float origin[3], angles[3];
			kv.GetVector("origin", origin);
			kv.GetVector("angles", angles);

			Dynamic spawn = Dynamic();
			spawn.SetVector("origin", origin);
			spawn.SetVector("angles", angles);
			spawnsBlue.Push(spawn);
		} while (kv.GotoNextKey(true));

		LogMessage("Loaded %d BLU spawns", spawnsBlue.Length);
	} else {
		LogError("Missing BLU spawns in %s", cfgPath);
		return false;
	}

	return true;
}

Dynamic getRandomSpawn(int team)
{
	if (cvRandomSpawns.BoolValue) {
		team = GetRandomInt(0, 1) + 2;
	}

	switch (team) {
		case TFTeam_Red: {
			int idx = GetRandomInt(0, spawnsRed.Length - 1);
			return spawnsRed.Get(idx);
		}

		case TFTeam_Blue: {
			int idx = GetRandomInt(0, spawnsBlue.Length - 1);
			return spawnsBlue.Get(idx);
		}
	}

	return INVALID_DYNAMIC_OBJECT;
}

Action respawnPlayer(Handle timer, any client)
{
	TF2_RespawnPlayer(client);

	if (IsPlayerAlive(client)) {
		int team = GetClientTeam(client);
		Dynamic spawn = getRandomSpawn(team);
		if (!spawn.IsValid)
			return Plugin_Stop;

		float origin[3], angles[3];
		spawn.GetVector("origin", origin);
		spawn.GetVector("angles", angles);

		TeleportEntity(client, origin, angles, NULL_VECTOR);
	}

	return Plugin_Stop;
}

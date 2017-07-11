#include <sourcemod>
#include <dynamic>

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

public void OnPluginStart()
{
	spawnsRed = new ArrayList();
	spawnsBlue = new ArrayList();
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

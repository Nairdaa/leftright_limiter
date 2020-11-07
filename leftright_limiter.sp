#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"
#define BLOCK_TIME 1.0

int g_iBlockUse[MAXPLAYERS+1];

Handle g_hTimers[MAXPLAYERS+1][2];

public Plugin myinfo =
{
	name = "+left/+right limiter",
	author = "ici // ported to new syntax and fixed by Nairda",
	description = "Limits use of +left/+right command",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/1ci"
};

public void OnClientPutInServer(int client)
{
	g_iBlockUse[client] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	// Don't care if player is BOT or is dead
	if (IsFakeClient(client) || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	int iLastButtons[MAXPLAYERS+1];
	float fLastAngles[MAXPLAYERS+1][3];

	if (buttons & IN_LEFT) {
		if (!(iLastButtons[client] & IN_LEFT)) {
			// Player started pressing +left so block +right
			blockUse(client, IN_RIGHT);
		}
		if (g_iBlockUse[client] & IN_LEFT) {
			// Player is not allowed to +left
			TeleportEntity(client, NULL_VECTOR, fLastAngles[client], NULL_VECTOR);
			return Plugin_Continue;
		}
		for (int i=0; i<3; ++i)
			fLastAngles[client][i] = angles[i];
	}

	if (buttons & IN_RIGHT) {
		if (!(iLastButtons[client] & IN_RIGHT)) {
			// Player started pressing +right so block +left
			blockUse(client, IN_LEFT);
		}
		if (g_iBlockUse[client] & IN_RIGHT) {
			// Player is not allowed to +right
			TeleportEntity(client, NULL_VECTOR, fLastAngles[client], NULL_VECTOR);
			return Plugin_Continue;
		}
		for (int i=0; i<3; ++i)
			fLastAngles[client][i] = angles[i];
	}

	iLastButtons[client] = buttons;
	return Plugin_Continue;
}

void blockUse(int client, int button)
{
	g_iBlockUse[client] |= button;

	int index = button / IN_LEFT - 1;
	if (g_hTimers[client][index] != INVALID_HANDLE)
		CloseHandle(g_hTimers[client][index]);

	Handle pack;
	g_hTimers[client][index] = CreateDataTimer(BLOCK_TIME, Timer_AllowUse, pack);

	WritePackCell(pack, client);
	WritePackCell(pack, button);
}

public Action Timer_AllowUse(Handle timer, Handle pack)
{
	ResetPack(pack);

	int client = ReadPackCell(pack);
	int button = ReadPackCell(pack);
	int index = button / IN_LEFT - 1;

	g_hTimers[client][index] = INVALID_HANDLE;

	g_iBlockUse[client] &= ~button;
}

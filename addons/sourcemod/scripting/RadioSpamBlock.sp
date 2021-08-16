#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

#define PLUGIN_VERSION	"1.1"

int last_radio_use[MAXPLAYERS+1];
int note[MAXPLAYERS+1];

Handle cvar_radio_spam_block = INVALID_HANDLE;
Handle cvar_radio_spam_block_time = INVALID_HANDLE;
Handle cvar_radio_spam_block_all = INVALID_HANDLE;
Handle cvar_radio_spam_block_notify = INVALID_HANDLE;

bool notify = true;

public Plugin myinfo = 
{
	name = "Radio Spam Block",
	author = "exvel, maxime1907",
	description = "Blocking players from radio spam. Also can disable radio commands for all players on the server if option is set.",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	CreateConVar("sm_radio_spam_block_version", PLUGIN_VERSION, "Radio Spam Block Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvar_radio_spam_block = CreateConVar("sm_radio_spam_block", "1", "0 = disabled, 1 = enabled Radio Spam Block functionality", 0, true, 0.0, true, 1.0);
	cvar_radio_spam_block_time = CreateConVar("sm_radio_spam_block_time", "5", "Time in seconds between radio messages", 0, true, 1.0, true, 60.0);
	cvar_radio_spam_block_all = CreateConVar("sm_radio_spam_block_all", "0", "0 = disabled, 1 = block all radio messages", 0, true, 0.0, true, 1.0);
	cvar_radio_spam_block_notify = CreateConVar("sm_radio_spam_block_notify", "1", "0 = disabled, 1 = show a chat message to the player when his radio spam blocked", 0, true, 0.0, true, 1.0);

	for (int i = 0; i <= MAXPLAYERS; i++)
		last_radio_use[i] = -1;

	RegConsoleCmd("coverme", RestrictRadio);
	RegConsoleCmd("takepoint", RestrictRadio);
	RegConsoleCmd("holdpos", RestrictRadio);
	RegConsoleCmd("regroup", RestrictRadio);
	RegConsoleCmd("followme", RestrictRadio);
	RegConsoleCmd("takingfire", RestrictRadio);
	RegConsoleCmd("go", RestrictRadio);
	RegConsoleCmd("fallback", RestrictRadio);
	RegConsoleCmd("sticktog", RestrictRadio);
	RegConsoleCmd("getinpos", RestrictRadio);
	RegConsoleCmd("stormfront", RestrictRadio);
	RegConsoleCmd("report", RestrictRadio);
	RegConsoleCmd("roger", RestrictRadio);
	RegConsoleCmd("enemyspot", RestrictRadio);
	RegConsoleCmd("needbackup", RestrictRadio);
	RegConsoleCmd("sectorclear", RestrictRadio);
	RegConsoleCmd("inposition", RestrictRadio);
	RegConsoleCmd("reportingin", RestrictRadio);
	RegConsoleCmd("getout", RestrictRadio);
	RegConsoleCmd("negative", RestrictRadio);
	RegConsoleCmd("enemydown", RestrictRadio);

	LoadTranslations("radiospamblock.phrases.txt");

	AutoExecConfig(true);
}

public Action RestrictRadio(int client, int args)
{
	if (!IsValidClient(client) || !GetConVarBool(cvar_radio_spam_block))
		return Plugin_Handled;

	notify = GetConVarBool(cvar_radio_spam_block_notify);

	if (GetConVarBool(cvar_radio_spam_block_all))
	{
		if (notify)
			PrintToChat(client, "[SM] %t", "Disabled");
		return Plugin_Handled;
	}

	if (last_radio_use[client] == -1)
	{
		last_radio_use[client] = GetTime();
		return Plugin_Continue;
	}

	int time = GetTime() - last_radio_use[client];
	int block_time = GetConVarInt(cvar_radio_spam_block_time);
	if (time >= block_time)
	{
		last_radio_use[client] = GetTime();
		return Plugin_Continue;
	}
	
	int wait_time = block_time - time;

	if ((note[client] != wait_time) && notify)
	{
		if (wait_time <= 1)
			PrintToChat(client, "[SM] %t", "Wait 1 second");
		else
			PrintToChat(client, "[SM] %t", "Wait X seconds", wait_time);
	}
	
	note[client] = wait_time;
	return Plugin_Handled;
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>

bool g_bProtoBuf;
bool g_bBlocked[MAXPLAYERS + 1];
int g_bRadioLastUse[MAXPLAYERS+1];
int note[MAXPLAYERS+1];
int g_iMessageClient = -1;

Handle cvar_radio_spam_block = INVALID_HANDLE;
Handle cvar_radio_spam_block_time = INVALID_HANDLE;
Handle cvar_radio_spam_block_all = INVALID_HANDLE;
Handle cvar_radio_spam_block_notify = INVALID_HANDLE;

bool notify = true;

public Plugin myinfo = 
{
	name = "Radio Spam Block",
	author = "exvel, maxime1907, Obus, .Rushaway",
	description = "Blocking players from radio spam. Also can disable radio commands for all players on the server if option is set.",
	version = "1.2.0",
	url = ""
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("radiospamblock.phrases.txt");

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
		g_bProtoBuf = true;

	UserMsg RadioText = GetUserMessageId("RadioText");
	if (RadioText == INVALID_MESSAGE_ID)
		SetFailState("This game does not support the \"RadioText\" UserMessage.");

	UserMsg SendAudio = GetUserMessageId("SendAudio");
	if (SendAudio == INVALID_MESSAGE_ID)
		SetFailState("This game does not support the \"SendAudio\" UserMessage.");

	cvar_radio_spam_block = CreateConVar("sm_radio_spam_block", "1", "0 = disabled, 1 = enabled Radio Spam Block functionality", 0, true, 0.0, true, 1.0);
	cvar_radio_spam_block_time = CreateConVar("sm_radio_spam_block_time", "5", "Time in seconds between radio messages", 0, true, 1.0, true, 60.0);
	cvar_radio_spam_block_all = CreateConVar("sm_radio_spam_block_all", "0", "0 = disabled, 1 = block all radio messages", 0, true, 0.0, true, 1.0);
	cvar_radio_spam_block_notify = CreateConVar("sm_radio_spam_block_notify", "1", "0 = disabled, 1 = show a chat message to the player when his radio spam blocked", 0, true, 0.0, true, 1.0);

	RegAdminCmd("sm_radiomute", Command_RadioMute, ADMFLAG_BAN, "Block a client from using the in-game radio.");
	RegAdminCmd("sm_radiounmute", Command_RadioUnmute, ADMFLAG_BAN, "Unblock a client from using the in-game radio.");

	for (int i = 0; i <= MAXPLAYERS; i++)
		g_bRadioLastUse[i] = -1;

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


	HookUserMessage(RadioText, Hook_RadioText, true);
	HookUserMessage(SendAudio, Hook_SendAudio, true);

	AutoExecConfig(true);
}

public void OnClientConnected(int client)
{
	g_bBlocked[client] = false;
	g_bRadioLastUse[client] = -1;
}

public void OnClientDisconnect(int client)
{
	g_bBlocked[client] = false;
	g_bRadioLastUse[client] = -1;
}

public Action Command_RadioMute(int client, int argc)
{
	if (argc < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_radiomute <target>");
		return Plugin_Handled;
	}

	char sArgs[64], sTargetName[MAX_NAME_LENGTH];
	int iTargets[MAXPLAYERS], iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0) {
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
		g_bBlocked[iTargets[i]] = true;

	CShowActivity2(client, "{green}[SM]{olive}", " {default}Radio muted {olive}%s", sTargetName);
	LogAction(client, -1, "\"%L\" radio muted \"%s\"", client, sTargetName);

	return Plugin_Handled;
}

public Action Command_RadioUnmute(int client, int argc)
{
	if (argc < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_radiounmute <target>");
		return Plugin_Handled;
	}

	char sArgs[64], sTargetName[MAX_NAME_LENGTH];
	int iTargets[MAXPLAYERS], iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0) {
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
		g_bBlocked[iTargets[i]] = false;

	CShowActivity2(client, "{green}[SM]{olive}", " {default}Radio unmuted {olive}%s", sTargetName);
	LogAction(client, -1, "\"%L\" radio unmuted \"%s\"", client, sTargetName);

	return Plugin_Handled;
}

public Action Hook_RadioText(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if (!g_bProtoBuf)
		return Plugin_Continue;
	
	g_iMessageClient = PbReadInt(bf, "client");

	if (g_bBlocked[g_iMessageClient])
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action Hook_SendAudio(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if (!g_bProtoBuf || g_iMessageClient == -1)
		return Plugin_Continue;

	char sSound[128];
	PbReadString(bf, "radio_sound", sSound, sizeof(sSound));

	if (strncmp(sSound[6], "lock", 4, false) == 0)
		return Plugin_Continue;

	if (g_bBlocked[g_iMessageClient]) {
		g_iMessageClient = -1;
		return Plugin_Handled;
	}

	g_iMessageClient = -1;
	return Plugin_Continue;
}

public Action RestrictRadio(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	SetGlobalTransTarget(client);

	if (g_bBlocked[client]) {
		PrintToChat(client, "[SM] %t", "Radio muted");
		return Plugin_Handled;
	}

	if (!GetConVarBool(cvar_radio_spam_block))
		return Plugin_Handled;

	notify = GetConVarBool(cvar_radio_spam_block_notify);

	if (GetConVarBool(cvar_radio_spam_block_all))
	{
		if (notify)
			PrintToChat(client, "[SM] %t", "Disabled");
		return Plugin_Handled;
	}

	if (g_bRadioLastUse[client] == -1)
	{
		g_bRadioLastUse[client] = GetTime();
		return Plugin_Continue;
	}

	int time = GetTime() - g_bRadioLastUse[client];
	int block_time = GetConVarInt(cvar_radio_spam_block_time);
	if (time >= block_time)
	{
		g_bRadioLastUse[client] = GetTime();
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

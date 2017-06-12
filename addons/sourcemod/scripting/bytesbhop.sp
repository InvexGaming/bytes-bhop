//Inspired by: https://forums.alliedmods.net/showthread.php?t=289075
//As well as: https://github.com/shavitush/bhoptimer/blob/fc45e60ba0983c38d60b601a827c4d5a94861879/scripting/shavit-core.sp

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.02"

#define WATER_LEVEL_DRY     0
#define WATER_LEVEL_FEET    1
#define WATER_LEVEL_HALF    2
#define WATER_LEVEL_FULL    3

bool g_LateLoaded = false;

//Convar
ConVar g_Cvar_sv_autobunnyhopping = null;

public Plugin myinfo =
{
  name = "Byte's Bhop",
  author = "Invex | Byte",
  description = "Clean, lag free bhopping for CSGO.",
  version = PLUGIN_VERSION,
  url = "https://www.invexgaming.com.au"
}

ConVar g_BhopEnabled;
bool g_BhopActive[MAXPLAYERS+1] = {true, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
  g_LateLoaded = late;
  return APLRes_Success;
}

public void OnPluginStart()
{
  CreateConVar("sm_bytesbhop_version", PLUGIN_VERSION, "Byte's Bhop Plugin Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
  g_BhopEnabled = CreateConVar("sm_bytesbhop_enabled", "1", "Enable/disable the bunny hopping.");
  AutoExecConfig(true, "bytesbhop");
  
  //Reg commands
  RegConsoleCmd("sm_bhop", Command_Toggle_Bhop, "Toggle auto-bhop.");
  
  //Late load our hook
  if (g_LateLoaded) {
    for (int i = 1; i <= MaxClients; ++i) {
      if (IsClientInGame(i))
        OnClientPutInServer(i);
    }
    
    g_LateLoaded = false;
  }
}

public void OnMapStart()
{
  g_Cvar_sv_autobunnyhopping = FindConVar("sv_autobunnyhopping");
  g_Cvar_sv_autobunnyhopping.BoolValue = false;
  
  //Set convars for CSGO
  FindConVar("sv_enablebunnyhopping").BoolValue = true;
  FindConVar("sv_staminamax").IntValue = 0;
  FindConVar("sv_staminajumpcost").IntValue = 0;
  FindConVar("sv_staminalandcost").IntValue = 0;
}

public void OnClientPutInServer(int client)
{
  g_BhopActive[client] = true;
  SDKHook(client, SDKHook_PreThink, PreThink);
}

public void PreThink(int client)
{
  if (IsClientConnected(client) && IsPlayerAlive(client))
    UpdateAutoBhop(client);
}

public void UpdateAutoBhop(int client)
{
  if (g_Cvar_sv_autobunnyhopping != null) {
    g_Cvar_sv_autobunnyhopping.ReplicateToClient(client, g_BhopActive[client] ? "1" : "0");
  }
}

public Action Command_Toggle_Bhop(int client, int args) 
{
  if (!g_BhopEnabled.BoolValue)
    return Plugin_Handled;
  
  //Toggle auto-bhop
  if (IsClientInGame(client)) {
    g_BhopActive[client] = !g_BhopActive[client];
    PrintToChat(client, "[SM] Auto Bhop is now %s.", g_BhopActive[client] ? "enabled" : "disabled");
  }
  
  return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
  if (!g_BhopEnabled.BoolValue)
    return Plugin_Continue;
    
  if (!g_BhopActive[client])
    return Plugin_Continue;
    
  if (!IsPlayerAlive(client))
    return Plugin_Continue;
         
  if (!(buttons & IN_JUMP))
    return Plugin_Continue;
         
  if (GetEntityMoveType(client) & MOVETYPE_LADDER)
    return Plugin_Continue;

  if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > WATER_LEVEL_FEET)
    return Plugin_Continue;

  if (GetEntityFlags(client) & FL_ONGROUND)
    return Plugin_Continue;
    
  SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);

  buttons &= ~IN_JUMP;
  
  return Plugin_Continue;
}
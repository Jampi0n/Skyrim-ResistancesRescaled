// Based on https://github.com/xanderdunn/skaar/releases/tag/plugin3

#include <ShlObj.h>

#include "SkyrimEdition.h"
#include "ResistancesRescaled.h"

static PluginHandle	g_pluginHandle = kPluginHandle_Invalid;
static SKSEPapyrusInterface* g_papyrus = NULL;

#if NEW_VERSION_CHECK
extern "C" {
	SKSEPluginVersionData SKSEPlugin_Version =
	{
		SKSEPluginVersionData::kVersion,
		3,
		MOD_NAME,
		"Jampion",
		"",
		0,
		{ COMPATIBLE_VERSION, 0 },
		0,
	};

	bool SKSEPlugin_Query(const SKSEInterface* skse, PluginInfo* info) {
		gLog.OpenRelative(CSIDL_MYDOCUMENTS, "\\My Games\\" LOG_FILE);
		gLog.SetPrintLevel(IDebugLog::kLevel_Error);
		gLog.SetLogLevel(IDebugLog::kLevel_DebugMessage);
		info->infoVersion = PluginInfo::kInfoVersion;
		info->name = MOD_NAME;
		info->version = 1;
		_MESSAGE("This version of " MOD_NAME " is for a newer version of SKSE that uses the new plugin manager, but the running SKSE version still uses the old plugin manager.");
		_MESSAGE("Make sure you use matching versions of SKSE and " MOD_NAME);
		return false;
	}

	bool SKSEPlugin_Load(const SKSEInterface* skse) {	// Called by SKSE to load this plugin
		gLog.OpenRelative(CSIDL_MYDOCUMENTS, "\\My Games\\" LOG_FILE);
		gLog.SetPrintLevel(IDebugLog::kLevel_Error);
		gLog.SetLogLevel(IDebugLog::kLevel_DebugMessage);
		_MESSAGE(MOD_NAME " loaded");

		g_papyrus = (SKSEPapyrusInterface*)skse->QueryInterface(kInterface_Papyrus);

		//Check if the function registration was a success...
		bool btest = g_papyrus->Register(ResistancesRescaled::RegisterFuncs);

		if (btest) {
			_MESSAGE("Papyrus functions registered");
		}

		return true;
	}
};
#else
struct SKSEPluginVersionData {
	int dummy;
};
extern "C" {
	SKSEPluginVersionData SKSEPlugin_Version =
	{
		0
	};

	bool SKSEPlugin_Query(const SKSEInterface* skse, PluginInfo* info) {	// Called by SKSE to learn about this plugin and check that it's safe to load it
		gLog.OpenRelative(CSIDL_MYDOCUMENTS, "\\My Games\\" LOG_FILE);
		gLog.SetPrintLevel(IDebugLog::kLevel_Error);
		gLog.SetLogLevel(IDebugLog::kLevel_DebugMessage);


		_MESSAGE("Trying to load " MOD_NAME "...");

		// populate info structure
		info->infoVersion = PluginInfo::kInfoVersion;
		info->name = MOD_NAME;
		info->version = 3;

		// store plugin handle so we can identify ourselves later
		g_pluginHandle = skse->GetPluginHandle();

		if (skse->isEditor)
		{
			_MESSAGE("loaded in editor, marking as incompatible");

			return false;
		}
		else if (skse->runtimeVersion != COMPATIBLE_VERSION)
		{
			_MESSAGE("unsupported runtime version %08X", skse->runtimeVersion);

			return false;
		}

		// ### do not do anything else in this callback
		// ### only fill out PluginInfo and return true/false

		// supported runtime version
		return true;
	}

	bool SKSEPlugin_Load(const SKSEInterface* skse) {	// Called by SKSE to load this plugin
		_MESSAGE(MOD_NAME " loaded");

		g_papyrus = (SKSEPapyrusInterface*)skse->QueryInterface(kInterface_Papyrus);

		//Check if the function registration was a success...
		bool btest = g_papyrus->Register(ResistancesRescaled::RegisterFuncs);

		if (btest) {
			_MESSAGE("Papyrus functions registered");
		}

		return true;
	}

};
#endif


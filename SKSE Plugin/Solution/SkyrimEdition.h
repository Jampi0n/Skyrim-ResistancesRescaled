#pragma once

#if __has_include("skse/PluginAPI.h")
	#define LEGENDARY_EDITION 1
	#include "skse/PluginAPI.h"
	#include "skse/skse_version.h"
	#define MOD_NAME "ResistancesRescaledLE"
	#define LOG_FILE "Skyrim\\SKSE\\" MOD_NAME ".log"
	#define MINIMUM_VERSION RUNTIME_VERSION_1_9_32_0
	#define MAXIMUM_VERSION RUNTIME_VERSION_1_9_32_0
#else
	#define LEGENDARY_EDITION 0
	#include "skse64/PluginAPI.h"
	#include "skse64_common/skse_version.h"
	#define MOD_NAME "ResistancesRescaledSE"
	#define LOG_FILE "Skyrim Special Edition\\SKSE\\" MOD_NAME ".log"
	#define MINIMUM_VERSION RUNTIME_VERSION_1_5_97
	#define MAXIMUM_VERSION RUNTIME_VERSION_1_5_97
#endif


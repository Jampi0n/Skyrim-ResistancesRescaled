#pragma once

#include "SkyrimEdition.h"
#if LEGENDARY_EDITION
#include "skse/PapyrusNativeFunctions.h"
#else
#include "skse64/PapyrusNativeFunctions.h"
#endif

namespace ResistancesRescaled
{
	bool RegisterFuncs(VMClassRegistry* registry);
}

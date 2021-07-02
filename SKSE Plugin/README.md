# Requirements

* Skse source code: https://skse.silverlock.org/

# Setup

The project is configured to work with both LE and SE.

* Add environment variables SKSE32Path and SKSE64Path that point towards the src directory of skse solutions. The solution file should be located at "SKSE32Path\skse\skse.sln" and "SKSE64Path\skse64\skse64.sln"
* Add this project as a new project to the skse solution.

# Build

Open the skse solution and build the ResistancesRescaled project. LE and SE need to be built individually. There is currently no system to build them both at the same time.


# Development

Use the `LEGENDARY_EDITION` macro to include different files for LE and SE:
```#if LEGENDARY_EDITION
#include "skse/GameReferences.h"
#include "skse/GameObjects.h"
#else
#include "skse64/GameReferences.h"
#include "skse64/GameObjects.h"
#endif
```

In most cases no other parts need to be changed to support both LE and SE.

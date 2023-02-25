Scriptname JRR_Core extends Quest
{Core script that contains configurable parameters and interacts with the active magic effect.}

import JRR_NativeFunctions


string modName = "ResistancesRescaled"
string fileName = "MCM\\Config\\ResistancesRescaled\\settings.ini"
string fileNameUser = "MCM\\Settings\\ResistancesRescaled.ini"


bool function ReadBool(string settingName, bool default, bool current)
	if mcmHelperVersion >= requiredMcmHelperVersion
		return MCM.GetModSettingBool(modName,settingName)
	elseif papyrusIniVersion >= requiredPapyrusIniVersion
		return BufferedIni.ReadBoolEx(fileName, fileNameUser, settingName, default)
	else
		return current
	endif
endfunction

int function ReadInt(string settingName, int default, int current)
	if mcmHelperVersion >= requiredMcmHelperVersion
		return MCM.GetModSettingInt(modName, settingName)
	elseif papyrusIniVersion >= requiredPapyrusIniVersion
		return BufferedIni.ReadIntEx(fileName, fileNameUser, settingName, default)
	else
		return current
	endif
endfunction

float function ReadFloat(string settingName, float default, float current)
	if mcmHelperVersion >= requiredMcmHelperVersion
		return MCM.GetModSettingFloat(modName, settingName)
	elseif papyrusIniVersion >= requiredPapyrusIniVersion
		return BufferedIni.ReadFloatEx(fileName, fileNameUser, settingName, default)
	else
		return current
	endif
endfunction

function WriteBool(string settingName, bool value)
	if mcmHelperVersion >= requiredMcmHelperVersion
		MCM.SetModSettingBool(modName, settingName, value)
	elseif papyrusIniVersion >= requiredPapyrusIniVersion
    	PapyrusIni.WriteBool(fileNameUser, settingName, value as int)
	endif
endfunction

function WriteInt(string settingName, int value)
	if mcmHelperVersion >= requiredMcmHelperVersion
		MCM.SetModSettingInt(modName, settingName, value)
	elseif papyrusIniVersion >= requiredPapyrusIniVersion
    	PapyrusIni.WriteInt(fileNameUser, settingName, value)
	endif
endfunction

function WriteFloat(string settingName, float value)
	if mcmHelperVersion >= requiredMcmHelperVersion
		MCM.SetModSettingFloat(modName, settingName, value)
	elseif papyrusIniVersion >= requiredPapyrusIniVersion
    	PapyrusIni.WriteFloat(fileNameUser, settingName, value)
	endif
endfunction

int papyrusIniVersion = 0
int mcmHelperVersion = 0
int requiredPapyrusIniVersion = 1
int requiredMcmHelperVersion = 1

bool initialized = false

Actor property PlayerRef auto
JRR_ModConfigurationMenu property MCMQuest auto
Spell[] property DisplaySpells auto

int ID_MAGIC = 0
int ID_ELEMENTAL = 1
int ID_FIRE = 2
int ID_FROST = 3
int ID_SHOCK = 4
int ID_ARMOR = 5
int ID_POISON = 6

bool property magicEffectPreview = true auto hidden

; Names of the actor values to be used with ModAV.
string[] property actorValueName auto hidden

; Names of the resistances in the MCM and Config File
string[] property resistanceName auto hidden

; Function parameters for the rescale function (max,a,c).
float[] property functionParameters auto hidden


bool[] property resistanceEnabledValue auto hidden

; The desired damage reduction at 0 vanilla resistance.
int[] property resistanceReduction0Value  auto hidden

; The desired damage reduction at 100 vanilla resistance.
; For index == ID_ARMOR this is the desired damage reduction at 1000 vanilla resistance.
int[] property resistanceReduction100Value  auto hidden

; Holds the game settings: fPlayerMaxResistance
float property playerMaxResistanceValue = 100.0 auto hidden

; Holds the game settings: fMaxArmorRating
float property maxArmorRatingValue = 100.0 auto hidden

; Holds the game settings: fArmorScalingFactor
float property armorScalingFactorValue = 0.12 auto hidden

Perk Property DisplayPerk auto
Perk Property DisplayPerkSwap auto
bool useSwapPerk = false

; The mod uses one big data array, which is used to interface with the SKSE plugin.
; Every value the SKSE plugin changes must be inside this array, since this is the only return value of the plugin.
; Array modification is not used in the SKSE plugin in order to make it easier to adapt the scripts to CommonLib, which cannot edit papyrus arrays.

; The mod currently uses two kind of masks:
; av group mask: magic,elemental,armor,poison (1,2,4,8)
; av mask: magic,_,fire,frost,shock,armor,poison (1,2,4,8,16,32,64)
; note that the second index of av masks is unused
; the av mask correspons to the defined resistance ids of 0 to 6, so mask value = 2^resistanceId
; the av group mask correspons to the different resistance groups which share the same parameters, mask values are hardcoded

; data
int[] Property data auto hidden
; data layout:
; 0-20: resistance data, 3 elements per resistance (old value, vanilla value, unused, was modifier value)
; 0-2: magic
; 3-5: reserved for elemental
; 6-14: fire,frost,shock
; 15-17: armor
; 18-20: poison
; 21: forceUpdate
; 22: updateRunning
; 23: resetResistance
; 24: updateMask (av group mask)
; 25: resistanceEnabledMask (av group mask)
; 26: modEnabledValue
; 27: changed
; 28: avRescaled (av mask)
; 29: avReset (av mask)
; 30: avUpdated (av mask)

; Whether the next update recalculates all resistances, even if vanilla resistances did not change. default = false
; Will be set back to false after the next update is completed.
; Currently updates are forced, when the mod starts, the player loads the game and the mcm is exited.
; If formulas or parameters change, all resistances need to be recalculated.
bool Property forceUpdate hidden
	Function Set(bool newValue)
		data[21] = newValue as int
	EndFunction
	bool Function Get()
		return data[21] as bool
	EndFunction
EndProperty

; Whether the update loop is currently running. default = true
; This property is used by the mcm to determine how the My Resistances page looks like.
bool Property updateRunning hidden
	Function Set(bool newValue)
		data[22] = newValue as int
	EndFunction
	bool Function Get()
		return data[22] as bool
	EndFunction
EndProperty

; Bitwise representation of which resistances are supposed to be reset in the next update. default = 0x0
; This property is used to disable rescaling for one or more resistances.
int Property resetResistance hidden
	Function Set(int newValue)
		data[23] = newValue
	EndFunction
	int Function Get()
		return data[23]
	EndFunction
EndProperty

; Resistances handled in the last update. default = 0xf
; This property is used by the mcm to determine how the My Resistances page looks like.
int Property updateMask hidden
	Function Set(int newValue)
		data[24] = newValue
	EndFunction
	int Function Get()
		return data[24]
	EndFunction
EndProperty

; The desired set of resistances that are rescaled. default = 0xf
; This property is modified in the mcm to configure, which resistances are rescaled.
int Property resistanceEnabledMask hidden
	Function Set(int newValue)
		data[25] = newValue
	EndFunction
	int Function Get()
		return data[25]
	EndFunction
EndProperty


; The desired state of the mod. The actual state will only change in the next update. default = true
; This property is modified in the mcm to toggle rescaling.
bool Property modEnabledValue hidden
	Function Set(bool newValue)
		data[26] = newValue as int
	EndFunction
	bool Function Get()
		return data[26] as bool
	EndFunction
EndProperty

; Which actor value were rescaled in the last update. default = 0x0
; av mask for which resistances have been rescaled in the last update
; all resistances are included, for which a new rescaled value was calculated, even if it was the same as before (e.g. due to forced update)
; that means resistances for which rescaling is disabled will not be in the mask
; this property is currently not used
int Property avRescaled hidden
	Function Set(int newValue)
		data[27] = newValue
	EndFunction
	int Function Get()
		return data[27]
	EndFunction
EndProperty

; Which actor value were reset in the last update. default = 0x0
; av mask for which resistances have been reset in the last update
; this is generally the av mask corresponding to the av mask of resetResistance
; this property is currently not used
int Property avReset hidden
	Function Set(int newValue)
		data[28] = newValue
	EndFunction
	int Function Get()
		return data[28]
	EndFunction
EndProperty

; Which actor value were updated in the last update. default = 0x0
; This includes external AV updates to any resistances covered by this mod, regardless of whether rescaling is enabled for them.
; Rescaled and reset AVs are also included.
; This property is used to update the display perk, whenever a resistance changes.
; In order to be correct, it also needs to cover resistances, for which rescaling is disabled.
int Property avUpdated hidden
	Function Set(int newValue)
		data[29] = newValue
	EndFunction
	int Function Get()
		return data[29]
	EndFunction
EndProperty

bool Property syncSettings = false auto hidden

int[] property resistanceFormula auto hidden

float[] resultArray

Event OnInit()
	data = new int[30]
	int i = 0
	while i < 21
		data[i] = 0
		i += 1
	endwhile
	
	resultArray = new float[16]
	functionParameters = new float[70]
	resistanceEnabledValue = new bool[7]
	resistanceReduction0Value = new int[7]
	resistanceReduction100Value = new int[7]
	resistanceFormula = new int[7]
	actorValueName = new string[7]
	resistanceName = new string[7]
	actorValueName[ID_MAGIC] = "MagicResist"
	actorValueName[ID_FIRE] = "FireResist"
	actorValueName[ID_FROST] = "FrostResist"
	actorValueName[ID_SHOCK] = "ElectricResist"
	actorValueName[ID_ARMOR] = "DamageResist"
	actorValueName[ID_POISON] = "PoisonResist"

	resistanceName[ID_MAGIC] = "Magic"
	resistanceName[ID_ELEMENTAL] = "Elemental"
	resistanceName[ID_FIRE] = "Fire"
	resistanceName[ID_FROST] = "Frost"
	resistanceName[ID_SHOCK] = "Shock"
	resistanceName[ID_ARMOR] = "Armor"
	resistanceName[ID_POISON] = "Poison"
	i = 0
	while i < 7
		resistanceEnabledValue[i] = true
		resistanceReduction0Value[i] = 0
		resistanceReduction100Value[i] = 75
		resistanceFormula[i] = 0
		
		; Calculate default function parameters.
		if i == ID_ARMOR
			CalculateArmorParameters(resistanceFormula[i], resistanceReduction0Value[i], resistanceReduction100Value[i])
		else
			CalculateParameters(resistanceFormula[i], i, resistanceReduction0Value[i], resistanceReduction100Value[i])
		endif
		
		i += 1
	endwhile
	
	forceUpdate = false
	updateRunning = true
	resetResistance = 0
	updateMask = 0xf
	resistanceEnabledMask = 0xf
	modEnabledValue = true
	avRescaled = 0x0
	avReset = 0x0
	avUpdated = 0x0
	
	; On first start read the armor scaling factor
	armorScalingFactorValue = Game.GetGameSettingFloat("fArmorScalingFactor")
	
	initialized = true
	Maintenance()
EndEvent

function Recalculate(int resistanceID, bool readFromFile = false)
	if readFromFile
		resistanceEnabledValue[resistanceID] = ReadBool("bEnabled:"+ resistanceName[resistanceID], true, resistanceEnabledValue[resistanceID])
		resistanceFormula[resistanceID] = ReadInt("iFormula:" + resistanceName[resistanceID], 0, resistanceFormula[resistanceID])
		resistanceReduction0Value[resistanceID] = ReadInt("iAt0:" + resistanceName[resistanceID], 0, resistanceReduction0Value[resistanceID])
	endif
	
	if resistanceID == ID_ARMOR
		if readFromFile
			resistanceReduction100Value[resistanceID] = ReadInt("iAt1000:" + resistanceName[resistanceID], 75, resistanceReduction100Value[resistanceID])
		endif
		CalculateArmorParameters(resistanceFormula[resistanceID], resistanceReduction0Value[resistanceID], resistanceReduction100Value[resistanceID])
	else
		if readFromFile
			resistanceReduction100Value[resistanceID] = ReadInt("iAt100:" + resistanceName[resistanceID], 75, resistanceReduction100Value[resistanceID])
		endif
		CalculateParameters(resistanceFormula[resistanceID], resistanceID,  resistanceReduction0Value[resistanceID], resistanceReduction100Value[resistanceID])
	endif

	; update resistanceEnabledMask 
	int bit = 0
	if resistanceID == ID_MAGIC
		bit = 0x1
	elseif resistanceID == ID_ELEMENTAL
		bit = 0x2
	elseif resistanceID == ID_ARMOR
		bit = 0x4
	elseif resistanceID == ID_POISON
		bit = 0x8
	endif
	
	if resistanceEnabledValue[resistanceID]
		resistanceEnabledMask = Math.LogicalOr(resistanceEnabledMask, bit)
	else
		resistanceEnabledMask = Math.LogicalAnd(resistanceEnabledMask, Math.LogicalNot(bit))
	endif
endfunction


function Maintenance()
	if initialized
		papyrusIniVersion = PapyrusIni.GetPluginVersion()
		mcmHelperVersion = MCM.GetVersionCode()
		Debug.Trace("Resistances Rescaled: MCM Helper version = " + mcmHelperVersion + ", Papyrus Ini version = " + papyrusIniVersion)

		; Read settings from file (also writes defaukt values for any settings that do not exist)
		playerMaxResistanceValue = ReadFloat("fPlayerMaxResistance:General", 100.0, playerMaxResistanceValue)
		maxArmorRatingValue = ReadFloat("fMaxArmorRating:General", 100.0, maxArmorRatingValue)
		armorScalingFactorValue = ReadFloat("fArmorScalingFactor:General", 0.12, armorScalingFactorValue)
		modEnabledValue = ReadBool("bEnabled:General", true, modEnabledValue)
		magicEffectPreview = ReadBool("bMagicEffectPreview:General", true, magicEffectPreview)
		Recalculate(ID_MAGIC, true)
		Recalculate(ID_ELEMENTAL, true)
		Recalculate(ID_ARMOR, true)
		Recalculate(ID_POISON, true)
		if mcmHelperVersion < requiredMcmHelperVersion && papyrusIniVersion >= requiredPapyrusIniVersion
			BufferedIni.CloseBuffer(fileName)
			BufferedIni.CloseBuffer(fileNameUser)
		endif

		; Reapply game settings.
		Game.SetGameSettingFloat("fArmorBaseFactor", 0.0)
		Game.SetGameSettingFloat("fPlayerMaxResistance", playerMaxResistanceValue)
		Game.SetGameSettingFloat("fMaxArmorRating", maxArmorRatingValue)
		Game.SetGameSettingFloat("fArmorScalingFactor", armorScalingFactorValue)
		forceUpdate = true

		if modEnabledValue
			StartEffect()
		else
			FinishEffect()
		endif
		UpdateDisplayPerk()
		RegisterForSingleUpdate(0.4) ; Safety mechanism in case the script stopped and update was not scheduled
	endif
endfunction

function CalculateParameters(int formula, int resistanceID, int at0, int at100)
	functionParameters[resistanceID * 10] = formula as float
	functionParameters[resistanceID * 10 + 1] = at0
	functionParameters[resistanceID * 10 + 2] = at100
	functionParameters[resistanceID * 10 + 3] = 100
	functionParameters[resistanceID * 10 + 4] = 1
endfunction

function CalculateArmorParameters(int formula, int at0, int at1000)
	functionParameters[ID_ARMOR * 10] = formula as float
	functionParameters[ID_ARMOR * 10 + 1] = at0
	functionParameters[ID_ARMOR * 10 + 2] = at1000
	functionParameters[ID_ARMOR * 10 + 3] = 1000
	functionParameters[ID_ARMOR * 10 + 4] = armorScalingFactorValue
endfunction

function StartEffect()
	modEnabledValue = true
	updateRunning = true
	RegisterForSingleUpdate(0.4)
endfunction

function FinishEffect()
	modEnabledValue = false
endfunction

; Resets the resistance in the next update to vanilla.
function ResetToVanilla(int resistanceID)
	int bit = 0
	if resistanceID == ID_MAGIC
		bit = 0x1
	elseif resistanceID == ID_ELEMENTAL
		bit = 0x2
	elseif resistanceID == ID_ARMOR
		bit = 0x4
	elseif resistanceID == ID_POISON
		bit = 0x8
	endif
	resetResistance = Math.LogicalOr(resetResistance, bit)
endfunction


; Updates the active effects to display correct resistance values
; Uses perks to minimize function calls
; A swap perk with swap spells is used in order to avoid timing problems.
; On every update, the player gets new abilities, which will have correct values.
; The abilities with old values are removed.
function UpdateDisplayPerk()
	if magicEffectPreview && modEnabledValue
		if useSwapPerk
			useSwapPerk = false
			PlayerRef.RemovePerk(DisplayPerkSwap)
			PlayerRef.AddPerk(DisplayPerk)
		else
			useSwapPerk = true
			PlayerRef.RemovePerk(DisplayPerk)
			PlayerRef.AddPerk(DisplayPerkSwap)
		endif
	else
		PlayerRef.RemovePerk(DisplayPerkSwap)
		PlayerRef.RemovePerk(DisplayPerk)
	endif
endfunction

Event OnUpdate()
	; First check if mod is still enabled.
	bool enabled = modEnabledValue
	bool tmpForceUpdate = forceUpdate
	data = JRR_MainLoop(PlayerRef, data, functionParameters, DisplaySpells)
	if enabled
		; Schedule next update.
		RegisterForSingleUpdate(0.4)
		int tmp = avUpdated
		if magicEffectPreview
			if (tmpForceUpdate || (tmp != 0 && tmp != 32 )) ; != 32 ignores updates to damage resist
				UpdateDisplayPerk()
			endif
		endif
	endif
EndEvent

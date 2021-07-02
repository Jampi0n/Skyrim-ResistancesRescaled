Scriptname JRR_ModConfigurationMenu extends SKI_ConfigBase


import JRR_Core
import JRR_NativeFunctions

JRR_Core property coreScript auto
actor property PlayerRef auto

;===============

int function GetVersion()
	return 300
endFunction

;===============

int ID_MAGIC = 0
int ID_ELEMENTAL = 1
int ID_FIRE = 2
int ID_FROST = 3
int ID_SHOCK = 4
int ID_ARMOR = 5
int ID_POISON = 6

int currentResistanceID
string[] resistanceName

Event OnConfigInit()
	int i = 0
	Pages = new string[6]
	Pages[0] = "Magic"
	Pages[1] = "Elemental"
	Pages[2] = "Armor"
	Pages[3] = "Poison"
	Pages[4] = "My Resistances"
	Pages[5] = "Advanced"
	
	formulaName = new string[2]
	formulaName[0] = "$Hyperbolic"
	formulaName[1] = "$Exponential"
	
	resistanceEnabledButton = new int[7]
	resistanceReduction0Button = new int[7]
	resistanceReduction100Button = new int[7]
	resistanceEnabledTooltip = new string[7]
	resistanceFormulaButton = new int[7]
	resistanceName = new string[7]
	while i < 7
		resistanceEnabledButton[i] = 0
		resistanceReduction0Button[i] = 0
		resistanceReduction100Button[i] = 0
		i += 1
	endwhile

	resistanceName[ID_MAGIC] = "Magic"
	resistanceName[ID_ELEMENTAL] = "Elemental"
	resistanceName[ID_FIRE] = "Fire"
	resistanceName[ID_FROST] = "Frost"
	resistanceName[ID_SHOCK] = "Shock"
	resistanceName[ID_ARMOR] = "Armor"
	resistanceName[ID_POISON] = "Poison"
	
	resistanceEnabledTooltip[ID_MAGIC] = "Toggles whether the mod affects magic resistance."
	resistanceEnabledTooltip[ID_ELEMENTAL] = "Toggles whether the mod affects elemental (fire, frost and shock) resistances."
	resistanceEnabledTooltip[ID_ARMOR] = "Toggles whether the mod affects armor rating."
	resistanceEnabledTooltip[ID_POISON] = "Toggles whether the mod affects poison resistance."
	
	resistancePreviewTextButton = new int[32]
	previewValues = new int[32]
	
	previewSize = 0
	AddPreviewValue(0)
	AddPreviewValue(20)
	AddPreviewValue(40)
	AddPreviewValue(60)
	AddPreviewValue(80)
	AddPreviewValue(100)
	AddPreviewValue(140)
	AddPreviewValue(200)
EndEvent

function AddPreviewValue(int value)
	previewValues[previewSize] = value
	previewSize += 1
endfunction


string function GetVersionName(int version)
	int h = version/100
	version = (version - h*100)
	int t = version/10
	version = (version - t*10)
	int o = version
	return h+"."+t+"."+o
endfunction







int modEnabledButton = 0
int magicEffectPreviewButton = 0

int[] resistanceEnabledButton
string[] resistanceEnabledTooltip
int[] resistanceReduction0Button
int[] resistanceReduction100Button
int[] resistanceFormulaButton

string[] formulaName

int previewSize = 0
int[] previewValues
int[] resistancePreviewTextButton

; fPlayerMaxResistance
int playerMaxResistanceButton = 0

;fMaxArmorRating
int maxArmorRatingButton = 0

;fArmorScalingFactor
int armorScalingFactorButton = 0

int uninstallInformationButton = 0
int gameSettingInformationButton = 0


event OnOptionHighlight(int option)
	int i = 0
	bool break = false
	if option == modEnabledButton
		SetInfoText("Enable/Disable the mod.")
		return
	endif
	if option == magicEffectPreviewButton
		SetInfoText("Shows current resistances in active magic effects. Shows resistances regardless of whether rescaling is enabled for them.")
		return
	endif
	if option == playerMaxResistanceButton
		SetInfoText("Sets the maximum damage reduction for the player for magic and elemental resistances. Modifies the game setting fPlayerMaxResistance.")
		return
	endif
	if option == maxArmorRatingButton
		SetInfoText("Sets the maximum damage reduction for armor. Modifies the game setting fMaxArmorRating.")
		return
	endif
	if option == armorScalingFactorButton
		SetInfoText("Sets physical damage reduction per point of armor rating. Has no effect on the player while armor rescaling is enabled. Modifies the game setting fArmorScalingFactor.")
		return
	endif
	if option == uninstallInformationButton
		SetInfoText("Before you uninstall the mod, disable rescaling here and wait a few seconds outside of any menus. This ensures that all resistances are reset to their vanilla values.")
		return
	endif
	if option == gameSettingInformationButton
		SetInfoText("These settings generally do not need to be changed. Check the ReadMe for more information.")
		return
	endif
	
	if CurrentPage == "My Resistances"
		SetInfoText("The vanilla and rescaled values on this page are from the last update. If you changed some settings, close the menu for a few seconds so the values can update.")
		return
	endif
	
	if option == resistanceReduction0Button[currentResistanceID]
		if currentResistanceID != ID_ARMOR
			SetInfoText("Sets damage reduction at 0 vanilla resistance.")
			return
		else
			SetInfoText("Sets damage reduction at 0 vanilla armor rating.")
			return
		endif	
	elseif option == resistanceReduction100Button[currentResistanceID]
		if currentResistanceID != ID_ARMOR
			SetInfoText("Sets damage reduction at 100 vanilla resistance.")
			return
		else
			SetInfoText("Sets damage reduction at 1000 vanilla armor rating.")
			return
		endif
	elseif option == resistanceEnabledButton[currentResistanceID]
		SetInfoText(resistanceEnabledTooltip[currentResistanceID])
		return
	endif
endEvent

function AddPreviewText(int resistanceID)
	if resistanceID != ID_ARMOR
		int i = 0
		int value = 0
		while i < previewSize
			value = JRR_RescaleFunction(previewValues[i], coreScript.functionParameters, resistanceID * 10)
			resistancePreviewTextButton[i] = AddTextOption("$PreviewResistance{" + previewValues[i] + "}", ""+value+"%", OPTION_FLAG_DISABLED)
			i += 1
		endwhile
	else
		int i = 0
		int value = 0
		while i < previewSize
			value = (JRR_RescaleFunction(previewValues[i] * 10, coreScript.functionParameters, resistanceID * 10) * coreScript.armorScalingFactorValue) as int
			resistancePreviewTextButton[i] = AddTextOption("$PreviewArmorRating{" + (previewValues[i] * 10) + "}", ""+value+"%", OPTION_FLAG_DISABLED)
			i += 1
		endwhile
	endif
	;AddHeaderOption("$Current")
	if resistanceID != ID_ELEMENTAL
		if resistanceID != ID_ARMOR
			int vanilla = coreScript.data[resistanceID * 3 + 1]
			int value = JRR_RescaleFunction(vanilla, coreScript.functionParameters, resistanceID * 10)
			resistancePreviewTextButton[previewSize] = AddTextOption("$CurrentPreview{" +vanilla + "}", ""+value+"%", OPTION_FLAG_DISABLED)
		else
			int vanilla = coreScript.data[resistanceID * 3 + 1]
			int value = (JRR_RescaleFunction(vanilla, coreScript.functionParameters, resistanceID * 10) * coreScript.armorScalingFactorValue) as int
			resistancePreviewTextButton[previewSize] = AddTextOption("$CurrentPreviewArmor{" + vanilla + "}", ""+value+"%", OPTION_FLAG_DISABLED)
		endif
	else
		int vanillaFire = coreScript.data[ID_FIRE * 3 + 1]
		int vanillaFrost = coreScript.data[ID_FROST * 3 + 1]
		int vanillaShock = coreScript.data[ID_SHOCK * 3 + 1]
		int valueFire = JRR_RescaleFunction(vanillaFire, coreScript.functionParameters, resistanceID * 10)
		int valueFrost = JRR_RescaleFunction(vanillaFrost, coreScript.functionParameters, resistanceID * 10)
		int valueShock = JRR_RescaleFunction(vanillaShock, coreScript.functionParameters, resistanceID * 10)
		resistancePreviewTextButton[previewSize] = AddTextOption("$CurrentPreviewFire{" +vanillaFire + "}", ""+valueFire+"%", OPTION_FLAG_DISABLED)
		resistancePreviewTextButton[previewSize+1] = AddTextOption("$CurrentPreviewFrost{" +vanillaFrost + "}", ""+valueFrost+"%", OPTION_FLAG_DISABLED)
		resistancePreviewTextButton[previewSize+2] = AddTextOption("$CurrentPreviewShock{" +vanillaShock + "}", ""+valueShock+"%", OPTION_FLAG_DISABLED)
	endif
endfunction

function UpdatePreviewText(int resistanceID)
	if resistanceID != ID_ARMOR
		int i = 0
		int value = 0
		while i < previewSize
			value = JRR_RescaleFunction(previewValues[i], coreScript.functionParameters, resistanceID * 10)
			SetTextOptionValue(resistancePreviewTextButton[i], ""+value+"%", i != previewSize - 1)
			i += 1
		endwhile
	else
		int i = 0
		int value = 0
		while i < previewSize
			value = (JRR_RescaleFunction(previewValues[i] * 10, coreScript.functionParameters, resistanceID * 10) * coreScript.armorScalingFactorValue) as int
			SetTextOptionValue(resistancePreviewTextButton[i], ""+value+"%", i != previewSize - 1)
			i += 1
		endwhile
	endif

	if resistanceID != ID_ELEMENTAL
		if resistanceID != ID_ARMOR
			int vanilla = coreScript.data[resistanceID * 3 + 1]
			int value = JRR_RescaleFunction(vanilla, coreScript.functionParameters, resistanceID * 10)
			SetTextOptionValue(resistancePreviewTextButton[previewSize], ""+value+"%")
		else
			int vanilla = coreScript.data[resistanceID * 3 + 1]
			int value = (JRR_RescaleFunction(vanilla, coreScript.functionParameters, resistanceID * 10) * coreScript.armorScalingFactorValue) as int
			SetTextOptionValue(resistancePreviewTextButton[previewSize], ""+value+"%")
		endif
	else
		int vanillaFire = coreScript.data[ID_FIRE * 3 + 1]
		int vanillaFrost = coreScript.data[ID_FROST * 3 + 1]
		int vanillaShock = coreScript.data[ID_SHOCK * 3 + 1]
		int valueFire = JRR_RescaleFunction(vanillaFire, coreScript.functionParameters, resistanceID * 10)
		int valueFrost = JRR_RescaleFunction(vanillaFrost, coreScript.functionParameters, resistanceID * 10)
		int valueShock = JRR_RescaleFunction(vanillaShock, coreScript.functionParameters, resistanceID * 10)
		SetTextOptionValue(resistancePreviewTextButton[previewSize], ""+valueFire+"%")
		SetTextOptionValue(resistancePreviewTextButton[previewSize+1], ""+valueFrost+"%")
		SetTextOptionValue(resistancePreviewTextButton[previewSize+2], ""+valueShock+"%")
	endif
endfunction

function Recalculate(int resistanceID)
	if coreScript.useIni
		coreScript.resistanceEnabledValue[currentResistanceID] = PapyrusIni.ReadBool("ResistancesRescaled.ini", resistanceName[currentResistanceID], "enabled", true)
		coreScript.resistanceFormula[resistanceID] = PapyrusIni.ReadInt("ResistancesRescaled.ini", resistanceName[resistanceID], "formula", 0)
		coreScript.resistanceReduction0Value[resistanceID] = PapyrusIni.ReadInt("ResistancesRescaled.ini", resistanceName[resistanceID], "at0", 0)
	endif
	
	if resistanceID == ID_ARMOR
		if coreScript.useIni
			coreScript.resistanceReduction100Value[resistanceID] = PapyrusIni.ReadInt("ResistancesRescaled.ini", resistanceName[resistanceID], "at1000", 75)
		endif
		coreScript.CalculateArmorParameters(coreScript.resistanceFormula[resistanceID], coreScript.resistanceReduction0Value[resistanceID], coreScript.resistanceReduction100Value[resistanceID])
	else
		if coreScript.useIni
			coreScript.resistanceReduction100Value[resistanceID] = PapyrusIni.ReadInt("ResistancesRescaled.ini", resistanceName[resistanceID], "at100", 75)
		endif
		int formula = coreScript.resistanceFormula[resistanceID]
		int at0 = coreScript.resistanceReduction0Value[resistanceID]
		int at100 = coreScript.resistanceReduction100Value[resistanceID]
		coreScript.CalculateParameters(formula, resistanceID, at0, at100)
	endif
endfunction

function ResistancePage(string name, string low, string high)
	AddHeaderOption(name)
	resistanceEnabledButton[currentResistanceID] = AddToggleOption("$RescalingEnabled", coreScript.resistanceEnabledValue[currentResistanceID])
	resistanceFormulaButton[currentResistanceID] = AddMenuOption("$Formula", formulaName[coreScript.resistanceFormula[currentResistanceID]])
	resistanceReduction0Button[currentResistanceID] = AddSliderOption(low, coreScript.resistanceReduction0Value[currentResistanceID], "{0}%")
	resistanceReduction100Button[currentResistanceID] = AddSliderOption(high, coreScript.resistanceReduction100Value[currentResistanceID], "{0}%")
	SetCursorPosition(1)
	AddHeaderOption("$DamageReduction")
	AddPreviewText(currentResistanceID)
endfunction

event OnPageReset(string page)
	SetCursorFillMode(TOP_TO_BOTTOM)
	if page == Pages[0]
		currentResistanceID = ID_MAGIC
		ResistancePage("$Magic", "$VanillaResistance{0}", "$VanillaResistance{100}")

	elseif page == Pages[1]
		currentResistanceID = ID_ELEMENTAL
		ResistancePage("$Elemental", "$VanillaResistance{0}", "$VanillaResistance{100}")
		
	elseif page == Pages[2]
		currentResistanceID = ID_ARMOR
		ResistancePage("$Armor", "$VanillaArmorRating{0}", "$VanillaArmorRating{1000}")
		
	elseif page == Pages[3]
		currentResistanceID = ID_POISON
		ResistancePage("$Poison", "$VanillaResistance{0}", "$VanillaResistance{100}")
		
	
	elseif page == Pages[4]
		AddHeaderOption("$Vanilla")
		
		
		bool enabledMagic = Math.LogicalAnd(coreScript.updateMask, 0x1) > 0 && coreScript.updateRunning
		bool enabledElemental  = Math.LogicalAnd(coreScript.updateMask, 0x2) > 0 && coreScript.updateRunning
		bool enabledArmor  = Math.LogicalAnd(coreScript.updateMask, 0x4) > 0 && coreScript.updateRunning
		bool enabledPoison  = Math.LogicalAnd(coreScript.updateMask, 0x8) > 0 && coreScript.updateRunning
		if enabledMagic
			AddTextOption("$Magic", ""+coreScript.data[1] + "%", OPTION_FLAG_DISABLED)
		else
			AddTextOption("$Magic", "" + (PlayerRef.GetActorValue("MagicResist") as int) + "%", OPTION_FLAG_DISABLED)
		endif
		
		if enabledElemental
			AddTextOption("$Fire", ""+coreScript.data[7] + "%", OPTION_FLAG_DISABLED)
			AddTextOption("$Frost", ""+coreScript.data[10] + "%", OPTION_FLAG_DISABLED)
			AddTextOption("$Shock", ""+coreScript.data[13] + "%", OPTION_FLAG_DISABLED)
		else
			AddTextOption("$Fire", "" + (PlayerRef.GetActorValue("FireResist") as int) + "%", OPTION_FLAG_DISABLED)
			AddTextOption("$Frost", "" + (PlayerRef.GetActorValue("FrostResist") as int) + "%", OPTION_FLAG_DISABLED)
			AddTextOption("$Shock", "" + (PlayerRef.GetActorValue("ElectricResist") as int) + "%", OPTION_FLAG_DISABLED)
		endif
		
		if enabledArmor
			AddTextOption("$ArmorRating", ""+coreScript.data[16], OPTION_FLAG_DISABLED)
			AddTextOption("$ArmorDamageReduction", ""+((coreScript.data[16] * coreScript.armorScalingFactorValue) as int) + "%", OPTION_FLAG_DISABLED)
		else
			int damageResist = PlayerRef.GetActorValue("DamageResist") as int
			AddTextOption("$ArmorRating", "" + damageResist, OPTION_FLAG_DISABLED)
			AddTextOption("$ArmorDamageReduction", "" + ((damageResist * coreScript.armorScalingFactorValue) as int) + "%", OPTION_FLAG_DISABLED)
		endif
		
		if enabledPoison
			AddTextOption("$Poison", ""+coreScript.data[19] + "%", OPTION_FLAG_DISABLED)
		else
			AddTextOption("$Poison", "" + (PlayerRef.GetActorValue("PoisonResist") as int) + "%", OPTION_FLAG_DISABLED)
		endif
		
		AddEmptyOption()
		AddTextOption("$Information", "")
		
		SetCursorPosition(1)
		AddHeaderOption("$Rescaled")
		
		if enabledMagic
			AddTextOption("$Magic", ""+coreScript.data[0] + "%", OPTION_FLAG_DISABLED)
		else
			AddTextOption("$Magic", "$Disabled", OPTION_FLAG_DISABLED)
		endif
		
		if enabledElemental
			AddTextOption("$Fire", ""+coreScript.data[6] + "%", OPTION_FLAG_DISABLED)
			AddTextOption("$Frost", ""+coreScript.data[9] + "%", OPTION_FLAG_DISABLED)
			AddTextOption("$Shock", ""+coreScript.data[12] + "%", OPTION_FLAG_DISABLED)
		else
			AddTextOption("$Fire", "$Disabled", OPTION_FLAG_DISABLED)
			AddTextOption("$Frost", "$Disabled", OPTION_FLAG_DISABLED)
			AddTextOption("$Shock", "$Disabled", OPTION_FLAG_DISABLED)
		endif
		
		if enabledArmor
			AddTextOption("$ArmorRating", ""+coreScript.data[15], OPTION_FLAG_DISABLED)
			AddTextOption("$ArmorDamageReduction", ""+((coreScript.data[15] * coreScript.armorScalingFactorValue) as int)+"%", OPTION_FLAG_DISABLED)
		else
			AddTextOption("$ArmorRating", "$Disabled", OPTION_FLAG_DISABLED)
			AddTextOption("$ArmorDamageReduction", "$Disabled", OPTION_FLAG_DISABLED)
		endif
		
		if enabledPoison
			AddTextOption("$Poison", ""+coreScript.data[18] + "%", OPTION_FLAG_DISABLED)
		else
			AddTextOption("$Poison", "$Disabled", OPTION_FLAG_DISABLED)
		endif
	
	elseif page == Pages[5]
		AddHeaderOption("$Advanced")
		modEnabledButton = AddToggleOption("$RescalingEnabled", coreScript.modEnabledValue)
		magicEffectPreviewButton = AddToggleOption("$MagicEffectPreview", coreScript.magicEffectPreview)
		uninstallInformationButton = AddTextOption("$Information", "")
		AddHeaderOption("$GameSettings")
		playerMaxResistanceButton = AddSliderOption("$MagicReductionCap", (coreScript.playerMaxResistanceValue) as int, "{0}%" )
		maxArmorRatingButton = AddSliderOption("$ArmorReductionCap", (coreScript.maxArmorRatingValue) as int, "{0}%" )
		armorScalingFactorButton = AddSliderOption("$ArmorScaling", coreScript.armorScalingFactorValue, "{3}" )
		gameSettingInformationButton = AddTextOption("$Information", "")
	endif
endEvent

event  OnOptionSliderOpen(int option)
	if option == resistanceReduction0Button[currentResistanceID]
		SetSliderDialogStartValue(coreScript.resistanceReduction0Value[currentResistanceID])
		SetSliderDialogDefaultValue(0)
		SetSliderDialogRange(0,99)
		SetSliderDialogInterval(1)
	elseif option == resistanceReduction100Button[currentResistanceID]
		SetSliderDialogStartValue(coreScript.resistanceReduction100Value[currentResistanceID])
		SetSliderDialogDefaultValue(75)
		SetSliderDialogRange(0,99)
		SetSliderDialogInterval(1)
	endif
	if option == playerMaxResistanceButton
		SetSliderDialogStartValue(coreScript.playerMaxResistanceValue)
		SetSliderDialogDefaultValue(100)
		SetSliderDialogRange(0, 100)
		SetSliderDialogInterval(1)
	elseif option == maxArmorRatingButton
		SetSliderDialogStartValue(coreScript.maxArmorRatingValue)
		SetSliderDialogDefaultValue(100)
		SetSliderDialogRange(0, 100)
		SetSliderDialogInterval(1)
	elseif option == armorScalingFactorButton
		SetSliderDialogStartValue(coreScript.armorScalingFactorValue)
		SetSliderDialogDefaultValue(0.12)
		SetSliderDialogRange(0.001, 2)
		SetSliderDialogInterval(0.001)
	endif
endEvent

event  OnOptionSliderAccept(int option, float value)
	if option == resistanceReduction0Button[currentResistanceID]
		coreScript.resistanceReduction0Value[currentResistanceID] = value as int
		if coreScript.useIni
			PapyrusIni.WriteInt("ResistancesRescaled.ini", resistanceName[currentResistanceID], "at0", value as int)
		endif
		SetSliderOptionValue(option, value, "{0}%")
		Recalculate(currentResistanceID)
		UpdatePreviewText(currentResistanceID)
	elseif option == resistanceReduction100Button[currentResistanceID]
		coreScript.resistanceReduction100Value[currentResistanceID] = value as int
		if coreScript.useIni
			if currentResistanceID == ID_ARMOR
				PapyrusIni.WriteInt("ResistancesRescaled.ini", resistanceName[currentResistanceID], "at1000", value as int)
			else
				PapyrusIni.WriteInt("ResistancesRescaled.ini", resistanceName[currentResistanceID], "at100", value as int)
			endif
		endif
		SetSliderOptionValue(option, value, "{0}%")
		Recalculate(currentResistanceID)
		UpdatePreviewText(currentResistanceID)
	endif

	if(option == playerMaxResistanceButton)
		coreScript.playerMaxResistanceValue = value
		if coreScript.useIni
			PapyrusIni.WriteFloat("ResistancesRescaled.ini", "General", "playerMaxResistance", value)
		endif
		SetSliderOptionValue(option, value, "{0}%")
		Game.SetGameSettingFloat("fPlayerMaxResistance", coreScript.playerMaxResistanceValue)
	elseif(option == maxArmorRatingButton)
		coreScript.maxArmorRatingValue = value
		if coreScript.useIni
			PapyrusIni.WriteFloat("ResistancesRescaled.ini", "General", "maxArmorRating", value)
		endif
		SetSliderOptionValue(option, value, "{0}%")
		Game.SetGameSettingFloat("fMaxArmorRating", coreScript.maxArmorRatingValue)
	elseif(option == armorScalingFactorButton)
		coreScript.armorScalingFactorValue = value
		if coreScript.useIni
			PapyrusIni.WriteFloat("ResistancesRescaled.ini", "General", "armorScalingFactor", value)
		endif
		SetSliderOptionValue(option, value, "{3}")
		Game.SetGameSettingFloat("fArmorScalingFactor", coreScript.armorScalingFactorValue)
		coreScript.CalculateArmorParameters(coreScript.resistanceFormula[ID_ARMOR], coreScript.resistanceReduction0Value[ID_ARMOR], coreScript.resistanceReduction100Value[ID_ARMOR])
	endif
endEvent

event OnOptionSelect(int option)
	if option == resistanceEnabledButton[currentResistanceID]
		coreScript.resistanceEnabledValue[currentResistanceID] = !coreScript.resistanceEnabledValue[currentResistanceID]
		if coreScript.useIni
			PapyrusIni.WriteBool("ResistancesRescaled.ini", resistanceName[currentResistanceID], "enabled", coreScript.resistanceEnabledValue[currentResistanceID])
		endif
		SetToggleOptionValue(option, coreScript.resistanceEnabledValue[currentResistanceID])
		int bit = 0
		if currentResistanceID == ID_MAGIC
			bit = 0x1
		elseif currentResistanceID == ID_ELEMENTAL
			bit = 0x2
		elseif currentResistanceID == ID_ARMOR
			bit = 0x4
		elseif currentResistanceID == ID_POISON
			bit = 0x8
		endif
		
		if coreScript.resistanceEnabledValue[currentResistanceID]
			coreScript.resistanceEnabledMask = Math.LogicalOr(coreScript.resistanceEnabledMask, bit)
		else
			coreScript.resistanceEnabledMask = Math.LogicalAnd(coreScript.resistanceEnabledMask, Math.LogicalNot(bit))
		endif
		
		coreScript.ResetToVanilla(currentResistanceID)
	elseif option == modEnabledButton
		coreScript.modEnabledValue = !coreScript.modEnabledValue
		if coreScript.useIni
			PapyrusIni.WriteBool("ResistancesRescaled.ini", "General", "enabled", coreScript.modEnabledValue)
		endif
		SetToggleOptionValue(option, coreScript.modEnabledValue)
		if coreScript.modEnabledValue
			coreScript.StartEffect()
		else
			coreScript.FinishEffect()
		endif
	elseif option == magicEffectPreviewButton
		coreScript.magicEffectPreview = !coreScript.magicEffectPreview
		if coreScript.useIni
			PapyrusIni.WriteBool("ResistancesRescaled.ini", "General", "magicEffectPreview", coreScript.magicEffectPreview)
		endif
		SetToggleOptionValue(option, coreScript.magicEffectPreview)
	endif
endEvent

event OnOptionMenuOpen(int option)
	if option == resistanceFormulaButton[currentResistanceID]
		SetMenuDialogStartIndex(coreScript.resistanceFormula[currentResistanceID])
		SetMenuDialogDefaultIndex(coreScript.resistanceFormula[currentResistanceID])
		SetMenuDialogOptions(formulaName)
		return
	endif
endEvent

event OnOptionMenuAccept(int option, int index)
	if option == resistanceFormulaButton[currentResistanceID]
		SetMenuOptionValue(option, formulaName[index])
		coreScript.resistanceFormula[currentResistanceID] = index
		if coreScript.useIni
			PapyrusIni.WriteInt("ResistancesRescaled.ini", resistanceName[currentResistanceID], "formula", index)
		endif
		Recalculate(currentResistanceID)
		UpdatePreviewText(currentResistanceID)
		return
	endif
endEvent

event OnConfigClose()
	; Force update in case rescale parameters were changed.
	coreScript.forceUpdate = true
	coreScript.UpdateDisplayPerk()
endEvent

event OnGameReload()
	parent.OnGameReload()
	
	coreScript.Maintenance()
endEvent

event OnVersionUpdate(int newVer)
	; newVer is the new version, CurrentVersion is the old version
	if(newVer > CurrentVersion)
		; Mod installed, no previous version used
		if(CurrentVersion == 0)
			return
		endif
		
		; Previous version to old.
		if(CurrentVersion < 300)
			Debug.MessageBox("Error! Resistance Rescaled cannot be updated. Previous version is not compatible.")
			return
		endif
	
		; Standard update
	
		Debug.Notification("[RR]: Updating from  "+GetVersionName(CurrentVersion)+" to "+GetVersionName(newVer))
		Debug.Trace("[RR]: Updating from  "+GetVersionName(CurrentVersion)+" to "+GetVersionName(newVer))
		
	elseif(newVer < CurrentVersion)
		Debug.Notification("[MMR]: Downgrading from  "+GetVersionName(CurrentVersion)+" to "+GetVersionName(newVer))
		Debug.MessageBox("Error! Magic Resistance Rescaled detected, that you are using an older version than before!")
		Debug.Trace("[MRR]: Downgrading from  "+GetVersionName(CurrentVersion)+" to "+GetVersionName(newVer))
		Debug.Trace("[MRR]: Error! Magic Resistance Rescaled detected, that you are using an older version than before!")
	endif
endEvent



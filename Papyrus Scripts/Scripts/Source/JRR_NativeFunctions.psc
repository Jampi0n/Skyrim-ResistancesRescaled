scriptName JRR_NativeFunctions Hidden
{Contains declarations of functions implemented in the dll.}

int Function JRR_RescaleFunction(int x, float[] parameters, int parameterOffset) global native

int[] Function JRR_MainLoop(actor akActor, int[] data, float[] functionParameters, spell[] spellArray, perk[] perkArray) global native

Function Print(string s) global
	Debug.Trace(s)
	Debug.Notification(s)
EndFunction

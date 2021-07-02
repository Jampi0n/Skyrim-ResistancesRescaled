scriptName JRR_NativeFunctions Hidden
{Contains declarations of functions implemented in the dll.}

; f(max,a,c,x) = max - 100 / (c * x + a)
int Function JRR_RescaleFunction(int x, float[] parameters, int parameterOffset) global native

int[] Function JRR_MainLoop(actor akActor, int[] data, float[] functionParameters, spell[] displaySpell) global native

Function Print(string s) global
	Debug.Trace(s)
	Debug.Notification(s)
EndFunction


;Function MyModActorValue(actor akActor, int av, float mod) global native

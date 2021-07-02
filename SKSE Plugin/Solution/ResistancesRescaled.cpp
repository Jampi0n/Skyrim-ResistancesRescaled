#include "ResistancesRescaled.h"

#include <vector>
#include <cmath>

#if LEGENDARY_EDITION
#include "skse/GameReferences.h"
#include "skse/GameObjects.h"
#include "skse/PapyrusSpell.h"
#else
#include "skse64/GameReferences.h"
#include "skse64/GameObjects.h"
#include "skse64/PapyrusSpell.h"
#endif

namespace ResistancesRescaled {

	constexpr size_t ELEMENTS_PER_AV = 3;
	constexpr size_t PARAMETERS_PER_AV = 10;

	constexpr size_t MAGIC_RESIST = 44;
	constexpr size_t FIRE_RESIST = 41;
	constexpr size_t FROST_RESIST = 43;
	constexpr size_t SHOCK_RESIST = 42;
	constexpr size_t DAMAGE_RESIST = 39;
	constexpr size_t POISON_RESIST = 40;

	constexpr size_t ID_MAGIC = 0;
	constexpr size_t ID_ELEMENTAL = 1;
	constexpr size_t ID_FIRE = 2;
	constexpr size_t ID_FROST = 3;
	constexpr size_t ID_SHOCK = 4;
	constexpr size_t ID_ARMOR = 5;
	constexpr size_t ID_POISON = 6;

	/// <summary>
	/// Returns a new std::vector<T> containing the same elements as vmArray.
	/// </summary>
	/// <typeparam name="T">Type of the array elements.</typeparam>
	/// <param name="vmArray">VMArray from which values are copied.</param>
	/// <returns>The new vector.</returns>
	template<typename T>
	std::vector<T> VMArray2Vector(VMArray<T> &vmArray) {
		size_t length = vmArray.Length();
		std::vector<T> vec(length);
		for (size_t i = 0; i < length; ++i) {
			T tmp;
			vmArray.Get(&tmp, i);
			vec[i] = tmp;
		}
		return vec;
	}

	/// <summary>
	/// Returns a new VMResultArray<T> containing the same elements as vec.
	/// </summary>
	/// <typeparam name="T">Type of the array elements.</typeparam>
	/// <param name="vec">Vector from which values are copied.</param>
	/// <returns>The new array.</returns>
	template<typename T>
	VMResultArray<T> Vector2VMResultArray(std::vector<T>& vec) {
		VMResultArray<T> result;
		size_t length = vec.size();
		for (size_t i = 0; i < length; ++i) {
			result.push_back(vec[i]);
		}
		return result;
	}

	/// <summary>
	/// Modifies a specific actor value of an actor by a certain value. Works like the papyrus function with the same name.
	/// </summary>
	/// <param name="akActor">The actor, whose actor value is modifed.</param>
	/// <param name="avID">The actor value id of the actor value that is modified.</param>
	/// <param name="mod">The value by how much the actor value is modified.</param>
	void ModActorValue(Actor* akActor, SInt32 avID, float mod) {
		#if LEGENDARY_EDITION
		// Unk_06 has a wrong signature and the last parameter should be float instead of SInt32
		// Use pointer to use float hidden as SInt32
		SInt32* modPtr = (SInt32*)(&mod);
		akActor->actorValueOwner.Unk_06(0, avID, *modPtr);
		#else
		akActor->actorValueOwner.ModCurrent(0, avID, mod);
		#endif
	}
	
#define GET_DATA_VANILLA_VALUE(index) data[index * ELEMENTS_PER_AV]
#define GET_DATA_MAPPED_VALUE(index) data[index * ELEMENTS_PER_AV+1]

#define FORCE_UPDATE data[21]
#define UPDATE_RUNNING data[22]
#define RESET_RESISTANCE data[23]
#define UPDATE_MASK data[24]
#define RESISTANCE_ENABLED_MASK data[25]
#define MOD_ENABLED_VALUE data[26]
#define AV_RESCALED data[27]
#define AV_RESET data[28]
#define AV_UPDATED data[29]

#define RESET(av, id) ModActorValue(akActor, static_cast<SInt32>(av), static_cast<float>(GET_DATA_MAPPED_VALUE(id) - GET_DATA_VANILLA_VALUE(id))); \
	GET_DATA_MAPPED_VALUE(id) = 0; \
	GET_DATA_VANILLA_VALUE(id) = 0; \
	AV_RESET |= (1u << id); \
	AV_UPDATED |= (1u << id)

	/// <summary>
	/// Rescales actor value x (vanilla value) using the given parameters and returns the rescaled value.
	/// </summary>
	/// <param name="x">Vanilla actor value before rescaling.</param>
	/// <param name="parameters">Array of parameters. Semantics depends on the formula (always first element).</param>
	/// <param name="parameterOffset">Array offset for 'functionParameters'.</param>
	/// <returns>The new rescaled vallue.</returns>
	SInt32 Internal_RescaleFunction(SInt32 x, std::vector<float> &parameters, size_t parameterOffset) {
		double result = x;

		// Parameters:
		// parameters[0] = formula (int)
		// parameters[1] = at0
		// parameters[2] = atHigh
		// parameters[3] = highValue
		// parameters[4] = scalingFactor

		long formula = std::lround(parameters[0 + parameterOffset]);
		long at0 = std::lround(parameters[1 + parameterOffset]);
		long atHigh = std::lround(parameters[2 + parameterOffset]);
		long highValue = std::lround(parameters[3 + parameterOffset]);
		double scalingFactor = parameters[4 + parameterOffset];

		if (x < 0.) {
			result = at0 / scalingFactor + x;
		}
		else {
			if (formula == 0) {
				double max = 100. / scalingFactor;
				double a = 1. / (1. - 0.01 * at0) * scalingFactor;
				double b = 1. / (1. - 0.01 * atHigh) * scalingFactor;
				double c = (b - a) / highValue;
				result = max - 100. / (c * x + a);
			}
			else {
				double max = 100.0 / scalingFactor;
				double factor = (1. - 0.01 * at0) / scalingFactor;
				double base = std::pow((100. - atHigh) / (100. - at0), 1.0 / highValue);
				result = max - 100. * std::pow(base, x) * factor;
			}
		}
		return static_cast<SInt32>(std::lround(result));
	}

	void RescaleSingle(Actor* akActor, SInt32 actorValue, std::vector<SInt32> &data, SInt32 id, std::vector<float> &functionParameters, SInt32 parameterId, bool forceUpdate, bool doRescaling, VMArray<SpellItem*> displaySpells)
	{
		// The actual resistance value in the last update.
		SInt32 lastValue = data[id * ELEMENTS_PER_AV];
		// The actual resistance value in the current update.
		SInt32 newValue = (SInt32)akActor->actorValueOwner.GetCurrent(actorValue);

		// The difference in actual resistance values represents by how much the actor's
		// resistance value changed since the last update
		SInt32 difference = newValue - lastValue;

		// If resistance values did not change, only update if forceUpdate
		if (difference != 0 || forceUpdate)
		{
			AV_UPDATED |= (1u << id);
			// The vanilla resistance value in the last update.
			SInt32 combinedValue = data[id * ELEMENTS_PER_AV + 1];

			// Update to vanilla resistance value  in current update.
			combinedValue += difference;

			// Save in array.
			data[id * ELEMENTS_PER_AV + 1] = combinedValue;

			if (doRescaling) {
				// Calculate new rescaled result.
				// This only depends on the current vanilla resistance value.
				SInt32 newRescaled = Internal_RescaleFunction(combinedValue, functionParameters, parameterId * PARAMETERS_PER_AV);

				// This is the difference between desired (rescaled) and actual resistance.
				// Using ModActorValue("...",  modValue) will bring the resistance to the desired value.
				SInt32 modValue = newRescaled - newValue;
				ModActorValue(akActor, actorValue, static_cast<float>(modValue));

				// Save modValue in array. This will be lastValue in the next update.
				data[id * ELEMENTS_PER_AV] = newValue + modValue;
				AV_RESCALED |= (1u << id);
			}
			else {
				data[id * ELEMENTS_PER_AV] = combinedValue;
			}
			size_t spellIndex = id;
			SpellItem *spell;
			displaySpells.Get(&spell, spellIndex*2);
			papyrusSpell::SetNthEffectMagnitude(spell, 0, data[id * ELEMENTS_PER_AV]);
			displaySpells.Get(&spell, spellIndex*2+1);
			papyrusSpell::SetNthEffectMagnitude(spell, 0, data[id * ELEMENTS_PER_AV]);
		}
	}

	void RescaleAll(Actor* akActor, std::vector<SInt32> &data, SInt32 mask, std::vector<float> &functionParameters, bool forceUpdate, VMArray<SpellItem*> displaySpells) {

		RescaleSingle(akActor, MAGIC_RESIST, data, ID_MAGIC, functionParameters, ID_MAGIC, forceUpdate, mask & 0x1, displaySpells);

		RescaleSingle(akActor, FIRE_RESIST, data, ID_FIRE, functionParameters, ID_ELEMENTAL, forceUpdate, mask & 0x2, displaySpells);
		RescaleSingle(akActor, FROST_RESIST, data, ID_FROST, functionParameters, ID_ELEMENTAL, forceUpdate, mask & 0x2, displaySpells);
		RescaleSingle(akActor, SHOCK_RESIST, data, ID_SHOCK, functionParameters, ID_ELEMENTAL, forceUpdate, mask & 0x2, displaySpells);

		RescaleSingle(akActor, DAMAGE_RESIST, data, ID_ARMOR, functionParameters, ID_ARMOR, forceUpdate, mask & 0x4, displaySpells);

		RescaleSingle(akActor, POISON_RESIST, data, ID_POISON, functionParameters, ID_POISON, forceUpdate, mask & 0x8, displaySpells);
	}

	void ApplyReset(Actor* akActor, std::vector<SInt32> &data) {
		SInt32 resetFlags = data[23];
		SInt32 prevFlags = resetFlags;
		if (resetFlags >= 8) {
			RESET(POISON_RESIST, ID_POISON);
			resetFlags -= 8;
		}
		if (resetFlags >= 4) {
			RESET(DAMAGE_RESIST, ID_ARMOR);
			resetFlags -= 4;
		}
		if (resetFlags >= 2) {
			RESET(FIRE_RESIST, ID_FIRE);
			RESET(FROST_RESIST, ID_FROST);
			RESET(SHOCK_RESIST, ID_SHOCK);
			resetFlags -= 2;
		}
		if (resetFlags >= 1) {
			RESET(MAGIC_RESIST, ID_MAGIC);
			resetFlags -= 1;
		}
		data[23] -= prevFlags;

	}

	VMResultArray<SInt32> MainLoop(StaticFunctionTag*, Actor* akActor, VMArray<SInt32> vmData, VMArray<float> vmFloatParameters, VMArray<SpellItem*> displaySpells) {
		auto data = VMArray2Vector(vmData);
		auto floatParameters = VMArray2Vector(vmFloatParameters);
		AV_RESCALED = 0;
		AV_RESET = 0;
		AV_UPDATED = 0;
		
		if (!MOD_ENABLED_VALUE) {
			UPDATE_RUNNING = 0;
			RESET_RESISTANCE = 0xf;
			ApplyReset(akActor, data);
		} else {
			UPDATE_MASK = RESISTANCE_ENABLED_MASK;

			RescaleAll(akActor, data, UPDATE_MASK, floatParameters, static_cast<bool>(FORCE_UPDATE), displaySpells);
			FORCE_UPDATE = 0;

			if (RESET_RESISTANCE > 0) {
				ApplyReset(akActor, data);
			}

		}
		AV_RESCALED = static_cast<SInt32>(static_cast<UInt32>(AV_RESCALED) & ~static_cast<UInt32>(AV_RESET));
		return Vector2VMResultArray(data);
	}

	/// <summary>
	/// Papyrus wrapper for the internal rescale function.
	/// </summary>
	/// <param name="base">PapyrusVM.</param>
	/// <param name="x">Vanilla actor value before rescaling.</param>
	/// <param name="functionParameters">Array of parameters. Semantics depends on the formula (always first element).</param>
	/// <param name="parameterOffset">Array offset for 'functionParameters'.</param>
	/// <returns>The new rescaled vallue.</returns>
	SInt32 RescaleFunction(StaticFunctionTag* base, SInt32 x, VMArray<float> functionParameters, SInt32 parameterOffset) {
		auto param = VMArray2Vector(functionParameters);
		return Internal_RescaleFunction(x, param, parameterOffset);
	}

	bool RegisterFuncs(VMClassRegistry* registry) {
		registry->RegisterFunction(
			new NativeFunction3 <StaticFunctionTag, SInt32, SInt32, VMArray<float>, SInt32>("JRR_RescaleFunction", "JRR_NativeFunctions", RescaleFunction, registry));
		registry->RegisterFunction(
			new NativeFunction4 <StaticFunctionTag, VMResultArray<SInt32>, Actor*, VMArray<SInt32>, VMArray<float>, VMArray<SpellItem*>>("JRR_MainLoop", "JRR_NativeFunctions", MainLoop, registry));
		return true;
	}
}

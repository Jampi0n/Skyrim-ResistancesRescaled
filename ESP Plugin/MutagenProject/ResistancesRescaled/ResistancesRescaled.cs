using Mutagen.Bethesda;
using Mutagen.Bethesda.Skyrim;
using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.FormKeys.SkyrimLE;
using System;
using System.IO;
using Noggog;

namespace ResistancesRescaled {
    class ResistanceType {
        public readonly MagicEffect displayEffect;
        public readonly string shortName;
        public readonly string longName;
        public readonly Spell[] displaySpellList;
        public readonly bool includeInPerk;

        public ResistanceType(SkyrimMod mod, string shortName, string longName, bool usePercentSymbol = true, bool includeInPerk = true) {
            this.shortName = shortName;
            this.longName = longName;
            this.includeInPerk = includeInPerk;

            MagicEffect mEffect = mod.MagicEffects.AddNew("JRR_DisplayEffect" + shortName);
            mEffect.Name = "My " + longName;
            mEffect.MenuDisplayObject.SetTo(Skyrim.Static.MagicHatMarker);
            mEffect.Archetype.Type = MagicEffectArchetype.TypeEnum.Script;
            mEffect.Archetype.ActorValue = ActorValue.None;
            mEffect.Flags = mEffect.Flags.
                SetFlag(MagicEffect.Flag.Recover, true).
                SetFlag(MagicEffect.Flag.NoHitEvent, true).
                SetFlag(MagicEffect.Flag.NoDuration, true).
                SetFlag(MagicEffect.Flag.NoArea, true).
                SetFlag(MagicEffect.Flag.NoHitEffect, true);

            mEffect.CastType = CastType.ConstantEffect;
            mEffect.Description = longName + ": <mag>" + (usePercentSymbol ? "%" : "");

            this.displayEffect = mEffect;
            this.displaySpellList = new Spell[ResistancesRescaled.swapLength];

            for(var i = 0; i < ResistancesRescaled.swapLength; ++i) {
                Spell spell = mod.Spells.AddNew("JRR_DisplaySpell" + shortName + "" + i);
                spell.Name = "My " + longName;
                spell.MenuDisplayObject.SetTo(Skyrim.Static.MagicHatMarker);
                spell.EquipmentType.SetTo(Skyrim.EquipType.EitherHand);

                spell.Flags = spell.Flags.
                    SetFlag(SpellDataFlag.IgnoreResistance, true).
                    SetFlag(SpellDataFlag.NoAbsorbOrReflect, true);

                spell.Type = SpellType.Ability;
                spell.CastType = CastType.ConstantEffect;
                var effect = new Effect {
                    BaseEffect = displayEffect.AsNullableLink(),
                    Data = new EffectData {
                        Magnitude = 1,
                        Area = 0,
                        Duration = 0
                    }
                };
                spell.Effects.Add(effect);
                this.displaySpellList[i] = spell;
            }

        }
    }

    class ResistancesRescaled {
        public static int swapLength;

        static bool DirectoryContainsFile(string directory, string fileName) {
            var files = Directory.GetFiles(directory, fileName);
            return files.Length > 0;
        }
        static string FindRootDirectory() {
            string current = Directory.GetCurrentDirectory();
            while(!DirectoryContainsFile(current, "modname.txt")) {
                current = Directory.GetParent(current).FullName;
            }
            return current;
        }

        static Perk[] CreateDisplayPerks(SkyrimMod mod, ResistanceType[] rTypes) {
            var perks = new Perk[swapLength];
            for(var i = 0; i < ResistancesRescaled.swapLength; ++i) {
                Perk perk = mod.Perks.AddNew("JRR_DsiplayPerk" + "" + i);
                perk.Name = "JRR_DsiplayPerk" + "" + i;
                perk.NumRanks = 1;
                perk.Playable = true;
                byte j = 0;
                foreach(ResistanceType rType in rTypes) {
                    if(rType != null && rType.includeInPerk) {
                        var effect = new PerkAbilityEffect {
                            Priority = j,
                            Ability = rType.displaySpellList[i].AsLink()
                        };
                        perk.Effects.Add(effect);
                    }
                    j++;
                }
                perks[i] = perk;
            }
            return perks;
        }

        public static void EditMod(SkyrimMod mod, SkyrimRelease release) {
            swapLength = 2;

            var resistanceTypes = new ResistanceType[7];
            resistanceTypes[0] = new ResistanceType(mod, "Magic", "Magic Resistance");
            resistanceTypes[1] = null;
            resistanceTypes[2] = new ResistanceType(mod, "Fire", "Fire Resistance");
            resistanceTypes[3] = new ResistanceType(mod, "Frost", "Frost Resistance");
            resistanceTypes[4] = new ResistanceType(mod, "Shock", "Shock Resistance");
            resistanceTypes[5] = new ResistanceType(mod, "Armor", "Armor Rating", false, false);
            resistanceTypes[6] = new ResistanceType(mod, "Poison", "Poison Resistance");

            Perk[] perks = CreateDisplayPerks(mod, resistanceTypes);

            Quest mcmQuest = mod.Quests.AddNew("JRR_MCMQuest");
            mcmQuest.Name = "JRR_MCMQuest";

            Quest coreQuest = mod.Quests.AddNew("JRR_CoreQuest");
            coreQuest.Name = "JRR_CoreQuest";


            mcmQuest.Flags = mcmQuest.Flags.
                SetFlag(Quest.Flag.StartGameEnabled, true).
                SetFlag(Quest.Flag.RunOnce, true);
            var playerAlias = new QuestAlias {
                Name = "PlayerAlias",
                Flags = new QuestAlias.Flag(),
                VoiceTypes = FormKey.Null.AsNullableLink<IAliasVoiceTypeGetter>()
            };
            playerAlias.ForcedReference.SetTo(Constants.Player.Cast<IPlacedGetter>());
            mcmQuest.Aliases.Add(playerAlias);


            var mcmScript = new ScriptEntry {
                Name = "JRR_ModConfigurationMenu"
            };

            var coreScriptProperty = new ScriptObjectProperty {
                Name = "coreScript",
                Flags = ScriptProperty.Flag.Edited,
                Object = coreQuest.AsNullableLink(),
                Alias = -1
            };

            var modNameProperty = new ScriptStringProperty {
                Name = "ModName",
                Flags = ScriptProperty.Flag.Edited,
                Data = "Resistances Rescaled"
            };

            var playerRef = new ScriptObjectProperty {
                Name = "PlayerRef",
                Flags = ScriptProperty.Flag.Edited,
                Object = Constants.Player.AsNullable(),
                Alias = -1
            };

            mcmScript.Properties.Add(coreScriptProperty);
            mcmScript.Properties.Add(modNameProperty);
            mcmScript.Properties.Add(playerRef);

            var playerLoadScript = new ScriptEntry {
                Name = "SKI_PlayerLoadGameAlias",
                Flags = ScriptEntry.Flag.Local
            };

            var playerAliasFragment = new QuestFragmentAlias();
            playerAliasFragment.Scripts.Add(playerLoadScript);
            playerAliasFragment.Property.Object = mcmQuest.AsNullableLink();
            playerAliasFragment.Property.Alias = 0;

            mcmQuest.VirtualMachineAdapter = new QuestAdapter();
            mcmQuest.VirtualMachineAdapter.Scripts.Add(mcmScript);
            mcmQuest.VirtualMachineAdapter.Aliases.Add(playerAliasFragment);

            var coreScript = new ScriptEntry {
                Name = "JRR_Core"
            };

            var displayPerk = new ScriptObjectProperty {
                Name = "DisplayPerk",
                Flags = ScriptProperty.Flag.Edited,
                Object = perks[0].AsNullableLink(),
                Alias = -1
            };

            var displayPerkSwap = new ScriptObjectProperty {
                Name = "DisplayPerkSwap",
                Flags = ScriptProperty.Flag.Edited,
                Object = perks[1].AsNullableLink(),
                Alias = -1
            };

            var displaySpells = new ScriptObjectListProperty {
                Name = "DisplaySpells",
                Flags = ScriptProperty.Flag.Edited
            };
            foreach(ResistanceType rType in resistanceTypes) {
                var spell = new ScriptObjectProperty();
                var spellSwap = new ScriptObjectProperty();
                spell.Alias = -1;
                spellSwap.Alias = -1;
                if(rType != null) {
                    spell.Object = rType.displaySpellList[0].AsNullableLink();
                    spellSwap.Object = rType.displaySpellList[1].AsNullableLink();
                }
                displaySpells.Objects.Add(spell);
                displaySpells.Objects.Add(spellSwap);
            }

            playerRef = new ScriptObjectProperty {
                Name = "PlayerRef",
                Flags = ScriptProperty.Flag.Edited,
                Object = Constants.Player.AsNullable(),
                Alias = -1
            };

            var mcmQuestProperty = new ScriptObjectProperty {
                Name = "MCMQuest",
                Flags = ScriptProperty.Flag.Edited,
                Object = mcmQuest.AsNullableLink(),
                Alias = -1
            };

            coreScript.Properties.Add(displayPerk);
            coreScript.Properties.Add(displayPerkSwap);
            coreScript.Properties.Add(displaySpells);
            coreScript.Properties.Add(playerRef);
            coreScript.Properties.Add(mcmQuestProperty);


            coreQuest.VirtualMachineAdapter = new QuestAdapter();
            coreQuest.VirtualMachineAdapter.Scripts.Add(coreScript);

            coreQuest.Flags = coreQuest.Flags.
                SetFlag(Quest.Flag.StartGameEnabled, true).
                SetFlag(Quest.Flag.RunOnce, true);
        }
    }
}

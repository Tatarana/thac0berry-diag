import Foundation

/// Um `RuleProvider` genérico pra ler uma célula de uma das seis tabelas de
/// atributo (`AbilityTables.swift`) e devolver o texto pronto — em vez de
/// ~19 `struct`s quase idênticos (um por campo de `AbilityDetails`), um só
/// tipo parametrizado por `key`/`label`/`ruleID`/`lookup`. `lookup` recebe
/// o `AbilityScores` inteiro (não só um `Int`) porque Força precisa também
/// de `exceptionalStrength` — as outras cinco simplesmente ignoram os
/// campos que não usam.
///
/// Cada instância é "auto-aplicável" no `ConsequenceEngine`: o valor
/// calculado aqui é exatamente o texto que já mora em
/// `PlayerCharacter.details` (`AbilityDetails`), então aplicar a mudança é
/// só copiar a String pro campo certo — ver `ConsequenceEngine.swift`.
struct AbilityDetailProvider: RuleProvider {
    let key: String
    let label: String
    let ruleID: String
    let lookup: (AbilityScores) -> String?

    func compute(for context: RuleContext) -> RuleValue? {
        guard let text = lookup(context.abilities), !text.isEmpty else { return nil }
        return .string(text)
    }

    func sourceRuleID(for context: RuleContext) -> String? {
        ruleID
    }
}

/// As ~19 instâncias, uma por campo de texto livre de `AbilityDetails`.
/// Cada `sourceRuleID` aponta pro id da regra correspondente já presente
/// no corpus da Referência de Regras (mesmo padrão de
/// `phb_ch09_calculating_thac0` usado pelo THAC0/saving throws).
enum AbilityDetailProviders {
    private static let strengthRuleID = "phb_ch01_strength"
    private static let dexterityRuleID = "phb_ch01_dexterity"
    private static let constitutionRuleID = "phb_ch01_constitution"
    private static let intelligenceRuleID = "phb_ch01_intelligence"
    private static let wisdomRuleID = "phb_ch01_wisdom"
    private static let charismaRuleID = "phb_ch01_charisma"

    /// Atalho comum às seis linhas de Força: acha a `Row` (considerando
    /// força excepcional quando `score == 18`) e devolve um campo dela.
    private static func strengthField(_ field: @escaping (StrengthTable.Row) -> String) -> (AbilityScores) -> String? {
        { abilities in
            guard let row = StrengthTable.row(score: abilities.strength, exceptionalPercentile: abilities.exceptionalStrength) else {
                return nil
            }
            return field(row)
        }
    }

    static let all: [AbilityDetailProvider] = [
        // MARK: Força (Tabela 1)
        AbilityDetailProvider(key: "strengthHit", label: "Strength — Hit Probability (Table 1)",
                               ruleID: strengthRuleID, lookup: strengthField { $0.hit }),
        AbilityDetailProvider(key: "strengthDamage", label: "Strength — Damage Adjustment (Table 1)",
                               ruleID: strengthRuleID, lookup: strengthField { $0.dmg }),
        AbilityDetailProvider(key: "strengthWeight", label: "Strength — Weight Allowance (Table 1)",
                               ruleID: strengthRuleID, lookup: strengthField { $0.weight }),
        AbilityDetailProvider(key: "strengthMaxPress", label: "Strength — Maximum Press (Table 1)",
                               ruleID: strengthRuleID, lookup: strengthField { $0.maxPress }),
        AbilityDetailProvider(key: "strengthDoors", label: "Strength — Open Doors (Table 1)",
                               ruleID: strengthRuleID, lookup: strengthField { $0.doors }),
        AbilityDetailProvider(key: "strengthBars", label: "Strength — Bend Bars/Lift Gates (Table 1)",
                               ruleID: strengthRuleID, lookup: strengthField { $0.bars }),

        // MARK: Destreza (Tabela 2)
        AbilityDetailProvider(key: "dexterityReaction", label: "Dexterity — Reaction Adjustment (Table 2)",
                               ruleID: dexterityRuleID, lookup: { DexterityTable.byScore[$0.dexterity]?.reaction }),
        AbilityDetailProvider(key: "dexterityMissile", label: "Dexterity — Missile Attack Adjustment (Table 2)",
                               ruleID: dexterityRuleID, lookup: { DexterityTable.byScore[$0.dexterity]?.missile }),
        AbilityDetailProvider(key: "dexterityDefense", label: "Dexterity — Defensive Adjustment (Table 2)",
                               ruleID: dexterityRuleID, lookup: { DexterityTable.byScore[$0.dexterity]?.defense }),

        // MARK: Constituição (Tabela 3)
        AbilityDetailProvider(key: "constitutionHP", label: "Constitution — Hit Point Adjustment (Table 3)",
                               ruleID: constitutionRuleID, lookup: { ConstitutionTable.byScore[$0.constitution]?.hpAdjustment }),
        AbilityDetailProvider(key: "constitutionShock", label: "Constitution — System Shock (Table 3)",
                               ruleID: constitutionRuleID, lookup: { ConstitutionTable.byScore[$0.constitution]?.systemShock }),
        AbilityDetailProvider(key: "constitutionResurrection", label: "Constitution — Resurrection Survival (Table 3)",
                               ruleID: constitutionRuleID, lookup: { ConstitutionTable.byScore[$0.constitution]?.resurrectionSurvival }),
        AbilityDetailProvider(key: "constitutionPoison", label: "Constitution — Poison Save (Table 3)",
                               ruleID: constitutionRuleID, lookup: { ConstitutionTable.byScore[$0.constitution]?.poisonSave }),

        // MARK: Inteligência (Tabela 4)
        AbilityDetailProvider(key: "intelligenceLanguages", label: "Intelligence — Number of Languages (Table 4)",
                               ruleID: intelligenceRuleID, lookup: { IntelligenceTable.byScore[$0.intelligence]?.languages }),
        AbilityDetailProvider(key: "intelligenceMaxLevel", label: "Intelligence — Max Spell Level (Table 4)",
                               ruleID: intelligenceRuleID, lookup: { IntelligenceTable.byScore[$0.intelligence]?.maxSpellLevel }),
        AbilityDetailProvider(key: "intelligenceLearn", label: "Intelligence — Chance to Learn Spell (Table 4)",
                               ruleID: intelligenceRuleID, lookup: { IntelligenceTable.byScore[$0.intelligence]?.learnChance }),
        AbilityDetailProvider(key: "intelligenceMaxPerLevel", label: "Intelligence — Max Spells per Level (Table 4)",
                               ruleID: intelligenceRuleID, lookup: { IntelligenceTable.byScore[$0.intelligence]?.maxSpellsPerLevel }),

        // MARK: Sabedoria (Tabela 5)
        AbilityDetailProvider(key: "wisdomDefense", label: "Wisdom — Magical Defense Adjustment (Table 5)",
                               ruleID: wisdomRuleID, lookup: { WisdomTable.byScore[$0.wisdom]?.magicDefense }),
        AbilityDetailProvider(key: "wisdomFailure", label: "Wisdom — Spell Failure (Table 5)",
                               ruleID: wisdomRuleID, lookup: { WisdomTable.byScore[$0.wisdom]?.spellFailure }),
        // `bonus_spells_priest`, convertido de deltas-por-score pra soma
        // cumulativa por círculo — ver `WisdomTable.bonusSpells(forScore:)`.
        AbilityDetailProvider(key: "wisdomBonusSpells", label: "Wisdom — Bonus Spells (Table 5)",
                               ruleID: wisdomRuleID, lookup: { WisdomTable.bonusSpells(forScore: $0.wisdom) }),

        // MARK: Carisma (Tabela 6)
        AbilityDetailProvider(key: "charismaHenchmen", label: "Charisma — Maximum Henchmen (Table 6)",
                               ruleID: charismaRuleID, lookup: { CharismaTable.byScore[$0.charisma]?.maxHenchmen }),
        AbilityDetailProvider(key: "charismaLoyalty", label: "Charisma — Loyalty Base (Table 6)",
                               ruleID: charismaRuleID, lookup: { CharismaTable.byScore[$0.charisma]?.loyaltyBase }),
        AbilityDetailProvider(key: "charismaReaction", label: "Charisma — Reaction Adjustment (Table 6)",
                               ruleID: charismaRuleID, lookup: { CharismaTable.byScore[$0.charisma]?.reaction }),
    ]
}

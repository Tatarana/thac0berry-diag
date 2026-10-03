import Foundation

/// As seis tabelas de atributo do PHB (Tabelas 1-6, capítulo 1) — extraídas
/// do mesmo JSON auditado da Referência de Regras (ver item 10 do TODO.md),
/// não digitadas de memória, geradas por um script Python contra
/// `rules_phb/ch01_ability_scores.json` igual ao `Thac0ByLevelProvider`/
/// `SavingThrowsByLevelProvider`. Cada `enum` é só a tabela; quem decide o que
/// fazer com ela é `AbilityDetailProvider` (`AbilityDetailProvider.swift`).

enum StrengthTable {
    struct Row { let hit: String; let dmg: String; let weight: String; let maxPress: String; let doors: String; let bars: String }
    static let byScore: [Int: Row] = [
        1: Row(hit: "-5", dmg: "-4", weight: "1", maxPress: "3", doors: "1", bars: "0%"),
        2: Row(hit: "-3", dmg: "-2", weight: "1", maxPress: "5", doors: "1", bars: "0%"),
        3: Row(hit: "-3", dmg: "-1", weight: "5", maxPress: "10", doors: "2", bars: "0%"),
        4: Row(hit: "-2", dmg: "-1", weight: "10", maxPress: "25", doors: "3", bars: "0%"),
        5: Row(hit: "-2", dmg: "-1", weight: "10", maxPress: "25", doors: "3", bars: "0%"),
        6: Row(hit: "-1", dmg: "None", weight: "20", maxPress: "55", doors: "4", bars: "0%"),
        7: Row(hit: "-1", dmg: "None", weight: "20", maxPress: "55", doors: "4", bars: "0%"),
        8: Row(hit: "Normal", dmg: "None", weight: "35", maxPress: "90", doors: "5", bars: "1%"),
        9: Row(hit: "Normal", dmg: "None", weight: "35", maxPress: "90", doors: "5", bars: "1%"),
        10: Row(hit: "Normal", dmg: "None", weight: "40", maxPress: "115", doors: "6", bars: "2%"),
        11: Row(hit: "Normal", dmg: "None", weight: "40", maxPress: "115", doors: "6", bars: "2%"),
        12: Row(hit: "Normal", dmg: "None", weight: "45", maxPress: "140", doors: "7", bars: "4%"),
        13: Row(hit: "Normal", dmg: "None", weight: "45", maxPress: "140", doors: "7", bars: "4%"),
        14: Row(hit: "Normal", dmg: "None", weight: "55", maxPress: "170", doors: "8", bars: "7%"),
        15: Row(hit: "Normal", dmg: "None", weight: "55", maxPress: "170", doors: "8", bars: "7%"),
        16: Row(hit: "Normal", dmg: "1", weight: "70", maxPress: "195", doors: "9", bars: "10%"),
        17: Row(hit: "1", dmg: "1", weight: "85", maxPress: "220", doors: "10", bars: "13%"),
        18: Row(hit: "1", dmg: "2", weight: "110", maxPress: "255", doors: "11", bars: "16%"),
        19: Row(hit: "3", dmg: "7", weight: "485", maxPress: "640", doors: "16(8)", bars: "50%"),
        20: Row(hit: "3", dmg: "8", weight: "535", maxPress: "700", doors: "17(10)", bars: "60%"),
        21: Row(hit: "4", dmg: "9", weight: "635", maxPress: "810", doors: "17(12)", bars: "70%"),
        22: Row(hit: "4", dmg: "10", weight: "785", maxPress: "970", doors: "18(14)", bars: "80%"),
        23: Row(hit: "5", dmg: "11", weight: "935", maxPress: "1,130", doors: "18(16)", bars: "90%"),
        24: Row(hit: "6", dmg: "12", weight: "1,235", maxPress: "1,440", doors: "19(17)", bars: "95%"),
        25: Row(hit: "7", dmg: "14", weight: "1,535", maxPress: "1,750", doors: "19(18)", bars: "99%"),
    ]

    /// Força excepcional (18/01 a 18/00) — só existe pra pontuação 18. A
    /// chave é o LIMITE SUPERIOR da faixa de percentual; `row(forExceptional:)`
    /// acha a primeira faixa cujo limite já cobre o percentual do personagem.
    static let byExceptionalUpperBound: [(upperBound: Int, row: Row)] = [
        (50, Row(hit: "1", dmg: "3", weight: "135", maxPress: "280", doors: "12", bars: "20%")),
        (75, Row(hit: "2", dmg: "3", weight: "160", maxPress: "305", doors: "13", bars: "25%")),
        (90, Row(hit: "2", dmg: "4", weight: "185", maxPress: "330", doors: "14", bars: "30%")),
        (99, Row(hit: "2", dmg: "5", weight: "235", maxPress: "380", doors: "15(3)", bars: "35%")),
        (100, Row(hit: "3", dmg: "6", weight: "335", maxPress: "480", doors: "16(6)", bars: "40%")),
    ]

    /// `score` já em 3-18 (sem a parte fracionária); `exceptionalPercentile`
    /// é `AbilityScores.exceptionalStrength` (1-100, só relevante quando
    /// `score == 18`). Espelha a mesma leitura de `AbilityScores.strengthDisplay`.
    static func row(score: Int, exceptionalPercentile: Int?) -> Row? {
        if score == 18, let pct = exceptionalPercentile, pct > 0 {
            let clamped = max(1, min(pct, 100))
            for entry in byExceptionalUpperBound where clamped <= entry.upperBound {
                return entry.row
            }
        }
        return byScore[score]
    }
}

enum DexterityTable {
    struct Row { let reaction: String; let missile: String; let defense: String }
    static let byScore: [Int: Row] = [
        1: Row(reaction: "-6", missile: "-6", defense: "5"),
        2: Row(reaction: "-4", missile: "-4", defense: "5"),
        3: Row(reaction: "-3", missile: "-3", defense: "4"),
        4: Row(reaction: "-2", missile: "-2", defense: "3"),
        5: Row(reaction: "-1", missile: "-1", defense: "2"),
        6: Row(reaction: "0", missile: "0", defense: "1"),
        7: Row(reaction: "0", missile: "0", defense: "0"),
        8: Row(reaction: "0", missile: "0", defense: "0"),
        9: Row(reaction: "0", missile: "0", defense: "0"),
        10: Row(reaction: "0", missile: "0", defense: "0"),
        11: Row(reaction: "0", missile: "0", defense: "0"),
        12: Row(reaction: "0", missile: "0", defense: "0"),
        13: Row(reaction: "0", missile: "0", defense: "0"),
        14: Row(reaction: "0", missile: "0", defense: "0"),
        15: Row(reaction: "0", missile: "0", defense: "-1"),
        16: Row(reaction: "1", missile: "1", defense: "-2"),
        17: Row(reaction: "2", missile: "2", defense: "-3"),
        18: Row(reaction: "2", missile: "2", defense: "-4"),
        19: Row(reaction: "3", missile: "3", defense: "-4"),
        20: Row(reaction: "3", missile: "3", defense: "-4"),
        21: Row(reaction: "4", missile: "4", defense: "-5"),
        22: Row(reaction: "4", missile: "4", defense: "-5"),
        23: Row(reaction: "4", missile: "4", defense: "-5"),
        24: Row(reaction: "5", missile: "5", defense: "-6"),
        25: Row(reaction: "5", missile: "5", defense: "-6"),
    ]
}

enum ConstitutionTable {
    struct Row { let hpAdjustment: String; let systemShock: String; let resurrectionSurvival: String; let poisonSave: String }
    static let byScore: [Int: Row] = [
        1: Row(hpAdjustment: "-3", systemShock: "25%", resurrectionSurvival: "30%", poisonSave: "-2"),
        2: Row(hpAdjustment: "-2", systemShock: "30%", resurrectionSurvival: "35%", poisonSave: "-1"),
        3: Row(hpAdjustment: "-2", systemShock: "35%", resurrectionSurvival: "40%", poisonSave: "0"),
        4: Row(hpAdjustment: "-1", systemShock: "40%", resurrectionSurvival: "45%", poisonSave: "0"),
        5: Row(hpAdjustment: "-1", systemShock: "45%", resurrectionSurvival: "50%", poisonSave: "0"),
        6: Row(hpAdjustment: "-1", systemShock: "50%", resurrectionSurvival: "55%", poisonSave: "0"),
        7: Row(hpAdjustment: "0", systemShock: "55%", resurrectionSurvival: "60%", poisonSave: "0"),
        8: Row(hpAdjustment: "0", systemShock: "60%", resurrectionSurvival: "65%", poisonSave: "0"),
        9: Row(hpAdjustment: "0", systemShock: "65%", resurrectionSurvival: "70%", poisonSave: "0"),
        10: Row(hpAdjustment: "0", systemShock: "70%", resurrectionSurvival: "75%", poisonSave: "0"),
        11: Row(hpAdjustment: "0", systemShock: "75%", resurrectionSurvival: "80%", poisonSave: "0"),
        12: Row(hpAdjustment: "0", systemShock: "80%", resurrectionSurvival: "85%", poisonSave: "0"),
        13: Row(hpAdjustment: "0", systemShock: "85%", resurrectionSurvival: "90%", poisonSave: "0"),
        14: Row(hpAdjustment: "0", systemShock: "88%", resurrectionSurvival: "92%", poisonSave: "0"),
        15: Row(hpAdjustment: "1", systemShock: "90%", resurrectionSurvival: "94%", poisonSave: "0"),
        16: Row(hpAdjustment: "2", systemShock: "95%", resurrectionSurvival: "96%", poisonSave: "0"),
        17: Row(hpAdjustment: "+2(+3)", systemShock: "97%", resurrectionSurvival: "98%", poisonSave: "0"),
        18: Row(hpAdjustment: "+2(+4)", systemShock: "99%", resurrectionSurvival: "100%", poisonSave: "0"),
        19: Row(hpAdjustment: "+2(+5)", systemShock: "99%", resurrectionSurvival: "100%", poisonSave: "1"),
        20: Row(hpAdjustment: "+2(+5)", systemShock: "99%", resurrectionSurvival: "100%", poisonSave: "1"),
        21: Row(hpAdjustment: "+2(+6)", systemShock: "99%", resurrectionSurvival: "100%", poisonSave: "2"),
        22: Row(hpAdjustment: "+2(+6)", systemShock: "99%", resurrectionSurvival: "100%", poisonSave: "2"),
        23: Row(hpAdjustment: "+2(+6)", systemShock: "99%", resurrectionSurvival: "100%", poisonSave: "3"),
        24: Row(hpAdjustment: "+2(+7)", systemShock: "99%", resurrectionSurvival: "100%", poisonSave: "3"),
        25: Row(hpAdjustment: "+2(+7)", systemShock: "100%", resurrectionSurvival: "100%", poisonSave: "4"),
    ]
}

enum IntelligenceTable {
    struct Row { let languages: String; let maxSpellLevel: String; let learnChance: String; let maxSpellsPerLevel: String }
    static let byScore: [Int: Row] = [
        1: Row(languages: "0", maxSpellLevel: "—", learnChance: "—", maxSpellsPerLevel: "—"),
        2: Row(languages: "1", maxSpellLevel: "—", learnChance: "—", maxSpellsPerLevel: "—"),
        3: Row(languages: "1", maxSpellLevel: "—", learnChance: "—", maxSpellsPerLevel: "—"),
        4: Row(languages: "1", maxSpellLevel: "—", learnChance: "—", maxSpellsPerLevel: "—"),
        5: Row(languages: "1", maxSpellLevel: "—", learnChance: "—", maxSpellsPerLevel: "—"),
        6: Row(languages: "1", maxSpellLevel: "—", learnChance: "—", maxSpellsPerLevel: "—"),
        7: Row(languages: "1", maxSpellLevel: "—", learnChance: "—", maxSpellsPerLevel: "—"),
        8: Row(languages: "1", maxSpellLevel: "—", learnChance: "—", maxSpellsPerLevel: "—"),
        9: Row(languages: "2", maxSpellLevel: "4th", learnChance: "35%", maxSpellsPerLevel: "6"),
        10: Row(languages: "2", maxSpellLevel: "5th", learnChance: "40%", maxSpellsPerLevel: "7"),
        11: Row(languages: "2", maxSpellLevel: "5th", learnChance: "45%", maxSpellsPerLevel: "7"),
        12: Row(languages: "3", maxSpellLevel: "6th", learnChance: "50%", maxSpellsPerLevel: "7"),
        13: Row(languages: "3", maxSpellLevel: "6th", learnChance: "55%", maxSpellsPerLevel: "9"),
        14: Row(languages: "4", maxSpellLevel: "7th", learnChance: "60%", maxSpellsPerLevel: "9"),
        15: Row(languages: "4", maxSpellLevel: "7th", learnChance: "65%", maxSpellsPerLevel: "11"),
        16: Row(languages: "5", maxSpellLevel: "8th", learnChance: "70%", maxSpellsPerLevel: "11"),
        17: Row(languages: "6", maxSpellLevel: "8th", learnChance: "75%", maxSpellsPerLevel: "14"),
        18: Row(languages: "7", maxSpellLevel: "9th", learnChance: "85%", maxSpellsPerLevel: "18"),
        19: Row(languages: "8", maxSpellLevel: "9th", learnChance: "95%", maxSpellsPerLevel: "All"),
        20: Row(languages: "9", maxSpellLevel: "9th", learnChance: "96%", maxSpellsPerLevel: "All"),
        21: Row(languages: "10", maxSpellLevel: "9th", learnChance: "97%", maxSpellsPerLevel: "All"),
        22: Row(languages: "11", maxSpellLevel: "9th", learnChance: "98%", maxSpellsPerLevel: "All"),
        23: Row(languages: "12", maxSpellLevel: "9th", learnChance: "99%", maxSpellsPerLevel: "All"),
        24: Row(languages: "15", maxSpellLevel: "9th", learnChance: "100%", maxSpellsPerLevel: "All"),
        25: Row(languages: "20", maxSpellLevel: "9th", learnChance: "100%", maxSpellsPerLevel: "All"),
    ]

    /// `maxSpellLevel` acima como número puro ("9th" → 9, "—"/score fora da
    /// tabela → 0) — usado por `WizardTables.spellProgression` (2026-09-29)
    /// pra travar qualquer círculo acima do que a Inteligência do mago
    /// permite, em vez de duplicar os mesmos valores como `Int` à parte.
    static func maxSpellLevelInt(forScore score: Int) -> Int {
        guard let text = byScore[score]?.maxSpellLevel else { return 0 }
        let digits = text.filter { $0.isNumber }
        return Int(digits) ?? 0
    }

    /// `languages` acima como número puro (2026-09-30) — usado por
    /// `ProficiencySlotsTable.totalWeaponSlots` pra somar o bônus de
    /// Inteligência alta às slots de proficiência de arma (regra opcional
    /// do Complete Fighter's Handbook, "Intelligence and Proficiencies":
    /// "you may... take extra proficiencies when first created equal to
    /// the number of extra languages the character gets from high
    /// Intelligence [Table 4]" — o próprio PHB já usa essa coluna pro caso
    /// de proficiências NÃO-de-arma, ver `phb_ch05_proficiencies`).
    static func bonusLanguages(forScore score: Int) -> Int {
        guard let text = byScore[score]?.languages else { return 0 }
        return Int(text) ?? 0
    }
}

enum WisdomTable {
    struct Row { let magicDefense: String; let spellFailure: String }
    static let byScore: [Int: Row] = [
        1: Row(magicDefense: "-6", spellFailure: "80%"),
        2: Row(magicDefense: "-4", spellFailure: "60%"),
        3: Row(magicDefense: "-3", spellFailure: "50%"),
        4: Row(magicDefense: "-2", spellFailure: "45%"),
        5: Row(magicDefense: "-1", spellFailure: "40%"),
        6: Row(magicDefense: "-1", spellFailure: "35%"),
        7: Row(magicDefense: "-1", spellFailure: "30%"),
        8: Row(magicDefense: "0", spellFailure: "25%"),
        9: Row(magicDefense: "0", spellFailure: "20%"),
        10: Row(magicDefense: "0", spellFailure: "15%"),
        11: Row(magicDefense: "0", spellFailure: "10%"),
        12: Row(magicDefense: "0", spellFailure: "5%"),
        13: Row(magicDefense: "0", spellFailure: "0%"),
        14: Row(magicDefense: "0", spellFailure: "0%"),
        15: Row(magicDefense: "1", spellFailure: "0%"),
        16: Row(magicDefense: "2", spellFailure: "0%"),
        17: Row(magicDefense: "3", spellFailure: "0%"),
        18: Row(magicDefense: "4", spellFailure: "0%"),
        19: Row(magicDefense: "4", spellFailure: "0%"),
        20: Row(magicDefense: "4", spellFailure: "0%"),
        21: Row(magicDefense: "4", spellFailure: "0%"),
        22: Row(magicDefense: "4", spellFailure: "0%"),
        23: Row(magicDefense: "4", spellFailure: "0%"),
        24: Row(magicDefense: "4", spellFailure: "0%"),
        25: Row(magicDefense: "4", spellFailure: "0%"),
    ]

    /// Tabela 5 (PHB), coluna "Bonus Spells" — magias bônus por círculo que
    /// um sacerdote ganha por Sabedoria alta. A tabela impressa lista, pra
    /// cada valor de Sabedoria, quais círculos ganham +1 NAQUELE patamar
    /// (ex.: 13-14 → 1º círculo; 19 → "1st, 3rd"). `bonusSpellsByScore` é
    /// essa tabela crua, ainda não acumulada.
    private static let bonusSpellsByScore: [Int: [Int]] = [
        1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [], 8: [],
        9: [], 10: [], 11: [], 12: [],
        13: [1], 14: [1],
        15: [2], 16: [2],
        17: [3],
        18: [4],
        19: [1, 3],
        20: [2, 4],
        21: [3, 5],
        22: [4, 5],
        23: [1, 6],
        24: [5, 6],
        25: [6, 7],
    ]

    /// Soma cumulativa das magias bônus por círculo até a Sabedoria dada,
    /// no formato "+N / +N / ..." esperado por `AbilityDetails.wisdomBonusSpells`
    /// (posição = círculo, começando em 1).
    ///
    /// CORREÇÃO (2026-09-26): a versão anterior pulava a soma quando a
    /// lista de círculos de um score repetia a do score anterior (ex.:
    /// Sabedoria 13 e 14 mostram "1st" nos dois, então só somava uma vez).
    /// Isso está ERRADO — cada score de 13 a 25 é seu próprio evento de
    /// bônus, mesmo quando a linha impressa parece repetir o círculo do
    /// score anterior. A prova está no próprio texto da regra (Table 5,
    /// `Resources/rules.json`, id `phb_ch01_wisdom`): "a priest with a
    /// wisdom of 15 is entitled to TWO 1st-level bonus spells and ONE
    /// 2nd-level bonus spell" — ou seja, em Sabedoria 15 o 1º círculo já
    /// está em +2 (ganho em 13 E em 14), não +1. Somando sem pular
    /// repetidos: Sabedoria 19 dá 1º=+3, 2º=+2, 3º=+2, 4º=+1 (bate com o
    /// exemplo relatado pelo usuário: clérigo nível 11, 5 slots base de 1º
    /// círculo + 3 de bônus = 8).
    static func bonusSpells(forScore score: Int) -> String? {
        guard let totals = bonusSpellTotals(forScore: score), let maxCircle = totals.keys.max() else { return nil }
        let parts = (1...maxCircle).map { "+\(totals[$0] ?? 0)" }
        return parts.joined(separator: " / ")
    }

    /// Mesma soma de `bonusSpells(forScore:)`, mas como `[círculo: total]`
    /// em vez de texto formatado — usada por `PriestTables.spellProgression`
    /// (`Character.swift`) pra somar o bônus de verdade na grade de slots
    /// da Priest Spell Sheet, não só no texto informativo da célula "Bonus
    /// Spells" da tabela de atributos.
    ///
    /// CORREÇÃO (2026-09-26, mesmo dia do ajuste acima): até aqui essa soma
    /// só alimentava o campo de texto `AbilityDetails.wisdomBonusSpells`,
    /// que é editável e só é regravado quando o jogador muda a Sabedoria e
    /// aplica as consequências automáticas — nunca chega na grade real de
    /// slots (`PlayerCharacter.computedSpellSlotAllotments`), que vinha
    /// só da Tabela 24 (Priest Spell Progression), sem nenhum bônus de
    /// Sabedoria somado. Resultado: consertar só o texto não mudava a
    /// contagem de slots que o jogador via na ficha — exatamente o bug
    /// relatado.
    static func bonusSpellTotals(forScore score: Int) -> [Int: Int]? {
        guard score >= 9 else { return nil }
        var totals: [Int: Int] = [:]
        for s in 1...score {
            for circle in bonusSpellsByScore[s] ?? [] {
                totals[circle, default: 0] += 1
            }
        }
        return totals.isEmpty ? nil : totals
    }
}

enum CharismaTable {
    struct Row { let maxHenchmen: String; let loyaltyBase: String; let reaction: String }
    static let byScore: [Int: Row] = [
        1: Row(maxHenchmen: "0", loyaltyBase: "-8", reaction: "-7"),
        2: Row(maxHenchmen: "1", loyaltyBase: "-7", reaction: "-6"),
        3: Row(maxHenchmen: "1", loyaltyBase: "-6", reaction: "-5"),
        4: Row(maxHenchmen: "1", loyaltyBase: "-5", reaction: "-4"),
        5: Row(maxHenchmen: "2", loyaltyBase: "-4", reaction: "-3"),
        6: Row(maxHenchmen: "2", loyaltyBase: "-3", reaction: "-2"),
        7: Row(maxHenchmen: "3", loyaltyBase: "-2", reaction: "-1"),
        8: Row(maxHenchmen: "3", loyaltyBase: "-1", reaction: "0"),
        9: Row(maxHenchmen: "4", loyaltyBase: "0", reaction: "0"),
        10: Row(maxHenchmen: "4", loyaltyBase: "0", reaction: "0"),
        11: Row(maxHenchmen: "4", loyaltyBase: "0", reaction: "0"),
        12: Row(maxHenchmen: "5", loyaltyBase: "0", reaction: "0"),
        13: Row(maxHenchmen: "5", loyaltyBase: "0", reaction: "1"),
        14: Row(maxHenchmen: "6", loyaltyBase: "1", reaction: "2"),
        15: Row(maxHenchmen: "7", loyaltyBase: "3", reaction: "3"),
        16: Row(maxHenchmen: "8", loyaltyBase: "4", reaction: "5"),
        17: Row(maxHenchmen: "10", loyaltyBase: "6", reaction: "6"),
        18: Row(maxHenchmen: "15", loyaltyBase: "8", reaction: "7"),
        19: Row(maxHenchmen: "20", loyaltyBase: "10", reaction: "8"),
        20: Row(maxHenchmen: "25", loyaltyBase: "12", reaction: "9"),
        21: Row(maxHenchmen: "30", loyaltyBase: "14", reaction: "10"),
        22: Row(maxHenchmen: "35", loyaltyBase: "16", reaction: "11"),
        23: Row(maxHenchmen: "40", loyaltyBase: "18", reaction: "12"),
        24: Row(maxHenchmen: "45", loyaltyBase: "20", reaction: "13"),
        25: Row(maxHenchmen: "50", loyaltyBase: "20", reaction: "14"),
    ]
}

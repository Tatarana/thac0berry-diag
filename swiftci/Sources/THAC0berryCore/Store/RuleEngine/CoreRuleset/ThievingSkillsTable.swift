import Foundation

/// Dados de Thieving Skills do grupo Rogue (Thief/Bard/Ninja) — item da
/// rodada de 2026-09-30 junto com a Rules Reference do Complete Bard's/
/// Ninja's/Thief's Handbook. Tudo copiado linha a linha das Tables 25-30
/// e 32-33 do PHB (já embutidas em `Resources/rules.json`, entrada
/// `phb_ch03_rogue_tables` — não digitado de memória) e das Tables 2, 3 e
/// 5 do Complete Ninja's Handbook (enviadas pelo usuário; Table 3 do CNH é
/// a própria Table 28 do PHB "reproduzida", e a lista de raça do CNH pra
/// Dwarf/Halfling bate exatamente com a Table 27 do PHB — por isso ninja
/// reaproveita essas duas tabelas do thief em vez de duplicar).
///
/// Não existe cálculo automático de armadura aqui (ver `WeaponCombatForm`/
/// `ArmorField`: o campo "Armor" da ficha guarda só o valor de AC, nunca
/// o TIPO de armadura, então não dá pra saber com segurança qual coluna
/// da Table 29/Table 5 se aplica) — por isso o app semeia só Base + Raça
/// + Destreza no campo editável da ficha, e mostra as quatro tabelas
/// inteiras (base, raça, destreza, armadura) na 4ª página de referência
/// (`RogueReferencePage`) pro jogador aplicar o ajuste de armadura à mão,
/// do mesmo jeito que já acontece com a penalidade de não-proficiência do
/// Warrior (ver `ProficiencySlotsTable`).
enum ThievingSkillsTable {
    /// As 8 habilidades clássicas, na ordem em que o PHB sempre lista —
    /// Thief e Ninja usam as 8; Bard usa só 4 (ver `skills(for:)`).
    static let allSkills = [
        "Pick Pockets", "Open Locks", "Find/Remove Traps", "Move Silently",
        "Hide in Shadows", "Detect Noise", "Climb Walls", "Read Languages",
    ]

    /// Habilidades aplicáveis por classe — Bard só tem 4 (PHB, Table 33);
    /// Thief e Ninja têm as 8. Ordem preservada de `allSkills`.
    static func skills(for characterClass: CharacterClass) -> [String] {
        switch characterClass {
        case .bard: return ["Climb Walls", "Detect Noise", "Pick Pockets", "Read Languages"]
        case .thief, .ninja: return allSkills
        default: return []
        }
    }

    // MARK: Table 26 (PHB) — Thief base scores

    static let thiefBaseScores: [String: Int] = [
        "Pick Pockets": 15, "Open Locks": 10, "Find/Remove Traps": 5,
        "Move Silently": 10, "Hide in Shadows": 5, "Detect Noise": 15,
        "Climb Walls": 60, "Read Languages": 0,
    ]

    // MARK: Table 2 (Complete Ninja's Handbook) — Ninja base scores

    static let ninjaBaseScores: [String: Int] = [
        "Pick Pockets": 0, "Open Locks": 0, "Find/Remove Traps": 0,
        "Move Silently": 20, "Hide in Shadows": 20, "Detect Noise": 10,
        "Climb Walls": 40, "Read Languages": 0,
    ]

    // MARK: Table 33 (PHB) — Bard base scores (flat, não varia por raça na tabela — só as 4 habilidades do bardo)

    static let bardBaseScores: [String: Int] = [
        "Climb Walls": 50, "Detect Noise": 20, "Pick Pockets": 10, "Read Languages": 5,
    ]

    /// Escolhe a tabela-base certa pra classe (Bard usa a dele; Thief e
    /// Ninja têm tabelas PRÓPRIAS e DIFERENTES, apesar de ambos serem
    /// "ladrões" — Table 26 do PHB vs. Table 2 do CNH, conferido linha a
    /// linha: não são a mesma tabela).
    static func baseScore(skill: String, characterClass: CharacterClass) -> Int {
        switch characterClass {
        case .bard: return bardBaseScores[skill] ?? 0
        case .ninja: return ninjaBaseScores[skill] ?? 0
        default: return thiefBaseScores[skill] ?? 0
        }
    }

    // MARK: Table 27 (PHB) — Racial adjustments
    //
    // Reaproveitada por Ninja: o CNH restringe ninja a Human/Dwarf/Halfling
    // e os dois ajustes que lista (Dwarf, Halfling) batem número a número
    // com esta mesma tabela do PHB.

    static let racialAdjustments: [String: [String: Int]] = [
        "Dwarf": ["Open Locks": 10, "Find/Remove Traps": 15, "Climb Walls": -10, "Read Languages": -5],
        "Elf": ["Pick Pockets": 5, "Open Locks": -5, "Move Silently": 5, "Hide in Shadows": 10, "Detect Noise": 5],
        "Gnome": ["Open Locks": 5, "Find/Remove Traps": 10, "Move Silently": 5, "Hide in Shadows": 5,
                  "Detect Noise": 10, "Climb Walls": -15],
        "Half-Elf": ["Pick Pockets": 10, "Hide in Shadows": 5],
        "Halfling": ["Pick Pockets": 5, "Open Locks": 5, "Find/Remove Traps": 5, "Move Silently": 10,
                     "Hide in Shadows": 15, "Detect Noise": 5, "Climb Walls": -15, "Read Languages": -5],
    ]

    /// Busca por substring normalizada (`Fuzzy.normalize`) contra as 5
    /// raças da tabela — mesmo espírito de `WeaponFormRow.isRangedWeapon`:
    /// o campo "Race" da ficha é texto livre ("Hill Dwarf", "Grey Elf"
    /// etc.), então compara por substring em vez de igualdade exata.
    /// `nil` (raça não bate com nenhuma das 5, ex. Human) = sem ajuste.
    static func racialAdjustment(skill: String, race: String) -> Int {
        let normalizedRace = Fuzzy.normalize(race)
        guard !normalizedRace.isEmpty else { return 0 }
        for (key, table) in racialAdjustments {
            if normalizedRace.contains(Fuzzy.normalize(key)) {
                return table[skill] ?? 0
            }
        }
        return 0
    }

    // MARK: Table 28 (PHB) — Dexterity adjustments
    //
    // Reaproveitada por Ninja: a Table 3 do CNH é literalmente "reproduzida
    // da Table 28 do PHB" (texto do próprio livro) — mesmos números, só
    // recortada a partir de Destreza 13 (mínimo pra ser ninja).

    static let dexterityAdjustments: [Int: [String: Int]] = [
        9: ["Pick Pockets": -15, "Open Locks": -10, "Find/Remove Traps": -10, "Move Silently": -20, "Hide in Shadows": -10],
        10: ["Pick Pockets": -10, "Open Locks": -5, "Find/Remove Traps": -10, "Move Silently": -15, "Hide in Shadows": -5],
        11: ["Pick Pockets": -5, "Find/Remove Traps": -5, "Move Silently": -10],
        12: ["Move Silently": -5],
        13: [:], 14: [:], 15: [:],
        16: ["Open Locks": 5],
        17: ["Pick Pockets": 5, "Open Locks": 10, "Move Silently": 5, "Hide in Shadows": 5],
        18: ["Pick Pockets": 10, "Open Locks": 15, "Find/Remove Traps": 5, "Move Silently": 10, "Hide in Shadows": 10],
        19: ["Pick Pockets": 15, "Open Locks": 20, "Find/Remove Traps": 10, "Move Silently": 15, "Hide in Shadows": 15],
    ]

    /// Destreza abaixo de 9 ou acima de 19 usa a ponta mais próxima da
    /// tabela (o PHB não lista fora desse intervalo pra essas 5
    /// habilidades — as outras 3, Detect Noise/Climb Walls/Read Languages,
    /// nunca têm ajuste de Destreza em tabela nenhuma).
    static func dexterityAdjustment(skill: String, dexterity: Int) -> Int {
        let clamped = max(9, min(19, dexterity))
        return dexterityAdjustments[clamped]?[skill] ?? 0
    }

    // MARK: Table 30 (PHB) — Backstab Damage Multipliers
    //
    // O próprio CNH diz "the ninja has the same backstab ability as the
    // thief" (Table 4 do CNH = cópia idêntica da Table 30 do PHB) — uma
    // tabela só serve as duas classes.

    static func backstabMultiplier(level: Int) -> String {
        switch level {
        case ..<1: return "—"
        case 1...4: return "x2"
        case 5...8: return "x3"
        case 9...12: return "x4"
        default: return "x5"
        }
    }

    // MARK: Table 29 (PHB) — Thief armor adjustments (referência only)

    static let thiefArmorColumns = ["No Armor", "Elven Chain", "Padded/Hide/Studded", "Chain/Ring Mail"]
    static let thiefArmorAdjustments: [String: [Int]] = [
        // [No Armor, Elven Chain, Padded/Hide/Studded, Chain/Ring Mail]
        "Pick Pockets": [5, -20, -30, -25],
        "Open Locks": [0, -5, -10, -10],
        "Find/Remove Traps": [0, -5, -10, -10],
        "Move Silently": [10, -10, -20, -15],
        "Hide in Shadows": [5, -10, -20, -15],
        "Detect Noise": [0, -5, -10, -5],
        "Climb Walls": [10, -20, -30, -25],
        "Read Languages": [0, 0, 0, 0],
    ]

    // MARK: Table 5 (Complete Ninja's Handbook) — Ninja armor adjustments (referência only)
    //
    // Diferente da Table 29 do PHB — o ninja pode usar uma lista de
    // armaduras mais ampla (ver "Weapons and Armor" no CNH), então o livro
    // dá sua própria tabela em vez de reaproveitar a do thief.

    static let ninjaArmorColumns = ["No Armor", "Leather", "Elfin Chain", "Studded/Padded", "Hide",
                                     "Ring/Chain", "Brigandine/Splint", "Scale/Banded", "Shield"]
    static let ninjaArmorAdjustments: [String: [Int]] = [
        "Pick Pockets": [5, 0, -20, -30, -60, -40, -40, -50, -60],
        "Open Locks": [0, 0, -5, -10, -50, -15, -15, -20, -20],
        "Find/Remove Traps": [0, 0, -5, -10, -50, -15, -25, -20, -20],
        "Move Silently": [10, 0, -10, -20, -30, -40, -40, -60, -10],
        "Hide in Shadows": [5, 0, -10, -20, -20, -30, -30, -50, 0],
        "Detect Noise": [0, 0, -5, -10, -10, -20, -25, -30, -10],
        "Climb Walls": [10, 0, -20, -30, -60, -40, -50, -90, -30],
        "Read Languages": [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]

    /// Total "de referência" (base + raça + destreza, SEM armadura — ver
    /// doc do enum) — usado só pra semear o campo editável da ficha na
    /// primeira vez que a linha nasce, nunca recalculado depois (mesmo
    /// padrão de `ProficiencySlotsTable.nonProficiencyPenalty` /
    /// `CombatModifiersForm`).
    static func seedTotal(skill: String, characterClass: CharacterClass, race: String, dexterity: Int) -> String {
        let total = baseScore(skill: skill, characterClass: characterClass)
            + racialAdjustment(skill: skill, race: race)
            + dexterityAdjustment(skill: skill, dexterity: dexterity)
        return "\(total)%"
    }
}

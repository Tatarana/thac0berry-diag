import Foundation

/// Tabela 60 do PHB ("Character Saving Throws") — as cinco jogadas de
/// proteção por grupo/faixa de nível. Mesma origem confiável do
/// `Thac0ByLevelProvider`: extraído do JSON auditado (`phb_ch09_the_saving_throw`
/// na base de regras), não digitado de memória.
///
/// A tabela do livro não é "um valor por nível" como a de THAC0 — é uma
/// faixa (ex. níveis 1–3 do Clérigo têm os mesmos cinco números). `Row`
/// guarda o topo da faixa; a busca pega a primeira cuja `maxLevel` já
/// cobre o nível do personagem, então a última linha de cada grupo usa
/// `Int.max` pra representar o "N+" do livro.
struct SavingThrowsByLevelProvider: RuleProvider {
    let key = "savingThrows"
    let label = "Saving Throws by Level (Table 60)"

    private struct Row {
        let maxLevel: Int
        let values: SavingThrows
    }

    // Mesma causa raiz do `Thac0ByLevelProvider` (ver o comentário grande
    // lá) — aqui a expressão era maior ainda (27 `Row(...)` dentro de UM
    // dicionário só), então era a mais provável de estourar o
    // type-checker primeiro. Cada grupo virou uma constante `[Row]`
    // própria, type-checada sozinha, antes de entrar no dicionário.
    private static let priestRows: [Row] = [
        Row(maxLevel: 3, values: SavingThrows(paralyzationPoisonDeath: 10, rodStaffWand: 14, petrificationPolymorph: 13, breathWeapon: 16, spell: 15)),
        Row(maxLevel: 6, values: SavingThrows(paralyzationPoisonDeath: 9, rodStaffWand: 13, petrificationPolymorph: 12, breathWeapon: 15, spell: 14)),
        Row(maxLevel: 9, values: SavingThrows(paralyzationPoisonDeath: 7, rodStaffWand: 11, petrificationPolymorph: 10, breathWeapon: 13, spell: 12)),
        Row(maxLevel: 12, values: SavingThrows(paralyzationPoisonDeath: 6, rodStaffWand: 10, petrificationPolymorph: 9, breathWeapon: 12, spell: 11)),
        Row(maxLevel: 15, values: SavingThrows(paralyzationPoisonDeath: 5, rodStaffWand: 9, petrificationPolymorph: 8, breathWeapon: 11, spell: 10)),
        Row(maxLevel: 18, values: SavingThrows(paralyzationPoisonDeath: 4, rodStaffWand: 8, petrificationPolymorph: 7, breathWeapon: 10, spell: 9)),
        Row(maxLevel: .max, values: SavingThrows(paralyzationPoisonDeath: 2, rodStaffWand: 6, petrificationPolymorph: 5, breathWeapon: 8, spell: 7)),
    ]

    private static let rogueRows: [Row] = [
        Row(maxLevel: 4, values: SavingThrows(paralyzationPoisonDeath: 13, rodStaffWand: 14, petrificationPolymorph: 12, breathWeapon: 16, spell: 15)),
        Row(maxLevel: 8, values: SavingThrows(paralyzationPoisonDeath: 12, rodStaffWand: 12, petrificationPolymorph: 11, breathWeapon: 15, spell: 13)),
        Row(maxLevel: 12, values: SavingThrows(paralyzationPoisonDeath: 11, rodStaffWand: 10, petrificationPolymorph: 10, breathWeapon: 14, spell: 11)),
        Row(maxLevel: 16, values: SavingThrows(paralyzationPoisonDeath: 10, rodStaffWand: 8, petrificationPolymorph: 9, breathWeapon: 13, spell: 9)),
        Row(maxLevel: 20, values: SavingThrows(paralyzationPoisonDeath: 9, rodStaffWand: 6, petrificationPolymorph: 8, breathWeapon: 12, spell: 7)),
        Row(maxLevel: .max, values: SavingThrows(paralyzationPoisonDeath: 8, rodStaffWand: 4, petrificationPolymorph: 7, breathWeapon: 11, spell: 5)),
    ]

    // O livro também tem uma linha "nível 0" (recruta, pré-1º nível) —
    // fora de escopo aqui, já que todo `PlayerCharacter` é pelo menos
    // nível 1.
    private static let warriorRows: [Row] = [
        Row(maxLevel: 2, values: SavingThrows(paralyzationPoisonDeath: 14, rodStaffWand: 16, petrificationPolymorph: 15, breathWeapon: 17, spell: 17)),
        Row(maxLevel: 4, values: SavingThrows(paralyzationPoisonDeath: 13, rodStaffWand: 15, petrificationPolymorph: 14, breathWeapon: 16, spell: 16)),
        Row(maxLevel: 6, values: SavingThrows(paralyzationPoisonDeath: 11, rodStaffWand: 13, petrificationPolymorph: 12, breathWeapon: 13, spell: 14)),
        Row(maxLevel: 8, values: SavingThrows(paralyzationPoisonDeath: 10, rodStaffWand: 12, petrificationPolymorph: 11, breathWeapon: 12, spell: 13)),
        Row(maxLevel: 10, values: SavingThrows(paralyzationPoisonDeath: 8, rodStaffWand: 10, petrificationPolymorph: 9, breathWeapon: 9, spell: 11)),
        Row(maxLevel: 12, values: SavingThrows(paralyzationPoisonDeath: 7, rodStaffWand: 9, petrificationPolymorph: 8, breathWeapon: 8, spell: 10)),
        Row(maxLevel: 14, values: SavingThrows(paralyzationPoisonDeath: 5, rodStaffWand: 7, petrificationPolymorph: 6, breathWeapon: 5, spell: 8)),
        Row(maxLevel: 16, values: SavingThrows(paralyzationPoisonDeath: 4, rodStaffWand: 6, petrificationPolymorph: 5, breathWeapon: 4, spell: 7)),
        Row(maxLevel: .max, values: SavingThrows(paralyzationPoisonDeath: 3, rodStaffWand: 5, petrificationPolymorph: 4, breathWeapon: 4, spell: 6)),
    ]

    private static let wizardRows: [Row] = [
        Row(maxLevel: 5, values: SavingThrows(paralyzationPoisonDeath: 14, rodStaffWand: 11, petrificationPolymorph: 13, breathWeapon: 15, spell: 12)),
        Row(maxLevel: 10, values: SavingThrows(paralyzationPoisonDeath: 13, rodStaffWand: 9, petrificationPolymorph: 11, breathWeapon: 13, spell: 10)),
        Row(maxLevel: 15, values: SavingThrows(paralyzationPoisonDeath: 11, rodStaffWand: 7, petrificationPolymorph: 9, breathWeapon: 11, spell: 8)),
        Row(maxLevel: 20, values: SavingThrows(paralyzationPoisonDeath: 10, rodStaffWand: 5, petrificationPolymorph: 7, breathWeapon: 9, spell: 6)),
        Row(maxLevel: .max, values: SavingThrows(paralyzationPoisonDeath: 8, rodStaffWand: 3, petrificationPolymorph: 5, breathWeapon: 7, spell: 4)),
    ]

    /// Psionicist (CPsiH "Table 8: Psionicist Saving Throws") — parecida
    /// com o grupo Rogue, mas NÃO igual (ver comentário em
    /// `CoreClassGroup.psionicist`): Rod/Staff/Wand e Petrification/
    /// Polymorph divergem em todas as faixas. O livro também dá "+2 bônus
    /// em saves vs. encantamento/charme" — isso é um AJUSTE situacional
    /// (só contra um tipo de efeito específico, não a jogada inteira),
    /// fora do escopo de uma tabela "por nível" como esta; fica só
    /// documentado aqui, sem campo próprio nesta rodada.
    private static let psionicistRows: [Row] = [
        Row(maxLevel: 4, values: SavingThrows(paralyzationPoisonDeath: 13, rodStaffWand: 15, petrificationPolymorph: 10, breathWeapon: 16, spell: 15)),
        Row(maxLevel: 8, values: SavingThrows(paralyzationPoisonDeath: 12, rodStaffWand: 13, petrificationPolymorph: 9, breathWeapon: 15, spell: 14)),
        Row(maxLevel: 12, values: SavingThrows(paralyzationPoisonDeath: 11, rodStaffWand: 11, petrificationPolymorph: 8, breathWeapon: 13, spell: 12)),
        Row(maxLevel: 16, values: SavingThrows(paralyzationPoisonDeath: 10, rodStaffWand: 9, petrificationPolymorph: 7, breathWeapon: 12, spell: 11)),
        Row(maxLevel: 20, values: SavingThrows(paralyzationPoisonDeath: 9, rodStaffWand: 7, petrificationPolymorph: 6, breathWeapon: 11, spell: 9)),
        Row(maxLevel: .max, values: SavingThrows(paralyzationPoisonDeath: 8, rodStaffWand: 5, petrificationPolymorph: 5, breathWeapon: 9, spell: 7)),
    ]

    private static let byGroup: [CoreClassGroup: [Row]] = [
        .priest: priestRows,
        .rogue: rogueRows,
        .warrior: warriorRows,
        .wizard: wizardRows,
        .psionicist: psionicistRows,
    ]

    func compute(for context: RuleContext) -> RuleValue? {
        let group = CoreClassGroup(context.characterClass)
        guard let rows = Self.byGroup[group] else { return nil }
        guard context.level >= 1 else { return nil }
        guard let row = rows.first(where: { context.level <= $0.maxLevel }) else { return nil }
        return .savingThrows(row.values)
    }

    func sourceRuleID(for context: RuleContext) -> String? {
        context.characterClass == .psionicist ? "cpsih_ch01_special_abilities" : "phb_ch09_the_saving_throw"
    }
}

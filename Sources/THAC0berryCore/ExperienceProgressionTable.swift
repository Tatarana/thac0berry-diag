import Foundation

/// Tabela de XP acumulado por nível, por classe — pedido do usuário
/// (2026-09-22, item 4 do lote): "em XP needed for the next level, podemos
/// preencher automaticamente, dado que sabemos esta tabela por classe,
/// certo?". Copiada literalmente das 4 tabelas de progressão já
/// embutidas no corpus de regras (`Store/EmbeddedRules_Part14.swift`/
/// `Part15.swift`) — não é dado novo nem inventado, é a MESMA fonte que já
/// alimenta a consulta de regras (Table 14: Warrior Experience Levels,
/// Table 20: Wizard Experience Levels, Table 23: Priest Experience Levels,
/// Table 25: Rogue Experience Levels — conferidas linha a linha, 20 níveis
/// cada, batendo `headers.count`/`row.count` antes de copiar, seguindo a
/// regra do projeto de nunca inventar dado de regra). Guardada aqui como
/// constante Swift (em vez de reler o `RuleTable` em texto toda vez) só
/// pra não depender de parsing de string pra um cálculo que roda toda hora
/// que o jogador muda de nível/classe.
enum ExperienceProgressionTable {
    /// XP acumulado necessário pra alcançar cada nível, 1 a 20 (índice 0 =
    /// nível 1 = sempre 0). Fighter/Paladin/Ranger vêm de Table 14 (Paladin
    /// e Ranger dividem a mesma coluna "Paladin/Ranger" no PHB); Mage tem
    /// coluna própria em Table 20 ("Mage/Specialist", que também cobre
    /// Illusionist e os outros especialistas — não há classe Illusionist
    /// separada no app hoje); Cleric/Druid vêm de Table 23, cada um com
    /// coluna própria; Thief/Bard dividem a única coluna de Table 25 ("XP
    /// needed").
    // Mesma causa raiz do `Thac0ByLevelProvider`/`SavingThrowsByLevelProvider`
    // (ver os comentários grandes lá, 2026-10-01): este dicionário tinha 9
    // chaves (`[CharacterClass: [Int]]`, cada uma um array de 20 inteiros)
    // compilando bem antes desta rodada — adicionar a 10ª (`psionicist`)
    // tipo o mesmo estouro de "expression too complex to type-check" do
    // type-checker do Swift Playgrounds. Cada linha virou uma constante
    // `[Int]` própria, type-checada sozinha, ANTES de entrar no
    // dicionário — não é só estética.
    private static let fighterXP: [Int] = [0, 2_000, 4_000, 8_000, 16_000, 32_000, 64_000, 125_000, 250_000, 500_000,
                                            750_000, 1_000_000, 1_250_000, 1_500_000, 1_750_000, 2_000_000, 2_250_000,
                                            2_500_000, 2_750_000, 3_000_000]
    private static let paladinRangerXP: [Int] = [0, 2_250, 4_500, 9_000, 18_000, 36_000, 75_000, 150_000, 300_000, 600_000,
                                                  900_000, 1_200_000, 1_500_000, 1_800_000, 2_100_000, 2_400_000, 2_700_000,
                                                  3_000_000, 3_300_000, 3_600_000]
    private static let mageXP: [Int] = [0, 2_500, 5_000, 10_000, 20_000, 40_000, 60_000, 90_000, 135_000, 250_000,
                                         375_000, 750_000, 1_125_000, 1_500_000, 1_875_000, 2_250_000, 2_625_000,
                                         3_000_000, 3_375_000, 3_750_000]
    private static let clericXP: [Int] = [0, 1_500, 3_000, 6_000, 13_000, 27_500, 55_000, 110_000, 225_000, 450_000,
                                           675_000, 900_000, 1_125_000, 1_350_000, 1_575_000, 1_800_000, 2_025_000,
                                           2_250_000, 2_475_000, 2_700_000]
    // 17th: "500,000*" no PHB — hierophant druids só, ver nota da Table 23.
    private static let druidXP: [Int] = [0, 2_000, 4_000, 7_500, 12_500, 20_000, 35_000, 60_000, 90_000, 125_000,
                                          200_000, 300_000, 750_000, 1_500_000, 3_000_000, 3_500_000, 500_000,
                                          1_000_000, 1_500_000, 2_000_000]
    // Thief/Bard dividem a única coluna de Table 25 ("XP needed"). Ninja
    // (2026-09-30, Complete Ninja's Handbook "Table 1: Rogue Experience
    // Levels") também — conferida linha a linha, bate exatamente com
    // Thief/Bard: o próprio livro reproduz a Table 25 do PHB sem alterar
    // nenhum valor, só confirmando que ninja usa a mesma progressão de
    // todo o grupo Rogue.
    private static let rogueGroupXP: [Int] = [0, 1_250, 2_500, 5_000, 10_000, 20_000, 40_000, 70_000, 110_000, 160_000,
                                               220_000, 440_000, 660_000, 880_000, 1_100_000, 1_320_000, 1_540_000,
                                               1_760_000, 1_980_000, 2_200_000]
    // Psionicist (2026-10-01, Complete Psionics Handbook "Table 2:
    // Psionicist Experience Levels") — conferida linha a linha contra o
    // JSON extraído (`cpsih_ch01_advancement` em `rules.json`), coluna
    // própria (não reaproveita nenhuma das 4 de cima).
    private static let psionicistXP: [Int] = [0, 2_200, 4_400, 8_800, 16_500, 30_000, 55_000, 100_000, 200_000, 400_000,
                                               600_000, 800_000, 1_000_000, 1_200_000, 1_500_000, 1_800_000, 2_100_000,
                                               2_400_000, 2_700_000, 3_000_000]

    private static let thresholds: [CharacterClass: [Int]] = [
        .fighter: fighterXP,
        .paladin: paladinRangerXP,
        .ranger: paladinRangerXP,
        .mage: mageXP,
        .cleric: clericXP,
        .druid: druidXP,
        .thief: rogueGroupXP,
        .bard: rogueGroupXP,
        .ninja: rogueGroupXP,
        .psionicist: psionicistXP,
    ]

    /// XP total necessário pra alcançar `level` (1 a 20) — `nil` fora
    /// desse intervalo (acima de 20 o PHB não lista mais degraus fixos,
    /// vira XP-por-Hit-Die; abaixo de 1 não existe).
    static func xpRequired(for level: Int, class characterClass: CharacterClass) -> Int? {
        guard level >= 1, level <= 20, let table = thresholds[characterClass] else { return nil }
        return table[level - 1]
    }

    /// String pronta pro campo "XP needed for next level" — XP pro PRÓXIMO
    /// nível (`level + 1`), formatada com separador de milhar igual o
    /// resto da tabela do PHB ("2,000"). `nil` quando o próximo nível já
    /// passa de 20 (jogador preenche à mão dali pra frente, igual sempre
    /// foi).
    static func xpNeededForNextLevel(currentLevel: Int, class characterClass: CharacterClass) -> String? {
        guard let xp = xpRequired(for: currentLevel + 1, class: characterClass) else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: xp)) ?? "\(xp)"
    }
}

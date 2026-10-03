import Foundation

/// Tabela 34 do PHB ("Proficiency Slots") — os quatro "arquétipos" de
/// classe que o livro usa pra cobrir as 8 classes do jogo (Fighter/
/// Cleric/Thief/Wizard), com quantos slots iniciais de proficiência de
/// arma/não-arma cada um ganha, de quantos em quantos níveis ganha mais, e
/// a penalidade de não-proficiência (aplicada ao rolamento de ataque ao
/// usar arma sem proficiência). Dados conferidos contra o texto de
/// `phb_ch05_weapon_proficiencies` (Resources/rules.json) — "A warrior...
/// would have a -1 penalty with a related weapon instead of -2" e "A
/// wizard would have a -3 penalty instead of -5" confirmam Fighter=-2 e
/// Wizard=-5; a própria tabela embutida em `phb_ch05_proficiencies`
/// (`RuleEntry.tables`) já trazia os 4 valores certinhos.
///
/// 2026-09-30: criada pra dois usos — (1) `WarriorReferenceView`, a nova
/// 4ª página da ficha pro grupo Warrior (Fighter/Paladin/Ranger), e (2)
/// semear sozinho o campo "Non-proficiency penalty" em `CombatModifiersForm`
/// (`CharacterSheetView.swift`) na primeira vez que a ficha abre — antes
/// disso o campo nascia sempre vazio, mesmo já dando pra saber o valor só
/// pela classe do personagem.
enum ProficiencySlotsTable {
    struct Row {
        let group: String
        let initialWeapon: String
        let levelsWeapon: String
        let penalty: String
        let initialNonweapon: String
        let levelsNonweapon: String
    }

    static let rows: [Row] = [
        Row(group: "Fighter", initialWeapon: "4", levelsWeapon: "3", penalty: "-2",
            initialNonweapon: "3", levelsNonweapon: "3"),
        Row(group: "Cleric", initialWeapon: "2", levelsWeapon: "4", penalty: "-3",
            initialNonweapon: "4", levelsNonweapon: "3"),
        Row(group: "Thief", initialWeapon: "2", levelsWeapon: "4", penalty: "-3",
            initialNonweapon: "3", levelsNonweapon: "4"),
        Row(group: "Wizard", initialWeapon: "1", levelsWeapon: "6", penalty: "-5",
            initialNonweapon: "4", levelsNonweapon: "3"),
        // Psionicist (CPsiH "Table 10: Proficiency Slots") — tabela
        // própria do suplemento, não um dos 4 arquétipos da Tabela 34 do
        // PHB (por isso não reaproveita nenhuma linha acima).
        Row(group: "Psionicist", initialWeapon: "2", levelsWeapon: "5", penalty: "-4",
            initialNonweapon: "3", levelsNonweapon: "3"),
    ]

    /// Remapeia `CharacterClass.proficiencyGroup` ("Warrior"/"Priest"/
    /// "Rogue"/"Wizard") pro rótulo exato que a Tabela 34 usa (ela nomeia os
    /// quatro arquétipos pelas classes "puras" — Fighter/Cleric/Thief/
    /// Wizard — não pelo nome do grupo).
    static func group(for characterClass: CharacterClass) -> String {
        switch characterClass.proficiencyGroup {
        case "Warrior": return "Fighter"
        case "Rogue": return "Thief"
        case "Wizard": return "Wizard"
        case "Psionicist": return "Psionicist"
        default: return "Cleric" // "Priest" (Cleric e Druid)
        }
    }

    static func row(for characterClass: CharacterClass) -> Row? {
        rows.first { $0.group == group(for: characterClass) }
    }

    /// Penalidade de não-proficiência da classe, já como texto com sinal
    /// (ex. "-2") — pronta pra ir direto no campo de texto livre.
    static func nonProficiencyPenalty(for characterClass: CharacterClass) -> String {
        row(for: characterClass)?.penalty ?? "-2"
    }

    /// Total de slots de proficiência de ARMA que o personagem já ganhou
    /// no nível atual (2026-09-30, pedido do usuário: "conseguir aplicar
    /// os slots" em vez de só marcar uma estrela cosmética em Weapon
    /// Specialization). Fórmula tirada literalmente do texto do PHB
    /// (`phb_ch05_proficiencies`): "A new proficiency slot is gained at
    /// every experience level that is evenly divisible by [#Levels].
    /// Rath (a warrior)... gains one weapon proficiency slot at every
    /// level evenly divisible by 3. He gets one new slot at 3rd level,
    /// another at 6th, another at 9th" — ou seja `Inicial + nível ÷
    /// #Levels` (divisão inteira).
    ///
    /// `intelligence`, se informada, soma o bônus opcional do Complete
    /// Fighter's Handbook (`cfh_ch04_weapon_proficiency_slots`,
    /// "Intelligence and Proficiencies"): na criação do personagem, o
    /// jogador pode gastar os idiomas extras de Inteligência alta (Tabela
    /// 4 do PHB) como proficiências extras, "divided as the player
    /// chooses between Weapon Proficiencies and Nonweapon Proficiencies".
    /// Esse bônus é de criação (não escala com nível) e é uma ESCOLHA do
    /// jogador — nem toda a Inteligência precisa ir pra arma, uma parte
    /// pode ter ido pra proficiência não-marcial. O total aqui assume o
    /// MÁXIMO (tudo foi pra arma) — é um teto informativo, não uma trava;
    /// `intelligence: nil` (ou 0) deixa o bônus de fora, só Tabela 34 pura.
    static func totalWeaponSlots(for characterClass: CharacterClass, level: Int, intelligence: Int? = nil) -> Int {
        guard let row = row(for: characterClass) else { return 0 }
        let initial = Int(row.initialWeapon) ?? 0
        let perLevels = Int(row.levelsWeapon) ?? 0
        let fromLevels = perLevels > 0 ? level / perLevels : 0
        let intBonus = intelligence.map(IntelligenceTable.bonusLanguages(forScore:)) ?? 0
        return initial + fromLevels + intBonus
    }
}

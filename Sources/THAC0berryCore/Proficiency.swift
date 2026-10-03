import Foundation

/// Uma proficiência NÃO-de-arma de AD&D 2e — mesma origem/pipeline que
/// `Kit.swift` (extração da wiki, um passe de correção fora do app),
/// cobrindo não só o PHB básico (Tabela 37) mas suplementos inteiros
/// (Complete Handbooks, Player's Option: Skills & Powers, Dark Sun,
/// Al-Qadim, Spelljammer, Council of Wyrms...). 372 entradas ao todo, vêm
/// de `Resources/proficiencies.json` em runtime (ver o comentário em
/// `KitDatabase.swift`/`ProficiencyDatabase.swift` pro histórico do vai-e-
/// volta entre JSON e literal Swift).
struct Proficiency: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let wikiPageTitle: String
    let redirectAliases: [String]
    /// Grupo "principal" pra agrupar a lista de consulta — General/Priest/
    /// Rogue/Warrior/Wizard/Psionicist/"Racial / Special" (bate com qual
    /// dos 7 arquivos de origem a entrada veio).
    let primaryGroup: String
    /// Cenários de campanha em que essa proficiência existe — "Core" é o
    /// PHB básico (sem cenário nenhum, sempre disponível); o resto é uma
    /// lista curta e limpa (Dark Sun, Al-Qadim, Forgotten Realms,
    /// Spelljammer, Council of Wyrms, Planescape — ver
    /// `CampaignSettingCatalog` pro porquê desse eixo existir separado do
    /// `mechanics.groups`, que mistura classe+sourcebook e NÃO é a mesma
    /// coisa). Quase sempre um valor só; raríssimos casos (3 de 372) têm
    /// dois.
    let campaignSettings: [String]
    let mechanics: ProficiencyMechanics
    /// Só preenchido pras ~89 entradas que o Player's Option: Skills &
    /// Powers também descreve com o sistema alternativo de pontos de
    /// personagem — o app não implementa esse sistema (nenhuma outra parte
    /// do código sabe o que é "character point"), então isto fica só como
    /// referência exibida no detalhe, nunca usado em cálculo nenhum.
    let skillsAndPowers: ProficiencySkillsAndPowers?
    let description: ProficiencyDescription

    var isWeapon: Bool { false }
}

struct ProficiencyMechanics: Codable, Hashable {
    /// Grupo(s) de classe que aprendem essa proficiência sem custo extra —
    /// texto livre de propósito (ver comentário de `Proficiency.
    /// campaignSettings`): mistura nome de grupo com sourcebook entre
    /// parênteses às vezes ("Wizard (Rogue - Thief's Handbook)"), não é um
    /// eixo limpo o bastante pra virar enum fechado.
    let groups: [String]
    let slotsRequired: Int
    /// Como veio no arquivo de origem antes de virar `Int` (ex. "2 Slots")
    /// — mantido só de referência, não usado em lugar nenhum da UI.
    let rawSlots: String
    /// "Strength"/"Wisdom"/etc., ou "N/A" quando a proficiência não usa
    /// teste de atributo nenhum (ex. Blind-fighting).
    let relevantAbility: String
    let checkModifier: Int
    let rawModifier: String
    let prerequisites: [String]
}

/// Dados do sistema alternativo de "pontos de personagem" do Player's
/// Option: Skills & Powers — ver o comentário de `Proficiency.
/// skillsAndPowers` pro porquê disto ficar só decorativo.
struct ProficiencySkillsAndPowers: Codable, Hashable {
    let subAbility: String?
    let characterPointCost: Int?
    let baseRating: String
}

struct ProficiencyDescription: Codable, Hashable {
    /// Resumo de uma frase, pra listas/cards.
    let briefSummary: String
    /// Texto corrido já limpo de marcação de wiki, às vezes com uma seção
    /// por sourcebook diferente que descreveu essa proficiência (ex.
    /// "Acting" aparece em três Complete Handbooks distintos, cada um com
    /// seu parágrafo) — pronto pra exibir direto no detalhe.
    let fullText: String
}

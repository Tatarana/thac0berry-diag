import Foundation

/// Um item mágico do corpus completo entregue pelo usuário (TODO.md item 29
/// pra avaliação, item 30 pra implementação em escopo full — "Acho melhor
/// já irmos no escopo full, já que os dados estão bons"). 5.669 itens ao
/// todo, vindos de 8 arquivos por categoria (`armor_and_shields`,
/// `miscellaneous_a_to_m`/`miscellaneous_n_to_z`, `potions_and_oils`,
/// `rings`, `rods_staves_wands`, `scrolls_and_books`, `weapons`) — ver
/// `MagicItemDatabase` pra como os 8 arquivos viram uma base só.
///
/// Ao contrário de Weapon/ArmorPiece/MundaneItem (literais Swift embutidos —
/// ver `EmbeddedWeapons.swift` etc.), este modelo é `Codable` de verdade e
/// lido em runtime do bundle (`Resources/magic_*.json`), mesmo padrão já
/// comprovado por `SpellDatabase`/`Spell` com as 1.795 magias — a escala
/// aqui (5.669 itens, ~9MB mesmo depois de cortar `rawWikitext`) inviabiliza
/// o padrão de literal embutido usado nos Compendiums anteriores (precisaria
/// de umas 230 partições `_PartN.swift`, provavelmente travando o
/// type-checker do Swift Playgrounds). Ver o comentário grande em
/// `KitDatabase.swift`/`SpellDatabase.swift` — a regra antiga de "nunca ler
/// JSON do bundle" era baseada num diagnóstico errado (um
/// `DecodingError.keyNotFound` mascarado, não uma falha real de leitura do
/// bundle), não numa limitação de verdade da toolchain.
///
/// Todos os campos que variam por categoria (`enchantment` só em armas,
/// `power` só em anéis/varinhas/cajados/bastões, `containsSpells` só em
/// pergaminhos/livros, `defenseBonus` majoritariamente em poções/óleos)
/// ficam `Optional` — o corpus tem schema uniforme DENTRO de cada arquivo,
/// mas os 8 arquivos juntos não compartilham um schema único.
/// Nome `CompendiumMagicItem`, não `MagicItem` — esse nome já existe em
/// `SpellSheet.swift` (o item mágico de texto livre com cargas de magia que
/// o JOGADOR preenche na folha de magias, bem mais simples que este). Ver o
/// `struct MagicItem` de lá — sem relação nenhuma com este modelo de dado de
/// REGRA vindo do corpus da wiki; a build acusou "Invalid redeclaration of
/// 'MagicItem'"/"'MagicItem' is ambiguous" até este renomeado corrigir a
/// colisão (mesmo espírito de `Weapon` vs. `WeaponEntry` em
/// `Models/Weapon.swift`/`Models/Character.swift`, só que aqui o nome curto
/// já estava tomado pelo lado da ficha, não do Compendium).
struct CompendiumMagicItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let wikiPageTitle: String?
    let redirectAliases: [String]
    let otherNames: [String]
    let classification: MagicItemClassification
    let economyAndXP: MagicItemEconomy
    let description: MagicItemDescription
    let sources: [MagicItemSource]
    let categories: [String]
    /// Cenário(s) de campanha mencionados na fonte, quando a wiki registra
    /// (Forgotten Realms, Greyhawk, Oriental Adventures/Kara-Tur,
    /// Spelljammer, Mystara/Known World, Al-Qadim, Dragonlance, Ravenloft,
    /// Maztica, Dark Sun — 663 dos 5.669 itens têm pelo menos um). Rótulos
    /// PRÓPRIOS deste corpus, não idênticos aos de `CampaignSettingCatalog`
    /// (que tem "Council of Wyrms"/"Planescape", ausentes aqui, e não tem
    /// "Dragonlance"/"Maztica"/os dois rótulos compostos daqui) — por isso
    /// exibido como tag solta na ficha de detalhe, sem entrar no filtro de
    /// campanha que Grimório/Proficiências já usam.
    let campaignSettings: [String]
    /// Bônus de defesa — majoritariamente em poções/óleos de proteção
    /// (savingThrowBonus, abilityScoreBonus) mas também aparece em alguns
    /// anéis/itens diversos. `nil` na grande maioria (5.235 dos 5.669).
    let defenseBonus: MagicItemDefenseBonus?
    /// Só preenchido em `weapons.json` — bônus de ataque/dano de uma arma
    /// mágica (ex. "sword +2" → attackBonus/damageBonus = 2).
    let enchantment: MagicItemEnchantment?
    /// Só preenchido em `rings.json`/`rods_staves_wands.json` — o poder
    /// concedido pelo item, às vezes ligado a uma magia específica
    /// (`spell`, presente em 23 dos 546 itens com `power`).
    let power: MagicItemPower?
    /// Só preenchido em `scrolls_and_books.json` — as magias que o
    /// pergaminho/livro contém.
    let containsSpells: [MagicItemSpellRef]

    enum CodingKeys: String, CodingKey {
        case id, name, wikiPageTitle, redirectAliases, otherNames, classification
        case economyAndXP, description, sources, categories, campaignSettings
        case defenseBonus, enchantment, power, containsSpells
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        wikiPageTitle = try container.decodeIfPresent(String.self, forKey: .wikiPageTitle)
        redirectAliases = try container.decodeIfPresent([String].self, forKey: .redirectAliases) ?? []
        otherNames = try container.decodeIfPresent([String].self, forKey: .otherNames) ?? []
        classification = try container.decode(MagicItemClassification.self, forKey: .classification)
        economyAndXP = try container.decode(MagicItemEconomy.self, forKey: .economyAndXP)
        description = try container.decode(MagicItemDescription.self, forKey: .description)
        sources = try container.decodeIfPresent([MagicItemSource].self, forKey: .sources) ?? []
        categories = try container.decodeIfPresent([String].self, forKey: .categories) ?? []
        campaignSettings = try container.decodeIfPresent([String].self, forKey: .campaignSettings) ?? []
        defenseBonus = try container.decodeIfPresent(MagicItemDefenseBonus.self, forKey: .defenseBonus)
        enchantment = try container.decodeIfPresent(MagicItemEnchantment.self, forKey: .enchantment)
        power = try container.decodeIfPresent(MagicItemPower.self, forKey: .power)
        containsSpells = try container.decodeIfPresent([MagicItemSpellRef].self, forKey: .containsSpells) ?? []
    }

    /// Nome normalizado pra busca aproximada, mesmo padrão de `Spell.normalizedName`.
    var normalizedName: String { Fuzzy.normalize(name) }
}

struct MagicItemClassification: Codable, Hashable {
    /// Mapeia 1:1 pro arquivo de origem — "Armor/Shield", "Miscellaneous"
    /// (A-M e N-Z compartilham o MESMO valor; o split é só artefato de
    /// extração, ver `MagicItemDatabase.categoryOrder`), "Potion/Oil", "Ring",
    /// "Rod/Staff/Wand", "Scroll/Book", "Weapon" — 7 valores distintos,
    /// usados como agrupamento do Compendium.
    let broadCategory: String
    /// Subtipo mais específico, ex. "Magic Sword", "Cursed Ring" — sempre
    /// presente (nenhum `null` no corpus inteiro).
    let specificType: String
}

struct MagicItemEconomy: Codable, Hashable {
    let xpValue: Int?
    let goldValue: Int?
    /// Texto original da wiki, ex. "3,500 xp" — fallback de exibição
    /// quando `xpValue` é `nil` (799 dos 5.669 itens), mesmo padrão de
    /// "—" já usado em Weapon/Armor/Equipment quando o valor estruturado
    /// falta.
    let rawXP: String?
    let rawValue: String?
}

struct MagicItemDescription: Codable, Hashable {
    let briefSummary: String
    let fullText: String
}

struct MagicItemSource: Codable, Hashable {
    let book: String?
    let page: String?
}

/// Todos os campos aqui vêm sempre juntos (mesmo key-set nos 434 itens que
/// têm `defenseBonus`, confirmado por auditoria) — cada um `nil`/vazio
/// quando não se aplica àquele item específico.
struct MagicItemDefenseBonus: Codable, Hashable {
    let acBonus: Int?
    let savingThrowBonus: Int?
    let magicResistance: Int?
    /// Chaves são o nome do atributo em inglês ("Charisma", "Strength"...),
    /// mesmo padrão de `KitRequirements.abilities` — quase sempre só uma
    /// chave presente (13 dos 14 casos no corpus), mas o dicionário
    /// aceitaria mais de um bônus simultâneo se a fonte tiver.
    let abilityScoreBonus: [String: Int]?
    let hitPointBonus: Int?
    let attackBonus: Int?
    /// Tipos de dano/energia resistidos, ex. "fire", "poison" — texto
    /// livre como a wiki registra, sem enum fechado (mesmo espírito de
    /// `Weapon.type` aceitar combinações como "P/S").
    let resistances: [String]
    let regenerates: Bool
}

/// Só em `weapons.json` — bônus de ataque/dano de arma mágica.
struct MagicItemEnchantment: Codable, Hashable {
    let attackBonus: Int?
    let damageBonus: Int?
}

/// Só em `rings.json`/`rods_staves_wands.json`.
struct MagicItemPower: Codable, Hashable {
    let name: String?
    let chargeBased: Bool?
    let maxCharges: Int?
    /// Presente em 23 dos 546 itens com `power` — quando o poder do item
    /// é replicar uma magia específica da base de sacerdote/mago.
    let spell: MagicItemSpellRef?
}

/// Referência a uma magia específica — usado tanto por `power.spell`
/// (anéis/varinhas) quanto por `containsSpells` (pergaminhos/livros); as
/// duas fontes têm exatamente o mesmo key-set (`id`, `name`, `class`),
/// confirmado por auditoria, daí a struct compartilhada.
struct MagicItemSpellRef: Codable, Hashable {
    let id: String
    let name: String
    /// "Priest" ou "Wizard" — qual lista de magias o item usa.
    let spellClass: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case spellClass = "class"
    }
}

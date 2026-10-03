import Foundation

/// Um "kit" de sacerdote — a especialização/origem de personagem descrita
/// em livros como *The Complete Priest's Handbook* (kits genéricos, tipo
/// Fighting-Monk ou Warrior Priest) e nos guias regionais de Forgotten
/// Realms (sacerdote especializado de uma divindade específica, tipo
/// "Selûne - Silver Lady"). Ambos entram no mesmo arquivo/array porque a
/// wiki de origem já os trata como a mesma categoria ("Character Kit") —
/// só o subconjunto de campos preenchidos muda: os quatro campos de
/// divindade (`deity`/`pantheon`/`setting`/`titleInChurch`) só existem nos
/// kits de sacerdote especializado, `nil` no resto (ver `isSpecialtyPriest`).
///
/// Os 91 kits em si (97 originais menos os 6 "Create Your Own" — cartas em
/// branco sem regra nenhuma, removidos por não servirem pra nada num app de
/// fichas) vêm de `Resources/kits.json` (ver o comentário grande em
/// `KitDatabase.swift` pro histórico completo: três tentativas diferentes
/// de ler isso de JSON já tinham falhado — 13 dos 97 kits não têm a chave
/// `mechanics.armor.allowedTypes`, o que derrubava o decode do array
/// inteiro — mas isso já foi corrigido em `KitArmorRules.init(from:)`
/// abaixo, então voltar a ler JSON em runtime é seguro de novo).
///
/// 2026-09-29/2026-09-30: o mesmo array ganhou mais 187 kits de outros
/// três grupos — 41 de Mago (`Scripts/convert_wizard_kits.py`), 114 de
/// Warrior (Fighter/Paladin/Ranger + Barbarian, dobrado dentro de
/// Fighter) e 73 de Rogue (Thief/Bard/Ninja), os dois últimos via
/// `Scripts/convert_warrior_rogue_kits.py` — pelo mesmo motivo: a wiki de
/// origem já trata kit de qualquer classe como "Character Kit", então um
/// `classEligibility.classGroup`/`allowedClasses` por kit (já genérico,
/// sem nada hardcoded pra sacerdote) é o bastante pra `KitDatabase`/
/// `KitField`/`KitPickerSheet` filtrarem certo, sem precisar de um
/// array/arquivo por classe. `deity`/`pantheon`/`setting`/`titleInChurch`
/// continuam exclusivos do sacerdote especializado — `nil` em todo o
/// resto, Warrior/Rogue/Mago incluídos.
struct Kit: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let wikiPageTitle: String
    let redirectAliases: [String]
    let classEligibility: KitClassEligibility
    let sourceBook: String
    let features: KitFeatures
    let description: KitDescription
    let categories: [String]
    let mechanics: KitMechanics

    // Só preenchidos para kit de sacerdote especializado (um por divindade).
    let deity: String?
    let pantheon: String?
    let setting: String?
    let titleInChurch: String?

    var isSpecialtyPriest: Bool { deity != nil }
}

struct KitClassEligibility: Codable, Hashable {
    let classGroup: String
    /// "Cleric", "Druid", "Any Priest" ou "Specialty Priest" — mais
    /// granular que `allowedClasses` (que já veio pronto pra filtrar) mas
    /// útil pra exibir de forma legível ("kit de Druid", etc.).
    let subclass: String
    let allowedClasses: [String]
}

struct KitDescription: Codable, Hashable {
    /// Resumo de um parágrafo, pra listas/cards.
    let briefSummary: String
    /// Texto corrido — o comentário original dizia "já limpo de marcação
    /// de wiki", mas isso nunca foi verdade pra 56 dos 91 kits (ver
    /// `displaySections` abaixo). Mantido como veio (não regerado nesta
    /// sessão) — a limpeza acontece só na hora de EXIBIR, via
    /// `displaySections`.
    let fullText: String
    /// Wikitext original, mantido só como referência/depuração — não é
    /// pensado pra aparecer na UI.
    let rawWikitext: String

    /// Um bloco da descrição já limpo pra exibir — `title` vazio quando o
    /// texto não tinha nenhum "## Heading" pra nomear a seção.
    struct Section: Hashable, Identifiable {
        var id: String { title }
        let title: String
        let body: String
    }

    /// Item 6 do pedido do usuário (2026-09-24): "Descrições de Kits com
    /// tabelas wikitext quebradas (ex.: Ilmater - Alleviator)". Bug real,
    /// confirmado em 56 dos 91 kits (todos os de sacerdote especializado,
    /// um por divindade — os outros 35, do estilo Complete Handbook, já
    /// eram texto limpo): `fullText` começa com o wikitext CRU da
    /// tabela-resumo da wiki (`{| class="article-table" ... |}\n! colspan
    /// ...`), porque o pipeline de conversão (fora do app, não regerado
    /// aqui) só tratava negrito/links, nunca tabela.
    ///
    /// A boa notícia: TODO dado daquela tabela (Racial/Ability
    /// Requirements, Prime Requisite, Hit Die, Weapon/Nonweapon Slots,
    /// Bonus/Recommended Proficiencies etc.) já aparece em campos
    /// ESTRUTURADOS de verdade em outro lugar da própria `KitDetailSheet`
    /// (`kit.mechanics.*` e `kit.features.*`) — então a tabela crua é só
    /// DESCARTADA aqui, sem perder informação nenhuma, só o wikitext
    /// quebrado que duplicava esses campos. O que sobra (os parágrafos de
    /// prosa — Overview/Description/Role-Playing/Special Abilities/
    /// Special Disadvantages nos 56 com tabela; o texto corrido de
    /// handbook nos outros 35) vira uma lista de seções por
    /// `## Heading`, sem símbolo de wiki nenhum sobrando — `**negrito**`
    /// também é removido (a UI não teria como renderizar isso como
    /// negrito de qualquer forma).
    var displaySections: [Section] {
        var text = fullText
        if let tableStart = text.range(of: "{|"), let tableEnd = text.range(of: "|}") {
            text.removeSubrange(tableStart.lowerBound..<tableEnd.upperBound)
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        var sections: [Section] = []
        var currentTitle = ""
        var currentBody: [Substring] = []

        func flush() {
            let body = currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !currentTitle.isEmpty || !body.isEmpty else { return }
            sections.append(Section(title: currentTitle, body: KitDescription.stripInlineMarkup(body)))
            currentBody = []
        }

        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("## ") {
                flush()
                currentTitle = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
            } else {
                currentBody.append(line)
            }
        }
        flush()

        // Nenhum "## " no texto inteiro (não deveria acontecer nos 91
        // kits atuais, mas não custa ter uma saída segura pra dado
        // futuro nesse formato): devolve o texto inteiro como uma seção
        // sem título, em vez de sumir com a descrição.
        return sections.isEmpty ? [Section(title: "", body: KitDescription.stripInlineMarkup(text))] : sections
    }

    private static func stripInlineMarkup(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
    }
}

/// Texto livre por seção, como aparece no livro — cada campo é `nil`
/// quando o kit de origem não descreve aquela seção. `mechanics` cobre o
/// mesmo terreno de forma estruturada quando dá pra extrair um valor
/// (dados, listas); isto aqui é a prosa completa, pra exibir sem perder
/// nuance que a extração estruturada não capturou.
struct KitFeatures: Codable, Hashable {
    let role: String?
    let requirements: String?
    let specialBenefits: String?
    let specialHindrances: String?
    let wealthOptions: String?
    let weaponProficiencies: String?
    let nonweaponProficiencies: String?
    let equipment: String?
}

struct KitMechanics: Codable, Hashable {
    let requirements: KitRequirements
    let weapons: KitWeaponRules
    let proficiencies: KitProficiencyRules
    let armor: KitArmorRules
    let turnUndead: KitTurnUndeadRules
    /// Formato "dados" livre, ex. "3d6x10 gp" — mantido como texto porque
    /// já vem com o multiplicador embutido (ex.: "3d6x10") em vez de dado +
    /// fator separados, sem padrão fixo o bastante pra valer estruturar.
    let startingCash: String?
    /// Só preenchido pros 18 dos 41 kits de mago (2026-09-29,
    /// `Scripts/convert_wizard_kits.py`) que têm progressão de slot de
    /// arma diferente da tabela padrão da classe — `nil` pro resto (kit
    /// de sacerdote nunca tem isso, nem a maioria dos de mago). Campo
    /// `Optional` de verdade (não um array com valor padrão, que foi o
    /// bug do `Spell.schools` — ver `Store/SpellDatabase.swift`): o
    /// `Codable` sintetizado já trata `Optional` como `decodeIfPresent`
    /// sozinho, então uma chave ausente no JSON não quebra o decode.
    var weaponSlots: KitWeaponSlotRules? = nil
}

struct KitWeaponSlotRules: Codable, Hashable {
    let initial: Int?
    let additional: Int?
    /// Texto livre porque já vem com o sinal embutido no arquivo de
    /// origem (ex. "-5"), não um número puro.
    let nonproficiencyPenalty: String?

    /// `false` pros 23 dos 41 kits de mago cujo `weaponSlots` de origem
    /// tinha os três campos `null` (sem regra própria) — `convert_wizard_kits.py`
    /// já filtra a maioria desses na conversão, mas confere nulo de novo
    /// aqui por segurança, já que exibir um campo "Weapon Slots" vazio na
    /// UI seria pior que não mostrar nada.
    var hasContent: Bool { initial != nil || additional != nil || nonproficiencyPenalty != nil }
}

struct KitRequirements: Codable, Hashable {
    /// Chaves são o nome do atributo em inglês, como no livro
    /// ("Strength", "Wisdom", ...) — dicionário em vez de seis campos
    /// opcionais porque só os atributos exigidos aparecem.
    let abilities: [String: Int]
    let alignments: [String]
    let races: String?
}

struct KitWeaponRules: Codable, Hashable {
    let required: [String]
    let recommended: [String]
    let forbidden: [String]
    let notes: String?
}

struct KitProficiencyRules: Codable, Hashable {
    let bonus: [String]
    let recommended: [String]
    let notes: String?
}

struct KitArmorRules: Codable, Hashable {
    let allowedTypes: KitArmorRestriction
    let shieldsAllowed: KitArmorRestriction
    let metalAllowed: Bool
    /// Só preenchido quando o kit limita a CA alcançável (ex. monges
    /// desarmados) — texto livre porque o valor já vem como categoria
    /// ("leather_or_padded"), não um número, no arquivo de origem.
    let maxArmorClass: String?
    let notes: String

    /// Escrever `init(from:)` à mão (abaixo) tira o memberwise init
    /// sintetizado automaticamente — recriado aqui porque
    /// `EmbeddedKits.swift` constrói `KitArmorRules` direto por literal,
    /// sem passar por decode nenhum.
    init(allowedTypes: KitArmorRestriction, shieldsAllowed: KitArmorRestriction,
         metalAllowed: Bool, maxArmorClass: String?, notes: String) {
        self.allowedTypes = allowedTypes
        self.shieldsAllowed = shieldsAllowed
        self.metalAllowed = metalAllowed
        self.maxArmorClass = maxArmorClass
        self.notes = notes
    }

    /// `init(from:)` escrito à mão porque `allowedTypes` some por completo
    /// (não é `null` — a CHAVE não existe) em 13 dos 97 kits de origem —
    /// achado só depois de um decode inteiro falhando silenciosamente com
    /// "The data couldn't be read because it is missing" (é a mensagem
    /// genérica que o Swift dá pra `DecodingError.keyNotFound`, fácil de
    /// confundir com bundle/arquivo sumido — ver `KitDatabase`/`TODO.md`
    /// item 9 pro caso real que isso causou). Chave ausente vira `.asClass`
    /// — mesma leitura de "sem restrição própria do kit" que a string
    /// sentinela `"as_class"` já significa.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        allowedTypes = try container.decodeIfPresent(KitArmorRestriction.self, forKey: .allowedTypes) ?? .asClass
        shieldsAllowed = try container.decodeIfPresent(KitArmorRestriction.self, forKey: .shieldsAllowed) ?? .asClass
        metalAllowed = try container.decode(Bool.self, forKey: .metalAllowed)
        maxArmorClass = try container.decodeIfPresent(String.self, forKey: .maxArmorClass)
        notes = try container.decode(String.self, forKey: .notes)
    }
}

/// `allowedTypes`/`shieldsAllowed` vêm do arquivo de origem de duas formas:
/// a string sentinela `"as_class"` (sem restrição além da já imposta pela
/// classe base) ou uma lista concreta de tipos permitidos/proibidos.
/// Decodifica tentando lista primeiro, e trata qualquer string como
/// "sem restrição própria do kit" — não só `"as_class"` — pra não quebrar
/// o carregamento se uma regeneração futura do arquivo usar outra
/// sentinela.
enum KitArmorRestriction: Codable, Hashable {
    case asClass
    case specific([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let types = try? container.decode([String].self) {
            self = .specific(types)
        } else {
            _ = try container.decode(String.self)
            self = .asClass
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .asClass:
            try container.encode("as_class")
        case .specific(let types):
            try container.encode(types)
        }
    }

    var specificTypes: [String]? {
        if case .specific(let types) = self { return types }
        return nil
    }
}

struct KitTurnUndeadRules: Codable, Hashable {
    let capable: Bool
    /// "allowed" / "modified" / "forbidden" no arquivo de origem — mantido
    /// como texto (em vez de enum fechado) porque este arquivo já passou
    /// por três rodadas de correção de dados; um valor novo/inesperado aqui
    /// não pode derrubar o carregamento do kit inteiro.
    let mode: String
    let notes: String
}

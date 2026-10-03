import Foundation

/// Quem conjura a magia. Em AD&D 2e as listas de mago e sacerdote são
/// separadas, com mecânicas de memorização iguais mas fontes diferentes.
enum CasterType: String, Codable, CaseIterable, Identifiable {
    case arcane   // mago / ilusionista
    case divine   // clérigo / druida

    var id: String { rawValue }

    var label: String {
        switch self {
        case .arcane: return "Wizard"
        case .divine: return "Priest"
        }
    }
}

/// Dados mecânicos de uma magia, como aparecem no cabeçalho da descrição
/// no livro. O campo `summary` é um resumo próprio de uma linha, só para
/// lembrar o que a magia faz na hora do jogo.
struct Spell: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let level: Int
    let caster: CasterType
    /// Escola de magia, como no livro ("Evocation", "Enchantment/Charm").
    let school: String
    /// Tempo de conjuração — em 2e é isso que entra no cálculo de iniciativa.
    let castingTime: String
    let range: String
    let components: String
    let duration: String
    let areaOfEffect: String
    let savingThrow: String
    /// Dano ou cura por extenso, como no livro ("1d6 per level (max 10d6)").
    /// Fica intacto para a janela de descrição — quem calcula o valor do
    /// personagem é `damageDice`.
    let damage: String?
    /// Resumo de uma linha, para lembrar rápido o que a magia faz.
    let summary: String
    /// Versão estruturada de `damage`, quando dá para reduzir a um dado +
    /// bônus. É o que a tabela da folha de magias usa para mostrar o valor
    /// já calculado para o nível do conjurador, sem a legenda "Cura"/"Dmg".
    /// `nil` quando a magia não tem dano numérico (ou o texto é livre
    /// demais para modelar, como "quase todos os PV" de Heal).
    let damageDice: SpellDamage?
    /// Esferas de acesso (só faz sentido para sacerdote — ver TODO.md
    /// item 4). Vazio para magias de mago ou entradas de exemplo antigas.
    var spheres: [String] = []
    /// Escola(s) de magia em lista (só faz sentido para mago — a mesma
    /// informação já existe por extenso em `school`, mas separada aqui
    /// pro filtro do Grimório do Mago funcionar igual ao filtro de esfera
    /// do Grimório do Clérigo — ver `Scripts/convert_wizard_spells.py` e
    /// `SpellbookView`, 2026-09-29). Vazio para magias de sacerdote ou
    /// entradas de exemplo antigas.
    var schools: [String] = []
    /// Texto completo da descrição, quando disponível — `summary` continua
    /// sendo o resumo curto usado no resto do app; este campo é só para a
    /// janela de detalhe (`SpellDetailSheet`).
    var fullDescription: String? = nil
    /// Cenário/ambientação pra qual a magia é indicada ou possível
    /// ("Generic", "Forgotten Realms", "Dark Sun"...). `nil` para entradas
    /// de exemplo antigas que não vêm da base real.
    var setting: String? = nil

    /// Nome normalizado usado pelo casamento aproximado da escrita à mão.
    var normalizedName: String { Fuzzy.normalize(name) }

    /// Inicializador comum (o que os 62 literais Swift de
    /// `EmbeddedSampleSpells` usam) — precisa ficar explícito porque, assim
    /// que a struct ganha QUALQUER inicializador próprio (o `init(from:)`
    /// logo abaixo), o Swift para de gerar o memberwise init automático, e
    /// esses 62 literais quebrariam.
    init(id: String, name: String, level: Int, caster: CasterType, school: String,
         castingTime: String, range: String, components: String, duration: String,
         areaOfEffect: String, savingThrow: String, damage: String?, summary: String,
         damageDice: SpellDamage?, spheres: [String] = [], schools: [String] = [],
         fullDescription: String? = nil, setting: String? = nil) {
        self.id = id
        self.name = name
        self.level = level
        self.caster = caster
        self.school = school
        self.castingTime = castingTime
        self.range = range
        self.components = components
        self.duration = duration
        self.areaOfEffect = areaOfEffect
        self.savingThrow = savingThrow
        self.damage = damage
        self.summary = summary
        self.damageDice = damageDice
        self.spheres = spheres
        self.schools = schools
        self.fullDescription = fullDescription
        self.setting = setting
    }

    // MARK: - Decodable

    /// ACHADO 2026-09-29 — a causa de verdade do bug "priest_*.json não lê"
    /// que consumiu a v1.82 até a v1.85 (ver `Store/SpellDatabase.swift`
    /// pra timeline completa das tentativas erradas): nunca foi arquivo
    /// sumindo do bundle, nem timing, nem pipeline de recursos, nem code
    /// signing. Era só isto aqui — um decode de JSON falhando, com uma
    /// mensagem de erro do PRÓPRIO Swift enganosa o bastante pra confundir
    /// todo mundo (inclusive quem escreveu esse código): quando o
    /// Grimório do Mago foi criado, o campo `schools` ganhou um valor
    /// padrão em Swift (`= []`), mas isso NÃO faz o `Codable` sintetizado
    /// automaticamente aceitar a chave ausente no JSON — o decoder
    /// sintetizado continua exigindo a chave `schools` em TODO arquivo,
    /// mesmo tendo um default em Swift. Os `wizard_*.json` (gerados por um
    /// script escrito já sabendo do campo `schools`) sempre tiveram essa
    /// chave. Os `priest_*.json` (gerados por `convert_spells.py`, que é
    /// de antes do campo existir) NUNCA tiveram — cada um deles falhava a
    /// decodificação com `DecodingError.keyNotFound` pra chave `schools`.
    /// E o pulo do gato: quando esse erro de decodificação vira `NSError`
    /// (por `error.localizedDescription`), o Swift/Foundation devolve a
    /// frase — sem relação nenhuma com o que aconteceu de verdade —
    /// "The data couldn't be read because it is missing.", EXATAMENTE a
    /// mesma frase de um arquivo genuinamente ausente do disco. Foi isso
    /// que fez a investigação inteira (timing de bundle, `.process` vs
    /// `.copy`, code signing, cache do Playgrounds) mirar no lugar errado
    /// por 4 rodadas — o dado real (contagem de bytes lidos batendo
    /// exatamente com o tamanho do arquivo, capturada pelo diagnóstico da
    /// v1.83) foi o que finalmente expôs que a leitura sempre funcionou; só
    /// a decodificação que falhava. Este `init(from:)` próprio troca
    /// `decode` por `decodeIfPresent(...) ?? valorPadrão` pros campos
    /// aditivos (`spheres`, `schools`, `fullDescription`, `setting`, e por
    /// tabela `damage`/`damageDice`, que já eram opcionais) — agora uma
    /// chave nova pode faltar em arquivos JSON antigos sem quebrar nada,
    /// do jeito que já devia ter sido desde o início.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        level = try container.decode(Int.self, forKey: .level)
        caster = try container.decode(CasterType.self, forKey: .caster)
        school = try container.decode(String.self, forKey: .school)
        castingTime = try container.decode(String.self, forKey: .castingTime)
        range = try container.decode(String.self, forKey: .range)
        components = try container.decode(String.self, forKey: .components)
        duration = try container.decode(String.self, forKey: .duration)
        areaOfEffect = try container.decode(String.self, forKey: .areaOfEffect)
        savingThrow = try container.decode(String.self, forKey: .savingThrow)
        damage = try container.decodeIfPresent(String.self, forKey: .damage)
        summary = try container.decode(String.self, forKey: .summary)
        damageDice = try container.decodeIfPresent(SpellDamage.self, forKey: .damageDice)
        spheres = try container.decodeIfPresent([String].self, forKey: .spheres) ?? []
        schools = try container.decodeIfPresent([String].self, forKey: .schools) ?? []
        fullDescription = try container.decodeIfPresent(String.self, forKey: .fullDescription)
        setting = try container.decodeIfPresent(String.self, forKey: .setting)
    }
}

/// Um dano/cura reduzido a dado + bônus, com ou sem escala por nível do
/// conjurador — o que permite a folha mostrar "10d6" em vez de "1d6 per
/// level (max 10d6)" para quem já sabe seu próprio nível.
struct SpellDamage: Codable, Hashable {
    /// Número de dados na rolagem — ou, se `scalesWithLevel`, quantos dados
    /// por nível do conjurador.
    var dice: Int
    var sides: Int
    /// Bônus fixo somado uma vez (não escala com nível).
    var bonus: Int = 0
    var scalesWithLevel: Bool = false
    /// Teto de dados quando escala por nível (ex.: bola de fogo para em
    /// 10d6 mesmo com um conjurador de nível mais alto).
    var maxDice: Int? = nil
    var isHealing: Bool = false
    /// Bônus que cresce com o nível do conjurador (diferente de `dice`
    /// escalando: aqui o DADO fica fixo, só o bônus somado sobe) — ex.:
    /// "1d3 points of damage plus 2 points per level" (Frost Fingers).
    /// Some com `bonus` (que continua sendo o valor fixo, se houver os
    /// dois ao mesmo tempo).
    var bonusPerLevel: Int = 0
    /// Teto pro bônus TOTAL já escalado (`bonusPerLevel * nível`), quando
    /// o texto original menciona um máximo explícito. `nil` = sem teto.
    var maxBonus: Int? = nil

    /// O valor já calculado para o nível do conjurador, pronto para a
    /// tabela: "10d6", "2d8 + 1", "1d4", "1d3 + 10".
    func text(casterLevel: Int) -> String {
        let count: Int
        if scalesWithLevel {
            let raw = dice * max(casterLevel, 1)
            count = min(raw, maxDice ?? raw)
        } else {
            count = dice
        }
        var totalBonus = bonus
        if bonusPerLevel > 0 {
            let scaled = bonusPerLevel * max(casterLevel, 1)
            totalBonus += min(scaled, maxBonus ?? scaled)
        }
        var text = sides > 0 ? "\(count)d\(sides)" : "\(count)"
        if totalBonus > 0 { text += " + \(totalBonus)" }
        if totalBonus < 0 { text += " - \(abs(totalBonus))" }
        return text
    }
}

import Foundation

// MARK: - Atributos

struct AbilityScores: Codable, Hashable {
    var strength: Int = 10
    /// Força excepcional (01–00) — só guerreiros com Força 18.
    var exceptionalStrength: Int? = nil
    var dexterity: Int = 10
    var constitution: Int = 10
    var intelligence: Int = 10
    var wisdom: Int = 10
    var charisma: Int = 10

    var strengthDisplay: String {
        if strength == 18, let pct = exceptionalStrength, pct > 0 {
            return pct >= 100 ? "18/00" : String(format: "18/%02d", pct)
        }
        return "\(strength)"
    }
}

// MARK: - Esferas de acesso

/// Nível de acesso do personagem a uma esfera de magia de clérigo —
/// acesso MAIOR conjura até o círculo máximo que o nível permitir, acesso
/// MENOR só até o 3º círculo daquela esfera (regra do PHB, capítulo 3).
/// String bruta em vez de referência a `Spell.spheres` de propósito: são
/// dados de fontes diferentes (a lista canônica de esferas é fixa; o
/// texto de `spheres` em cada magia vem direto do corpus JSON), casam
/// pelo NOME, não por identidade de tipo.
enum SphereAccessLevel: String, Codable, Hashable, CaseIterable {
    case major
    case minor

    var label: String {
        switch self {
        case .major: return "Major"
        case .minor: return "Minor"
        }
    }
}

/// Sinal de esfera-de-acesso pra um candidato de magia na Folha de Magias
/// (ver `PlayerCharacter.sphereSignal(for:)`) — SEMPRE só um aviso, nunca
/// um filtro: a magia continua na lista, escolhível, do mesmo jeito.
enum SphereSignal: Hashable {
    /// Nenhuma das esferas da magia está marcada (nem maior, nem menor).
    case outsideSpheres
    /// Pelo menos uma esfera da magia está marcada, mas só como MENOR —
    /// regra do PHB (capítulo 3): acesso menor trava no 3º círculo,
    /// então uma magia de 4º círculo em diante nessa esfera fica fora do
    /// alcance mecânico do personagem, mesmo "tendo" a esfera.
    case minorCircleCap

    var label: String {
        switch self {
        case .outsideSpheres: return "outside spheres"
        case .minorCircleCap: return "minor — caps at 3rd circle"
        }
    }
}

// MARK: - Jogadas de proteção

/// As cinco categorias de saving throw de AD&D 2e. São valores "role igual
/// ou acima" — quanto MENOR, melhor. O app guarda o alvo "Start" direto da
/// tabela da classe/nível (o `ConsequenceEngine` escreve aqui sozinho numa
/// subida de nível) e um "Mod" numérico por jogada que o jogador ajusta na
/// mão (item de anel/poção temporário, penalidade de armadilha, bônus de
/// magia — qualquer coisa que a tabela por si só não cobre). "Total" (Start
/// − Mod, já que um bônus positivo FACILITA a jogada — reduz o número que
/// precisa tirar no d20, regra do PHB cap. 9) é só exibido, nunca guardado:
/// sempre recalculado a partir dos outros dois, nunca pode ficar
/// dessincronizado.
struct SavingThrows: Codable, Hashable {
    var paralyzationPoisonDeath: Int = 16
    var rodStaffWand: Int = 18
    var petrificationPolymorph: Int = 17
    var breathWeapon: Int = 20
    var spell: Int = 19

    /// Resistência mágica — linha extra do PDF oficial, texto livre (ex.:
    /// "10%"). Optional pelo mesmo motivo de sempre: fichas antigas não
    /// têm essa chave no JSON salvo.
    var spellResistance: String? = nil

    /// Coluna "Mod" do PDF — ajuste numérico por jogada (positivo = bônus,
    /// facilita; negativo = penalidade), guardado por `SaveEntry.id`
    /// porque cada jogada não tinha campo próprio antes. Optional pelo
    /// mesmo motivo de sempre: fichas antigas não têm essa chave no JSON
    /// salvo.
    var modifiers: [String: Int]? = nil

    func modifier(for id: String) -> Int { modifiers?[id] ?? 0 }

    mutating func setModifier(_ value: Int, for id: String) {
        var dict = modifiers ?? [:]
        if value == 0 {
            dict.removeValue(forKey: id)
        } else {
            dict[id] = value
        }
        modifiers = dict.isEmpty ? nil : dict
    }

    /// "Total" da coluna do PDF — Start menos o Mod aplicado (ver o
    /// comentário da struct pro porquê de ser subtração). Nunca guardado;
    /// sempre recalculado na hora de exibir.
    func total(for entry: SaveEntry) -> Int {
        self[keyPath: entry.keyPath] - modifier(for: entry.id)
    }

    struct SaveEntry: Identifiable {
        let id: String
        let label: String
        let keyPath: WritableKeyPath<SavingThrows, Int>
    }

    static let labels: [SaveEntry] = [
        SaveEntry(id: "ppd", label: "Paralyzation / Poison / Death",
                  keyPath: \.paralyzationPoisonDeath),
        SaveEntry(id: "rsw", label: "Rod / Staff / Wand",
                  keyPath: \.rodStaffWand),
        SaveEntry(id: "pp", label: "Petrification / Polymorph",
                  keyPath: \.petrificationPolymorph),
        SaveEntry(id: "bw", label: "Breath Weapon",
                  keyPath: \.breathWeapon),
        SaveEntry(id: "sp", label: "Spell",
                  keyPath: \.spell)
    ]
}

// MARK: - Slots de magia

/// Um slot individual. Em 2e o mago memoriza uma magia específica em cada
/// slot; conjurar gasta aquele slot, e só o descanso devolve.
struct SpellSlot: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var level: Int
    var caster: CasterType
    /// Magia preparada neste slot (id da base de magias), se houver.
    var preparedSpellID: String? = nil
    /// Nome livre, para magias que não estão na base embutida.
    var preparedSpellName: String? = nil
    var isSpent: Bool = false
    /// Posição do slot dentro do próprio círculo — só existe pra dar ao
    /// `sortSlots()` um critério de desempate que NÃO seja o `id`. Optional
    /// pelo motivo de sempre: folha salva antes desta versão não tem essa
    /// chave; ausência vira `0` pra todo mundo, o que é inofensivo (ver
    /// comentário em `sortSlots`). Corrige o bug relatado pelo usuário
    /// (2026-09-28): "ao criar uma nova priest spell sheet, as magias
    /// aparecem em ordem totalmente aleatória" — `SpellSheet.nextDay()`
    /// dá um `id` NOVO e aleatório pra cada slot de propósito (dois dias
    /// não podem ter slots com a mesma identidade), mas o desempate do
    /// sort usava justamente esse `id`, então a ordem visual do círculo
    /// virava loteria a cada dia novo. `orderKey` nunca é regenerado por
    /// `nextDay()` — só o `id` muda — então a ordem sobrevive à criação da
    /// folha nova.
    var orderKey: Int = 0

    var isEmpty: Bool { preparedSpellID == nil && preparedSpellName == nil }

    mutating func clear() {
        preparedSpellID = nil
        preparedSpellName = nil
        isSpent = false
    }
}

/// Quantos slots de um círculo o personagem tem por descanso — a tabela de
/// memorização do livro, preenchida uma vez na ficha. É o molde a partir
/// do qual toda folha de magia nova é montada; diferente do `SpellSlot`,
/// não guarda o que está preparado hoje, só o quanto cabe.
struct SpellSlotAllotment: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var caster: CasterType
    var level: Int
    var count: Int
}

/// Uma entrada do livro de magias do Mago (2026-09-29 — ver `PlayerCharacter.
/// wizardSpellbook` pro porquê disso ser um bloqueio de verdade, não um
/// sinal). Mesma ideia de "nome + id opcional da base" já usada em
/// `ItemSpellUse`/`SpellLogEntry`: uma magia homebrew ou achada num
/// pergaminho em jogo, sem entrada na base embutida, também pode entrar no
/// livro — só fica sem descrição completa disponível.
struct WizardSpellbookEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    /// Id da base embutida, quando reconhecida — usado pra achar círculo/
    /// escola/descrição de verdade.
    var matchedSpellID: String? = nil
    /// Círculo — só precisa vir preenchido quando `matchedSpellID == nil`
    /// (sem entrada na base pra ler o círculo de lá); `nil` quando bate
    /// com a base, o círculo real é sempre `Spell.level`, nunca este campo.
    var level: Int? = nil
}

// MARK: - Tabelas de referência do clérigo (PHB 2e — Tabelas 5, 24 e 61)
//
// Dados fixos do livro, traduzidos o mais fiel possível das tabelas
// oficiais. Vivem aqui (não numa view) porque `PlayerCharacter.
// computedSpellSlotAllotments` também lê a Priest Spell Progression pra
// montar a grade de slots de folhas novas — a tabela na tela do Clérigo é
// só a mesma fonte, exibida.
enum PriestTables {
    /// Tabela 24: Priest Spell Progression. Índice 0 = nível 1 do
    /// personagem; cada linha tem 7 posições (círculos 1–7). `nil` é "—"
    /// (círculo ainda não disponível nesse nível).
    static let spellProgressionRows: [[Int?]] = [
        [1, nil, nil, nil, nil, nil, nil],       // 1
        [2, nil, nil, nil, nil, nil, nil],       // 2
        [2, 1, nil, nil, nil, nil, nil],         // 3
        [3, 2, nil, nil, nil, nil, nil],         // 4
        [3, 3, 1, nil, nil, nil, nil],           // 5
        [3, 3, 2, nil, nil, nil, nil],           // 6
        [3, 3, 2, 1, nil, nil, nil],             // 7
        [3, 3, 3, 2, nil, nil, nil],             // 8
        [4, 4, 3, 2, 1, nil, nil],               // 9
        [4, 4, 3, 3, 2, nil, nil],               // 10
        [5, 4, 4, 3, 2, 1, nil],                 // 11
        [6, 5, 5, 3, 2, 2, nil],                 // 12
        [6, 6, 6, 4, 2, 2, nil],                 // 13
        [6, 6, 6, 5, 3, 2, 1],                   // 14
        [6, 6, 6, 6, 4, 2, 1],                   // 15
        [7, 7, 7, 6, 4, 3, 1],                   // 16
        [7, 7, 7, 7, 5, 3, 2],                   // 17
        [8, 8, 8, 8, 6, 4, 2],                   // 18
        [9, 9, 9, 8, 6, 4, 2],                   // 19
        [9, 9, 9, 8, 7, 5, 2],                   // 20
    ]

    /// Requisito mínimo de Sabedoria pra cada círculo (só 6º e 7º têm; os
    /// outros ficam 0, sem restrição além da tabela de progressão em si).
    static let wisdomRequirementByCircle: [Int: Int] = [6: 17, 7: 18]

    /// Slots de cada círculo (1–7) pro nível/Sabedoria dados — `count > 0`
    /// só quando a tabela concede e (se houver requisito) a Sabedoria bate.
    ///
    /// CORREÇÃO (2026-09-26): até aqui esta função nunca somava o bônus de
    /// magia por Sabedoria alta (Tabela 5 do PHB, `WisdomTable.
    /// bonusSpellTotals` em `AbilityTables.swift`) — só usava `wisdom` pra
    /// travar/destravar 6º e 7º círculo (`wisdomRequirementByCircle`).
    /// Relatado pelo usuário: clérigo nível 11 com Sabedoria 19 mostrava
    /// sempre 5 slots de 1º círculo (só a base da Tabela 24), nunca os 8
    /// (5 base + 3 de bônus) que a regra manda. Um conserto anterior, no
    /// mesmo dia, já tinha corrigido a SOMA do bônus (`bonusSpellTotals`),
    /// mas isso só alimentava um campo de texto informativo
    /// (`AbilityDetails.wisdomBonusSpells`) que nunca influenciava a grade
    /// de slots de verdade — o bug real estava aqui. Bônus só entra em
    /// círculos que a Tabela 24 já concede nesse nível (regra do livro:
    /// "these spells are available only when the priest is entitled to
    /// spells of the appropriate level") — nunca cria um círculo novo
    /// sozinho.
    static func spellProgression(level: Int, wisdom: Int) -> [Int] {
        let row = spellProgressionRows[max(0, min(level, spellProgressionRows.count) - 1)]
        let bonusByCircle = WisdomTable.bonusSpellTotals(forScore: wisdom) ?? [:]
        return row.enumerated().map { index, count in
            let circle = index + 1
            guard let count else { return 0 }
            if let required = wisdomRequirementByCircle[circle], wisdom < required { return 0 }
            return count + (bonusByCircle[circle] ?? 0)
        }
    }

    /// Tabela 61: Turning Undead. Cada linha é (tipo/DV, resultados nas 12
    /// colunas de nível de clérigo). "T" = turned automático, "D" =
    /// destroyed automático, "D*" = destroyed + 2d4 adicionais, "—" = sem
    /// efeito possível nesse nível.
    static let turningUndeadLevels = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10-11", "12-13", "14+"]
    static let turningUndeadRows: [(type: String, results: [String])] = [
        ("Skeleton or 1 HD", ["10", "7", "4", "T", "T", "D", "D", "D*", "D*", "D*", "D*", "D*"]),
        ("Zombie", ["13", "10", "7", "4", "T", "T", "D", "D", "D*", "D*", "D*", "D*"]),
        ("Ghoul or 2 HD", ["16", "13", "10", "7", "4", "T", "T", "D", "D", "D*", "D*", "D*"]),
        ("Shadow or 3-4 HD", ["19", "16", "13", "10", "7", "4", "T", "T", "D", "D", "D*", "D*"]),
        ("Wight or 5 HD", ["20", "19", "16", "13", "10", "7", "4", "T", "T", "D", "D", "D*"]),
        ("Ghast", ["—", "20", "19", "16", "13", "10", "7", "4", "T", "T", "D", "D"]),
        ("Wraith or 6 HD", ["—", "—", "20", "19", "16", "13", "10", "7", "4", "T", "T", "D"]),
        ("Mummy or 7 HD", ["—", "—", "—", "20", "19", "16", "13", "10", "7", "4", "T", "T"]),
        ("Spectre or 8 HD", ["—", "—", "—", "—", "20", "19", "16", "13", "10", "7", "4", "T"]),
        ("Vampire or 9 HD", ["—", "—", "—", "—", "—", "20", "19", "16", "13", "10", "7", "4"]),
        ("Ghost or 10 HD", ["—", "—", "—", "—", "—", "—", "20", "19", "16", "13", "10", "7"]),
        ("Lich or 11+ HD", ["—", "—", "—", "—", "—", "—", "—", "20", "19", "16", "13", "10"]),
        ("Special**", ["—", "—", "—", "—", "—", "—", "—", "—", "20", "19", "16", "13"]),
    ]
    static let turningUndeadFootnotes = [
        "* An additional 2d4 creatures of this type are turned.",
        "** Special creatures include unique undead, free-willed undead of the Negative Material Plane, certain Greater and Lesser Powers, and those undead that dwell in the Outer Planes.",
        "† Paladins turn undead as priests who are two levels lower.",
    ]

    /// Tabela 5: Wisdom. Uma linha por pontuação (1–25).
    static let wisdomRows: [(score: Int, magDef: String, bonus: String, failure: String, immunity: String)] = [
        (1, "−6", "—", "80%", "—"),
        (2, "−4", "—", "60%", "—"),
        (3, "−3", "—", "50%", "—"),
        (4, "−2", "—", "45%", "—"),
        (5, "−1", "—", "40%", "—"),
        (6, "−1", "—", "35%", "—"),
        (7, "−1", "—", "30%", "—"),
        (8, "0", "—", "25%", "—"),
        (9, "0", "0", "20%", "—"),
        (10, "0", "0", "15%", "—"),
        (11, "0", "0", "10%", "—"),
        (12, "0", "0", "5%", "—"),
        (13, "0", "1st", "0%", "—"),
        (14, "0", "1st", "0%", "—"),
        (15, "+1", "2nd", "0%", "—"),
        (16, "+2", "2nd", "0%", "—"),
        (17, "+3", "3rd", "0%", "—"),
        (18, "+4", "4th", "0%", "—"),
        (19, "+4", "1st, 3rd", "0%", "cause fear, charm person, command, friends, hypnotism"),
        (20, "+4", "2nd, 4th", "0%", "forget, hold person, ray of enfeeblement, scare"),
        (21, "+4", "3rd, 5th", "0%", "fear"),
        (22, "+4", "4th, 5th", "0%", "charm monster, confusion, emotion, fumble, suggestion"),
        (23, "+4", "1st, 6th", "0%", "chaos, feeblemind, hold monster, magic jar, quest"),
        (24, "+4", "5th, 6th", "0%", "geas, mass suggestion, rod of rulership"),
        (25, "+4", "6th, 7th", "0%", "antipathy/sympathy, death spell, mass charm"),
    ]
}

// MARK: - Tabela de referência do mago (PHB 2e — Tabela 21)
//
// Mesmo espírito de `PriestTables` acima: dado fixo do livro, vivendo aqui
// (não numa view) porque `PlayerCharacter.computedSpellSlotAllotments`
// também lê a Wizard Spell Progression pra montar a grade de slots de
// folhas novas — a tabela na tela do Mago é só a mesma fonte, exibida.
enum WizardTables {
    /// Tabela 21: Wizard Spell Progression. Índice 0 = nível 1 do
    /// personagem; cada linha tem 9 posições (círculos 1–9). `nil` é "—"
    /// (círculo ainda não disponível nesse nível). Conferida contra duas
    /// transcrições independentes da tabela do PHB 2e (2026-09-29) — ao
    /// contrário do sacerdote, o mago NÃO ganha slot bônus por Inteligência
    /// alta (essa é só a tabela de Sabedoria/Tabela 5); Inteligência entra
    /// só como TETO de círculo alcançável (ver `spellProgression` abaixo).
    static let spellProgressionRows: [[Int?]] = [
        [1, nil, nil, nil, nil, nil, nil, nil, nil],   // 1
        [2, nil, nil, nil, nil, nil, nil, nil, nil],   // 2
        [2, 1, nil, nil, nil, nil, nil, nil, nil],     // 3
        [3, 2, nil, nil, nil, nil, nil, nil, nil],     // 4
        [4, 2, 1, nil, nil, nil, nil, nil, nil],       // 5
        [4, 2, 2, nil, nil, nil, nil, nil, nil],       // 6
        [4, 3, 2, 1, nil, nil, nil, nil, nil],         // 7
        [4, 3, 3, 2, nil, nil, nil, nil, nil],         // 8
        [4, 3, 3, 2, 1, nil, nil, nil, nil],           // 9
        [4, 4, 3, 2, 2, nil, nil, nil, nil],           // 10
        [4, 4, 4, 3, 3, nil, nil, nil, nil],           // 11
        [4, 4, 4, 4, 4, 1, nil, nil, nil],             // 12
        [5, 5, 5, 4, 4, 2, nil, nil, nil],             // 13
        [5, 5, 5, 4, 4, 2, 1, nil, nil],               // 14
        [5, 5, 5, 5, 5, 2, 1, nil, nil],               // 15
        [5, 5, 5, 5, 5, 3, 2, 1, nil],                 // 16
        [5, 5, 5, 5, 5, 3, 3, 2, nil],                 // 17
        [5, 5, 5, 5, 5, 3, 3, 2, 1],                   // 18
        [5, 5, 5, 5, 5, 3, 3, 3, 1],                   // 19
        [5, 5, 5, 5, 5, 4, 3, 3, 2],                   // 20
    ]

    /// Slots de cada círculo (1–9) pro nível/Inteligência dados. Diferente
    /// do sacerdote (que trava só 6º/7º por Sabedoria mínima), a
    /// Inteligência do mago é um teto que corta QUALQUER círculo acima do
    /// que a Tabela 4 permite — reaproveita `IntelligenceTable.byScore`
    /// (a mesma tabela que já preenche o campo "Max Spell Level" da ficha,
    /// `AbilityDetailProviders`) em vez de duplicar os números aqui.
    static func spellProgression(level: Int, intelligence: Int) -> [Int] {
        let row = spellProgressionRows[max(0, min(level, spellProgressionRows.count) - 1)]
        let cap = IntelligenceTable.maxSpellLevelInt(forScore: intelligence)
        return row.enumerated().map { index, count in
            let circle = index + 1
            guard let count, circle <= cap else { return 0 }
            return count
        }
    }
}

// MARK: - Tabela de referência do bardo (PHB 2e — Tabela 32, 2026-09-30)
//
// Mesmo espírito de `WizardTables` acima — dado fixo do livro, vivendo
// aqui porque `PlayerCharacter.computedSpellSlotAllotments` também lê a
// Bard Spell Progression. Os números já tinham sido transcritos uma vez
// em `RogueReferenceView.swift` (tabela de consulta pura, sem ficha por
// trás) — esta é a cópia CANÔNICA; a view foi ajustada pra ler daqui em
// vez de manter os números duplicados (risco de um dia divergir).
//
// Bardo lança magia de Mago (mesma base arcana, mesmo atributo-chave —
// Inteligência), mas com teto natural de 6º círculo (não 9º) e SEM o
// bônus de especialização de escola do Table 22 (PHB, descrição do
// Bardo: "In no case can a bard choose to specialize in a school of
// magic") — por isso `computedSpellSlotAllotments` não soma bônus
// nenhum no `case .bard`, ao contrário do `case .mage`.
enum BardTables {
    /// Tabela 32: Bard Spell Progression. Índice 0 = nível 1 do
    /// personagem; cada linha tem 6 posições (círculos 1–6). `nil` é "—".
    static let spellProgressionRows: [[Int?]] = [
        [nil, nil, nil, nil, nil, nil],   // 1
        [1, nil, nil, nil, nil, nil],     // 2
        [2, nil, nil, nil, nil, nil],     // 3
        [2, 1, nil, nil, nil, nil],       // 4
        [3, 1, nil, nil, nil, nil],       // 5
        [3, 2, nil, nil, nil, nil],       // 6
        [3, 2, 1, nil, nil, nil],         // 7
        [3, 3, 1, nil, nil, nil],         // 8
        [3, 3, 2, nil, nil, nil],         // 9
        [3, 3, 2, 1, nil, nil],           // 10
        [3, 3, 3, 1, nil, nil],           // 11
        [3, 3, 3, 2, nil, nil],           // 12
        [3, 3, 3, 2, 1, nil],             // 13
        [3, 3, 3, 3, 1, nil],             // 14
        [3, 3, 3, 3, 2, nil],             // 15
        [4, 3, 3, 3, 2, 1],               // 16
        [4, 4, 3, 3, 3, 1],               // 17
        [4, 4, 4, 3, 3, 2],               // 18
        [4, 4, 4, 4, 3, 2],               // 19
        [4, 4, 4, 4, 4, 3],               // 20
    ]

    /// Slots de cada círculo (1–6) pro nível/Inteligência dados — mesmo
    /// mecanismo de teto de `WizardTables.spellProgression` (Inteligência
    /// corta qualquer círculo acima do que a Tabela 4 permite), só que a
    /// própria Tabela 32 já para no 6º círculo sozinha.
    static func spellProgression(level: Int, intelligence: Int) -> [Int] {
        let row = spellProgressionRows[max(0, min(level, spellProgressionRows.count) - 1)]
        let cap = IntelligenceTable.maxSpellLevelInt(forScore: intelligence)
        return row.enumerated().map { index, count in
            let circle = index + 1
            guard let count, circle <= cap else { return 0 }
            return count
        }
    }
}

// MARK: - Especialização de escola do Mago (PHB 2e — Table 22, 2026-09-30)
//
// Pedido do usuário: "escolas de magia", não "círculos" (correção do que
// tinha sido pedido antes). Especializar é OPCIONAL — um Mago pode
// continuar generalista (`PlayerCharacter.wizardSchool == nil`, sem bônus
// e sem restrição nenhuma, comportamento de sempre). Quem escolhe uma das
// oito escolas ganha +1 slot por círculo onde já tem magia (Table 22) e
// passa a ter escolas OPOSTAS bloqueadas de verdade — mesma filosofia de
// bloqueio real já usada pro livro de magias (`wizardSpellbook`), ao
// contrário da esfera do Clérigo (que só sinaliza). O bônus de aprendizado
// (+15%/-15%) e o bônus de teste de resistência (±1) do PHB não têm onde
// morar no app (não existe rolagem de "chance to learn" nem resolução de
// combate/salvamento por magia aqui) — de propósito, ficam só como regra
// documentada, não implementada, mesma linha de nunca simular dado que o
// app já segue.
//
// A tabela de oposição (verificada em duas fontes independentes — a wiki
// AD&D 2e e a página de Escolas Opostas do Complete Wizard's Handbook,
// que documenta a mesma mecânica do PHB) NÃO é um "oposto + os dois
// vizinhos, à escolha do jogador" como se pensou antes de perguntar ao
// usuário — é uma lista FIXA por escola, com contagem variando pela
// "força" da escola (fraca = 1, moderada = 2, forte = 3):
enum WizardSchool: String, Codable, CaseIterable, Identifiable, Hashable {
    case abjuration = "Abjuration"
    case alteration = "Alteration"
    case conjuration = "Conjuration/Summoning"
    case divination = "Divination"
    case enchantment = "Enchantment/Charm"
    case illusion = "Illusion/Phantasm"
    case invocation = "Invocation/Evocation"
    case necromancy = "Necromancy"

    var id: String { rawValue }

    /// Escolas opostas fixas (Table 22) — não é escolha do jogador, e a
    /// contagem não é simétrica entre as duas pontas (ex.: Illusion lista
    /// Invocation como oposta, mas Invocation não lista Illusion de volta
    /// — cada escola tem sua própria contagem por "força", conferido
    /// contra a fonte, não um erro de digitação).
    var oppositionSchools: [WizardSchool] {
        switch self {
        case .abjuration: return [.alteration, .illusion]
        case .alteration: return [.abjuration, .necromancy]
        case .conjuration: return [.divination, .invocation]
        case .divination: return [.conjuration]
        case .enchantment: return [.invocation, .necromancy]
        case .illusion: return [.necromancy, .invocation, .abjuration]
        case .invocation: return [.enchantment, .conjuration]
        case .necromancy: return [.illusion, .enchantment]
        }
    }

    /// Título de quem se especializa nesta escola — só pra exibição (ex.:
    /// cabeçalho de "My Spellbook"). Os nomes vêm do PHB (Table 4 lista
    /// "Diviner" pra Greater Divination, não "Divinationist").
    var specialistTitle: String {
        switch self {
        case .abjuration: return "Abjurer"
        case .alteration: return "Transmuter"
        case .conjuration: return "Conjurer"
        case .divination: return "Diviner"
        case .enchantment: return "Enchanter"
        case .illusion: return "Illusionist"
        case .invocation: return "Invoker"
        case .necromancy: return "Necromancer"
        }
    }
}

/// A grade inteira de slots de um personagem, agrupada por nível de círculo.
struct SpellSlotBoard: Codable, Hashable {
    var slots: [SpellSlot] = []

    func slots(level: Int, caster: CasterType) -> [SpellSlot] {
        slots.filter { $0.level == level && $0.caster == caster }
    }

    var usedLevels: [Int] {
        Array(Set(slots.map(\.level))).sorted()
    }

    func casters() -> [CasterType] {
        CasterType.allCases.filter { c in slots.contains { $0.caster == c } }
    }

    /// Ajusta a quantidade de slots de um nível, preservando o que já estava
    /// preparado nos slots que continuam existindo.
    mutating func setCount(_ count: Int, level: Int, caster: CasterType) {
        guard count >= 0 else { return }
        var existing = slots.filter { $0.level == level && $0.caster == caster }
        slots.removeAll { $0.level == level && $0.caster == caster }
        if existing.count > count {
            // Descarta primeiro os slots vazios, depois os já gastos — nunca
            // uma magia preparada que ainda está disponível.
            existing.sort { (lhs: SpellSlot, rhs: SpellSlot) -> Bool in
                SpellSlotBoard.keepRank(lhs) < SpellSlotBoard.keepRank(rhs)
            }
            existing = Array(existing.prefix(count))
        } else {
            // `orderKey` sequencial a partir do maior já usado NESTE círculo
            // — nunca a partir de um novo `UUID()` aleatório (era esse o
            // bug: ver o comentário em `SpellSlot.orderKey`).
            var nextOrder = (existing.map(\.orderKey).max() ?? -1) + 1
            while existing.count < count {
                existing.append(SpellSlot(level: level, caster: caster, orderKey: nextOrder))
                nextOrder += 1
            }
        }
        slots.append(contentsOf: existing)
        sortSlots()
    }

    /// Prioridade de permanência quando a quantidade de slots diminui:
    /// preparados e disponíveis ficam, vazios são os primeiros a sair.
    /// (A lista é ordenada por este posto e cortada pelo fim.)
    private static func keepRank(_ slot: SpellSlot) -> Int {
        if slot.isEmpty { return 2 }
        if slot.isSpent { return 1 }
        return 0
    }

    /// Ordem determinística: sem ALGUM critério de desempate, os chips
    /// embaralham a cada edição, porque sort não garante manter a ordem
    /// original entre dois slots "empatados" nos outros dois critérios.
    ///
    /// AJUSTE (2026-09-28): o desempate usava `id.uuidString`, e isso
    /// causava exatamente o bug oposto do que pretendia evitar — `id` é
    /// deliberadamente re-sorteado a cada `SpellSheet.nextDay()` (ver
    /// comentário lá), então a ordem visual do círculo virava loteria toda
    /// vez que se criava uma folha nova, mesmo com os MESMOS feitiços
    /// memorizados nos MESMOS slots. Trocado por `orderKey`, que `nextDay()`
    /// nunca toca — só o `id` muda de um dia pro outro.
    private mutating func sortSlots() {
        slots.sort { (lhs: SpellSlot, rhs: SpellSlot) -> Bool in
            if lhs.caster != rhs.caster {
                return lhs.caster.rawValue < rhs.caster.rawValue
            }
            if lhs.level != rhs.level {
                return lhs.level < rhs.level
            }
            return lhs.orderKey < rhs.orderKey
        }
    }

    /// Descanso: devolve todos os slots gastos. Mantém o que estava preparado
    /// para quem prefere remontar a lista a partir do dia anterior.
    mutating func rest(clearingPreparations: Bool) {
        for index in slots.indices {
            slots[index].isSpent = false
            if clearingPreparations { slots[index].clear() }
        }
    }

    /// Marca como gasto o primeiro slot disponível com a magia indicada.
    /// Retorna true se encontrou um slot pra gastar.
    @discardableResult
    mutating func spendSlot(spellID: String) -> Bool {
        guard let index = slots.firstIndex(where: {
            $0.preparedSpellID == spellID && !$0.isSpent
        }) else { return false }
        slots[index].isSpent = true
        return true
    }

    /// Mesma coisa para magias preparadas por nome livre (fora da base).
    @discardableResult
    mutating func spendSlot(named name: String) -> Bool {
        let target = Fuzzy.normalize(name)
        guard !target.isEmpty else { return false }
        guard let index = slots.firstIndex(where: { slot in
            guard !slot.isSpent, let prepared = slot.preparedSpellName else { return false }
            return Fuzzy.normalize(prepared) == target
        }) else { return false }
        slots[index].isSpent = true
        return true
    }
}

// MARK: - Personagem

/// Uma linha da lista de equipamento: nome e uma nota curta à direita
/// (peso, dano, quantidade) — como se escreve na margem da ficha.
struct EquipmentItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var note: String = ""
}

/// Uma linha da tabela de armas da ficha oficial.
struct WeaponEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var attacks: String = "1"
    var thac0: String = ""
    var damageSmall: String = ""
    var damageLarge: String = ""
    var range: String = "—"

    // Campos novos da ficha oficial (PDF page 1) — Optional porque uma
    // ficha salva antes desta versão não tem essas chaves no JSON, e o
    // decoder sintetizado do Swift falha o struct inteiro se um campo
    // não-Optional com valor padrão estiver ausente (só Optional vira
    // decodeIfPresent e cai em nil sozinho).
    var size: String? = nil
    var weaponType: String? = nil
    var speed: String? = nil
    var hitAdj: String? = nil
    var dmgAdj: String? = nil
    var rangeSpecial: String? = nil

    /// `Weapon.id` quando esta linha veio do `WeaponPickerSheet` (Weapon
    /// Compendium) — mesmo padrão de `ProficiencyEntry.matchedProficiencyID`:
    /// liga a linha à base pra abrir a descrição completa num toque, sem
    /// depender do nome bater exatamente. `nil` numa linha digitada à mão
    /// (fichas antigas, ou arma caseira fora da base de 69 armas do PHB).
    var matchedWeaponID: String? = nil

    /// Weapon Specialization (2026-09-30, regra do PHB conferida contra o
    /// resumo do Complete Fighter's Handbook cap. 4 — "Single-Weapon
    /// Proficiency, Weapon Specialization"): só Fighter (nunca Paladin ou
    /// Ranger) pode especializar. `Bool?` pela mesma razão de `hitAdj`
    /// acima — ficha antiga não tem essa chave. A UI (`WeaponFormRow`)
    /// semeia `thac0`("+1")/`dmgAdj`("+2") na primeira vez que liga isto,
    /// sem nunca sobrescrever o que o jogador já tiver escrito — o
    /// jogador continua livre pra editar os campos à mão depois.
    var isSpecialized: Bool? = nil
}

/// Uma linha da tabela de Proficiências da ficha oficial (nome + espaços
/// gastos + marcado ou não).
struct ProficiencyEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    /// Quantos espaços de proficiência esta entrada consome. Era um campo
    /// de TEXTO LIVRE — qualquer coisa podia ser digitada ali, inclusive
    /// coisas que não fazem sentido nenhum nessa coluna (bug relatado pelo
    /// usuário 2026-09-22: a ficha do Kelmon, gerada a partir dos dados de
    /// exemplo antigos de `SampleCharacter.swift`, tinha "weapon" e "WIS
    /// 17" no campo "Slots" — informação que devia estar em `target`, ou
    /// nem existir). Virou número de verdade. `init(from:)` abaixo lê
    /// fichas salvas ANTES dessa mudança (campo era String): tenta como
    /// Int primeiro, senão extrai os dígitos de dentro do texto antigo
    /// (ex.: "2 slots" → 2), senão cai pro padrão de 1 — nunca falha ao
    /// abrir a ficha, só normaliza o valor.
    var slots: Int = 1
    /// "checked" era um Bool (caixinha de visto) — na prática a coluna
    /// "Chk" da ficha oficial é o número-alvo pra rolar no dado (ex.: "14")
    /// pra ter sucesso na checagem, não um sim/não. `checked` fica sem uso
    /// (fichas antigas continuam decodificando normalmente, a chave extra é
    /// só ignorada) e `target` — Optional, mesma regra de sempre — guarda
    /// o valor de verdade.
    var checked: Bool = false
    var target: String? = nil
    /// `Proficiency.id` quando esta linha veio do `ProficiencyPickerSheet`
    /// (TODO.md item 18) — mesmo padrão de `ItemSpellUse.matchedSpellID`:
    /// liga a linha à base pra abrir a descrição completa num toque, sem
    /// depender do nome bater exatamente. `nil` numa linha digitada à mão
    /// (fichas antigas, ou proficiência caseira fora da base) — nesse caso
    /// o nome ainda é comparado contra a base como último recurso (ver
    /// `ProficiencyFormRow.matchedProficiency`), mas sem garantia nenhuma.
    var matchedProficiencyID: String? = nil

    init(id: UUID = UUID(), name: String = "", slots: Int = 1, checked: Bool = false,
         target: String? = nil, matchedProficiencyID: String? = nil) {
        self.id = id
        self.name = name
        self.slots = slots
        self.checked = checked
        self.target = target
        self.matchedProficiencyID = matchedProficiencyID
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, slots, checked, target, matchedProficiencyID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        checked = try container.decodeIfPresent(Bool.self, forKey: .checked) ?? false
        target = try container.decodeIfPresent(String.self, forKey: .target)
        matchedProficiencyID = try container.decodeIfPresent(String.self, forKey: .matchedProficiencyID)

        if let intSlots = try? container.decodeIfPresent(Int.self, forKey: .slots) {
            slots = intSlots
        } else if let textSlots = try? container.decodeIfPresent(String.self, forKey: .slots) {
            let digits = textSlots.filter(\.isNumber)
            slots = Int(digits) ?? 1
        } else {
            slots = 1
        }
    }
}

/// Uma linha da tabela "Thieving Skills" (2026-09-30, grupo Rogue —
/// Thief/Bard/Ninja, ver `CharacterClass.hasThievingSkills`) — nome fixo
/// (vem de `ThievingSkillsTable.skills(for:)`, não editável) + um único
/// campo de texto livre pra porcentagem final. Mesma filosofia de
/// `WeaponEntry`/`ProficiencyEntry`: nada aqui é recalculado ao vivo —
/// `value` só é SEMEADO uma vez (base + raça + Destreza, ver
/// `ThievingSkillsTable.seedTotal`) quando a linha nasce, e o jogador é
/// quem soma os pontos de distribuição por nível e o ajuste de armadura
/// (que o app não tem como calcular sozinho — ver doc de
/// `ThievingSkillsTable`) por cima, à mão.
struct ThievingSkillEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var skill: String = ""
    var value: String = ""
}

/// Wild Talent (CPsiH cap. 1, "Wild Talents" — `RuleEntry` id
/// `cpsih_ch01_wild_talents`, `Scripts/convert_psionics_rules.py`):
/// personagem de QUALQUER classe pode ter potencial psiônico latente,
/// independente de classe/raça/alinhamento. Diferente de um Psionicist de
/// verdade (que ainda não é uma `CharacterClass` jogável — rodada
/// "fundação primeiro" dos Psiônicos, 2026-10-01, ver TODO.md), um wild
/// talent não tem Attack/Defense Modes nem avança em nível igual um
/// psiônico — só guarda o(s) poder(es) que a rolagem/Mestre concedeu e os
/// PSP que vêm junto. Mesmo tratamento de `CombatDetails`/`WeaponEntry`:
/// o app registra o RESULTADO da regra (powers conhecidos, PSP), não
/// automatiza a rolagem percentual em si (Tabela 11 de chance base,
/// Tabela 12/13 Wild Devotions/Sciences) — o jogador rola fora da ficha e
/// anota aqui, do jeito que já faz com XP ou dano recebido.
struct WildTalent: Codable, Hashable {
    /// Nome(s) do(s) poder(es) conhecido(s) — texto livre (pode bater com
    /// `PsionicPower.title` da base, ou vir escrito à mão); mais de um
    /// poder é raro mas possível ("a lucky few" no texto da regra), por
    /// isso lista em vez de campo único.
    var powers: [String] = []
    /// PSP do wild talent — bem menor que um Psionicist de verdade (CPsiH:
    /// "the minimum number of PSPs necessary to use the power once" +
    /// 4x o custo de manutenção se o poder puder ser mantido; +4 PSP a
    /// cada nível novo depois).
    var psionicStrengthPoints: Int = 0
}

/// Um poder conhecido de um Psionicist de verdade — mesmo molde de
/// `WizardSpellbookEntry` (nome livre + id batido com a base quando dá pra
/// casar), porque `PsionicPower` não tem conceito de "círculo" pra guardar
/// à parte quando não bate: o poder free-name só perde a ficha de detalhe
/// completa, nada mais.
struct PsionicPowerEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var matchedPowerID: String? = nil
}

// `PsionicistPowers` (a struct "caixinha" que juntava os 4 campos abaixo
// num `PlayerCharacter.psionicistPowers: PsionicistPowers?` só) foi
// REMOVIDA (2026-10-02) — não é refatoração por estilo, é a causa raiz
// confirmada por bissecção desta rodada (ver os comentários grandes em
// `Thac0ByLevelProvider.swift`/`ExperienceProgressionTable.swift` pras
// outras causas já corrigidas): um `Optional<Struct>` onde a struct por
// dentro guarda um `[OutraStruct]` é um formato que `PlayerCharacter` (a
// maior struct do app, com Codable/Hashable sintetizados por já ter
// centenas de campos) não aguenta mais — confirmado isolando só essas
// duas declarações de struct no arquivo (sem nenhuma propriedade nova em
// `PlayerCharacter`): compilou limpo. Só a PROPRIEDADE estourava.
// `wizardSpellbook: [WizardSpellbookEntry]` (array direto, sem wrapper
// opcional) e `wildTalent: WildTalent?` (opcional, mas sem array de
// struct por dentro) já provam que cada peça SOZINHA é segura — só a
// combinação dos dois (opcional de struct-com-array-de-struct) não é.
//
// Fix: os 4 campos viraram propriedades PLANAS, direto no
// `PlayerCharacter`, cada uma com seu próprio default (mesmo padrão de
// `wizardSpellbook`) em vez de aninhados numa struct só — ver
// `psionicistKnownPowers`/`psionicistDefenseModesKnown`/
// `psionicistPSPMax`/`psionicistPSPCurrent` mais abaixo. PSP máximo
// continua em branco por padrão (jogador preenche à mão) pelo mesmo
// motivo de sempre — a fórmula da "Inherent Potential" (CPsiH Table 5)
// parte de uma tabela por pontuação de Sabedoria que o material enviado
// pelo usuário só trouxe um recorte (15 a 18); sem a tabela completa (3 a
// 25), calcular sozinho seria inventar dado de regra, o que este projeto
// nunca faz (ver `Scripts/convert_psionics_rules.py`) — mesma filosofia
// de nunca rolar dado sozinho que `WildTalent.psionicStrengthPoints` já
// segue.

/// Os detalhes de combate da ficha oficial que não têm campo próprio ainda
/// no personagem — tudo texto livre, como as linhas em branco do PDF.
/// Todo o struct é Optional no personagem (ver `PlayerCharacter.combat`)
/// pelo mesmo motivo do `WeaponEntry` acima.
struct CombatDetails: Codable, Hashable {
    var surprisedAC: String? = nil
    var shieldlessAC: String? = nil
    var rearAC: String? = nil
    var typeWorn: String? = nil
    var dexChecks: String? = nil
    var visionChecks: String? = nil
    var hearingChecks: String? = nil
    var hitDiceType: String? = nil
    var numbedNumber: String? = nil
    var uselessNumber: String? = nil
    var maxDeaths: String? = nil
    var deathsToDate: String? = nil
    var wounds: String? = nil
}

/// Uma linha da tabela de Equipment da página 2 do PDF oficial — item,
/// onde está guardado, peso. Diferente do `EquipmentItem` da aba Equipment
/// (que só tem nome + nota): mantido à parte de propósito, pra não mexer
/// na aba Equipment enquanto ela não for refeita também.
struct Page2EquipmentEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var item: String = ""
    var location: String = ""
    var weight: String = ""

    /// Coluna fixa em que a linha nasceu (0 ou 1). Antes as duas colunas
    /// eram um rodízio calculado pelo índice na lista — apagar uma linha
    /// deslocava o índice de tudo que vinha depois, e metade das linhas
    /// "pulava" de coluna. Guardando a coluna na própria linha, apagar uma
    /// só mexe nas linhas abaixo dela NA MESMA coluna, como uma lista
    /// normal. Optional pelo mesmo motivo de sempre; ausência vira coluna 0.
    var column: Int? = nil

    /// `MundaneItem.id` quando esta linha veio do `MundaneItemPickerSheet`
    /// (Equipment Compendium) — mesmo padrão de
    /// `ProficiencyEntry.matchedProficiencyID`/`WeaponEntry.matchedWeaponID`:
    /// liga a linha à base pra abrir a descrição completa (custo/peso) num
    /// toque. `nil` numa linha digitada à mão (fichas antigas, ou item
    /// caseiro fora do catálogo de 183 itens).
    var matchedItemID: String? = nil
}

/// As taxas da tabela "Movement" da página 2.
struct MovementRates: Codable, Hashable {
    var base: String = ""
    var jog: String = ""
    var runX3: String = ""
    var runX4: String = ""
    var runX5: String = ""
    var day: String = ""
}

/// Uma linha da tabela de Encumbrance da página 2 — uma das quatro
/// categorias fixas do livro (Light/Moderate/Heavy/Severe).
struct EncumbranceRow: Codable, Hashable {
    var weightCarried: String = ""
    var moveRate: String = ""
    var attackPenalty: String = ""
    var acPenalty: String = ""
}

struct EncumbranceTable: Codable, Hashable {
    var light = EncumbranceRow()
    var moderate = EncumbranceRow()
    var heavy = EncumbranceRow()
    var severe = EncumbranceRow()
}

/// Uma linha da tabela "Level Changes" (By / At Levels) da página 2.
struct LevelChangeRow: Codable, Hashable {
    var by: String = ""
    var atLevels: String = ""
}

struct LevelChangesTable: Codable, Hashable {
    var thac0 = LevelChangeRow()
    var savingThrows = LevelChangeRow()
    var weaponProficiencies = LevelChangeRow()
    var nonWeaponProficiencies = LevelChangeRow()
}

/// Uma linha com quantidade — "10 poções de cura" numa linha só, em vez de
/// dez linhas repetidas. Usado pelas listas de Magic Items e Treasure/
/// Other Possessions da página 2.
struct QuantifiedItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var quantity: Int = 1

    /// Quantos já foram usados/gastos — marcado a mão com o mesmo contador
    /// de traço ("pauzinhos") da Priest Spell Sheet. Optional pelo mesmo
    /// motivo de sempre: linhas criadas antes desta versão não têm essa
    /// chave.
    var usedCount: Int? = nil

    /// Liga esta linha a um item de `MagicItemDatabase` (mesmo padrão de
    /// `Page2EquipmentEntry.matchedItemID`/`MundaneItemDatabase`) — só usado
    /// pela lista "Magic Items" (não por "Treasure / Other Possessions",
    /// que continua puramente texto livre). `nil` = linha digitada à mão
    /// pelo jogador (item caseiro/criado por ele) ou ficha salva antes
    /// desta versão existir; nesse caso cai pro fallback de nome exato,
    /// igual ao equipamento mundano.
    var matchedItemID: String? = nil
}

/// As moedas, como na caixa de tesouro da ficha.
struct Treasure: Codable, Hashable {
    var platinum: Int = 0
    var gold: Int = 0
    var electrum: Int = 0
    var silver: Int = 0
    var copper: Int = 0
}

/// Os ajustes derivados dos atributos. Na ficha oficial são linhas em
/// branco preenchidas a partir das tabelas do Livro do Jogador; aqui o app
/// sugere o que sabe calcular e deixa o resto por sua conta.
struct AbilityDetails: Codable, Hashable {
    var strengthHit: String = ""
    var strengthDamage: String = ""
    var strengthWeight: String = ""
    var strengthMaxPress: String = ""
    var strengthDoors: String = ""
    var strengthBars: String = ""

    var dexterityReaction: String = ""
    var dexterityMissile: String = ""
    var dexterityDefense: String = ""

    var constitutionHP: String = ""
    var constitutionShock: String = ""
    var constitutionResurrection: String = ""
    var constitutionPoison: String = ""

    var intelligenceLanguages: String = ""
    var intelligenceMaxLevel: String = ""
    var intelligenceLearn: String = ""
    var intelligenceMaxPerLevel: String = ""

    var wisdomDefense: String = ""
    var wisdomFailure: String = ""
    /// Bônus de magia por círculo, como está escrito na tabela do livro:
    /// "+2 / +2 / +1" — círculo 1 ganha +2 slot(s), círculo 2 +2, círculo 3 +1.
    var wisdomBonusSpells: String = ""

    /// O bônus de um círculo específico, lido do texto livre acima. `0`
    /// quando o círculo não tem bônus (ou o texto não cobre esse círculo).
    ///
    /// SEM USO desde 2026-09-26: a grade real de slots
    /// (`PriestTables.spellProgression`) e o rótulo "(base+bônus)" da
    /// Priest Spell Sheet (`SpellSheetView.CircleBlock`) passaram a
    /// calcular direto de `WisdomTable.bonusSpellTotals`, em vez de ler
    /// este texto livre — que só é regravado quando o jogador muda a
    /// Sabedoria e aplica as consequências automáticas, então podia ficar
    /// em branco ou desatualizado sem nada perceber. Mantido aqui só como
    /// leitor auxiliar do campo de texto (que continua existindo, editável,
    /// só de referência na tabela de atributos), caso alguma tela futura
    /// precise do valor que o jogador digitou à mão ali.
    func wisdomBonus(forCircle level: Int) -> Int {
        let parts = wisdomBonusSpells
            .replacingOccurrences(of: " ", with: "")
            .split(separator: "/")
        guard level >= 1, level <= parts.count else { return 0 }
        let digits = parts[level - 1].filter { $0.isNumber }
        return Int(digits) ?? 0
    }

    var charismaHenchmen: String = ""
    var charismaLoyalty: String = ""
    var charismaReaction: String = ""

    // Três campos da ficha oficial que as folhas antigas não têm —
    // Optional pelo mesmo motivo do `WeaponEntry`/`CombatDetails` acima.
    var intelligenceSpellImmunity: String? = nil
    var wisdomSpellImmunity: String? = nil
    var constitutionRegen: String? = nil
}

/// As classes de personagem de AD&D 2e (livro do jogador). A classe decide
/// que ficha de magia a pasta abre — Clérigo (Priest Spell Sheet), Mago
/// (Wizard Spell Sheet, 2026-09-29) e Bardo (2026-09-30, reaproveitando a
/// mesma folha/livro do Mago — ver `isArcaneCaster`) têm a sua; Druida
/// (também conjurador divino) ainda não ganhou a dele.
enum CharacterClass: String, Codable, CaseIterable, Identifiable, Hashable {
    case fighter = "Fighter"
    case paladin = "Paladin"
    case ranger = "Ranger"
    case mage = "Mage"
    case cleric = "Cleric"
    case druid = "Druid"
    case thief = "Thief"
    case bard = "Bard"
    // Ninja (2026-09-30, Complete Ninja's Handbook) — diferente do
    // Barbarian (Kit de Fighter), o próprio livro trata ninja como CLASSE
    // própria do grupo Rogue: "The ninja character class, like the thief
    // and the bard classes, belongs to the rogue group", com Table 1
    // (XP/Hit Dice) idêntica à Table 25 do PHB (Rogue), mas requisitos de
    // habilidade, restrição racial e progressão de thieving skills
    // próprios. Usuário confirmou essa escolha (nova `CharacterClass` em
    // vez de forçar como Kit de Thief) antes de codar.
    case ninja = "Ninja"

    // Psionicist (2026-10-01, Complete Psionics Handbook cap. 1) — classe
    // própria do PHB/CPsiH, não um Kit de ninguém (igual ninja, diferente
    // de Barbarian). THAC0 (Table 7) e Hit Dice (Table 2, d6) batem
    // exatamente com o grupo Rogue, mas Saving Throws (Table 8) são
    // DIFERENTES do grupo Rogue de verdade (ex.: Rod/Staff/Wand 15 no
    // Rogue, 15 só nos primeiros 4 níveis mas diverge dali pra frente —
    // conferido linha a linha, ver `CoreClassGroup.psionicist`), e os
    // slots de proficiência (Table 10) são uma tabela própria, não
    // reaproveitando nenhum dos 4 arquétipos da Tabela 34 do PHB — por
    // isso ganha seu PRÓPRIO grupo em vez de entrar no Rogue, embora THAC0
    // calculado seja idêntico. PSP/known powers ficam em
    // `PlayerCharacter.psionicistKnownPowers`/`psionicistPSPMax`/
    // `psionicistPSPCurrent`/`psionicistDefenseModesKnown`.
    case psionicist = "Psionicist"

    var id: String { rawValue }

    /// Clérigo, Mago e Bardo têm folha de magias (2026-09-29: Mago ganhou a
    /// dele, espelhando o do Clérigo — ver `WizardTables`/`SpellSheetView`;
    /// 2026-09-30: Bardo entrou também, reaproveitando TUDO que já existia
    /// pro Mago — `wizardSpellbook`/`wizardSchool`/`WizardSpellbookEditorSheet`
    /// — em vez de duplicar, porque um personagem só tem uma classe de cada
    /// vez, então esses campos já significam "as magias arcanas que este
    /// personagem conhece", não "as magias do Mago especificamente". Ver
    /// `isArcaneCaster` e `BardTables`.)
    var hasSpellSheet: Bool { self == .cleric || self == .mage || self == .bard }

    /// `true` pra Mago e Bardo — as duas classes que lançam magia arcana
    /// (Inteligência, livro pessoal bloqueando o que pode ser memorizado).
    /// Centraliza o que antes era escrito como `== .mage` espalhado pelas
    /// views (`CharacterSheetView`, `SpellbookView`, `SpellSheetView`) — só
    /// o Bardo NÃO pode especializar em escola (`WizardSpellbookEditorSheet`
    /// esconde essa seção fora de `.mage`) nem ganha a semente de "Read
    /// Magic" (`seedWizardSpellbookIfNeeded` continua travada em `.mage`,
    /// de propósito: o PHB não garante nenhuma magia inicial pro bardo).
    var isArcaneCaster: Bool { self == .mage || self == .bard }

    /// Item 6 do feedback do usuário (2026-09-30): "não tem página de
    /// tabelas úteis pro Warrior". Generaliza a 4ª página (antes só pra
    /// quem tinha ficha de magia) pro grupo Warrior também — Fighter,
    /// Paladin e Ranger ganham `WarriorReferencePage` (Tabela 34 de slots
    /// de proficiência + Weapon Specialization) no lugar das tabelas de
    /// magia. Estendida no mesmo dia pro grupo Rogue (Thief/Bard/Ninja),
    /// que ganha `RogueReferencePage` (Thieving Skills + Backstab). Ver
    /// `proficiencyGroup` pra que classes entram em cada grupo.
    var hasReferencePage: Bool {
        hasSpellSheet || proficiencyGroup == "Warrior" || proficiencyGroup == "Rogue" || self == .psionicist
    }

    /// Thief, Bard e Ninja têm a seção "Thieving Skills" na página 1 da
    /// ficha (2026-09-30) — cada um com sua própria lista de habilidades e
    /// tabela-base (ver `ThievingSkillsTable`), mas a UI é compartilhada.
    var hasThievingSkills: Bool { proficiencyGroup == "Rogue" }

    /// Quantas páginas fixas a aba "Sheet" da ficha de personagem tem pra
    /// essa classe (`RecordSheetPagerView`/`RecordSheetBeadRow` em
    /// `CharacterSheetView.swift`) — Ficha + Equipment/Movement/Experience
    /// + Character Description pra todo mundo, mais uma 4ª página de
    /// tabelas de referência (do Clérigo, do Mago ou do Warrior, conforme a
    /// classe) só pra quem tem `hasReferencePage`. Centralizado aqui
    /// (2026-09-20) porque as duas views antes tinham cada uma sua própria
    /// conta solta — divergiram (`RecordSheetBeadRow` ficou um a menos que
    /// `RecordSheetPagerView`), e a página extra nunca ganhava bolinha
    /// própria por causa disso.
    var recordSheetPageCount: Int { hasReferencePage ? 4 : 3 }

    /// O grupo (Warrior/Wizard/Priest/Rogue) que esta classe pertence —
    /// mesmo rótulo de `Proficiency.primaryGroup` (2026-09-22, pedido do
    /// usuário: destacar no seletor de Proficiências o grupo "da classe do
    /// personagem"). "General" fica de fora — toda classe pode aprender
    /// proficiências gerais, então não é o grupo de NINGUÉM em particular.
    var proficiencyGroup: String {
        switch self {
        case .fighter, .paladin, .ranger: return "Warrior"
        case .mage: return "Wizard"
        case .cleric, .druid: return "Priest"
        case .thief, .bard, .ninja: return "Rogue"
        case .psionicist: return "Psionicist"
        }
    }

    /// O dado de Hit Dice de cada classe — coluna "Hit Dice" das tabelas
    /// de progressão de experiência do PHB, já conferidas em
    /// `ExperienceProgressionTable` (Table 14: Warrior Experience Levels →
    /// "Hit Dice (d10)"; Table 20: Wizard → "d4"; Table 23: Priest →
    /// "d8"; Table 25: Rogue → "d6"). Usado por
    /// `PlayerCharacter.refreshHitDiceType()` pra preencher o campo "Hit
    /// Dice" sozinho quando o jogador escolhe a classe (pedido do usuário,
    /// 2026-09-22: "deve entrar naquele motor", o mesmo de XP needed for
    /// the next level).
    var hitDieType: String {
        switch self {
        case .fighter, .paladin, .ranger: return "d10"
        case .mage: return "d4"
        case .cleric, .druid: return "d8"
        case .thief, .bard, .ninja: return "d6"
        // Psionicist (CPsiH Table 2: "Hit Dice (d6)") — mesmo dado do
        // grupo Rogue, mas listado explícito (não cai no `default`) pra
        // não depender de coincidência se o grupo Rogue mudar um dia.
        case .psionicist: return "d6"
        }
    }

    /// Fichas salvas antes da tradução da UI pra inglês guardavam o nome
    /// da classe em português (era o `rawValue` da época) — sem isso elas
    /// deixariam de decodificar e a pasta apareceria vazia. Continua
    /// aceitando o valor antigo na leitura; a próxima gravação já salva no
    /// valor novo em inglês.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        if let match = CharacterClass(rawValue: raw) {
            self = match
            return
        }
        switch raw {
        case "Guerreiro": self = .fighter
        case "Paladino": self = .paladin
        case "Patrulheiro": self = .ranger
        case "Mago": self = .mage
        case "Clérigo": self = .cleric
        case "Druida": self = .druid
        case "Ladino": self = .thief
        case "Bardo": self = .bard
        default: self = .fighter
        }
    }
}

/// Uma sessão de mesa — a data real em que ela aconteceu, não a data do
/// jogo. Cada folha de magia (`SpellSheet`) pertence a uma sessão através
/// de `sessionID`; a sessão em si só guarda o cabeçalho (data, título,
/// resumo), nunca as folhas — evita o mesmo tipo de binding aninhado que
/// já doeu com os slots.
struct Session: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    /// A data real da mesa — o dia em que vocês jogaram, não um dia dentro
    /// da história.
    var date: Date = Date()
    var title: String = ""
    var summary: String = ""
    /// Sessões encerradas somem da faixa de abas e da lista principal do
    /// índice, mas os dados continuam intactos — arquivar nunca apaga.
    var isArchived: Bool = false
}

/// Os dois tipos de folha do caderno: uma escrita com o Scribble do sistema
/// (vira texto de verdade, editável e pesquisável) e uma de desenho livre,
/// pra quem tem letra feia — ali é tinta pura, sem tentativa de transcrever.
enum NotebookPageKind: String, Codable {
    case transcribed
    case freeform
}

/// O papel de fundo de uma folha do caderno — pedido do usuário
/// (2026-09-24): "crie mais dois estilos de folha: pautada e quadriculada,
/// com a opção de trocar qual tipo de folha". `.plain` é o único que
/// existia até então (folha lisa, sem nada desenhado por trás do texto/
/// traço). O desenho de cada estilo mora em `NotebookPaperTexture`
/// (`Views/NotebookView.swift`) — este enum só guarda a ESCOLHA.
enum NotebookPaperStyle: String, Codable, CaseIterable {
    case plain
    case lined
    case grid

    var label: String {
        switch self {
        case .plain: return "Plain"
        case .lined: return "Lined"
        case .grid: return "Grid"
        }
    }
}

/// Uma folha livre do caderno de campanha — encontro com NPC, pista,
/// decisão do grupo. Sem seções fixas: só um título opcional, uma data e o
/// conteúdo, que é texto ou tinta dependendo do tipo da folha.
struct NotebookEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String = ""
    var text: String = ""

    /// Optional pelo mesmo motivo de sempre: folhas criadas antes desta
    /// versão não têm essa chave — ausência é tratada como `.transcribed`,
    /// que era o único tipo que existia até então.
    var kind: NotebookPageKind? = nil

    /// Traço de tinta serializado (PKDrawing.dataRepresentation()) — só
    /// usado quando kind == .freeform.
    var drawingData: Data? = nil

    /// Optional pelo mesmo motivo de sempre — folha criada antes desta
    /// versão não tem essa chave; ausência é tratada como `.plain` na hora
    /// de exibir (ver `NotebookPageView.style`), igual a como toda folha
    /// já era antes deste pedido existir. Cada folha guarda a PRÓPRIA
    /// escolha (pode trocar depois de criada, ver `NotebookBeadRow`'s
    /// picker no cabeçalho); só a folha NOVA nasce com o padrão configurado
    /// em Settings (`CharacterLibrary.defaultNotebookPaperStyle`, item 3).
    var paperStyle: NotebookPaperStyle? = nil
}

/// Uma campanha de mesa: dura meses ou anos, agrupa as sessões jogadas e o
/// caderno de anotações — ambos compartilhados por quem quer que esteja
/// jogando essa campanha, não mais presos a um personagem só (ver
/// `Session`/`NotebookEntry`, que moraram dentro de `PlayerCharacter` até
/// esta versão). Um personagem pertence a uma campanha, ou a nenhuma — ver
/// `PlayerCharacter.campaignID` — e mais de um personagem pode jogar a
/// mesma campanha ao mesmo tempo, inclusive compartilhando a mesma sessão.
struct Campaign: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    /// Quando a campanha começou de verdade — não precisa bater com a data
    /// da sessão mais antiga (a campanha pode ter sido criada bem antes da
    /// primeira mesa marcada, ex.: personagens preparados com um mês de
    /// antecedência).
    var startedDate: Date = Date()
    var notes: String = ""
    /// Encerrada (nunca apagada) — sai da lista principal, mas continua
    /// consultável, igual a uma sessão arquivada.
    var isArchived: Bool = false

    /// As sessões de mesa — cada uma agrupa um punhado de folhas de dia de
    /// um ou mais personagens.
    var sessions: [Session] = []

    /// Caderno de anotações livres da campanha — encontros com NPCs,
    /// pistas, decisões do grupo. Compartilhado por todo mundo que joga
    /// essa campanha, não mais um caderno por personagem.
    var notebookEntries: [NotebookEntry] = []

    /// Cenários de campanha ligados (ver `CampaignSettingCatalog`) — `nil`
    /// é o padrão (campanha nova, ou nunca mexeu nisso) e significa "sem
    /// filtro, mostra tudo", igual toda outra feature de sinalização deste
    /// app (esferas de acesso, etc.): nunca quebra campanha existente, só
    /// SOMA um filtro quando o jogador liga pelo menos um cenário. Um
    /// conjunto vazio (todos os cenários desligados na mão) tem o mesmo
    /// efeito de `nil` — só o conteúdo genérico/core apareceria, o que não
    /// faz sentido pra nenhuma mesa de verdade, então é tratado como "sem
    /// filtro" também (ver `allowsSetting`).
    var enabledSettings: Set<String>? = nil

    var displayTitle: String {
        name.isEmpty ? "Unnamed Campaign" : name
    }

    /// Verdadeiro quando `setting` deveria aparecer nas listas desta
    /// campanha — conteúdo genérico/core sempre aparece; o resto só
    /// aparece se a campanha não tiver filtro configurado, ou se tiver
    /// ligado esse cenário especificamente.
    func allowsSetting(_ setting: String?) -> Bool {
        if CampaignSettingCatalog.isGeneric(setting) { return true }
        guard let enabledSettings, !enabledSettings.isEmpty else { return true }
        guard let setting else { return true }
        return enabledSettings.contains(setting)
    }

    /// Mesma regra que `allowsSetting`, mas pra proficiências — que podem
    /// pertencer a mais de um cenário (`Proficiency.campaignSettings`):
    /// aparece se QUALQUER um dos cenários dela bater (união, não
    /// interseção — mesmo raciocínio do filtro por esfera do Grimório).
    func allowsAnySetting(_ settings: [String]) -> Bool {
        guard let enabledSettings, !enabledSettings.isEmpty else { return true }
        if settings.isEmpty { return true }
        if settings.contains(where: { CampaignSettingCatalog.isGeneric($0) }) { return true }
        return !Set(settings).isDisjoint(with: enabledSettings)
    }

    /// A sessão "ativa": a mais recente que não está arquivada. Se não
    /// existir nenhuma (campanha nova, ou todas encerradas), cria uma
    /// sozinha, datada de hoje.
    @discardableResult
    mutating func activeSession() -> Session {
        if let existing = sessions.filter({ !$0.isArchived }).max(by: { $0.date < $1.date }) {
            return existing
        }
        let created = Session(date: Date())
        sessions.append(created)
        return created
    }

    /// Cria uma folha nova no fim do caderno (mais recente) e devolve o id
    /// dela, pronto pra virar o `currentID` do pager. `paperStyle` nasce da
    /// preferência padrão configurada em Settings (item 3 do pedido de
    /// 2026-09-24) — parâmetro com default `.plain` só pra não quebrar
    /// nenhuma chamada antiga que não passe esse argumento.
    @discardableResult
    mutating func addNotebookPage(kind: NotebookPageKind, paperStyle: NotebookPaperStyle = .plain) -> UUID {
        var entry = NotebookEntry()
        entry.kind = kind
        entry.paperStyle = paperStyle
        notebookEntries.append(entry)
        return entry.id
    }
}

/// O estado de um personagem dentro de uma campanha — só "alive" aparece
/// no elenco por padrão; os outros dois ficam em seções recolhidas, nunca
/// somem de verdade (matar/aposentar nunca apaga dados).
enum CharacterStatus: String, Codable, CaseIterable {
    case alive
    case dead
    case archived
}

struct PlayerCharacter: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var playerName: String = ""
    var race: String = ""
    var characterClass: CharacterClass = .fighter
    var level: Int = 1
    var alignment: String = ""
    var deity: String = ""
    var sex: String = ""
    var age: String = ""
    var height: String = ""
    var weight: String = ""
    var hair: String = ""
    var eyes: String = ""

    // Campos novos da ficha oficial (PDF page 1) — Optional pelo mesmo
    // motivo do resto desta seção: fichas salvas antes desta versão não
    // têm essas chaves.
    var kit: String? = nil
    var placeOfOrigin: String? = nil
    var combat: CombatDetails? = nil
    var proficiencies: [ProficiencyEntry]? = nil
    /// Thieving Skills (2026-09-30, grupo Rogue) — ver `ThievingSkillEntry`
    /// e `CharacterClass.hasThievingSkills`. `nil`/vazio pra qualquer ficha
    /// de classe fora do grupo Rogue, ou salva antes desta versão.
    var thievingSkills: [ThievingSkillEntry]? = nil
    var toHitModifiers: [EquipmentItem]? = nil
    var damageModifiers: [EquipmentItem]? = nil
    var acModifiers: [EquipmentItem]? = nil
    var nonProficiencyPenalty: String? = nil

    /// Ajustes manuais da tabela "Target's AC / To Hit #", indexados pela
    /// CA alvo (10 a −10). Uma CA sem entrada aqui usa o valor calculado
    /// automaticamente a partir do THAC0 — ver `thac0TargetDisplay`.
    var thac0TargetOverrides: [Int: String]? = nil

    // Campos novos da página 4 do PDF oficial (Character Description) —
    // Optional pelo mesmo motivo do resto. `name`, `playerName`, `race`,
    // `alignment`, `deity`, `sex`, `age`, `height`, `weight`, `hair`,
    // `eyes` e `placeOfOrigin` (Origin) já existiam desde a página 1 e são
    // reaproveitados direto nesta página, sem duplicar dado.
    var birthDate: String? = nil
    var birthRank: String? = nil
    var nationality: String? = nil
    var racialAbilities: String? = nil
    var skin: String? = nil
    var vision: String? = nil
    var handedness: String? = nil
    var personality: String? = nil
    var hitPointsByLevel: String? = nil
    var backgroundHistory: String? = nil
    /// Retrato pro quadrado "Character Sketch" do PDF — enviado pelo
    /// jogador (upload de foto/desenho), não gerado pelo app. Guardado já
    /// redimensionado e comprimido em JPEG (ver `UIImage.resizedForSketch`
    /// em `CharacterDescriptionView.swift`) antes de chegar aqui, pro JSON
    /// da biblioteca não inchar com fotos em resolução de câmera.
    var portraitImageData: Data? = nil

    // Campos novos da página 2 do PDF oficial (Equipment/Movement/
    // Experience) — Optional pelo mesmo motivo do resto: fichas salvas
    // antes desta versão não têm essas chaves. `magicItems` e `experience`
    // já existiam e são reaproveitados aqui direto, sem duplicar dado.
    var page2Equipment: [Page2EquipmentEntry]? = nil
    var page2TotalWeight: String? = nil
    var page2EquipmentEncumbrance: String? = nil
    var page2MovementRate: String? = nil
    var page2Movement: MovementRates? = nil
    var page2EncumbranceTable: EncumbranceTable? = nil
    var xpNeededNextLevel: String? = nil

    /// Recalcula `xpNeededNextLevel` a partir de `ExperienceProgressionTable`
    /// (nível/classe atuais) e marca `recentAutoChange` pro `ChangeFlash`
    /// piscar da próxima vez que o campo aparecer. Método no MODELO (não só
    /// dentro de `ExperienceForm`) porque a página 2 da ficha vive dentro
    /// de um `UIPageViewController` (`RecordSheetPagerView`) que só
    /// atualiza a página VISÍVEL — mudar de nível/classe enquanto a página
    /// 1 está na tela não disparava o `onChange` de `ExperienceForm`
    /// (página 2, fora de vista, congelada) — bug relatado pelo usuário
    /// (2026-09-22): "ao subir ou descer de nível este campo não é
    /// atualizado". Chamado agora direto de onde nível/classe são editados
    /// (página 1), não só de dentro de `ExperienceForm`.
    mutating func refreshXPNeededNextLevel() {
        guard let text = ExperienceProgressionTable.xpNeededForNextLevel(
            currentLevel: level, class: characterClass
        ) else { return }
        guard xpNeededNextLevel != text else { return }
        xpNeededNextLevel = text
        markRecentAutoChange("xpNeededNextLevel")
    }

    /// Preenche `combat.hitDiceType` ("Hit Dice: __d__" na página 1, perto
    /// do THAC0) a partir de `CharacterClass.hitDieType` — mesmo "motor"
    /// de `refreshXPNeededNextLevel()`, pedido do usuário (2026-09-22).
    ///
    /// `force: true` (chamado de `ClassPicker.select`, na troca de
    /// classe): sempre resincroniza com a classe atual, igual o XP faz —
    /// bug relatado pelo usuário na v1.38 ("não tá refletindo ao trocar
    /// de classe"): a versão anterior só preenchia quando o campo estava
    /// vazio, então depois do primeiro preenchimento a troca de classe
    /// parava de atualizar o valor.
    ///
    /// `force: false` (padrão — chamado de `CombatForm.onAppear`, toda
    /// vez que a página aparece): só preenche quando o campo está VAZIO,
    /// nunca sobrescreve uma anotação que o jogador tenha escrito à mão —
    /// senão o safety net rodaria de novo a cada vez que a página
    /// aparecesse e apagaria qualquer texto customizado.
    mutating func refreshHitDiceType(force: Bool = false) {
        let expected = characterClass.hitDieType
        guard force || (combat?.hitDiceType ?? "").isEmpty else { return }
        guard combat?.hitDiceType != expected else { return }
        var updated = combat ?? CombatDetails()
        updated.hitDiceType = expected
        combat = updated
        markRecentAutoChange("hitDiceType")
    }

    var xpKitModifier: String? = nil
    var xpAbilityBonus: String? = nil
    var xpSubraceModifier: String? = nil
    var xpLevelLimit: String? = nil
    var levelChanges: LevelChangesTable? = nil
    /// Substituída por `page2MagicItems`/`page2TreasureItems` (com
    /// quantidade) — o campo antigo fica aqui só pra não quebrar a leitura
    /// de fichas salvas com ele, mas não é mais editado em lugar nenhum.
    var page2TreasureNotes: [String]? = nil
    var page2MagicItems: [QuantifiedItem]? = nil
    var page2TreasureItems: [QuantifiedItem]? = nil

    var movement: Int = 12
    var equipment: [EquipmentItem] = []
    var weapons: [WeaponEntry] = []
    var languages: [String] = []
    var magicItems: [String] = []
    var allies: [String] = []
    var treasure = Treasure()
    var details = AbilityDetails()

    var abilities = AbilityScores()
    var saves = SavingThrows()

    var hitPointsMax: Int = 6
    var hitPointsCurrent: Int = 6
    var armorClass: Int = 10
    var thac0: Int = 20

    var experience: Int = 0

    /// Armadura e escudo separados, porque a ficha oficial mostra a conta.
    var armorRating: String = ""
    var shieldRating: String = ""

    /// Uma folha de magias por dia de jogo. Os slots vivem aqui, não no
    /// personagem: eles zeram no repouso, e cada dia é uma folha nova.
    var spellSheets: [SpellSheet] = []

    /// Quantos slots de cada círculo o personagem tem por descanso — a
    /// tabela de memorização da classe, preenchida uma vez aqui na ficha.
    /// Toda folha de magia nova nasce a partir dela; não é editável dia a
    /// dia na própria folha, porque senão duas folhas do mesmo personagem
    /// discordariam sobre quantos slots ele tem.
    var spellSlotAllotments: [SpellSlotAllotment] = []

    /// A campanha a que este personagem pertence — `nil` quer dizer que ele
    /// está no Sandbox: já existe (atributos, equipamento, o que for), mas
    /// ainda não foi associado a nenhuma campanha de verdade. É a campanha,
    /// não mais o personagem, que possui as sessões de mesa e o caderno —
    /// ver `Campaign`.
    var campaignID: UUID? = nil

    /// Vivo, morto (mas consultável) ou aposentado sem ter morrido.
    var status: CharacterStatus = .alive

    /// Quando morreu, se for o caso — a data real da mesa, não uma data da
    /// história.
    var diedOn: Date? = nil
    /// Nota livre sobre a morte (ex.: "caiu pra um dragão vermelho perto de
    /// Elturel").
    var deathNote: String? = nil

    /// Se este personagem nasceu de "Clonar personagem", o id de quem foi
    /// clonado — só pra rastrear a linhagem; nada no app depende disso pra
    /// funcionar.
    var clonedFromCharacterID: UUID? = nil

    // MARK: - Motor de Consequências (2026-09-19)
    //
    // Retrato de nível/atributos na última vez que o jogador revisou (ou
    // dispensou) a janela de consequências — não é "o que a ficha tinha
    // quando foi criada", é "o que já foi visto". Comparado contra
    // `level`/`abilities` atuais pra decidir se o sinal "•" aparece perto
    // do nível (ver `RecordHeaderForm`/`ConsequenceEngine`). Optional pelo
    // mesmo motivo de sempre: uma ficha salva antes desta versão não tem
    // essas chaves — `ensureConsequenceSnapshotInitialized()` preenche
    // com o valor atual na primeira vez que a ficha abre, silenciosamente,
    // pra não fazer todo personagem já existente aparecer com o sinal
    // aceso do nada.
    var lastAppliedLevel: Int? = nil
    var lastAppliedAbilities: AbilityScores? = nil

    /// Qual campo foi editado por último, entre os que o motor de
    /// consequências acompanha ("level", "strength", "dexterity",
    /// "constitution", "intelligence", "wisdom", "charisma") — decide ONDE
    /// mostrar o sinal (ver `effectiveChangedField`). Setado pelas views
    /// (`RecordHeaderForm`/`AbilityScoresForm`, via `.onChange`) a cada
    /// edição de verdade, e zerado em `markConsequencesReviewed()`.
    ///
    /// Existe porque o usuário testou a versão anterior (um sinal por
    /// campo mudado, todos ao mesmo tempo) e achou pior: "o ícone fica
    /// replicando a cada ajuste". Pediu pra deixar só UM sinal ativo — o
    /// do último campo mexido — mas que ao tocar continue mostrando a
    /// SOMA de todos os ajustes pendentes (por isso `ConsequencePreviewSheet`
    /// continua comparando `lastAppliedRuleContext` inteiro contra
    /// `currentRuleContext`, sem filtrar por este campo).
    var lastChangedField: String? = nil

    // MARK: - Sinal de "mudou sozinho" (2026-09-22)
    //
    // Pedido do usuário ao ver o seletor de Raça aplicando ajustes de
    // atributo/resistência mágica sozinho na ficha: "dá pra deixar o novo
    // valor numa outra cor por alguns segundos? Assim fica claro pro
    // player o que mudou". Chaves aqui são o MESMO vocabulário de
    // `lastChangedField` ("strength", "dexterity" etc.) mais campos que
    // esse outro sinal não cobre ("spellResistance", "racialAbilities") —
    // guarda só "isso foi tocado por uma ação automática e ainda não foi
    // mostrado piscando"; `ChangeFlash` (`Views/ChangeFlash.swift`) lê e
    // consome (remove a chave) na primeira vez que aquele campo aparece
    // na tela, então cada mudança pisca uma única vez, mesmo que o campo
    // fique fora da aba visível por um tempo antes do jogador chegar lá.
    /// Não existe pra tudo que muda (edição manual do jogador não entra
    /// aqui) — só pra mudanças que o APP fez sozinho, feitas fora da
    /// visão do jogador naquele instante (ex.: escolher raça mexe em
    /// Força/Constituição na aba Sheet enquanto ele está na aba
    /// Description). Optional pelo mesmo motivo de sempre.
    var recentAutoChanges: Set<String>? = nil

    /// Marca `key` pra piscar na próxima vez que aparecer na tela.
    mutating func markRecentAutoChange(_ key: String) {
        recentAutoChanges = (recentAutoChanges ?? []).union([key])
    }

    /// `true` enquanto `key` ainda não piscou — consultado a cada render
    /// do campo (não é um evento único), então quem chama decide quando
    /// "consumir" com `clearRecentAutoChange`.
    func hasRecentAutoChange(_ key: String) -> Bool {
        recentAutoChanges?.contains(key) ?? false
    }

    /// Consome a marca — chamado pelo `ChangeFlash` depois de agendar a
    /// animação, pra não piscar de novo a cada re-render enquanto o
    /// campo continua visível.
    mutating func clearRecentAutoChange(_ key: String) {
        recentAutoChanges?.remove(key)
    }

    // MARK: - Efeitos Ativos (2026-09-28, revisado 2026-09-28)
    //
    // Ver `Models/ActiveEffect.swift` pro desenho geral (um `ActiveEffect`
    // é o "item" — nome/duração/notas — e carrega uma lista dinâmica de
    // `EffectComponent`, o mecanismo em si; um item pode ter mais de um
    // componente, ex. Recitation = bônus em To Hit + bônus em Saves).
    // Optional pelo mesmo motivo de sempre (fichas salvas antes desta
    // versão não têm essa chave).
    var activeEffects: [ActiveEffect]? = nil

    /// `true` quando existe pelo menos um efeito ativo — liga o brilho
    /// contínuo do ícone "✨" na fileira de abas (`SheetTabs`), pedido do
    /// usuário pra nunca esquecer um efeito ligado.
    var hasActiveEffects: Bool { !(activeEffects ?? []).isEmpty }

    /// Um componente `.attackNegation`, junto do item (`ActiveEffect`) a
    /// que pertence — usado só pela "pequena janela flutuante" na Ficha
    /// (pedido do usuário, 2026-09-29: "bônus de ataque negado deveria
    /// replicar o contador para a ficha do personagem"), pra não precisar
    /// abrir a aba de Efeitos Ativos só pra riscar um ataque anulado.
    struct ActiveAttackNegation: Identifiable {
        var id: UUID { component.id }
        var effectID: UUID
        var effectName: String
        var component: EffectComponent
    }

    var activeAttackNegations: [ActiveAttackNegation] {
        (activeEffects ?? []).flatMap { effect in
            effect.components
                .filter { $0.kind == .attackNegation }
                .map { ActiveAttackNegation(effectID: effect.id, effectName: effect.name, component: $0) }
        }
    }

    /// Ajusta o contador de UM `.attackNegation` sem passar pela tela de
    /// Efeitos Ativos — mesma escrita que `ActiveEffectCard.updateComponent`
    /// faz, só que endereçada por `effectID`/`componentID` em vez de
    /// receber o `ActiveEffect` inteiro (a janela flutuante não guarda
    /// isso, só os ids).
    mutating func adjustAttackNegation(effectID: UUID, componentID: UUID, by delta: Int) {
        guard var effects = activeEffects,
              let effectIndex = effects.firstIndex(where: { $0.id == effectID }),
              let componentIndex = effects[effectIndex].components.firstIndex(where: { $0.id == componentID })
        else { return }
        var component = effects[effectIndex].components[componentIndex]
        component.usedCount = min(max(component.usedCount + delta, 0), component.maxUses)
        effects[effectIndex].components[componentIndex] = component
        activeEffects = effects
    }

    mutating func addActiveEffect(_ effect: ActiveEffect) {
        activeEffects = (activeEffects ?? []) + [effect]
    }

    mutating func updateActiveEffect(_ effect: ActiveEffect) {
        guard var list = activeEffects,
              let index = list.firstIndex(where: { $0.id == effect.id }) else { return }
        list[index] = effect
        activeEffects = list
    }

    /// Bom (verde) ou ruim (vermelho)? Usado pelos campos afetados
    /// (Força, THAC0, CA, Saves...) pra ficarem tingidos ENQUANTO o
    /// efeito estiver ativo — pedido do usuário (2026-09-28): "todos os
    /// ajustes temporários devem permanecer na cor verde se bons ou
    /// vermelhos se ruins". Diferente do `ChangeFlash`, que só pisca uma
    /// vez e apaga, isto é consultado a cada redesenho do campo.
    enum EffectPolarity { case good, bad }

    /// Varre todos os componentes de todos os efeitos ativos procurando
    /// algum que mexa no campo `key` (mesmo vocabulário de
    /// `markRecentAutoChange`: "strength", "armorClass", "thac0",
    /// "savingThrows"). Quando mais de um componente mexe no mesmo campo,
    /// o mais recente decide a cor — raro (dois efeitos empilhados no
    /// mesmo lugar), mas nunca indefinido.
    func activeEffectPolarity(for key: String) -> EffectPolarity? {
        var found: EffectPolarity? = nil
        for effect in activeEffects ?? [] {
            for component in effect.components {
                switch component.kind {
                case .statOverride where component.overrideStat.changeFlashKey == key:
                    let better = component.overrideStat.lowerIsBetter
                        ? component.overrideValue < component.previousValue
                        : component.overrideValue > component.previousValue
                    found = better ? .good : .bad
                case .flatBonus where key == "thac0" && component.bonusTarget == .toHit:
                    // THAC0 menor é melhor — um bônus de To Hit REDUZ o
                    // THAC0 (ver `applyActiveEffect`), então um valor
                    // positivo aqui é bom.
                    found = component.bonusAmount >= 0 ? .good : .bad
                case .flatBonus where key == "armorClass" && component.bonusTarget == .armorClass:
                    found = component.bonusAmount >= 0 ? .good : .bad
                case .flatBonus where key == "savingThrows" && component.bonusTarget == .allSaves:
                    found = component.bonusAmount >= 0 ? .good : .bad
                default:
                    break
                }
            }
        }
        return found
    }

    /// Escreve o que o `effect` precisa na ficha de verdade — chamado
    /// pra CADA componente, na hora de criar (ou reaplicar, num "Save"
    /// de edição) um item. Recebe `inout` porque precisa guardar de
    /// volta o que foi feito (a linha inserida, o valor anterior) pra
    /// `revertActiveEffectApplication` saber desfazer exatamente aquilo,
    /// e nada mais, quando o efeito for encerrado.
    mutating func applyActiveEffect(_ effect: inout ActiveEffect) {
        for index in effect.components.indices {
            applyComponent(&effect.components[index], itemName: effect.name)
        }
    }

    private mutating func applyComponent(_ component: inout EffectComponent, itemName: String) {
        switch component.kind {
        case .flatBonus:
            switch component.bonusTarget {
            case .toHit:
                // "+N To Hit" na prática É "-N no THAC0" (número menor =
                // mais fácil de acertar) — o único jeito de um bônus de
                // acerto realmente REFLETIR em algum lugar da ficha, já
                // que não existe outro campo de "to hit" avulso.
                component.previousValue = thac0
                thac0 -= component.bonusAmount
                markRecentAutoChange("thac0")
            case .armorClass:
                // Mesma ideia: CA menor é melhor, então um bônus positivo
                // SUBTRAI do valor de Armor Class.
                component.previousValue = armorClass
                armorClass -= component.bonusAmount
                markRecentAutoChange("armorClass")
            case .allSaves:
                for entry in SavingThrows.labels where component.effectiveSaveIDs.contains(entry.id) {
                    saves.setModifier(saves.modifier(for: entry.id) + component.bonusAmount, for: entry.id)
                }
                markRecentAutoChange("savingThrows")
            case .damage:
                // Não existe um único "total de dano" na ficha (cada arma
                // tem sua própria linha) — o mais perto que dá de
                // "refletir" é uma linha na tabela Damage Modifiers, só
                // como lembrete de conferir na hora de rolar.
                let displayName = itemName.isEmpty ? "Effect" : itemName
                let noteText = component.bonusAmount >= 0 ? "+\(component.bonusAmount)" : "\(component.bonusAmount)"
                var row = EquipmentItem()
                row.name = displayName
                row.note = noteText
                damageModifiers = (damageModifiers ?? []) + [row]
                component.appliedDamageRowID = row.id
            }
        case .statOverride:
            switch component.overrideStat {
            case .strength:
                component.previousValue = abilities.strength
                abilities.strength = component.overrideValue
            case .dexterity:
                component.previousValue = abilities.dexterity
                abilities.dexterity = component.overrideValue
            case .constitution:
                component.previousValue = abilities.constitution
                abilities.constitution = component.overrideValue
            case .intelligence:
                component.previousValue = abilities.intelligence
                abilities.intelligence = component.overrideValue
            case .wisdom:
                component.previousValue = abilities.wisdom
                abilities.wisdom = component.overrideValue
            case .charisma:
                component.previousValue = abilities.charisma
                abilities.charisma = component.overrideValue
            case .armorClass:
                component.previousValue = armorClass
                armorClass = component.overrideValue
            case .thac0:
                component.previousValue = thac0
                thac0 = component.overrideValue
            }
            markRecentAutoChange(component.overrideStat.changeFlashKey)
        case .tempHP:
            // Some direto no PV atual (pedido do usuário, 2026-09-28: "o
            // personagem tem 30/30 e recebe 10 temp, deveria pular pra
            // 40/30") — sem contador visível separado; `tempHPRemaining`
            // só existe pra `applyDamage`/`revertActiveEffectApplication`
            // saberem quanto ainda não foi perdido.
            component.tempHPRemaining = component.tempHPGranted
            hitPointsCurrent += component.tempHPGranted
        case .attackNegation, .bankedHeal, .note:
            break
        }
    }

    /// Desfaz exatamente o que `applyActiveEffect` tiver escrito —
    /// chamado por `endActiveEffect` ao encerrar/descartar um efeito, e
    /// por um "Save" de edição antes de reaplicar com os novos valores.
    mutating func revertActiveEffectApplication(_ effect: ActiveEffect) {
        for component in effect.components {
            revertComponent(component)
        }
    }

    private mutating func revertComponent(_ component: EffectComponent) {
        switch component.kind {
        case .flatBonus:
            switch component.bonusTarget {
            case .toHit:
                thac0 = component.previousValue
                markRecentAutoChange("thac0")
            case .armorClass:
                armorClass = component.previousValue
                markRecentAutoChange("armorClass")
            case .allSaves:
                for entry in SavingThrows.labels where component.effectiveSaveIDs.contains(entry.id) {
                    saves.setModifier(saves.modifier(for: entry.id) - component.bonusAmount, for: entry.id)
                }
                markRecentAutoChange("savingThrows")
            case .damage:
                damageModifiers?.removeAll { $0.id == component.appliedDamageRowID }
            }
        case .statOverride:
            switch component.overrideStat {
            case .strength: abilities.strength = component.previousValue
            case .dexterity: abilities.dexterity = component.previousValue
            case .constitution: abilities.constitution = component.previousValue
            case .intelligence: abilities.intelligence = component.previousValue
            case .wisdom: abilities.wisdom = component.previousValue
            case .charisma: abilities.charisma = component.previousValue
            case .armorClass: armorClass = component.previousValue
            case .thac0: thac0 = component.previousValue
            }
            markRecentAutoChange(component.overrideStat.changeFlashKey)
        case .tempHP:
            // Só tira de volta o que ainda não foi perdido pra dano — o
            // que já foi consumido nunca é devolvido, mesmo encerrando o
            // efeito (é exatamente a regra "não pode ser curado").
            hitPointsCurrent -= component.tempHPRemaining
        case .attackNegation, .bankedHeal, .note:
            break
        }
    }

    /// Encerra um efeito — desfaz o que ele tiver aplicado na ficha e o
    /// remove da lista. É a única forma de remover um efeito (tanto o
    /// botão "End" quanto descartar um recém-criado passam por aqui), pra
    /// nunca deixar um bônus/substituição "grudado" na ficha depois que o
    /// cartão some.
    mutating func endActiveEffect(id: UUID) {
        guard let effect = activeEffects?.first(where: { $0.id == id }) else { return }
        revertActiveEffectApplication(effect)
        activeEffects?.removeAll { $0.id == id }
    }

    /// Salva a EDIÇÃO de um item já existente — pedido do usuário
    /// (2026-09-28): "falta opção de editar efeito salvo". Não é só
    /// "reverte tudo, aplica tudo de novo": isso funciona bem pra
    /// `.flatBonus`/`.statOverride` (o valor anterior é sempre recapturado
    /// do zero, então nunca empilha), mas faria um `.tempHP` em edição
    /// "curar de volta" o que já tinha sido perdido pra dano, só por
    /// trocar o nome do item — errado. Por isso compara componente por
    /// componente (pelo `id`, estável entre uma edição e outra) e só
    /// ajusta `.tempHP` pela DIFERENÇA entre o total antigo e o novo,
    /// preservando o que já foi consumido.
    mutating func saveEditedActiveEffect(replacing old: ActiveEffect, with newEffect: inout ActiveEffect) {
        let oldByID = Dictionary(uniqueKeysWithValues: old.components.map { ($0.id, $0) })
        let newIDs = Set(newEffect.components.map(\.id))

        // Componentes que saíram da lista na edição: desfaz por completo,
        // igual um "End" normal faria com eles.
        for oldComponent in old.components where !newIDs.contains(oldComponent.id) {
            revertComponent(oldComponent)
        }

        for index in newEffect.components.indices {
            let id = newEffect.components[index].id
            let previous = oldByID[id]
            // Desfaz o que esse MESMO componente (mesmo id) tinha
            // aplicado antes — cobre tanto "só mudou o valor" quanto
            // "trocou de mecanismo no meio da edição" (`revertComponent`
            // olha o `kind` do valor antigo, não do novo).
            if let previous {
                revertComponent(previous)
            }
            switch newEffect.components[index].kind {
            case .flatBonus, .statOverride:
                applyComponent(&newEffect.components[index], itemName: newEffect.name)
            case .tempHP:
                let previousRemaining = (previous?.kind == .tempHP) ? previous!.tempHPRemaining : 0
                let previousGranted = (previous?.kind == .tempHP) ? previous!.tempHPGranted : 0
                let delta = newEffect.components[index].tempHPGranted - previousGranted
                let newRemaining = max(0, min(newEffect.components[index].tempHPGranted, previousRemaining + delta))
                newEffect.components[index].tempHPRemaining = newRemaining
                hitPointsCurrent += newRemaining
            case .attackNegation, .bankedHeal, .note:
                break
            }
        }
    }

    /// Ponto único por onde todo dano "de verdade" passa (chamado por
    /// `WoundsBlock.commit`, em vez de mexer direto em
    /// `hitPointsCurrent`) — pra poder interceptar os efeitos ativos que
    /// reagem a dano, pedidos do usuário (2026-09-28):
    ///   - PV temporário (`.tempHP`): já está somado em `hitPointsCurrent`
    ///     desde a ativação (ver `applyComponent`) — aqui só desconta o
    ///     bookkeeping de `tempHPRemaining` na mesma proporção, pra saber
    ///     quanto ainda não foi perdido (o que SOBRAR quando o efeito
    ///     acabar é descontado de novo; o que já foi perdido aqui nunca
    ///     volta).
    ///   - Regenerate pendente (`.bankedHeal`, ainda `healIsBanked`): o
    ///     primeiro dano recebido dispara a cura (vira `healIsBanked =
    ///     false`; a partir daí quem cura 1/round é o jogador, tocando o
    ///     contador do cartão do efeito).
    /// `amount` negativo (jogador digitou um número negativo na caixa de
    /// Wounds) continua se comportando como sempre — cura direta, sem
    /// passar por nenhum efeito, já que não é dano de verdade.
    mutating func applyDamage(_ amount: Int) {
        guard amount > 0 else {
            hitPointsCurrent -= amount
            return
        }
        // O PV temporário já foi somado a `hitPointsCurrent` na hora de
        // ativar o efeito (ver `applyComponent`/item 10) — então o dano
        // INTEIRO sempre sai de `hitPointsCurrent` aqui; este loop só
        // atualiza o "quanto ainda resta" (`tempHPRemaining`) de cada
        // componente `.tempHP` pra bookkeeping (saber quanto devolver se o
        // efeito for encerrado antes de todo consumido) — ele NUNCA reduz
        // o quanto é descontado do PV atual, ou o dano seria subcontado.
        var toAccount = amount
        if var effects = activeEffects {
            for effectIndex in effects.indices {
                for componentIndex in effects[effectIndex].components.indices {
                    guard effects[effectIndex].components[componentIndex].kind == .tempHP,
                          effects[effectIndex].components[componentIndex].tempHPRemaining > 0 else { continue }
                    let pool = effects[effectIndex].components[componentIndex].tempHPRemaining
                    let consumed = min(toAccount, pool)
                    effects[effectIndex].components[componentIndex].tempHPRemaining -= consumed
                    toAccount -= consumed
                    if toAccount == 0 { break }
                }
                if toAccount == 0 { break }
            }
            for effectIndex in effects.indices {
                for componentIndex in effects[effectIndex].components.indices
                where effects[effectIndex].components[componentIndex].kind == .bankedHeal
                    && effects[effectIndex].components[componentIndex].healIsBanked {
                    effects[effectIndex].components[componentIndex].healIsBanked = false
                }
            }
            activeEffects = effects
        }
        hitPointsCurrent -= amount
    }

    /// `true` quando nível ou atributos mudaram desde a última revisão —
    /// liga o sinal "•" no cabeçalho da ficha.
    var hasPendingConsequences: Bool {
        guard let lastAppliedLevel, let lastAppliedAbilities else { return false }
        return lastAppliedLevel != level || lastAppliedAbilities != abilities
    }

    /// `true` só quando o NÍVEL mudou desde a última revisão.
    var hasPendingLevelChange: Bool {
        guard let lastAppliedLevel else { return false }
        return lastAppliedLevel != level
    }

    /// Mesma ideia de `hasPendingLevelChange`, mas por ATRIBUTO.
    func hasPendingAbilityChange(_ keyPath: KeyPath<AbilityScores, Int>) -> Bool {
        guard let lastAppliedAbilities else { return false }
        return lastAppliedAbilities[keyPath: keyPath] != abilities[keyPath: keyPath]
    }

    /// Versão ESCOPADA de `hasPendingConsequences`, pros realces que ficam
    /// em cima de uma seção específica (`PendingConsequenceHighlight` em
    /// "Saving Throws" e "THAC0" — item 1 do pedido do usuário, 2026-09-24:
    /// mudar WIS não deveria acender o realce do THAC0, já que WIS não
    /// afeta o THAC0). `hasPendingConsequences` (acima) continua global de
    /// propósito — é o que liga o sinal único do cabeçalho
    /// (`ConsequenceSignalBadge`), que precisa acender pra QUALQUER
    /// mudança pendente, não só pras rastreadas por chave.
    ///
    /// Só reaproveita `ConsequenceEngine.diff` (a mesma conta que
    /// `ConsequencePreviewSheet` já faz) e filtra pelas `keys` da regra —
    /// ex. `["thac0"]` pro campo de THAC0, `["savingThrows"]` pra Saving
    /// Throws. `false` sem `lastAppliedRuleContext` (ficha ainda sem
    /// snapshot inicial), igual ao comportamento de `hasPendingConsequences`.
    func hasPendingConsequence(forKeys keys: Set<String>, registry: RulesetRegistry) -> Bool {
        guard let old = lastAppliedRuleContext else { return false }
        let items = ConsequenceEngine.diff(old: old, new: currentRuleContext, registry: registry)
        return items.contains { keys.contains($0.id) }
    }

    /// Qual campo deve mostrar o sinal de consequência agora — só UM de
    /// cada vez, nunca vários simultâneos (ver `lastChangedField` acima).
    /// Usa `lastChangedField` quando ele bate com alguma mudança ainda
    /// pendente; se não houver (ficha salva antes deste campo existir, com
    /// uma mudança pendente "órfã" — sem edição rastreada desde então),
    /// cai num fallback previsível (nível primeiro, depois cada atributo
    /// em ordem) em vez de simplesmente não mostrar sinal nenhum.
    var effectiveChangedField: String? {
        guard hasPendingConsequences else { return nil }
        if let lastChangedField, isPendingChange(forField: lastChangedField) {
            return lastChangedField
        }
        if hasPendingLevelChange { return "level" }
        if hasPendingAbilityChange(\.strength) { return "strength" }
        if hasPendingAbilityChange(\.dexterity) { return "dexterity" }
        if hasPendingAbilityChange(\.constitution) { return "constitution" }
        if hasPendingAbilityChange(\.intelligence) { return "intelligence" }
        if hasPendingAbilityChange(\.wisdom) { return "wisdom" }
        if hasPendingAbilityChange(\.charisma) { return "charisma" }
        return nil
    }

    /// Auxiliar de `effectiveChangedField`: o campo nomeado ainda tem uma
    /// mudança pendente de verdade? (evita apontar pro último campo
    /// editado se essa mudança específica já foi revisada por algum outro
    /// caminho, mas outras continuam pendentes.)
    private func isPendingChange(forField field: String) -> Bool {
        switch field {
        case "level": return hasPendingLevelChange
        case "strength": return hasPendingAbilityChange(\.strength)
        case "dexterity": return hasPendingAbilityChange(\.dexterity)
        case "constitution": return hasPendingAbilityChange(\.constitution)
        case "intelligence": return hasPendingAbilityChange(\.intelligence)
        case "wisdom": return hasPendingAbilityChange(\.wisdom)
        case "charisma": return hasPendingAbilityChange(\.charisma)
        default: return false
        }
    }

    /// Retrato "antes" pro `ConsequenceEngine.diff` — `nil` só na primeira
    /// abertura de uma ficha antiga, antes do snapshot inicial rodar.
    var lastAppliedRuleContext: RuleContext? {
        guard let lastAppliedLevel, let lastAppliedAbilities else { return nil }
        return RuleContext(level: lastAppliedLevel, characterClass: characterClass, abilities: lastAppliedAbilities)
    }

    /// Retrato "agora" pro `ConsequenceEngine.diff`.
    var currentRuleContext: RuleContext {
        RuleContext(level: level, characterClass: characterClass, abilities: abilities)
    }

    /// Chamado ao abrir a ficha (`.onAppear`). Só preenche o snapshot
    /// quando ainda não existe (ficha nova, ou salva antes desta versão) —
    /// sem marcar consequência nenhuma pra trás: só a partir daqui uma
    /// mudança de nível/atributo liga o sinal. Chamar de novo depois que
    /// já existe não faz nada (por isso é seguro repetir a cada
    /// `.onAppear`, sem apagar uma consequência pendente de verdade).
    mutating func ensureConsequenceSnapshotInitialized() {
        guard lastAppliedLevel == nil, lastAppliedAbilities == nil else { return }
        markConsequencesReviewed()
    }

    /// "Zera" o sinal: o snapshot passa a valer o nível/atributos atuais.
    /// Chamado depois que o jogador revisou a janela de consequências
    /// (aplicou as automáticas, ou fechou tendo visto) — ao contrário de
    /// `ensureConsequenceSnapshotInitialized()`, sempre sobrescreve.
    mutating func markConsequencesReviewed() {
        lastAppliedLevel = level
        lastAppliedAbilities = abilities
        lastChangedField = nil
    }

    /// LEGADO (2026-09-19): favoritar deixou de ser por personagem e virou
    /// preferência global do jogador — ver `CharacterLibrary.favoriteSpellIDs`.
    /// Este campo continua aqui só pra migrar fichas salvas ANTES da troca
    /// (`CharacterLibrary.load()` junta os favoritos de todo personagem num
    /// conjunto só, uma vez); nada escreve nele de novo, e nenhuma tela lê
    /// dele — todo mundo passou a consultar a biblioteca.
    var favoriteSpellIDs: Set<String> = []

    /// Quantos slots de cada círculo o personagem tem por descanso, calculado
    /// pela Priest Spell Progression (Tabela 24) pro Clérigo ou pela Wizard
    /// Spell Progression (Tabela 21) pro Mago, a partir do nível e da
    /// Sabedoria/Inteligência atuais — substitui a antiga entrada manual
    /// (`spellSlotAllotments`, mantida só pra fichas salvas antigas
    /// continuarem decodificando) que morava na aba Equipment.
    var computedSpellSlotAllotments: [SpellSlotAllotment] {
        switch characterClass {
        case .cleric:
            let counts = PriestTables.spellProgression(level: level, wisdom: abilities.wisdom)
            return counts.enumerated().compactMap { index, count in
                guard count > 0 else { return nil }
                return SpellSlotAllotment(caster: .divine, level: index + 1, count: count)
            }
        case .mage:
            let counts = WizardTables.spellProgression(level: level, intelligence: abilities.intelligence)
            // Table 22: quem se especializou numa escola ganha +1 slot em
            // todo círculo onde já tem magia (não cria círculo novo do
            // nada) — o PHB pede que esse slot extra seja preenchido com
            // magia da própria escola, mas o app não tem como forçar isso
            // no board de slots (genérico por círculo, não por escola);
            // fica como lembrete pro jogador, não uma trava.
            let bonus = wizardSchool == nil ? 0 : 1
            return counts.enumerated().compactMap { index, count in
                guard count > 0 else { return nil }
                return SpellSlotAllotment(caster: .arcane, level: index + 1, count: count + bonus)
            }
        case .bard:
            // Table 32, sem bônus de especialização — o bardo nunca pode
            // especializar em escola (ver doc de `BardTables` acima).
            let counts = BardTables.spellProgression(level: level, intelligence: abilities.intelligence)
            return counts.enumerated().compactMap { index, count in
                guard count > 0 else { return nil }
                return SpellSlotAllotment(caster: .arcane, level: index + 1, count: count)
            }
        default:
            return []
        }
    }

    /// A pontuação de atributo que decide os slots de magia desta classe —
    /// Sabedoria pro Clérigo, Inteligência pro Mago e pro Bardo (os dois
    /// lançam magia arcana — ver `CharacterClass.isArcaneCaster`). Usada só
    /// pra congelar o valor certo em `SpellSheet.wisdomAtCreation` na hora
    /// de criar uma folha nova (o nome do campo ficou o de sempre,
    /// "wisdomAtCreation" — trocar o NOME da propriedade mudaria a chave
    /// usada pelo `Codable` sintetizado, e uma folha de Clérigo salva antes
    /// desta versão pararia de decodificar por causa exatamente do mesmo
    /// tipo de bug documentado em `Spell.init(from:)`; então o campo
    /// continua se chamando Wisdom, só passa a guardar Inteligência quando
    /// a classe lança magia arcana).
    var spellSheetAbilityScoreAtCreation: Int {
        characterClass.isArcaneCaster ? abilities.intelligence : abilities.wisdom
    }

    /// Uma grade de slots em branco (sem nada preparado ainda), do
    /// tamanho que a Priest Spell Progression diz que o personagem tem hoje.
    func freshSlotBoard() -> SpellSlotBoard {
        var board = SpellSlotBoard()
        for allotment in computedSpellSlotAllotments where allotment.count > 0 {
            board.setCount(allotment.count, level: allotment.level, caster: allotment.caster)
        }
        return board
    }

    /// Esferas de acesso (TODO.md item 16) — `nil`/vazio até o jogador
    /// preencher pela primeira vez (nenhuma ficha antiga tem essa chave).
    /// Guardado como dicionário esfera→nível em vez de dois `Set`s
    /// separados porque uma esfera só pode ter UM nível por personagem —
    /// o dicionário já impede o estado inválido "maior E menor ao mesmo
    /// tempo" que dois conjuntos permitiriam sem checagem extra.
    var sphereAccess: [String: SphereAccessLevel]? = nil

    /// Wild Talent (CPsiH, "fundação primeiro" dos Psiônicos, 2026-10-01)
    /// — `nil` até o jogador registrar um (toda ficha de antes desta
    /// versão não tem essa chave). Disponível pra QUALQUER classe, ao
    /// contrário de `sphereAccess`/`kit` — ver `WildTalent`.
    var wildTalent: WildTalent? = nil

    /// Poderes/PSP de um Psionicist de VERDADE (`characterClass ==
    /// .psionicist`) — 4 campos PLANOS (2026-10-02; ver o comentário
    /// grande acima do antigo `PsionicistPowers`, removido) em vez de uma
    /// struct só, exatamente pelo motivo descrito ali: struct opcional com
    /// array de outra struct por dentro era o que estourava o build.
    /// Separado de `wildTalent` de propósito: as duas coisas podem, em
    /// teoria, coexistir (um personagem troca de classe), e cada uma tem
    /// sua própria filosofia de limite (Wild Talent nunca ganha Attack/
    /// Defense Modes, Psionicist sim).
    var psionicistKnownPowers: [PsionicPowerEntry] = []
    /// Nomes dos 5 Defense Modes (Mind Blank/Thought Shield/Mental
    /// Barrier/Tower of Iron Will/Intellect Fortress) que o personagem já
    /// escolheu — ganhos automaticamente nos níveis 1, 3, 5, 7 e 9 (CPsiH,
    /// "Defense Modes"). Guardado separado de `psionicistKnownPowers`
    /// porque o livro é explícito: "Defense modes do not count toward the
    /// psionicist's maximum number of powers" (Table 4) — misturar as
    /// duas listas destruiria essa distinção.
    var psionicistDefenseModesKnown: [String] = []
    var psionicistPSPMax: Int = 0
    var psionicistPSPCurrent: Int = 0

    /// Ids da base que estão nos poderes conhecidos do Psionicist — mesmo
    /// padrão de `wizardSpellbookMatchedIDs`, usado pra marcar "já
    /// conhecido" no buscador (`PsionicPowerPickerSheet`) e evitar
    /// duplicata.
    var psionicistKnownPowerMatchedIDs: Set<String> {
        Set(psionicistKnownPowers.compactMap { $0.matchedPowerID })
    }

    /// `nil` quando a esfera não está marcada (nem maior nem menor) — o
    /// mesmo "sem preferência" de antes de o jogador mexer em nada.
    func sphereAccessLevel(for sphere: String) -> SphereAccessLevel? {
        sphereAccess?[sphere]
    }

    /// Só pra decidir se vale ordenar/sinalizar a lista de candidatos por
    /// esfera (`SlotEditorSheet`/`MemorizedRow` em `SpellSheetView.swift`)
    /// — personagem que nunca abriu o editor de esferas não deve ter a
    /// lista reordenada "sem querer" a partir de um mapa vazio.
    var hasConfiguredSphereAccess: Bool {
        !(sphereAccess?.isEmpty ?? true)
    }

    /// `true` quando QUALQUER esfera da magia está marcada (maior ou
    /// menor) — usado só pra ordenar/sinalizar, nunca pra esconder uma
    /// magia (decisão do usuário: o filtro de esferas não bloqueia).
    func hasSphereAccess(to spheres: [String]) -> Bool {
        guard let sphereAccess, !sphereAccess.isEmpty else { return false }
        return spheres.contains { sphereAccess[$0] != nil }
    }

    /// `true` quando ALGUMA esfera da magia está marcada como MAIOR —
    /// critério de ordenação mais forte que `hasSphereAccess(to:)` (TODO.md
    /// item 16, pedido do usuário 2026-09-20): acesso maior conjura em
    /// qualquer círculo, então é a aposta mais segura pra pôr no topo da
    /// lista, antes até de uma esfera marcada só como Menor (que trava no
    /// 3º círculo — ver `sphereSignal(for:)`). Só ordena, nunca esconde.
    func hasMajorSphereAccess(to spheres: [String]) -> Bool {
        spheres.contains { sphereAccessLevel(for: $0) == .major }
    }

    /// Aviso pra um candidato de magia na Folha de Magias (TODO.md item
    /// 16) — sempre só um SINAL, nunca um filtro. Centralizado aqui (em
    /// vez de duas versões quase iguais em `MemorizedRow`/`SlotEditorSheet`
    /// de `SpellSheetView.swift`) pra não arriscar as duas divergirem.
    func sphereSignal(for spell: Spell) -> SphereSignal? {
        guard hasConfiguredSphereAccess, !spell.spheres.isEmpty else { return nil }
        let matchedLevels = spell.spheres.compactMap { sphereAccessLevel(for: $0) }
        guard !matchedLevels.isEmpty else { return .outsideSpheres }
        // Tem a esfera, mas só como MENOR (regra do PHB: acesso menor
        // trava no 3º círculo) — se NENHUMA das esferas batidas for MAIOR
        // e a magia passa do 3º círculo, ela está fora do alcance mecânico
        // do personagem mesmo "tendo" a esfera.
        if spell.level > 3, !matchedLevels.contains(.major) {
            return .minorCircleCap
        }
        return nil
    }

    /// Prioridade de ordenação por esfera (TODO.md item 16, retocado
    /// 2026-09-20 — print do usuário mostrou o bug): antes o critério de
    /// ORDENAR (`hasMajorSphereAccess`) e o de AVISAR (`sphereSignal`) eram
    /// dois critérios DIFERENTES — uma magia com esfera Menor mas dentro do
    /// 3º círculo não mostrava aviso nenhum (`sphereSignal == nil`), mas
    /// também não contava como "esfera maior" pra ordenação, então ficava
    /// no mesmo grupo (sem prioridade) que uma magia de fato fora de
    /// qualquer esfera — resultado: magias SEM aviso apareciam espalhadas
    /// no meio de magias COM aviso, em vez de todas agrupadas no topo.
    /// Agora os dois usam a MESMA régua: 0 = esfera maior batida (aposta
    /// mais segura, vai pro topo), 1 = sem aviso nenhum (esfera menor
    /// dentro do alcance, ou magia sem `spheres` pra comparar — nem favor
    /// nem contra), 2 = com aviso (`sphereSignal` não é `nil`) — essas
    /// afundam TODAS juntas pro fim da lista. Devolve `1` (neutro, sem
    /// reordenar nada) quando o personagem não configurou esferas.
    func sphereSortRank(for spell: Spell) -> Int {
        guard hasConfiguredSphereAccess else { return 1 }
        if hasMajorSphereAccess(to: spell.spheres) { return 0 }
        return sphereSignal(for: spell) == nil ? 1 : 2
    }

    // MARK: - Livro de magias do Mago (2026-09-29)
    //
    // Diferente do Clérigo (que conjura qualquer magia da esfera que tem
    // acesso, sem precisar "aprender" nada — `sphereAccess` acima é só um
    // SINAL, nunca bloqueia), o Mago só pode memorizar magias que estão no
    // PRÓPRIO livro. Decisão do usuário (2026-09-29): bloqueio de verdade
    // (não só aviso), lista editável simples (sem simular rolagem de
    // "chance to learn" — mesma filosofia de nunca rolar dado sozinho que
    // o app já segue pra Hit Points), e um Mago novo nasce com "Read
    // Magic" no livro (regra do PHB: todo mago começa com essa magia).

    /// `wizardSpellbook` fica no `PlayerCharacter` (não na Folha de
    /// Magias) pelo mesmo motivo de `sphereAccess`: é um traço PERMANENTE
    /// do personagem, não algo que só existe enquanto o dia de jogo dura.
    var wizardSpellbook: [WizardSpellbookEntry] = []

    /// Especialização de escola (2026-09-30, Table 22) — `nil` é
    /// generalista (comportamento de sempre: nenhum bônus, nenhuma
    /// restrição). Fica opcional/`nil` de propósito pra fichas antigas
    /// (Mago criado antes desta versão) continuarem decodificando sem
    /// ficar preso a uma escola que nunca escolheu.
    var wizardSchool: WizardSchool? = nil

    /// `true` quando a magia tem uma escola LISTADA em `spell.schools`
    /// que está na lista de oposição da especialização atual — bloqueio
    /// de verdade (mesma filosofia do livro de magias em si), não sinal.
    /// Generalista (`wizardSchool == nil`) nunca bloqueia nada. Magias
    /// marcadas "All"/"All Schools" na base (ex.: Read Magic, Detect
    /// Magic) são universais — nunca ficam de fora, mesmo se a lista de
    /// oposição citar a escola que também aparece nelas.
    func isSpellOpposedBySchool(_ spell: Spell) -> Bool {
        guard let wizardSchool else { return false }
        guard !spell.schools.contains("All") && !spell.schools.contains("All Schools") else { return false }
        let opposed = Set(wizardSchool.oppositionSchools.map(\.rawValue))
        return !opposed.isDisjoint(with: Set(spell.schools))
    }

    /// Ids da base que estão no livro — usado pra restringir de verdade a
    /// Folha de Magias (`SlotEditorSheet`/`MemorizedRow` em
    /// `SpellSheetView.swift`) e pra `SpellDatabase.matches(restrictToIDs:)`.
    var wizardSpellbookMatchedIDs: Set<String> {
        Set(wizardSpellbook.compactMap { $0.matchedSpellID })
    }

    /// `true` quando esta magia está no livro (por id da base) — usado
    /// pelo Grimório pra mostrar o selo de "no seu livro" e decidir se o
    /// botão ali é "add" ou "remove".
    func wizardKnows(spellID: String) -> Bool {
        wizardSpellbookMatchedIDs.contains(spellID)
    }

    /// Magias do círculo dado que estão no livro E batem com a base — a
    /// lista que a Folha de Magias mostra pra escolher, em vez da base
    /// inteira (~2.600 magias) que o Clérigo vê. `in spellbook:` é a
    /// mesma instância de `SpellDatabase` injetada como `@EnvironmentObject`
    /// nas views — fica de fora do `PlayerCharacter` (que não tem acesso a
    /// ela) só recebida como parâmetro.
    func wizardSpellbookSpells(level: Int, in spellbook: SpellDatabase) -> [Spell] {
        let ids = wizardSpellbookMatchedIDs
        guard !ids.isEmpty else { return [] }
        return spellbook.spells(caster: .arcane, level: level).filter { ids.contains($0.id) }
    }

    /// Entradas do livro que NÃO batem com a base (magia homebrew, ou
    /// achada num pergaminho/livro em jogo sem entrada na base embutida) —
    /// mostradas por nome livre, sem descrição completa disponível. O
    /// círculo vem do campo `level` da própria entrada (só existe pra
    /// quem não bate com a base — ver `WizardSpellbookEntry`).
    func wizardSpellbookFreeNames(level: Int) -> [WizardSpellbookEntry] {
        wizardSpellbook
            .filter { $0.matchedSpellID == nil && $0.level == level }
            .sorted { $0.name < $1.name }
    }

    /// Semeia "Read Magic" a primeira vez que o personagem vira Mago —
    /// nunca sobrescreve um livro que já tem algo (nem repete a entrada se
    /// já tiver sido removida de propósito e o jogador trocar de classe e
    /// voltar pra Mago — checagem é só "vazio", não "nunca chamado antes").
    /// Chamado do mesmo lugar que já semeava a primeira Folha de Magias
    /// (`CharacterSheetView.ClassPicker`, ao escolher Mago no cabeçalho).
    /// `in spellbook:` deixa a entrada casada com a base de verdade quando
    /// "Read Magic" existir lá (descrição completa disponível), em vez de
    /// sempre cair no nome livre.
    mutating func seedWizardSpellbookIfNeeded(in spellbook: SpellDatabase) {
        guard characterClass == .mage, wizardSpellbook.isEmpty else { return }
        let matched = spellbook.spells(caster: .arcane, level: 1)
            .first { Fuzzy.normalize($0.name) == Fuzzy.normalize("Read Magic") }
        wizardSpellbook = [WizardSpellbookEntry(name: matched?.name ?? "Read Magic",
                                                matchedSpellID: matched?.id,
                                                level: matched == nil ? 1 : nil)]
    }

    /// O maior círculo que o Mago já consegue LANÇAR agora, nível e
    /// Inteligência atuais (mesma tabela de `computedSpellSlotAllotments` —
    /// um círculo só entra aqui se tiver pelo menos 1 slot). Pedido do
    /// usuário (2026-09-30): restringe quais círculos aparecem pra
    /// ADICIONAR magia ao livro — tanto na busca da folha "My Spellbook"
    /// quanto no botão de adicionar direto do Grimório (`SpellbookView`) —
    /// não faz sentido oferecer aprender um círculo que ainda nem dá pra
    /// lançar. `0` pra quem não é Mago, ou pro Mago que ainda não tem
    /// slot nenhum (nível 1 sem Inteligência suficiente, por exemplo).
    var wizardMaxKnowableCircle: Int {
        computedSpellSlotAllotments.filter { $0.caster == .arcane }.map(\.level).max() ?? 0
    }

    /// Folhas em ordem, da mais recente para a mais antiga.
    var sortedSpellSheets: [SpellSheet] {
        spellSheets.sorted { $0.date > $1.date }
    }

    /// A folha do dia em andamento — a última criada.
    var currentSheetIndex: Int? {
        guard !spellSheets.isEmpty else { return nil }
        var newestIndex = 0
        for index in spellSheets.indices where spellSheets[index].date > spellSheets[newestIndex].date {
            newestIndex = index
        }
        return newestIndex
    }

    /// Quantas vezes cada magia apareceu memorizada em alguma folha deste
    /// personagem — usado pra ordenar por "mais usada" sem precisar de um
    /// contador dedicado (ver TODO.md item 3).
    func spellUsageCounts() -> [String: Int] {
        var counts: [String: Int] = [:]
        for sheet in spellSheets {
            for slot in sheet.slotBoard.slots {
                guard let id = slot.preparedSpellID else { continue }
                counts[id, default: 0] += 1
            }
        }
        return counts
    }

    var displayTitle: String {
        name.isEmpty ? "Unnamed Character" : name
    }

    var displaySubtitle: String {
        let parts = [race, characterClass.rawValue].filter { !$0.isEmpty }
        let base = parts.joined(separator: " ")
        return base.isEmpty ? "Level \(level)" : "\(base) — level \(level)"
    }

    // MARK: - Tabela "Target's AC / To Hit #"

    /// As 21 CAs-alvo mostradas na ficha oficial, de 10 até −10.
    static let thac0TargetACs: [Int] = Array(stride(from: 10, through: -10, by: -1))

    /// O número de ataque calculado pela regra pura: THAC0 − CA alvo.
    func thac0AutoTarget(ac: Int) -> Int { thac0 - ac }

    /// O que a célula mostra: o ajuste manual, se houver um escrito por
    /// cima (bônus situacional), senão o valor calculado.
    func thac0TargetDisplay(ac: Int) -> String {
        if let override = thac0TargetOverrides?[ac], !override.isEmpty {
            return override
        }
        return "\(thac0AutoTarget(ac: ac))"
    }

    /// Grava um ajuste manual — mas se o texto escrito bate com o valor
    /// calculado (ou fica vazio), a célula "cicatriza" de volta pro modo
    /// automático em vez de guardar um texto redundante.
    mutating func setThac0Override(ac: Int, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let auto = "\(thac0AutoTarget(ac: ac))"
        if trimmed.isEmpty || trimmed == auto {
            thac0TargetOverrides?[ac] = nil
        } else {
            if thac0TargetOverrides == nil { thac0TargetOverrides = [:] }
            thac0TargetOverrides?[ac] = trimmed
        }
    }

    // `==`/`hash(into:)` escritos à mão (2026-10-02) — mesma causa raiz dos
    // outros comentários grandes de "expression too complex" nesta rodada
    // (ver `Thac0ByLevelProvider`/`ExperienceProgressionTable`), só que
    // aqui não é UMA expressão gigante: é a conformidade `Hashable`
    // SINTETIZADA pelo compilador pra essa struct inteira — já com
    // dezenas e dezenas de campos (`PlayerCharacter` é a maior struct do
    // app) — que já estava raspando o limite do type-checker. Confirmado
    // por bissecção (2026-10-02): adicionar UMA propriedade nova
    // (`psionicistPowers`, um `Optional` de um struct pequeno) bastava pra
    // estourar, mesmo sem nenhuma expressão grande — reverter só essa
    // propriedade (sem mexer em mais nada) já resolvia.
    //
    // Fix: parar de pedir pro compilador sintetizar `==`/`hash(into:)`
    // campo a campo (centenas de comparações numa função só) e escrever a
    // versão manual, comparando só o `id` — barato de tipar, e seguro:
    // conferido (grep em todo o projeto) que NADA depende de igualdade
    // "profunda" entre duas fichas (os `.onChange(of:)` da ficha são todos
    // em sub-propriedades específicas — `character.level`,
    // `character.kit`, etc. — não em `character` inteiro; `deleteCharacter`
    // já compara só por `$0.id == character.id`). Cada `PlayerCharacter`
    // tem um `id: UUID` estável desde a criação, então "mesmo id" já
    // significa "mesma ficha" pra todo propósito que o app realmente usa.
    static func == (lhs: PlayerCharacter, rhs: PlayerCharacter) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

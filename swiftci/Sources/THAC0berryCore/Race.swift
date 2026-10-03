import Foundation

/// As 6 raças-padrão do PHB 2ª edição (Human, Dwarf, Elf, Gnome, Half-Elf,
/// Halfling — não existe Half-Orc no PHB principal desta edição, só em
/// suplementos como o Complete Book of Humanoids, de propósito fora daqui).
/// Mesmo espírito do `AlignmentOption` (`Views/AlignmentPicker.swift`):
/// enum fechado com os dados fixos direto no arquivo, sem depender do
/// `RuleEngine` em tempo de execução — decisão do usuário (2026-09-22),
/// já que esse conteúdo é fixo e sem ambiguidade, igual o alinhamento.
///
/// TODA a informação abaixo foi conferida contra o corpus de Regras já
/// embutido no app (`Store/EmbeddedRules_Part*.swift`) e, no caso da
/// Table 7 (Racial Class and Level Limits), TAMBÉM contra uma foto da
/// página real do PHB que o usuário mandou em 2026-09-22 — a versão só do
/// corpus tinha uma coluna inteira (Halfling) faltando por um problema de
/// extração; a foto fechou a lacuna. Ver TODO.md item 35 pro histórico
/// completo dessa investigação.
enum RaceOption: String, CaseIterable, Identifiable, Hashable {
    case human = "Human"
    case dwarf = "Dwarf"
    case elf = "Elf"
    case gnome = "Gnome"
    case halfElf = "Half-Elf"
    case halfling = "Halfling"

    var id: String { rawValue }

    static func match(_ text: String) -> RaceOption? {
        let normalized = Fuzzy.normalize(text)
        guard !normalized.isEmpty else { return nil }
        return RaceOption.allCases.first { Fuzzy.normalize($0.rawValue) == normalized }
    }

    // MARK: - Table 7 (PHB): Racial Ability Requirements
    // Fonte: `phb_ch02_character_race_tables` (id do RuleEntry), conferida
    // célula a célula contra a foto do PHB que o usuário mandou
    // (2026-09-22) — bateu 100%.

    struct AbilityRange: Hashable { let min: Int; let max: Int }

    /// `nil` = Human: sem mínimo/máximo nenhum, qualquer coisa de 3 a 18 serve.
    var abilityRequirements: [String: AbilityRange]? {
        switch self {
        case .human:
            return nil
        case .dwarf:
            return [
                "Strength": .init(min: 8, max: 18), "Dexterity": .init(min: 3, max: 17),
                "Constitution": .init(min: 11, max: 18), "Intelligence": .init(min: 3, max: 18),
                "Wisdom": .init(min: 3, max: 18), "Charisma": .init(min: 3, max: 17)
            ]
        case .elf:
            return [
                "Strength": .init(min: 3, max: 18), "Dexterity": .init(min: 6, max: 18),
                "Constitution": .init(min: 7, max: 18), "Intelligence": .init(min: 8, max: 18),
                "Wisdom": .init(min: 3, max: 18), "Charisma": .init(min: 8, max: 18)
            ]
        case .gnome:
            return [
                "Strength": .init(min: 6, max: 18), "Dexterity": .init(min: 3, max: 18),
                "Constitution": .init(min: 8, max: 18), "Intelligence": .init(min: 6, max: 18),
                "Wisdom": .init(min: 3, max: 18), "Charisma": .init(min: 3, max: 18)
            ]
        case .halfElf:
            return [
                "Strength": .init(min: 3, max: 18), "Dexterity": .init(min: 6, max: 18),
                "Constitution": .init(min: 6, max: 18), "Intelligence": .init(min: 4, max: 18),
                "Wisdom": .init(min: 3, max: 18), "Charisma": .init(min: 3, max: 18)
            ]
        case .halfling:
            return [
                "Strength": .init(min: 7, max: 18), "Dexterity": .init(min: 7, max: 18),
                "Constitution": .init(min: 10, max: 18), "Intelligence": .init(min: 6, max: 18),
                "Wisdom": .init(min: 3, max: 17), "Charisma": .init(min: 3, max: 18)
            ]
        }
    }

    /// Nota "*" da Table 7 — só o Halfling tem.
    var abilityRequirementFootnote: String? {
        self == .halfling ? "Halfling fighters do not roll for exceptional Strength." : nil
    }

    /// Quais atributos do personagem ficam fora do mínimo/máximo desta
    /// raça — SÓ um aviso (ver TODO.md item 35: decisão do usuário foi
    /// nunca travar a escolha, só mostrar a tabela).
    func abilityWarnings(for abilities: AbilityScores) -> [String] {
        guard let req = abilityRequirements else { return [] }
        let scores: [(String, Int)] = [
            ("Strength", abilities.strength), ("Dexterity", abilities.dexterity),
            ("Constitution", abilities.constitution), ("Intelligence", abilities.intelligence),
            ("Wisdom", abilities.wisdom), ("Charisma", abilities.charisma)
        ]
        return scores.compactMap { name, score in
            guard let range = req[name], score < range.min || score > range.max else { return nil }
            return "\(name) \(score) is outside the \(range.min)–\(range.max) range \(rawValue) requires."
        }
    }

    // MARK: - Racial Ability Adjustments (mesma Table 7, ajustes fixos)

    struct AbilityAdjustment: Hashable { let ability: String; let delta: Int }

    /// Ajuste automático e sem ambiguidade — não é escolha do jogador,
    /// por isso `apply(to:)` aplica direto (TODO.md item 35, regra do
    /// usuário: "quando não for limitar o jogador, pode aplicar direto").
    var abilityAdjustments: [AbilityAdjustment] {
        switch self {
        case .human, .halfElf: return []
        case .dwarf: return [.init(ability: "Constitution", delta: 1), .init(ability: "Charisma", delta: -1)]
        case .elf: return [.init(ability: "Dexterity", delta: 1), .init(ability: "Constitution", delta: -1)]
        case .gnome: return [.init(ability: "Intelligence", delta: 1), .init(ability: "Wisdom", delta: -1)]
        case .halfling: return [.init(ability: "Dexterity", delta: 1), .init(ability: "Strength", delta: -1)]
        }
    }

    // MARK: - Table 7 (DMG): Racial Class and Level Limits
    // Fonte: `dmg_ch02_racial_level_restrictions` (id do RuleEntry) pras
    // colunas Human/Dwarf/Elf/Gnome/Half-elf — citada como regra do DMG
    // no corpus, não do PHB (ver TODO.md item 35, correção 2026-09-22).
    // Coluna Halfling: só veio da foto do PHB que o usuário mandou, o
    // corpus não tinha esse dado nenhum. "Illusionist" (linha "Illus." no
    // livro) fica de fora — o app não tem essa classe separada, só "Mage".

    enum LevelLimit: Equatable {
        case unlimited
        case forbidden
        case upTo(Int)

        var display: String {
            switch self {
            case .unlimited: return "U"
            case .forbidden: return "—"
            case .upTo(let level): return "\(level)"
            }
        }
    }

    func levelLimit(for characterClass: CharacterClass) -> LevelLimit {
        switch self {
        case .human:
            return .unlimited
        case .dwarf:
            switch characterClass {
            case .cleric: return .upTo(10)
            case .fighter: return .upTo(15)
            case .thief: return .upTo(12)
            // Ninja (Complete Ninja's Handbook, 2026-09-30): "Races
            // Allowed: Human, Dwarf, Halfling" — sem número de Table 7
            // pro ninja no texto-fonte enviado pelo usuário (o PHB nunca
            // teve ninja pra começo de conversa), então `.unlimited` em
            // vez de inventar um teto — só marca que a raça É permitida,
            // o mesmo "default: .forbidden" abaixo já cobria Elf/Gnome/
            // Half-Elf corretamente (CNH: "There are no demihuman ninja
            // clans").
            case .ninja: return .unlimited
            // Psionicist (CPsiH "Table 1: Psionicist Racial Level
            // Limits", 2026-10-01) — raças permitidas: human, halfling,
            // dwarf, gnome, elf, half-elf (todas as 6 do app). Humano é
            // `.unlimited` (já cai no `case .human` acima); os outros 5
            // têm teto próprio, nenhum reaproveitando os números de
            // nenhuma outra classe.
            case .psionicist: return .upTo(8)
            default: return .forbidden
            }
        case .elf:
            switch characterClass {
            case .cleric: return .upTo(12)
            case .fighter: return .upTo(12)
            case .mage: return .upTo(15)
            case .ranger: return .upTo(15)
            case .thief: return .upTo(12)
            case .psionicist: return .upTo(7)
            default: return .forbidden
            }
        case .gnome:
            switch characterClass {
            case .cleric: return .upTo(9)
            case .fighter: return .upTo(11)
            case .thief: return .upTo(13)
            case .psionicist: return .upTo(9)
            default: return .forbidden
            }
        case .halfElf:
            switch characterClass {
            case .bard: return .unlimited
            case .cleric: return .upTo(14)
            case .druid: return .upTo(9)
            case .fighter: return .upTo(14)
            case .mage: return .upTo(12)
            case .ranger: return .upTo(16)
            case .thief: return .upTo(12)
            case .psionicist: return .upTo(7)
            default: return .forbidden
            }
        case .halfling:
            switch characterClass {
            case .cleric: return .upTo(8)
            case .fighter: return .upTo(9)
            case .thief: return .upTo(15)
            // Ver comentário no case .ninja de `.dwarf` acima — mesmo
            // raciocínio, Halfling também está na lista de raças
            // permitidas do Complete Ninja's Handbook.
            case .ninja: return .unlimited
            case .psionicist: return .upTo(10)
            default: return .forbidden
            }
        }
    }

    /// Aviso pra classe atual do personagem, se houver algo a dizer —
    /// `nil` quando ilimitado (nada a avisar). SÓ aviso, nunca trava (ver
    /// TODO.md item 35).
    func levelLimitWarning(for characterClass: CharacterClass, currentLevel: Int) -> String? {
        switch levelLimit(for: characterClass) {
        case .unlimited:
            return nil
        case .forbidden:
            return "\(rawValue) cannot normally be a \(characterClass.rawValue) (PHB Table 7)."
        case .upTo(let max):
            guard currentLevel > max else { return nil }
            return "\(rawValue) \(characterClass.rawValue)s are normally limited to level \(max) (PHB Table 7) — this character is already level \(currentLevel)."
        }
    }

    // MARK: - Resistência mágica de verdade (não confundir com o bônus de
    // saving throw por Constituição do Dwarf/Gnome/Halfling, ver abaixo)
    // Fonte: `phb_ch02_elf` / `phb_ch02_half_elf`.

    /// Preenche `SavingThrows.spellResistance` — campo que já existia na
    /// ficha ("linha extra do PDF oficial"). Determinístico pela raça,
    /// sem depender de decisão do jogador, por isso `apply(to:)` aplica
    /// direto.
    var spellResistanceText: String? {
        switch self {
        case .elf: return "90% vs. sleep & charm"
        case .halfElf: return "30% vs. sleep & charm"
        default: return nil
        }
    }

    /// Dwarf, Gnome e Halfling ganham um BÔNUS de saving throw vs. magia
    /// (e, no caso do Halfling, também vs. veneno) por Constituição —
    /// Table 9 (Constitution Saving Throw Bonuses), já usada em outro
    /// lugar do app. Ainda NÃO entra automaticamente na conta dos 5
    /// números de `SavingThrows` porque esse bônus mistura categorias
    /// (ex.: o bônus de veneno do Halfling não vale pra Paralyzation/
    /// Death, que dividem a mesma célula na ficha) — aplicar direto
    /// arriscaria inflar um número que não devia. Fica registrado aqui
    /// só como referência pro jogador (ver `referenceNotes`), decisão
    /// documentada no TODO.md item 35 pra retomar com calma depois.
    var hasConstitutionSaveBonusVsMagic: Bool {
        switch self { case .dwarf, .gnome, .halfling: return true; default: return false }
    }

    // MARK: - Movement básico (Table 7, "Base Movement Rate")
    // Item 8 do pedido do usuário (2026-09-24): "Movement preenchido
    // automaticamente ao escolher raça" — mesma taxa-padrão de todo
    // material 2e (Human/Elf/Half-Elf 12", Dwarf/Gnome/Halfling 6", os
    // "pequenos" da lista). Só preenche o campo "Base" — os outros
    // (Jog/Run/Day) dependem de fator de encumbrance e outras variáveis
    // que o app não modela ainda, então continuam em branco pro jogador
    // preencher à mão (igual antes desta mudança).
    var baseMovementRate: String {
        switch self {
        case .human, .elf, .halfElf: return "12\""
        case .dwarf, .gnome, .halfling: return "6\""
        }
    }

    // MARK: - Texto de referência (habilidades raciais) — preenche
    // `PlayerCharacter.racialAbilities` só se esse campo ainda estiver
    // vazio (nunca sobrescreve texto que o jogador já escreveu ali).
    // Resumo fiel ao conteúdo de `phb_ch02_dwarf` / `_elf` / `_gnome` /
    // `_half_elf` / `_halfling` (parafraseado, não copiado literal).

    var specialAbilitiesText: String? {
        switch self {
        case .human:
            return nil
        case .dwarf:
            return "Infravision 60 ft. Saving throw bonus vs. wands/staves/rods/spells and vs. poison (+1 per 3½ points of Constitution — see Saving Throws). 20% chance a non-class magic item malfunctions when used. +1 to hit orcs, half-orcs, goblins, hobgoblins; ogres/trolls/giants/titans suffer −4 to hit dwarves. Can detect grade/slope, new construction, shifting walls, stonework traps, and approximate depth underground."
        case .elf:
            return "Infravision 60 ft. 90% resistance to sleep and charm-related spells. +1 to hit with bow (except crossbow) or short/long sword. Good chance to notice secret/concealed doors. Surprise bonus if unarmored in metal, alone or with elves/halflings, or 90+ ft from the party: −4 to opponents' surprise roll (−2 if opening a door)."
        case .gnome:
            return "Infravision 60 ft. Saving throw bonus vs. wands/staves/rods/spells (+1 per 3½ points of Constitution — see Saving Throws). 20% chance a non-class, non-illusionist magic item malfunctions when used. +1 to hit kobolds/goblins; gnolls/bugbears/ogres/trolls/giants/titans suffer −4 to hit gnomes. Can detect grade/slope, unsafe walls/ceilings/floors, and approximate depth/direction underground."
        case .halfElf:
            return "Infravision 60 ft. 30% resistance to sleep and charm-related spells. Good chance to notice secret/concealed doors, same as elves."
        case .halfling:
            return "High resistance to magic and poison: saving throw bonus vs. wands/staves/rods/spells and vs. poison (+1 per point of Constitution — see Saving Throws). +1 to attack rolls with thrown weapons and slings. Surprise bonus if unarmored in metal, alone or with halflings/elves, or 90+ ft from the party: −4 to opponents' surprise roll (−2 if opening a door). Chance of infravision (60 ft or 30 ft) depending on lineage."
        }
    }

    // MARK: - Aplicar

    /// Aplica tudo que a raça determina SOZINHA — sem exigir decisão do
    /// jogador nem travar nada (regra do usuário, TODO.md item 35:
    /// "quando não for limitar o jogador... pode aplicar direto na
    /// ficha"). Marca cada campo tocado em `recentAutoChanges` pro
    /// `ChangeFlash` (`Views/ChangeFlash.swift`) piscar quando aparecer
    /// na tela. NÃO mexe em classe, nível, nem bloqueia nada — mínimos de
    /// atributo e limite de classe/nível continuam só aviso, mostrados
    /// pelo `RacePickerSheet` antes de confirmar.
    func apply(to character: inout PlayerCharacter) {
        character.race = rawValue

        for adjustment in abilityAdjustments {
            switch adjustment.ability {
            case "Strength": character.abilities.strength += adjustment.delta
            case "Dexterity": character.abilities.dexterity += adjustment.delta
            case "Constitution": character.abilities.constitution += adjustment.delta
            case "Intelligence": character.abilities.intelligence += adjustment.delta
            case "Wisdom": character.abilities.wisdom += adjustment.delta
            case "Charisma": character.abilities.charisma += adjustment.delta
            default: break
            }
            character.markRecentAutoChange(adjustment.ability.lowercased())
        }

        character.saves.spellResistance = spellResistanceText
        character.markRecentAutoChange("spellResistance")

        // Só preenche se estava vazio — texto que o jogador já escreveu
        // na caixa "Racial Abilities" nunca é apagado sozinho.
        if character.racialAbilities?.isEmpty ?? true, let specialAbilitiesText {
            character.racialAbilities = specialAbilitiesText
            character.markRecentAutoChange("racialAbilities")
        }

        // Item 8 do pedido do usuário (2026-09-24): preenche "Movement"
        // (página 2) sozinho ao escolher raça — mesmo cuidado de nunca
        // sobrescrever um valor que o jogador já tenha digitado ali.
        var movement = character.page2Movement ?? MovementRates()
        if movement.base.isEmpty {
            movement.base = baseMovementRate
            character.page2Movement = movement
            character.markRecentAutoChange("page2MovementBase")
        }
    }
}

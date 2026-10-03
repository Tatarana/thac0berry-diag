import Foundation

/// Personagem de exemplo carregado na primeira execução, para as folhas
/// nunca aparecerem vazias. Kelmon é um clérigo humano de 11º nível.
///
/// Os números seguem as tabelas de sacerdote de AD&D 2e: THAC0 14 (níveis
/// 10-12), jogadas de proteção da faixa 10-12, e magias 5/4/4/3/2/1 pelo
/// nível mais 2/2/1 de bônus por Sabedoria 17 — total 7/6/5/3/2/1.
extension PlayerCharacter {

    /// O exemplo de primeira execução agora vem com sua própria campanha —
    /// personagem e campanha são entidades separadas desde esta versão.
    static func kelmonWithCampaign() -> (Campaign, PlayerCharacter) {
        var campaign = Campaign()
        campaign.name = "The Elturel Campaign"
        campaign.startedDate = Date().addingTimeInterval(-26 * 3600)

        // Duas sessões de mesa de exemplo, pra mostrar o índice já povoado:
        // a chegada em Elturel (ontem) e a sessão de hoje.
        let arrivalSession = Session(date: Date().addingTimeInterval(-26 * 3600),
                                     title: "Arrival in Elturel")
        let todaySession = Session(date: Date(), title: "The Temple Trail")
        campaign.sessions = [arrivalSession, todaySession]

        var kelmon = PlayerCharacter()
        kelmon.campaignID = campaign.id
        kelmon.name = "Kelmon"
        kelmon.playerName = "Fernando"
        kelmon.race = "Human"
        kelmon.characterClass = .cleric
        kelmon.level = 11
        kelmon.alignment = "Lawful Good"
        kelmon.deity = "Torm"
        kelmon.sex = "M"
        kelmon.age = "41"
        kelmon.height = "5'10\""
        kelmon.weight = "180 lb"
        kelmon.hair = "Gray"
        kelmon.eyes = "Brown"
        kelmon.movement = 9

        kelmon.abilities = AbilityScores(
            strength: 14,
            exceptionalStrength: nil,
            dexterity: 12,
            constitution: 15,
            intelligence: 11,
            wisdom: 17,
            charisma: 15
        )

        kelmon.saves = SavingThrows(
            paralyzationPoisonDeath: 6,
            rodStaffWand: 10,
            petrificationPolymorph: 9,
            breathWeapon: 12,
            spell: 11
        )

        kelmon.hitPointsMax = 63
        kelmon.hitPointsCurrent = 47
        kelmon.armorClass = 0
        kelmon.armorRating = "3"
        // Hífen ASCII de propósito (não o "−" matemático/U+2212) — é
        // exatamente essa troca de caractere que causava o bug corrigido em
        // `ConsequenceEngine.recalculateArmorClass` (AJUSTE 2026-09-24):
        // `Int.init?(String)` não reconhece o sinal de menos "bonito".
        kelmon.shieldRating = "-2"
        kelmon.thac0 = 14
        kelmon.experience = 712_450

        kelmon.details = kelmonDetails()

        kelmon.weapons = [
            WeaponEntry(name: "Mace +2", attacks: "1", thac0: "12",
                        damageSmall: "1d6+3", damageLarge: "1d6+3", range: "—"),
            WeaponEntry(name: "Sling", attacks: "1", thac0: "14",
                        damageSmall: "1d4", damageLarge: "1d4", range: "5/10/20")
        ]

        kelmon.equipment = [
            EquipmentItem(name: "Plate mail", note: "50"),
            EquipmentItem(name: "Large shield +1", note: "10"),
            EquipmentItem(name: "Silver holy symbol", note: "1"),
            EquipmentItem(name: "Potion of healing ×2", note: "2"),
            EquipmentItem(name: "Backpack, rope, torches", note: "14"),
            EquipmentItem(name: "Trail rations (5 days)", note: "5")
        ]

        // Cada entrada tinha o que devia estar em "Chk" (número-alvo pra
        // rolar no dado, ex. "Wis 17") ou nem devia existir ("weapon")
        // espremido dentro de "Slots" — bug relatado pelo usuário
        // 2026-09-22, o campo "Slots" era texto livre até essa mudança.
        // Corrigido: `slots` agora é sempre a contagem de espaços gastos
        // (1, o valor mais comum — ver `Proficiency.mechanics.
        // slotsRequired` na base de 372 proficiências) e o número-alvo de
        // cada checagem de habilidade foi pro `target`, que é pra isso.
        kelmon.proficiencies = [
            ProficiencyEntry(name: "Mace", slots: 1),
            ProficiencyEntry(name: "Sling", slots: 1),
            ProficiencyEntry(name: "War hammer", slots: 1),
            ProficiencyEntry(name: "Religion", slots: 1, target: "17"),
            ProficiencyEntry(name: "Healing", slots: 1, target: "15"),
            ProficiencyEntry(name: "Herbalism", slots: 1, target: "10"),
            ProficiencyEntry(name: "Reading/Writing", slots: 1, target: "12"),
            ProficiencyEntry(name: "Etiquette", slots: 1, target: "15")
        ]

        kelmon.languages = ["Common", "Elvish"]
        kelmon.magicItems = ["Mace +2", "Large shield +1",
                             "Periapt of proof against poison"]
        kelmon.allies = ["Dorn, fighter — traveling companion",
                         "Sister Ivet, acolyte"]

        kelmon.treasure = Treasure(platinum: 3, gold: 214, electrum: 18,
                                   silver: 40, copper: 65)

        kelmon.spellSlotAllotments = kelmonPreparation.map { level, spellIDs in
            SpellSlotAllotment(caster: .divine, level: level, count: spellIDs.count)
        }

        var yesterday = kelmonYesterday()
        yesterday.sessionID = arrivalSession.id
        var today = kelmonToday()
        today.sessionID = todaySession.id
        kelmon.spellSheets = [yesterday, today]

        return (campaign, kelmon)
    }

    // MARK: - Ajustes de atributo já preenchidos

    private static func kelmonDetails() -> AbilityDetails {
        var details = AbilityDetails()
        details.strengthHit = "0"
        details.strengthDamage = "0"
        details.strengthWeight = "55"
        details.strengthMaxPress = "170"
        details.strengthDoors = "8"
        details.strengthBars = "7%"

        details.dexterityReaction = "0"
        details.dexterityMissile = "0"
        details.dexterityDefense = "0"

        details.constitutionHP = "+1"
        details.constitutionShock = "90%"
        details.constitutionResurrection = "94%"
        details.constitutionPoison = "0"

        details.intelligenceLanguages = "2"
        details.intelligenceMaxLevel = "5th"
        details.intelligenceLearn = "45%"
        details.intelligenceMaxPerLevel = "7"

        details.wisdomDefense = "+3"
        details.wisdomFailure = "0%"
        details.wisdomBonusSpells = "+2 / +2 / +1"

        details.charismaHenchmen = "7"
        details.charismaLoyalty = "+15%"
        details.charismaReaction = "+3"
        return details
    }

    // MARK: - Folhas de magia

    /// Quantidade de slots por círculo e a lista memorizada do dia.
    ///
    /// IDs no formato real da base importada (`priest-<círculo>-<slug>`,
    /// ver `Scripts/convert_spells.py`) — antes usavam o prefixo curto
    /// "pri1-"/"pri2-"/... que só existia nos ~62 exemplos do Kelmon de
    /// antes da importação real (TODO.md item 1). Depois da importação
    /// (1.795 magias reais) esses IDs curtos pararam de bater com
    /// qualquer entrada da base: `preparedSpellID` ficava preenchido (não
    /// nulo) mas sem resolver pra magia nenhuma, então cada slot memorizado
    /// do personagem de exemplo contava como "não vazio" pro
    /// `SpellSlot.isEmpty` — perdia o campo de escrita da linha e, ao
    /// tocar, abria o detalhe com "Unnamed spell" em vez do nome. Corrigido
    /// trocando pelo ID real de cada magia.
    private static let kelmonPreparation: [(Int, [String])] = [
        (1, ["priest-1-bless", "priest-1-cure-light-wounds", "priest-1-cure-light-wounds",
             "priest-1-command", "priest-1-sanctuary", "priest-1-detect-magic", "priest-1-light"]),
        (2, ["priest-2-silence-15-radius", "priest-2-hold-person", "priest-2-spiritual-hammer",
             "priest-2-aid", "priest-2-chant", "priest-2-slow-poison"]),
        (3, ["priest-3-prayer", "priest-3-dispel-magic", "priest-3-cure-disease",
             "priest-3-remove-curse", "priest-3-continual-light"]),
        (4, ["priest-4-cure-serious-wounds", "priest-4-divination",
             "priest-4-protection-from-evil-10-radius"]),
        (5, ["priest-5-raise-dead", "priest-5-flame-strike"]),
        (6, ["priest-6-heal"])
    ]

    private static func kelmonBoard(spent: [Int: Int]) -> SpellSlotBoard {
        var board = SpellSlotBoard()

        for (level, spellIDs) in kelmonPreparation {
            board.setCount(spellIDs.count, level: level, caster: .divine)
            let spentCount: Int = spent[level] ?? 0
            var position = 0
            for index in board.slots.indices
            where board.slots[index].level == level && board.slots[index].caster == .divine {
                if position < spellIDs.count {
                    board.slots[index].preparedSpellID = spellIDs[position]
                    board.slots[index].isSpent = position < spentCount
                }
                position += 1
            }
        }
        return board
    }

    /// Folha de ontem, já encerrada — serve para mostrar que o histórico da
    /// campanha fica guardado folha a folha.
    private static func kelmonYesterday() -> SpellSheet {
        var sheet = SpellSheet()
        sheet.title = "Day 2 in Elturel"
        sheet.date = Date().addingTimeInterval(-26 * 3600)
        sheet.wisdomAtCreation = 17
        sheet.turnUndeadUsed = 5
        sheet.slotBoard = kelmonBoard(spent: [1: 4, 2: 3, 3: 2, 4: 1])

        // Exemplo do uso real de Additional Spells: um "passar rápido" de
        // alguns dias descansando na estalagem, sem repreparar slot por
        // slot em cada dia — só o registro do que foi lançado nesse meio
        // tempo, com Regeneration como caso de magia ainda fora da base.
        var extra = SpellLogEntry()
        extra.displayName = "Regeneration"
        extra.rawText = "Regeneration"

        sheet.entries = [extra]
        return sheet
    }

    /// A folha do dia em andamento.
    private static func kelmonToday() -> SpellSheet {
        var sheet = SpellSheet()
        sheet.title = "Day 3 in Elturel"
        sheet.date = Date()
        sheet.wisdomAtCreation = 17
        sheet.turnUndeadUsed = 1
        sheet.slotBoard = kelmonBoard(spent: [1: 2, 2: 1, 3: 1])

        // O que foi memorizado e gasto hoje já aparece riscado na grade de
        // círculos acima — Additional Spells começa em branco, pronta pra
        // registrar algo fora dela quando precisar.
        sheet.entries = []

        // Um item mágico de exemplo, pra mostrar a seção cheia — com duas
        // magias atreladas, pra deixar claro que um item não fica preso a
        // uma só.
        sheet.magicItems = [
            MagicItem(name: "Wand of Cure Light Wounds",
                      itemDescription: "A slim silver wand tipped with a moonstone. "
                          + "10 charges; recharges at a temple of Torm once a season.",
                      spells: [
                          ItemSpellUse(spellName: "Cure Light Wounds",
                                       matchedSpellID: "priest-1-cure-light-wounds",
                                       damageNote: "1d8+1",
                                       maxUses: 10,
                                       usedCount: 3)
                      ])
        ]
        return sheet
    }
}

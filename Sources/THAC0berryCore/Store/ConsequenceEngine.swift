import Foundation

/// Compara dois retratos de personagem (antes/depois de subir de nível ou
/// mudar um atributo) e produz as diferenças que a janela de consequências
/// mostra. Fica em cima do `RulesetRegistry` sem saber nada de módulo — só
/// pergunta pela `key` lógica, então um suplemento futuro (Dark Sun,
/// Ravenloft) mudando a resposta de "thac0" ou "savingThrows" não exige
/// tocar neste arquivo.
///
/// A lista de regras rastreadas (`trackedRules`) é o único lugar que sabe
/// COMO escrever um `RuleValue` de volta no `PlayerCharacter` — de
/// propósito: mantém `RuleProvider`/`RulesetRegistry` só de leitura, sem
/// acoplar o motor de regras ao formato exato da ficha.
enum ConsequenceEngine {
    private struct TrackedRule {
        let key: String
        let kind: ConsequenceItem.Kind
        let apply: ((RuleValue, inout PlayerCharacter) -> Void)?
    }

    /// Atalho pras regras de ajuste de atributo: todas seguem o mesmo
    /// formato (`RuleValue.string` → um campo de texto livre em
    /// `PlayerCharacter.details`), só muda a `key` e qual campo recebe.
    private static func abilityRule(_ key: String, write: @escaping (String, inout AbilityDetails) -> Void) -> TrackedRule {
        TrackedRule(key: key, kind: .autoApplicable, apply: { value, character in
            guard let text = value.stringValue else { return }
            write(text, &character.details)
        })
    }

    /// As regras cobertas até agora — HP por nível continua fora daqui de
    /// propósito (pede dado, e o motor nunca aplica nada que envolva
    /// rolagem). Ampliar esta lista é como o Motor de Consequências
    /// cresce, sem mexer na UI que a consome.
    private static let trackedRules: [TrackedRule] = [
        TrackedRule(key: "thac0", kind: .autoApplicable, apply: { value, character in
            guard let newTHAC0 = value.intValue else { return }
            character.thac0 = newTHAC0
        }),
        TrackedRule(key: "savingThrows", kind: .autoApplicable, apply: { value, character in
            guard let newSaves = value.savingThrowsValue else { return }
            character.saves = newSaves
        }),
        TrackedRule(key: "priestSpellSlots", kind: .alreadyAutomatic, apply: nil),
        TrackedRule(key: "wizardSpellSlots", kind: .alreadyAutomatic, apply: nil),

        // MARK: Ajustes de atributo (Tabelas 1-6) — cada um escreve num
        // campo de texto livre pré-existente em `AbilityDetails` (a mesma
        // struct que já alimenta a seção "o que o app sabe calcular" da
        // ficha). Ver `AbilityDetailProvider.swift` pra origem dos dados.
        abilityRule("strengthHit", write: { text, details in details.strengthHit = text }),
        abilityRule("strengthDamage", write: { text, details in details.strengthDamage = text }),
        abilityRule("strengthWeight", write: { text, details in details.strengthWeight = text }),
        abilityRule("strengthMaxPress", write: { text, details in details.strengthMaxPress = text }),
        abilityRule("strengthDoors", write: { text, details in details.strengthDoors = text }),
        abilityRule("strengthBars", write: { text, details in details.strengthBars = text }),

        abilityRule("dexterityReaction", write: { text, details in details.dexterityReaction = text }),
        abilityRule("dexterityMissile", write: { text, details in details.dexterityMissile = text }),
        abilityRule("dexterityDefense", write: { text, details in details.dexterityDefense = text }),

        abilityRule("constitutionHP", write: { text, details in details.constitutionHP = text }),
        abilityRule("constitutionShock", write: { text, details in details.constitutionShock = text }),
        abilityRule("constitutionResurrection", write: { text, details in details.constitutionResurrection = text }),
        abilityRule("constitutionPoison", write: { text, details in details.constitutionPoison = text }),

        abilityRule("intelligenceLanguages", write: { text, details in details.intelligenceLanguages = text }),
        abilityRule("intelligenceMaxLevel", write: { text, details in details.intelligenceMaxLevel = text }),
        abilityRule("intelligenceLearn", write: { text, details in details.intelligenceLearn = text }),
        abilityRule("intelligenceMaxPerLevel", write: { text, details in details.intelligenceMaxPerLevel = text }),

        abilityRule("wisdomDefense", write: { text, details in details.wisdomDefense = text }),
        abilityRule("wisdomFailure", write: { text, details in details.wisdomFailure = text }),
        abilityRule("wisdomBonusSpells", write: { text, details in details.wisdomBonusSpells = text }),

        abilityRule("charismaHenchmen", write: { text, details in details.charismaHenchmen = text }),
        abilityRule("charismaLoyalty", write: { text, details in details.charismaLoyalty = text }),
        abilityRule("charismaReaction", write: { text, details in details.charismaReaction = text }),
    ]

    /// Diferenças entre `old` e `new` pra cada regra rastreada. Uma regra
    /// só vira item quando o valor resolvido realmente muda — inclusive
    /// quando um lado é `nil` (ex. saiu do alcance da tabela).
    static func diff(old: RuleContext, new: RuleContext, registry: RulesetRegistry) -> [ConsequenceItem] {
        var items: [ConsequenceItem] = []

        for rule in trackedRules {
            let oldResolved = registry.resolve(key: rule.key, context: old)
            let newResolved = registry.resolve(key: rule.key, context: new)
            guard oldResolved?.value != newResolved?.value else { continue }

            let label = newResolved?.provider.label ?? oldResolved?.provider.label ?? rule.key
            let sourceRuleID = newResolved?.provider.sourceRuleID(for: new)
                ?? oldResolved?.provider.sourceRuleID(for: old)

            items.append(ConsequenceItem(
                id: rule.key,
                label: label,
                oldValue: oldResolved?.value,
                newValue: newResolved?.value,
                sourceRuleID: sourceRuleID,
                kind: rule.kind
            ))
        }

        return items
    }

    /// Aplica no personagem só os itens automáticos (`.autoApplicable`) —
    /// os `.alreadyAutomatic` não têm o que aplicar, e nada aqui pede dado
    /// (por enquanto o motor só cobre regra determinística; um item que
    /// dependesse de rolagem entraria com um terceiro `Kind` que este
    /// método simplesmente ignoraria).
    static func applyAutomatic(_ items: [ConsequenceItem], to character: inout PlayerCharacter) {
        for item in items where item.kind == .autoApplicable {
            guard let newValue = item.newValue else { continue }
            guard let rule = trackedRules.first(where: { $0.key == item.id }),
                  let apply = rule.apply
            else { continue }
            apply(newValue, &character)
            // Item 2 do pedido do usuário (2026-09-24): estas regras
            // escreviam certinho no personagem (THAC0, Saving Throws, os
            // campos de Ability Details) mas nunca marcavam
            // `recentAutoChange` — então `ChangeFlash` nunca tinha o que
            // piscar, mesmo com o valor corretamente ajustado. `rule.key`
            // já é o mesmo vocabulário usado pelos `.changeFlash`/
            // `OptionalChangeFlash` das views (thac0 não pisca por aqui —
            // usa `PendingConsequenceHighlight`, ver `hasPendingConsequence`
            // em `Models/Character.swift` — mas savingThrows e os campos
            // de Ability Details sim).
            character.markRecentAutoChange(rule.key)
        }
    }

    // MARK: - "Level Changes" automático (item 9 do pedido do usuário, 2026-09-24)

    /// ID da regra embutida que documenta cada linha — usado pro botão
    /// "?" (`RuleLinkButton`) na `LevelChangesForm`, pro jogador abrir a
    /// tabela cheia do livro (Table 53/60) sem sair da ficha. Mesmo
    /// `sourceRuleID` que `Thac0ByLevelProvider`/`SavingThrowsByLevelProvider`
    /// já declaram.
    static let levelChangeRuleIDs: [String: String] = [
        "thac0": "phb_ch09_calculating_thac0",
        "savingThrows": "phb_ch09_the_saving_throw",
    ]

    /// Preenche a tabela "Level Changes" (página 2: THAC0 / Saving Throws
    /// / Weapon Proficiencies / Non-weapon Proficiencies, coluna "At
    /// Levels") sozinho, sem exigir que o jogador consulte o livro e
    /// digite à mão. Só as duas primeiras linhas têm de onde tirar o dado
    /// com segurança — `Thac0ByLevelProvider`/`SavingThrowsByLevelProvider`
    /// (Tables 53/60 do PHB, já conferidas e embutidas no app, mesma fonte
    /// que calcula o THAC0/Saves de verdade da ficha). As duas linhas de
    /// Proficiências ficam de fora: o app não tem (ainda) uma tabela
    /// verificada de em que nível cada classe ganha slot novo, e
    /// inventar esse número arriscaria escrever algo errado — melhor
    /// continuar em branco, do jeito que sempre foi, do que um dado
    /// impreciso.
    ///
    /// A linha do THAC0 tem os dois campos, "By" E "At Levels", calculados
    /// de verdade — nada de texto genérico. Usuário perguntou (2026-09-24)
    /// o que escrever em "By" já que a v1.55 deixava vazio: resposta —
    /// nada, o app escreve sozinho agora. "By" vira a lista de quanto o
    /// THAC0 cai em CADA parada (ex. "-2, -2, -2, -1, -2, -1" pro
    /// Cleric), alinhada item a item com "At Levels" (ex. "4, 7, 10, 13,
    /// 16, 19"), e "At Levels" ainda embute o valor final de cada parada
    /// — ex. "4 (→18), 7 (→16), 10 (→14)…". Os dois lados vêm do MESMO
    /// `registry.resolve` que grava o THAC0 real da ficha (Table 53 do
    /// PHB, já conferida), então não é um número novo por conta própria.
    ///
    /// Saving Throws não dá pro mesmo tratamento: são 5 números mudando
    /// junto, não um só, então "-2, -1, -1..." não diria a qual dos cinco
    /// se refere. Pra essa linha, os valores REAIS já aparecem ao vivo na
    /// seção "Saving Throws" da própria ficha (pisca em verde quando
    /// muda, ver item 1), então "At Levels" aqui só avisa QUANDO
    /// conferir, "By" fica livre pro jogador anotar o que achar útil
    /// (ex. "ver Saving Throws"), e o botão "?" ao lado do título
    /// (`RuleLinkButton`, ver `levelChangeRuleIDs`) abre a Table 60
    /// inteira pra consulta.
    ///
    /// As duas linhas de Proficiências ficam de fora do preenchimento
    /// automático: o app não tem (ainda) uma tabela verificada de em que
    /// nível cada classe ganha slot novo, e inventar esse número
    /// arriscaria escrever algo errado — melhor continuar em branco, do
    /// jeito que sempre foi, do que um dado impreciso.
    ///
    /// Chamado ao trocar de classe (`ClassPicker.select`, com
    /// `force: true` — a tabela do nível anterior fica errada pra classe
    /// nova, então precisa resincronizar mesmo que já houvesse algo
    /// escrito) e ao editar o nível (`RecordHeaderForm`, `force: false`,
    /// igual `refreshHitDiceType`: só preenche linha vazia, nunca
    /// sobrescreve o que o jogador já tiver escrito ali).
    static func refreshLevelChanges(for character: inout PlayerCharacter, registry: RulesetRegistry, force: Bool = false) {
        var table = character.levelChanges ?? LevelChangesTable()
        var changed = false

        if force || (table.thac0.by.isEmpty && table.thac0.atLevels.isEmpty),
           let row = levelChangeRow(key: "thac0", characterClass: character.characterClass, abilities: character.abilities, registry: registry, embedValue: true) {
            table.thac0.by = row.by
            table.thac0.atLevels = row.atLevels
            changed = true
        }

        if force || (table.savingThrows.by.isEmpty && table.savingThrows.atLevels.isEmpty),
           let row = levelChangeRow(key: "savingThrows", characterClass: character.characterClass, abilities: character.abilities, registry: registry, embedValue: false) {
            table.savingThrows.atLevels = row.atLevels
            changed = true
        }

        guard changed else { return }
        character.levelChanges = table
        character.markRecentAutoChange("levelChanges")
    }

    /// Varre os níveis 1–20 chamando o MESMO `registry.resolve` que
    /// `diff`/`applyAutomatic` já usam, e devolve em quais níveis o valor
    /// resolvido muda de um nível pro seguinte — sem duplicar nenhuma
    /// tabela: se `Thac0ByLevelProvider`/`SavingThrowsByLevelProvider`
    /// mudar, este cálculo acompanha sozinho. `nil` quando a regra não
    /// resolve em nível nenhum (classe fora do alcance da tabela).
    /// `embedValue: true` (só faz sentido pra uma regra de saída ESCALAR
    /// como THAC0 — `RuleValue.intValue` devolve `nil` pra um
    /// `.savingThrows(...)`) também preenche `by` com a lista de deltas
    /// alinhada a `atLevels`; sem isso `by` sempre volta vazio.
    private static func levelChangeRow(key: String, characterClass: CharacterClass, abilities: AbilityScores, registry: RulesetRegistry, embedValue: Bool, maxLevel: Int = 20) -> (by: String, atLevels: String)? {
        var changePoints: [(level: Int, value: RuleValue, delta: Int?)] = []
        var previous: RuleValue? = nil

        for level in 1...maxLevel {
            let context = RuleContext(level: level, characterClass: characterClass, abilities: abilities)
            guard let resolved = registry.resolve(key: key, context: context)?.value else { continue }
            if let previous, previous != resolved {
                let delta: Int? = {
                    guard let oldInt = previous.intValue, let newInt = resolved.intValue else { return nil }
                    return newInt - oldInt
                }()
                changePoints.append((level, resolved, delta))
            }
            previous = resolved
        }

        guard !changePoints.isEmpty else { return nil }

        guard embedValue else {
            return (by: "", atLevels: Self.condense(changePoints.map(\.level)))
        }
        // Com valor embutido não dá pra condensar "At Levels" em faixa
        // ("4–7") — cada parada tem um número diferente do lado, por
        // isso lista uma a uma em vez de reusar `condense`.
        let atLevels = changePoints
            .map { point in
                if let intValue = point.value.intValue {
                    return "\(point.level) (→\(intValue))"
                }
                return "\(point.level)"
            }
            .joined(separator: ", ")
        let by = changePoints
            .map { point in
                guard let delta = point.delta else { return "?" }
                return delta > 0 ? "+\(delta)" : "\(delta)"
            }
            .joined(separator: ", ")
        return (by: by, atLevels: atLevels)
    }

    /// "2, 3, 4, 5, 7" → "2–5, 7" — só pra não deixar a célula "At Levels"
    /// ilegível quando a mudança é praticamente todo nível (comum nos
    /// Warriors, que melhoram THAC0 ano a ano).
    private static func condense(_ levels: [Int]) -> String {
        guard !levels.isEmpty else { return "" }
        var ranges: [(Int, Int)] = []
        var start = levels[0]
        var end = levels[0]
        for level in levels.dropFirst() {
            if level == end + 1 {
                end = level
            } else {
                ranges.append((start, end))
                start = level
                end = level
            }
        }
        ranges.append((start, end))
        return ranges.map { $0.0 == $0.1 ? "\($0.0)" : "\($0.0)–\($0.1)" }.joined(separator: ", ")
    }

    // MARK: - Armor Class automático (itens 7 e 10 do pedido do usuário, 2026-09-24)

    /// Itens 7 ("Armor mostra só '1' no campo, AC base não muda; estender
    /// pra Shield") e 10 ("Magic Items — armadura mágica — não muda o AC").
    /// Os campos "Armor"/"Shield" da página 2 (`character.armorRating`/
    /// `shieldRating`, texto livre — ver `ArmorField` em
    /// `CharacterSheetView.swift`) viviam 100% desligados do círculo grande
    /// de AC da página 1 (`character.armorClass`, `ArmorClassShield`): o
    /// jogador escolhia uma armadura no seletor, via o número aparecer só
    /// no campinho de texto da página 2, e tinha que copiar o valor a mão
    /// pro círculo. Esta função soma os três componentes num AC final só:
    ///
    /// - Armadura (`armorRating`): já é um AC final de verdade na base
    ///   embutida (ex. Plate Mail = 3, Leather = 8 — não um delta a partir
    ///   de 10), então entra direto na conta.
    /// - Escudo (`shieldRating`): nenhum escudo tem `baseAC` próprio na
    ///   base de dados (a tabela de preços do PHB não atribui um valor de
    ///   AC isolado a eles, ver `ArmorPiece`) — a regra central de 2e é um
    ///   -1 fixo de AC por qualquer escudo, e é esse "-1" que
    ///   `ArmorPickerSheet` agora grava em `shieldRating` ao escolher um
    ///   (item 7). Somado direto — já vem com o sinal certo.
    /// - Magic Items com `defenseBonus.acBonus` (armadura/escudo mágicos,
    ///   ex. "Abbathor's Armor +4" → `acBonus: 4`): SUBTRAÍDO do total,
    ///   porque AC menor é melhor em AD&D 2e e `acBonus` vem como inteiro
    ///   positivo representando o nível de encantamento (item 10).
    ///
    /// Dexterity (`character.details.dexterityDefense`) fica de FORA de
    /// propósito — nenhum dos dois itens pedidos menciona Dexterity, e essa
    /// conta automática já mexe na área mais visível/consequente da ficha;
    /// somar um campo que o jogador pode estar preenchendo à mão por conta
    /// própria arriscaria contar o bônus em dobro sem que o pedido tivesse
    /// coberto isso.
    ///
    /// AJUSTE (2026-09-24, mesmo dia — usuário testou o Lote 4 e reportou:
    /// "mudar Shield sensibilizou o AC certinho, mas depois mudar Armor ou
    /// incluir/excluir armadura mágica não mudou nada"). Causa raiz: esta
    /// função tinha um "portão" (`guard`) travado em `armorRating` — só
    /// recalculava OS TRÊS gatilhos (Armor, Shield, Magic Items) se
    /// `armorRating` sozinho já fosse um número válido; `shieldRating`
    /// tinha o tratamento certo (falha de parse = trata como "sem
    /// contribuição", não trava a função inteira), mas `armorRating` não.
    /// Bastava `armorRating` estar vazio ou não-numérico num certo momento
    /// (personagem ainda sem Armor escolhida, ou um valor antigo com lixo)
    /// pra NADA recalcular, nem Shield nem Magic Items — mesmo que os dois
    /// tivessem dado certo. E hà pelo menos uma fonte concreta desse "lixo"
    /// no próprio código: `SampleCharacter.swift` (ficha de exemplo,
    /// Kelmon) tinha `shieldRating = "−2"` usando o SINAL DE MENOS
    /// matemático (U+2212, "−"), não o hífen ASCII ("-") que
    /// `Int.init?(String)` exige — o iPadOS troca "-" por "–"/"−"
    /// silenciosamente em alguns teclados/autocorreção, então um jogador
    /// digitando um valor negativo a mão corre o mesmo risco.
    ///
    /// Duas mudanças: `parsedRating` normaliza os travessões/sinal de
    /// menos "bonitos" mais comuns pro hífen ASCII antes do parse (conserta
    /// a causa concreta), e Armor passou a ter o MESMO tratamento "soft"
    /// que Shield já tinha (`Int?` em vez de `guard ... else return`) — um
    /// campo inválido agora conta como "sem contribuição" (equivalente a
    /// 0), não trava mais os outros dois. A função só desiste de vez
    /// quando não há NENHUM sinal — Armor, Shield e Magic Items todos
    /// vazios/sem match —, que é o único caso em que "recalcular" não
    /// significaria nada (personagem que ainda não escolheu equipamento
    /// nenhum), preservando a intenção original de não forçar o AC pra 0
    /// numa ficha nova.
    ///
    /// Chamado a partir de `ArmorBlock`/`RecordSheetPageTwo`
    /// (`CharacterSheetView.swift`) sempre que `armorRating`, `shieldRating`
    /// ou a lista "Magic Items" mudam — nunca em `onAppear`, pra não
    /// sobrescrever silenciosamente um AC que o jogador ajustou a mão por
    /// um motivo que a conta automática não conhece (ex. um efeito
    /// temporário).
    static func recalculateArmorClass(for character: inout PlayerCharacter, magicItemDatabase: MagicItemDatabase) {
        let armorValue = Self.parsedRating(character.armorRating)
        let shieldValue = Self.parsedRating(character.shieldRating)

        var magicBonus = 0
        for entry in character.page2MagicItems ?? [] {
            guard let matchedID = entry.matchedItemID,
                  let magicItem = magicItemDatabase.item(id: matchedID),
                  let acBonus = magicItem.defenseBonus?.acBonus
            else { continue }
            magicBonus += acBonus
        }

        guard armorValue != nil || shieldValue != nil || magicBonus != 0 else { return }

        let newAC = (armorValue ?? 0) + (shieldValue ?? 0) - magicBonus
        guard newAC != character.armorClass else { return }
        character.armorClass = newAC
        character.markRecentAutoChange("armorClass")
    }

    /// `Int.init?(String)` só aceita o hífen ASCII ("-") como sinal de
    /// negativo — aceita também o sinal de menos matemático ("−", U+2212)
    /// e os travessões en/em dash ("–"/"—") que o teclado do iPadOS às
    /// vezes insere sozinho no lugar do hífen comum, pra um "-1" digitado
    /// a mão não falhar o parse silenciosamente por causa do caractere
    /// errado.
    private static func parsedRating(_ raw: String) -> Int? {
        let normalized = raw
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\u{2212}", with: "-")
            .replacingOccurrences(of: "\u{2013}", with: "-")
            .replacingOccurrences(of: "\u{2014}", with: "-")
        return Int(normalized)
    }
}

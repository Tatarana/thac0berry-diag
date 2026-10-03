import Foundation

// MARK: - Efeitos Ativos (2026-09-28, revisado 2026-09-28)
//
// Pedido original do usuário: um jeito de anotar efeitos/magias com
// duração finita (Regenerate, Stone Skin, Recitation, poção de Fire
// Giant Strength, PV temporário não-curável) sem inventar um motor de
// fórmulas pro app inteiro — os campos de combate (Força, THAC0, CA,
// Saves, PV) continuam sendo os mesmos campos editáveis à mão de sempre.
//
// Revisão (mesma data, rodada de feedback): um "item" (a magia/poção em
// si — ex. "Recitation") pode ter MAIS DE UM efeito mecânico ao mesmo
// tempo (Recitation = bônus em To Hit E em Saves, dois efeitos
// separados). Por isso `ActiveEffect` (o item) virou só nome/duração/
// notas + uma lista dinâmica de `EffectComponent` (o mecanismo em si);
// antes os dois eram a mesma coisa.
//
// Cada `EffectComponent` tem um "kind" que sabe COMO se aplicar (ou não)
// na ficha:
//   - `.flatBonus`      — bônus temporário num campo NUMÉRICO de verdade
//                          da ficha (To Hit → `thac0`, já que reduzir o
//                          THAC0 é a forma real do jogo de melhorar o
//                          acerto; Armor Class → `armorClass`; Saving
//                          Throws → +N no "Mod" de todos os cinco saves)
//                          — assim o bônus REFLETE na ficha de verdade,
//                          não só numa lista descritiva. Bônus de dano
//                          continua só uma linha na tabela "Damage
//                          Modifiers": não existe um único número de
//                          "dano total" na ficha pra ajustar.
//   - `.statOverride`   — SUBSTITUI um atributo (não soma) — guarda o
//                          valor anterior pra devolver quando o efeito
//                          acabar.
//   - `.attackNegation`, `.bankedHeal` — não escrevem em nada além de si
//                          mesmos; usam o mesmo contador "X de Y"
//                          (`usedCount`/`maxUses`) que os itens mágicos e
//                          o Turn Undead já usam com o `TallyBoard`.
//   - `.tempHP`         — soma direto em `hitPointsCurrent` na hora de
//                          ativar (30/30 + 10 temp = 40/30), sem contador
//                          visível — só um número a mais no PV atual,
//                          exatamente como a regra descreve.
//   - `.note`           — só uma anotação, sem mecânica nenhuma (ex.:
//                          "sob efeito de Bless, sem bônus numérico
//                          relevante aqui").
//
// `PlayerCharacter.applyActiveEffect`/`revertActiveEffectApplication`
// (em `Character.swift`) fazem a escrita/desfazer nos campos de verdade,
// sempre marcando `markRecentAutoChange` pro `ChangeFlash` avisar o
// jogador — mesmo mecanismo já usado quando a Raça mexe em atributo
// sozinha. `PlayerCharacter.activeEffectPolarity(for:)` decide se esse
// campo deve ficar tingido de verde (bom) ou vermelho (ruim) ENQUANTO o
// efeito estiver ativo — diferente do `ChangeFlash`, que só pisca uma
// vez e apaga.
struct ActiveEffect: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    /// Nome livre do item — "Stone Skin", "Regenerate", "Potion of Fire
    /// Giant Strength"... o que o jogador quiser digitar.
    var name: String = ""
    /// Duração em texto livre ("3 rounds", "6 hours", "until it lands a
    /// hit") — o app não tem relógio de rounds/turnos em lugar nenhum
    /// (nem a Priest Spell Sheet tem), então em vez de fingir que
    /// controla isso sozinho, só guarda a anotação que o jogador
    /// escreveu.
    var durationLabel: String = ""
    var notes: String = ""
    /// Um item pode ter mais de um efeito mecânico ao mesmo tempo — ex.
    /// Recitation é UM item com DOIS `EffectComponent`s (+3 To Hit, +3
    /// Saves).
    var components: [EffectComponent] = []
}

struct EffectComponent: Codable, Identifiable, Hashable {
    enum Kind: String, Codable, CaseIterable, Hashable {
        case flatBonus
        case statOverride
        case attackNegation
        case bankedHeal
        case tempHP
        case note

        var label: String {
            switch self {
            case .flatBonus: return "Flat Bonus"
            case .statOverride: return "Stat Override"
            case .attackNegation: return "Attack Negation"
            case .bankedHeal: return "Banked Heal"
            case .tempHP: return "Temporary HP"
            case .note: return "Note"
            }
        }

        /// Frase curta explicando o mecanismo — mostrada no seletor de
        /// tipo na hora de criar um efeito, pra quem nunca usou a tela
        /// não precisar adivinhar qual exemplo dos cinco do pedido
        /// original cada tipo cobre.
        var hint: String {
            switch self {
            case .flatBonus: return "e.g. Recitation: +3 To Hit (add a 2nd effect for +3 Saves)"
            case .statOverride: return "e.g. Potion of Giant Strength: Strength becomes 22"
            case .attackNegation: return "e.g. Stone Skin: negates the next N attacks"
            case .bankedHeal: return "e.g. Regenerate: heals once you next take damage"
            case .tempHP: return "e.g. extra HP added now, lost to damage never comes back"
            case .note: return "just a reminder, no automatic effect"
            }
        }
    }

    /// Onde um `.flatBonus` é somado — sempre UM alvo por efeito; um
    /// item que afeta dois campos ao mesmo tempo (Recitation) vira dois
    /// `EffectComponent`s separados, um por alvo.
    enum BonusTarget: String, Codable, CaseIterable, Hashable {
        case toHit
        case allSaves
        case armorClass
        case damage

        var label: String {
            switch self {
            case .toHit: return "To Hit"
            case .allSaves: return "Saving Throws"
            case .armorClass: return "Armor Class"
            case .damage: return "Damage"
            }
        }

        /// `false` só pra `.damage` — não existe um único número de dano
        /// na ficha (cada arma tem sua própria linha), então esse alvo
        /// não tem como "refletir" em campo nenhum; fica só como anotação
        /// na tabela "Damage Modifiers", igual sempre foi.
        var reflectsOnSheet: Bool { self != .damage }
    }

    /// Qual campo um `.statOverride` substitui.
    enum OverrideStat: String, Codable, CaseIterable, Hashable {
        case strength, dexterity, constitution, intelligence, wisdom, charisma
        case armorClass
        case thac0

        var label: String {
            switch self {
            case .strength: return "Strength"
            case .dexterity: return "Dexterity"
            case .constitution: return "Constitution"
            case .intelligence: return "Intelligence"
            case .wisdom: return "Wisdom"
            case .charisma: return "Charisma"
            case .armorClass: return "Armor Class"
            case .thac0: return "THAC0"
            }
        }

        /// Chave usada tanto por `markRecentAutoChange` (`ChangeFlash`)
        /// quanto por `PlayerCharacter.activeEffectPolarity(for:)` pra
        /// ler/escrever o campo certo.
        var changeFlashKey: String {
            switch self {
            case .strength: return "strength"
            case .dexterity: return "dexterity"
            case .constitution: return "constitution"
            case .intelligence: return "intelligence"
            case .wisdom: return "wisdom"
            case .charisma: return "charisma"
            case .armorClass: return "armorClass"
            case .thac0: return "thac0"
            }
        }

        /// `true` pros dois campos onde um número MENOR é melhor (THAC0,
        /// Armor Class) — decide se uma substituição conta como "boa"
        /// (verde) ou "ruim" (vermelha) em `activeEffectPolarity`. Todos
        /// os outros (atributos) são "maior é melhor".
        var lowerIsBetter: Bool { self == .armorClass || self == .thac0 }
    }

    var id: UUID = UUID()
    var kind: Kind = .flatBonus

    // MARK: .flatBonus
    var bonusTarget: BonusTarget = .toHit
    var bonusAmount: Int = 0
    /// `EquipmentItem.id` da linha inserida em `damageModifiers` (só
    /// quando o alvo é `.damage` — os outros três alvos escrevem direto
    /// no campo numérico, sem precisar de linha nenhuma) — guardado só
    /// pra `revertActiveEffectApplication` saber qual linha remover, sem
    /// mexer nas outras que o jogador tenha lançado à mão.
    var appliedDamageRowID: UUID? = nil
    /// Só quando `bonusTarget == .allSaves`: QUAIS jogadas de resistência
    /// recebem o bônus — pedido do usuário (2026-09-29): "além da opção
    /// de bônus pra TODOS os saves, dar opção de escolher um ou mais
    /// dentre eles". `nil` = todos os cinco (era o único comportamento
    /// antes desta versão, então fichas salvas com a v1.79 ou antes
    /// continuam se comportando exatamente igual). Guarda os `id`s de
    /// `SavingThrows.SaveEntry` ("ppd", "rsw", "pp", "bw", "sp").
    var savingThrowIDs: Set<String>? = nil
    /// Conjunto de verdade a usar — `nil` vira "todos".
    var effectiveSaveIDs: Set<String> {
        savingThrowIDs ?? Set(SavingThrows.labels.map(\.id))
    }

    // MARK: .statOverride
    var overrideStat: OverrideStat = .strength
    var overrideValue: Int = 0
    /// Valor do campo ANTES da substituição — devolvido ao encerrar o
    /// efeito. Só tem sentido depois que o efeito foi mesmo aplicado.
    var previousValue: Int = 0

    // MARK: .attackNegation / .bankedHeal
    //
    // Reaproveitam o mesmo par que os itens mágicos e o Turn Undead já
    // usam com `TallyBoard` ("X de Y"):
    //   - attackNegation: quantos ataques já foram anulados, de quantos a
    //     magia concede no total.
    //   - bankedHeal (fase ativa): quanto já foi curado, do total do
    //     "banco" (ex.: 3d4+6 rolado uma vez na hora de ativar).
    var usedCount: Int = 0
    var maxUses: Int = 1

    /// Só pra `.bankedHeal`: `true` enquanto a cura ainda não foi
    /// disparada (esperando o personagem tomar dano). `applyDamage`, em
    /// `PlayerCharacter`, vira isso pra `false` sozinho no primeiro dano
    /// recebido enquanto o efeito existir.
    var healIsBanked: Bool = true
    /// Prazo (em HORAS) pra cura ser disparada antes de expirar — texto
    /// livre em vez de número (efeitos de longa duração de campanha,
    /// tipo "até a próxima lua cheia", podem passar de milhares de
    /// horas) — só anotação, o app não conta o tempo sozinho (mesmo
    /// motivo de `ActiveEffect.durationLabel`).
    var healWindowLabel: String = "6 hours"

    // MARK: .tempHP
    //
    // Some direto em `hitPointsCurrent` na hora de ativar (ver
    // `PlayerCharacter.applyActiveEffect`) — `tempHPGranted` é o total
    // concedido, `tempHPRemaining` é quanto disso ainda não foi perdido
    // pra dano (`applyDamage` desconta daqui primeiro); a diferença
    // entre os dois nunca é mostrada como um contador separado — é só
    // bookkeeping interno pra saber quanto tirar de volta se o efeito
    // for encerrado antes de todo consumido.
    var tempHPGranted: Int = 0
    var tempHPRemaining: Int = 0

    var isExhausted: Bool { usedCount >= maxUses }
    var remainingUses: Int { max(0, maxUses - usedCount) }

    /// Resumo de uma linha pro cartão do efeito — cada `kind` sabe
    /// descrever a si mesmo.
    var summary: String {
        switch kind {
        case .flatBonus:
            let amount = bonusAmount >= 0 ? "+\(bonusAmount)" : "\(bonusAmount)"
            if bonusTarget == .allSaves {
                let all = Set(SavingThrows.labels.map(\.id))
                if effectiveSaveIDs == all {
                    return "\(amount) Saving Throws (all)"
                }
                let names = SavingThrows.labels
                    .filter { effectiveSaveIDs.contains($0.id) }
                    .map(\.label)
                let list = names.isEmpty ? "none selected" : names.joined(separator: ", ")
                return "\(amount) Saving Throws (\(list))"
            }
            return "\(amount) \(bonusTarget.label)"
        case .statOverride:
            return "\(overrideStat.label) → \(overrideValue)"
        case .attackNegation:
            return "Negates \(maxUses) attack\(maxUses == 1 ? "" : "s")"
        case .bankedHeal:
            return "Heals \(maxUses) HP (1/round once triggered)"
        case .tempHP:
            return "+\(tempHPGranted) temporary HP"
        case .note:
            return "Note"
        }
    }
}

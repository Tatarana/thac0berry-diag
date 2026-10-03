import Foundation

/// O resultado de uma regra computável. Um enum fechado (em vez de um
/// protocolo genérico com `associatedtype`) de propósito — o resto do
/// projeto já evita generics pesados por causa do type-checker do Swift
/// Playgrounds (ver `KitArmorRestriction`/`RuleContentBlock` pro mesmo
/// padrão), e um `RulesetRegistry` que guarda `[any RuleProvider<Value>]`
/// heterogêneo precisaria de erasure manual pra pouco ganho real: o motor
/// só tem um punhado de "formatos" de resposta possíveis, e cada um novo
/// (ajuste de atributo, encumbrance, etc.) é só mais um `case` aqui.
enum RuleValue: Hashable {
    case int(Int)
    /// Um valor por círculo de magia (1–7) — hoje só a Priest Spell
    /// Progression usa isso, mas serve pra qualquer "N slots por nível de
    /// algo" futuro.
    case intByCircle([Int])
    case savingThrows(SavingThrows)
    /// Texto livre já formatado — usado pelos `AbilityDetailProvider`
    /// (ex.: "+2", "40%", "18(14)"), que espelham campos de texto livre
    /// pré-existentes em `AbilityDetails` em vez de um número puro.
    case string(String)

    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    var intByCircleValue: [Int]? {
        if case .intByCircle(let value) = self { return value }
        return nil
    }

    var savingThrowsValue: SavingThrows? {
        if case .savingThrows(let value) = self { return value }
        return nil
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    /// Texto curto pra exibir numa linha de "antes → depois" sem cada
    /// chamador precisar saber qual `case` está lidando.
    var displaySummary: String {
        switch self {
        case .int(let value):
            return "\(value)"
        case .intByCircle(let counts):
            // Em inglês, igual ao resto do texto da janela de consequências
            // ("What Changes", "Apply automatic changes" etc.) — antes o
            // resumo saía em português ("1× círc. 1") no meio de uma tela
            // toda em inglês, o que pode ter sido a razão de o jogador não
            // ter reconhecido a linha como sendo sobre slots de magia do
            // clérigo ao testar a subida de nível (ver TODO.md item 12).
            let parts = counts.enumerated().compactMap { index, count -> String? in
                guard count > 0 else { return nil }
                return "\(count)× circle \(index + 1)"
            }
            return parts.isEmpty ? "no spells yet" : parts.joined(separator: ", ")
        case .savingThrows(let saves):
            return "PPD \(saves.paralyzationPoisonDeath) · RSW \(saves.rodStaffWand) · "
                + "PP \(saves.petrificationPolymorph) · BW \(saves.breathWeapon) · Sp \(saves.spell)"
        case .string(let value):
            return value
        }
    }
}

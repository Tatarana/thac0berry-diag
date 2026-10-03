import Foundation

/// O agrupamento "Warrior / Wizard / Priest / Rogue" que as tabelas de
/// progressão do PHB usam (Tabela 53 — THAC0, Tabela 60 — Saving Throws)
/// em vez da classe específica do personagem. Compartilhado pelos dois
/// providers que dependem dele — evita duas cópias do mesmo mapeamento
/// divergindo silenciosamente se uma classe nova entrar no app.
enum CoreClassGroup: String, Hashable {
    case warrior = "Warrior"
    case wizard = "Wizard"
    case priest = "Priest"
    case rogue = "Rogue"
    /// Psionicist (2026-10-01, Complete Psionics Handbook) — grupo
    /// PRÓPRIO, não reaproveita Rogue. THAC0 (CPsiH Table 7) bate número a
    /// número com a Tabela 53 do grupo Rogue, mas Saving Throws (CPsiH
    /// Table 8) DIVERGE da Tabela 60 do Rogue a partir da faixa 1-4 (Rod/
    /// Staff/Wand 15 no Psionicist contra 14 no Rogue, Petrification/
    /// Polymorph 10 contra 12) — ver os dois providers que leem este
    /// grupo. Misturar os dois produziria saves erradas pro Psionicist.
    case psionicist = "Psionicist"

    /// Fighter/Paladin/Ranger → Warrior; Mage → Wizard; Cleric/Druid →
    /// Priest; Thief/Bard/Ninja → Rogue — o agrupamento padrão do livro.
    /// Ninja entra aqui (2026-09-30) sem risco de dado inventado: Table
    /// 53/60 do PHB já são organizadas por ESTE agrupamento genérico, não
    /// por classe específica, e o próprio Complete Ninja's Handbook diz
    /// que "Ninja earn experience levels as other rogues do" — THAC0/Saves
    /// do ninja são, por definição, os mesmos do grupo Rogue. Psionicist
    /// (2026-10-01) vira seu PRÓPRIO grupo — ver o comentário no case
    /// acima.
    init(_ characterClass: CharacterClass) {
        switch characterClass {
        case .fighter, .paladin, .ranger:
            self = .warrior
        case .mage:
            self = .wizard
        case .cleric, .druid:
            self = .priest
        case .thief, .bard, .ninja:
            self = .rogue
        case .psionicist:
            self = .psionicist
        }
    }
}

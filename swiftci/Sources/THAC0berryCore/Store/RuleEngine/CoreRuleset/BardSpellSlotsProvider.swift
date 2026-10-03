import Foundation

/// Tabela 32 do PHB ("Bard Spell Progression") — mesmo padrão de
/// `WizardSpellSlotsProvider`/`PriestSpellSlotsProvider` ao lado, só que pro
/// Bardo (2026-09-30, Bard Spell Sheet de verdade): embrulha
/// `BardTables.spellProgression(level:intelligence:)`, que já existe e já é
/// usada de verdade pela folha de magia
/// (`PlayerCharacter.computedSpellSlotAllotments`). Entrar no motor não
/// duplica a tabela, só dá a ela uma `key` lógica igual às outras regras.
///
/// Mesma observação das duas outras: os slots de magia do bardo já são um
/// `computed var` na ficha (recalculam sozinhos toda vez que nível ou
/// Inteligência mudam) — não há nada pra "aplicar", o valor mostrado na
/// janela de consequências é só informativo.
struct BardSpellSlotsProvider: RuleProvider {
    let key = "bardSpellSlots"
    let label = "Bard Spell Slots per Level (Table 32)"

    func compute(for context: RuleContext) -> RuleValue? {
        guard context.characterClass == .bard else { return nil }
        let counts = BardTables.spellProgression(level: context.level, intelligence: context.abilities.intelligence)
        guard counts.contains(where: { $0 > 0 }) else { return nil }
        return .intByCircle(counts)
    }

    func sourceRuleID(for context: RuleContext) -> String? {
        "phb_ch03_rogue_tables"
    }
}

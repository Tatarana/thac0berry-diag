import Foundation

/// Tabela 21 do PHB ("Wizard Spell Progression") — mesmo padrão de
/// `PriestSpellSlotsProvider` ao lado, só que pro Mago: embrulha
/// `WizardTables.spellProgression(level:intelligence:)`, que já existe e já
/// é usada de verdade pela folha de magia
/// (`PlayerCharacter.computedSpellSlotAllotments`). Entrar no motor não
/// duplica a tabela, só dá a ela uma `key` lógica igual às outras regras.
///
/// Mesma observação de `PriestSpellSlotsProvider`: os slots de magia do
/// mago já são um `computed var` na ficha (recalculam sozinhos toda vez que
/// nível ou Inteligência mudam) — não há nada pra "aplicar", o valor
/// mostrado na janela de consequências é só informativo.
struct WizardSpellSlotsProvider: RuleProvider {
    let key = "wizardSpellSlots"
    let label = "Wizard Spell Slots per Level (Table 21)"

    func compute(for context: RuleContext) -> RuleValue? {
        guard context.characterClass == .mage else { return nil }
        let counts = WizardTables.spellProgression(level: context.level, intelligence: context.abilities.intelligence)
        guard counts.contains(where: { $0 > 0 }) else { return nil }
        return .intByCircle(counts)
    }

    func sourceRuleID(for context: RuleContext) -> String? {
        "phb_ch03_wizard_tables"
    }
}

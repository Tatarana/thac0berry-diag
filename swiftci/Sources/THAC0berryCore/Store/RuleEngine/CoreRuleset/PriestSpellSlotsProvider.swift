import Foundation

/// Tabela 24 do PHB ("Priest Spell Progression") — não reimplementa a
/// conta: só embrulha `PriestTables.spellProgression(level:wisdom:)`, que
/// já existe e já é usada de verdade pela folha de magia
/// (`PlayerCharacter.computedSpellSlotAllotments`). Entrar no motor não
/// duplica a tabela, só dá a ela uma `key` lógica igual às outras regras —
/// e serve de prova de que o motor também acomoda lógica que já existia
/// no projeto antes dele, não só regra nova.
///
/// Diferença importante pras outras duas regras deste módulo: os slots de
/// magia do clérigo já são um `computed var` na ficha (recalculam sozinhos
/// toda vez que nível ou Sabedoria mudam) — não há nada pra "aplicar", o
/// valor mostrado na janela de consequências é só informativo.
struct PriestSpellSlotsProvider: RuleProvider {
    let key = "priestSpellSlots"
    // Rótulo antigo ("Priest Spell Progression") não deixava óbvio que a
    // linha é sobre GANHAR slots de magia — trocado por algo que qualquer
    // jogador reconhece de cara (ver TODO.md item 12).
    let label = "Priest Spell Slots per Level (Table 24)"

    func compute(for context: RuleContext) -> RuleValue? {
        // Restrito ao Clérigo mesmo (não `hasSpellSheet`, que desde
        // 2026-09-29 também é `true` pro Mago) — a Priest Spell Progression
        // não se aplica a ele; ver `WizardSpellSlotsProvider` ao lado.
        guard context.characterClass == .cleric else { return nil }
        let counts = PriestTables.spellProgression(level: context.level, wisdom: context.abilities.wisdom)
        guard counts.contains(where: { $0 > 0 }) else { return nil }
        return .intByCircle(counts)
    }

    func sourceRuleID(for context: RuleContext) -> String? {
        "phb_ch03_priest_tables"
    }
}

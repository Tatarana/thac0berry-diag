import Foundation

/// O módulo base — Player's Handbook + Dungeon Master's Guide, sempre
/// ativo, sempre por último na prioridade do `RulesetRegistry` (é o piso:
/// toda `key` sem suplemento cobrindo cai aqui). Cada provider abaixo tem
/// seu próprio arquivo em `CoreRuleset/`, um por regra, no mesmo espírito
/// de granularidade dos `EmbeddedRules_PartN.swift`.
struct CoreRuleset: RulesetModule {
    static let moduleID = "core"

    let id = CoreRuleset.moduleID
    let displayName = "Core (Player's Handbook & Dungeon Master's Guide)"

    let providers: [RuleProvider] = [
        Thac0ByLevelProvider(),
        SavingThrowsByLevelProvider(),
        PriestSpellSlotsProvider(),
        WizardSpellSlotsProvider(),
        BardSpellSlotsProvider(),
    ] + AbilityDetailProviders.all
}

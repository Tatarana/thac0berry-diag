import Foundation

/// Uma regra computável — a peça central do motor. Em vez de espalhar
/// conta de jogo pelas Views (o que já tinha acontecido: o grid THAC0×CA
/// morava dentro de `Thac0TargetForm`), toda regra que dá pra calcular a
/// partir do personagem vira um `RuleProvider`, registrado num
/// `RulesetModule` (ver `RulesetModule.swift`) e resolvido pelo
/// `RulesetRegistry`.
///
/// A `key` é o nome pelo qual QUALQUER módulo — o Core (PHB/DMG) ou um
/// suplemento futuro tipo Dark Sun/Ravenloft — se candidata a responder.
/// Dois módulos ativos ao mesmo tempo podem ter um provider para a mesma
/// `key`; o `RulesetRegistry` resolve por prioridade (módulo mais
/// específico primeiro), não por "primeiro que existir" — é assim que um
/// suplemento futuro vai poder SOBRESCREVER uma regra do Core (ex. Dark Sun
/// mudando Encumbrance por escassez de metal) sem precisar tocar no
/// provider do Core nem duplicá-lo.
protocol RuleProvider {
    /// Identificador estável e único POR CONCEITO de regra — ex. "thac0",
    /// "savingThrows", "priestSpellSlots". Nunca inclui o nome do módulo
    /// (isso já é `RulesetModule.id`); a mesma `key` é o que permite dois
    /// módulos competirem pela mesma pergunta.
    var key: String { get }

    /// Nome curto pra exibir de onde um valor computado veio (ex. "THAC0
    /// by Level — Table 53") — usado na UI de consequências, não pretende
    /// ser único.
    var label: String { get }

    /// Calcula o valor pra um retrato de personagem. `nil` quando esta
    /// combinação não tem resposta (nível fora de alcance, classe que essa
    /// regra não cobre, etc.) — o `RulesetRegistry` então tenta o próximo
    /// módulo na ordem de prioridade em vez de travar.
    func compute(for context: RuleContext) -> RuleValue?

    /// Id de uma `RuleEntry` (`RulesDatabase`) que documenta de onde este
    /// número vem — alimenta o "ver regra" sem duplicar texto entre a
    /// referência legível e o motor. `nil` quando não há entrada
    /// correspondente na base (não deveria travar nada, só esconde o
    /// botão "ver regra" pra esse item).
    func sourceRuleID(for context: RuleContext) -> String?
}

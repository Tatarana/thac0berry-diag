import Foundation

/// Uma linha da janela de consequências: uma regra que mudou de valor
/// entre o "antes" e o "depois" de uma ação do jogador (subir de nível,
/// mudar um atributo). Produzido por `ConsequenceEngine.diff`, não guarda
/// lógica nenhuma — só o que já foi calculado, pronto pra exibir.
struct ConsequenceItem: Identifiable {
    /// Igual à `key` do `RuleProvider` que respondeu — único por regra
    /// rastreada nesta comparação.
    let id: String
    let label: String
    let oldValue: RuleValue?
    let newValue: RuleValue?
    /// Id de `RuleEntry` pro botão "ver regra" — `nil` esconde o botão.
    let sourceRuleID: String?
    let kind: Kind

    enum Kind: Equatable {
        /// Determinística, sem dado envolvido — ganha um botão "aplicar".
        case autoApplicable
        /// Já é um `computed var` em algum lugar da ficha (ex. slots de
        /// magia do clérigo) — o valor mostrado já está em vigor sozinho,
        /// só é informativo aqui.
        case alreadyAutomatic
    }
}

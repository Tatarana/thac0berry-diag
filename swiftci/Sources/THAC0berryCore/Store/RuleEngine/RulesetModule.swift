import Foundation

/// Um sourcebook/suplemento como unidade de regras — hoje só existe o
/// `CoreRuleset` (PHB/DMG, ver `CoreRuleset/CoreRuleset.swift`), mas o
/// protocolo já é o encaixe pronto pra Dark Sun, Ravenloft etc.: cada um
/// vira um `struct` novo implementando isto, com seus próprios
/// `RuleProvider`s, sem precisar mexer no motor ou nos módulos existentes.
protocol RulesetModule {
    /// Identificador estável do módulo (ex. "core", "dark_sun",
    /// "ravenloft") — usado pra evitar duplicar o mesmo módulo ativo duas
    /// vezes e como chave de exibição/depuração.
    var id: String { get }

    /// Nome pra exibir ao jogador/mestre (ex. "Core (PHB & DMG)", "Dark
    /// Sun").
    var displayName: String { get }

    /// As regras computáveis que este módulo contribui. Um módulo não
    /// precisa cobrir toda `key` que existe — só as que ele adiciona ou
    /// sobrescreve; o `RulesetRegistry` cai pro próximo módulo na
    /// prioridade (o Core, no fim da fila) pra qualquer `key` que faltar.
    var providers: [RuleProvider] { get }
}

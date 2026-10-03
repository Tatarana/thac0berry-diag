import Foundation

/// Retrato mínimo de um personagem, do jeito que uma regra computável
/// precisa pra responder — não é o `PlayerCharacter` inteiro de propósito:
/// isolar o motor de regras (`RuleProvider`/`RulesetRegistry`) da ficha
/// completa evita que ele fique acoplado a todo campo novo que a ficha
/// ganhar (retrato de personagem, texto de background, etc.), e deixa claro
/// exatamente do que uma regra pode depender.
///
/// Cresce conforme mais regras entrarem no motor (ex. um dia vai precisar
/// de raça pra regras de Dark Sun) — sempre por campo novo aqui, nunca
/// passando o personagem inteiro pra dentro de um `RuleProvider`.
struct RuleContext: Hashable {
    var level: Int
    var characterClass: CharacterClass
    var abilities: AbilityScores
}

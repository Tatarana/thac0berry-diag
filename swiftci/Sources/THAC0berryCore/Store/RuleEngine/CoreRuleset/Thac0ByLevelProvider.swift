import Foundation

/// Tabela 53 do PHB ("Calculated THAC0s") — um THAC0 direto por
/// grupo/nível, níveis 1 a 20. Os números abaixo não foram digitados de
/// memória: vieram do mesmo JSON de extração auditado que virou
/// `EmbeddedRules_Part*.swift` (ver `phb_ch09_calculating_thac0` na base
/// de regras — é o mesmo "ver regra" que este provider aponta), conferidos
/// contra a tabela renderizada na Referência de Regras antes de entrar
/// aqui.
///
/// Nível 21+ fica fora do alcance desta v1 (a Tabela 54 — Improvement
/// Rate — cobre a progressão depois do 20, mas não entrou nesta rodada);
/// `compute` devolve `nil` nesse caso e o campo simplesmente não aparece
/// como alterável na janela de consequências.
struct Thac0ByLevelProvider: RuleProvider {
    let key = "thac0"
    let label = "THAC0 by Level (Table 53)"

    // Cada linha vira uma constante separada, com tipo explícito, ANTES de
    // entrar no dicionário (2026-10-01) — não é só estética. Com as 5
    // linhas inteiras dentro de UM литeral de dicionário só, o
    // type-checker do Swift Playgrounds (rodando no próprio iPad, recursos
    // limitados) estourava e o build falhava SEM NENHUMA MENSAGEM assim
    // que `CoreClassGroup` ganhou um 5º caso — confirmado por bisseção
    // isolando esse exato arquivo (um `[CoreClassGroup: [Row]]`/
    // `[CoreClassGroup: [Int]]` com literais grandes é um padrão conhecido
    // de "expression too complex" do compilador Swift; o 5º caso só
    // empurrou a inferência de tipo dessa UMA expressão gigante pro limite
    // de tempo). Separar cada array com `: [Int]` explícito faz o
    // type-checker resolver cada um sozinho, rápido, em vez de inferir
    // tudo de uma vez só dentro do dicionário.
    private static let priestRow: [Int] = [20, 20, 20, 18, 18, 18, 16, 16, 16, 14, 14, 14, 12, 12, 12, 10, 10, 10, 8, 8]
    private static let rogueRow: [Int] = [20, 20, 19, 19, 18, 18, 17, 17, 16, 16, 15, 15, 14, 14, 13, 13, 12, 12, 11, 11]
    private static let warriorRow: [Int] = [20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
    private static let wizardRow: [Int] = [20, 20, 20, 19, 19, 19, 18, 18, 18, 17, 17, 17, 16, 16, 16, 15, 15, 15, 14, 14]
    /// Psionicist (CPsiH "Table 7: Psionicist Calculated Thacos") —
    /// idêntica à do grupo Rogue, número a número, mas listada em
    /// separado porque `CoreClassGroup.psionicist` é seu próprio caso (ver
    /// comentário lá: Saving Throws diverge, THAC0 não).
    private static let psionicistRow: [Int] = rogueRow

    private static let byGroup: [CoreClassGroup: [Int]] = [
        .priest: priestRow,
        .rogue: rogueRow,
        .warrior: warriorRow,
        .wizard: wizardRow,
        .psionicist: psionicistRow,
    ]

    func compute(for context: RuleContext) -> RuleValue? {
        let group = CoreClassGroup(context.characterClass)
        guard let row = Self.byGroup[group] else { return nil }
        let index = context.level - 1
        guard index >= 0, index < row.count else { return nil }
        return .int(row[index])
    }

    func sourceRuleID(for context: RuleContext) -> String? {
        context.characterClass == .psionicist ? "cpsih_ch01_special_abilities" : "phb_ch09_calculating_thac0"
    }
}

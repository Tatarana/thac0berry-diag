import Foundation

/// Base das armaduras/elmos/escudos mundanos do PHB — vem de
/// `armor_and_shields.json` (TODO.md itens 22/24), literais Swift de
/// verdade, SEM bundle/`Data`/`JSONDecoder` nenhum em runtime. Mesmo
/// motivo/mesmo padrão de `EmbeddedWeapons.swift`/`KitDatabase.swift` — ver
/// o comentário em `KitDatabase.swift` pro histórico completo.
///
/// 20 itens — os 21 do corpus original menos a linha "Helmet" (cabeçalho
/// de seção do livro incluído por engano como item pelo extrator; ver
/// TODO.md item 24, confirmado contra o print do PHB).
enum EmbeddedArmor {
    static let entries: [ArmorPiece] = [
        embeddedArmor000,
        embeddedArmor001,
        embeddedArmor002,
        embeddedArmor003,
        embeddedArmor004,
        embeddedArmor005,
        embeddedArmor006,
        embeddedArmor007,
        embeddedArmor008,
        embeddedArmor009,
        embeddedArmor010,
        embeddedArmor011,
        embeddedArmor012,
        embeddedArmor013,
        embeddedArmor014,
        embeddedArmor015,
        embeddedArmor016,
        embeddedArmor017,
        embeddedArmor018,
        embeddedArmor019
    ]
}

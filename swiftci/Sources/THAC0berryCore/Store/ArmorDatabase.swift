import Foundation

/// Base de armaduras/elmos/escudos mundanos do PHB — vem de
/// `EmbeddedArmor.entries`, literais Swift de verdade, SEM bundle/`Data`/
/// `JSONDecoder` nenhum em runtime. Mesmo motivo/mesmo padrão de
/// `WeaponDatabase.swift`/`KitDatabase.swift`.
final class ArmorDatabase: ObservableObject {
    @Published private(set) var pieces: [ArmorPiece] = []
    /// Mantido só pra bater com o padrão das outras bases — sempre `nil`
    /// agora que não há leitura de bundle nenhuma pra falhar.
    @Published private(set) var loadError: String? = nil

    init() {
        pieces = EmbeddedArmor.entries.sorted { $0.name < $1.name }
    }

    func piece(id: String) -> ArmorPiece? {
        pieces.first { $0.id == id }
    }

    /// Só as peças de um `kind` — usado pelo seletor de "Armor" da ficha
    /// pra não misturar elmo/escudo na lista de armaduras de verdade.
    func pieces(kind: ArmorPieceKind) -> [ArmorPiece] {
        pieces.filter { $0.kind == kind }
    }

    /// Busca aproximada por nome — mesmo padrão de `WeaponDatabase.matches`.
    func matches(for query: String, kind: ArmorPieceKind? = nil, limit: Int = 20) -> [ArmorPiece] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let normalizedQuery = Fuzzy.normalize(trimmed)
        guard !normalizedQuery.isEmpty else { return [] }

        let base = kind.map { k in pieces.filter { $0.kind == k } } ?? pieces

        let substringMatches = base.filter {
            Fuzzy.normalize($0.name).contains(normalizedQuery)
        }
        if !substringMatches.isEmpty { return Array(substringMatches.prefix(limit)) }

        let scored = base
            .map { ($0, Fuzzy.similarity(normalizedQuery, Fuzzy.normalize($0.name))) }
            .filter { $0.1 >= 0.55 }
            .sorted { $0.1 > $1.1 }
        return scored.prefix(limit).map(\.0)
    }
}

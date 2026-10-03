import Foundation

/// Base do catálogo geral de itens mundanos — vem de
/// `EmbeddedMundaneItems.entries`, literais Swift de verdade, SEM bundle/
/// `Data`/`JSONDecoder` nenhum em runtime. Mesmo motivo/mesmo padrão de
/// `WeaponDatabase.swift`/`ArmorDatabase.swift`/`KitDatabase.swift`.
final class MundaneItemDatabase: ObservableObject {
    @Published private(set) var items: [MundaneItem] = []
    /// Mantido só pra bater com o padrão das outras bases — sempre `nil`
    /// agora que não há leitura de bundle nenhuma pra falhar.
    @Published private(set) var loadError: String? = nil

    init() {
        items = EmbeddedMundaneItems.entries.sorted { $0.name < $1.name }
    }

    func item(id: String) -> MundaneItem? {
        items.first { $0.id == id }
    }

    /// Busca aproximada por nome — mesmo padrão de `WeaponDatabase.matches`
    /// / `ArmorDatabase.matches`.
    func matches(for query: String, limit: Int = 20) -> [MundaneItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let normalizedQuery = Fuzzy.normalize(trimmed)
        guard !normalizedQuery.isEmpty else { return [] }

        let substringMatches = items.filter {
            Fuzzy.normalize($0.name).contains(normalizedQuery)
        }
        if !substringMatches.isEmpty { return Array(substringMatches.prefix(limit)) }

        let scored = items
            .map { ($0, Fuzzy.similarity(normalizedQuery, Fuzzy.normalize($0.name))) }
            .filter { $0.1 >= 0.55 }
            .sorted { $0.1 > $1.1 }
        return scored.prefix(limit).map(\.0)
    }
}

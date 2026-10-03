import Foundation

/// Base das armas mundanas do PHB — vem de `EmbeddedWeapons.entries`,
/// literais Swift de verdade, SEM bundle/`Data`/`JSONDecoder` nenhum em
/// runtime. Mesmo motivo/mesmo padrão de `KitDatabase.swift`/
/// `ProficiencyDatabase.swift` — ver o comentário em `KitDatabase.swift`
/// pro histórico completo de por que ler isso de JSON de bundle não é
/// confiável neste toolchain.
final class WeaponDatabase: ObservableObject {
    @Published private(set) var weapons: [Weapon] = []
    /// Mantido só pra bater com o padrão das outras bases (`spellbook.
    /// loadError`/`kits.loadError`/`proficiencies.loadError`) — sempre
    /// `nil` agora que não há leitura de bundle nenhuma pra falhar.
    @Published private(set) var loadError: String? = nil

    init() {
        weapons = EmbeddedWeapons.entries.sorted { $0.name < $1.name }
    }

    func weapon(id: String) -> Weapon? {
        weapons.first { $0.id == id }
    }

    /// Busca aproximada por nome — mesmo padrão de `ProficiencyDatabase.
    /// matches`/`SpellDatabase.matches`: substring primeiro (o que se
    /// espera de uma busca digitada), só cai pro fuzzy se a substring não
    /// achar nada.
    func matches(for query: String, limit: Int = 20) -> [Weapon] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let normalizedQuery = Fuzzy.normalize(trimmed)
        guard !normalizedQuery.isEmpty else { return [] }

        let substringMatches = weapons.filter {
            Fuzzy.normalize($0.name).contains(normalizedQuery)
        }
        if !substringMatches.isEmpty { return Array(substringMatches.prefix(limit)) }

        let scored = weapons
            .map { ($0, Fuzzy.similarity(normalizedQuery, Fuzzy.normalize($0.name))) }
            .filter { $0.1 >= 0.55 }
            .sorted { $0.1 > $1.1 }
        return scored.prefix(limit).map(\.0)
    }
}

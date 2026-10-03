import Foundation

/// Base de proficiências não-de-arma — lida de `Resources/proficiencies.json`
/// em runtime (ver `KitDatabase.swift` pro histórico completo: o bug de
/// decode que motivou embutir isso como literal Swift já foi corrigido, e
/// o literal gigante virou o problema novo — travava o archive de
/// distribuição do Swift Playgrounds).
final class ProficiencyDatabase: ObservableObject {
    @Published private(set) var proficiencies: [Proficiency] = []
    @Published private(set) var loadError: String? = nil

    init() {
        load()
    }

    private func load() {
        guard let resourceURL = Bundle.main.resourceURL,
              let fileURL = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
                  .first(where: { $0.lastPathComponent == "proficiencies.json" })
        else {
            loadError = "Couldn't find proficiencies.json in the app bundle."
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            proficiencies = try JSONDecoder().decode([Proficiency].self, from: data).sorted { $0.name < $1.name }
        } catch {
            loadError = "Couldn't read proficiencies.json: \(error.localizedDescription)"
        }
    }

    func proficiency(id: String) -> Proficiency? {
        proficiencies.first { $0.id == id }
    }

    /// Todos os grupos primários existentes, na ordem fixa do PHB/wiki de
    /// origem — pra agrupar a lista de consulta.
    static let groupOrder = ["General", "Priest", "Rogue", "Warrior", "Wizard", "Psionicist", "Racial / Special"]

    /// Busca aproximada por nome — mesmo padrão de `SpellDatabase.matches`:
    /// substring primeiro (o que se espera de uma busca digitada), só cai
    /// pro fuzzy se a substring não achar nada (cobre erro de digitação
    /// pequeno sem abrir a porta pra qualquer coisa parecida).
    func matches(for query: String, limit: Int = 20) -> [Proficiency] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let normalizedQuery = Fuzzy.normalize(trimmed)
        guard !normalizedQuery.isEmpty else { return [] }

        let substringMatches = proficiencies.filter {
            Fuzzy.normalize($0.name).contains(normalizedQuery)
        }
        if !substringMatches.isEmpty { return Array(substringMatches.prefix(limit)) }

        let scored = proficiencies
            .map { ($0, Fuzzy.similarity(normalizedQuery, Fuzzy.normalize($0.name))) }
            .filter { $0.1 >= 0.55 }
            .sorted { $0.1 > $1.1 }
        return scored.prefix(limit).map(\.0)
    }
}

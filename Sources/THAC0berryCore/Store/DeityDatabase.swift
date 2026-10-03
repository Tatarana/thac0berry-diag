import Foundation

/// Base de divindades (*Faiths & Avatars* + *Powers & Pantheons*, 79
/// entradas) — lida de `Resources/deities.json` em runtime (ver o
/// comentário em `KitDatabase.swift`/`Rule.swift` pro porquê da volta ao
/// JSON, 2026-09-25).
final class DeityDatabase: ObservableObject {
    @Published private(set) var entries: [Deity] = []
    @Published private(set) var loadError: String? = nil

    init() {
        load()
    }

    private func load() {
        guard let resourceURL = Bundle.main.resourceURL,
              let fileURL = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
                  .first(where: { $0.lastPathComponent == "deities.json" })
        else {
            loadError = "Couldn't find deities.json in the app bundle."
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            entries = try JSONDecoder().decode([Deity].self, from: data).sorted { $0.name < $1.name }
        } catch {
            loadError = "Couldn't read deities.json: \(error.localizedDescription)"
        }
    }

    func deity(id: String) -> Deity? {
        entries.first { $0.id == id }
    }

    /// Casamento EXATO de nome (não fuzzy) — usado pelos dois links
    /// cruzados (`Kit.deity` e o campo livre "Patron Deity" da ficha).
    /// Comparação sem acento/maiúscula (`Fuzzy.normalize`) porque o nome
    /// digitado na ficha ou vindo do `Kit` às vezes varia só nisso (ex.
    /// "Selune" vs "Selûne") — mas ainda exige o nome completo bater,
    /// não é busca parcial: um "?" que abrisse a divindade errada seria
    /// pior que não abrir nada.
    func deity(named name: String) -> Deity? {
        let normalized = Fuzzy.normalize(name)
        guard !normalized.isEmpty else { return nil }
        return entries.first { Fuzzy.normalize($0.name) == normalized }
    }

    /// Livros únicos, na ordem em que aparecem no array embutido.
    func books() -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for entry in entries where !seen.contains(entry.book) {
            seen.insert(entry.book)
            result.append(entry.book)
        }
        return result
    }

    /// Candidatos ordenados por semelhança com o texto buscado — mesma
    /// técnica de `SpellDatabase.matches`/`RulesDatabase.matches`: compara
    /// contra nome, apelidos e portfólio (não `fullText` — prosa longa
    /// combina com quase tudo e afogaria o resultado certo).
    func matches(for text: String, limit: Int = 40, book: String? = nil) -> [DeityMatch] {
        let query = Fuzzy.normalize(text)
        guard !query.isEmpty else { return [] }

        var scored: [DeityMatch] = []
        scored.reserveCapacity(entries.count)

        for entry in entries {
            if let book, entry.book != book { continue }

            let nameScore = Fuzzy.similarity(query, Fuzzy.normalize(entry.name))
            let aliasScore = entry.aliases.map { Fuzzy.similarity(query, Fuzzy.normalize($0)) } ?? 0
            let portfolioScore = Fuzzy.similarity(query, Fuzzy.normalize(entry.portfolio))
            let best = max(nameScore, aliasScore, portfolioScore)
            if best >= 0.3 {
                scored.append(DeityMatch(entry: entry, score: best))
            }
        }

        scored.sort { lhs, rhs in
            if lhs.score == rhs.score { return lhs.entry.name < rhs.entry.name }
            return lhs.score > rhs.score
        }

        if scored.count > limit {
            scored.removeLast(scored.count - limit)
        }
        return scored
    }
}

struct DeityMatch: Identifiable, Hashable {
    let entry: Deity
    let score: Double

    var id: String { entry.id }
}

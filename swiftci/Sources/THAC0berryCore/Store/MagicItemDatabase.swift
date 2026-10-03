import Foundation

/// Base de itens mágicos — mesmo padrão de leitura em runtime que
/// `SpellDatabase` já comprova (ver o comentário grande em `Models/MagicItem.swift`
/// pro porquê da mudança de padrão): varre o bundle por `magic_*.json`
/// (gerados por `Scripts/preprocess_magic_items.py` — ver TODO.md item 30 —
/// a partir do corpus bruto entregue pelo usuário, com `rawWikitext` e
/// outros campos sempre-nulos já cortados) e decodifica cada um.
final class MagicItemDatabase: ObservableObject {
    @Published private(set) var items: [CompendiumMagicItem] = []
    @Published private(set) var loadError: String? = nil

    init() {
        load()
    }

    private func load() {
        var merged: [CompendiumMagicItem] = []
        var seenIDs: Set<String> = []
        var errors: [String] = []

        for file in magicFiles() {
            do {
                let data = try Data(contentsOf: file.url)
                let batch = try JSONDecoder().decode([CompendiumMagicItem].self, from: data)
                for item in batch {
                    guard !seenIDs.contains(item.id) else { continue }
                    seenIDs.insert(item.id)
                    merged.append(item)
                }
            } catch {
                errors.append("Failed to read \(file.name).json: \(error.localizedDescription)")
            }
        }

        items = merged
        if errors.isEmpty {
            loadError = nil
        } else {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
            let fileCount = magicFiles().count
            loadError = errors.joined(separator: " ")
                + " [running build \(version) (\(build)), \(fileCount) magic item file(s) found]"
        }
    }

    /// Mesma varredura de `SpellDatabase.priestFiles()` — nome + URL de
    /// todo `magic_*.json` do bundle, achados e lidos da MESMA URL (ver o
    /// histórico de bug documentado lá pro porquê disso importar).
    private func magicFiles() -> [(name: String, url: URL)] {
        guard let resourceURL = Bundle.main.resourceURL,
              let entries = try? FileManager.default.contentsOfDirectory(at: resourceURL,
                                                                          includingPropertiesForKeys: nil)
        else { return [] }

        let byName = Dictionary(entries
            .filter { $0.pathExtension == "json" && $0.deletingPathExtension().lastPathComponent.hasPrefix("magic_") }
            .map { ($0.deletingPathExtension().lastPathComponent, $0) },
            uniquingKeysWith: { first, _ in first })

        return byName.keys.sorted().compactMap { name in byName[name].map { (name, $0) } }
    }

    func item(id: String) -> CompendiumMagicItem? {
        items.first { $0.id == id }
    }

    /// Candidatos ordenados por semelhança — mesmo padrão de
    /// `SpellDatabase.matches(for:...)`, usado pelo campo "use as typed"
    /// do `MagicItemPickerSheet`.
    func matches(for text: String, limit: Int = 5, minimumScore: Double = 0.34) -> [MagicItemMatch] {
        let query = Fuzzy.normalize(text)
        guard !query.isEmpty else { return [] }

        var scored: [MagicItemMatch] = []
        scored.reserveCapacity(items.count)
        for item in items {
            let score = Fuzzy.similarity(query, item.normalizedName)
            if score >= minimumScore {
                scored.append(MagicItemMatch(item: item, score: score))
            }
        }
        scored.sort { lhs, rhs in
            if lhs.score == rhs.score { return lhs.item.name < rhs.item.name }
            return lhs.score > rhs.score
        }
        if scored.count > limit {
            scored.removeLast(scored.count - limit)
        }
        return scored
    }

    /// As 7 categorias amplas do Compendium — A-M/N-Z de "Miscellaneous"
    /// mesclam na mesma (o split é só artefato de arquivo de extração, os
    /// dois têm `broadCategory == "Miscellaneous"`). Ordem fixa por
    /// tamanho aproximado do grupo, maior primeiro, igual ao critério já
    /// usado em `KitCompendiumView.groupOrder`.
    static let categoryOrder = [
        "Miscellaneous", "Weapon", "Potion/Oil", "Rod/Staff/Wand",
        "Scroll/Book", "Ring", "Armor/Shield",
    ]
}

struct MagicItemMatch: Identifiable, Hashable {
    let item: CompendiumMagicItem
    let score: Double
    var id: String { item.id }
    var isStrong: Bool { score >= 0.72 }
}

/// Agrupamento por fonte, pro filtro "grupo primeiro, livro depois" pedido
/// pelo usuário ("Os dois: grupo primeiro, livro depois", resposta à
/// pergunta sobre granularidade). Cada `CompendiumMagicItem` pode ter mais de uma
/// fonte (`sources` é lista) — `MagicItemSourceGroup.groups(for:)` devolve
/// TODOS os grupos que pelo menos uma fonte do item toca, já que um item
/// reimpresso num Dragon Magazine E na Encyclopedia Magica pertence aos
/// dois pro propósito do filtro.
enum MagicItemSourceGroup: String, CaseIterable, Identifiable, Hashable {
    case encyclopediaMagica = "Encyclopedia Magica"
    case dragonMagazine = "Dragon Magazine"
    case polyhedronNewszine = "Polyhedron Newszine"
    case tradingCards = "Trading Cards"
    case basicDnD = "Basic D&D (non-AD&D)"
    case otherSourcebooks = "Other Sourcebooks"
    case unknown = "Unknown Source"

    var id: String { rawValue }

    /// Linha-lista de títulos que caem no grupo "Basic D&D (non-AD&D)" —
    /// escrita por extenso ("Dungeons & Dragons ...", não "D&D ...").
    /// A primeira versão deste checker (protótipo em Python, ver TODO.md
    /// item 30) checava o prefixo abreviado "D&D Master Set" e por isso
    /// deixava "Dungeons & Dragons Master Set" cair no catch-all "Other
    /// Sourcebooks" por engano — corrigido aqui antes de qualquer código
    /// Swift existir, checando o título completo.
    private static let basicDnDPrefixes = [
        "Dungeons & Dragons Rules Cyclopedia",
        "Dungeons & Dragons Basic Set",
        "Dungeons & Dragons Expert Set",
        "Dungeons & Dragons Companion Set",
        "Dungeons & Dragons Master Set",
        "Dungeons & Dragons Immortals Set",
    ]

    /// Grupo de UMA fonte específica (`book`, como aparece em
    /// `MagicItemSource.book`) — usado internamente por `groups(for:)`.
    static func group(forBook book: String?) -> MagicItemSourceGroup {
        guard let book, !book.isEmpty else { return .unknown }
        if book == "Encyclopedia Magica" { return .encyclopediaMagica }
        if book.hasPrefix("Dragon Magazine") { return .dragonMagazine }
        if book.hasPrefix("Polyhedron Newszine") { return .polyhedronNewszine }
        if book.contains("Trading Cards") { return .tradingCards }
        if basicDnDPrefixes.contains(where: { book.hasPrefix($0) }) { return .basicDnD }
        return .otherSourcebooks
    }

    /// TODOS os grupos que o item toca (um por fonte distinta, sem
    /// repetir) — item sem nenhuma fonte cadastrada cai só em `.unknown`.
    static func groups(for item: CompendiumMagicItem) -> Set<MagicItemSourceGroup> {
        guard !item.sources.isEmpty else { return [.unknown] }
        return Set(item.sources.map { group(forBook: $0.book) })
    }

    /// Todo título de livro que pertence a este grupo, dentre os itens
    /// passados — pra alimentar o segundo nível do filtro ("livro depois")
    /// depois que o usuário já escolheu um grupo.
    static func books(in group: MagicItemSourceGroup, items: [CompendiumMagicItem]) -> [String] {
        var seen: Set<String> = []
        for item in items {
            for source in item.sources {
                guard let book = source.book, !book.isEmpty else { continue }
                guard MagicItemSourceGroup.group(forBook: book) == group else { continue }
                seen.insert(book)
            }
        }
        return seen.sorted()
    }
}

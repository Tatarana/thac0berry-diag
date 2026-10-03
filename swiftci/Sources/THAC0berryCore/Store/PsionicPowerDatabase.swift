import Foundation

/// Base de powers psiônicos — lida de `Resources/psionic_powers.json` em
/// runtime, mesmo mecanismo de `KitDatabase`/`RulesDatabase`
/// (`Bundle.main.resourceURL` + `FileManager.contentsOfDirectory`, já
/// comprovado confiável neste toolchain em vez de `Bundle.main.url
/// (forResource:)` direto — ver o histórico de bug documentado em
/// `SpellDatabase.swift`).
///
/// Rodada "fundação primeiro" dos Psiônicos (2026-10-01, ver TODO.md): só
/// o banco consultável existe por enquanto — sem personagem conhecendo
/// power nenhum ainda, por isso esta classe não tem nada parecido com
/// `KitDatabase.kits(allowedFor:)` (não existe "classe elegível" aqui,
/// todo power é só do Psionicist, que ainda não é uma `CharacterClass`
/// jogável).
final class PsionicPowerDatabase: ObservableObject {
    @Published private(set) var powers: [PsionicPower] = []
    @Published private(set) var loadError: String? = nil

    init() {
        load()
    }

    private func load() {
        guard let resourceURL = Bundle.main.resourceURL,
              let fileURL = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
                  .first(where: { $0.lastPathComponent == "psionic_powers.json" })
        else {
            loadError = "Couldn't find psionic_powers.json in the app bundle."
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            powers = try JSONDecoder().decode([PsionicPower].self, from: data).sorted { $0.title < $1.title }
        } catch {
            loadError = "Couldn't read psionic_powers.json: \(error.localizedDescription)"
        }
    }

    func power(id: String) -> PsionicPower? {
        powers.first { $0.id == id }
    }

    /// Acha o power pelo TÍTULO — mesmo papel de `KitDatabase.kit(named:)`,
    /// pensado pra um dia virar o lookup usado por um campo de texto livre
    /// na ficha (Wild Talent, "known powers" do Psionicist) sem precisar
    /// guardar `id` nenhum junto do texto digitado.
    func power(named title: String) -> PsionicPower? {
        let normalized = Fuzzy.normalize(title)
        guard !normalized.isEmpty else { return nil }
        return powers.first { Fuzzy.normalize($0.title) == normalized }
    }

    /// Ordem fixa das seis disciplinas canônicas (CPsiH cap. 1, "A
    /// Psionics Primer") — mesma ideia de `KitCompendiumView.priestGroupOrder`,
    /// a leitura mais natural pra quem já conhece o livro em vez de
    /// alfabética (que juntaria Clairsentience/Metapsionics longe de
    /// Psychokinesis/Psychometabolism/Psychoportation, que são
    /// alfabeticamente vizinhas só por acaso do prefixo "Psycho-").
    static let disciplineOrder = [
        "Clairsentience", "Psychokinesis", "Psychometabolism",
        "Psychoportation", "Telepathy", "Metapsionics",
    ]

    func powers(discipline: String) -> [PsionicPower] {
        powers.filter { $0.discipline == discipline }
    }
}

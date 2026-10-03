import Foundation

/// Base de kits — lida de `Resources/kits.json` em runtime. Começou só
/// com os de sacerdote; hoje cobre quatro grupos no mesmo arquivo/array
/// (Priest, Wizard, Warrior, Rogue — ver o comentário no topo de
/// `Models/Kit.swift`), todos filtrados pelo mesmo `classEligibility`
/// genérico abaixo, sem nenhum caso especial por classe.
///
/// HISTÓRICO (pra quem ler isto e se assustar de novo): entre v0.81 e
/// v0.84, TRÊS tentativas diferentes de ler isso de JSON de bundle
/// falharam com a mesma mensagem genérica ("The data couldn't be read
/// because it is missing"). A causa real era `DecodingError.keyNotFound`
/// (13 dos 97 kits não têm a chave `mechanics.armor.allowedTypes`), que o
/// Swift renderiza com essa mesma frase de "missing" — fácil de confundir
/// com arquivo sumido. Isso já foi corrigido em `KitArmorRules.init(from:)`
/// (`Models/Kit.swift`), que trata a chave ausente com `decodeIfPresent`.
/// Por causa disso o app passou a embutir os 91 kits como literal Swift
/// puro (`EmbeddedKits.swift`) — só que esse literal gigante (~1MB, ~91
/// structs aninhados) virou um problema NOVO e diferente (2026-09-25): o
/// archive de distribuição do Swift Playgrounds trava, porque a
/// compilação de Release usa "whole module optimization" e recompila tudo
/// junto, não importa quantos arquivos-parte o literal esteja dividido —
/// só o build de Debug/execução local se beneficia da divisão. Como o
/// bug de decode original já está corrigido, voltar pro JSON resolve os
/// dois problemas: nada mais passa pelo type-checker em tempo de
/// compilação, e o decode não tropeça mais na chave ausente.
final class KitDatabase: ObservableObject {
    @Published private(set) var kits: [Kit] = []
    @Published private(set) var loadError: String? = nil

    init() {
        load()
    }

    private func load() {
        guard let resourceURL = Bundle.main.resourceURL,
              let fileURL = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
                  .first(where: { $0.lastPathComponent == "kits.json" })
        else {
            loadError = "Couldn't find kits.json in the app bundle."
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            kits = try JSONDecoder().decode([Kit].self, from: data).sorted { $0.name < $1.name }
        } catch {
            loadError = "Couldn't read kits.json: \(error.localizedDescription)"
        }
    }

    func kit(id: String) -> Kit? {
        kits.first { $0.id == id }
    }

    /// Acha o kit pelo NOME — `character.kit` só guarda `kit.name` (texto
    /// livre, ver `KitField`/`KitPickerSheet`), sem `id` nenhum salvo na
    /// ficha. Usado por `addBonusProficiencies(forKit:)` (item 5 do
    /// pedido do usuário, 2026-09-24) pra achar `mechanics.proficiencies.bonus`
    /// a partir do texto do campo "Kit" do cabeçalho. `nil` pra texto
    /// digitado à mão que não bate com kit nenhum da base — nesse caso
    /// não tem proficiência bônus pra adicionar mesmo.
    func kit(named name: String) -> Kit? {
        let normalized = Fuzzy.normalize(name)
        guard !normalized.isEmpty else { return nil }
        return kits.first { Fuzzy.normalize($0.name) == normalized }
    }

    /// Kits elegíveis pra uma classe (como o valor aparece em
    /// `classEligibility.allowedClasses` — "Cleric", "Druid" etc.),
    /// alfabético. Sem filtro (`nil`/vazio) devolve a base inteira.
    ///
    /// Caso especial: os 57 kits de sacerdote especializado (um por
    /// divindade) só têm `"Specialty Priest"` em `allowedClasses` — é como
    /// o dado de origem descreve o grupo, mas o app não tem uma classe
    /// separada "Specialty Priest" (`CharacterClass` só tem `Cleric`,
    /// `Druid` etc.): um sacerdote especializado é jogado mecanicamente
    /// como Cleric. Sem esse caso especial, escolher "Cleric" na ficha
    /// esconderia os 57 kits de divindade — justamente o grupo mais
    /// numeroso e o que mais faz sentido pra um Cleric escolher.
    func kits(allowedFor className: String? = nil) -> [Kit] {
        guard let className, !className.isEmpty else { return kits }
        return kits.filter { kit in
            let allowed = kit.classEligibility.allowedClasses
            if allowed.contains(className) { return true }
            if className == "Cleric" && allowed.contains("Specialty Priest") { return true }
            return false
        }
    }

    /// Só os kits genéricos (Fighting-Monk, Warrior Priest, ...) — exclui
    /// os de sacerdote especializado por divindade.
    func generalKits() -> [Kit] {
        kits.filter { !$0.isSpecialtyPriest }
    }

    /// Só os kits de sacerdote especializado, opcionalmente restritos a um
    /// panteão (como aparece em `pantheon`, ex. "Faerûnian").
    func specialtyPriestKits(pantheon: String? = nil) -> [Kit] {
        let specialty = kits.filter(\.isSpecialtyPriest)
        guard let pantheon, !pantheon.isEmpty else { return specialty }
        return specialty.filter { $0.pantheon == pantheon }
    }
}

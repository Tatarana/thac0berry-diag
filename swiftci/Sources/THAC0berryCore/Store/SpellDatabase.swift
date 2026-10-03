import Foundation

/// Base de magias embutida mais a busca aproximada usada pelo log escrito
/// à mão.
///
/// A base fica espalhada em duas fontes bem diferentes de propósito.
/// O punhado de exemplos usado por `SampleCharacter` (o personagem Kelmon
/// pré-carregado) vem de `EmbeddedSampleSpells.spells` — literais Swift de
/// verdade, sem JSON nenhum de permeio (ver o comentário grande naquele
/// arquivo: um bug de campo em duas partes — primeiro `spells.json` do
/// bundle, depois até uma versão embutida como STRING JSON gigante, as
/// duas dando "The data couldn't be read because it is missing"). A base
/// de verdade de sacerdote (`priest_*.json`) e, desde 2026-09-29, a de
/// mago (`wizard_*.json` — Grimório do Mago) entram como um arquivo por
/// nível/tipo no bundle, no formato que `Scripts/convert_spells.py`/
/// `Scripts/convert_wizard_spells.py` geram a partir dos dados brutos da
/// wiki (ver TODO.md item 1).
///
/// Histórico do bug "priest_*.json não lê" (ver TODO.md pra timeline
/// completa): a v1.82 tratava como corrida de timing no primeiro acesso
/// ao bundle (uma pausa de 0.35s + uma tentativa a mais, reusando a
/// mesma URL capturada na primeira varredura) — não resolveu; o usuário
/// viu a mensagem "(after retry)" nos mesmos 10 arquivos de sempre. Isso
/// descarta corrida de timing simples: uma corrida de verdade some ou
/// muda de arquivo entre tentativas, não falha sempre exatamente igual.
/// A v1.83 apostou que o culpado fosse o pipeline de PROCESSAMENTO de
/// recursos (`Package.swift` trocando `.process("Resources")` por
/// `.copy("Resources")`) — errado, e pior: `.copy` quebrou o CODE SIGNING
/// do build inteiro (erro `NSOSStatusErrorDomain Code=-67072` na
/// instalação, nem chegava a abrir o app). `Package.swift` voltou pra
/// `.process("Resources")` na v1.85 — a mudança de empacotamento de
/// recursos foi abandonada por completo. O que ficou (e continua
/// valendo) é só do lado da LEITURA, em `load()`: até 4 tentativas,
/// re-escaneando o bundle (recursivamente, não só a raiz) a cada uma em
/// vez de reusar uma URL antiga, e guardando o erro REAL (domínio+código
/// do `NSError`, ou existência/tamanho do arquivo em disco) em vez de só
/// "missing" — se o bug original ainda aparecer, a mensagem de erro na
/// tela inicial já vem com uma pista de verdade em vez de precisar
/// adivinhar de novo.
final class SpellDatabase: ObservableObject {
    @Published private(set) var spells: [Spell] = []
    @Published private(set) var loadError: String? = nil

    init() {
        load()
    }

    private func load() {
        var merged: [Spell] = []
        var seenIDs: Set<String> = []
        var errors: [String] = []

        // Exemplos do Kelmon primeiro — igual antes, prioridade no merge
        // abaixo (nenhum id da base real de sacerdote sobrescreve um
        // exemplo igual). Literais Swift, sem JSON nem bundle nenhum no
        // meio — nada aqui pode falhar em runtime.
        for spell in EmbeddedSampleSpells.spells {
            guard !seenIDs.contains(spell.id) else { continue }
            seenIDs.insert(spell.id)
            merged.append(spell)
        }

        // "priest_" (sacerdote) e "wizard_" (mago, 2026-09-29 — Grimório
        // do Mago) — mesmo formato de arquivo, mesmo tratamento de erro,
        // só o prefixo muda.
        var pending = bundleFiles(withPrefix: "priest_") + bundleFiles(withPrefix: "wizard_")
        var lastFailure: [String: String] = [:]  // nome -> descrição do erro real (2026-09-29)

        // Até 4 tentativas, com pausa crescente entre elas, RE-VARRENDO o
        // diretório a cada tentativa (2026-09-29 — v1.85, ver comentário
        // grande no topo do arquivo pra timeline completa). A v1.82
        // tentava de novo com a MESMA URL capturada na primeira varredura
        // e uma pausa fixa de 0.35s — não ajudou nada: o usuário viu a
        // mensagem "(after retry)" nos mesmos 10 arquivos de Priest de
        // sempre, o que descarta a hipótese de corrida de timing simples
        // (uma corrida de verdade teria sumido ou pelo menos mudado de
        // arquivo entre tentativas). A v1.83 tentou mexer em COMO os
        // recursos são empacotados (`Package.swift`) e isso quebrou o
        // build de um jeito pior (falha de code signing) — foi revertido.
        // O que fica é só isto: re-escanear o bundle do zero (recursivo,
        // não só a raiz — sem custo, e cobre qualquer variação de layout)
        // a cada tentativa, em vez de reusar a mesma URL antiga.
        for attempt in 1...4 {
            if attempt > 1 {
                Thread.sleep(forTimeInterval: 0.3 * Double(attempt))
                pending = bundleFiles(names: Set(pending.map { $0.name }))
            }

            var stillPending: [(name: String, url: URL)] = []
            for file in pending {
                switch readBatch(at: file.url) {
                case .success(let batch):
                    for spell in batch {
                        guard !seenIDs.contains(spell.id) else { continue }
                        seenIDs.insert(spell.id)
                        merged.append(spell)
                    }
                case .failure(let reason):
                    lastFailure[file.name] = reason
                    stillPending.append(file)
                }
            }
            pending = stillPending
            if pending.isEmpty { break }
        }

        for file in pending {
            let reason = lastFailure[file.name] ?? "unknown"
            errors.append("Failed to read \(file.name).json after 4 tries (\(reason))")
        }

        spells = merged
        if errors.isEmpty {
            loadError = nil
        } else {
            // Só sobra erro aqui se algum `priest_*.json`/`wizard_*.json`
            // do bundle falhar pra ler ou decodificar — os exemplos do
            // Kelmon não passam mais por leitura nenhuma (literais Swift,
            // ver `EmbeddedSampleSpells.swift`). A versão/build entra
            // junto na mensagem — ajudou a confirmar, na rodada anterior
            // desse bug, que o build testado era mesmo o mais novo.
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
            let priestCount = bundleFiles(withPrefix: "priest_").count
            let wizardCount = bundleFiles(withPrefix: "wizard_").count
            loadError = errors.joined(separator: " ")
                + " [running build \(version) (\(build)), \(priestCount) priest file(s), \(wizardCount) wizard file(s) found]"
        }
    }

    /// Resultado de `readBatch` — like `Result<[Spell], String>`, mas sem
    /// usar o `Result` de verdade da stdlib: seu segundo parâmetro de tipo
    /// exige conformidade com o protocolo `Error`, e `String` não conforma
    /// a ele ("Type 'String' does not conform to protocol 'Error'" — foi
    /// exatamente esse o erro de COMPILAÇÃO que a v1.83 saiu com, achado
    /// pelo usuário antes mesmo de rodar no iPad). Esse enum próprio evita
    /// o problema de raiz sem precisar criar um wrapper conforme a `Error`
    /// só pra isso.
    private enum ReadResult {
        case success([Spell])
        case failure(String)
    }

    /// Lê e decodifica um arquivo de magias. Em caso de falha, devolve uma
    /// descrição de verdade do erro (domínio+código do `NSError`, ou se o
    /// arquivo existe no disco e qual o tamanho dele) em vez de só `nil`
    /// como antes (2026-09-29 — v1.83): se essa tentativa de conserto
    /// também não resolver, a PRÓXIMA rodada de diagnóstico já vem com
    /// dado de verdade em vez de precisar adivinhar de novo.
    private func readBatch(at url: URL) -> ReadResult {
        let fm = FileManager.default
        do {
            let data = try Data(contentsOf: url)
            do {
                let batch = try JSONDecoder().decode([Spell].self, from: data)
                return .success(batch)
            } catch {
                return .failure("decode error, \(data.count) bytes read: \(error.localizedDescription)")
            }
        } catch {
            let nsError = error as NSError
            let exists = fm.fileExists(atPath: url.path)
            let attributes = try? fm.attributesOfItem(atPath: url.path)
            let size = attributes?[.size] as? Int
            let existsDesc = exists ? "exists, size=\(size.map(String.init) ?? "?")" : "does not exist on disk"
            return .failure("\(nsError.domain)#\(nsError.code) — \(existsDesc)")
        }
    }

    /// Nome + URL de todo `<prefix>*.json` achado numa varredura
    /// RECURSIVA do bundle (2026-09-29 — era uma varredura rasa de
    /// `Bundle.main.resourceURL` só; trocada pra recursiva sem custo real
    /// e sem depender de os recursos ficarem soltos bem na raiz do
    /// bundle). Lida dessa MESMA URL depois (em vez de descobrir o nome
    /// de um jeito e pedir a URL de novo por outro caminho, como o código
    /// fazia antes — ver histórico do bug em `EmbeddedSampleSpells.swift`).
    private func bundleFiles(withPrefix prefix: String) -> [(name: String, url: URL)] {
        guard let resourceURL = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: resourceURL,
                                                                includingPropertiesForKeys: nil,
                                                                options: [.skipsHiddenFiles])
        else { return [] }

        var byName: [String: URL] = [:]
        for case let url as URL in enumerator {
            guard url.pathExtension == "json" else { continue }
            let name = url.deletingPathExtension().lastPathComponent
            guard name.hasPrefix(prefix) else { continue }
            // `uniquingKeysWith`-style dedupe: nomes duplicados não
            // deveriam existir, mas não vale travar o app (fatal error)
            // se algum cenário esquisito de build do Playgrounds produzir
            // um.
            if byName[name] == nil { byName[name] = url }
        }
        return byName.keys.sorted().compactMap { name in byName[name].map { (name, $0) } }
    }

    /// Re-busca (por nome, varredura nova) as URLs de um subconjunto de
    /// arquivos — usado entre tentativas de `load()` pra nunca reusar uma
    /// URL capturada numa varredura anterior (2026-09-29, ver comentário
    /// grande em `load()`).
    private func bundleFiles(names: Set<String>) -> [(name: String, url: URL)] {
        guard let resourceURL = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: resourceURL,
                                                                includingPropertiesForKeys: nil,
                                                                options: [.skipsHiddenFiles])
        else { return [] }

        var found: [String: URL] = [:]
        for case let url as URL in enumerator {
            guard url.pathExtension == "json" else { continue }
            let name = url.deletingPathExtension().lastPathComponent
            guard names.contains(name), found[name] == nil else { continue }
            found[name] = url
        }
        return names.sorted().compactMap { name in found[name].map { (name, $0) } }
    }

    func spell(id: String) -> Spell? {
        spells.first { $0.id == id }
    }

    func spells(caster: CasterType, level: Int) -> [Spell] {
        spells
            .filter { $0.caster == caster && $0.level == level }
            .sorted { $0.name < $1.name }
    }

    /// Candidatos ordenados por semelhança com o que foi escrito.
    /// `limit` mantém a lista curta o bastante para caber ao lado da linha.
    ///
    /// `caster`/`level`, quando informados, filtram a base ANTES de cortar
    /// pelo `limit` — não depois. Cortar primeiro e filtrar depois (como
    /// era) deixava um slot de círculo 1 sem nenhum candidato só porque as
    /// 5 magias mais parecidas do app inteiro eram todas de outros
    /// círculos (ex.: escrever "cure" no círculo 1 - "Cure Light Wounds" -
    /// esbarrava em "Cure Rot"/"Cure Scurvy"/"Cure Madness", todas de
    /// círculos mais altos e com nome mais parecido letra a letra,
    /// tomando as 5 vagas antes do filtro por círculo/classe rodar).
    /// `restrictToIDs` (2026-09-29 — Livro de Magias do Mago): quando
    /// informado, só magias com id NESTE conjunto entram na pontuação —
    /// usado pra restringir a busca da Folha de Magias ao livro pessoal do
    /// Mago (`PlayerCharacter.wizardSpellbookMatchedIDs`) em vez da base
    /// inteira. `nil` (o padrão) continua buscando em tudo, como sempre —
    /// é o que o Clérigo usa, que não precisa "aprender" magia nenhuma.
    func matches(for text: String, limit: Int = 5, minimumScore: Double = 0.34,
                 caster: CasterType? = nil, level: Int? = nil,
                 restrictToIDs: Set<String>? = nil) -> [SpellMatch] {
        let query = Fuzzy.normalize(text)
        guard !query.isEmpty else { return [] }

        // Passos separados e com tipo explícito de propósito: uma cadeia
        // única de map/filter/sorted estoura o tempo de inferência do
        // compilador ("unable to type-check this expression in reasonable
        // time") no Swift Playgrounds.
        var scored: [SpellMatch] = []
        scored.reserveCapacity(spells.count)

        for spell in spells {
            if let caster, spell.caster != caster { continue }
            if let level, spell.level != level { continue }
            if let restrictToIDs, !restrictToIDs.contains(spell.id) { continue }
            let score: Double = Fuzzy.similarity(query, spell.normalizedName)
            if score >= minimumScore {
                scored.append(SpellMatch(spell: spell, score: score))
            }
        }

        scored.sort { (lhs: SpellMatch, rhs: SpellMatch) -> Bool in
            if lhs.score == rhs.score {
                return lhs.spell.name < rhs.spell.name
            }
            return lhs.score > rhs.score
        }

        if scored.count > limit {
            scored.removeLast(scored.count - limit)
        }
        return scored
    }
}

struct SpellMatch: Identifiable, Hashable {
    let spell: Spell
    let score: Double

    var id: String { spell.id }

    /// Acima disso o app se sente à vontade para pré-selecionar o candidato.
    var isStrong: Bool { score >= 0.72 }

    var confidenceLabel: String {
        switch score {
        case 0.85...: return "near match"
        case 0.6..<0.85: return "likely"
        default: return "guess"
        }
    }
}

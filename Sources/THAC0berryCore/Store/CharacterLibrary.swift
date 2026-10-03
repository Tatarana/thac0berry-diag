import Foundation
#if canImport(Combine)
import Combine
#endif

/// Guarda campanhas e personagens em um JSON único no diretório Documents,
/// com a mesma decisão de segurança do Just Pencil It: proteção de dados
/// nativa do iOS na classe `.completeUnlessOpen`, sem criptografia própria
/// por cima. As duas listas são irmãs, ligadas por
/// `PlayerCharacter.campaignID` — não personagens aninhados dentro da
/// campanha — porque um personagem pode existir SEM campanha (o Sandbox,
/// pra preparar alguém antes da campanha começar de verdade).
final class CharacterLibrary: ObservableObject {
    @Published var campaigns: [Campaign] = [] {
        didSet { scheduleSave() }
    }
    @Published var characters: [PlayerCharacter] = [] {
        didSet { scheduleSave() }
    }
    /// Magias favoritadas — pedido do usuário (2026-09-19): "quem escolhe
    /// as magias são os jogadores", então um jogador que gosta de uma
    /// spell tende a usá-la em QUALQUER personagem Priest que criar, não só
    /// num específico. Por isso favoritar deixou de ser um campo de
    /// `PlayerCharacter` e virou uma preferência global daqui — um jogador,
    /// um conjunto de favoritas, usado em toda ficha e no Grimório
    /// (inclusive aberto direto da Tela Principal, sem personagem nenhum).
    @Published var favoriteSpellIDs: Set<String> = [] {
        didSet { scheduleSave() }
    }
    /// Item 3 do pedido do usuário (2026-09-24): "nas configurações gerais,
    /// deixar o jogador definir o tipo de folha padrão: liso, pautado ou
    /// quadriculado" — preferência global (não por campanha/personagem),
    /// lida por `Campaign.addNotebookPage(kind:paperStyle:)` toda vez que
    /// uma folha NOVA nasce. Trocar aqui não muda folha já existente — só
    /// o padrão de folhas futuras (ver `NotebookPaperStyle`).
    @Published var defaultNotebookPaperStyle: NotebookPaperStyle = .plain {
        didSet { scheduleSave() }
    }
    @Published private(set) var lastError: String? = nil

    private struct LibraryData: Codable {
        var campaigns: [Campaign] = []
        var characters: [PlayerCharacter] = []
        /// Opcional só pra ler bibliotecas salvas ANTES de favoritar virar
        /// global (chave ainda não existia) sem falhar o decode — mesma
        /// convenção do resto do app pra campo novo em JSON antigo.
        var favoriteSpellIDs: Set<String>? = nil
        /// Mesma convenção — biblioteca salva antes deste pedido
        /// (2026-09-24) não tem essa chave; ausência vira `.plain`, que já
        /// era o único estilo de folha que existia.
        var defaultNotebookPaperStyle: NotebookPaperStyle? = nil

        init(campaigns: [Campaign] = [], characters: [PlayerCharacter] = [], favoriteSpellIDs: Set<String>? = nil,
             defaultNotebookPaperStyle: NotebookPaperStyle? = nil) {
            self.campaigns = campaigns
            self.characters = characters
            self.favoriteSpellIDs = favoriteSpellIDs
            self.defaultNotebookPaperStyle = defaultNotebookPaperStyle
        }

        enum CodingKeys: String, CodingKey {
            case campaigns, characters, favoriteSpellIDs, defaultNotebookPaperStyle
        }

        /// Decode manual (2026-09-20) — em vez do sintetizado automático,
        /// que faz `[Campaign]`/`[PlayerCharacter]` inteiros falharem se UM
        /// item só vier com um campo ilegível (um enum com valor que este
        /// build não reconhece mais, por exemplo). `LossyArray` (abaixo)
        /// descarta só o item ruim, não a lista toda — antes, um personagem
        /// corrompido levava todo mundo junto de arrasto.
        ///
        /// Isso é uma rede de segurança, não a causa do bug que o usuário
        /// relatou (2026-09-20: "toda versão nova eu perco meus
        /// personagens") — aquele era outra coisa: reimportar o .zip inteiro
        /// no Swift Playgrounds cria uma cópia NOVA do projeto, com sua
        /// própria pasta Documents vazia (mesmo bundle identifier, sandbox
        /// diferente) — `library.json` simplesmente não existe aí, sem
        /// decode nenhum envolvido, daí `load()` cair direto no branch de
        /// "primeira execução" e semear o Kelmon de exemplo, sem erro na
        /// tela. Mantém o app aberto pra recomeçar via Export/Import
        /// (`SettingsView`) — mas o de verdade é não reimportar o projeto
        /// inteiro a cada versão nova.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            campaigns = try container.decodeIfPresent(LossyArray<Campaign>.self, forKey: .campaigns)?.elements ?? []
            characters = try container.decodeIfPresent(LossyArray<PlayerCharacter>.self, forKey: .characters)?.elements ?? []
            favoriteSpellIDs = try container.decodeIfPresent(Set<String>.self, forKey: .favoriteSpellIDs)
            defaultNotebookPaperStyle = try container.decodeIfPresent(NotebookPaperStyle.self, forKey: .defaultNotebookPaperStyle)
        }
    }

    private let fileName = "library.json"
    private var saveWorkItem: DispatchWorkItem?

    private var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask)[0]
        return documents.appendingPathComponent(fileName)
    }

    init() {
        load()
    }

    // MARK: - Leitura e escrita

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // Primeira execução: pedido do usuário (2026-09-24) — nada de
            // campanha/personagem de exemplo (o Kelmon) semeado sozinho.
            // A pasta abre vazia mesmo; `campaigns`/`characters` já nascem
            // `[]` pelos inicializadores das propriedades acima.
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(LibraryData.self, from: data)
            campaigns = decoded.campaigns
            characters = decoded.characters
            if let saved = decoded.favoriteSpellIDs {
                favoriteSpellIDs = saved
            } else {
                // Migração: biblioteca salva antes de favoritar virar
                // global — junta os favoritos que já existiam por
                // personagem (campo legado em `PlayerCharacter`) num
                // conjunto só, pra ninguém perder favorito nenhum na troca.
                favoriteSpellIDs = Set(decoded.characters.flatMap(\.favoriteSpellIDs))
            }
            defaultNotebookPaperStyle = decoded.defaultNotebookPaperStyle ?? .plain
        } catch {
            // JSON gravado por uma versão anterior (sem campanha, sem os
            // campos novos) não decodifica. Pedido do usuário (2026-09-24):
            // sem semear o Kelmon de exemplo automaticamente aqui também —
            // só avisa do erro e deixa a pasta vazia mesmo, pronta pra um
            // Import de backup (`SettingsView`) se o jogador tiver um.
            lastError = "Couldn't read the saved library: \(error.localizedDescription)"
        }
    }

    /// Salva com um pequeno atraso, para não escrever no disco a cada toque
    /// em um slot durante o combate.
    private func scheduleSave() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.saveNow()
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    func saveNow() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(LibraryData(campaigns: campaigns, characters: characters,
                                                       favoriteSpellIDs: favoriteSpellIDs,
                                                       defaultNotebookPaperStyle: defaultNotebookPaperStyle))
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
            lastError = nil
        } catch {
            lastError = "Couldn't save: \(error.localizedDescription)"
        }
    }

    // MARK: - Magias favoritas

    func isFavorite(_ spellID: String) -> Bool {
        favoriteSpellIDs.contains(spellID)
    }

    func toggleFavorite(_ spellID: String) {
        if favoriteSpellIDs.contains(spellID) {
            favoriteSpellIDs.remove(spellID)
        } else {
            favoriteSpellIDs.insert(spellID)
        }
    }

    // MARK: - Campanhas

    func campaign(with id: UUID) -> Campaign? {
        campaigns.first { $0.id == id }
    }

    func campaignIndex(of id: UUID) -> Int? {
        campaigns.firstIndex { $0.id == id }
    }

    /// Um binding pra campanha do personagem — `nil` se ele estiver no
    /// Sandbox, ou se (por algum motivo) o id apontar pra uma campanha que
    /// não existe mais. Índice recalculado a cada chamada de propósito
    /// (mesmo padrão dos outros bindings computados do app): é leve, e
    /// evita guardar um índice que pode ficar velho se a lista mudar.
    func binding(forCampaignID id: UUID?) -> Binding<Campaign>? {
        guard let id, let index = campaignIndex(of: id) else { return nil }
        return Binding(
            get: { self.campaigns[index] },
            set: { self.campaigns[index] = $0 }
        )
    }

    @discardableResult
    func addCampaign(name: String = "") -> Campaign {
        var new = Campaign()
        new.name = name
        campaigns.append(new)
        return new
    }

    func updateCampaign(_ campaign: Campaign) {
        guard let index = campaignIndex(of: campaign.id) else { return }
        campaigns[index] = campaign
    }

    /// Apaga a campanha — os personagens dela NÃO são apagados junto, só
    /// perdem o vínculo e voltam pro Sandbox (sessões/caderno da campanha
    /// é que somem de verdade, junto com o resto da campanha).
    func deleteCampaign(_ campaign: Campaign) {
        for index in characters.indices where characters[index].campaignID == campaign.id {
            characters[index].campaignID = nil
        }
        campaigns.removeAll { $0.id == campaign.id }
    }

    // MARK: - Personagens

    func character(with id: UUID) -> PlayerCharacter? {
        characters.first { $0.id == id }
    }

    func index(of id: UUID) -> Int? {
        characters.firstIndex { $0.id == id }
    }

    /// Um binding pro personagem — mesma ideia do `binding(forCampaignID:)`
    /// acima, usado onde uma lista filtrada (Sandbox, Elenco de uma
    /// campanha) precisa de um binding pra um item que não é o array
    /// `characters` inteiro.
    func binding(forCharacterID id: UUID) -> Binding<PlayerCharacter>? {
        guard let index = index(of: id) else { return nil }
        return Binding(
            get: { self.characters[index] },
            set: { self.characters[index] = $0 }
        )
    }

    /// Personagens sem campanha — o Sandbox.
    var sandboxCharacters: [PlayerCharacter] {
        characters.filter { $0.campaignID == nil }
    }

    func characters(in campaignID: UUID) -> [PlayerCharacter] {
        characters.filter { $0.campaignID == campaignID }
    }

    /// Cria a primeira folha de magia de um personagem que ainda não tem
    /// nenhuma, na sessão ativa da campanha — usado tanto ao criar um
    /// personagem já dentro de uma campanha quanto ao associar um
    /// personagem do Sandbox a uma. Sem campanha (ainda no Sandbox), não há
    /// onde criar a folha — fica pendente até ele ser associado.
    private func seedFirstSpellSheetIfNeeded(_ character: inout PlayerCharacter) {
        guard character.characterClass.hasSpellSheet, character.spellSheets.isEmpty,
              let campaignID = character.campaignID,
              let campaignIdx = campaignIndex(of: campaignID)
        else { return }
        let session = campaigns[campaignIdx].activeSession()
        var sheet = SpellSheet()
        sheet.sessionID = session.id
        sheet.title = "First day"
        sheet.wisdomAtCreation = character.spellSheetAbilityScoreAtCreation
        sheet.slotBoard = character.freshSlotBoard()
        character.spellSheets = [sheet]
    }

    @discardableResult
    func addCharacter(campaignID: UUID? = nil) -> PlayerCharacter {
        var new = PlayerCharacter()
        new.name = ""
        new.campaignID = campaignID
        seedFirstSpellSheetIfNeeded(&new)
        characters.append(new)
        return new
    }

    /// Duplica um personagem — nova identidade, sem histórico de sessões,
    /// pronto pra recomeçar. A ficha em si (atributos, equipamento,
    /// proficiências, magias favoritas...) é copiada como ponto de
    /// partida; o clone nasce vivo, mesmo que o original esteja morto.
    @discardableResult
    func cloneCharacter(_ original: PlayerCharacter, into campaignID: UUID?) -> PlayerCharacter {
        var clone = original
        clone.id = UUID()
        clone.campaignID = campaignID
        clone.status = .alive
        clone.diedOn = nil
        clone.deathNote = nil
        clone.clonedFromCharacterID = original.id
        clone.spellSheets = []
        seedFirstSpellSheetIfNeeded(&clone)
        characters.append(clone)
        return clone
    }

    /// Associa um personagem do Sandbox a uma campanha — se ele já tiver
    /// classe com ficha de magia e nenhuma folha ainda, ganha a primeira
    /// folha na sessão ativa da campanha, igual a um personagem que já
    /// nasceu dentro dela.
    func assign(_ character: PlayerCharacter, toCampaignID campaignID: UUID?) {
        guard let idx = index(of: character.id) else { return }
        characters[idx].campaignID = campaignID
        seedFirstSpellSheetIfNeeded(&characters[idx])
    }

    func markDead(_ character: PlayerCharacter, on date: Date, note: String) {
        guard let idx = index(of: character.id) else { return }
        characters[idx].status = .dead
        characters[idx].diedOn = date
        characters[idx].deathNote = note.isEmpty ? nil : note
    }

    func toggleArchived(_ character: PlayerCharacter) {
        guard let idx = index(of: character.id) else { return }
        characters[idx].status = characters[idx].status == .archived ? .alive : .archived
    }

    /// Traz um personagem morto ou aposentado de volta pro elenco ativo.
    func reviveToAlive(_ character: PlayerCharacter) {
        guard let idx = index(of: character.id) else { return }
        characters[idx].status = .alive
        characters[idx].diedOn = nil
        characters[idx].deathNote = nil
    }

    func deleteCharacter(_ character: PlayerCharacter) {
        characters.removeAll { $0.id == character.id }
    }

    func update(_ character: PlayerCharacter) {
        guard let index = index(of: character.id) else { return }
        characters[index] = character
    }

    // MARK: - Backup manual (Export/Import — 2026-09-20)

    /// Cópia dos dados salvos, pronta pra compartilhar (AirDrop, Arquivos,
    /// iCloud, e-mail pra si mesmo...). Existe porque reimportar o `.zip`
    /// de uma versão nova no Swift Playgrounds cria um projeto NOVO com sua
    /// própria pasta Documents vazia — `library.json` não atravessa esse
    /// tipo de atualização sozinho. Com um backup exportado, dá pra
    /// restaurar depois de qualquer reimportação, não importa a causa.
    func exportSnapshot() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(LibraryData(campaigns: campaigns, characters: characters,
                                                favoriteSpellIDs: favoriteSpellIDs,
                                                defaultNotebookPaperStyle: defaultNotebookPaperStyle))
    }

    struct ImportPreview {
        let campaignCount: Int
        let characterCount: Int
    }

    /// Só olha o arquivo, sem aplicar nada ainda — pra `SettingsView` poder
    /// mostrar "isso tem N campanhas e M personagens, substituir os M
    /// atuais?" antes do jogador confirmar (importar é destrutivo: troca a
    /// biblioteca inteira, não faz merge).
    func previewImport(from data: Data) throws -> ImportPreview {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(LibraryData.self, from: data)
        return ImportPreview(campaignCount: decoded.campaigns.count, characterCount: decoded.characters.count)
    }

    /// Aplica um backup exportado por `exportSnapshot()` — SUBSTITUI a
    /// biblioteca atual inteira. Quem chama já deve ter confirmado com o
    /// jogador (ver `previewImport(from:)`).
    func importSnapshot(from data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(LibraryData.self, from: data)
        campaigns = decoded.campaigns
        characters = decoded.characters
        favoriteSpellIDs = decoded.favoriteSpellIDs ?? Set(decoded.characters.flatMap(\.favoriteSpellIDs))
        defaultNotebookPaperStyle = decoded.defaultNotebookPaperStyle ?? .plain
        saveNow()
    }
}

/// Decodifica um array elemento por elemento — se UM item vier corrompido
/// (ou num formato que este build não reconhece mais), só ELE é
/// descartado, em vez de `Array<Element>.init(from:)` padrão, que faz o
/// array INTEIRO falhar assim que um item dá erro. `container.decode` só
/// "consome" a posição atual do array quando tem sucesso — por isso o
/// `try?` pra `AnyDecodableDiscard` no `else`: decodificar QUALQUER coisa
/// (mesmo sem usar o valor) avança o cursor e evita um laço infinito no
/// item ruim.
private struct LossyArray<Element: Decodable>: Decodable {
    private struct AnyDecodableDiscard: Decodable {}

    let elements: [Element]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [Element] = []
        while !container.isAtEnd {
            if let value = try? container.decode(Element.self) {
                result.append(value)
            } else {
                _ = try? container.decode(AnyDecodableDiscard.self)
            }
        }
        elements = result
    }
}

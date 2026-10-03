import Foundation

/// A lista canônica de cenários de campanha que o app reconhece pra
/// filtrar conteúdo — união dos valores de verdade que já existem em dois
/// corpora distintos, que usam rótulos ligeiramente diferentes pro mesmo
/// eixo:
/// - `Spell.setting` (1.795 magias): Generic, Forgotten Realms, Dark Sun,
///   Greyhawk, Planescape, Ravenloft.
/// - `Proficiency.campaignSettings` (372 proficiências): Core, Dark Sun,
///   Al-Qadim, Forgotten Realms, Spelljammer, Council of Wyrms,
///   Planescape.
///
/// Os dois têm um rótulo "sem cenário específico" diferente (Spell usa
/// "Generic", Proficiency usa "Core") pro MESMO conceito — conteúdo do
/// PHB/DMG básico, sempre disponível não importa quais cenários a
/// campanha ligou. Em vez de reescrever um dos dois corpora pra bater com
/// o outro (não vale a pena — cada um já é fiel à extração original de
/// sua fonte), `isGeneric(_:)` trata os dois como sinônimos só na hora de
/// filtrar.
enum CampaignSettingCatalog {
    /// Todo cenário "de verdade" que aparece em pelo menos um dos dois
    /// corpora — ordenado, pra popular o seletor da campanha. Greyhawk e
    /// Ravenloft só existem no corpus de magias; Al-Qadim, Spelljammer e
    /// Council of Wyrms só no de proficiências — a união cobre os dois.
    static let all: [String] = [
        "Al-Qadim",
        "Council of Wyrms",
        "Dark Sun",
        "Forgotten Realms",
        "Greyhawk",
        "Planescape",
        "Ravenloft",
        "Spelljammer",
    ]

    /// Os dois rótulos de "sem cenário específico" — conteúdo assim nunca
    /// é escondido pelo filtro de uma campanha, seja qual for o conjunto
    /// de cenários ligados (inclusive vazio).
    static func isGeneric(_ setting: String?) -> Bool {
        guard let setting else { return true }
        return setting == "Generic" || setting == "Core"
    }

    /// Um símbolo SF por cenário, pro filtro de ícones do Compendium de
    /// Proficiências (TODO.md item 18, rodada 2026-09-20 — usuário pediu
    /// "sem combos feios de formulário", ícone em vez de `Picker`). Cada
    /// escolha tenta lembrar o tema do cenário sem depender de arte nova:
    /// lua/estrelas pras Noites Árabes de Al-Qadim, réptil pros dragões do
    /// Council of Wyrms, sol impiedoso do deserto de Dark Sun, globo pro
    /// "mundo padrão" dos Forgotten Realms, colunas clássicas pro Greyhawk
    /// original, infinito pro multiverso de planos do Planescape, lua com
    /// névoa pro gótico do Ravenloft, e uma nave pro Spelljammer velejando
    /// no wildspace. Só strings — nenhuma dependência de SwiftUI aqui, é
    /// puro Foundation como o resto deste arquivo.
    static func icon(for setting: String) -> String {
        switch setting {
        case "Al-Qadim": return "moon.stars.fill"
        case "Council of Wyrms": return "lizard.fill"
        case "Dark Sun": return "sun.max.fill"
        case "Forgotten Realms": return "globe.americas.fill"
        case "Greyhawk": return "building.columns.fill"
        case "Planescape": return "infinity"
        case "Ravenloft": return "cloud.moon.fill"
        case "Spelljammer": return "paperplane.fill"
        default: return "questionmark"
        }
    }

    /// Logo de verdade por cenário — PNG com fundo transparente entregue
    /// pelo usuário (2026-09-21, `campaign-settings-icons.zip`), recortado
    /// e convertido aqui (fundo branco virou alpha) pra arte preta pura,
    /// pensada pra renderizar como TEMPLATE (`Image.bundled(_:)
    /// .renderingMode(.template)`) e herdar a mesma cor que o SF Symbol
    /// antigo usava — troca direta, sem mudar o resto do visual do selinho
    /// (`SettingFilterChip`) nem da lista de `CampaignSettingsEditorSheet`.
    /// `nil` quando não existe logo pro cenário — quem chama cai de volta
    /// pro SF Symbol de `icon(for:)`, mesmo padrão de fallback que
    /// `HomeIconTile` já usa pros ícones ilustrados.
    static func logoImageName(for setting: String) -> String? {
        switch setting {
        case "Al-Qadim": return "campaign_al_qadim"
        case "Council of Wyrms": return "campaign_council_of_wyrms"
        case "Dark Sun": return "campaign_dark_sun"
        case "Forgotten Realms": return "campaign_forgotten_realms"
        case "Greyhawk": return "campaign_greyhawk"
        case "Planescape": return "campaign_planescape"
        case "Ravenloft": return "campaign_ravenloft"
        case "Spelljammer": return "campaign_spelljammer"
        default: return nil
        }
    }

    /// Legenda curta pro selinho do filtro — os dois nomes compostos
    /// (`Council of Wyrms`, `Forgotten Realms`) não cabem inteiros num
    /// selinho de 56pt de largura; os outros seis já são curtos o
    /// bastante e ficam como estão. O nome completo continua aparecendo
    /// no tooltip de toque-e-segure (`actionTooltip`).
    static func shortLabel(for setting: String) -> String {
        switch setting {
        case "Council of Wyrms": return "Wyrms"
        case "Forgotten Realms": return "Forgotten"
        default: return setting
        }
    }
}

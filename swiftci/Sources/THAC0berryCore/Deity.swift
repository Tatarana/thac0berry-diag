import Foundation

/// Uma divindade do panteão de Forgotten Realms, vinda de *Faiths &
/// Avatars* e *Powers & Pantheons* (2ª edição) — 79 entradas ao todo (46 +
/// 33). Cobre o perfil narrativo (portfólio, símbolo, aliados/inimigos,
/// dogma, clero) E o statblock de combate do avatar (AC/HP/THAC0/magias/
/// saves) quando o livro traz um — 7 das 79 não têm avatar documentado
/// (ex. divindades "mortas"/"adormecidas" ou poderes conceituais demais
/// pra ter forma física, como Ao).
///
/// AJUSTE (2026-09-25): voltou a carregar de `Resources/deities.json` via
/// `Codable` (ver o comentário equivalente e mais detalhado em
/// `Rule.swift`/`RuleEntry` pro porquê) — o literal Swift gigante estava
/// entre os suspeitos de travar o archive de distribuição do Swift
/// Playgrounds. Continua vindo de um pipeline de extração externo — não
/// editar à mão, regenerar a partir da fonte se os dados mudarem.
struct Deity: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let book: String       // "Faiths & Avatars" ou "Powers & Pantheons"
    let bookCode: String   // "FA" ou "PP"

    /// "Over-power"/"Greater Power"/"Intermediate Power"/"Lesser Power"/
    /// "Demipower" — a hierarquia de poder divino do 2e. `nil` numa única
    /// entrada (Gwaeron Windstrom, um semideus recém-ascendido demais
    /// pro livro classificar). Tiamat veio do corpus extraído como
    /// "Letter Power" (erro de digitação do livro por "Lesser Power") —
    /// corrigido a pedido do usuário, que confirmou ser mesmo Lesser
    /// Power.
    let rank: String?

    let plane: String?

    /// `nil` só em Ao (o Over-power não tem alinhamento — está acima
    /// desse conceito).
    let alignment: String?

    /// "Dead"/"Missing"/"Slumbering" — estado da divindade no cenário
    /// (algumas morreram ou desapareceram em eventos do Realms). `nil`
    /// pra a grande maioria, que está ativa normalmente.
    let status: String?

    let portfolio: String
    let aliases: String?
    let domainName: String?
    let superior: String?
    let allies: String?
    let foes: String?
    let symbol: String?
    let worshiperAlignments: String?

    /// Nível/classe do avatar em combate (ex. "30-HD Air Elemental,
    /// Cleric 30, Mage 30") — `nil` junto com `avatarDescription` nas 7
    /// divindades sem avatar documentado.
    let avatarClassLevels: String?
    /// Statblock completo em prosa (AC/MV/HP/THAC0/#AT/Dmg/MR/SZ/
    /// ability scores/spells/saves) + táticas especiais — texto corrido,
    /// não campos estruturados (o livro mistura prosa com o statblock).
    let avatarDescription: String?

    /// Resumo de uma linha (ex. "WOR. ALIGN: Any") — reaproveitado do
    /// mesmo padrão de `KitDescription.briefSummary`.
    let briefSummary: String
    /// Mitologia, dogma, clero, ritos, templos — texto corrido completo.
    let fullText: String

    let categories: [String]
}

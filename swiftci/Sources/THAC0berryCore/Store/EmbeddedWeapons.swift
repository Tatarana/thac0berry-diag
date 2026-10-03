import Foundation

/// As 69 armas mundanas do PHB, embutidas como literais Swift de
/// verdade — SEM JSON, `Bundle`, `Data` ou `JSONDecoder` nenhum em
/// runtime. Mesmo padrão de `EmbeddedKits.swift`/`EmbeddedProficiencies.
/// swift` — ver o comentário em `KitDatabase.swift` pro histórico
/// completo de por que ler isso de JSON de bundle NÃO é confiável neste
/// toolchain.
///
/// Fonte: `weapons.json` (TODO.md itens 22/24 — corpus de itens mundanos
/// extraído do PHB, avaliado e confirmado contra a tabela original antes
/// de entrar aqui). Duas diferenças em relação ao JSON de origem, as
/// duas já discutidas e confirmadas com o usuário:
/// - O item lixo nenhum foi removido daqui (esse problema era só em
///   `armor_and_shields.json`, não neste arquivo).
/// - "Short bow" e "Composite short bow" (que no livro não têm dano
///   próprio — a munição Flight/Sheaf arrow é vendida à parte) viraram 2
///   variantes cada, igual "Long bow"/"Composite long bow" já eram no
///   JSON de origem, reaproveitando o MESMO dano de munição documentado
///   (1d6/1d6 pra Flight arrow, 1d8/1d8 pra Sheaf arrow — não é dado
///   inventado, é a munição real reaplicada a outro arco que a usa).
enum EmbeddedWeapons {
    static let entries: [Weapon] = [
        embeddedWeapon000,
        embeddedWeapon001,
        embeddedWeapon002,
        embeddedWeapon003,
        embeddedWeapon004,
        embeddedWeapon005,
        embeddedWeapon006,
        embeddedWeapon007,
        embeddedWeapon008,
        embeddedWeapon009,
        embeddedWeapon010,
        embeddedWeapon011,
        embeddedWeapon012,
        embeddedWeapon013,
        embeddedWeapon014,
        embeddedWeapon015,
        embeddedWeapon016,
        embeddedWeapon017,
        embeddedWeapon018,
        embeddedWeapon019,
        embeddedWeapon020,
        embeddedWeapon021,
        embeddedWeapon022,
        embeddedWeapon023,
        embeddedWeapon024,
        embeddedWeapon025,
        embeddedWeapon026,
        embeddedWeapon027,
        embeddedWeapon028,
        embeddedWeapon029,
        embeddedWeapon030,
        embeddedWeapon031,
        embeddedWeapon032,
        embeddedWeapon033,
        embeddedWeapon034,
        embeddedWeapon035,
        embeddedWeapon036,
        embeddedWeapon037,
        embeddedWeapon038,
        embeddedWeapon039,
        embeddedWeapon040,
        embeddedWeapon041,
        embeddedWeapon042,
        embeddedWeapon043,
        embeddedWeapon044,
        embeddedWeapon045,
        embeddedWeapon046,
        embeddedWeapon047,
        embeddedWeapon048,
        embeddedWeapon049,
        embeddedWeapon050,
        embeddedWeapon051,
        embeddedWeapon052,
        embeddedWeapon053,
        embeddedWeapon054,
        embeddedWeapon055,
        embeddedWeapon056,
        embeddedWeapon057,
        embeddedWeapon058,
        embeddedWeapon059,
        embeddedWeapon060,
        embeddedWeapon061,
        embeddedWeapon062,
        embeddedWeapon063,
        embeddedWeapon064,
        embeddedWeapon065,
        embeddedWeapon066,
        embeddedWeapon067,
        embeddedWeapon068,
        embeddedWeaponCPrH00,
        embeddedWeaponCPrH01,
        embeddedWeaponCPrH02,
        embeddedWeaponCPrH03,
        embeddedWeaponCPrH04,
        embeddedWeaponCPrH05,
    ]
}

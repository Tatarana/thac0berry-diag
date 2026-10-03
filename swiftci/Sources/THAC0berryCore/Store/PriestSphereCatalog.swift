import Foundation

/// A lista canônica de esferas de magia de clérigo que o app reconhece —
/// pesquisada e conferida contra o Player's Handbook (16 esferas
/// originais), o Tome of Magic (8 esferas menores) e Player's Option:
/// Spells & Magic (Cosmos, esfera de monge) antes de normalizar os
/// rótulos crus do corpus de magias (ver TODO.md item 16). Três esferas
/// paraelementais de Dark Sun (Silt, Magma, Sun) também entraram — não
/// são ruído: toda magia rotulada com elas tem `setting: "Dark Sun"`.
///
/// Cada `PriestSphere` é só o nome — a exibição em grupos (pra caber a
/// picareta de ~32 esferas numa tela sem virar uma lista sem fim) vive em
/// `PriestSphereCatalog.groups`.
struct PriestSphereGroup: Identifiable {
    var id: String { title }
    let title: String
    let spheres: [String]
}

enum PriestSphereCatalog {
    /// As 16 esferas maiores do PHB (capítulo 3) — todo Clérigo começa com
    /// acesso maior à maioria delas; kits/divindades restringem ou trocam.
    static let phbMajor = [
        "All", "Animal", "Astral", "Charm", "Combat", "Creation", "Divination",
        "Elemental", "Guardian", "Healing", "Necromantic", "Plant", "Protection",
        "Summoning", "Sun", "Weather",
    ]

    /// As 4 subesferas elementais — contam separado da esfera-mãe
    /// "Elemental" porque uma magia costuma pedir só uma delas, não a
    /// família toda.
    static let elemental = [
        "Elemental Air", "Elemental Earth", "Elemental Fire", "Elemental Water",
    ]

    /// As esferas menores acrescentadas pelo Tome of Magic + a esfera de
    /// monge "Cosmos" (Player's Option: Spells & Magic) — normalmente só
    /// concedidas por kit/classe especializada, não pelo Clérigo padrão.
    static let minor = [
        "Chaos", "Law", "Numbers", "Thought", "Time", "Travelers", "War", "Wards", "Cosmos",
    ]

    /// Paraelementos de Dark Sun (fusão de dois elementos cada) — só fazem
    /// sentido pra campanha nesse cenário; ficam separados pra não
    /// confundir jogador de outro cenário com esfera que ele nunca vai
    /// usar. "Rain" (Água+Ar) não aparece porque nenhuma magia da base
    /// atual usa esse rótulo — adicionar aqui se um dia aparecer.
    static let darkSunParaelemental = [
        "Silt", "Elemental Magma", "Elemental Sun",
    ]

    /// Todas juntas, na ordem que `groups` usa — é o que valida se uma
    /// esfera de magia (`Spell.spheres`) é "reconhecida" ou uma das ~6
    /// ainda incertas deixadas de fora da normalização (Unknown,
    /// Alteration, Elemental Lightning, Learning, Plane).
    static let all = phbMajor + elemental + minor + darkSunParaelemental

    static let groups: [PriestSphereGroup] = [
        PriestSphereGroup(title: "Major Spheres (PHB)", spheres: phbMajor),
        PriestSphereGroup(title: "Elemental", spheres: elemental),
        PriestSphereGroup(title: "Minor Spheres (Tome of Magic)", spheres: minor),
        PriestSphereGroup(title: "Dark Sun — Paraelemental", spheres: darkSunParaelemental),
    ]
}

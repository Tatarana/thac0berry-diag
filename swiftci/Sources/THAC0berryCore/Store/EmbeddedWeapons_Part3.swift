import Foundation

/// Parte 3 de 4 das armas embutidas — mesmo padrão de
/// `EmbeddedKits_PartN.swift`/`EmbeddedProficiencies_PartN.swift`: cada
/// arma é uma constante com tipo explícito (`: Weapon`), pro compilador
/// checar cada uma isolada e rápido em vez de inferir um array gigante de
/// uma vez. Ver `EmbeddedWeapons.swift` pro porquê disso existir (nunca
/// leia isso de JSON/bundle em runtime).
///
/// Gerado a partir de `weapons.json` (PHB cap. 6, "Weapons" — 306 itens
/// não-mágicos extraídos, ver TODO.md itens 22/24) — regenere com o
/// script de origem se os dados mudarem, não edite à mão.

let embeddedWeapon036: Weapon = Weapon(
    id: "javelin",
    name: "Javelin",
    size: "M",
    type: "P",
    speedFactor: 4,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d6",
    range: WeaponRange(
        short: "20",
        medium: "40",
        long: "60"
    )
)

let embeddedWeapon037: Weapon = Weapon(
    id: "jousting_lance",
    name: "Jousting lance",
    size: "L",
    type: "P",
    speedFactor: 10,
    attacksPerRound: "1",
    damageSmall: "1d3-1",
    damageLarge: "1d2-1",
    range: nil
)

let embeddedWeapon038: Weapon = Weapon(
    id: "khopesh",
    name: "Khopesh",
    size: "M",
    type: "S",
    speedFactor: 9,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "1d6",
    range: nil
)

let embeddedWeapon039: Weapon = Weapon(
    id: "knife",
    name: "Knife",
    size: "S",
    type: "P/S",
    speedFactor: 2,
    attacksPerRound: "2/1",
    damageSmall: "1d3",
    damageLarge: "1d2",
    range: WeaponRange(
        short: "10",
        medium: "20",
        long: "30"
    )
)

let embeddedWeapon040: Weapon = Weapon(
    id: "light_crossbow_light_quarrel",
    name: "Light crossbow (Light quarrel)",
    size: "M",
    type: "P",
    speedFactor: 7,
    attacksPerRound: "1",
    damageSmall: "1d4",
    damageLarge: "1d4",
    range: WeaponRange(
        short: "60",
        medium: "120",
        long: "180"
    )
)

let embeddedWeapon041: Weapon = Weapon(
    id: "light_horse_lance",
    name: "Light horse lance",
    size: "L",
    type: "P",
    speedFactor: 6,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d8",
    range: nil
)

let embeddedWeapon042: Weapon = Weapon(
    id: "long_bow_flight_arrow",
    name: "Long bow (Flight arrow)",
    size: "L",
    type: "P",
    speedFactor: 8,
    attacksPerRound: "2/1",
    damageSmall: "1d6",
    damageLarge: "1d6",
    range: WeaponRange(
        short: "70",
        medium: "140",
        long: "210"
    )
)

let embeddedWeapon043: Weapon = Weapon(
    id: "long_bow_sheaf_arrow",
    name: "Long bow (Sheaf arrow)",
    size: "L",
    type: "P",
    speedFactor: 8,
    attacksPerRound: "2/1",
    damageSmall: "1d8",
    damageLarge: "1d8",
    range: WeaponRange(
        short: "50",
        medium: "100",
        long: "170"
    )
)

let embeddedWeapon044: Weapon = Weapon(
    id: "long_sword",
    name: "Long sword",
    size: "M",
    type: "S",
    speedFactor: 5,
    attacksPerRound: "1",
    damageSmall: "1d8",
    damageLarge: "1d12",
    range: nil
)

let embeddedWeapon045: Weapon = Weapon(
    id: "lucern_hammer",
    name: "Lucern hammer",
    size: "L",
    type: "P/B",
    speedFactor: 9,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "1d6",
    range: nil
)

let embeddedWeapon046: Weapon = Weapon(
    id: "medium_horse_lance",
    name: "Medium horse lance",
    size: "L",
    type: "P",
    speedFactor: 7,
    attacksPerRound: "1",
    damageSmall: "1d6+1",
    damageLarge: "2d6",
    range: nil
)

let embeddedWeapon047: Weapon = Weapon(
    id: "military_fork",
    name: "Military fork",
    size: "L",
    type: "P",
    speedFactor: 7,
    attacksPerRound: "1",
    damageSmall: "1d8",
    damageLarge: "2d4",
    range: nil
)

let embeddedWeapon048: Weapon = Weapon(
    id: "morning_star",
    name: "Morning star",
    size: "M",
    type: "B",
    speedFactor: 7,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "1d6+1",
    range: nil
)

let embeddedWeapon049: Weapon = Weapon(
    id: "partisan",
    name: "Partisan",
    size: "L",
    type: "P",
    speedFactor: 9,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d6+1",
    range: nil
)

let embeddedWeapon050: Weapon = Weapon(
    id: "quarterstaff",
    name: "Quarterstaff",
    size: "L",
    type: "B",
    speedFactor: 4,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d6",
    range: nil
)

let embeddedWeapon051: Weapon = Weapon(
    id: "ranseur",
    name: "Ranseur",
    size: "L",
    type: "P",
    speedFactor: 8,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "2d4",
    range: nil
)

let embeddedWeapon052: Weapon = Weapon(
    id: "scimitar",
    name: "Scimitar",
    size: "M",
    type: "S",
    speedFactor: 5,
    attacksPerRound: "1",
    damageSmall: "1d8",
    damageLarge: "1d8",
    range: nil
)

let embeddedWeapon053: Weapon = Weapon(
    id: "scourge",
    name: "Scourge",
    size: "S",
    type: nil,
    speedFactor: 5,
    attacksPerRound: "1",
    damageSmall: "1d4",
    damageLarge: "1d2",
    range: nil
)

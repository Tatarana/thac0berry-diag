import Foundation

/// Parte 4 de 4 das armas embutidas — mesmo padrão de
/// `EmbeddedKits_PartN.swift`/`EmbeddedProficiencies_PartN.swift`: cada
/// arma é uma constante com tipo explícito (`: Weapon`), pro compilador
/// checar cada uma isolada e rápido em vez de inferir um array gigante de
/// uma vez. Ver `EmbeddedWeapons.swift` pro porquê disso existir (nunca
/// leia isso de JSON/bundle em runtime).
///
/// Gerado a partir de `weapons.json` (PHB cap. 6, "Weapons" — 306 itens
/// não-mágicos extraídos, ver TODO.md itens 22/24) — regenere com o
/// script de origem se os dados mudarem, não edite à mão.

let embeddedWeapon054: Weapon = Weapon(
    id: "short_bow_flight_arrow",
    name: "Short bow (Flight arrow)",
    size: "M",
    type: "P",
    speedFactor: 7,
    attacksPerRound: "2/1",
    damageSmall: "1d6",
    damageLarge: "1d6",
    range: WeaponRange(
        short: "50",
        medium: "100",
        long: "150"
    )
)

let embeddedWeapon055: Weapon = Weapon(
    id: "short_bow_sheaf_arrow",
    name: "Short bow (Sheaf arrow)",
    size: "M",
    type: "P",
    speedFactor: 7,
    attacksPerRound: "2/1",
    damageSmall: "1d8",
    damageLarge: "1d8",
    range: WeaponRange(
        short: "50",
        medium: "100",
        long: "150"
    )
)

let embeddedWeapon056: Weapon = Weapon(
    id: "short_sword",
    name: "Short sword",
    size: "S",
    type: "P",
    speedFactor: 3,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d8",
    range: nil
)

let embeddedWeapon057: Weapon = Weapon(
    id: "sickle",
    name: "Sickle",
    size: "S",
    type: "S",
    speedFactor: 4,
    attacksPerRound: "1",
    damageSmall: "1d4+1",
    damageLarge: "1d4",
    range: nil
)

let embeddedWeapon058: Weapon = Weapon(
    id: "sling_bullet",
    name: "Sling (bullet)",
    size: "S",
    type: "B",
    speedFactor: 6,
    attacksPerRound: "1",
    damageSmall: "1d4+1",
    damageLarge: "1d6+1",
    range: WeaponRange(
        short: "50",
        medium: "100",
        long: "200"
    )
)

let embeddedWeapon059: Weapon = Weapon(
    id: "sling_stone",
    name: "Sling (stone)",
    size: "S",
    type: "B",
    speedFactor: 6,
    attacksPerRound: "1",
    damageSmall: "1d4",
    damageLarge: "1d4",
    range: WeaponRange(
        short: "40",
        medium: "80",
        long: "160"
    )
)

let embeddedWeapon060: Weapon = Weapon(
    id: "spear",
    name: "Spear",
    size: "M",
    type: "P",
    speedFactor: 6,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d8",
    range: WeaponRange(
        short: "10",
        medium: "20",
        long: "30"
    )
)

let embeddedWeapon061: Weapon = Weapon(
    id: "spetum",
    name: "Spetum",
    size: "L",
    type: "P",
    speedFactor: 8,
    attacksPerRound: "1",
    damageSmall: "1d6+1",
    damageLarge: "2d6",
    range: nil
)

let embeddedWeapon062: Weapon = Weapon(
    id: "staff_sling_bullet",
    name: "Staff sling (bullet)",
    size: "M",
    type: "B",
    speedFactor: 11,
    attacksPerRound: "2/1",
    damageSmall: "1d4+1",
    damageLarge: "1d6+1",
    range: WeaponRange(
        short: "—",
        medium: "30-60",
        long: "90"
    )
)

let embeddedWeapon063: Weapon = Weapon(
    id: "staff_sling_stone",
    name: "Staff sling (stone)",
    size: "M",
    type: "B",
    speedFactor: 11,
    attacksPerRound: "2/1",
    damageSmall: "1d4",
    damageLarge: "1d4",
    range: WeaponRange(
        short: "—",
        medium: "30-60",
        long: "90"
    )
)

let embeddedWeapon064: Weapon = Weapon(
    id: "trident",
    name: "Trident",
    size: "L",
    type: "P",
    speedFactor: 7,
    attacksPerRound: "1",
    damageSmall: "1d6+1",
    damageLarge: "3d4",
    range: nil
)

let embeddedWeapon065: Weapon = Weapon(
    id: "two_handed_sword",
    name: "Two-handed sword",
    size: "L",
    type: "S",
    speedFactor: 10,
    attacksPerRound: "1",
    damageSmall: "1d10",
    damageLarge: "3d6",
    range: nil
)

let embeddedWeapon066: Weapon = Weapon(
    id: "voulge",
    name: "Voulge",
    size: "L",
    type: "S",
    speedFactor: 10,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "2d4",
    range: nil
)

let embeddedWeapon067: Weapon = Weapon(
    id: "warhammer",
    name: "Warhammer",
    size: "M",
    type: "B",
    speedFactor: 4,
    attacksPerRound: "1",
    damageSmall: "1d4+1",
    damageLarge: "1d4",
    range: WeaponRange(
        short: "10",
        medium: "20",
        long: "30"
    )
)

let embeddedWeapon068: Weapon = Weapon(
    id: "whip",
    name: "Whip",
    size: "M",
    type: nil,
    speedFactor: 8,
    attacksPerRound: "1",
    damageSmall: "1d2",
    damageLarge: "1",
    range: nil
)

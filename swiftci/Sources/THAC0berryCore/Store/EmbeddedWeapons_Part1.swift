import Foundation

/// Parte 1 de 4 das armas embutidas — mesmo padrão de
/// `EmbeddedKits_PartN.swift`/`EmbeddedProficiencies_PartN.swift`: cada
/// arma é uma constante com tipo explícito (`: Weapon`), pro compilador
/// checar cada uma isolada e rápido em vez de inferir um array gigante de
/// uma vez. Ver `EmbeddedWeapons.swift` pro porquê disso existir (nunca
/// leia isso de JSON/bundle em runtime).
///
/// Gerado a partir de `weapons.json` (PHB cap. 6, "Weapons" — 306 itens
/// não-mágicos extraídos, ver TODO.md itens 22/24) — regenere com o
/// script de origem se os dados mudarem, não edite à mão.

let embeddedWeapon000: Weapon = Weapon(
    id: "arquebus",
    name: "Arquebus",
    size: "M",
    type: "P",
    speedFactor: 15,
    attacksPerRound: "1/3",
    damageSmall: "1d10",
    damageLarge: "1d10",
    range: WeaponRange(
        short: "50",
        medium: "150",
        long: "210"
    )
)

let embeddedWeapon001: Weapon = Weapon(
    id: "awl_pike",
    name: "Awl pike",
    size: "L",
    type: "P",
    speedFactor: 13,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d12",
    range: nil
)

let embeddedWeapon002: Weapon = Weapon(
    id: "bardiche",
    name: "Bardiche",
    size: "L",
    type: "S",
    speedFactor: 9,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "2d6",
    range: nil
)

let embeddedWeapon003: Weapon = Weapon(
    id: "bastard_sword_one_handed_grip",
    name: "Bastard sword (One-handed grip)",
    size: "M",
    type: "S",
    speedFactor: 6,
    attacksPerRound: "1",
    damageSmall: "1d8",
    damageLarge: "1d12",
    range: nil
)

let embeddedWeapon004: Weapon = Weapon(
    id: "bastard_sword_two_handed_grip",
    name: "Bastard sword (Two-handed grip)",
    size: "M",
    type: "S",
    speedFactor: 8,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "2d8",
    range: nil
)

let embeddedWeapon005: Weapon = Weapon(
    id: "battle_axe",
    name: "Battle axe",
    size: "M",
    type: "S",
    speedFactor: 7,
    attacksPerRound: "1",
    damageSmall: "1d8",
    damageLarge: "1d8",
    range: nil
)

let embeddedWeapon006: Weapon = Weapon(
    id: "bec_de_corbin",
    name: "Bec de corbin",
    size: "L",
    type: "P/B",
    speedFactor: 9,
    attacksPerRound: "1",
    damageSmall: "1d8",
    damageLarge: "1d6",
    range: nil
)

let embeddedWeapon007: Weapon = Weapon(
    id: "bill_guisarme",
    name: "Bill-guisarme",
    size: "L",
    type: "P/S",
    speedFactor: 10,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "1d10",
    range: nil
)

let embeddedWeapon008: Weapon = Weapon(
    id: "blowgun",
    name: "Blowgun",
    size: "L",
    type: nil,
    speedFactor: 5,
    attacksPerRound: "2/1",
    damageSmall: nil,
    damageLarge: nil,
    range: WeaponRange(
        short: "10",
        medium: "20",
        long: "30"
    )
)

let embeddedWeapon009: Weapon = Weapon(
    id: "broad_sword",
    name: "Broad sword",
    size: "M",
    type: "S",
    speedFactor: 5,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "1d6+1",
    range: nil
)

let embeddedWeapon010: Weapon = Weapon(
    id: "club",
    name: "Club",
    size: "M",
    type: "B",
    speedFactor: 4,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d3",
    range: WeaponRange(
        short: "10",
        medium: "20",
        long: "30"
    )
)

let embeddedWeapon011: Weapon = Weapon(
    id: "composite_long_bow_flight_arrow",
    name: "Composite long bow (Flight arrow)",
    size: "L",
    type: "P",
    speedFactor: 7,
    attacksPerRound: "2/1",
    damageSmall: "1d6",
    damageLarge: "1d6",
    range: WeaponRange(
        short: "60",
        medium: "120",
        long: "210"
    )
)

let embeddedWeapon012: Weapon = Weapon(
    id: "composite_long_bow_sheaf_arrow",
    name: "Composite long bow (Sheaf arrow)",
    size: "L",
    type: "P",
    speedFactor: 7,
    attacksPerRound: "2/1",
    damageSmall: "1d8",
    damageLarge: "1d8",
    range: WeaponRange(
        short: "40",
        medium: "80",
        long: "170"
    )
)

let embeddedWeapon013: Weapon = Weapon(
    id: "composite_short_bow_flight_arrow",
    name: "Composite short bow (Flight arrow)",
    size: "M",
    type: "P",
    speedFactor: 6,
    attacksPerRound: "2/1",
    damageSmall: "1d6",
    damageLarge: "1d6",
    range: WeaponRange(
        short: "50",
        medium: "100",
        long: "180"
    )
)

let embeddedWeapon014: Weapon = Weapon(
    id: "composite_short_bow_sheaf_arrow",
    name: "Composite short bow (Sheaf arrow)",
    size: "M",
    type: "P",
    speedFactor: 6,
    attacksPerRound: "2/1",
    damageSmall: "1d8",
    damageLarge: "1d8",
    range: WeaponRange(
        short: "50",
        medium: "100",
        long: "180"
    )
)

let embeddedWeapon015: Weapon = Weapon(
    id: "dagger_or_dirk",
    name: "Dagger or dirk",
    size: "S",
    type: "P",
    speedFactor: 2,
    attacksPerRound: "2/1",
    damageSmall: "1d4",
    damageLarge: "1d3",
    range: WeaponRange(
        short: "10",
        medium: "20",
        long: "30"
    )
)

let embeddedWeapon016: Weapon = Weapon(
    id: "dart",
    name: "Dart",
    size: "S",
    type: "P",
    speedFactor: 2,
    attacksPerRound: "3/1",
    damageSmall: "1d3",
    damageLarge: "1d2",
    range: WeaponRange(
        short: "10",
        medium: "20",
        long: "40"
    )
)

let embeddedWeapon017: Weapon = Weapon(
    id: "fauchard",
    name: "Fauchard",
    size: "L",
    type: "P/S",
    speedFactor: 8,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d8",
    range: nil
)

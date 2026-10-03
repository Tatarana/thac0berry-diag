import Foundation

/// Parte 2 de 4 das armas embutidas — mesmo padrão de
/// `EmbeddedKits_PartN.swift`/`EmbeddedProficiencies_PartN.swift`: cada
/// arma é uma constante com tipo explícito (`: Weapon`), pro compilador
/// checar cada uma isolada e rápido em vez de inferir um array gigante de
/// uma vez. Ver `EmbeddedWeapons.swift` pro porquê disso existir (nunca
/// leia isso de JSON/bundle em runtime).
///
/// Gerado a partir de `weapons.json` (PHB cap. 6, "Weapons" — 306 itens
/// não-mágicos extraídos, ver TODO.md itens 22/24) — regenere com o
/// script de origem se os dados mudarem, não edite à mão.

let embeddedWeapon018: Weapon = Weapon(
    id: "fauchard_fork",
    name: "Fauchard-fork",
    size: "L",
    type: "P/S",
    speedFactor: 8,
    attacksPerRound: "1",
    damageSmall: "1d8",
    damageLarge: "1d10",
    range: nil
)

let embeddedWeapon019: Weapon = Weapon(
    id: "footman_s_flail",
    name: "Footman's flail",
    size: "M",
    type: "B",
    speedFactor: 7,
    attacksPerRound: "1",
    damageSmall: "1d6+1",
    damageLarge: "2d4",
    range: nil
)

let embeddedWeapon020: Weapon = Weapon(
    id: "footman_s_mace",
    name: "Footman's mace",
    size: "M",
    type: "B",
    speedFactor: 7,
    attacksPerRound: "1",
    damageSmall: "1d6+1",
    damageLarge: "1d6",
    range: nil
)

let embeddedWeapon021: Weapon = Weapon(
    id: "footman_s_pick",
    name: "Footman's pick",
    size: "M",
    type: "P",
    speedFactor: 7,
    attacksPerRound: "1",
    damageSmall: "1d6+1",
    damageLarge: "2d4",
    range: nil
)

let embeddedWeapon022: Weapon = Weapon(
    id: "glaive",
    name: "Glaive",
    size: "L",
    type: "S",
    speedFactor: 8,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d10",
    range: nil
)

let embeddedWeapon023: Weapon = Weapon(
    id: "glaive_guisarme",
    name: "Glaive-guisarme",
    size: "L",
    type: "P/S",
    speedFactor: 9,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "2d6",
    range: nil
)

let embeddedWeapon024: Weapon = Weapon(
    id: "guisarme",
    name: "Guisarme",
    size: "L",
    type: "S",
    speedFactor: 8,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "1d8",
    range: nil
)

let embeddedWeapon025: Weapon = Weapon(
    id: "guisarme_voulge",
    name: "Guisarme-voulge",
    size: "L",
    type: "P/S",
    speedFactor: 10,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "2d4",
    range: nil
)

let embeddedWeapon026: Weapon = Weapon(
    id: "halberd",
    name: "Halberd",
    size: "L",
    type: "P/S",
    speedFactor: 9,
    attacksPerRound: "1",
    damageSmall: "1d10",
    damageLarge: "2d6",
    range: nil
)

let embeddedWeapon027: Weapon = Weapon(
    id: "hand_crossbow_hand_quarrel",
    name: "Hand crossbow (Hand quarrel)",
    size: "S",
    type: "P",
    speedFactor: 5,
    attacksPerRound: "1",
    damageSmall: "1d3",
    damageLarge: "1d2",
    range: WeaponRange(
        short: "20",
        medium: "40",
        long: "60"
    )
)

let embeddedWeapon028: Weapon = Weapon(
    id: "hand_or_throwing_axe",
    name: "Hand or throwing axe",
    size: "M",
    type: "S",
    speedFactor: 4,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d4",
    range: WeaponRange(
        short: "10",
        medium: "20",
        long: "30"
    )
)

let embeddedWeapon029: Weapon = Weapon(
    id: "harpoon",
    name: "Harpoon",
    size: "L",
    type: "P",
    speedFactor: 7,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "2d6",
    range: WeaponRange(
        short: "10",
        medium: "20",
        long: "30"
    )
)

let embeddedWeapon030: Weapon = Weapon(
    id: "heavy_crossbow_heavy_quarrel",
    name: "Heavy crossbow (Heavy quarrel)",
    size: "M",
    type: "P",
    speedFactor: 10,
    attacksPerRound: "1/2",
    damageSmall: "1d4+1",
    damageLarge: "1d6+1",
    range: WeaponRange(
        short: "80",
        medium: "160",
        long: "240"
    )
)

let embeddedWeapon031: Weapon = Weapon(
    id: "heavy_horse_lance",
    name: "Heavy horse lance",
    size: "L",
    type: "P",
    speedFactor: 8,
    attacksPerRound: "1",
    damageSmall: "1d8+1",
    damageLarge: "3d6",
    range: nil
)

let embeddedWeapon032: Weapon = Weapon(
    id: "hook_fauchard",
    name: "Hook fauchard",
    size: "L",
    type: "P/S",
    speedFactor: 9,
    attacksPerRound: "1",
    damageSmall: "1d4",
    damageLarge: "1d4",
    range: nil
)

let embeddedWeapon033: Weapon = Weapon(
    id: "horseman_s_flail",
    name: "Horseman's flail",
    size: "M",
    type: "B",
    speedFactor: 6,
    attacksPerRound: "1",
    damageSmall: "1d4+1",
    damageLarge: "1d4+1",
    range: nil
)

let embeddedWeapon034: Weapon = Weapon(
    id: "horseman_s_mace",
    name: "Horseman's mace",
    size: "M",
    type: "B",
    speedFactor: 6,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d4",
    range: nil
)

let embeddedWeapon035: Weapon = Weapon(
    id: "horseman_s_pick",
    name: "Horseman's pick",
    size: "M",
    type: "P",
    speedFactor: 5,
    attacksPerRound: "1",
    damageSmall: "1d4+1",
    damageLarge: "1d4",
    range: nil
)

import Foundation

/// Parte 5 — as 6 armas novas do cap. 6 ("New Weapons List") do Complete
/// Priest's Handbook: Bill, Lasso, Maul, Net, Nunchaku, Scythe. Mesmo
/// padrão de Part1-4 (PHB), mas com `source: "CPrH"` (as 69 da PHB ficam
/// com o `source` padrão `nil`, ver `Weapon.source`).
///
/// O livro não lista "attacks per round" pra nenhuma delas (a tabela do
/// cap. 6 do CPrH não tem essa coluna, diferente da Table 45 do PHB) —
/// usamos "1" como padrão de ataque por rodada pra todas, igual a maioria
/// das armas de uma mão do PHB; é uma inferência razoável, não um dado
/// confirmado no livro. `range: nil` também — a tabela não traz alcance
/// pra nenhuma delas (Lasso/Net têm dano "—" porque são armas de captura,
/// não causam dano direto).

let embeddedWeaponCPrH00: Weapon = Weapon(
    id: "bill",
    name: "Bill",
    size: "S",
    type: "P",
    speedFactor: 2,
    attacksPerRound: "1",
    damageSmall: "1d4",
    damageLarge: "1d8",
    range: nil,
    source: "CPrH"
)

let embeddedWeaponCPrH01: Weapon = Weapon(
    id: "lasso",
    name: "Lasso",
    size: "L",
    type: nil,
    speedFactor: 10,
    attacksPerRound: "1",
    damageSmall: nil,
    damageLarge: nil,
    range: nil,
    source: "CPrH"
)

let embeddedWeaponCPrH02: Weapon = Weapon(
    id: "maul",
    name: "Maul",
    size: "L",
    type: "B",
    speedFactor: 9,
    attacksPerRound: "1",
    damageSmall: "2d4",
    damageLarge: "1d10",
    range: nil,
    source: "CPrH"
)

let embeddedWeaponCPrH03: Weapon = Weapon(
    id: "net",
    name: "Net",
    size: "M",
    type: nil,
    speedFactor: 10,
    attacksPerRound: "1",
    damageSmall: nil,
    damageLarge: nil,
    range: nil,
    source: "CPrH"
)

let embeddedWeaponCPrH04: Weapon = Weapon(
    id: "nunchaku",
    name: "Nunchaku",
    size: "M",
    type: "B",
    speedFactor: 3,
    attacksPerRound: "1",
    damageSmall: "1d6",
    damageLarge: "1d6",
    range: nil,
    source: "CPrH"
)

let embeddedWeaponCPrH05: Weapon = Weapon(
    id: "scythe",
    name: "Scythe",
    size: "M",
    type: "P/S",
    speedFactor: 8,
    attacksPerRound: "1",
    damageSmall: "1d6+1",
    damageLarge: "1d8",
    range: nil,
    source: "CPrH"
)

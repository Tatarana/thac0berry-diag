import Foundation

/// Literais das armaduras/elmos/escudos embutidos — mesmo padrão de
/// `EmbeddedWeapons_PartN.swift`: cada item é uma constante com tipo
/// explícito, pro compilador checar rápido em vez de inferir um array
/// gigante de uma vez. Ver `EmbeddedArmor.swift` pro porquê disso existir.
/// Gerado a partir de `armor_and_shields.json` — regenere com o script de
/// origem se os dados mudarem, não edite à mão.

let embeddedArmor000: ArmorPiece = ArmorPiece(
    id: "banded_mail",
    name: "Banded mail",
    kind: .armor,
    baseAC: 4,
    cost: "200 gp",
    weight: "35 lbs."
)

let embeddedArmor001: ArmorPiece = ArmorPiece(
    id: "brigandine",
    name: "Brigandine",
    kind: .armor,
    baseAC: 6,
    cost: "120 gp",
    weight: "35 lbs."
)

let embeddedArmor002: ArmorPiece = ArmorPiece(
    id: "bronze_plate_mail",
    name: "Bronze plate mail",
    kind: .armor,
    baseAC: 4,
    cost: "400 gp",
    weight: "45 lbs."
)

let embeddedArmor003: ArmorPiece = ArmorPiece(
    id: "chain_mail",
    name: "Chain mail",
    kind: .armor,
    baseAC: 5,
    cost: "75 gp",
    weight: "40 lbs."
)

let embeddedArmor004: ArmorPiece = ArmorPiece(
    id: "field_plate",
    name: "Field plate",
    kind: .armor,
    baseAC: 2,
    cost: "2000 gp",
    weight: "60 lbs."
)

let embeddedArmor005: ArmorPiece = ArmorPiece(
    id: "full_plate",
    name: "Full plate",
    kind: .armor,
    baseAC: 1,
    cost: "4,000-10,000 gp",
    weight: "70 lbs."
)

let embeddedArmor006: ArmorPiece = ArmorPiece(
    id: "great_helm",
    name: "Great helm",
    kind: .helmet,
    baseAC: nil,
    cost: "30 gp",
    weight: "10 lbs."
)

let embeddedArmor007: ArmorPiece = ArmorPiece(
    id: "basinet",
    name: "Basinet",
    kind: .helmet,
    baseAC: nil,
    cost: "8 gp",
    weight: "5 lbs."
)

let embeddedArmor008: ArmorPiece = ArmorPiece(
    id: "hide",
    name: "Hide",
    kind: .armor,
    baseAC: 6,
    cost: "15 gp",
    weight: "30 lbs."
)

let embeddedArmor009: ArmorPiece = ArmorPiece(
    id: "leather",
    name: "Leather",
    kind: .armor,
    baseAC: 8,
    cost: "5 gp",
    weight: "15 lbs."
)

let embeddedArmor010: ArmorPiece = ArmorPiece(
    id: "padded",
    name: "Padded",
    kind: .armor,
    baseAC: 8,
    cost: "4 gp",
    weight: "10 lbs."
)

let embeddedArmor011: ArmorPiece = ArmorPiece(
    id: "plate_mail",
    name: "Plate mail",
    kind: .armor,
    baseAC: 3,
    cost: "600 gp",
    weight: "50 lbs."
)

let embeddedArmor012: ArmorPiece = ArmorPiece(
    id: "ring_mail",
    name: "Ring mail",
    kind: .armor,
    baseAC: 7,
    cost: "100 gp",
    weight: "30 lbs."
)

let embeddedArmor013: ArmorPiece = ArmorPiece(
    id: "scale_mail",
    name: "Scale mail",
    kind: .armor,
    baseAC: 6,
    cost: "120 gp",
    weight: "40 lbs."
)

let embeddedArmor014: ArmorPiece = ArmorPiece(
    id: "body_shield",
    name: "Body Shield",
    kind: .shield,
    baseAC: nil,
    cost: "10 gp",
    weight: "15 lbs."
)

let embeddedArmor015: ArmorPiece = ArmorPiece(
    id: "buckler_shield",
    name: "Buckler Shield",
    kind: .shield,
    baseAC: nil,
    cost: "1 gp",
    weight: "3 lbs."
)

let embeddedArmor016: ArmorPiece = ArmorPiece(
    id: "medium_shield",
    name: "Medium Shield",
    kind: .shield,
    baseAC: nil,
    cost: "7 gp",
    weight: "10 lbs."
)

let embeddedArmor017: ArmorPiece = ArmorPiece(
    id: "small_shield",
    name: "Small Shield",
    kind: .shield,
    baseAC: nil,
    cost: "3 gp",
    weight: "5 lbs."
)

let embeddedArmor018: ArmorPiece = ArmorPiece(
    id: "splint_mail",
    name: "Splint mail",
    kind: .armor,
    baseAC: 4,
    cost: "80 gp",
    weight: "40 lbs."
)

let embeddedArmor019: ArmorPiece = ArmorPiece(
    id: "studded_leather",
    name: "Studded leather",
    kind: .armor,
    baseAC: 7,
    cost: "20 gp",
    weight: "25 lbs."
)

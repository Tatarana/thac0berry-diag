import Foundation

/// Um item da tabela "Armor" do PHB cap. 6 — armaduras, elmos e escudos
/// mundanos. Igual `Weapon`, fica separado do texto livre que já existe na
/// ficha (`ArmorField`/`character.armorRating`/`character.shieldRating`) —
/// este struct é só o dado de regra fixo que o seletor usa pra sugerir um
/// valor. Ver `Views/ArmorCompendiumView.swift` pra como um vira o outro.
///
/// 20 itens — os 21 do corpus original menos a linha "Helmet" (cabeçalho
/// de seção do livro que o extrator incluiu por engano como se fosse um
/// item; ver TODO.md item 24, confirmado contra o print do PHB). Elmos de
/// verdade (Great helm, Basinet) e escudos não têm `baseAC` no corpus — a
/// tabela de preços do PHB não atribui um valor de AC isolado a eles (o
/// bônus de escudo é regra à parte em outro lugar do livro, não um dado
/// tabulado aqui) — por isso só o seletor de "Armor" da ficha sugere AC;
/// Elmo e Escudo ficam só como referência de consulta no Compendium por
/// enquanto, sem inventar um número que não está na fonte.
struct ArmorPiece: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: ArmorPieceKind
    let baseAC: Int?
    let cost: String?
    let weight: String?
}

enum ArmorPieceKind: String, Hashable {
    case armor
    case helmet
    case shield
}

import Foundation

/// Um item do catálogo geral de equipamento mundano (não-mágico) do PHB —
/// tudo que não é arma nem armadura/escudo (esses dois já têm seus
/// próprios structs/Compendium, `Weapon` e `ArmorPiece`). Junta 7 das 10
/// categorias do corpus avaliado no TODO.md item 22/24 — ver
/// `Store/EmbeddedMundaneItems.swift` pra lista exata e o porquê de deixar
/// `animals.json` de fora por enquanto.
///
/// Usado pelo Equipment Compendium (consulta) e pelo seletor da tabela de
/// Equipment da página 2 da ficha (`Page2EquipmentEntry` — preenche peso
/// sozinho; local de guarda continua sempre manual, é escolha do jogador).
struct MundaneItem: Identifiable, Hashable {
    let id: String
    let name: String

    /// Ex. "Clothing", "Food & Lodging", "Tack & Harness" — como o corpus
    /// já vem categorizado, reaproveitado tal e qual pro agrupamento do
    /// Compendium.
    let category: String

    let cost: String?
    let weight: String?
}

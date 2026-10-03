import Foundation

/// Uma arma mundana da tabela do PHB cap. 6 ("Weapons") — a base de
/// consulta do Weapon Compendium (TODO.md itens 22/24), não o `WeaponEntry`
/// que já existe na Weapon Combat table da ficha (`Models/Character.swift`).
/// Os dois ficam separados de propósito: `WeaponEntry` é a linha que o
/// JOGADOR preenche (nome livre, THAC0/ajuste de dano PRÓPRIOS do
/// personagem, tudo texto solto — inclusive homebrew); `Weapon` é o dado
/// de REGRA, fixo pro livro inteiro, que o seletor usa pra preencher
/// aquela linha rapidamente. Ver `WeaponPickerSheet` pra como um vira o
/// outro.
///
/// 69 armas — as 67 do corpus original menos "Short bow"/"Composite short
/// bow" (sem dano próprio no livro, a munição Flight/Sheaf arrow é vendida
/// à parte) mais as 4 variantes "(Flight arrow)"/"(Sheaf arrow)" de cada
/// uma, reaproveitando o MESMO dano de munição que "Long bow"/"Composite
/// long bow" já usavam no corpus original (não é dado inventado — é a
/// munição real reaplicada a outro arco que a usa, confirmado contra a
/// Table 45 do PHB). Ver `Store/EmbeddedWeapons.swift`.
struct Weapon: Identifiable, Hashable {
    let id: String
    let name: String

    /// "S"/"M"/"L" — tamanho da arma.
    let size: String?

    /// "P"/"S"/"B" (ou combinado, ex. "P/S") — tipo de dano. `nil` quando
    /// o próprio PHB não classifica (ex. Scourge, Whip — confirmado contra
    /// a fonte, não é lacuna de extração).
    let type: String?

    let speedFactor: Int

    /// Ex. "1", "2/1", "1/2" — ataques por rodada, como a tabela imprime
    /// (não um Int: "1/2" significa 1 ataque a cada 2 rodadas).
    let attacksPerRound: String

    /// Dano contra alvo Pequeno/Médio e Grande — texto livre (dado, ex.
    /// "1d8", ou às vezes um valor fixo sem rolagem, ex. "1" no Whip,
    /// fiel ao que o livro imprime).
    let damageSmall: String?
    let damageLarge: String?

    /// `nil` quando a arma não tem alcance (corpo a corpo pura).
    let range: WeaponRange?

    /// `nil` pras 69 armas originais do PHB (a base assumida do
    /// Compendium/seletor). Preenchido só pras armas vindas de outro
    /// livro — hoje só as 6 do Complete Priest's Handbook cap. 6 ("New
    /// Weapons List": Bill, Lasso, Maul, Net, Nunchaku, Scythe), com
    /// `"CPrH"`.
    let source: String?

    /// Init explícito em vez de confiar no memberwise sintetizado pelo
    /// compilador: testado no Playgrounds (v1.42), o sintetizado NÃO deu
    /// um parâmetro `source:` opcional pros 69 `Weapon(...)` do PHB que
    /// não passam esse argumento — deu "Extra argument 'source' in call"
    /// nos 6 novos que passam. Declarando o init à mão com
    /// `source: String? = nil` no fim, os dois grupos compilam: os 69
    /// antigos (sem passar `source`) e os 6 novos (passando `source:
    /// "CPrH"`).
    init(id: String, name: String, size: String?, type: String?, speedFactor: Int,
         attacksPerRound: String, damageSmall: String?, damageLarge: String?,
         range: WeaponRange?, source: String? = nil) {
        self.id = id
        self.name = name
        self.size = size
        self.type = type
        self.speedFactor = speedFactor
        self.attacksPerRound = attacksPerRound
        self.damageSmall = damageSmall
        self.damageLarge = damageLarge
        self.range = range
        self.source = source
    }
}

/// Alcance Curto/Médio/Longo — texto livre em vez de `Int` porque o
/// próprio PHB mistura número ("50"), faixa ("30-60") e travessão de "não
/// tem" ("—") na mesma coluna (ex. Staff sling) — confirmado contra a
/// Table 45 (Missile Weapon Ranges) do livro, não é inconsistência de
/// extração.
struct WeaponRange: Hashable {
    let short: String?
    let medium: String?
    let long: String?
}

extension Weapon {
    /// Formata o alcance como "curto/médio/longo" pro campo livre
    /// `WeaponEntry.range` — mesmo formato que a Weapon Combat table já
    /// mostra na coluna "Range/Special". `nil` quando a arma não tem
    /// alcance nenhum (`range == nil`), pra não sobrescrever o "—" padrão
    /// do campo com um "—/—/—" redundante.
    var formattedRange: String? {
        guard let range else { return nil }
        let short = range.short ?? "—"
        let medium = range.medium ?? "—"
        let long = range.long ?? "—"
        return "\(short)/\(medium)/\(long)"
    }
}

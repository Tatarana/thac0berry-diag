import Foundation

/// Sugestão de esferas por kit, extraída do texto livre de cada kit
/// (`specialBenefits`/`specialHindrances`) por um script de padrão —
/// SÓ pras frases claras o bastante pra não arriscar erro ("cannot cast
/// spells from the X, Y spheres", "gains access to the X sphere"). Cobre
/// 19 dos 91 kits de sacerdote — o resto não tem menção a esfera
/// no texto, ou a frase é ambígua demais pra extrair com segurança (ver
/// TODO.md item 16). NUNCA aplicado sozinho: é só o que o botão "Suggest
/// from kit" (`SphereAccessEditorSheet`) oferece pro jogador confirmar —
/// o jogador quem decide se aceita, ajusta ou ignora.
enum KitSphereSuggestions {
    struct Suggestion {
        /// Esferas que o texto do kit nega explicitamente — sugestão é
        /// REMOVER (ou nunca marcar) do conjunto do personagem.
        let denied: [String]
        /// Esferas que o texto do kit concede, com o nível encontrado.
        let granted: [String: SphereAccessLevel]
    }

    static let byKitID: [String: Suggestion] = [
        "azuth_magefriend": Suggestion(denied: ["Animal", "Plant", "Weather"], granted: [:]),
        "chauntea_cultivator": Suggestion(denied: ["Guardian", "Necromantic"], granted: [:]),
        "chauntea_lifewarden": Suggestion(denied: ["Combat"], granted: [:]),
        "cyric_purifier": Suggestion(denied: ["Healing"], granted: [:]),
        "cyric_sword": Suggestion(denied: ["Healing"], granted: [:]),
        "helm_quester": Suggestion(denied: ["Animal", "Plant"], granted: [:]),
        "iyachtu_xvim_gauntlet": Suggestion(denied: ["Healing", "Necromantic"], granted: [:]),
        "iyachtu_xvim_orb": Suggestion(denied: ["Creation"], granted: [:]),
        "kelemvor_necrobane": Suggestion(denied: ["Necromantic"], granted: [:]),
        "lost_druid": Suggestion(denied: [], granted: ["Necromantic": .minor]),
        "mielikki_treespeaker": Suggestion(denied: ["Guardian", "Necromantic"], granted: [:]),
        "milil_loresinger": Suggestion(denied: ["Combat"], granted: [:]),
        "mystra_monitor": Suggestion(denied: ["Combat", "Necromantic", "Plant", "Weather"], granted: [:]),
        "oghma_quill": Suggestion(denied: ["Combat", "Necromantic"], granted: [:]),
        "shar_darkcloak": Suggestion(denied: ["Combat"], granted: [:]),
        "shar_nightbringer": Suggestion(denied: ["Sun", "Weather"], granted: [:]),
        "talos_chaos_knight": Suggestion(denied: [], granted: ["Chaos": .major]),
        "tempus_battleforge": Suggestion(denied: ["Animal", "Healing", "Plant"], granted: [:]),
        "tempus_gloryblood": Suggestion(denied: ["Healing"], granted: [:]),
    ]
}

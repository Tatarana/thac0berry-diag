import Foundation

/// Um poder psiônico — a mesma categoria que `Spell` cobre pra magia, só
/// que vinda do *Complete Psionics Handbook* e seus suplementos de Dark
/// Sun. Um psiônico não "conjura" powers com componentes/duração como um
/// mago/clérigo — gasta Pontos de Força Psiônica (PSP) pra ativar um
/// `powerScore` (teste de atributo com modificador), por isso o esquema
/// aqui é bem diferente de `Spell` apesar do papel parecido.
///
/// 257 powers ao todo, vindos de `Resources/psionic_powers.json`
/// (`Scripts/convert_psionic_powers.py` junta as 6 disciplinas + os 32
/// "High-Level Enhancements" num arquivo só, mesmo espírito de
/// `spells.json` juntar os níveis de magia). Rodada "fundação primeiro"
/// dos Psiônicos (2026-10-01, ver TODO.md): isto é só o banco
/// consultável — nenhum campo aqui liga a um personagem ainda (sem
/// "known powers"/PSP na ficha), igual os 41 kits de Mago existiram no
/// Compêndio bem antes da ficha do Mago ganhar Specialization de verdade.
struct PsionicPower: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let wikiPageTitle: String
    let redirectAliases: [String]
    /// "Clairsentience" / "Psychokinesis" / "Psychometabolism" /
    /// "Psychoportation" / "Telepathy" / "Metapsionics" — as seis
    /// disciplinas canônicas do CPsiH. Os 32 "High-Level Enhancements"
    /// também vêm marcados com a disciplina a que pertencem (um
    /// enhancement é sempre de uma disciplina específica), não um sétimo
    /// valor à parte.
    let discipline: String
    /// "Devotion" (poder menor) / "Science" (poder maior) / "Psionic
    /// Enhancement" (só pra quem já é mestre da disciplina, cap. 7 do
    /// CPsiH) — nomenclatura do próprio livro.
    let powerTier: String
    let powerScore: PsionicPowerScore
    let pspCost: PsionicPowerCost
    /// `nil` em 22 dos 257 powers (os que não entram em combate tático —
    /// MAC só faz sentido pra quem pode ser alvo de ataque psiônico).
    let tacticalCombat: PsionicTacticalCombat?
    let parameters: PsionicPowerParameters
    let description: PsionicPowerDescription
    let sources: [PsionicPowerSource]
    let categories: [String]

    /// Nome normalizado — mesmo padrão de `Spell.normalizedName`/
    /// `Kit`, usado pelo casamento aproximado de busca/escrita à mão.
    var normalizedName: String { Fuzzy.normalize(title) }
}

struct PsionicPowerScore: Codable, Hashable {
    /// Como aparece no livro, pronto pra exibir ("Con -3", "Wis -2").
    let raw: String
    let baseAbility: String
    let modifier: Int
}

struct PsionicPowerCost: Codable, Hashable {
    /// Custo pra ATIVAR o power pela primeira vez — texto livre porque às
    /// vezes é "na"/"Varies" (powers sem custo inicial fixo) em vez de
    /// número.
    let initial: String
    /// Custo pra MANTER o power ativo por rodada adicional — "na" quando o
    /// power não pode ser mantido (efeito instantâneo), ou `nil` em 3 dos
    /// 257 powers (`initial: "Varies"` — o livro não dá nem o texto "na"
    /// pra manutenção desses, a chave vem `null` no dado de origem).
    let maintenance: String?
    /// "10/4" — o resumo "inicial/manutenção" como o livro mostra na
    /// tabela de referência rápida, pronto pra exibir sem concatenar
    /// `initial`/`maintenance` na UI.
    let summary: String
}

/// Dado de Combate Tático (CPsiH cap. 2, "Psionic Combat") — só o MAC
/// (Mental Armor Class) interessa aqui; ataque/defesa psiônica em si
/// (Attack/Defense Modes) é mecânica de PERSONAGEM (depende de quais
/// modos o psiônico escolheu), não do power — fica pra quando a classe
/// Psionicist virar jogável.
struct PsionicTacticalCombat: Codable, Hashable {
    let mac: String
}

struct PsionicPowerParameters: Codable, Hashable {
    let range: String
    let preparationTime: String
    let areaOfEffect: String
    /// IDs de outros powers que este exige conhecer primeiro (ex.:
    /// telepatia que precisa de "contact") — texto livre, não
    /// necessariamente batendo com `PsionicPower.id` de verdade (alguns
    /// vêm como nome livre do pré-requisito, não id normalizado).
    let prerequisites: [String]
}

struct PsionicPowerDescription: Codable, Hashable {
    let briefSummary: String
    let sections: PsionicPowerSections
    let fullText: String
    let rawWikitext: String
}

struct PsionicPowerSections: Codable, Hashable {
    let effect: String
    /// Preenchido só nos powers cujo "Power Score" tem efeito adicional
    /// quando o teste é um sucesso excepcional, ou consequência extra numa
    /// falha crítica (73 dos 257) — `nil` no resto (efeito já cobre tudo
    /// em `effect`).
    let powerScoreRollResults: PsionicPowerRollResults?
}

struct PsionicPowerRollResults: Codable, Hashable {
    let powerScoreSuccess: String
    let criticalFailure20: String
}

struct PsionicPowerSource: Codable, Hashable {
    let book: String
    let page: Int?
}

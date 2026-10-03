# Diagnóstico de build — THAC0berry

Isso não é o app. É só os arquivos de Models/Store (a lógica, sem telas)
empacotados como uma lib Swift comum, com uma Action do GitHub que roda
`swift build` sozinha quando você sobe isso num repo. O Linux tem
compilador Swift de verdade e não passa pelo Swift Playgrounds — se o
problema for aquele erro clássico de "expression too complex to
type-check", a mensagem REAL do compilador vai aparecer no log da Action,
coisa que o Playgrounds no iPad nunca mostrou.

## Passo a passo (2 minutos, direto do navegador, sem instalar nada)

1. Entra em github.com → **New repository** (pode ser público, nome
   qualquer, ex. `thac0berry-diag`) → Create repository.
2. Na tela do repo vazio, clica em **"uploading an existing file"**
   (link que aparece na própria página) e arrasta TODOS os arquivos e
   pastas de dentro deste zip (incluindo a pasta `.github` — ela pode
   vir escondida, confirma que ela subiu) → **Commit changes**.
3. Vai na aba **Actions** do repo. Uma run chamada "Diagnóstico de
   build (Swift)" já deve estar rodando sozinha (ela dispara em todo
   push). Espera uns 1-2 minutos e abre ela.
4. Se der erro, abre o passo **"swift build (verbose)"** dentro da run
   — a mensagem de erro de verdade do compilador vai estar ali.
   Manda um screenshot (ou copia o texto) dessa parte pra mim.

Se isso rodar LIMPO (sem erro), também é informação valiosa — significa
que o problema é mais específico do ambiente do Swift Playgrounds
(recursos do iPad) do que do código em si, e muda a estratégia.

// swift-tools-version: 5.9
import PackageDescription

// Pacote SOMENTE pra diagnóstico — pega as mesmas Models/Store do
// THAC0berry (sem as Views, que dependem de SwiftUI/iOS) e tenta
// compilar como biblioteca Linux comum via `swift build`. O objetivo
// não é rodar o app aqui, é conseguir a MENSAGEM DE ERRO REAL do
// compilador Swift que o Swift Playgrounds no iPad não mostra —
// "expression too complex to type-check in reasonable time" e esse
// tipo de erro vêm do mesmo front-end do compilador em qualquer
// plataforma, então se for isso mesmo, aparece aqui igualzinho.
let package = Package(
    name: "THAC0berryCore",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "THAC0berryCore", path: "Sources/THAC0berryCore")
    ]
)

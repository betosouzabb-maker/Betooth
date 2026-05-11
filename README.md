# Betooth

Base Flutter app para o projeto Betooth, organizada em **feature-first + clean architecture**, com tema dark premium, `go_router`, `Riverpod` e estrutura pronta para evoluir autenticação, biblioteca, player e demais módulos.

## Requisitos

- Flutter SDK latest stable
- Dart SDK incluído no Flutter
- Android SDK com **minSdk 21**
- Xcode/iOS SDK com **iOS 13.0+**

## Setup

1. Instale o Flutter stable e valide com:
   - `flutter --version`
   - `flutter doctor`
2. No diretório do projeto, rode:
   - `flutter pub get`
3. Gere arquivos de codegen quando necessário:
   - `dart run build_runner build --delete-conflicting-outputs`
4. Execute o app:
   - `flutter run`

## Estrutura

- `lib/app`: bootstrap do app, tema, router, DI e config
- `lib/core`: utilitários e abstrações compartilhadas
- `lib/features`: módulos por feature
- `lib/shared`: widgets e layouts reutilizáveis
- `assets`: fontes, ícones, imagens e animações

## Observações

- `package name`: `com.betooth.app`
- Android mínimo: `21`
- iOS mínimo: `13.0`
- Splash animada com fade de 2 segundos
- Mini-player persistente acima da bottom navigation como placeholder

## Próximos passos sugeridos

- Rodar `flutter create . --platforms=android,ios` em um ambiente com Flutter instalado para gerar/atualizar os arquivos nativos padrão, preservando a pasta `lib/`
- Configurar ícones, splash nativa e identidade visual final
- Implementar estado real de autenticação, player e persistência local
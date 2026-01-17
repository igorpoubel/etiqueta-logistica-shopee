# 📦 Etiqueta Logística Shopee (Versão Correios)

O **Etiqueta Logística Shopee** é um utilitário desenvolvido para agilizar a expedição de mercadorias em operações de e-commerce. Ele processa um arquivo PDF de duas páginas e as envia simultaneamente para impressoras distintas, otimizando o fluxo de quem utiliza etiquetas térmicas e impressoras comuns no mesmo processo.

> **⚠️ Nota de Uso:** Este projeto foi testado e validado especificamente para o modelo de **Etiqueta Logística dos Correios** gerado pela Shopee, onde a primeira página é a etiqueta de postagem e a segunda página é a Declaração de Conteúdo.

---

## 🚀 Para Usuários (Instalação e Uso)

Se você não é programador e quer apenas facilitar seu dia a dia de envios, siga estas instruções:

### 1. Download do Instalador

- Vá até a seção [**Releases**](https://github.com/seu-usuario/etiqueta_logistica_shopee/releases) no lado direito desta página.
- Baixe o arquivo executável mais recente: `Instalador_Etiqueta_Shopee_v1.exe`.

### 2. Instalação no Windows

- Execute o arquivo baixado.
- **Nota:** Como o software é independente e não possui assinatura digital paga, o Windows pode exibir um alerta (_"O Windows protegeu o seu computador"_). Clique em **"Mais informações"** e depois em **"Executar assim mesmo"**.
- Siga o passo a passo de instalação até criar o ícone na sua Área de Trabalho.

### 3. Como Usar e Ajustar a Escala

1.  **Configuração de Impressoras:** Na primeira execução, selecione a sua impressora térmica para a **Página 1 (Etiqueta)** e a sua impressora jato de tinta/laser para a **Página 2 (A4)**.
2.  **Ajuste da Etiqueta (Pág 1):** Use o slider para ajustar o zoom. O valor padrão começa em 100%. Como o PDF original é A4, você precisará aumentar a escala (ex: 200% ou mais) até que a etiqueta preencha o preview do papel 100x150mm.
3.  **Ajuste do A4 (Pág 2):** Se a sua Declaração de Conteúdo estiver saindo pequena ou fora de centro na folha comum, use o slider da Página 2 para ajustar a escala de impressão.
4.  **Automação:** O programa salva suas escalas e impressoras automaticamente. Na próxima vez, basta abrir o PDF e clicar em imprimir.

---

## 🛠️ Dados Técnicos (Para Desenvolvedores)

Se você deseja compilar o projeto ou contribuir com o código, siga os requisitos abaixo.

### Requisitos do Sistema

- Flutter SDK (Versão estável).
- Visual Studio 2022 com a carga de trabalho **"Desktop development with C++"**.
- [Inno Setup](https://jrsoftware.org/isdl.php) (necessário para gerar o instalador final `.exe`).

### Comandos para Build

Para gerar a versão de produção otimizada:

```powershell
# Limpa arquivos temporários e busca dependências
flutter clean
flutter pub get

# Gera a pasta de release para Windows
flutter build windows
```

Os binários compilados estarão localizados em:
`build\windows\x64\runner\Release\`

### Arquitetura e Lógica

- **Interface:** Desenvolvida em Flutter com suporte a Preview em tempo real que respeita o _Aspect Ratio_ (proporção) do papel selecionado (100x150mm ou A4).
- **Lógica de Impressão:** Utiliza posicionamento absoluto via coordenadas matemáticas (`Stack` + `Positioned`). Isso garante que o zoom aplicado na interface seja transmitido fielmente ao hardware, ignorando redimensionamentos automáticos (_Shrink to Fit_) comuns em drivers de impressoras térmicas.
- **Persistência:** As seleções de impressoras e os níveis de escala são persistidos localmente via `shared_preferences`. Isso permite que o software mantenha as preferências do usuário mesmo após ser fechado.

---

## 🤝 Contribuições e Roadmap

Este é um projeto de código aberto e toda ajuda é bem-vinda para melhorar a logística de pequenos e médios vendedores!

- **Contribuições:** Sinta-se à vontade para abrir **Issues** ou enviar **Pull Requests** com melhorias de código, correções de bugs ou aprimoramentos na interface.
- **Roadmap de Funcionalidades:**
  - [ ] Suporte para etiquetas **Shopee Xpress**.

---

## 📄 Licença

Distribuído sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

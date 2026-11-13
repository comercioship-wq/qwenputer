# Revisão de arquitetura e melhorias

Análise estática do checkout em 13 nov. 2026. O foco foi reconstruir o caminho entre a especificação da máquina, o compilador e a execução, e identificar riscos concretos de manutenção e uso.

## Como o projeto funciona

1. [`chipformer/spec.py`](../chipformer/spec.py) define a memória CHIP-8, os registradores, os tokens `ADDR`/`VAL`/`STEP` e o formato observável da máquina.
2. [`chipformer/ref/emu.py`](../chipformer/ref/emu.py) é o modelo de referência da semântica CHIP-8. [`chipformer/trace.py`](../chipformer/trace.py) transforma escritas de memória em registros de tokens.
3. [`chipformer/dsl/graph.py`](../chipformer/dsl/graph.py) representa operações simbólicas; [`chipformer/q35/chip8_q35.py`](../chipformer/q35/chip8_q35.py) monta o grafo que implementa a máquina.
4. [`chipformer/compile.py`](../chipformer/compile.py) converte esse grafo em pesos de um transformer. As buscas de atenção e unidades FFN funcionam como tabelas de consulta exatas; o checkpoint resultante contém a implementação da máquina.
5. [`chipformer/check.py`](../chipformer/check.py) compara os registros previstos pelo circuito com a semântica de referência. [`chipformer/session.py`](../chipformer/session.py) dirige um modelo em execução e mantém apenas o espelho de estado necessário para entrada e tela.
6. [`experimental/riscv/`](../experimental/riscv/) contém uma cópia autônoma de `chipformer`, com o compilador e o alvo RV32IM em evolução independente. O README da pasta explicita que essa divergência é intencional.

## Melhorias priorizadas

### Feito nesta revisão: proteger a saída do gerador web

[`chipformer/web.py`](../chipformer/web.py) implementa `python -m chipformer.web space --out ...`. Antes, o comando removia recursivamente qualquer diretório de destino existente e só depois tentava copiar `ROOT/space`. Uma opção `--out` apontada para uma pasta não gerada pelo projeto podia apagar dados do usuário; neste checkout, `space/`, `engine/` e os pesos em `model/` também não estão versionados, então o comando documentado não pode concluir o build.

O comando agora verifica a presença da fonte antes de qualquer substituição, recusa diretórios não vazios sem um marcador próprio e marca a saída gerada para permitir rebuilds seguros. A compilação WASM também dá erro direto quando a fonte `engine/` está ausente.

### Próximo: decidir o destino de `web.py`

O módulo ainda descreve um pipeline para um engine Rust, uma página estática e um checkpoint que não fazem parte deste checkout. Restaurar essas fontes como dependências versionadas, ou mover o gerador para o repositório que as contém, evitaria uma interface de build que parece disponível mas não pode funcionar aqui.

### Próximo: automatizar as verificações de equivalência

O projeto já tem verificadores diferenciais e testes por instrução, compilador e execução. Um workflow de CI que rode o conjunto sem dependências de Hugging Face/GPU em cada mudança protegeria a propriedade central de exatidão; um job separado poderia cobrir as dependências opcionais quando houver ambiente adequado. Não executei a suíte nesta revisão.

### Próximo: detectar deriva no snapshot RISC-V

A cópia isolada em `experimental/riscv/chipformer/` é justificada enquanto as mudanças do compilador não forem integradas. Até lá, uma verificação automatizada de arquivos compartilhados ou um procedimento claro de sincronização reduziria correções divergentes sem forçar a fusão prematura.

## Escopo da Astryx

O clone local `D:\SS\astryx` é um design system React 19/StyleX com CLI para componentes e padrões de interface. Este checkout do Qwenputer é Python e não contém aplicação React ou componentes Astryx; instalar o design system aqui não contribuiria para instalar ou analisar o compilador. A instalação feita nesta máquina foi do próprio pacote Python em `.venv`; não foram baixados pesos opcionais do modelo.

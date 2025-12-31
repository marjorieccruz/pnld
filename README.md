# Extração de Dados PNLD - Matemática (2020-2024)

Este repositório contém dados extraídos do **Programa Nacional do Livro e do Material Didático (PNLD)** do Brasil, filtrados especificamente para o componente curricular de **Matemática**.

Para filtrar outras áreas, altere os termos.

## Sobre os Dados

Os dados originais foram obtidos do FNDE (Fundo Nacional de Desenvolvimento da Educação) e contêm informações sobre a distribuição de livros didáticos para escolas brasileiras entre 2020 e 2024.

### Arquivos Disponíveis

| Arquivo | Descrição | Formato |
|---------|-----------|---------|
| `MATEMATICA_ESTADUAIS.xlsx` | Dados de escolas estaduais | Excel |
| `MATEMATICA_FEDERAIS.xlsx` | Dados de escolas federais | Excel |
| `MATEMATICA_MUNICIPAIS.csv` | Dados de escolas municipais | CSV* |

*O arquivo de escolas municipais é salvo em CSV devido ao grande volume de dados (mais de 1 milhão de registros), que excede o limite do Excel.

### Estrutura dos Dados

Cada arquivo contém as seguintes colunas principais:

| Coluna | Descrição |
|--------|-----------|
| `COD ESCO` | Código da escola |
| `NOME ESCOLA` | Nome da escola |
| `ESFERA` | Esfera administrativa |
| `MUNICIPIO` | Município |
| `UF` | Unidade Federativa (estado) |
| `TITULO` | Título do livro didático |
| `EDITORA` | Editora do livro |
| `COMPONENTE` | Componente curricular (Matemática) |
| `ANO/SÉRIE` | Ano ou série escolar |
| `QTE LIVRO` | Quantidade de livros |
| `TIPO_ESCOLA` | Tipo de escola (ESTADUAL, FEDERAL, MUNICIPAL) |
| `ANO` | Ano de distribuição (2020-2024) |

## Como Extrair os Dados

Se você deseja replicar a extração a partir dos dados brutos do PNLD, siga os passos abaixo.

### Pré-requisitos

- Python 3.8+
- Bibliotecas: `pandas`, `openpyxl`

```bash
pip install pandas openpyxl
```

### Script de Extração

```python
import pandas as pd
import os
import re
from pathlib import Path

# ------------------------------------------------------------
# CONFIGURAÇÃO
# ------------------------------------------------------------

# Altere para o caminho onde estão os arquivos originais do PNLD
caminho = "/caminho/para/seus/arquivos"
filtro = "matem"

# Tipos de escola e padrões de busca
TIPOS_ESCOLA = {
    "ESTADUAIS": "*ESTADUAIS*.xlsx",
    "FEDERAIS": "*FEDERAIS*.xlsx", 
    "MUNICIPAIS": "*MUNICIPAIS*.xlsm",
}

# ------------------------------------------------------------
# FUNÇÕES
# ------------------------------------------------------------

def extrair_ano(nome_arquivo):
    match = re.search(r'(\d{4})', nome_arquivo)
    return int(match.group(1)) if match else None

def processar_arquivo(arquivo, tipo_escola):
    dados = []
    try:
        todas_planilhas = pd.read_excel(arquivo, sheet_name=None)
        
        for nome_aba, df in todas_planilhas.items():
            # Converter nomes das colunas para string e limpar espaços
            df.columns = [str(c).strip() for c in df.columns]
            col_comp = [c for c in df.columns if "COMPONENTE" in c.upper()]
            
            if col_comp:
                # Converter coluna para string antes de filtrar
                coluna = df[col_comp[0]].fillna("").astype(str)
                df_filt = df[coluna.str.contains(filtro, case=False, na=False)]
                
                if len(df_filt) > 0:
                    df_filt = df_filt.copy()
                    df_filt["TIPO_ESCOLA"] = tipo_escola
                    df_filt["ANO"] = extrair_ano(arquivo.name)
                    df_filt["UF"] = nome_aba
                    dados.append(df_filt)
    except Exception as e:
        print(f"Erro: {e}")
    
    return dados

# ------------------------------------------------------------
# PROCESSAMENTO
# ------------------------------------------------------------

for tipo, padrao in TIPOS_ESCOLA.items():
    arquivos = list(Path(caminho).glob(padrao))
    todos_dados = []
    
    for arquivo in arquivos:
        dados = processar_arquivo(arquivo, tipo.rstrip("S"))
        todos_dados.extend(dados)
    
    if todos_dados:
        df_tipo = pd.concat(todos_dados, ignore_index=True)
        
        # Se tiver mais de 1 milhão de linhas, salvar como CSV
        if len(df_tipo) > 1000000:
            df_tipo.to_csv(f"MATEMATICA_{tipo}.csv", index=False, encoding='utf-8-sig')
            print(f"Salvo: MATEMATICA_{tipo}.csv ({len(df_tipo):,} registros)")
        else:
            df_tipo.to_excel(f"MATEMATICA_{tipo}.xlsx", index=False)
            print(f"Salvo: MATEMATICA_{tipo}.xlsx ({len(df_tipo):,} registros)")
```

### Estrutura dos Arquivos Originais

Os arquivos originais do PNLD seguem o padrão:
```
ESCOLAS_ESTADUAIS_ANO_2020.xlsx
ESCOLAS_ESTADUAIS_ANO_2021.xlsx
...
ESCOLAS_FEDERAIS_ANO_2020.xlsx
...
ESCOLAS_MUNICIPAIS_ANO_2020.xlsm
...
```

Cada arquivo contém múltiplas planilhas (abas), uma para cada estado brasileiro (AC, AL, AM, BA, CE, etc.).

## Fonte dos Dados

- **Origem**: FNDE - Fundo Nacional de Desenvolvimento da Educação
- **Programa**: PNLD - Programa Nacional do Livro e do Material Didático
- **Site**: https://www.gov.br/fnde/pt-br/acesso-a-informacao/acoes-e-programas/programas/programas-do-livro

## Licença

Os dados são de domínio público, disponibilizados pelo Governo Federal do Brasil.

## Contato

Para dúvidas ou sugestões, abra uma issue neste repositório.

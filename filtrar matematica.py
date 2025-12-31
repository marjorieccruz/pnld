# ============================================================
# Script Python - Filtrar dados de Matemática
# Gera um arquivo por TIPO DE ESCOLA
# ============================================================

import pandas as pd
import os
import re
from pathlib import Path

# ------------------------------------------------------------
# CONFIGURAÇÃO
# ------------------------------------------------------------

# Altere para o caminho onde estão os arquivos originais do PNLD
caminho = "/caminho/para/sua/pasta/PNLD"
filtro = "matem"

# Tipos de escola e padrões de busca nos nomes dos arquivos
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
    """Processa um arquivo Excel com múltiplas abas"""
    dados = []
    
    try:
        todas_planilhas = pd.read_excel(arquivo, sheet_name=None)
        
        for nome_aba, df in todas_planilhas.items():
            df.columns = df.columns.str.strip()
            col_comp = [c for c in df.columns if "COMPONENTE" in c.upper()]
            
            if col_comp:
                df_filt = df[df[col_comp[0]].astype(str).str.contains(filtro, case=False, na=False)]
                
                if len(df_filt) > 0:
                    df_filt = df_filt.copy()
                    df_filt["TIPO_ESCOLA"] = tipo_escola
                    df_filt["ANO"] = extrair_ano(arquivo.name)
                    df_filt["UF"] = nome_aba
                    dados.append(df_filt)
                    
    except Exception as e:
        print(f"    Erro: {e}")
    
    return dados

# ------------------------------------------------------------
# PROCESSAMENTO POR TIPO
# ------------------------------------------------------------

arquivos_gerados = []

for tipo, padrao in TIPOS_ESCOLA.items():
    print(f"\n{'='*50}")
    print(f"PROCESSANDO: {tipo}")
    print('='*50)
    
    arquivos = list(Path(caminho).glob(padrao))
    print(f"Arquivos encontrados: {len(arquivos)}")
    
    todos_dados = []
    
    for arquivo in arquivos:
        print(f"  → {arquivo.name}...", end=" ", flush=True)
        dados = processar_arquivo(arquivo, tipo.rstrip("S"))  # Remove "S" final
        todos_dados.extend(dados)
        total = sum(len(d) for d in dados)
        print(f"{total} registros")
    
    if todos_dados:
        df_tipo = pd.concat(todos_dados, ignore_index=True)
        
        # Salvar arquivo do tipo
        arquivo_saida = os.path.join(caminho, f"MATEMATICA_{tipo}.xlsx")
        df_tipo.to_excel(arquivo_saida, index=False)
        arquivos_gerados.append((tipo, arquivo_saida, len(df_tipo)))
        
        print(f"\n✓ Salvo: MATEMATICA_{tipo}.xlsx ({len(df_tipo):,} registros)")

# ------------------------------------------------------------
# RESUMO FINAL
# ------------------------------------------------------------

print(f"\n{'='*50}")
print("RESUMO FINAL")
print('='*50)

total_geral = 0
for tipo, arquivo, total in arquivos_gerados:
    print(f"  {tipo}: {total:,} registros")
    total_geral += total

print(f"\n  TOTAL GERAL: {total_geral:,} registros")
print(f"\nArquivos salvos em:\n{caminho}")

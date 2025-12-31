# ============================================================
# Script R - Filtrar dados de Matemática
# Gera um arquivo por TIPO DE ESCOLA
# ============================================================

# Instalar pacotes se necessário
pacotes <- c("openxlsx", "dplyr", "stringr")
for (p in pacotes) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}

library(openxlsx)
library(dplyr)
library(stringr)

# ------------------------------------------------------------
# CONFIGURAÇÃO
# ------------------------------------------------------------

# Altere para o caminho onde estão os arquivos originais do PNLD
caminho <- "/caminho/para/sua/pasta/PNLD"
filtro <- "matem"

# Tipos de escola e padrões de busca
tipos_escola <- list(
  ESTADUAIS = "ESTADUAIS.*\\.xlsx$",
  FEDERAIS = "FEDERAIS.*\\.xlsx$",
  MUNICIPAIS = "MUNICIPAIS.*\\.xlsm$"
)

# ------------------------------------------------------------
# FUNÇÕES
# ------------------------------------------------------------

extrair_ano <- function(nome_arquivo) {
  match <- str_extract(nome_arquivo, "\\d{4}")
  if (!is.na(match)) return(as.integer(match))
  return(NA)
}

processar_arquivo <- function(arquivo, tipo_escola) {
  cat("  ->", basename(arquivo), "... ")
  
  dados <- list()
  
  tryCatch({
    # Carregar workbook e obter nomes das abas
    wb <- loadWorkbook(arquivo)
    abas <- names(wb)
    
    for (aba in abas) {
      df <- read.xlsx(arquivo, sheet = aba)
      
      # Limpar nomes das colunas
      names(df) <- str_trim(names(df))
      
      # Encontrar coluna COMPONENTE
      col_comp <- names(df)[str_detect(toupper(names(df)), "COMPONENTE")]
      
      if (length(col_comp) > 0) {
        # Converter para character e filtrar por matemática
        df_filt <- df %>%
          mutate(across(all_of(col_comp[1]), as.character)) %>%
          filter(str_detect(tolower(.data[[col_comp[1]]]), filtro))
        
        if (nrow(df_filt) > 0) {
          df_filt <- df_filt %>%
            mutate(
              TIPO_ESCOLA = str_remove(tipo_escola, "S$"),
              ANO = extrair_ano(basename(arquivo)),
              UF = aba
            )
          dados <- append(dados, list(df_filt))
        }
      }
    }
    
    total <- sum(sapply(dados, nrow))
    cat(total, "registros\n")
    
  }, error = function(e) {
    cat("Erro:", e$message, "\n")
  })
  
  return(dados)
}

# ------------------------------------------------------------
# PROCESSAMENTO POR TIPO
# ------------------------------------------------------------

arquivos_gerados <- list()

for (tipo in names(tipos_escola)) {
  cat("\n", strrep("=", 50), "\n", sep = "")
  cat("PROCESSANDO:", tipo, "\n")
  cat(strrep("=", 50), "\n")
  
  padrao <- tipos_escola[[tipo]]
  arquivos <- list.files(caminho, pattern = padrao, full.names = TRUE)
  
  cat("Arquivos encontrados:", length(arquivos), "\n\n")
  
  todos_dados <- list()
  
  for (arquivo in arquivos) {
    dados <- processar_arquivo(arquivo, tipo)
    todos_dados <- append(todos_dados, dados)
  }
  
  if (length(todos_dados) > 0) {
    df_tipo <- bind_rows(todos_dados)
    
    # Se tiver mais de 1 milhão de linhas, salvar como CSV
    if (nrow(df_tipo) > 1000000) {
      arquivo_saida <- file.path(caminho, paste0("MATEMATICA_", tipo, ".csv"))
      write.csv(df_tipo, arquivo_saida, row.names = FALSE, fileEncoding = "UTF-8")
      formato <- "CSV"
    } else {
      arquivo_saida <- file.path(caminho, paste0("MATEMATICA_", tipo, ".xlsx"))
      write.xlsx(df_tipo, arquivo_saida, rowNames = FALSE)
      formato <- "XLSX"
    }
    
    arquivos_gerados[[tipo]] <- list(
      arquivo = arquivo_saida,
      registros = nrow(df_tipo),
      formato = formato
    )
    
    cat("\n Salvo: MATEMATICA_", tipo, ".", tolower(formato), 
        " (", format(nrow(df_tipo), big.mark = ","), " registros)\n", sep = "")
  }
}

# ------------------------------------------------------------
# RESUMO FINAL
# ------------------------------------------------------------

cat("\n", strrep("=", 50), "\n", sep = "")
cat("RESUMO FINAL\n")
cat(strrep("=", 50), "\n")

total_geral <- 0
for (tipo in names(arquivos_gerados)) {
  info <- arquivos_gerados[[tipo]]
  cat(" ", tipo, ": ", format(info$registros, big.mark = ","), " registros (", info$formato, ")\n", sep = "")
  total_geral <- total_geral + info$registros
}

cat("\n  TOTAL GERAL: ", format(total_geral, big.mark = ","), " registros\n", sep = "")
cat("\nArquivos salvos em:\n", caminho, "\n")

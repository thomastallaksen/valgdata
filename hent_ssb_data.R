library(PxWebApiData)
library(dplyr)
library(readxl)

# Oppretter data-mappe hvis den ikke eksisterer
if (!dir.exists("data")) {
  dir.create("data")
}

cat("====================================================\n")
cat("HENTER SSB-DATA FOR NORSKE KOMMUNER - 2021\n")
cat("====================================================\n\n")

# ============================================================================
# 1. SENTRALITETSINDEKS
# ============================================================================

cat("1. Henter sentralitetsindeks fra SSB...\n")
url_sent <- "https://www.ssb.no/befolkning/folketall/artikler/sentralitetsindeksen/_/attachment/inline/f35aaacf-dcb1-4e3a-a090-6d14065617fd:d54935b4b6477cd2f47cf5b0fc70d6e50b9baf2d/sentralitet%202023-2024%20kommuner.xlsx"

temp_file <- tempfile(fileext = ".xlsx")
download.file(url_sent, temp_file, mode = "wb", quiet = TRUE)
sentralitet <- read_excel(temp_file)
write.csv(sentralitet, "data/sentralitetsindeks_2023-2024.csv", row.names = FALSE, fileEncoding = "UTF-8")

cat("   ✓ Lastet ned:", nrow(sentralitet), "kommuner\n")
cat("   Lagret i: data/sentralitetsindeks_2023-2024.csv\n\n")

# ============================================================================
# 2. BEFOLKNING OG AREAL (tabell 11342)
# ============================================================================

cat("2. Henter befolkning og areal for kommuner (tabell 11342)...\n")

# Hent metadata for å se tilgjengelige verdier
metadata_11342 <- ApiData("https://data.ssb.no/api/v0/no/table/11342",
                          returnMetaFrames = TRUE)

# Hent data
befolkning <- ApiData(
  "https://data.ssb.no/api/v0/no/table/11342",
  Region = TRUE,  # Alle kommuner
  ContentsCode = c("Folkemengde", "LandArealKm2", "FolkeLandArealKm2"),
  Tid = "2021"
)

# Rydd opp i datasettet
befolkning_clean <- befolkning[[1]] %>%
  select(region, value, statistikkvariabel) %>%
  group_by(region, statistikkvariabel) %>%
  summarise(value = first(value), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = statistikkvariabel, values_from = value)

write.csv(befolkning_clean, "data/befolkning_areal_2021.csv", row.names = FALSE, fileEncoding = "UTF-8")

cat("   ✓ Lastet ned:", nrow(befolkning_clean), "kommuner\n")
cat("   Lagret i: data/befolkning_areal_2021.csv\n\n")

# ============================================================================
# 3. UTDANNINGSNIVÅ (tabell 09429)
# ============================================================================

cat("3. Henter utdanningsnivå for kommuner (tabell 09429)...\n")

utdanning <- ApiData(
  "https://data.ssb.no/api/v0/no/table/09429",
  Region = TRUE,  # Alle kommuner
  Kjonn = "0",    # Begge kjønn
  Nivaa = c("00", "02a", "03a", "04a"),  # Totalt, videregående, fagskoleutdanning, universitet/høgskole
  Tid = "2021"
)

# Rydd opp i datasettet
utdanning_df <- utdanning[[1]]
utdanning_clean <- utdanning_df %>%
  rename(antall = value)

write.csv(utdanning_clean, "data/utdanning_2021.csv", row.names = FALSE, fileEncoding = "UTF-8")

cat("   ✓ Lastet ned:", nrow(utdanning_clean), "rader\n")
cat("   Kolonner:", paste(names(utdanning_clean), collapse = ", "), "\n")
cat("   Lagret i: data/utdanning_2021.csv\n\n")

# ============================================================================
# 4. INNTEKT (tabell 06944)
# ============================================================================

cat("4. Henter medianinntekt for kommuner (tabell 06944)...\n")

inntekt <- ApiData(
  "https://data.ssb.no/api/v0/no/table/06944",
  Region = TRUE,  # Alle kommuner
  HusholdType = "0000",  # Alle husholdninger
  ContentsCode = "InntSkatt",  # Inntekt etter skatt, median
  Tid = "2021"
)

# Rydd opp i datasettet
inntekt_clean <- inntekt[[1]] %>%
  select(region, value) %>%
  rename(median_inntekt = value)

write.csv(inntekt_clean, "data/inntekt_2021.csv", row.names = FALSE, fileEncoding = "UTF-8")

cat("   ✓ Lastet ned:", nrow(inntekt_clean), "kommuner\n")
cat("   Lagret i: data/inntekt_2021.csv\n\n")

# ============================================================================
# OPPSUMMERING
# ============================================================================

cat("====================================================\n")
cat("FERDIG! Alle data er lastet ned og lagret.\n")
cat("====================================================\n\n")

cat("Filer lagret i data/-mappen:\n")
cat("  1. data/sentralitetsindeks_2023-2024.csv\n")
cat("     - Kommuner:", nrow(sentralitet), "\n")
cat("     - Sentralitetsindeks og klasser\n\n")

cat("  2. data/befolkning_areal_2021.csv\n")
cat("     - Kommuner:", nrow(befolkning_clean), "\n")
cat("     - Folkemengde, landareal, personer per km²\n\n")

cat("  3. data/utdanning_2021.csv\n")
cat("     - Rader:", nrow(utdanning_clean), "\n")
cat("     - Utdanningsnivå: Totalt, grunnskole, høyere utdanning\n\n")

cat("  4. data/inntekt_2021.csv\n")
cat("     - Kommuner:", nrow(inntekt_clean), "\n")
cat("     - Medianinntekt etter skatt\n\n")

cat("Disse dataene kan nå kobles med valgdataene for analyse!\n")

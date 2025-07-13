# Tilgang til dataene fra alle_data listen

# alle_data er en liste med to elementer:
# $stemmer - alle stemmeresultater på valgkrets-nivå
# $mandater - alle mandatresultater på riktig nivå per valgtype

# Hent ut dataframes fra listen:
stemmedata <- alle_data$stemmer
mandatdata <- alle_data$mandater

cat("Stemmedata:\n")
cat("- Rader:", nrow(stemmedata), "\n")
cat("- Kolonner:", ncol(stemmedata), "\n")
if (nrow(stemmedata) > 0) {
  cat("- År:", paste(unique(stemmedata$aar), collapse = ", "), "\n")
  cat("- Valgtyper:", paste(unique(stemmedata$valgtype), collapse = ", "), "\n")
  cat("- Antall unike valgkretser:", length(unique(stemmedata$valgkrets_navn)), "\n")
}

cat("\nMandatdata:\n")
cat("- Rader:", nrow(mandatdata), "\n")
cat("- Kolonner:", ncol(mandatdata), "\n")
if (nrow(mandatdata) > 0) {
  cat("- År:", paste(unique(mandatdata$aar), collapse = ", "), "\n")
  cat("- Valgtyper:", paste(unique(mandatdata$valgtype), collapse = ", "), "\n")
  cat("- Stedtyper:", paste(unique(mandatdata$sted_type), collapse = ", "), "\n")
}

cat("\n=== Eksempel på stemmedata ===\n")
if (nrow(stemmedata) > 0) {
  print(head(stemmedata, 3))
}

cat("\n=== Eksempel på mandatdata ===\n")
if (nrow(mandatdata) > 0) {
  print(head(mandatdata, 3))
}

cat("\n=== Hvordan bruke dataene ===\n")
cat("# Få tilgang til stemmedata:\n")
cat("stemmedata <- alle_data$stemmer\n\n")

cat("# Få tilgang til mandatdata:\n") 
cat("mandatdata <- alle_data$mandater\n\n")

cat("# Eksempel analyser:\n")
cat("# Stemmer per parti i Oslo 2021:\n")
cat("oslo_2021 <- stemmedata[stemmedata$fylke_navn == 'Oslo' & stemmedata$aar == 2021, ]\n\n")

cat("# Mandater per fylke i stortingsvalg 2021:\n")
cat("st_mandater_2021 <- mandatdata[mandatdata$valgtype == 'st' & mandatdata$aar == 2021, ]\n\n")

cat("# Aggreger stemmer til fylkesnivå:\n")
cat("library(dplyr)\n")
cat("fylke_stemmer <- stemmedata %>%\n")
cat("  group_by(aar, valgtype, fylke_navn, parti_navn) %>%\n")
cat("  summarise(totale_stemmer = sum(stemmer_antall, na.rm = TRUE))\n")
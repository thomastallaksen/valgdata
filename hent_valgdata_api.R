library(httr)
library(jsonlite)
library(dplyr)

# Funksjon for å hente valgresultater for ett spesifikt år med separerte data
hent_valgresultater_aar_separert <- function(target_aar) {
  base_url <- "https://valgresultat.no/api"
  
  if (!dir.exists("data")) {
    dir.create("data")
  }
  
  # Hent hovedindeks
  response <- GET(base_url)
  main_data <- fromJSON(content(response, "text"))
  
  # Initialiser dataframes
  alle_stemmedata <- data.frame()
  alle_mandatdata <- data.frame()
  
  cat("Henter valgkrets-resultater for", target_aar, "...\n\n")
  
  # Hjelpefunksjoner
  safe_extract <- function(obj, default = NA) {
    tryCatch({
      if (is.null(obj) || length(obj) == 0) return(default)
      return(obj)
    }, error = function(e) default)
  }
  
  safe_nrow <- function(obj) {
    if (is.null(obj)) return(0)
    if (is.data.frame(obj)) return(nrow(obj))
    if (is.list(obj) && length(obj) == 0) return(0)
    return(0)
  }
  
  # Funksjon for å hente stemmedata på valgkrets-nivå (uten mandater)
  hent_stemmedata <- function(data, aar, valgtype, kommune_navn, fylke_navn) {
    if (!is.null(data$partier) && safe_nrow(data$partier) > 0) {
      partier_df <- data$partier
      n_partier <- nrow(partier_df)
      
      stemme_resultater <- data.frame(
        aar = rep(aar, n_partier),
        valgtype = rep(valgtype, n_partier),
        fylke_navn = rep(fylke_navn, n_partier),
        kommune_navn = rep(kommune_navn, n_partier),
        valgkrets_navn = rep(safe_extract(data$id$navn, ""), n_partier),
        valgkrets_nr = rep(safe_extract(data$id$nr, ""), n_partier),
        parti_kode = safe_extract(partier_df$id$partikode, rep(NA, n_partier)),
        parti_navn = safe_extract(partier_df$id$navn, rep(NA, n_partier)),
        parti_kategori = safe_extract(partier_df$id$partikategori, rep(NA, n_partier)),
        stemmer_prosent = safe_extract(partier_df$stemmer$resultat$prosent, rep(NA, n_partier)),
        stemmer_antall = safe_extract(partier_df$stemmer$resultat$antall$total, rep(NA, n_partier)),
        stemmer_fhs = safe_extract(partier_df$stemmer$resultat$antall$fhs, rep(NA, n_partier)),
        stringsAsFactors = FALSE
      )
      return(stemme_resultater)
    }
    return(data.frame())
  }
  
  # Funksjon for å hente mandatdata på riktig nivå
  hent_mandatdata <- function(data, aar, valgtype, sted_navn, sted_type, overordnet_navn = "") {
    if (!is.null(data$partier) && safe_nrow(data$partier) > 0) {
      partier_df <- data$partier
      
      # Filtrer kun partier med mandater
      har_mandater <- !is.na(safe_extract(partier_df$mandater$resultat$antall, rep(NA, nrow(partier_df))))
      if (any(har_mandater)) {
        partier_med_mandater <- partier_df[har_mandater, ]
        n_partier <- nrow(partier_med_mandater)
        
        mandat_resultater <- data.frame(
          aar = rep(aar, n_partier),
          valgtype = rep(valgtype, n_partier),
          sted_type = rep(sted_type, n_partier),
          sted_navn = rep(sted_navn, n_partier),
          overordnet_navn = rep(overordnet_navn, n_partier),
          parti_kode = safe_extract(partier_med_mandater$id$partikode, rep(NA, n_partier)),
          parti_navn = safe_extract(partier_med_mandater$id$navn, rep(NA, n_partier)),
          mandater_antall = safe_extract(partier_med_mandater$mandater$resultat$antall, rep(NA, n_partier)),
          mandater_endring = safe_extract(partier_med_mandater$mandater$resultat$endring, rep(NA, n_partier)),
          stringsAsFactors = FALSE
        )
        return(mandat_resultater)
      }
    }
    return(data.frame())
  }
  
  # Sjekk om året finnes
  if (!target_aar %in% names(main_data$`_sublinks`)) {
    cat("Feil: År", target_aar, "finnes ikke i API\n")
    return(list(stemmer = data.frame(), mandater = data.frame()))
  }
  
  valg_i_aar <- main_data$`_sublinks`[[target_aar]]
  
  for (i in seq_len(nrow(valg_i_aar))) {
    valgtype <- valg_i_aar$navn[i]
    href <- valg_i_aar$href[i]
    
    cat("Henter data for", valgtype, target_aar, "...\n")
    
    valg_url <- paste0(base_url, href)
    tryCatch({
      valg_response <- GET(valg_url)
      
      if (status_code(valg_response) == 200) {
        data <- fromJSON(content(valg_response, "text"))
        
        # Bestem mandatnivå basert på valgtype
        mandat_nivaa <- switch(valgtype,
          "st" = "fylke",      # Stortingsvalg: mandater per fylke
          "ft" = "fylke",      # Fylkesting: mandater per fylke
          "ko" = "kommune",    # Kommunevalg: mandater per kommune
          "sa" = "valgkrets",  # Sametingsvalg: spesiell struktur
          "kommune"            # Default
        )
        
        # Hent fylker/regioner
        if (!is.null(data$`_links`$related) && safe_nrow(data$`_links`$related) > 0) {
          fylker <- data$`_links`$related
          cat("  - Behandler", nrow(fylker), "fylker/regioner\n")
          
          for (j in seq_len(nrow(fylker))) {
            fylke_href <- fylker$href[j]
            fylke_navn <- fylker$navn[j]
            
            fylke_url <- paste0(base_url, fylke_href)
            tryCatch({
              fylke_response <- GET(fylke_url)
              
              if (status_code(fylke_response) == 200) {
                fylke_data <- fromJSON(content(fylke_response, "text"))
                
                # Hent mandater på fylkesnivå for stortings- og fylkestingsvalg
                if (mandat_nivaa == "fylke") {
                  fylke_mandater <- hent_mandatdata(fylke_data, target_aar, valgtype, fylke_navn, "fylke")
                  if (nrow(fylke_mandater) > 0) {
                    alle_mandatdata <- rbind(alle_mandatdata, fylke_mandater)
                    cat("    ✓ Hentet mandater for fylke", fylke_navn, "\n")
                  }
                }
                
                # Hent kommuner i fylket
                if (!is.null(fylke_data$`_links`$related) && safe_nrow(fylke_data$`_links`$related) > 0) {
                  kommuner <- fylke_data$`_links`$related
                  
                  for (k in seq_len(nrow(kommuner))) {
                    kommune_href <- kommuner$href[k]
                    kommune_navn <- kommuner$navn[k]
                    
                    kommune_url <- paste0(base_url, kommune_href)
                    tryCatch({
                      kommune_response <- GET(kommune_url)
                      
                      if (status_code(kommune_response) == 200) {
                        kommune_data <- fromJSON(content(kommune_response, "text"))
                        
                        # Hent mandater på kommunenivå for kommunevalg
                        if (mandat_nivaa == "kommune") {
                          kommune_mandater <- hent_mandatdata(kommune_data, target_aar, valgtype, kommune_navn, "kommune", fylke_navn)
                          if (nrow(kommune_mandater) > 0) {
                            alle_mandatdata <- rbind(alle_mandatdata, kommune_mandater)
                          }
                        }
                        
                        # Hent stemmedata på valgkrets-nivå
                        if (!is.null(kommune_data$`_links`$related) && safe_nrow(kommune_data$`_links`$related) > 0) {
                          # Kommune med valgkretser
                          valgkretser <- kommune_data$`_links`$related
                          
                          for (l in seq_len(nrow(valgkretser))) {
                            krets_href <- valgkretser$href[l]
                            krets_navn <- valgkretser$navn[l]
                            
                            krets_url <- paste0(base_url, krets_href)
                            tryCatch({
                              krets_response <- GET(krets_url)
                              
                              if (status_code(krets_response) == 200) {
                                krets_data <- fromJSON(content(krets_response, "text"))
                                
                                # Hent stemmedata for valgkrets
                                krets_stemmer <- hent_stemmedata(krets_data, target_aar, valgtype, kommune_navn, fylke_navn)
                                if (nrow(krets_stemmer) > 0) {
                                  alle_stemmedata <- rbind(alle_stemmedata, krets_stemmer)
                                }
                              }
                            }, error = function(e) {
                              cat("      ✗ Feil ved", krets_navn, "\n")
                            })
                            
                            Sys.sleep(0.05)
                          }
                        } else {
                          # Kommune uten valgkretser - bruk kommune som valgkrets
                          if (!is.null(kommune_data$partier) && safe_nrow(kommune_data$partier) > 0) {
                            kommune_stemmer <- hent_stemmedata(kommune_data, target_aar, valgtype, kommune_navn, fylke_navn)
                            if (nrow(kommune_stemmer) > 0) {
                              alle_stemmedata <- rbind(alle_stemmedata, kommune_stemmer)
                            }
                          }
                        }
                      }
                    }, error = function(e) {
                      cat("    ✗ Feil ved", kommune_navn, "\n")
                    })
                    
                    Sys.sleep(0.05)
                  }
                }
              }
            }, error = function(e) {
              cat("  ✗ Feil ved", fylke_navn, "\n")
            })
            
            Sys.sleep(0.1)
          }
        }
        
        cat("  ✓ Ferdig med", target_aar, valgtype, "\n")
      }
    }, error = function(e) {
      cat("  ✗ Feil:", e$message, "\n")
    })
    
    Sys.sleep(0.2)
  }
  
  return(list(
    stemmer = alle_stemmedata,
    mandater = alle_mandatdata
  ))
}

# Funksjon for å lagre ett års data (begge dataframes)
lagre_aar_data_separert <- function(aar) {
  stemmer_filename <- paste0("data/stemmedata_", aar, ".csv")
  mandater_filename <- paste0("data/mandatdata_", aar, ".csv")
  
  # Sjekk om filene allerede eksisterer
  if (file.exists(stemmer_filename) && file.exists(mandater_filename)) {
    cat("Filene for", aar, "eksisterer allerede. Hopper over.\n")
    return(TRUE)
  }
  
  cat("Henter data for", aar, "...\n")
  data <- hent_valgresultater_aar_separert(aar)
  
  if (nrow(data$stemmer) > 0 || nrow(data$mandater) > 0) {
    write.csv(data$stemmer, stemmer_filename, row.names = FALSE)
    write.csv(data$mandater, mandater_filename, row.names = FALSE)
    cat("Lagret", nrow(data$stemmer), "stemmerader og", nrow(data$mandater), "mandatrader for", aar, "\n")
    return(TRUE)
  } else {
    cat("Ingen data funnet for", aar, "\n")
    return(FALSE)
  }
}

# Funksjon for å kombinere alle års-filer
kombiner_alle_aar_separert <- function() {
  stemme_filer <- list.files("data", pattern = "stemmedata_[0-9]{4}\\.csv", full.names = TRUE)
  mandat_filer <- list.files("data", pattern = "mandatdata_[0-9]{4}\\.csv", full.names = TRUE)
  
  # Kombiner stemmedata
  alle_stemmer <- data.frame()
  if (length(stemme_filer) > 0) {
    for (fil in stemme_filer) {
      aar_data <- read.csv(fil, stringsAsFactors = FALSE)
      alle_stemmer <- rbind(alle_stemmer, aar_data)
    }
    write.csv(alle_stemmer, "data/stemmedata_alle_aar.csv", row.names = FALSE)
    cat("Kombinert stemmedata:", nrow(alle_stemmer), "rader\n")
  }
  
  # Kombiner mandatdata
  alle_mandater <- data.frame()
  if (length(mandat_filer) > 0) {
    for (fil in mandat_filer) {
      aar_data <- read.csv(fil, stringsAsFactors = FALSE)
      alle_mandater <- rbind(alle_mandater, aar_data)
    }
    write.csv(alle_mandater, "data/mandatdata_alle_aar.csv", row.names = FALSE)
    cat("Kombinert mandatdata:", nrow(alle_mandater), "rader\n")
  }
  
  return(list(
    stemmer = alle_stemmer,
    mandater = alle_mandater
  ))
}

# Hovedscript for å hente alle år med separerte data
hent_alle_aar_separert <- function(start_aar = 2013, slutt_aar = 2021) {
  cat("Starter henting av separerte data fra", start_aar, "til", slutt_aar, "\n\n")
  
  for (aar in start_aar:slutt_aar) {
    cat("=== Behandler år", aar, "===\n")
    success <- lagre_aar_data_separert(as.character(aar))
    
    if (success) {
      cat("✓ År", aar, "fullført\n\n")
    } else {
      cat("✗ År", aar, "feilet\n\n")
    }
    
    Sys.sleep(1)
  }
  
  cat("=== Kombinerer alle år ===\n")
  kombinerte_data <- kombiner_alle_aar_separert()
  
  cat("\nFerdig! Du har nå:\n")
  cat("- Stemmedata: data/stemmedata_alle_aar.csv (", nrow(kombinerte_data$stemmer), "rader)\n")
  cat("- Mandatdata: data/mandatdata_alle_aar.csv (", nrow(kombinerte_data$mandater), "rader)\n")
  cat("- Individuelle år-filer i data/\n")
  
  return(kombinerte_data)
}

# Kjør henting av alle år med separerte dataframes
cat("Starter år-for-år henting med separerte stem- og mandatdata...\n")
cat("Stemmer: valgkrets-nivå | Mandater: fylke (st/ft) eller kommune (ko)\n\n")

alle_data <- hent_alle_aar_separert()
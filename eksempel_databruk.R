source("hent_valgdata_api.R")

# For å hente kun ett spesifikt år med separerte data:
# data_2021 <- hent_valgresultater_aar_separert("2021")
# stemmer_2021 <- data_2021$stemmer
# mandater_2021 <- data_2021$mandater

# For å lagre ett spesifikt år:
# lagre_aar_data_separert("2021")

# For å kombinere eksisterende filer:
# alle_data <- kombiner_alle_aar_separert()

# For å hente et spesifikt tidsrom:
# data_2017_2021 <- hent_alle_aar_separert(2017, 2021)

cat("Tilgjengelige funksjoner for separerte data:\n")
cat("- hent_valgresultater_aar_separert('2021') - returnerer list(stemmer, mandater)\n")
cat("- lagre_aar_data_separert('2021') - lagrer stemmedata_2021.csv og mandatdata_2021.csv\n") 
cat("- kombiner_alle_aar_separert() - kombinerer til stemmedata_alle_aar.csv og mandatdata_alle_aar.csv\n")
cat("- hent_alle_aar_separert(2017, 2021) - henter flere år med separerte data\n\n")

cat("Mandatnivåer:\n")
cat("- Stortingsvalg (st): mandater per fylke\n")
cat("- Fylkestingsvalg (ft): mandater per fylke\n") 
cat("- Kommunevalg (ko): mandater per kommune\n")
cat("- Sametingsvalg (sa): mandater per valgkrets\n\n")

cat("Stemmedata er alltid på valgkrets-nivå med fylke/kommune-info\n")
# Norske Valgdata

Dette prosjektet henter og organiserer norske valgresultater fra valgresultat.no API for perioden 2013-2021.

## Filer

### Hovedskript
- **`hent_valgdata_api.R`** - Henter valgdata fra API og lagrer dem lokalt
- **`eksempel_databruk.R`** - Viser hvordan du bruker de nedlastede dataene  
- **`dataoversikt.R`** - Forklarer datastrukturen og gir eksempler

### Data
Alle data lagres i `data/`-mappen:
- `stemmedata_[år].csv` - Stemmeresultater per år på valgkrets-nivå
- `mandatdata_[år].csv` - Mandatfordeling per år på riktig nivå  
- `stemmedata_alle_aar.csv` - Alle stemmedata kombinert
- `mandatdata_alle_aar.csv` - Alle mandatdata kombinert

## Hvordan komme i gang

### 1. Hent data
```r
source("hent_valgdata_api.R")

# Hent alle år (2013-2021)
alle_data <- hent_alle_aar_separert()

# Eller bare ett spesifikt år
data_2021 <- hent_valgresultater_aar_separert("2021")
```

### 2. Bruk dataene
```r
source("dataoversikt.R")  # Viser struktur og eksempler

# Få tilgang til data
stemmedata <- alle_data$stemmer
mandatdata <- alle_data$mandater

# Eller les fra fil
stemmedata <- read.csv("data/stemmedata_alle_aar.csv")
mandatdata <- read.csv("data/mandatdata_alle_aar.csv")
```

## Datastruktur

### Stemmedata (valgkrets-nivå)
- `aar` - Valgår
- `valgtype` - st (Storting), ft (Fylkesting), ko (Kommune), sa (Sameting)
- `fylke_navn`, `kommune_navn`, `valgkrets_navn` - Geografisk info
- `parti_kode`, `parti_navn` - Parti-informasjon
- `stemmer_antall`, `stemmer_prosent` - Stemmeresultater

### Mandatdata (fylke/kommune-nivå)
- `aar`, `valgtype` - Som over
- `sted_type` - fylke, kommune eller valgkrets
- `sted_navn` - Navn på fylke/kommune
- `parti_kode`, `parti_navn` - Parti-informasjon  
- `mandater_antall` - Antall mandater

## Mandatnivåer
- **Stortingsvalg (st)**: Mandater per fylke
- **Fylkestingsvalg (ft)**: Mandater per fylke
- **Kommunevalg (ko)**: Mandater per kommune
- **Sametingsvalg (sa)**: Mandater per valgkrets

## Eksempel-analyser

```r
library(dplyr)

# Stemmer per parti i Oslo 2021
oslo_2021 <- stemmedata %>%
  filter(fylke_navn == "Oslo", aar == 2021) %>%
  group_by(parti_navn) %>%
  summarise(totale_stemmer = sum(stemmer_antall, na.rm = TRUE))

# Mandater per fylke i stortingsvalg 2021  
st_mandater_2021 <- mandatdata %>%
  filter(valgtype == "st", aar == 2021) %>%
  group_by(sted_navn) %>%
  summarise(totale_mandater = sum(mandater_antall, na.rm = TRUE))

# Partienes utvikling over tid
parti_utvikling <- stemmedata %>%
  group_by(aar, parti_navn) %>%
  summarise(totale_stemmer = sum(stemmer_antall, na.rm = TRUE)) %>%
  arrange(parti_navn, aar)
```

## Avhengigheter
```r
install.packages(c("httr", "jsonlite", "dplyr"))
```
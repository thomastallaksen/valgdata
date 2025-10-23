# Analyse av valgdata

## Quarto-dokument opprettet!

Jeg har laget et komplett analysedokument: **analyse_valgdata.qmd**

### Hva dokumentet gjør:

1. **Laster inn data**
   - Valgdata (2013-2021)
   - SSB befolkning, inntekt, utdanning, sentralitet

2. **Preprosesserer data**
   - Beregner andel med høyere utdanning per kommune
   - Rydder opp i sentralitetsdata
   - Aggregerer stemmedata til kommune-nivå

3. **Slår sammen alt**
   - Lager ett komplett datasett: `data/valgdata_komplett.csv`
   - Kobler kommune-navn mellom valgdata og SSB-data

4. **Analyser med visualiseringer**
   - Partienes utvikling over tid (2013-2021)
   - Stemmegivning og inntektsnivå
   - Stemmegivning og utdanningsnivå
   - By vs. land (sentralitetsanalyse)
   - Befolkningstetthet og stemmegivning

### Kjør analysen:

```bash
# I terminal
quarto render analyse_valgdata.qmd

# Eller åpne i RStudio og klikk "Render"
```

Dette genererer en HTML-fil med alle analyser og grafer!

### Valgdata 2023/2025

Scriptet `hent_nye_valgdata.R` er opprettet for å laste ned 2023 og 2025 data.
Nedlastingen tar lang tid (10-15 min per år). Kjør:

```bash
Rscript hent_nye_valgdata.R
```

Når de er ferdig, kjør Quarto-dokumentet på nytt for å inkludere de nye årene!

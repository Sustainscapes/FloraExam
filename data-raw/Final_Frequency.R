## code to prepare `Final_Frequency` dataset goes here

library(tidyverse)
library(readxl)
library(fuzzyjoin)
library(stringdist)

# This sources the apply_rules function for filtering the Final_Frequency dataset
source("data-raw/Final_Frequency_rules.R")

Final_Frequency <- read_csv("data-raw/Final_Frequency.csv") |>
  # Run the apply_rules function on the species column
  dplyr::mutate(species = map_chr(species, apply_rules)) |>
  dplyr::filter(!is.na(species)) |>
  dplyr::mutate(plot = as.character(plot))

# Changing species names of Final_Frequency to match taxon names on Arter.dk
Final_Frequency$species <- ifelse(Final_Frequency$species == "Taraxacum officinale",
                                                 "Taraxacum officinale sensu lato", Final_Frequency$species)
Final_Frequency$species <- ifelse(Final_Frequency$species == "Rubus fruticosus",
                                  "Rubus fruticosus sensu lato", Final_Frequency$species)
Final_Frequency$species <- ifelse(Final_Frequency$species == "Inula salicina",
                                  "Pentanema salicinum", Final_Frequency$species)
Final_Frequency$species <- ifelse(Final_Frequency$species == "Schoenoplectus maritimus",
                                  "Bolboschoenus maritimus", Final_Frequency$species)
Final_Frequency$species <- ifelse(Final_Frequency$species == "Avenula pratensis",
                                  "Helictochloa pratensis", Final_Frequency$species)
Final_Frequency$species <- ifelse(Final_Frequency$species == "Salicornia europaea coll.",
                                  "Salicornia europaea", Final_Frequency$species)
Final_Frequency$species <- ifelse(Final_Frequency$species == "Spartina ×townsendii",
                                  "Spartina alterniflora × maritima", Final_Frequency$species)

# Read in taxon data from Arter.dk. Excludes "Marchantiophyta", "Anthocerotophyta" and "Bryophyta" that are not Sphagnum.
taxonlist_plants <- read_xlsx("data-raw/taxonlist_Plants.xlsx") |>
  filter(!(Række == "Bryophyta" & Familie != "Sphagnaceae") & Række != "Marchantiophyta" & Række != "Anthocerotophyta") |>
  dplyr::select("Videnskabeligt navn", "Accepteret dansk navn", "TaxonId") |>
  rename(Accepteret_dansk_navn = "Accepteret dansk navn", taxon_id_Arter = "TaxonId")

taxonlist_lichens <- read_xlsx("data-raw/taxonlist_Lichens.xlsx") |>
  dplyr::select("Videnskabeligt navn", "Accepteret dansk navn", "TaxonId") |>
  rename(Accepteret_dansk_navn = "Accepteret dansk navn", taxon_id_Arter = "TaxonId")

Final_Frequency <- Final_Frequency %>%
  left_join(taxonlist_plants, by = join_by("species" == "Videnskabeligt navn")) %>%
  left_join(taxonlist_lichens, by = join_by("species" == "Videnskabeligt navn")) %>%
  mutate(Accepteret_dansk_navn = coalesce(Accepteret_dansk_navn.x, Accepteret_dansk_navn.y)) %>%
  mutate(taxon_id_Arter = coalesce(taxon_id_Arter.x, taxon_id_Arter.y)) |>
  select(-Accepteret_dansk_navn.x, -Accepteret_dansk_navn.y, -taxon_id_Arter.x, -taxon_id_Arter.y)

# Remove records that did not match to Arter.dk taxa
Final_Frequency <- Final_Frequency[!is.na(Final_Frequency$taxon_id_Arter),]

unique_taxa <- read_xlsx("data-raw/DFV_app_indicator_common_species.xlsx") |>
  select(videnskabeligt_navn) |>
  distinct()

unique_taxa$videnskabeligt_navn <- tolower(unique_taxa$videnskabeligt_navn)

taxa_df <- tibble(Taxa = Final_Frequency$species)
files_df <- tibble(Taxa = list.files("inst/Pictures"))

# Standardize filenames by removing ".jpg" and replacing underscores with spaces
files_df <- files_df |>
  mutate(Taxa = gsub("\\.jpg$", "", Taxa), Taxa = gsub("\\.JPG$", "", Taxa),
         Taxa = gsub("_", " ", Taxa))

# Perform fuzzy matching
matched <- stringdist_left_join(
  unique_taxa, files_df,
  by = c("videnskabeligt_navn" = "Taxa"),
  method = "osa",
  max_dist = 1.5
)

# Restore the original filenames in matched, ignoring NAs
matched$Taxa <- ifelse(is.na(matched$Taxa), NA, paste0(matched$Taxa, ".jpg"))
matched$Taxa <- ifelse(is.na(matched$Taxa), NA, gsub(" ", "_", matched$Taxa))

firstup <- function(x) {
  substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  x
}

matched$videnskabeligt_navn <- firstup(matched$videnskabeligt_navn)

# Update Final_Frequency with taxon_id_Arter and photo_file
Final_Frequency <- Final_Frequency |>
  stringdist_left_join(
    matched,
    by = c("species" = "videnskabeligt_navn"),
    method = "osa",
    max_dist = 1
  ) |>
  rename(photo_file = Taxa) |>
  select(-videnskabeligt_navn)

# Final_Frequency <- Final_Frequency_combined %>%
#   group_by(plot, year, Taxa) %>%
#   filter(!is.na(taxon_id_Arter) | row_number() == 1) %>%  # Keep non-NA taxon_id_Arter or the first row if all are NA
#   arrange(desc(!is.na(taxon_id_Arter))) %>%
#   slice(1) %>%  # Keep the first row within each group
#   ungroup() %>%  # Ungroup to return to the original data frame structure
#   distinct()

usethis::use_data(Final_Frequency, overwrite = TRUE)

# Cladonia and Sphagnum habitat codes are exported from the exceptions_and_rules.csv
# file. These are the habitat types where we want to show these groups, else hide them.

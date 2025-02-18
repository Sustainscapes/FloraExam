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

unique_taxa <- read_xlsx("data-raw/DFV_app_indicator_common_species.xlsx") |>
  select(videnskabeligt_navn, taxon_id_Arter) |>
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
  rename(photo_file = Taxa)

usethis::use_data(Final_Frequency, overwrite = TRUE)

# Cladonia and Sphagnum habitat codes are exported from the exceptions_and_rules.csv
# file. These are the habitat types where we want to show these groups, else hide them.
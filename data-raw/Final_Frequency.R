## code to prepare `Final_Frequency` dataset goes here

library(tidyverse)
library(readxl)
library(fuzzyjoin)
library(stringdist)

Final_Frequency <- read_csv("data-raw/Final_Frequency.csv") |>
  dplyr::filter(!is.na(species)) |>
  dplyr::mutate(plot = as.character(plot))

taxonlist_plants <- read_xlsx("data-raw/taxonlist_Plants.xlsx") %>%
  select("Videnskabeligt navn", "Accepteret dansk navn") %>%
  rename(Accepteret_dansk_navn = "Accepteret dansk navn")

taxonlist_lichens <- read_xlsx("data-raw/taxonlist_Lichens.xlsx") %>%
  select("Videnskabeligt navn", "Accepteret dansk navn") %>%
  rename(Accepteret_dansk_navn = "Accepteret dansk navn")

Final_Frequency <- Final_Frequency %>%
  left_join(taxonlist_plants, by = join_by("species" == "Videnskabeligt navn")) %>%
  left_join(taxonlist_lichens, by = join_by("species" == "Videnskabeligt navn")) %>%
  mutate(Accepteret_dansk_navn = coalesce(Accepteret_dansk_navn.x, Accepteret_dansk_navn.y)) %>%
  select(-Accepteret_dansk_navn.x, -Accepteret_dansk_navn.y)

unique_taxa <- read_xlsx("data-raw/DFV_app_indicator_common_species.xlsx") %>%
  select(videnskabeligt_navn, taxon_id_Arter) %>%
  distinct()

unique_taxa$videnskabeligt_navn <- tolower(unique_taxa$videnskabeligt_navn)

taxa_df <- tibble(Taxa = Final_Frequency$species)
files_df <- tibble(Taxa = list.files("inst/Pictures"))

# Standardize filenames by removing ".jpg" and replacing underscores with spaces
files_df <- files_df %>%
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

# Left join on species and videnskabeligt_navn
Final_Frequency <- Final_Frequency %>%
  left_join(matched, by = c("species" = "videnskabeligt_navn")) %>%
  rename(photo_file = Taxa) %>%
  distinct()

# Final_Frequency <- Final_Frequency_combined %>%
#   group_by(plot, year, Taxa) %>%
#   filter(!is.na(taxon_id_Arter) | row_number() == 1) %>%  # Keep non-NA taxon_id_Arter or the first row if all are NA
#   arrange(desc(!is.na(taxon_id_Arter))) %>%
#   slice(1) %>%  # Keep the first row within each group
#   ungroup() %>%  # Ungroup to return to the original data frame structure
#   distinct()

usethis::use_data(Final_Frequency, overwrite = TRUE)


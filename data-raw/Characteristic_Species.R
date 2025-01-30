## code to prepare `Characteristic_Species` dataset goes here

library(tidyverse)
library(readxl)

Characteristic_Species <- readxl::read_xlsx("data-raw/DFV_app_indicator_common_species.xlsx") |>
  tidyr::pivot_longer("1210":"91E0", names_to = "habtype", values_to = "characteristic") |>
  dplyr::filter(!is.na(characteristic)) |>
  dplyr::select(gbifid, videnskabeligt_navn, accepteret_dansk_navn, taxonrang, habtype, characteristic, taxon_id_Arter) |>
  dplyr::rename(Taxa = videnskabeligt_navn) #|>
#  dplyr::mutate(habtype = as.numeric(habtype))

Cleaned_Taxons <- SDMWorkflows::Clean_Taxa(Taxons = Characteristic_Species$Taxa, Species_Only = F)

Characteristic_Species <- Cleaned_Taxons |> dplyr::left_join(Characteristic_Species)



usethis::use_data(Characteristic_Species, overwrite = TRUE)

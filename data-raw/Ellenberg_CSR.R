## code to prepare `Ellenberg_CSR` dataset goes here
library(tidyverse)
library(readxl)

# Ellenberg_CSR <- readRDS("data-raw/CRS_Ellenberg_Dataset.rds")
Ellenberg_CSR <- read_xlsx("data-raw/CRS_Ellenberg_Dataset.xlsx") %>%
  select("ID_Arter", "Taxonrang", "Videnskabeligt_navn", "light", "moisture", "reaction", "nutrients", "salinity", "C", "S", "R", "Strategy")

# assign color base one strategy
Ellenberg_CSR <- Ellenberg_CSR %>% mutate(Red = (R/100)*255,
                                          Green = (C/100)*255,
                                          Blue = (S/100)*255)

color_key <- Ellenberg_CSR %>%
  select("ID_Arter", "Taxonrang", "Videnskabeligt_navn", "C", "S", "R",
         "Strategy", "Red", "Green", "Blue") %>%
  na.omit() %>%
  mutate(RGB = rgb(Red, Green, Blue, maxColorValue = 255))

Ellenberg_CSR <- Ellenberg_CSR %>% left_join(color_key)

usethis::use_data(Ellenberg_CSR, overwrite = TRUE)


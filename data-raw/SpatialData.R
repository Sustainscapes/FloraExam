## code to prepare `SpatialData` dataset goes here
library(terra)
library(tidyverse)
library(readxl)
library(Artscore)

Coords <- terra::vect("data-raw/Spatial.geojson") |>
    terra::geom() |>
    as.data.frame() |>
    dplyr::select(x, y)

NewHabs <- read_xlsx("data-raw/Habitat_types_DFV_v2.xlsx") |>
    dplyr::mutate(
        MajorHab = as.character(MajorHab),
        habtype = as.character(habtype)
    ) |>
    dplyr::rename(habitat_name = habtypeName) |>
    dplyr::select("habtype", "habitat_name", "MajorHab", "MajorHabName")

SpatialData <- terra::vect("data-raw/Spatial.geojson") |>
    as.data.frame() |>
    dplyr::bind_cols(Coords) |>
    dplyr::rename(
        Lat = y,
        Long = x
    ) |>
    # Match the major habitat type from the NewHabs data by matching the habtype
    dplyr::mutate(habtype = as.character(habtype)) |>
    left_join(NewHabs, by = "habtype") |>
    dplyr::select(
        "plot", "habtype", "MajorHab", "habitat_name", "MajorHabName", "Long", "Lat"
    ) |>
    dplyr::select(-habitat_name, -MajorHabName) |>
    dplyr::mutate(plot = as.character(plot), habtype = as.character(habtype)) |>
    dplyr::mutate(habtype = case_when(
        habtype == "9998" ~ "91D0",
        habtype == "9999" ~ "91E0",
        TRUE ~ habtype
    )) |>
    dplyr::mutate(MajorHab = case_when(
        habtype == "91D0" ~ "91",
        habtype == "91E0" ~ "91",
        TRUE ~ MajorHab
    )) |>
    left_join(NewHabs) |>
    dplyr::filter_all(~ !is.na(.x)) |>
    dplyr::select(
        "plot", "habtype", "MajorHab", "habitat_name", "MajorHabName", "Long", "Lat"
    )



Ellenberg_CSR <- readRDS("data-raw/CRS_Ellenberg_Dataset.rds")


Final_Frequency <- read_csv("data-raw/Final_Frequency.csv") |>
    dplyr::filter(!is.na(species)) |>
    dplyr::mutate(plot = as.character(plot))


SpatialData$Artsindeks <- as.numeric(rep(NA, nrow(SpatialData)))

for(i in 1:nrow(SpatialData)){
    Temp <- Final_Frequency |>
        dplyr::filter(plot == SpatialData$plot[i])
    Temp <- suppressMessages(full_join(Temp, SpatialData[i,]))
    try({
        suppressMessages(
            SpatialData$Artsindeks[i] <- Artscore::Artscore(
                ScientificName = Temp$species, 
                Habitat_code = unique(Temp$habtype)
            )$Artsindex
        )
    })
    if((i %% 100) == 0){
        message(paste(i, "of", nrow(SpatialData), "ready", Sys.time()))
    }
}

SpatialData <-SpatialData |>
    group_by(habitat_name) |>
    dplyr::mutate(
        median_arts = median(Artsindeks, na.rm = T),
        delta_arts = abs(Artsindeks - median_arts)
    ) |>
    ungroup()


SpatialDataMedian <- SpatialData |>
    group_by(habtype) |>
    slice_min(order_by = delta_arts, n = 50) |>
    ungroup()

SpatialDataMax <- SpatialData |>
    group_by(habtype) |>
    slice_max(order_by = Artsindeks, n = 5, na_rm = T) |>
    ungroup()

Plots <- SpatialDataMedian |>
    dplyr::left_join(Final_Frequency, multiple = "all") |>
    dplyr::left_join(
        Ellenberg_CSR, 
        multiple = "all", 
        relationship = "many-to-many"
    ) |>
    dplyr::filter(!is.na(habitat_name)) |>
    group_by(plot, habitat_name) |>
    dplyr::summarize(
        non_na_csr = sum(!is.na(C)),
        na_csr = sum(is.na(C))
    ) |>
    mutate(
        prop_csr = non_na_csr/(na_csr + non_na_csr),
        total_csr = na_csr + non_na_csr
    ) |>
    dplyr::filter(non_na_csr > 2) |>
    ungroup() |>
    group_by(habitat_name) |>
    dplyr::slice_max(order_by = total_csr, n = 30) |>
    dplyr::slice_max(order_by = non_na_csr, n = 20) |>
    pull(plot) |>
    unique()

Plots <- unique(c(Plots, SpatialDataMax$plot))

SpatialData <- SpatialData |>
    dplyr::filter(plot %in% Plots) |>
    dplyr::mutate(habitat_name = paste0(habitat_name, " (", habtype, ")")) |>
    dplyr::distinct()

Final_Frequency <- Final_Frequency |>
    dplyr::filter(plot %in% Plots) |>
    dplyr::distinct()

usethis::use_data(SpatialData, overwrite = TRUE)

usethis::use_data(Final_Frequency, overwrite = TRUE)

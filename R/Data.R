#' A subset of data from a sampled dataset with habitat types and plot code
#' of sampling.
#'
#' @format ## A data frame with 647 rows and 7 columns:
#' \describe{
#'   \item{plot}{Code for the plot}
#'   \item{habtype}{Code for habitat type}
#'   \item{MajorHab}{Code for the major habitat type}
#'   \item{habitat_name}{Name for the habitat type}
#'   \item{MajorHabName}{Name for the major habitat type}
#'   \item{Long}{Plot longitude}
#'   \item{Long}{Plot latitude}
#' }
#'
"SpatialData"

#' A subset of data from from a sampled dataset with the sampled species with added taxon_id_Arter and photo_file.
#'
#' @format A data frame with 615860 rows and 6 columns:
#' \describe{
#'   \item{Taxa}{name of the species subspecies or variety}
#'   \item{plot}{Code for the plot}
#'   \item{year}{The sampled year}
#'   \item{species}{name of the species, solved for synonyms}
#'   \item{taxon_id_Arter}{taxon_id for linking to Arter.dk}
#'   \item{photo_file}{file name for photos in folder inst/Pictures}
#' }

"Final_Frequency"

#' CSR values and Ellenberg values for different species
#'
#' @format A data frame with 2,827 rows and 36 columns:

"Ellenberg_CSR"


#' Characteristic species for different habitat types
#'
#' @format A data frame with 847 rows and 16 columns:

"Characteristic_Species"



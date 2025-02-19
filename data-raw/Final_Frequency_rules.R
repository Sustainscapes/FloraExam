# This script contains the rules by which species in the Final Frequency dataset
# are included or excluded.

# The exceptions and rules csv has three columns, Art_Latin, Grouping and Habtype
# The Art-Latin column contains the taxon of species to leave at whatever level
# described in the exceptions, everything else is to be left at species level
# Grouping column lists entries that should be grouped into a higher level
# Habtype contains entries that should only be shown in certian habitat types

# Load the exceptions and rules
exceptions <- read.csv("data-raw/exceptions_and_rules.csv")

# Get the rows where the Grouping is Cladonia and get the Art_Latin column
cladonia <- exceptions[exceptions$Grouping == "Cladonia", "Art_Latin"]
cladonia_codes <- exceptions[exceptions$Grouping == "Cladonia", "Habtype"] |>
    unique() |>
    as.character() |>
    strsplit("\\|") |>
    unlist()
# Same for the Sphagnum group
sphagnum <- exceptions[exceptions$Grouping == "Sphagnum", "Art_Latin"]
sphagnum_codes <- exceptions[exceptions$Grouping == "Sphagnum", "Habtype"] |>
    unique() |>
    as.character() |>
    strsplit("\\|") |>
    unlist()

apply_rules <- function(x) {
    split_name <- strsplit(x, " ")[[1]]
    # If the species is not in the exceptions list but is not a species,
    # drop if it is higher than species, or make it at species level
    # First check if it the species name needs to be grouped
    if (x %in% cladonia) {
        return("Cladonia")
    } else if (x %in% sphagnum) {
        return("Sphagnum")
    } else if (x %in% exceptions$Art_Latin) {
        return(x)
    } else if (length(split_name) < 2) { # If at genus level, drop
        return(NA)
    } else if (length(split_name) > 2) { # If below species level, keep only species
        return(paste(split_name[1], split_name[2], sep = " "))
    } else {
        return(x)
    }
}


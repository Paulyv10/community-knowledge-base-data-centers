# =============================================================================
# global.R — Shared data loading and constants
# Runs once on app startup, available to both ui.R and server.R
# =============================================================================

library(shiny)
library(bslib)
library(tidyverse)
library(sf)
library(leaflet)
library(ggplot2)

# -----------------------------------------------------------------------------
# Constants — NNG: match between system and real world
# Use plain language labels everywhere, never raw column names
# -----------------------------------------------------------------------------

IMPACT_LABELS <- c(
  "noise"       = "Noise & Vibration",
  "water"       = "Water Quality",
  "air_quality" = "Air Quality",
  "zoning"      = "Zoning & Land Use",
  "health"      = "Health Concerns",
  "energy"      = "Energy & Grid"
)

IMPACT_COLORS <- c(
  "noise"       = "#E69F00",
  "water"       = "#56B4E9",
  "air_quality" = "#009E73",
  "zoning"      = "#CC79A7",
  "health"      = "#D55E00",
  "energy"      = "#0072B2"
)
# ^ Wong (2011) colorblind-safe palette — R4DS best practice

SOURCE_LABELS <- c(
  "news"                = "News Article",
  "zba"                 = "ZBA Meeting Minutes",
  "community_submission"= "Community Report"
)

# -----------------------------------------------------------------------------
# Load processed spatial data
# Gracefully returns NULL with message if file missing — NNG: error prevention
# -----------------------------------------------------------------------------

load_gpkg <- function(path) {
  if (!file.exists(path)) {
    message("Layer not found: ", path)
    return(NULL)
  }
  st_read(path, quiet = TRUE)
}

burden_tracts  <- load_gpkg("../data/processed/burden_index_tracts.gpkg")
tompkins_county <- load_gpkg("../data/processed/tompkins_county.gpkg")
terrawulf_sf   <- load_gpkg("../data/processed/terrawulf_point.gpkg")

# Testimony — loaded from CSV, may not exist yet
testimony_data <- {
  path <- "../data/processed/testimony_classified.csv"
  if (file.exists(path)) {
    read_csv(path, show_col_types = FALSE) |>
      filter(!is.na(lon), !is.na(lat)) |>
      st_as_sf(coords = c("lon", "lat"), crs = 4326)
  } else {
    NULL
  }
}

# -----------------------------------------------------------------------------
# Leaflet color palettes (defined here so server + ui both see them)
# -----------------------------------------------------------------------------

burden_pal <- if (!is.null(burden_tracts)) {
  colorNumeric("YlOrRd", domain = burden_tracts$burden_score, na.color = "#e0e0e0")
} else NULL

testimony_pal <- colorFactor(
  palette = unname(IMPACT_COLORS),
  levels  = names(IMPACT_COLORS)
)

# -----------------------------------------------------------------------------
# Data freshness — NNG: visibility of system status
# -----------------------------------------------------------------------------

DATA_UPDATED <- format(Sys.Date(), "%B %d, %Y")

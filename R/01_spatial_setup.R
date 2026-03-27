# =============================================================================
# 01 — Spatial Setup
# Base geography: Tompkins County census tracts, facility location, Cayuga Lake
# =============================================================================

library(tidyverse)
library(sf)
library(tigris)
library(tidycensus)
library(leaflet)

options(tigris_use_cache = TRUE)

# Requires CENSUS_API_KEY in .Renviron
# Run once: tidycensus::census_api_key("YOUR_KEY", install = TRUE)

# -----------------------------------------------------------------------------
# Study area: Tompkins County, NY
# -----------------------------------------------------------------------------

TOMPKINS_FIPS  <- "36109"
TERRAWULF_COORDS <- c(lon = -76.5419, lat = 42.5453)
TARGET_CRS_WEB  <- 4326   # WGS84 — for leaflet / web output
TARGET_CRS_AREA <- 5070   # Albers Equal Area — for area calculations

# County boundary
tompkins_county <- counties(state = "NY", cb = TRUE) |>
  filter(GEOID == TOMPKINS_FIPS) |>
  st_transform(TARGET_CRS_WEB)

# Census tracts — Tompkins County
tompkins_tracts <- tracts(state = "NY", county = "Tompkins", cb = TRUE) |>
  st_transform(TARGET_CRS_WEB)

# TeraWulf facility point
terrawulf_sf <- tibble(
  name = "TeraWulf Nautilus Cryptomine",
  lon  = TERRAWULF_COORDS["lon"],
  lat  = TERRAWULF_COORDS["lat"]
) |>
  st_as_sf(coords = c("lon", "lat"), crs = TARGET_CRS_WEB)

# TODO: Add Cayuga Lake shoreline (from tigris::water_bodies or NHD)
# TODO: Add surrounding county boundaries for regional context

# -----------------------------------------------------------------------------
# Quick visual check
# -----------------------------------------------------------------------------

leaflet() |>
  addProviderTiles("CartoDB.Positron") |>
  addPolygons(data = tompkins_tracts, color = "#444", weight = 0.5,
              fillOpacity = 0.05, label = ~NAMELSAD) |>
  addCircleMarkers(data = terrawulf_sf, color = "red", radius = 8,
                   label = ~name)

# -----------------------------------------------------------------------------
# Save base layers
# -----------------------------------------------------------------------------

st_write(tompkins_tracts,  "data/processed/tompkins_tracts.gpkg",   delete_layer = TRUE)
st_write(tompkins_county,  "data/processed/tompkins_county.gpkg",   delete_layer = TRUE)
st_write(terrawulf_sf,     "data/processed/terrawulf_point.gpkg",   delete_layer = TRUE)

cat("Base spatial layers saved to data/processed/\n")

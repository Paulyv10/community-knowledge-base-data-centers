# =============================================================================
# 05 — Map Layer Preparation
# Assembles all processed data layers into a unified leaflet map
# This feeds into the summer community dashboard
# =============================================================================

library(tidyverse)
library(sf)
library(leaflet)
library(leaflet.extras)

TARGET_CRS_WEB <- 4326

# -----------------------------------------------------------------------------
# Load processed layers (run scripts 01-04 first)
# -----------------------------------------------------------------------------

load_layer <- function(path, layer = NULL) {
  if (!file.exists(path)) {
    message("Layer not found: ", path, " — run earlier pipeline scripts first")
    return(NULL)
  }
  if (is.null(layer)) st_read(path, quiet = TRUE) else st_read(path, layer = layer, quiet = TRUE)
}

tracts         <- load_layer("data/processed/tompkins_tracts.gpkg")
county         <- load_layer("data/processed/tompkins_county.gpkg")
terrawulf      <- load_layer("data/processed/terrawulf_point.gpkg")
burden_index   <- load_layer("data/processed/burden_index_tracts.gpkg")
# testimony    <- load_layer("data/processed/testimony_classified.csv")  # CSV, not gpkg
# zba          <- load_layer("data/processed/zba_testimony.csv")

# -----------------------------------------------------------------------------
# Color palettes
# -----------------------------------------------------------------------------

burden_pal <- colorNumeric("YlOrRd", domain = burden_index$burden_score, na.color = "#cccccc")

category_pal <- colorFactor(
  palette = c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00"),
  levels  = c("noise", "water", "air_quality", "zoning", "health")
)

# -----------------------------------------------------------------------------
# Base map
# -----------------------------------------------------------------------------

base_map <- leaflet() |>
  addProviderTiles("CartoDB.Positron", group = "Basemap") |>
  addProviderTiles("Esri.WorldImagery", group = "Satellite") |>
  setView(lng = -76.55, lat = 42.55, zoom = 11)

# -----------------------------------------------------------------------------
# Layer: Environmental Burden Index
# -----------------------------------------------------------------------------

if (!is.null(burden_index)) {
  base_map <- base_map |>
    addPolygons(
      data        = burden_index,
      fillColor   = ~burden_pal(burden_score),
      fillOpacity = 0.6,
      color       = "white",
      weight      = 0.5,
      group       = "Burden Index",
      label       = ~paste0(NAMELSAD, "<br>Burden score: ", round(burden_score, 2)) |>
                      lapply(htmltools::HTML),
      popup       = ~paste0(
        "<b>", NAMELSAD, "</b><br>",
        "Burden score: ", round(burden_score, 2), "<br>",
        "% Poverty: ", round(pct_poverty, 1), "%<br>",
        "% Non-white: ", round(pct_nonwhite, 1), "%"
      )
    ) |>
    addLegend(
      pal      = burden_pal,
      values   = burden_index$burden_score,
      title    = "Cumulative<br>Burden Score",
      position = "bottomright",
      group    = "Burden Index"
    )
}

# -----------------------------------------------------------------------------
# Layer: TeraWulf facility
# -----------------------------------------------------------------------------

if (!is.null(terrawulf)) {
  base_map <- base_map |>
    addCircleMarkers(
      data   = terrawulf,
      color  = "black",
      fillColor = "red",
      fillOpacity = 0.9,
      radius = 10,
      weight = 2,
      group  = "Facility",
      label  = ~name,
      popup  = ~paste0("<b>", name, "</b><br>TeraWulf Bitcoin mining facility<br>Capacity: ~50 MW")
    )
}

# -----------------------------------------------------------------------------
# Layer: Testimony points (uncomment when testimony_classified is ready)
# -----------------------------------------------------------------------------

# if (!is.null(testimony) && "lon" %in% names(testimony)) {
#   testimony_sf <- testimony |>
#     filter(!is.na(lon), !is.na(lat)) |>
#     st_as_sf(coords = c("lon", "lat"), crs = TARGET_CRS_WEB)
#
#   base_map <- base_map |>
#     addCircleMarkers(
#       data        = testimony_sf,
#       color       = ~category_pal(primary_category),
#       radius      = 6,
#       fillOpacity = 0.8,
#       group       = "Testimony",
#       popup       = ~paste0("<b>", type, "</b><br>", text)
#     ) |>
#     addLegend(
#       pal    = category_pal,
#       values = testimony_sf$primary_category,
#       title  = "Impact Type",
#       group  = "Testimony"
#     )
# }

# -----------------------------------------------------------------------------
# Layer controls
# -----------------------------------------------------------------------------

base_map <- base_map |>
  addLayersControl(
    baseGroups    = c("Basemap", "Satellite"),
    overlayGroups = c("Burden Index", "Facility", "Testimony"),
    options       = layersControlOptions(collapsed = FALSE)
  )

# Display
base_map

# =============================================================================
# 02 — Environmental Burden Index
# Joins ACS, CDC SVI, and PLACES data at census tract level for Tompkins County
# Produces a composite EJ burden score for each tract
# =============================================================================

library(tidyverse)
library(sf)
library(tidycensus)

TARGET_CRS_WEB <- 4326

# -----------------------------------------------------------------------------
# ACS variables — demographic and economic indicators
# -----------------------------------------------------------------------------

acs_vars <- c(
  total_pop      = "B01003_001",
  median_income  = "B19013_001",
  white_pop      = "B02001_002",
  black_pop      = "B02001_003",
  hispanic_pop   = "B03002_012",
  poverty_total  = "B17001_001",
  poverty_below  = "B17001_002",
  no_hs_total    = "B15003_001",
  no_hs_below    = "B15003_002",   # TODO: sum all pre-HS diploma categories
  renter_total   = "B25003_001",
  renter_occ     = "B25003_003"
)

acs_tracts <- get_acs(
  geography = "tract",
  variables = acs_vars,
  state     = "NY",
  county    = "Tompkins",
  year      = 2022,
  geometry  = TRUE,
  output    = "wide"
) |>
  st_transform(TARGET_CRS_WEB) |>
  mutate(
    pct_nonwhite = 100 * (1 - (white_popE / total_popE)),
    pct_poverty  = 100 * (poverty_belowE / poverty_totalE),
    pct_renter   = 100 * (renter_occE / renter_totalE)
  ) |>
  mutate(across(starts_with("pct_"), \(x) ifelse(is.nan(x) | is.infinite(x), NA, x)))

# -----------------------------------------------------------------------------
# CDC SVI — Social Vulnerability Index
# Download from: https://www.atsdr.cdc.gov/placeandhealth/svi/data_documentation_download.html
# Save to: data/raw/svi_ny_2022.csv
# -----------------------------------------------------------------------------

# TODO: Uncomment when SVI CSV is downloaded
# svi_raw <- read_csv("data/raw/svi_ny_2022.csv") |>
#   filter(COUNTY == "Tompkins") |>
#   select(FIPS, RPL_THEMES, RPL_THEME1, RPL_THEME2, RPL_THEME3, RPL_THEME4)
#
# acs_tracts <- acs_tracts |>
#   left_join(svi_raw, by = c("GEOID" = "FIPS"))

# -----------------------------------------------------------------------------
# CDC PLACES — Local health outcomes
# Download from: https://chronicdata.cdc.gov/500-Cities-Places/
# Save to: data/raw/places_ny_2023.csv
# -----------------------------------------------------------------------------

# TODO: Uncomment when PLACES CSV is downloaded
# places_raw <- read_csv("data/raw/places_ny_2023.csv") |>
#   filter(StateAbbr == "NY", CountyName == "Tompkins") |>
#   select(LocationID, CASTHMA_CrudePrev, COPD_CrudePrev, CHD_CrudePrev,
#          DIABETES_CrudePrev, OBESITY_CrudePrev, SLEEP_CrudePrev)
#
# acs_tracts <- acs_tracts |>
#   left_join(places_raw, by = c("GEOID" = "LocationID"))

# -----------------------------------------------------------------------------
# Composite burden score (percentile rank approach)
# Higher score = greater cumulative burden
# -----------------------------------------------------------------------------

burden_tracts <- acs_tracts |>
  mutate(
    rank_poverty   = percent_rank(pct_poverty),
    rank_nonwhite  = percent_rank(pct_nonwhite),
    rank_renter    = percent_rank(pct_renter),
    # TODO: add rank_svi and rank_health_outcomes once those sources are joined
    burden_score   = rowMeans(pick(starts_with("rank_")), na.rm = TRUE)
  )

# Save
st_write(burden_tracts, "data/processed/burden_index_tracts.gpkg", delete_layer = TRUE)
cat("Burden index saved to data/processed/burden_index_tracts.gpkg\n")
cat("Tracts scored:", nrow(burden_tracts), "\n")

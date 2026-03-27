# =============================================================================
# 03 — Testimony Ingest & NLP Pipeline
# Classifies community testimony and news articles by impact type and extracts
# location mentions for geocoding. Designed to ingest Mikko's scraper output.
# =============================================================================
#
# Input schema (coordinate with Mikko before finalizing):
#   - text:       full article or testimony text
#   - source:     URL or document reference
#   - date:       publication or submission date
#   - type:       "news" | "testimony" | "zba" | "community_submission"
#
# Output:
#   - data/processed/testimony_classified.csv  — classified + geocoded records
# =============================================================================

library(tidyverse)
library(tidytext)
library(sf)

# -----------------------------------------------------------------------------
# Impact category keywords
# Expand these based on what emerges in the corpus
# -----------------------------------------------------------------------------

impact_keywords <- tribble(
  ~word,          ~category,
  "noise",        "noise",
  "loud",         "noise",
  "sound",        "noise",
  "vibration",    "noise",
  "hum",          "noise",
  "water",        "water",
  "lake",         "water",
  "thermal",      "water",
  "discharge",    "water",
  "cooling",      "water",
  "temperature",  "water",
  "air",          "air_quality",
  "emissions",    "air_quality",
  "pollution",    "air_quality",
  "dust",         "air_quality",
  "zoning",       "zoning",
  "permit",       "zoning",
  "variance",     "zoning",
  "ordinance",    "zoning",
  "health",       "health",
  "asthma",       "health",
  "headache",     "health",
  "sleep",        "health",
  "stress",       "health",
  "electricity",  "energy",
  "grid",         "energy",
  "power",        "energy",
  "rate",         "energy"
)

# -----------------------------------------------------------------------------
# Classify a testimony dataframe
# Returns original df with added `primary_category` and `category_scores` cols
# -----------------------------------------------------------------------------

classify_testimony <- function(df, text_col = "text", id_col = "id") {
  df |>
    unnest_tokens(word, {{ text_col }}) |>
    anti_join(stop_words, by = "word") |>
    inner_join(impact_keywords, by = "word") |>
    count({{ id_col }}, category) |>
    group_by({{ id_col }}) |>
    slice_max(n, n = 1, with_ties = FALSE) |>
    rename(primary_category = category, category_score = n) |>
    right_join(df, by = as_label(enquo(id_col)))
}

# -----------------------------------------------------------------------------
# Location extraction — placeholder for NER
# TODO: replace with a proper NER approach (e.g., spacyr or entity dictionary)
# -----------------------------------------------------------------------------

# Known Lansing/Tompkins place names to scan for
place_dictionary <- c(
  "Lansing", "Cayuga Lake", "Tompkins", "Ithaca", "Ludlowville",
  "Myers Park", "Salmon Creek", "Milliken Station", "Lake Ridge"
)

extract_locations <- function(text_vec) {
  # Returns a list of matched place names for each text element
  map(text_vec, \(txt) {
    found <- place_dictionary[str_detect(txt, fixed(place_dictionary, ignore_case = TRUE))]
    if (length(found) == 0) NA_character_ else paste(found, collapse = "; ")
  }) |> unlist()
}

# -----------------------------------------------------------------------------
# Main pipeline — run when Mikko's scraper output is available
# -----------------------------------------------------------------------------

# TODO: Replace with actual input path once schema is confirmed
# raw_testimony <- read_csv("data/raw/testimony_raw.csv")
#
# classified <- raw_testimony |>
#   mutate(
#     id = row_number(),
#     location_mentions = extract_locations(text)
#   ) |>
#   classify_testimony(text_col = text, id_col = id)
#
# write_csv(classified, "data/processed/testimony_classified.csv")
# cat("Classified", nrow(classified), "records\n")
# cat("Category breakdown:\n")
# print(count(classified, primary_category, sort = TRUE))

cat("03_testimony_ingest.R loaded — pipeline ready.\n")
cat("Waiting on Mikko's scraper output schema before running.\n")

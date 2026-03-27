# =============================================================================
# 04 — ZBA Meeting Minutes Extraction
# Extracts and structures testimony from Lansing Town ZBA/Planning Board PDFs
# Source: https://www.lansingtown.com/minutes (public records)
# =============================================================================

library(tidyverse)
library(pdftools)
library(tidytext)

# Place PDFs in data/raw/zba/
ZBA_DIR <- "data/raw/zba"

# -----------------------------------------------------------------------------
# Extract text from all PDFs in the ZBA directory
# -----------------------------------------------------------------------------

extract_zba_pdfs <- function(dir = ZBA_DIR) {
  pdf_files <- list.files(dir, pattern = "\\.pdf$", full.names = TRUE)

  if (length(pdf_files) == 0) {
    message("No PDFs found in ", dir, " — download minutes from lansingtown.com")
    return(tibble())
  }

  map_dfr(pdf_files, \(path) {
    text_pages <- pdf_text(path)
    tibble(
      source_file = basename(path),
      page        = seq_along(text_pages),
      text        = text_pages
    )
  })
}

# -----------------------------------------------------------------------------
# Parse meeting date from filename
# Assumes filenames like: "2024-03-12_ZBA_minutes.pdf"
# Adjust regex if Lansing uses a different naming convention
# -----------------------------------------------------------------------------

parse_meeting_date <- function(filename) {
  date_str <- str_extract(filename, "\\d{4}-\\d{2}-\\d{2}")
  if (is.na(date_str)) {
    date_str <- str_extract(filename, "\\d{8}")
    if (!is.na(date_str)) {
      date_str <- paste0(
        substr(date_str, 1, 4), "-",
        substr(date_str, 5, 6), "-",
        substr(date_str, 7, 8)
      )
    }
  }
  as.Date(date_str)
}

# -----------------------------------------------------------------------------
# Split pages into individual speaker blocks / agenda items
# This is heuristic — will need tuning once we have real PDFs
# -----------------------------------------------------------------------------

split_into_segments <- function(page_text) {
  # Split on common minute-formatting patterns
  segments <- str_split(page_text, "\n{2,}|(?=\\bMR\\.|\\bMS\\.|\\bMRS\\.|\\bCHAIR)")[[1]]
  segments[nchar(trimws(segments)) > 30]  # drop very short fragments
}

# -----------------------------------------------------------------------------
# Main extraction pipeline
# -----------------------------------------------------------------------------

# zba_raw <- extract_zba_pdfs()
#
# if (nrow(zba_raw) > 0) {
#   zba_structured <- zba_raw |>
#     mutate(
#       meeting_date = parse_meeting_date(source_file),
#       text         = str_squish(text)
#     ) |>
#     filter(str_detect(str_to_lower(text), "terrawulf|data center|bitcoin|mining|noise|water")) |>
#     mutate(
#       segments = map(text, split_into_segments)
#     ) |>
#     unnest(segments) |>
#     rename(text = segments) |>
#     mutate(id = row_number(), type = "zba")
#
#   write_csv(zba_structured, "data/processed/zba_testimony.csv")
#   cat("Extracted", nrow(zba_structured), "ZBA segments\n")
# }

cat("04_zba_extraction.R loaded.\n")
cat("Next step: download PDFs from lansingtown.com into data/raw/zba/\n")

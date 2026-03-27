# Community Knowledge Base — Data Centers

A participatory GIS and environmental justice data infrastructure project tracking community-reported impacts of data center development, starting with the TeraWulf facility near Lansing, NY (Cayuga Lake).

This repository scaffolds the spatial data pipeline, NLP testimony processing, and environmental burden analysis that will feed into a community-facing dashboard. It is part of an interdisciplinary lab effort combining sensor data, satellite remote sensing, community testimony, and civic records.

---

## Project Goals

- Build a geospatially-referenced knowledge base of community testimony, news coverage, and civic records (e.g., ZBA meeting minutes) related to data center impacts
- Develop an NLP pipeline to extract location mentions and classify impacts by type (noise, water, air quality, zoning, health)
- Construct a cumulative environmental burden index for Tompkins County combining ACS/Census, CDC SVI, PLACES, and lab sensor data
- Create a participatory data collection framework where community members can submit geo-tagged observations
- Provide a clean, structured spatial data schema for downstream integration into the summer community dashboard

---

## Focus Area

**TeraWulf Bitcoin Mining Facility — Lansing, NY / Cayuga Lake region**

Key environmental concerns being tracked:
- Thermal discharge into Cayuga Lake (cooling water)
- Air quality and noise impacts on surrounding neighborhoods
- Zoning and land use changes
- Community health outcomes over time

---

## Data Sources

| Source | Type | Notes |
|---|---|---|
| U.S. Census / ACS | Demographic | Via `tidycensus` |
| CDC SVI & PLACES | Health / Vulnerability | Census tract level |
| Tompkins County ZBA Minutes | Civic testimony | Public PDFs |
| News & media scrapes | Community testimony | NLP processing pipeline |
| PurpleAir | Air quality sensors | Community sensor network |
| Landsat / Sentinel-2 | Satellite imagery | Thermal & land cover change |
| Lab acoustic sensors | Sound monitoring | Goose sensor deployment |

---

## Tech Stack

- **Language:** R
- **Spatial:** `sf`, `terra`, `tigris`, `tidycensus`, `leaflet`
- **NLP / Text:** `tidytext`, `pdftools`, entity extraction
- **Modeling:** `tidymodels`
- **Dashboard (planned):** `shiny`
- **Workflow:** `renv` for reproducibility, `quarto` for reporting

---

## Repository Structure

```
community-knowledge-base-data-centers/
├── R/                     # Analysis and pipeline scripts
│   ├── 01_spatial_setup.R       # Base map, census geographies
│   ├── 02_burden_index.R        # Environmental burden index (ACS/SVI/PLACES)
│   ├── 03_testimony_ingest.R    # NLP pipeline for testimony/news data
│   ├── 04_zba_extraction.R      # PDF extraction from ZBA meeting minutes
│   └── 05_map_layers.R          # Layer preparation for dashboard
├── data/
│   ├── raw/               # Unprocessed source files
│   └── processed/         # Cleaned, geocoded, classified outputs
├── reports/               # Quarto documents and analysis outputs
├── shiny/                 # Participatory data collection app (planned)
├── CLAUDE.md              # Claude Code project instructions
├── renv.lock              # R dependency lockfile
└── README.md
```

---

## Getting Started

```r
# Restore R dependencies
renv::restore()

# Required environment variables
# Add to your .Renviron:
# CENSUS_API_KEY=your_key_here

# Pull base spatial data for Tompkins County
source("R/01_spatial_setup.R")
```

---

## Lab Context

This project is part of a broader community environmental monitoring initiative. Related workstreams include:

- **Acoustic monitoring** — ML-based analysis of sound data from deployed sensors
- **Satellite thermal analysis** — Water surface temperature change detection in Cayuga Lake
- **Community dashboard** — Summer project integrating all data layers into a public-facing interface

This repository focuses on the **participatory and civic data layer** — structured collection, classification, and geolocation of community knowledge that gives residents an evidence base for zoning, regulatory, and public health engagement.

---

## Contributing

This is an active research project. If you are a lab member working on testimony data, sensor outputs, or satellite layers, please open an issue or reach out before making structural changes to the data schema — the goal is a shared spatial infrastructure that all workstreams can plug into.

---

## License

MIT

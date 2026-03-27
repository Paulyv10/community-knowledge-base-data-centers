# Community Knowledge Base — Data Centers

## Purpose
Participatory GIS and environmental justice data infrastructure for mapping community
testimony and environmental burden around data centers. Primary focus: TeraWulf Bitcoin
mining facility near Lansing, NY / Cayuga Lake (Tompkins County).

This project feeds into a community-facing dashboard (summer build). Our lane is the
civic and participatory data layer — structured collection, NLP classification, and
geolocation of community knowledge.

## Tech Stack
- R (tidyverse, sf, tidytext, tidymodels, leaflet, shiny)
- Spatial: sf, terra, tigris, tidycensus — always use sf, never sp
- Text: tidytext, pdftools, entity extraction
- Reporting: quarto
- Dependency management: renv

## Key Geography
- Primary: Tompkins County, NY (FIPS: 36109)
- Facility: TeraWulf Nautilus — approx. 42.5453, -76.5419
- Water body: Cayuga Lake
- Use EPSG:4326 for web/leaflet, EPSG:5070 (Albers) for area calculations

## Pipeline Order
1. `R/01_spatial_setup.R`     — base geography, census tracts, facility location
2. `R/02_burden_index.R`      — ACS + SVI + PLACES environmental burden score
3. `R/03_testimony_ingest.R`  — NLP pipeline for news/testimony classification
4. `R/04_zba_extraction.R`    — PDF extraction from Lansing ZBA meeting minutes
5. `R/05_map_layers.R`        — Layer prep for dashboard integration

## Commands
- `Rscript -e "renv::restore()"` — restore dependencies
- `quarto render reports/` — render analysis reports

## Environment Variables
CENSUS_API_KEY must be set in .Renviron for tidycensus to work.

## Style
- Pipe with |> (base R pipe)
- tidyverse conventions throughout
- sf objects for all spatial data
- Comment non-obvious spatial operations
- Use snake_case for all variable and function names

## Common Mistakes to Avoid
- Never use sp package — always sf
- tidycensus requires CENSUS_API_KEY in .Renviron
- ZBA minutes are PDFs — use pdftools for extraction, not readLines
- st_transform before any spatial joins — confirm CRS match first
- Don't hardcode file paths — use here::here() or relative paths from project root

## Lab Context
- Mikko: news/testimony scraper (coordinate on output schema)
- Laura: participatory design and ontology decisions
- Saarang: audio ML / acoustic monitoring (separate workstream)
- Summer: full community dashboard integrating all layers
- This repo is the data infrastructure that feeds the dashboard

## Data Sources
- ACS/Census: via tidycensus
- CDC SVI & PLACES: downloaded to data/raw/
- ZBA minutes: public PDFs from Lansing town website
- News scrapes: from Mikko (coordinate on format before ingesting)
- PurpleAir: community sensor network (API or download)
- Landsat/Sentinel-2: via Google Earth Engine or terra

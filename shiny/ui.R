# =============================================================================
# ui.R — Dashboard layout
#
# NNG principles applied:
#   1. Visibility of system status     — loading spinners, data freshness
#   2. Match system to real world      — plain language, no raw column names
#   3. User control & freedom          — reset filters button
#   4. Consistency & standards         — same colors in map, charts, legend
#   5. Recognition over recall         — persistent legend, always-visible labels
#   6. Aesthetic & minimalist design   — progressive disclosure via nav panels
#   7. Accessibility                   — colorblind-safe palette, WCAG contrast
#
# R4DS viz conventions:
#   - theme_minimal() throughout
#   - Meaningful color only (Wong colorblind-safe palette)
#   - Direct labels where space allows
#   - No decorative chart elements
# =============================================================================

ui <- page_navbar(
  title = "Cayuga Lake Data Center Monitor",
  theme = bs_theme(
    bootswatch  = "flatly",
    primary     = "#2C3E50",
    base_font   = font_google("Inter"),
    code_font   = font_google("Fira Code"),
    font_scale  = 0.95
  ),
  bg = "#2C3E50",
  inverse = TRUE,

  # ---------------------------------------------------------------------------
  # NAV: Map — primary view
  # NNG: most important content first; map is the core affordance
  # ---------------------------------------------------------------------------
  nav_panel(
    title = "Map",
    icon  = icon("map"),

    layout_sidebar(
      # --- Sidebar: filters and layer controls ---
      sidebar = sidebar(
        width = 280,
        open  = "open",

        # Context — NNG: match system to real world
        p(class = "text-muted small",
          "Monitoring environmental impacts of the TeraWulf Bitcoin mining facility,",
          "Lansing, NY."
        ),
        hr(),

        # Layer toggles — NNG: user control, recognition over recall
        strong("Map Layers"),
        checkboxInput("layer_burden",    "Environmental Burden Index", value = TRUE),
        checkboxInput("layer_facility",  "TeraWulf Facility",          value = TRUE),
        checkboxInput("layer_testimony", "Community Reports",          value = TRUE),
        hr(),

        # Impact type filter — NNG: consistency (same colors as map markers)
        strong("Filter by Impact Type"),
        checkboxGroupInput(
          inputId  = "filter_impact",
          label    = NULL,
          choices  = setNames(names(IMPACT_LABELS), IMPACT_LABELS),
          selected = names(IMPACT_LABELS)
        ),
        hr(),

        # Source type filter
        strong("Filter by Source"),
        checkboxGroupInput(
          inputId  = "filter_source",
          label    = NULL,
          choices  = setNames(names(SOURCE_LABELS), SOURCE_LABELS),
          selected = names(SOURCE_LABELS)
        ),
        hr(),

        # Reset — NNG: user control and freedom
        actionButton("reset_filters", "Reset Filters",
                     icon = icon("rotate-left"),
                     class = "btn-outline-secondary btn-sm w-100"),

        hr(),
        # Data freshness — NNG: visibility of system status
        p(class = "text-muted small",
          icon("circle-info"), " Data updated:", DATA_UPDATED)
      ),

      # --- Main panel: map ---
      card(
        full_screen = TRUE,
        card_header(
          "Community Environmental Map",
          # Report count badge — NNG: visibility of system status
          span(class = "ms-2",
               textOutput("report_count", inline = TRUE))
        ),
        leafletOutput("main_map", height = "600px"),
        card_footer(
          class = "text-muted small",
          "Click any marker to read the community report. Click any tract to see its burden score."
        )
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # NAV: Analysis — charts and EJ statistics
  # NNG: progressive disclosure — don't show everything on the map screen
  # ---------------------------------------------------------------------------
  nav_panel(
    title = "Analysis",
    icon  = icon("chart-bar"),

    layout_columns(
      col_widths = c(6, 6, 12),

      # Impact breakdown — R4DS: bar chart, direct labels, meaningful color
      card(
        card_header("Community Reports by Impact Type"),
        plotOutput("chart_impact_types", height = "300px"),
        card_footer(class = "text-muted small",
                    "Based on classified testimony and news coverage.")
      ),

      # Source breakdown
      card(
        card_header("Reports by Source"),
        plotOutput("chart_source_types", height = "300px"),
        card_footer(class = "text-muted small",
                    "ZBA = Zoning Board of Appeals meeting minutes.")
      ),

      # Burden index distribution — R4DS: histogram, theme_minimal
      card(
        card_header("Environmental Burden Score Distribution — Tompkins County Tracts"),
        plotOutput("chart_burden_dist", height = "280px"),
        card_footer(class = "text-muted small",
                    "Score combines poverty rate, % non-white, and renter rate (percentile ranked). ",
                    "Higher = greater cumulative burden. SVI and health outcomes to be added.")
      )
    )
  ),

  # ---------------------------------------------------------------------------
  # NAV: Reports — browsable testimony table
  # NNG: recognition over recall — full text accessible without leaving app
  # ---------------------------------------------------------------------------
  nav_panel(
    title = "Reports",
    icon  = icon("file-lines"),

    card(
      card_header(
        "Community Reports & Testimony",
        # Download — NNG: user control
        downloadButton("download_reports", "Download CSV",
                       class = "btn-sm btn-outline-secondary ms-auto")
      ),
      # Search — NNG: flexibility and efficiency
      textInput("search_reports", label = NULL,
                placeholder = "Search reports...",
                width = "100%"),
      DT::dataTableOutput("testimony_table")
    )
  ),

  # ---------------------------------------------------------------------------
  # NAV: About
  # ---------------------------------------------------------------------------
  nav_panel(
    title = "About",
    icon  = icon("circle-info"),

    layout_columns(
      col_widths = c(8, 4),

      card(
        card_header("About This Project"),
        card_body(
          h5("What is this?"),
          p("This dashboard maps community-reported environmental impacts of the",
            strong("TeraWulf Nautilus Bitcoin mining facility"), "near Lansing, NY,",
            "which draws cooling water from Cayuga Lake."),
          h5("What data is shown?"),
          tags$ul(
            tags$li(strong("Environmental Burden Index:"),
                    "Census tract-level composite of poverty, race, and housing
                    vulnerability (ACS 2022). CDC Social Vulnerability Index and
                    local health outcomes will be added."),
            tags$li(strong("Community Reports:"),
                    "Testimony from ZBA/planning board meetings, news coverage,
                    and direct community submissions — classified by impact type."),
            tags$li(strong("Facility Location:"),
                    "TeraWulf Nautilus Cryptomine, Lansing, NY (~50 MW capacity).")
          ),
          h5("Who made this?"),
          p("Built by the Community Environmental Monitoring Lab as part of a",
            "participatory GIS initiative. This is a living dataset —",
            "data and methodology will be updated as the project develops."),
          h5("How do I submit a report?"),
          p("Community submission form coming soon.")
        )
      ),

      card(
        card_header("Data Sources"),
        card_body(
          tags$dl(
            tags$dt("U.S. Census / ACS"),
            tags$dd("2018–2022 5-year estimates via tidycensus"),
            tags$dt("CDC Social Vulnerability Index"),
            tags$dd("2022, census tract level — coming soon"),
            tags$dt("CDC PLACES"),
            tags$dd("Local health outcomes — coming soon"),
            tags$dt("ZBA Meeting Minutes"),
            tags$dd("Lansing Town public records"),
            tags$dt("News & Media"),
            tags$dd("Scraped and classified coverage"),
            tags$dt("PurpleAir"),
            tags$dd("Community air quality sensors — coming soon")
          )
        )
      )
    )
  ),

  # Footer spacer
  nav_spacer(),
  nav_item(
    tags$span(class = "navbar-text text-white-50 small",
              "Cayuga Lake Community Monitor")
  )
)

# =============================================================================
# server.R — Reactive logic
# =============================================================================

server <- function(input, output, session) {

  # ---------------------------------------------------------------------------
  # Reset filters — NNG: user control and freedom
  # ---------------------------------------------------------------------------

  observeEvent(input$reset_filters, {
    updateCheckboxInput(session,  "layer_burden",    value = TRUE)
    updateCheckboxInput(session,  "layer_facility",  value = TRUE)
    updateCheckboxInput(session,  "layer_testimony", value = TRUE)
    updateCheckboxGroupInput(session, "filter_impact", selected = names(IMPACT_LABELS))
    updateCheckboxGroupInput(session, "filter_source", selected = names(SOURCE_LABELS))
  })

  # ---------------------------------------------------------------------------
  # Filtered testimony — reactive to filter inputs
  # ---------------------------------------------------------------------------

  filtered_testimony <- reactive({
    req(testimony_data)
    testimony_data |>
      filter(
        primary_category %in% input$filter_impact,
        type             %in% input$filter_source
      )
  })

  # ---------------------------------------------------------------------------
  # Report count badge — NNG: visibility of system status
  # ---------------------------------------------------------------------------

  output$report_count <- renderText({
    if (is.null(testimony_data)) return("No reports loaded yet")
    n <- if (is.null(testimony_data)) 0 else nrow(filtered_testimony())
    paste0(n, " report", if (n != 1) "s" else "")
  })

  # ---------------------------------------------------------------------------
  # Main map
  # ---------------------------------------------------------------------------

  output$main_map <- renderLeaflet({
    leaflet() |>
      addProviderTiles("CartoDB.Positron", group = "Street") |>
      addProviderTiles("Esri.WorldImagery", group = "Satellite") |>
      setView(lng = -76.55, lat = 42.55, zoom = 11) |>
      addLayersControl(
        baseGroups    = c("Street", "Satellite"),
        overlayGroups = c("Burden Index", "Facility", "Community Reports"),
        options       = layersControlOptions(collapsed = FALSE)
      )
  })

  # Burden index layer — toggled separately so it doesn't reset map view
  observe({
    proxy <- leafletProxy("main_map")
    if (input$layer_burden && !is.null(burden_tracts)) {
      proxy |>
        clearGroup("Burden Index") |>
        addPolygons(
          data        = burden_tracts,
          group       = "Burden Index",
          fillColor   = ~burden_pal(burden_score),
          fillOpacity = 0.55,
          color       = "white",
          weight      = 0.8,
          label       = ~paste0(NAME, " — Burden: ", round(burden_score, 2)) |>
                          lapply(htmltools::HTML),
          popup       = ~paste0(
            "<b>", NAME, "</b><br>",
            "Burden score: <b>", round(burden_score, 2), "</b><br>",
            "% Poverty: ", round(pct_poverty, 1), "%<br>",
            "% Non-white: ", round(pct_nonwhite, 1), "%<br>",
            "% Renter: ", round(pct_renter, 1), "%"
          ),
          highlightOptions = highlightOptions(
            weight = 2, color = "#333", fillOpacity = 0.75, bringToFront = TRUE
          )
        ) |>
        addLegend(
          layerId   = "burden_legend",
          pal       = burden_pal,
          values    = burden_tracts$burden_score,
          title     = "Burden<br>Score",
          position  = "bottomright",
          group     = "Burden Index",
          opacity   = 0.8
        )
    } else {
      proxy |> clearGroup("Burden Index")
    }
  })

  # Facility layer
  observe({
    proxy <- leafletProxy("main_map")
    if (input$layer_facility && !is.null(terrawulf_sf)) {
      proxy |>
        clearGroup("Facility") |>
        addCircleMarkers(
          data        = terrawulf_sf,
          group       = "Facility",
          radius      = 12,
          color       = "#c0392b",
          fillColor   = "#e74c3c",
          fillOpacity = 0.9,
          weight      = 2,
          label       = "TeraWulf Nautilus Cryptomine",
          popup       = paste0(
            "<b>TeraWulf Nautilus Cryptomine</b><br>",
            "Lansing, NY — Tompkins County<br>",
            "Capacity: ~50 MW<br>",
            "Cooling: Cayuga Lake water withdrawal"
          )
        )
    } else {
      proxy |> clearGroup("Facility")
    }
  })

  # Testimony layer
  observe({
    proxy <- leafletProxy("main_map")
    if (input$layer_testimony && !is.null(testimony_data) && nrow(filtered_testimony()) > 0) {
      ft <- filtered_testimony()
      proxy |>
        clearGroup("Community Reports") |>
        addCircleMarkers(
          data        = ft,
          group       = "Community Reports",
          radius      = 7,
          color       = "white",
          weight      = 1.5,
          fillColor   = ~testimony_pal(primary_category),
          fillOpacity = 0.85,
          label       = ~paste0(IMPACT_LABELS[primary_category], " — ", SOURCE_LABELS[type]) |>
                          lapply(htmltools::HTML),
          popup       = ~paste0(
            "<b>", IMPACT_LABELS[primary_category], "</b><br>",
            "<i>", SOURCE_LABELS[type], "</i><br><br>",
            substr(text, 1, 300), if (nchar(text) > 300) "..." else ""
          )
        )
    } else {
      proxy |> clearGroup("Community Reports")
    }
  })

  # ---------------------------------------------------------------------------
  # Analysis charts — R4DS conventions: theme_minimal, meaningful color, no junk
  # ---------------------------------------------------------------------------

  output$chart_impact_types <- renderPlot({
    if (is.null(testimony_data)) {
      ggplot() +
        annotate("text", x = 0.5, y = 0.5, label = "No testimony data loaded yet",
                 color = "grey50", size = 5) +
        theme_void()
    } else {
      testimony_data |>
        st_drop_geometry() |>
        count(primary_category) |>
        mutate(
          label     = IMPACT_LABELS[primary_category],
          label     = fct_reorder(label, n)
        ) |>
        ggplot(aes(x = n, y = label, fill = primary_category)) +
        geom_col(width = 0.65, show.legend = FALSE) +
        geom_text(aes(label = n), hjust = -0.2, size = 3.5, color = "grey30") +
        scale_fill_manual(values = IMPACT_COLORS) +
        scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
        labs(x = "Number of reports", y = NULL) +
        theme_minimal(base_size = 13) +
        theme(
          panel.grid.major.y = element_blank(),
          panel.grid.minor   = element_blank(),
          axis.text.y        = element_text(color = "grey20")
        )
    }
  }, res = 110)

  output$chart_source_types <- renderPlot({
    if (is.null(testimony_data)) {
      ggplot() +
        annotate("text", x = 0.5, y = 0.5, label = "No testimony data loaded yet",
                 color = "grey50", size = 5) +
        theme_void()
    } else {
      testimony_data |>
        st_drop_geometry() |>
        count(type) |>
        mutate(label = SOURCE_LABELS[type]) |>
        ggplot(aes(x = "", y = n, fill = label)) +
        geom_col(width = 0.5) +
        geom_text(aes(label = paste0(label, "\n(", n, ")")),
                  position = position_stack(vjust = 0.5),
                  size = 3.5, color = "white", fontface = "bold") +
        coord_polar(theta = "y") +
        scale_fill_brewer(palette = "Set2") +
        labs(fill = NULL) +
        theme_void(base_size = 13) +
        theme(legend.position = "bottom")
    }
  }, res = 110)

  output$chart_burden_dist <- renderPlot({
    if (is.null(burden_tracts)) {
      ggplot() +
        annotate("text", x = 0.5, y = 0.5, label = "Burden index not loaded",
                 color = "grey50", size = 5) +
        theme_void()
    } else {
      burden_tracts |>
        st_drop_geometry() |>
        ggplot(aes(x = burden_score)) +
        geom_histogram(bins = 12, fill = "#E07B39", color = "white", linewidth = 0.3) +
        geom_vline(xintercept = mean(burden_tracts$burden_score, na.rm = TRUE),
                   linetype = "dashed", color = "grey40", linewidth = 0.7) +
        annotate("text",
                 x     = mean(burden_tracts$burden_score, na.rm = TRUE) + 0.01,
                 y     = Inf, vjust = 1.5, hjust = 0,
                 label = "County mean",
                 color = "grey40", size = 3.5) +
        scale_x_continuous(labels = scales::label_number(accuracy = 0.01)) +
        labs(x = "Burden score", y = "Number of tracts") +
        theme_minimal(base_size = 13) +
        theme(panel.grid.minor = element_blank())
    }
  }, res = 110)

  # ---------------------------------------------------------------------------
  # Testimony table — NNG: recognition over recall, flexibility via search
  # ---------------------------------------------------------------------------

  output$testimony_table <- DT::renderDataTable({
    if (is.null(testimony_data)) {
      return(DT::datatable(
        tibble(Message = "No testimony data loaded yet — run pipeline scripts 03 and 04."),
        options = list(dom = "t"), rownames = FALSE
      ))
    }

    df <- testimony_data |>
      st_drop_geometry() |>
      filter(
        primary_category %in% input$filter_impact,
        type             %in% input$filter_source
      )

    # Apply search
    if (nchar(trimws(input$search_reports)) > 0) {
      q <- tolower(trimws(input$search_reports))
      df <- df |> filter(str_detect(tolower(text), q))
    }

    df |>
      mutate(
        `Impact Type` = IMPACT_LABELS[primary_category],
        `Source`      = SOURCE_LABELS[type],
        `Date`        = as.character(date),
        `Excerpt`     = paste0(substr(text, 1, 200), "...")
      ) |>
      select(`Date`, `Impact Type`, `Source`, `Excerpt`) |>
      DT::datatable(
        rownames  = FALSE,
        selection = "single",
        options   = list(
          pageLength  = 15,
          dom         = "tip",        # table, info, pagination only — no redundant search box
          scrollX     = TRUE,
          columnDefs  = list(
            list(width = "55%", targets = 3)  # wider excerpt column
          )
        )
      )
  })

  # Download — NNG: user control
  output$download_reports <- downloadHandler(
    filename = function() paste0("community_reports_", Sys.Date(), ".csv"),
    content  = function(file) {
      if (!is.null(testimony_data)) {
        testimony_data |>
          st_drop_geometry() |>
          mutate(
            impact_type = IMPACT_LABELS[primary_category],
            source_type = SOURCE_LABELS[type]
          ) |>
          write_csv(file)
      }
    }
  )
}

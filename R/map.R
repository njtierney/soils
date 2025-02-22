#' Prep data to gis df
#'
#' @param df Dataframe containing columns: `longitude`, `latitude`, and two
#'   columns with values you want to appear in the map label and popup.
#' @param label_heading Column in `df` that you want to appear as the bold point
#'   label on your map, as well as the first line of the popup when the user
#'   clicks a point.
#' @param label_body Column in `df` that you want to appear as body text below
#'   the `label_heading` in the popup.
#' @returns Dataframe to be input into `make_leaflet()`.
#' @export
#'
#' @examples
#' exampleData |>
#'   dplyr::distinct(latitude, longitude, .keep_all = TRUE) |>
#'   head(3) |>
#'   prep_for_map(label_heading = fieldName, label_body = crop) |>
#'   dplyr::glimpse()
prep_for_map <- function(df, label_heading, label_body) {
  df |>
    assertr::verify(assertr::has_all_names(
      "longitude",
      "latitude"
    )) |>
    subset(!duplicated(sampleId)) |>
    dplyr::arrange(fieldId) |>
    dplyr::mutate(
      dplyr::across(dplyr::where(is.numeric), \(x) round(x, 4)),
      label = paste0("<strong>", {{ label_heading }}, "</strong>"),
      popup = paste0(label, "<br>", {{ label_body }})
    )
}

#' Make leaflet map
#'
#' @param df Dataframe containing columns: `longitude`, `latitude`, `label`,
#'   `popup`. See `prep_for_map()` for details.
#' @param primary_color Color of points. Defaults to WaSHI red.
#'
#' @source JavaScript code adapted from
#'   [`leaflet.extras`](https://github.com/bhaskarvk/leaflet.extras/tree/master).
#'
#' @returns Leaflet map.
#'
#' @export
#'
#' @examples
#' gis_df <- exampleData |>
#'   dplyr::distinct(latitude, longitude, .keep_all = TRUE) |>
#'   head(3) |>
#'   prep_for_map(label_heading = fieldName, label_body = crop)
#'
#' dplyr::glimpse(gis_df)
#'
#' # Make leaflet
#' make_leaflet(gis_df)
make_leaflet <- function(
  df,
  primary_color = "#a60f2d"
    ) {
  agol <- "https://server.arcgisonline.com/ArcGIS/rest/services/"

  assertr::verify(
    df,
    assertr::has_all_names(
      "longitude",
      "latitude",
      "label",
      "popup"
    )
  )

    leaflet::leaflet(df) |>
    leaflet::addTiles(
      urlTemplate = paste0(agol, "World_Imagery/MapServer/tile/{z}/{y}/{x}"),
      group = "Satellite"
    ) |>
    leaflet::addTiles(
      urlTemplate = paste0(agol, "/World_Topo_Map/MapServer/tile/{z}/{y}/{x}"),
      group = "Topographic"
    ) |>
    leaflet::addCircleMarkers(
      ~longitude,
      ~latitude,
      label = ~ purrr::map(label, \(x) htmltools::HTML(x)),
      labelOptions = leaflet::labelOptions(
        noHide = TRUE,
        style = list("font-size" = "15px"),
        direction = "auto"
      ),
      popup = ~ purrr::map(popup, \(x) htmltools::HTML(x)),
      popupOptions = leaflet::popupOptions(closeOnClick = TRUE),
      options = leaflet::markerOptions(riseOnHover = TRUE),
      radius = 10,
      color = primary_color,
      stroke = FALSE,
      fillOpacity = 0.7
    ) |>
    leaflet::addLayersControl(
      baseGroups = c("Satellite", "Topographic"),
      options = leaflet::layersControlOptions(collapsed = FALSE)
    ) |>
    leaflet::addEasyButton(
      leaflet::easyButton(
        icon = "ion-arrow-shrink",
        title = "Reset view",
        onClick = leaflet::JS(
          "function(btn, map){ map.setView(map._initialCenter, map._initialZoom); }"
        )
      )
    ) |>
    htmlwidgets::onRender(leaflet::JS(
      "
function(el, x){
  var map = this;
  map.whenReady(function(){
    map._initialCenter = map.getCenter();
    map._initialZoom = map.getZoom();
  });
}"
    ))
}

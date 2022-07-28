#' Create a map, whether static or interactive leaflet, from a GeoJSON file
#' @name geojson_map
#' @description Create a distribution map
#'
#' @param map.name the name of the output map. By default "map".
#' @param geojson.path the path of the GeoJSON file. By default 'caravanserail.geojson'
#' @param field.names a vector one or many field names for thematic cartography. If NA (by default)
#' will create a general map
#' @param highlights.eamenaids EAMENA IDs (ex: 'EAMENA-0205783') that will be highlighted in the map.
#'  If NA (by default), no highlights
#' @param plotly.plot if FALSE create a static PNG, if TRUE create a plotly plot as a HTML widget
#' @param export.plot if TRUE, export the plot, if FALSE will only display it
#' @param dataOut the folder where the outputs will be saved. By default: '/results'.
#' If it doesn't exist, it will be created. Only useful is export plot is TRUE
#'
#' @return A map interactive (leaflet) or not
#'
#' @examples
#'
#' # plot a general map
#'  geojson_map_temp(map.name = "caravanserail")
#'
#' # save different thematic map
#' geojson_map_temp(map.name = "caravanserail",
#'                  field.names = c("Disturbance.Cause.Type.", "Damage.Extent.Type"),
#'                  export.plot = T)
#'
#' @export
geojson_map <- function(map.name = "map",
                        geojson.path = paste0(system.file(package = "eamenaR"), "/extdata/caravanserail.geojson"),

                        field.names = NA,

                        highlights.eamenaids = NA,
                        plotly.plot = F,
                        export.plot = F,
                        dataOut = paste0(system.file(package = "eamenaR"), "/results/"),
                        fig.width = 8,
                        fig.height = 8){
  # TODO: generalise from point to othe geometries

  # map.name = "caravanserail" ; geojson.path = paste0(system.file(package = "eamenaR"), "/extdata/caravanserail.geojson") ;
  # highlights.eamenaids = NA ; plotly.plot = F ; export.plot = F ; dataOut = paste0(system.file(package = "eamenaR"), "/results/")
  # fig.width = 8 ; fig.height = 8 ;
  # field.names = c("Disturbance.Cause.Type.", "Threat.Cause.Type")
  # field.names = c("Damage.Extent.Type")
  ea.geojson <- sf::st_read(geojson.path)
  ea.geojson.geom.types <- sf::st_geometry_type(ea.geojson$geometry)

  ea.geojson.point <- ea.geojson[sf::st_geometry_type(ea.geojson$geometry) == "POINT", ]
  ea.geojson.line <- ea.geojson[sf::st_geometry_type(ea.geojson$geometry) == "LINESTRING", ]
  ea.geojson.polygon <- ea.geojson[sf::st_geometry_type(ea.geojson$geometry) == "POLYGON", ]
  if(!is.na(highlights.eamenaids)){
    ea.geojson.highlights.point <- row.names(ea.geojson.point[ea.geojson.point@data$EAMENA.ID %in% highlights.eamenaids, ])
    ea.geojson.highlights.line <- row.names(ea.geojson.line[ea.geojson.line@data$EAMENA.ID %in% highlights.eamenaids, ])
    ea.geojson.highlights.polygon <- row.names(ea.geojson.polygon[ea.geojson.polygon@data$EAMENA.ID %in% highlights.eamenaids, ])
  }
  if(!plotly.plot){
    left <- as.numeric(sf::st_bbox(ea.geojson.point)$xmin)
    bottom <- as.numeric(sf::st_bbox(ea.geojson.point)$ymin)
    right <- as.numeric(sf::st_bbox(ea.geojson.point)$xmax)
    top <- as.numeric(sf::st_bbox(ea.geojson.point)$ymax)
    buffer <- mean(c(abs(left - right), abs(top - bottom)))/10
    bbox <- c(left = left - buffer,
              bottom = bottom - buffer,
              right = right + buffer,
              top = top + buffer
    )
    stamenbck <- ggmap::get_stamenmap(bbox,
                                      zoom = 8,
                                      maptype = "terrain-background")
    cpt.field.name <- 0
    if(!is.na(field.names)){
      print(paste0("* there is/are '", length(field.names),"' different field name to read"))
      for(field.name in field.names){
        # field.name <- "Damage.Extent.Type"
        cpt.field.value <- 0
        cpt.field.name <- cpt.field.name + 1
        print(paste0(" ", cpt.field.name, "/",length(field.names),")    read '", field.name,"' field name"))
        aggregated.unique.values <- unique(ea.geojson.point[[field.name]])
        splitted.values <- stringr::str_split(aggregated.unique.values, ", ")
        splitted.unique.values <- unique(unlist(splitted.values))
        splitted.unique.values <- as.character(na.omit(splitted.unique.values))
        # splitted.unique.values[is.na(splitted.unique.values)] <- "NA"
        print(paste0("*       - there is/are ", length(splitted.unique.values)," different field values to read"))
        for(field.value in splitted.unique.values){
          # field.value <- "Water and/or Wind Action"
          cpt.field.value <- cpt.field.value + 1
          print(paste0("        ", cpt.field.value, "/",length(splitted.unique.values),")    read '", field.value,"' field value"))
          ea.geojson.point.sub <- ea.geojson.point[grep(field.value, ea.geojson.point[[field.name]]), ]
          if(nrow(ea.geojson.point.sub) > 0){
            gmap <- ggmap::ggmap(stamenbck) +
              ggplot2::geom_sf(data = ea.geojson.point.sub,
                               colour = "black",
                               inherit.aes = FALSE) +
              ggrepel::geom_text_repel(data = ea.geojson.point.sub,
                                       ggplot2::aes(x = sf::st_coordinates(ea.geojson.point.sub)[, "X"],
                                                    y = sf::st_coordinates(ea.geojson.point.sub)[, "Y"],
                                                    label = rownames(ea.geojson.point.sub)),
                                       size = 2,
                                       inherit.aes = FALSE) +
              ggplot2::labs(title = map.name,
                            subtitle = paste0(field.name, " = ", field.value)) +
              ggplot2::theme(plot.title = ggplot2::element_text(size = 15,
                                                                hjust = 0.5),
                             plot.subtitle = ggplot2::element_text(size = 12,
                                                                   hjust = 0.5))
            if (export.plot) {
              dir.create(dataOut, showWarnings = FALSE)
              field.value.norm <- gsub("/", "_", field.value)
              field.value.norm <- gsub(" ", "_", field.value.norm)
              field.value.norm <- gsub("%", "perc", field.value.norm)
              gout <- paste0(dataOut, map.name, "_", field.name, "_", field.value.norm, ".png")
              ggplot2::ggsave(gout, gmap,
                              width = fig.width,
                              height = fig.height)
              print(paste(gout, "is exported"))
            } else {
              print(gmap)
            }
          }
        }
      }
    } else {
      ea.geojson.point.sub <- ea.geojson.point
      gmap <- ggmap::ggmap(stamenbck) +
        ggplot2::geom_sf(data = ea.geojson.point.sub,
                         colour = "black",
                         inherit.aes = FALSE) +
        ggrepel::geom_text_repel(data = ea.geojson.point.sub,
                                 ggplot2::aes(x = sf::st_coordinates(ea.geojson.point.sub)[, "X"],
                                              y = sf::st_coordinates(ea.geojson.point.sub)[, "Y"],
                                              label = rownames(ea.geojson.point.sub)),
                                 size = 2,
                                 inherit.aes = FALSE) +
        ggplot2::labs(title = map.name) +
        ggplot2::theme(plot.title = ggplot2::element_text(size = 15,
                                                          hjust = 0.5))
      if (export.plot) {
        dir.create(dataOut, showWarnings = FALSE)
        gout <- paste0(dataOut, map.name, ".png")
        ggplot2::ggsave(gout, gmap,
                        width = fig.width,
                        height = fig.height)
        print(paste(gout, "is exported"))
      } else {
        print(gmap)
      }
    }

    if(plotly.plot){
      if(nrow(ea.geojson.point) > 0){
        ea.geojson.point$lbl <- paste0("<b>", ea.geojson.point$EAMENA.ID,"</b><br>",
                                       ea.geojson.point$Site.Feature.Interpretation.Type, " (", ea.geojson.point$Cultural.Period.Type, ")",
                                       ea.geojson.point$Administrative.Division., ", ", ea.geojson.point$Country.Type, "<br>")
      }
      if(nrow(ea.geojson.line) > 0){
        ea.geojson.line$lbl <- paste0("<b>", ea.geojson.line$EAMENA.ID,"</b><br>",
                                      ea.geojson.line$Site.Feature.Interpretation.Type, " (", ea.geojson.line$Cultural.Period.Type, ")",
                                      ea.geojson.line$Administrative.Division., ", ", ea.geojson.line$Country.Type, "<br>")
      }
      if(nrow(ea.geojson.polygon) > 0){
        ea.geojson.polygon$lbl <- paste0("<b>", ea.geojson.polygon$EAMENA.ID,"</b><br>",
                                         ea.geojson.polygon$Site.Feature.Interpretation.Type, " (", ea.geojson.polygon$Cultural.Period.Type, ")",
                                         ea.geojson.polygon$Administrative.Division., ", ", ea.geojson.polygon$Country.Type, "<br>")
      }
      ea.map <- leaflet::leaflet() %>%
        leaflet::addProviderTiles(leaflet::providers$"Esri.WorldImagery", group = "Ortho") %>%
        leaflet::addProviderTiles(leaflet::providers$"OpenStreetMap", group = "OSM")
      if(nrow(ea.geojson.point) > 0){
        ea.map <- ea.map %>%
          leaflet::addCircleMarkers(data = ea.geojson.point,
                                    weight = 1,
                                    radius = 3,
                                    popup = ~lbl,
                                    label = ~EAMENA.ID,
                                    fillOpacity = .5,
                                    opacity = .8)
      }
      if(nrow(ea.geojson.line) > 0){
        ea.map <- ea.map %>%
          leaflet::addPolylines(data = ea.geojson.line,
                                weight = 1,
                                popup = ~lbl,
                                label = ~EAMENA.ID,
                                fillOpacity = .5,
                                opacity = .8)
      }
      if(nrow(ea.geojson.polygon) > 0){
        ea.map <- ea.map %>%
          leaflet::addPolygons(data = ea.geojson.polygon,
                               weight = 1,
                               popup = ~lbl,
                               label = ~EAMENA.ID,
                               fillOpacity = .5,
                               opacity = .8)
      }
      ea.map <- ea.map %>%
        leaflet::addLayersControl(
          baseGroups = c("Ortho", "OSM"),
          position = "topright") %>%
        leaflet::addScaleBar(position = "bottomright")

      if(!is.na(highlights.eamenaids)){
        if(length(ea.geojson.highlights.point) > 0){
          hl.geom <- ea.geojson.point[rownames(ea.geojson.point@data) == ea.geojson.highlights.point, ]
          ea.map <- ea.map %>%
            leaflet::addCircleMarkers(
              data = hl.geom,
              weight = 1,
              radius = 4,
              popup = ~lbl,
              label = ~EAMENA.ID,
              color = "red",
              fillOpacity = 1,
              opacity = 1)
        }
        if(length(ea.geojson.highlights.line) > 0){
          hl.geom <- ea.geojson.line[rownames(ea.geojson.line@data) == ea.geojson.highlights.line, ]
          ea.map <- ea.map %>%
            leaflet::addPolylines(# lng = ~Longitude,
              data = hl.geom,
              weight = 2,
              color = "red",
              popup = ~lbl,
              label = ~EAMENA.ID,
              fillOpacity = .5,
              opacity = .8)
        }
        if(length(ea.geojson.highlights.polygon) > 0){
          hl.geom <- ea.geojson.polygon[rownames(ea.geojson.polygon@data) == ea.geojson.highlights.polygon, ]
          ea.map <- ea.map %>%
            leaflet::addPolygons(# lng = ~Longitude,
              data = hl.geom,
              weight = 5,
              color = "red",
              popup = ~lbl,
              label = ~EAMENA.ID,
              fillOpacity = .5,
              opacity = .8)
        }
      }
      if (export.plot) {
        dir.create(dataOut, showWarnings = FALSE)
        gout <- paste0(dataOut, map.name, ".html")
        saveWidget(ea.map, gout)
        print(paste(gout, "is exported"))
      } else {
        print(ea.map)
      }
    }
  }
}
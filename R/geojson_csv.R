#' Convert from GeoJSON to CSV
#'
#' @name geojson_csv
#' @description Convert from KML/KMZ to GeoJSON, or from GeoJSON to KML. Geometries drawn in Google Earth or Google Earth pro can be exported as KML or KMZ (ie, compressed KML). At the same time, geometries drawn in EAMENA can be exported as GeoJSON. For a given HP, this data can be then imported into the EAMENA DB.
#'
#' @param geom.path the path to the GeoJSON file. This file comes from the geojson_kml() function.
#' @param export if TRUE (by default), will export the GeoJSON to a CSV file.
#' @param dirOut the path to the folder where the CSV file will be created.
#' @param csv.name the name of the CSV that will be created without the extension
#' @param verbose if TRUE (by default) then display different messages.
#'
#' @return a CSV file
#'
#' @examples
#'
#' geojson_csv()
#'
#' @export
geojson_csv <- function(geom.path = paste0(system.file(package = "eamenaR"),
                                           "/extdata/caravanserail_outGeoJSON.geojson"),
                        export = T,
                        dirOut = paste0(system.file(package = "eamenaR"),
                                        "/extdata/"),
                        csv.name = "caravanserail_outCSV",
                        verbose = T){
  if(verbose){print(paste0("*read: ", geom.path))}
  geom <- sf::st_read(geom.path, quiet = TRUE)
  geom.noZ <- sf::st_zm(geom)
  if(verbose){print(paste0(" ... Z-dim is removed"))}
  n <- nrow(geom.noZ)
  df <- data.frame("ResourceID" = geom.noZ$Name,
                   "Geometric Place Expression" = sf::st_as_text(geom.noZ$geometry),
                   # TODO: modify these values
                   "Location Certainty" = rep("High", n),
                   "Geometry Extent Certainty" = rep("High", n),
                   "Geometry Type" = rep("Perimeter Polygon", n),
                   check.names = FALSE)
  outCSV <- paste0(dirOut, csv.name, ".csv")
  write.table(df, outCSV,
             row.names = FALSE, sep = ",")
  if(verbose){print(paste0("Exported to: ", outCSV))}
}

# geojson_csv(geom.path = paste0(system.file(package = "eamenaR"),
#                                "/extdata/caravanserail_outGeoJSON.geojson"),
#             csv.name = "caravanserail_outCSV2")

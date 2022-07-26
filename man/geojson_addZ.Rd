% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/_temp.R, R/geojson_addZ.R
\name{geojson_addZ}
\alias{geojson_addZ}
\title{Add a Z value to geometries}
\usage{
geojson_addZ(
  geojson.path = paste0(system.file(package = "eamenaR"),
    "/extdata/caravanserail.geojson"),
  geojson.out = NA,
  elevation.api = "open-elevation",
  sleep = 0.3,
  dirOut = paste0(system.file(package = "eamenaR"), "/results/"),
  verbose = T
)

geojson_addZ(
  geojson.path = paste0(system.file(package = "eamenaR"),
    "/extdata/caravanserail.geojson"),
  geojson.out = NA,
  elevation.api = "open-elevation",
  sleep = 0.3,
  dirOut = paste0(system.file(package = "eamenaR"), "/results/"),
  verbose = T
)
}
\arguments{
\item{geojson.path}{the path of the GeoJSON file. By default 'caravanserail.geojson'.}

\item{geojson.out}{the name of the output file. By default NA, will add the suffix 'Z' to the the name of the GeoJSON file (variable `geojson.path`)}

\item{sleep}{the time delay between two API request in seconds. By default 0.3.}

\item{dirOut}{the folder where the outputs will be saved. By default: '/results'. If it doesn't exist, it will be created. Only useful is export plot is TRUE.}

\item{verbose}{if TRUE (by default): verbose}

\item{map.name}{the name of the output map and the name of the saved file (if export.plot is TRUE). By default "map".}

\item{ids}{the IDs of the resources, by default "EAMENA.ID" (R fieldname format, without spaces).}

\item{field.names}{a vector one or many field names for thematic cartography. If NA (by default), will create a general map}

\item{highlights.ids}{EAMENA IDs (ex: 'EAMENA-0205783') that will be highlighted in the map. If NA (by default), no highlights.}

\item{symbology}{the path to the XLSX recording the symbology for the different values, by default 'symbology.xlsx'.}

\item{stamen.zoom}{the zoom of the Stamen basemap, between 0 (world, unprecise) to 21 (building, very precise). By default NA, the zoom level will be calculated automatically.}

\item{plotly.plot}{if FALSE create a static PNG, if TRUE create a plotly plot as a HTML widget.}

\item{export.plot}{if TRUE, export the plot, if FALSE will only display it.}
}
\value{



}
\description{


Use a geoserver API to recover the Z for a given set of points stored in a GeoJSON file
}
\examples{



df <- geojson_addZ(geojson.path = "C:/Rprojects/eamenaR/inst/extdata/caravanserail.geojson",
                   dirOut = "C:/Rprojects/eamenaR/inst/extdata/")


}

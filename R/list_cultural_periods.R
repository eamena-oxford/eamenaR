#' List the name of all the cultural period of a given HP
#' @name list_cultural_periods
#' @description With a given concept UUID (v. Reference Data Manager), find all
#' the cultural periods, subperiods, etc., of a given HP
#'
#' @param db the name of the database or dataset, by default 'eamena'. If 'eamena': will connect the Pg database. If 'geojson', will read the GeoJSON file path recorded in the parameter 'geojson.path'.
#' @param d a hash() object (a Python-like dictionary)
#' @param uuid the UUIDs of one or several HP, only useful if db = 'eamena'. These
#' UUID can be stored in the `d` variable (eg., d_sql[["uuid"]]), a vector, or
#' a single UUID (eg., '12053a2b-9127-47a4-990f-7f5279cd89da')
#' @param geojson.path the path of the GeoJSON file. By default 'caravanserail.geojson'
#' @param cultural_periods the reference table where all the periods and subperiods are
#' listed. By defaut: https://github.com/eamena-oxford/eamenaR/blob/main/inst/extdata/cultural_periods.tsv
#'
#' @return A hash() with listed cultural periods names in the field 'periods'
#' and listed cultural sub-periods names in the field 'subperiods'
#'
#' @examples
#'
#' # looking into the EAMENA DB
#' d_sql <- hash::hash()
#' d_sql <- uuid_from_eamenaid("eamena", "EAMENA-0187363", d_sql, "uuid")
#' d_sql <- list_cultural.periods("eamena", d_sql, "culturalper", d_sql$uuid)
#'
#'
#' # looking into a GeoJSON file
#' geojson.path <- "https://raw.githubusercontent.com/eamena-oxford/eamena-arches-dev/main/data/geojson/caravanserail.geojson"
#' d_sql <- list_cultural.periods(db = "geojson", d = d_sql, field = "culturalper", geojson.path)
#' plot_cultural.periods(d = d_sql, field = "period")
#'
#' @export
list_cultural_periods <- function(db = 'eamena',
                                  d = NA,
                                  uuid = NA,
                                  geojson.path = paste0(system.file(package = "eamenaR"), "/extdata/caravanserail.geojson"),
                                  cultural_periods = paste0(system.file(package = "eamenaR"), "/extdata/cultural_periods.tsv")){



  # TODO: field is useful?
  # d <- d_sql ; uuid <- '12053a2b-9127-47a4-990f-7f5279cd89da'; field <- "culturalper"
  # d <- d_sql ; uuid <- d_sql[["uuid"]]; field <- "culturalper"
  # d <- d_sql ; uuid <- d_sql[["uuid"]]; field <- "culturalper" ; db = 'geojson' ; geojson.path = 'https://raw.githubusercontent.com/eamena-oxford/eamena-arches-dev/main/data/geojson/caravanserail.geojson'
  df.periods.template <- data.frame(eamenaid = character(0),
                                    periods = character(0),
                                    periods.certain = character(0),
                                    name.periods = character(0),
                                    name.periods.certain = character(0)
  )
  df.subperiods.template <- data.frame(eamenaid = character(0),
                                       subperiods = character(0),
                                       subperiods.certain = character(0),
                                       name.subperiods = character(0),
                                       name.subperiods.certain = character(0)
  )
  #length(uuid)
  if(db == "eamena"){
    for (i in seq(1, length(uuid))){
      # i <- 2
      # print(i)
      if(i %% 10 == 0){print(paste("*read:", i, "/", length(uuid)))}
      a_uuid <- uuid[i]
      a_eamenaid <- d$eamenaid[i]
      sqll <- stringr::str_interp("
      SELECT
      '${a_eamenaid}' AS eamenaid,
      tiledata ->> '38cff73b-c77b-11ea-a292-02e7594ce0a0' AS periods,
      tiledata ->> '38cff738-c77b-11ea-a292-02e7594ce0a0' AS periods_certain,
      tiledata ->> '38cff73c-c77b-11ea-a292-02e7594ce0a0' AS subperiods,
      tiledata ->> '38cff73a-c77b-11ea-a292-02e7594ce0a0' AS subperiods_certain
      FROM tiles
      WHERE resourceinstanceid = '${a_uuid}'
                     ")
      print("DB")
      # con <- my_con(db) # load the Pg connection
      df.part <- DBI::dbGetQuery(con, sqll)
      DBI::dbDisconnect(con)
    }
  }
  if(db == "geojson"){
    eamenaid <- geojson_get_field(geojson.path, "EAMENA.ID")
    periods <- geojson_get_field(geojson.path, "Cultural.Period.Type")
    periods_certain <- geojson_get_field(geojson.path, "Cultural.Period.Certainty")
    subperiods <- geojson_get_field(geojson.path, "Cultural.Sub.period.Type")
    subperiods_certain <- geojson_get_field(geojson.path, "Cultural.Sub.period.Certainty")
    df.part <- data.frame(eamenaid = eamenaid,
                          periods = periods,
                          periods_certain = periods_certain,
                          subperiods = subperiods,
                          subperiods_certain = subperiods_certain)
  }
  periods <- df.part[!(is.na(df.part$periods) | df.part$periods == ""), ]
  if(nrow(periods) > 0){
    df.periods <- data.frame(eamenaid = periods$eamenaid,
                             periods = periods$periods,
                             periods.certain = periods$periods_certain
    )
    cultural.periods <- read.table(cultural_periods,
                                   sep = "\t", header = T)
    df.periods.template <- merge(df.periods, cultural.periods, by.x = "periods", by.y = "ea.name", all.x = TRUE)
  }
  subperiods <- df.part[!(is.na(df.part$subperiods) | df.part$subperiods == ""), ]
  if(nrow(subperiods) > 0){
    df.subperiods <- data.frame(eamenaid = subperiods$eamenaid,
                                subperiods = subperiods$subperiods,
                                subperiods.certain = subperiods$subperiods_certain
    )
    cultural.periods <- read.table(cultural_periods,
                                   sep = "\t", header = T)
    df.subperiods.template <- merge(df.subperiods, cultural.periods, by.x = "subperiods", by.y = "ea.name", all.x = TRUE)
  }
  # clean
  df.periods.template <- df.periods.template[df.periods.template$eamenaid != "NA", ]
  df.periods.template <- df.periods.template[df.periods.template$periods != "Unknown", ]

  df.subperiods.template <- df.subperiods.template[df.subperiods.template$eamenaid != "NA", ]
  df.subperiods.template <- df.subperiods.template[df.subperiods.template$subperiods != "Unknown", ]

  # store in tibble
  ifelse(nrow(df.periods.template) > 0, periods.out <- df.periods.template, periods.out <- NA)
  ifelse(nrow(df.subperiods.template) > 0, subperiods.out <- df.subperiods.template, subperiods.out <- NA)

  df.tibble <- tidyr::tibble(
    period = periods.out,
  )
  d[["periods"]] <- tidyr::tibble(periods = periods.out)
  d[["subperiods"]] <- tidyr::tibble(subperiods = subperiods.out)
  message("the fields 'periods' and 'subperiods' have been created")
  return(d)
}

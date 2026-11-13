# Run from the book root: Rscript scripts/build-db.R
# Source data: nycflights13 (CC0). No network access is needed after installation.
build_flights_db <- function(path = "data/flights.sqlite") {
  packages <- c("DBI", "RSQLite", "nycflights13")
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop("Install required packages: ", paste(missing, collapse = ", "))
  }
  if (file.exists(path)) return(invisible(path))

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  staging <- tempfile("flights-", tmpdir = dirname(path), fileext = ".sqlite")
  con <- DBI::dbConnect(RSQLite::SQLite(), staging)
  on.exit({
    if (DBI::dbIsValid(con)) DBI::dbDisconnect(con)
    if (file.exists(staging)) unlink(staging)
  }, add = TRUE)

  tables <- list(
    airlines = nycflights13::airlines,
    airports = nycflights13::airports,
    planes = nycflights13::planes,
    weather = nycflights13::weather,
    flights = nycflights13::flights
  )
  # The source stores year, month and day separately. Supply ISO date text too.
  tables$flights$flight_date <- with(
    tables$flights, sprintf("%04d-%02d-%02d", year, month, day)
  )
  DBI::dbWithTransaction(con, {
    for (name in names(tables)) {
      data <- as.data.frame(tables[[name]])
      # POSIXct otherwise becomes a numeric epoch when written through DBI.
      # Use UTC text consistently in both flights and weather; retain NA as NULL.
      for (column in names(data)) {
        if (inherits(data[[column]], "POSIXt")) {
          data[[column]] <- format(data[[column]], "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
        }
      }
      DBI::dbWriteTable(con, name, data, row.names = FALSE)
    }
    DBI::dbExecute(con, "CREATE UNIQUE INDEX airlines_carrier ON airlines(carrier)")
    DBI::dbExecute(con, "CREATE UNIQUE INDEX airports_faa ON airports(faa)")
    DBI::dbExecute(con, "CREATE UNIQUE INDEX planes_tailnum ON planes(tailnum)")
  })
  DBI::dbDisconnect(con)
  if (!file.rename(staging, path)) stop("Could not save database to ", path)
  message("Built ", path)
  invisible(path)
}

if (sys.nframe() == 0L) build_flights_db()

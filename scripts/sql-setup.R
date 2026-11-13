# Hidden setup for each Part I chapter. Run with the book root as working directory.
source("scripts/build-db.R", local = TRUE)
build_flights_db()
con <- DBI::dbConnect(RSQLite::SQLite(), "data/flights.sqlite",
                      flags = RSQLite::SQLITE_RO)

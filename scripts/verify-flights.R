# Run from the book root: Rscript scripts/verify-flights.R
# Check the data and the SQLite behaviours taught by Part I using RSQLite.
source("scripts/sql-setup.R")
check_query <- function(sql, expected) {
  result <- DBI::dbGetQuery(con, sql)[[1]]
  stopifnot(isTRUE(all.equal(result, expected, check.attributes = FALSE)))
  message("OK: ", sql)
}

source_tables <- list(
  airlines = nycflights13::airlines, airports = nycflights13::airports,
  planes = nycflights13::planes, weather = nycflights13::weather,
  flights = nycflights13::flights
)
stopifnot(setequal(DBI::dbListTables(con), names(source_tables)))
for (name in names(source_tables)) {
  stored <- DBI::dbReadTable(con, name)
  original <- as.data.frame(source_tables[[name]])
  stopifnot(nrow(stored) == nrow(original))
  for (column in names(original)) {
    expected <- original[[column]]
    if (inherits(expected, "POSIXt")) {
      expected <- format(expected, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    }
    stopifnot(isTRUE(all.equal(stored[[column]], expected, check.attributes = FALSE)))
  }
  message("OK: ", name, " (", nrow(stored), " rows; all source values preserved)")
}
dates <- DBI::dbGetQuery(con, "SELECT flight_date FROM flights")[[1]]
stopifnot(identical(dates, with(nycflights13::flights,
                              sprintf("%04d-%02d-%02d", year, month, day))))
message("SQLite ", DBI::dbGetQuery(con, "SELECT sqlite_version()")[[1]])

check_query("SELECT 7 / 2", 3L)
check_query("SELECT 7 * 1.0 / 2", 3.5)
check_query("SELECT 'JetBlue' LIKE 'jet%'", 1L)
check_query("SELECT char(230) LIKE char(198)", 0L) # ae ligatures, non-ASCII
check_query("SELECT 'JFK' = 'jfk'", 0L)
check_query("SELECT 'JFK' < 'jfk'", 1L)
check_query("SELECT '10' < '9'", 1L)
check_query("SELECT 2013-07-04", 2002L)
check_query("SELECT 60 BETWEEN 60 AND 120", 1L)
check_query("SELECT 120 BETWEEN 60 AND 120", 1L)
check_query("SELECT 90 BETWEEN 120 AND 60", 0L)
check_query("SELECT '2013-07-04' BETWEEN '2013-07-01' AND '2013-07-04'", 1L)
check_query("SELECT 'Air' LIKE '%Air%'", 1L) # % can match zero characters
check_query("SELECT 'JFK' LIKE '_F_'", 1L)
check_query("SELECT 'JFKX' LIKE '_F_'", 0L)
check_query("SELECT 'Airways' LIKE 'Air'", 0L)
check_query("SELECT 1 OR 0 AND 0", 1L)
check_query("SELECT (1 OR 0) AND 0", 0L)
check_query("SELECT NOT 1 = 0", 1L)
check_query("SELECT NOT 0 AND 0", 0L)
check_query("SELECT COUNT(*) FROM flights WHERE origin = 'JFK' AND origin = 'LGA'", 0L)
check_query("SELECT COUNT(*) FROM flights WHERE dep_delay = NULL", 0L)
stopifnot(DBI::dbGetQuery(con, "SELECT COUNT(*) FROM flights WHERE dep_delay IS NULL")[[1]] > 0L)
check_query("SELECT carrier FROM airlines ORDER BY carrier LIMIT 3", c("9E", "AA", "AS"))
check_query("SELECT carrier FROM airlines ORDER BY carrier ASC LIMIT 3", c("9E", "AA", "AS"))
renamed <- DBI::dbGetQuery(con, "SELECT carrier name FROM airlines ORDER BY carrier LIMIT 1")
stopifnot(identical(names(renamed), "name"), identical(renamed$name, "9E"))
stopifnot(is.na(DBI::dbGetQuery(con, "SELECT dep_delay FROM flights ORDER BY dep_delay LIMIT 1")[[1]]))
check_query("SELECT dep_delay FROM flights ORDER BY dep_delay DESC LIMIT 1", 1301L)
stopifnot(inherits(try(DBI::dbGetQuery(con, "SELECT carrier FROM airlines LIMIT 5 ORDER BY carrier"), silent = TRUE), "try-error"))
stopifnot(inherits(try(DBI::dbGetQuery(con, "SELECT carrier FROM airlines WHERE carrier = JFK"), silent = TRUE), "try-error"))
check_query("SELECT COUNT(*) FROM flights f INNER JOIN airlines a ON f.carrier = a.carrier", nrow(source_tables$flights))
check_query("SELECT COUNT(*) FROM airlines a RIGHT JOIN flights f ON a.carrier = f.carrier", nrow(source_tables$flights))
check_query("SELECT COUNT(*) FROM airlines a FULL OUTER JOIN flights f ON a.carrier = f.carrier", nrow(source_tables$flights))
check_query("SELECT COUNT(*) FROM flights f LEFT JOIN planes p ON f.tailnum = p.tailnum", nrow(source_tables$flights))

# Execute every SQL example, including expandable answers and companion solutions.
files <- c("sql-intro.qmd", "sql-basics.qmd", "sql-advanced.qmd", "joins.qmd",
           "solutions/sql-advanced.md", "solutions/joins.md")
total <- 0L
for (file in files) {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  in_sql <- FALSE
  query <- character()
  count <- 0L
  for (line in lines) {
    if (!in_sql && grepl("^```(\\{sql[,}]|sql$)", line)) {
      in_sql <- TRUE
      query <- character()
    } else if (in_sql && grepl("^```$", line)) {
      result <- DBI::dbGetQuery(con, paste(query, collapse = "\n"))
      stopifnot(nrow(result) > 0L)
      count <- count + 1L
      in_sql <- FALSE
    } else if (in_sql) {
      query <- c(query, line)
    }
  }
  stopifnot(!in_sql, count > 0L)
  total <- total + count
  message("OK: ", file, " (", count, " SQL examples)")
}
DBI::dbDisconnect(con)
before <- file.info("data/flights.sqlite")$mtime
build_flights_db()
stopifnot(identical(before, file.info("data/flights.sqlite")$mtime))
message("verify-flights OK: ", total, " examples; repeat build reuses existing file")

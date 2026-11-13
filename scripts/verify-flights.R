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
stopifnot(identical(names(DBI::dbGetQuery(con, "SELECT name, carrier FROM airlines LIMIT 1")),
                    c("name", "carrier")))
stopifnot(nrow(DBI::dbGetQuery(con, "SELECT carrier FROM airlines LIMIT 100")) == 16L)
stopifnot(nrow(DBI::dbGetQuery(con, "SELECT carrier FROM airlines WHERE carrier = 'missing' LIMIT 5")) == 0L)
stopifnot(is.na(DBI::dbGetQuery(con, "SELECT dep_delay FROM flights ORDER BY dep_delay LIMIT 1")[[1]]))
stopifnot(is.na(DBI::dbGetQuery(con, "SELECT dep_delay FROM flights ORDER BY dep_delay DESC LIMIT 1 OFFSET 336775")[[1]]))
check_query("SELECT dep_delay FROM flights ORDER BY dep_delay DESC LIMIT 1", 1301L)
stopifnot(inherits(try(DBI::dbGetQuery(con, "SELECT carrier FROM airlines LIMIT 5 ORDER BY carrier"), silent = TRUE), "try-error"))
stopifnot(inherits(try(DBI::dbGetQuery(con, "SELECT carrier FROM airlines WHERE carrier = JFK"), silent = TRUE), "try-error"))
check_query("SELECT COUNT(*) FROM flights f INNER JOIN airlines a ON f.carrier = a.carrier", nrow(source_tables$flights))
check_query("SELECT COUNT(*) FROM airlines a RIGHT JOIN flights f ON a.carrier = f.carrier", nrow(source_tables$flights))
check_query("SELECT COUNT(*) FROM airlines a FULL OUTER JOIN flights f ON a.carrier = f.carrier", nrow(source_tables$flights))
check_query("SELECT COUNT(*) FROM flights f LEFT JOIN planes p ON f.tailnum = p.tailnum", nrow(source_tables$flights))

# Chapter 4: row counts, missing values, distinct values and group semantics.
check_query("SELECT COUNT(*) FROM flights", 336776L)
check_query("SELECT COUNT(dep_delay) FROM flights", 328521L)
check_query("SELECT COUNT(*) - COUNT(dep_delay) FROM flights", 8255L)
check_query("SELECT COUNT(DISTINCT carrier) FROM flights", 16L)
check_query("SELECT COUNT(DISTINCT tailnum) FROM flights", 4043L)
numeric_summary <- DBI::dbGetQuery(con, "SELECT SUM(dep_delay) AS total, AVG(dep_delay) AS average, MIN(dep_delay) AS minimum, MAX(dep_delay) AS maximum FROM flights")
delay_values <- source_tables$flights$dep_delay
stopifnot(isTRUE(all.equal(as.numeric(numeric_summary[1, ]),
  c(sum(delay_values, na.rm = TRUE), mean(delay_values, na.rm = TRUE),
    min(delay_values, na.rm = TRUE), max(delay_values, na.rm = TRUE)))))
nonpositive_counts <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS rows, COUNT(dep_delay) AS known FROM flights WHERE dep_delay <= 0")
stopifnot(nonpositive_counts$rows == nonpositive_counts$known)
stopifnot(DBI::dbGetQuery(con, "SELECT COUNT(*) FROM flights WHERE dep_delay = 0")[[1]] > 0L,
          DBI::dbGetQuery(con, "SELECT COUNT(*) FROM flights WHERE dep_delay < 0")[[1]] > 0L)
for (filter in c("dep_delay IS NULL", "origin = 'XXX'")) {
  result <- DBI::dbGetQuery(con, paste("SELECT COUNT(*) AS rows, COUNT(dep_delay) AS known,",
    "SUM(dep_delay) AS total, AVG(dep_delay) AS average, MIN(dep_delay) AS minimum,",
    "MAX(dep_delay) AS maximum FROM flights WHERE", filter))
  stopifnot(nrow(result) == 1L, result$known == 0L,
            all(is.na(result[c("total", "average", "minimum", "maximum")])))
  stopifnot(result$rows == if (filter == "dep_delay IS NULL") 8255L else 0L)
}
stopifnot(nrow(DBI::dbGetQuery(con, "SELECT origin, COUNT(*) FROM flights WHERE origin = 'XXX' GROUP BY origin")) == 0L)
averages <- DBI::dbGetQuery(con, "SELECT AVG(dep_delay) AS builtin, SUM(dep_delay)*1.0/COUNT(dep_delay) AS manual FROM flights WHERE origin = 'JFK'")
stopifnot(isTRUE(all.equal(averages$builtin, averages$manual)))
# Check the four actual input rows and all numbers in the grouping diagram.
tiny <- DBI::dbGetQuery(con, "SELECT origin, carrier, flight, dep_delay FROM flights WHERE flight_date = '2013-01-01' AND sched_dep_time <= 550 ORDER BY sched_dep_time, carrier, flight, origin")
stopifnot(identical(tiny$origin, c("EWR", "LGA", "JFK", "JFK")),
          identical(tiny$carrier, c("UA", "UA", "AA", "B6")),
          identical(tiny$flight, c(1545L, 1714L, 1141L, 725L)),
          identical(tiny$dep_delay, c(2, 4, 2, -1)))
tiny_groups <- DBI::dbGetQuery(con, "SELECT origin, COUNT(*) AS departures, SUM(dep_delay) AS delay FROM flights WHERE flight_date = '2013-01-01' AND sched_dep_time <= 550 GROUP BY origin ORDER BY origin")
stopifnot(identical(tiny_groups$origin, c("EWR", "JFK", "LGA")),
          identical(tiny_groups$departures, c(1L, 2L, 1L)),
          identical(tiny_groups$delay, c(2, 1, 4)))
bare <- DBI::dbGetQuery(con, "SELECT origin, COUNT(*) AS departures FROM flights")
stopifnot(nrow(bare) == 1L, bare$departures == 336776L,
          bare$origin %in% c("EWR", "JFK", "LGA")) # no promise about which bare value
stopifnot(inherits(try(DBI::dbGetQuery(con, "SELECT carrier, COUNT(*) FROM flights WHERE COUNT(*) >= 1000 GROUP BY carrier"), silent = TRUE), "try-error"),
          inherits(try(DBI::dbGetQuery(con, "SELECT carrier, COUNT(*) FROM flights HAVING COUNT(*) >= 1000 GROUP BY carrier"), silent = TRUE), "try-error"))
july <- DBI::dbGetQuery(con, "SELECT carrier, COUNT(*) AS departures, AVG(dep_delay) AS delay FROM flights WHERE month = 7 GROUP BY carrier HAVING COUNT(*) >= 1000 AND AVG(dep_delay) > 20 ORDER BY carrier")
# Independently compare the grouped counts and averages with the package data.
july_source <- subset(source_tables$flights, month == 7)
july_counts <- table(july_source$carrier)
july_means <- tapply(july_source$dep_delay, july_source$carrier, mean, na.rm = TRUE)
expected_carriers <- sort(names(july_counts)[july_counts >= 1000 & july_means > 20])
stopifnot(identical(july$carrier, expected_carriers),
          isTRUE(all.equal(july$departures, as.integer(july_counts[july$carrier]))),
          isTRUE(all.equal(july$delay, as.numeric(july_means[july$carrier]))))
message("OK: chapter 4 counts, NULL aggregates, diagram, GROUP BY and HAVING")

# Chapter 6: verify lookup keys and every match/no-match claim with this RSQLite.
for (table in c("airlines", "planes")) {
  key <- if (table == "airlines") "carrier" else "tailnum"
  keys <- DBI::dbGetQuery(con, sprintf(
    "SELECT COUNT(*) AS rows, COUNT(%s) AS known, COUNT(DISTINCT %s) AS distinct_keys FROM %s",
    key, key, table))
  stopifnot(keys$rows == keys$known, keys$rows == keys$distinct_keys)
}
check_query("SELECT COUNT(*) FROM flights f INNER JOIN planes p ON f.tailnum = p.tailnum", 284170L)
check_query("SELECT COUNT(*) FROM flights f LEFT JOIN planes p ON f.tailnum = p.tailnum WHERE p.tailnum IS NULL", 52606L)
check_query("SELECT COUNT(*) FROM flights WHERE tailnum IS NULL", 2512L)
check_query("SELECT COUNT(*) FROM flights f LEFT JOIN planes p ON f.tailnum = p.tailnum WHERE p.tailnum IS NULL AND f.tailnum IS NOT NULL", 50094L)
check_query("SELECT COUNT(DISTINCT f.tailnum) FROM flights f LEFT JOIN planes p ON f.tailnum = p.tailnum WHERE p.tailnum IS NULL AND f.tailnum IS NOT NULL", 721L)
# Independent package-side match check, including the missing identifiers.
flight_keys <- source_tables$flights$tailnum
plane_keys <- source_tables$planes$tailnum
package_matches <- !is.na(flight_keys) & flight_keys %in% plane_keys
stopifnot(sum(package_matches) == 284170L, sum(!package_matches) == 52606L,
          sum(is.na(flight_keys)) == 2512L,
          sum(!is.na(flight_keys) & !package_matches) == 50094L)
airline_picture <- DBI::dbGetQuery(con, "SELECT f.carrier, f.flight, a.name FROM flights f INNER JOIN airlines a ON f.carrier = a.carrier WHERE f.flight_date = '2013-01-01' AND f.sched_dep_time <= 540 ORDER BY f.sched_dep_time, f.carrier, f.flight, f.origin")
stopifnot(identical(airline_picture$carrier, c("UA", "UA", "AA")),
          identical(airline_picture$flight, c(1545L, 1714L, 1141L)),
          identical(airline_picture$name, c("United Air Lines Inc.", "United Air Lines Inc.", "American Airlines Inc.")))
unlisted <- DBI::dbGetQuery(con, "SELECT f.tailnum, p.tailnum AS matched_tailnum, p.model FROM flights f LEFT JOIN planes p ON f.tailnum = p.tailnum WHERE f.flight_date = '2013-01-01' AND f.carrier = 'AA' AND f.flight = 301 AND f.origin = 'LGA'")
stopifnot(nrow(unlisted) == 1L, unlisted$tailnum == "N3ALAA",
          is.na(unlisted$matched_tailnum), is.na(unlisted$model))
check_query("SELECT COUNT(*) FROM flights f INNER JOIN planes p ON f.tailnum = p.tailnum WHERE p.year IS NULL", 5306L)
check_query("SELECT COUNT(*) FROM flights f LEFT JOIN planes p ON f.tailnum = p.tailnum WHERE p.year IS NULL", 57912L)
check_query("SELECT COUNT(*) FROM flights f LEFT JOIN planes p ON f.tailnum = p.tailnum WHERE p.year >= 2000", 192846L)
check_query("SELECT COUNT(*) FROM flights f LEFT JOIN planes p ON f.tailnum = p.tailnum AND p.year >= 2000", 336776L)
check_query("SELECT COUNT(p.tailnum) FROM flights f LEFT JOIN planes p ON f.tailnum = p.tailnum AND p.year >= 2000", 192846L)
check_query("SELECT COUNT(*) FROM flights f INNER JOIN planes p ON f.tailnum = p.tailnum WHERE f.tailnum IS NULL", 0L)
stopifnot(inherits(try(DBI::dbGetQuery(con, "SELECT carrier FROM flights f INNER JOIN airlines a ON f.carrier = a.carrier LIMIT 1"), silent = TRUE), "try-error"))
# Omitted ON is accepted; LIMIT bounds the intentionally incorrect preview.
stopifnot(nrow(DBI::dbGetQuery(con, "SELECT f.carrier, a.name FROM flights f INNER JOIN airlines a LIMIT 3")) == 3L)
message("OK: chapter 6 unique keys, diagram, missing matches, attributes and ON/WHERE")

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

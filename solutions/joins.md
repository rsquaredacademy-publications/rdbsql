# Solutions — Joining two tables

Run against `data/flights.sqlite` after `Rscript scripts/build-db.R`.
These answers mirror the chapter's expandable answers.


Attempt each question before opening its answer. Keep the matching key
visible when checking individual rows.

1. Show six departures with airline names, ordered by date, scheduled
   time, carrier, flight number and origin.

**Answer**

```sql
SELECT f.flight_date, f.sched_dep_time, f.carrier, f.flight,
       f.origin, f.dest, a.name
FROM flights AS f
INNER JOIN airlines AS a ON f.carrier = a.carrier
ORDER BY f.flight_date, f.sched_dep_time, f.carrier, f.flight, f.origin
LIMIT 6;
```



2. Count July departures by airline code and name. Show the busiest first.

**Answer**

```sql
SELECT f.carrier, a.name, COUNT(*) AS departures
FROM flights AS f
INNER JOIN airlines AS a ON f.carrier = a.carrier
WHERE f.month = 7
GROUP BY f.carrier, a.name
ORDER BY departures DESC, f.carrier;
```

Each departure matches one airline, so the joined row count is a
departure count.



3. Show six departures without an aircraft match. Why test the key from
   `planes` rather than the tail number from `flights`?

**Answer**

```sql
SELECT f.flight_date, f.carrier, f.flight, f.origin, f.tailnum
FROM flights AS f
LEFT JOIN planes AS p ON f.tailnum = p.tailnum
WHERE p.tailnum IS NULL
ORDER BY f.flight_date, f.sched_dep_time, f.carrier, f.flight, f.origin
LIMIT 6;
```

The right key is missing for every unmatched departure. The flight's
tail number can be recorded even when the lookup fails.



4. For each origin, count all departures, matched aircraft records and
   departures without a match.

**Answer**

```sql
SELECT f.origin, COUNT(*) AS departures,
       COUNT(p.tailnum) AS matched_departures,
       COUNT(*) - COUNT(p.tailnum) AS unmatched_departures
FROM flights AS f
LEFT JOIN planes AS p ON f.tailnum = p.tailnum
GROUP BY f.origin
ORDER BY f.origin;
```

The two match-status counts add to the departure count for each origin.



5. Count departures that have an aircraft match but no recorded
   manufacture year. Should these be called unmatched departures?

**Answer**

```sql
SELECT COUNT(*) AS matched_departures_without_year
FROM flights AS f
INNER JOIN planes AS p ON f.tailnum = p.tailnum
WHERE p.year IS NULL;
```

They are matched departures with a missing attribute. The inner join
has already required the tail number to match.



6. Keep every departure from JFK on January 1 and attach aircraft
   details only for aircraft manufactured from 2000 onward. Preview six rows.

**Answer**

```sql
SELECT f.flight_date, f.carrier, f.flight, f.tailnum,
       p.tailnum AS qualifying_tailnum, p.year AS plane_year, p.model
FROM flights AS f
LEFT JOIN planes AS p
  ON f.tailnum = p.tailnum AND p.year >= 2000
WHERE f.origin = 'JFK' AND f.flight_date = '2013-01-01'
ORDER BY f.sched_dep_time, f.carrier, f.flight
LIMIT 6;
```

The left-table conditions select the departures in `WHERE`. The aircraft
year condition belongs in `ON` so departures without a qualifying
aircraft match survive. `LIMIT` previews six of those departures.

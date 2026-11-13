# Solutions — Joining two tables

Run against `data/flights.sqlite` after `Rscript scripts/build-db.R`.
For the customer and order examples with R verbs, see `dbplyr.qmd`.

1. Six departures with airline names:

```sql
SELECT f.flight_date, f.sched_dep_time, f.carrier, f.flight,
       f.origin, f.dest, a.name
FROM flights f
INNER JOIN airlines a ON f.carrier = a.carrier
ORDER BY f.flight_date, f.sched_dep_time, f.carrier, f.flight, f.origin
LIMIT 6;
```

2. Departures per airline name:

```sql
SELECT a.name, COUNT(*) AS departures
FROM flights f
INNER JOIN airlines a ON f.carrier = a.carrier
GROUP BY a.name
ORDER BY departures DESC, a.name;
```

3. Six departures with no aircraft match:

```sql
SELECT f.flight_date, f.carrier, f.flight, f.origin, f.tailnum
FROM flights f
LEFT JOIN planes p ON f.tailnum = p.tailnum
WHERE p.tailnum IS NULL
ORDER BY f.flight_date, f.sched_dep_time, f.carrier, f.flight, f.origin
LIMIT 6;
```

# Solutions — Summaries and groups

Run against `data/flights.sqlite` after `Rscript scripts/build-db.R`.
Results are computed when the queries run.

1. Average departure delay by origin:

```sql
SELECT origin, AVG(dep_delay) AS avg_delay
FROM flights
GROUP BY origin
ORDER BY avg_delay DESC;
```

2. Longest distance among departures from JFK:

```sql
SELECT MAX(distance) AS longest_distance
FROM flights
WHERE origin = 'JFK';
```

3. Top five destinations among AA departures:

```sql
SELECT dest, COUNT(*) AS departures
FROM flights
WHERE carrier = 'AA'
GROUP BY dest
ORDER BY departures DESC, dest
LIMIT 5;
```

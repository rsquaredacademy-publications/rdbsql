# Solutions — Summaries and groups

Run against `data/flights.sqlite` after `Rscript scripts/build-db.R`.
These answers mirror the chapter's expandable answers.


Attempt each question before opening the answer. Describe what one
result row represents as well as writing the SQL.

1. Find the average departure delay for each origin, largest first.
   Include the number of recorded delays. Which airport tops the list?

**Answer**

```sql
SELECT origin, COUNT(dep_delay) AS recorded_delays,
       ROUND(AVG(dep_delay), 2) AS avg_delay_minutes
FROM flights
GROUP BY origin
ORDER BY avg_delay_minutes DESC, origin;
```

Each row describes one origin. EWR has the largest average, calculated
over recorded departure delays.



2. What is the longest distance among departures from JFK? Does the
   result identify a particular flight?

**Answer**

```sql
SELECT MAX(distance) AS longest_distance_miles
FROM flights
WHERE origin = 'JFK';
```

The result is one distance value. It does not identify the departure or
tell us how many flights share that distance.



3. Among AA departures, show the five busiest destinations. Break ties
   alphabetically by destination code.

**Answer**

```sql
SELECT dest, COUNT(*) AS departures
FROM flights
WHERE carrier = 'AA'
GROUP BY dest
ORDER BY departures DESC, dest
LIMIT 5;
```

One row describes an AA destination. `WHERE` selects AA flights before
we count them; `LIMIT` acts on the sorted destination summaries.



4. Count different destinations served from each origin during July.

**Answer**

```sql
SELECT origin, COUNT(DISTINCT dest) AS destinations
FROM flights
WHERE month = 7
GROUP BY origin
ORDER BY origin;
```

Repeated departures to the same destination contribute once per origin.



5. Find carriers with at least 1,000 July departures and an average
   departure delay above 20 minutes. Where do the two thresholds belong?

**Answer**

```sql
SELECT carrier, COUNT(*) AS departures,
       ROUND(AVG(dep_delay), 2) AS avg_delay_minutes
FROM flights
WHERE month = 7
GROUP BY carrier
HAVING COUNT(*) >= 1000 AND AVG(dep_delay) > 20
ORDER BY avg_delay_minutes DESC, carrier;
```

Both thresholds describe groups, so both belong in `HAVING`. The average
uses recorded delays; the departure count includes rows with missing delays.

To check the answer, temporarily remove `HAVING` and inspect all carrier
summaries for July. Then restore the thresholds and confirm that every
remaining carrier meets both. Keeping the month filter unchanged makes
this a comparison of the same population.



6. Count missing departure delays for each origin without discarding
   rows that have a recorded delay.

**Answer**

```sql
SELECT origin, COUNT(*) - COUNT(dep_delay) AS missing_delays
FROM flights
GROUP BY origin
ORDER BY origin;
```

The subtraction counts missing delays while keeping all scheduled
departures in each input group.

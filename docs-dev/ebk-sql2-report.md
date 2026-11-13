# ebk-sql2 report

Worktree: `F:/R/ebooks/_worktrees/rdbsql-part1`.
Branch: `task/sql-part1`; base: `7341480` (reviewed ebk-sql1).
Local commits only. No push, GitHub operation, branch change or other
worktree edit.

## Delivered

- Rewrote outline chapter 4, `sql-advanced.qmd`, as **Summaries and groups**.
  It covers all five aggregate functions, row counts versus recorded-value
  counts, missing and empty inputs, distinct values and combinations,
  grouping, multiple group columns, sorting summaries, HAVING versus WHERE,
  and written versus logical clause order.
- Rewrote outline chapter 6, `joins.qmd`, as **Joining two tables**.
  It uses flights/airlines for the first lookup and flights/planes for
  missing matches. It covers keys, repeated lookups, aliases, qualified
  columns, inner and left joins, missing attributes versus missing matches,
  conditions in ON versus WHERE, table order, Venn diagram limitations,
  and the SQLite RIGHT/FULL version note.
- Added one accessible SVG per chapter: split/summarize/combine using
  four actual departures, and a row-by-row airline lookup using three
  actual departures. Their values are checked against RSQLite results.
- Followed sql1's hidden shared setup, `connection=con` SQL chunks and
  final disconnect. Both chapters have learning objectives, a portable
  Common mistakes blockquote, six Try it questions with expandable
  runnable answers, five key points, a next pointer and course lesson links.
- Updated both companion solution files to mirror all six inline answers.
- Extended the shared verifier with data assertions for these chapters.
  All chapter tables come from executed SQL, with no pasted result tables.

## Files changed

| File | Purpose |
|:--|:--|
| `sql-advanced.qmd` | Full chapter 4 rewrite |
| `joins.qmd` | Full chapter 6 rewrite |
| `img/sql-groups.svg` | Four departures split into three origin summaries |
| `img/sql-joins.svg` | Three departures looking up two airline records |
| `solutions/sql-advanced.md` | Six matching summary answers |
| `solutions/joins.md` | Six matching join answers |
| `scripts/verify-flights.R` | SQL behaviour, source-data and example checks |
| `docs-dev/ebk-sql2-report.md` | This report |

No changes to committed `docs/`, Part II, book configuration, redirects,
the database builder or shared setup. `roadmap/` and the generated
`data/flights.sqlite` remain ignored.

## Chapter word counts

| Source | Prose words | Target |
|:--|--:|--:|
| `sql-advanced.qmd` | 2,730 | Approximately 2,800 |
| `joins.qmd` | 2,710 | Approximately 2,800 |

Counts include headings, inline code, image alt text, questions and prose
answers. They exclude fenced code, HTML tags, link destinations and anchor
attributes. The check uses Python Unicode word tokens with internal
apostrophes/hyphens retained (`\w+(?:['’-]\w+)*`), as recorded in
`check-sql2.py` in the temporary render directory.

## Data and SQLite verification

Verified through R 4.6.1, DBI 1.3.0, RSQLite 3.53.3 (SQLite 3.53.3),
nycflights13 1.0.2 and knitr 1.52. The render uses sql1's temporary
dbplyr 2.6.0 library. No packages or system tools were installed by this job.

`Rscript scripts/verify-flights.R` passes against both the existing
worktree database and the fresh database built during the archive render.
The verifier still compares every stored source column to nycflights13,
including missing values, UTC timestamp conversion and added flight dates.
It also checks that a second build reuses the existing file.

| Claim | Executed check and observed result |
|:--|:--|
| COUNT(*) counts all departure rows | 336,776 rows |
| COUNT(dep_delay) skips missing values | 328,521 recorded delays; subtraction gives 8,255 missing delays |
| Zero and negative delays are recorded values | Both occur; COUNT(*) and COUNT(dep_delay) agree on the nonpositive-delay subset |
| SUM, AVG, MIN and MAX summarize recorded numbers | All four SQL results agree with independent R calculations on the package delay column, removing NA |
| AVG uses the recorded-value denominator | JFK AVG agrees with SUM * 1.0 / COUNT(dep_delay) |
| Whole-number division needs a fractional operand | Retained sql1 checks: 7 / 2 = 3; 7 * 1.0 / 2 = 3.5 |
| All-missing and empty aggregate inputs differ | Missing-delay subset has 8,255 rows and zero recorded delays; nonexistent origin has zero rows; both return NULL for SUM/AVG/MIN/MAX and zero for COUNT(dep_delay) |
| Empty grouped input has no groups | Grouped nonexistent-origin query returns zero rows |
| Distinct counts differ from repeated values | 16 different carriers and 4,043 different recorded tail numbers |
| Grouping picture uses real departures | Jan 1 scheduled by 550 gives EWR/UA1545/2, LGA/UA1714/4, JFK/AA1141/2 and JFK/B6725/-1 |
| Picture summaries are correct | EWR: count 1, net delay 2; JFK: count 2, net delay 1; LGA: count 1, net delay 4 |
| SQLite accepts an ungrouped column beside COUNT | Returns one origin label beside the whole-table count; no particular label is asserted |
| WHERE cannot test a group count; HAVING follows GROUP BY | Both intentionally misplaced queries raise errors |
| HAVING applies group thresholds after the July row filter | SQL carrier counts and means agree with independent R table/tapply calculations and the same thresholds |
| Lookup keys are present and unique | COUNT(*), COUNT(key) and COUNT(DISTINCT key) agree for airlines.carrier and planes.tailnum |
| Every flight has exactly one airline match | Airline inner join returns 336,776 rows |
| Airline picture uses real repeated lookups | Three Jan 1 departures scheduled by 540 are UA1545, UA1714 and AA1141; their names match the diagram |
| Aircraft inner join omits unmatched departures | 284,170 matched departures |
| Aircraft left join preserves all departures | 336,776 result rows; 52,606 have no aircraft match |
| Missing flight identifiers explain only part of the gap | 2,512 departure rows have NULL tailnum |
| Recorded but unlisted identifiers explain the rest | 50,094 departures use 721 different recorded tail numbers absent from planes |
| Aircraft counts agree with an independent lookup | Package-side membership checks reproduce 284,170 matches and 52,606 gaps |
| A retained identifier can lack a lookup row | Jan 1 AA301 from LGA retains N3ALAA while matched_tailnum and model are NULL |
| A missing manufacture year does not prove no match | 5,306 departures have an aircraft match with NULL p.year; testing p.year IS NULL after a left join returns 57,912, including the 52,606 gaps |
| A right-table WHERE filter removes unmatched rows | WHERE p.year >= 2000 returns 192,846 departures |
| The same condition in ON preserves left rows | 336,776 departures remain, of which 192,846 have a qualifying aircraft match |
| NULL identifiers do not match through equality | No aircraft inner-join row has NULL f.tailnum |
| An unqualified shared name is ambiguous | SELECT carrier in the airline join raises an error |
| SQLite permits a join without ON | An intentionally bounded incorrect query executes; it does not enforce our intended relationship |
| RIGHT/FULL support is present in this bundled SQLite | Retained sql1 RIGHT JOIN and FULL OUTER JOIN checks execute and return 336,776 rows on the airline/flight relationship |

SQLite's [3.39.0 release notes](https://www.sqlite.org/releaselog/3_39_0.html)
also confirm the introduction of RIGHT/FULL support. Existing sql1 checks
for LIKE case rules, equality, integer division, date comparisons, operator
precedence, NULL comparisons and NULL sorting continue to pass.

All **87** SQL examples and solutions execute with nonempty results:
chapter 1: 3; chapter 2: 25; chapter 4: 24; chapter 6: 23; summary solutions:
6; join solutions: 6. Empty-result behaviour is tested separately rather
than weakening the example check.

## Rendering, links and anchors

Final render summary: **HTML, PDF and ePub all pass** on the final sources.
The PDF is 2,262,764 bytes and has the expected PDF header; the ePub is
947,271 bytes. Both SVGs are embedded byte-for-byte from the render copy
in the ePub (Pandoc names them file4.svg and file5.svg). Both also have
nonempty image alt attributes in HTML and ePub. Chrome headless previews
of the diagrams were visually inspected for readable labels and arrows.

Final gates, from the temporary book root:

- `bash scripts/verify-slugs.sh stage-checked`: PASS, all 11 declared
  chapters/front-matter pages, using the Windows R/yaml fallback.
- `bash scripts/test-redirects.sh stage-checked`: PASS, both existing
  redirect destinations exist.
- `python check-sql2.py`: PASS, all nine original chapter/section IDs
  on each rewritten page, six expandable answers per chapter, resolved
  course links, local HTML fragment links and nonempty diagram alt text.
  It also verifies the 24 and 23 SQL result tables, PDF signature,
  ePub SVG contents and chapter word counts.
- Companion solution comparison: PASS, all six queries in each solution
  file match the chapter's inline answers exactly.
- Final archive source comparison: PASS, both chapters, solutions,
  verifier and diagrams match the worktree after line-ending normalization.
- `Rscript scripts/verify-flights.R`: PASS, all 87 examples/solutions,
  source-data comparisons and SQLite checks in the fresh render copy.
- `git diff --check`: PASS. Comparison to sql1 confirms no edits to
  committed docs/, Part II, book configuration or redirects.

The final log is `render-final-alt.log`. It has no duplicate-identifier,
missing-resource or unresolved-cross-reference warnings. The known local
Linux Libertine font fallback and Windows R locale startup warnings remain;
they do not prevent rendering. Existing CI installs Linux Libertine.

Rendering takes place only in
`C:/Users/DELL/AppData/Local/Temp/ebk-sql2-render-b6695ceecb7c481a905cd9ff4c1d7542`.
The copy was created with `git archive --format=zip` and extracted outside
the repository. Final chapter and verifier fixes were overlaid from the
worktree. The archive began without `data/flights.sqlite`; rendering built it.

All render attempts use:

```sh
bash ~/.claude/bin/heavy-slot.sh ebk-sql2 <portable-quarto> render --to all --output-dir stage-checked
```

The wrapper recognized the ebk-sql2 queue job and reused its counted slot.
The renderer is sql1's portable Quarto 1.10.18 with its bundled Typst
0.15.1 on PATH. R_LIBS_USER includes both the temporary dbplyr library
and the normal R user library.

The first render attempt replaced the normal user library path and could
not find DBI/RSQLite/nycflights13. Restoring that path alongside the temporary
library resolved it. A complete initial render then passed all formats
but warned about duplicate explicit exercises identifiers in the combined
book. The new Try it headings now use automatic identifiers, with raw
HTML compatibility spans retaining each old page's exercises fragment.
The final render checks this correction. An HTML check also found that
Markdown image descriptions had become captions without image alt text.
Both images now use sql1's explicit fig-alt option, retaining the SVG's
own title/description as well.

## Not done and follow-ups

1. No publishing or push. Generated HTML and downloads stay in the temporary
   copy, and committed docs/ is untouched, as the shared brief requires.
2. Planned chapters 3, 5 and 7 remain outside this job. Their next pointers
   identify them as planned and link to available material as well. Until
   those slots exist, Quarto's consecutive numbers differ from outline
   chapter numbers, as already recorded by sql1.
3. Part II, the appendix and the legacy R scripts are unchanged.
   `code/ch4-sqladvanced.R` and `code/ch5-joins.R` remain legacy companions
   under the README's existing notice; migrating those scripts needs a
   separate code-companion pass. The two SQL solution files in this job
   are fully updated.
4. No browser SQL cells were added. The book continues to show rendered
   examples and uses the existing local setup and course practice links.
5. No decision from Aravind is needed to complete these two rewrites.

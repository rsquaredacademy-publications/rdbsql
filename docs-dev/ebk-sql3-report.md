# ebk-sql3 report

Worktree: `F:/R/ebooks/_worktrees/rdbsql-part1`.
Branch: `task/sql-part1`; starting HEAD: `30ddf38`.
Read the common brief, complete companion outline, course design sections
4/6/8/13, Gemini audit, and `origin/style-audit:docs/style-guide.md`
from intro-r before writing.

Local commits only; no push, branch change, GitHub operation, or edits to
another worktree. `roadmap/` was already ignored. The pre-existing
untracked `docs-dev/ebk-sql-audit.md` is untouched and uncommitted.

## Delivered and files changed

| File | Change |
|:--|:--|
| `sql-calculated.qmd` | New chapter 3: per-row arithmetic, aliases, rounding, integer division, storage classes, affinity and text comparisons |
| `sql-null.qmd` | New chapter 5: missing values, comparisons, full AND/OR truth tables, NOT, aggregates, COALESCE and NULLIF |
| `sql-next.qmd` | New chapter 7: one running-total query and one CTE query, both with executed output; neutral paid-track sentence and Part II/SQLite links |
| `img/sql-running-total.svg` | January–March accumulation using real counts |
| `img/sql-cte.svg` | Flight rows to monthly counts to July/August selection |
| `cheatsheet.qmd` | Part I SQL reference before the existing R reference; appendix title updated, `sec-cheatsheet` retained |
| `_quarto.yml` | Filled the three reserved Part I slots in outline order |
| `index.qmd` | Preface describes all seven chapters; removed the planned-chapters notice |
| `sql-basics.qmd`, `sql-advanced.qmd`, `joins.qmd` | Next links lead to chapters 3, 5 and 7 respectively |
| `README.md` | Complete syllabus, appendix description and accurate exercise-availability note |
| `scripts/verify-flights.R` | Added arithmetic/type/NULL/window/CTE assertions and execution of all new chapter and appendix examples |
| `docs-dev/ebk-sql3-report.md` | This report |

All three new chapters use the shared hidden setup, read-only connection,
`connection=con` SQL chunks and final disconnect. Their objectives use
`## Introduction` and the same opening formula as chapters 2/4/6.
Chapters 3 and 5 each have five expandable Try it answers and an
`<span id="exercises"></span>` before the heading. Chapter 7 has no
exercises. Each has Common mistakes, Key points, a Next link and the
matching course link (lessons 5, 8 and 12).

The new truth-table results are calculated by SQL, not pasted tables.
Three one-row queries cover every pair of true/false/unknown inputs for
both AND and OR. The prose explains the renderer's `NA` display of SQL
NULL. Both SVGs have titles/descriptions and explicit Quarto `fig-alt`.

## Word counts

Measured with the sql2 report's method: remove fenced code, HTML tags,
explicit anchors and link destinations; count word tokens in the remaining
text, including headings, objectives, exercises, answers and image text.
These are prose counts, excluding SQL and rendered results.

| Content | Words |
|:--|--:|
| Chapter 3 | 1,649 |
| Chapter 5 | 1,675 |
| Chapter 7 | 801 |
| SQL appendix portion, including introduction | 534 |

The chapters cover the requested outline without adding the excluded
advanced topics. Chapters 3/5 are within about 9% of the approximate
1,800-word targets. The existing R reference from `## Connect, query,
disconnect` through the end matches starting HEAD exactly after newline
normalization, including every code example and heading.

## SQLite facts and data verification

Executed against SQLite **3.53.3**, bundled with RSQLite **3.53.3**.
Other packages: DBI 1.3.0, nycflights13 1.0.2, knitr 1.52; rendering also
uses dbplyr 2.6.0 from the existing temporary sql1 library.

`Rscript scripts/verify-flights.R` passes in the fresh archive. It compares
all original columns in all five stored tables against the installed
nycflights13 data, checks the added ISO dates, and executes **137 SQL
examples/solution queries**. The new chapters contribute 19, 28 and 2
queries; the appendix adds 1. All yield real result tables.

| Fact checked | How and observed result |
|:--|:--|
| Per-row expressions preserve the selected flight rows | Executed all examples; four early departures retain their own inputs; kilometre calculations match miles times 1.609344 |
| Delay differences and rounded rates | UA 1545/1714, AA 1141 and B6 725 give changes 9/16/31/-17 minutes and rates 370/374.3/408.4/516.7 mph |
| Operator precedence and brackets | `10 + 5 * 2 = 20`; `(10 + 5) * 2 = 30` |
| Integer division truncates toward zero | `7 / 2 = 3`; `-7 / 2 = -3`; `7 * 1.0 / 2 = 3.5` |
| Later conversion/rounding cannot restore a discarded fraction | `(7 / 2) * 1.0` and `ROUND(7 / 2, 2)` both give 3 |
| AS names result columns and works in ORDER BY | Executed each alias/sort example; a same-list alias reference, unquoted spaced alias, and `90%` each produce the expected error |
| Five value storage classes | `typeof(NULL/7/7.0/'7'/X'37')` checked individually in a single query: null/integer/real/text/blob |
| Actual column affinities and printed whole values | `PRAGMA table_info(flights)` verifies REAL for distance/air_time/dep_delay, INTEGER for month/flight, TEXT for tailnum; chapter typeof queries execute |
| Affinity guides conversion without rigidly enforcing a storage class | Separate in-memory fixture tests INTEGER/REAL/NUMERIC/TEXT/BLOB columns with numeric strings, nonnumeric strings and NULL; all classes match expectations; book database stays read-only |
| Affinity can change a comparison | `1545 = '1545'` gives 0, while `flight = '1545'` for flight 1545 gives 1 |
| Text versus numeric comparison | `'10' < '9'` gives 1; `10 < 9` and the real-converted comparison give 0; `'JFK' * 1.0` gives 0 and is explained as unsuitable conversion |
| NULL equality/inequality is unknown | NULL compared with itself, zero or text produces NULL; both missing-delay filters using `= NULL`/`<> NULL` count 0 |
| Missing, recorded, zero and empty values differ | 336,776 rows; 328,521 recorded delays; 8,255 missing delays; 334,264 recorded tailnums; 2,512 missing tailnums; 16,514 zero delays; 0 empty or literal `'NULL'` tailnums |
| IS NULL and IS NOT NULL are complementary | Direct counts verified; recorded plus missing delay counts equal all departures |
| Full three-valued AND/OR logic and NOT | Both operations asserted for all nine ordered input pairs; NOT true/false/unknown gives false/true/unknown |
| WHERE retains true conditions only | `NOT (dep_delay > 0)` counts 200,089; explicitly adding missing delays counts 208,344 |
| Missingness overlap is a data property | Both missing counts 2,512; either missing counts 8,255; independently checked against source missingness |
| Grouped missing counts | EWR/JFK/LGA delays: 3,239/1,863/3,153; tailnums: 606/909/997 |
| Aggregates skip NULL, while COUNT(*) counts rows | Existing checks verify net delay 4,152,200, average 12.64, minimum -43 and maximum 1,301; all-missing and empty ungrouped inputs give zero counts and NULL numeric aggregates |
| Missing arithmetic remains missing | Checked `NULL / 60.0`, `10 - NULL`, `NULL * 0`, and `1 / NULL`; count of complete delay differences independently matches rows with both inputs recorded |
| COALESCE uses the first nonmissing argument | Display labels execute; `COALESCE(NULL, 0, 5)` gives 0; all-NULL arguments give NULL; zero-filled delay average is 12.33 versus recorded average 12.64, checked independently in R |
| NULLIF removes equal special values | `NULLIF(0, 0)` and `NULLIF('', '')` give NULL; `NULLIF(5, 0)` gives 5; normalizing empty tailnums changes no recorded count |
| Missing/zero denominator treatment | All-missing delay ratio with `NULLIF(COUNT(dep_delay), 0)` gives NULL; direct SQLite division by zero gives NULL |
| Monthly window runs over monthly summaries | All 12 monthly counts match R's table of source months; every running total matches its cumulative sum; first three totals 27,004/51,955/80,789 and final total 336,776 |
| CTE result and lifetime | Months 7/8 have 29,425/29,327 departures; the next statement cannot read the CTE name; no permanent table is created |

The existing regression checks for LIKE ASCII/non-ASCII behavior, ISO
date comparisons, inclusive BETWEEN, NULL ordering, DISTINCT, GROUP BY,
HAVING, key matches, RIGHT/FULL support and left-join ON/WHERE placement
also pass. The verifier's all-NULL assertion handles RSQLite's logical
NA columns without conflating them with numeric zero.

Official references checked while writing: SQLite's
[types](https://www.sqlite.org/datatype3.html),
[expressions](https://www.sqlite.org/lang_expr.html),
[window functions](https://www.sqlite.org/windowfunctions.html), and
[WITH clause](https://www.sqlite.org/lang_with.html). Numeric and behavioral
claims above were executed locally against the book's bundled engine.

## Render and integrity checks

Rendered only in this throwaway copy outside the repository:

`C:/Users/DELL/AppData/Local/Temp/ebk-sql3-render-1794589098756`.

Created using `git archive HEAD` and overlaid the uncommitted verifier.
The archive initially had no flights database. Rendering rebuilt the
34,193,408-byte file from the installed package. Final source comparison
passes for all 13 changed content/configuration/asset/verifier files,
after newline normalization; README was copied after its later update.

Render command:

```sh
bash ~/.claude/bin/heavy-slot.sh ebk-sql3 <portable-quarto> render --to all --output-dir stage-checked
```

Used the existing sql1 portable Quarto 1.10.18 and its bundled Typst on
PATH. R_LIBS_USER includes both the sql1 temporary dbplyr library and
the ordinary R user library. The wrapper recognized the counted ebk-sql3
queue slot. The complete render exited 0 on its first attempt.

| Check | Result |
|:--|:--|
| Full HTML/PDF/ePub render | PASS |
| `bash scripts/verify-slugs.sh stage-checked` | PASS: all 14 declared pages |
| `bash scripts/test-redirects.sh stage-checked` | PASS: both existing redirects, zero missing destinations |
| `python check-sql3.py` in temporary copy | PASS: internal HTML destinations/fragments, resolved cross-references and shortcodes, Next chain, lesson links, chapter anchors and existing neighbour/appendix anchors |
| Rendered new chapter SQL tables | PASS: exactly 19/28/2 tables; five/five/zero expandable answers |
| New diagrams | PASS: nonempty HTML alternative text and both original SVGs embedded in ePub |
| PDF | PASS: valid PDF, 2,930,340 bytes; pdftotext confirms new titles and numeric results |
| ePub | PASS: valid archive, 996,769 bytes; new SQL examples and both diagrams present |
| Fresh-copy data and SQL verifier | PASS: all source data, assertions and 137 examples |
| `git diff 30ddf38 --check` | PASS |
| Worktree scope | PASS: no changes in committed docs/, Part II chapter files, redirects or ignore rules |

Logs and check artifacts remain in the temporary copy: `render-all.log`,
`verify-flights.log`, `check-sql3.py`, `book-text.txt`, and `stage-checked/`.
The log contains the previously known Windows R locale startup warnings
and Linux Libertine font fallback. There are no unresolved-reference,
duplicate-identifier or missing-resource render warnings.

## Not done and follow-ups

1. No push, publishing or generated docs commit, as required by the common
   brief. Generated HTML and downloadable files remain in the temporary copy.
2. The local PDF uses a font fallback because Linux Libertine is unavailable;
   the existing CI font installation remains the production path.
3. Optional browser screenshot review was inconclusive: headless Chrome
   returned blank captures. No claim of desktop/mobile visual approval is
   made. HTML structure, result tables, accessible image text, extracted PDF
   content and ePub assets were checked successfully. The temporary local
   preview server was stopped.
4. Legacy R/ecom companion scripts and Part II are outside this job. The
   printable DBI PDF remains the R reference; the updated SQL reference is
   the rendered appendix. No browser SQL cells were added.
5. No unresolved content or navigation work and no decision needed from
   Aravind. A visual review in the normal browser/CI environment can follow
   during the book's existing publication review.

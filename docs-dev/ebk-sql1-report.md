# ebk-sql1 report

Worktree: `F:/R/ebooks/_worktrees/rdbsql-part1`.
Branch: `task/sql-part1`, based on `f49e37b`.
Local commits only; no push or GitHub operations.

## Delivered

- Split the book into **Part I: SQL** and **Part II: SQL from R**.
  Part I contains `sql-intro.qmd`, `sql-basics.qmd`, `sql-advanced.qmd`
  and `joins.qmd`, in that order. Outline slots 3, 5 and 7 are comments
  only. Part II contains DBI, dbplyr, production and DuckDB. The existing
  cheatsheet is the appendix.
- Updated the Preface with the structure, planned chapters and
  “R users who know SQL: start at Part II”. Added the shared course URL
  variable, `https://app.rsquaredacademy.com/`.
- Added chapter 1 and rewrote chapter 2 with SQL engine examples,
  learning objectives, common mistakes, five/six questions with answers
  in `<details>`, key points, next pointers and course practice links.
  Chapter 1 has a relationship diagram; chapter 2 has a precedence diagram.
- Moved the two R join sections from `joins.qmd` into `dbplyr.qmd`.
  Their original source text and chunks are unchanged. Added a lead-in
  and hidden setup that copies their original customers/orders tables
  into the existing dbplyr connection. Old section anchors in `joins.qmd`
  now hold pointers to Part II. DBI, production and DuckDB sources are
  byte-for-byte unchanged from the base commit.
- Built all five nycflights13 tables into a shared SQLite file. Each
  Part I chapter sources the same hidden setup, uses `connection=con`
  for SQL and closes the connection. The setup builds an absent file.
  The build reuses an existing file; deleting it triggers a clean rebuild.
- Migrated the existing chapter 4 and 6 examples and their companion
  solutions to flights so all Part I examples use that connection.
  Corrected the obsolete RSQLite RIGHT/FULL warning. These are data
  migrations, not the full outline rewrites of those two chapters.
- Updated contributor instructions, build dependencies and the slug
  checker for nested parts and Windows R. `roadmap/` remains ignored.

## Files changed

| Files | Purpose |
|:--|:--|
| `_quarto.yml`, `_variables.yml`, `index.qmd` | Parts, appendix, course URL and Preface |
| `sql-intro.qmd`, `sql-basics.qmd` | New/revised first two chapters |
| `img/sql-tables.svg`, `img/sql-precedence.svg` | Accessible vector diagrams shared by all book formats |
| `sql-advanced.qmd`, `joins.qmd` | Flight-data integration, preserved anchors and R-section pointers |
| `dbplyr.qmd` | Unchanged moved sections plus lead-in and connection setup |
| `scripts/build-db.R`, `scripts/sql-setup.R` | Database build and shared hidden setup |
| `scripts/verify-flights.R` | Source-data equality checks, SQL facts and runnable examples |
| `scripts/verify-slugs.sh` | Recursive parts and UTF-8-safe R fallback when yq is absent |
| `.gitignore` | Ignore the generated database |
| `.github/workflows/render.yml`, `.devcontainer/Dockerfile` | Add nycflights13 to render dependencies |
| `solutions/sql-advanced.md`, `solutions/joins.md` | Solutions matching the migrated exercises |
| `README.md` | Current structure, data/build instructions and legacy-script distinction |
| `docs-dev/ebk-sql1-report.md` | This report |

No changes to committed `docs/`, `_redirects`, other worktrees or Part II
chapter content outside the dbplyr insertion.

## Chapter word counts

Counts include headings, inline code, questions and prose answers. They
exclude fenced code/diagram blocks, HTML tags, link destinations and
anchor attributes. Words use Unicode word boundaries with internal
apostrophes/hyphens retained.

| Source | Prose words | Scope |
|:--|--:|:--|
| `sql-intro.qmd` | 1,386 | New chapter, approximately 1,500 words |
| `sql-basics.qmd` | 2,769 | Rewritten chapter, approximately 3,000 words |
| `sql-advanced.qmd` | 301 | Existing chapter migrated; full rewrite deferred |
| `joins.qmd` | 469 | Existing chapter migrated; full rewrite deferred |
| `dbplyr.qmd` | 501 | Includes the unchanged moved sections |

## Data and reproducibility

Verified with R 4.6.1, DBI 1.3.0, RSQLite 3.53.3 (bundled SQLite 3.53.3),
nycflights13 1.0.2 and knitr 1.52. Render used dbplyr 2.6.0.

| Table | Rows |
|:--|--:|
| airlines | 16 |
| airports | 1,458 |
| planes | 3,322 |
| weather | 26,115 |
| flights | 336,776 |

`scripts/verify-flights.R` compares every stored source column with the
installed package, including missing values. The two POSIXct `time_hour`
columns are deliberately converted to UTC ISO timestamp text in both
tables. Added `flight_date` is checked against the source year/month/day
for every flight. The build makes unique indexes for airline carrier,
airport FAA and aircraft tail number; flights receive no invented key.

`data/flights.sqlite` is 34,193,408 bytes, above the brief's 20 MB threshold,
and is ignored. A fresh archive render started without that file and
successfully generated it. Repeating the build preserved its modification
time. Data are from the CC0 [nycflights13 package](https://nycflights13.tidyverse.org/).
No course data are used in Part I.

## SQLite facts verified

The executable checks live in `scripts/verify-flights.R`. They run through
DBI/RSQLite, not Python's separately bundled SQLite.

| Fact | Check and observed result |
|:--|:--|
| Integer division | `SELECT 7 / 2` returns 3; `7 * 1.0 / 2` returns 3.5 |
| ASCII LIKE case folding | `'JetBlue' LIKE 'jet%'` returns 1 |
| Non-ASCII LIKE | `char(230) LIKE char(198)` returns 0 (lower/upper ae ligature) |
| Text equality and binary order | `'JFK' = 'jfk'` returns 0; `'JFK' < 'jfk'` returns 1 |
| Text numbers sort as text | `'10' < '9'` returns 1; reserved for future types coverage |
| Unquoted ISO dates are arithmetic | `2013-07-04` returns 2002 |
| BETWEEN is inclusive | Both 60 and 120 satisfy `BETWEEN 60 AND 120`; reversed bounds reject 90 |
| Consistent ISO date text compares in calendar order | July 4 satisfies the July 1–4 text range; date-filter examples execute |
| LIKE wildcards | `%Air%` matches `Air`; `_F_` matches `JFK` but not `JFKX`; `Air` alone does not match `Airways` |
| Operator precedence | `1 OR 0 AND 0` is 1; `(1 OR 0) AND 0` is 0; comparison/NOT/AND checks also pass |
| Alternatives on one column | No flight satisfies both `origin = 'JFK'` and `origin = 'LGA'` |
| NULL comparison | `dep_delay = NULL` finds zero rows; `IS NULL` finds missing delays |
| Default ascending sort | Implicit ASC and explicit ASC both begin with carriers 9E, AA, AS |
| NULL ordering | Ascending delay begins with NULL; descending delay begins with 1301 and ends with NULL |
| Missing SELECT comma | `SELECT carrier name` returns one column named `name`, containing the carrier code |
| SELECT column order | `SELECT name, carrier` returns those headings in that order |
| LIMIT is an upper bound | LIMIT 100 on airlines yields 16 rows; a nonmatching filter with LIMIT 5 yields zero |
| Written clause order | `LIMIT 5 ORDER BY carrier` raises an error |
| Unquoted text is interpreted as a name | `carrier = JFK` raises a missing-column error |
| RIGHT and FULL OUTER JOIN support | Both execute on the airline/flight key and retain 336,776 matching departures |
| Join key/cardinality claims | Airline inner join and plane left join each retain 336,776 flight rows |
| Weather row meaning and origin list | Grouping weather by origin/time_hour finds no duplicate keys; distinct flight origins are EWR, JFK and LGA |

SQLite's [3.39.0 release notes](https://www.sqlite.org/releaselog/3_39_0.html)
confirm when RIGHT/FULL support was introduced. The current bundled
version's behaviour was independently executed above.

All **59** SQL examples/solutions execute and return nonempty results:
chapter 1: 3; chapter 2: 25; chapter 4: 18; chapter 6: 7; companion
solutions: 6. Rendered tables come from knitr SQL chunks; no outputs are
pasted into the source.

## Render and link validation

Render summary: **HTML, PDF and ePub all pass** on the final sources.
The final command was:

```sh
bash ~/.claude/bin/heavy-slot.sh ebk-sql1 <portable-quarto> render --to all --output-dir stage-checked
```

Output is in the temporary copy's `stage-checked/`: 11 chapter/front-matter
HTML pages, a 1,738,694-byte `databases-and-sql.pdf` and a 927,005-byte
`databases-and-sql.epub`. The PDF header and size were checked; both
original SVG assets were verified byte-for-byte inside the ePub archive.
The final log has no missing-resource or callout errors. Typst warned
that Linux Libertine was unavailable locally and used its font fallback;
the existing CI already installs that font.

Rendering took place only in
`C:/Users/DELL/AppData/Local/Temp/ebk-sql1-render-a2cccaa555dd4f20ba48b6d02cf14e2a`,
created with `git archive HEAD`; later source/checker fixes were overlaid.
All render commands ran through `bash ~/.claude/bin/heavy-slot.sh ebk-sql1`.
The wrapper recognised the queue job and reused its already counted slot.

The system Quarto is 1.6.39. A portable Quarto 1.10.18 and temporary R
library supplied the required renderer/dbplyr without changing system
installations. Quarto was obtained from the authors' Chocolatey package;
the embedded ZIP's SHA-256 was
`4e824652ff0da3f646868277582ed59c0872d1456e35350b7d7cdc4243ee18c2`.
The bundled Typst 0.15.1 was added to the render process PATH.

An initial PDF attempt found Typst absent from PATH. After using the
bundled binary, the new Quarto callout failed with `unknown variable:
callout`. The common-mistakes box now uses a portable Markdown blockquote.
These fixes preserve the chapter content. Windows R emits pre-existing
`LC_*=C.UTF-8` startup warnings; the checks and SQL execution still run.
The slug checker's R fallback explicitly reads UTF-8 to avoid that
locale's input conversion failure and strips Windows carriage returns.

A combined-format render also exposed missing Mermaid PNG resources in
ePub. Both diagrams now use standalone SVGs with accessible titles,
descriptions and image alt text. Browser screenshots were inspected to
check their labels, arrows and layout. The SVGs avoid screenshot resources
and carry the same diagram into HTML, PDF and ePub.

Final gates, run from the temporary book root:

- `bash scripts/verify-slugs.sh stage-checked`: PASS, all 11 declared
  chapters/front-matter pages. This exercised the Windows R/yaml fallback;
  yq is absent on this machine.
- `bash scripts/test-redirects.sh stage-checked`: PASS, both existing
  redirect destinations exist.
- HTML parsing: PASS, all 16 original SQL Basics section anchors, seven
  SQL Advanced anchors and eight JOINs anchors remain. The old chapter
  anchors remain in source as well.
- HTML parsing: PASS, no unresolved `??` cross-references; chapter and
  moved-section fragment links resolve; course variables resolve to the
  supplied URL; chapter 1 has five `<details>` answers and chapter 2 six.
  Both diagram images have nonempty alt text.
- Final SQL verification: PASS, all 59 examples/solutions and data/fact
  checks; repeated database build reuses the existing file.
- Source comparison: PASS, unchanged moved sections and insertion-only
  dbplyr edit; DBI, production, DuckDB, appendix and committed `docs/`
  unchanged. `git diff --check` passes.

Source comparisons confirm that the moved sections are unchanged and the
rest of dbplyr matches the base source exactly. Chapter file names and
chapter anchors stay in place. No page redirects were needed; the two
existing redirect rules remain intact.

## Not done and follow-ups

1. **Full chapter 4 rewrite:** expand to the outline's approximately 2,800
   words, including COUNT(*) versus COUNT(column), missing values in
   aggregates, split/summarise/combine visual, HAVING versus WHERE,
   execution order, common mistakes, expandable answers and course footer.
   This job only migrated the existing material and supplied DISTINCT
   coverage needed by the chapter 2 pointer.
2. **Full chapter 6 rewrite:** expand to approximately 2,800 words with
   the row-by-row join visual, key explanations, Venn-diagram limitations,
   common mistakes, expandable answers and course footer. Current examples
   are real flights/airlines/planes queries, not the old customers/orders.
3. **Outline chapters 3, 5 and 7:** write them in separate jobs. They remain
   comments, with no empty files or broken navigation entries. Quarto numbers
   the currently present chapters consecutively; outline numbers 4 and 6
   are reserved by comments and will align after the intervening chapters
   are added.
4. **Appendix:** the existing DBI cheatsheet was moved to the appendix
   unchanged. The outline's SQL clause/function/NULL cheatsheet needs a
   separate content pass.
5. **Legacy scripts and SQL Basics solutions:** `code/ch3-sqlbasics.R`,
   `code/ch4-sqladvanced.R`, `code/ch5-joins.R` and
   `solutions/sql-basics.md` still describe the previous ecom examples.
   README identifies them as legacy. Decide in a later code-companion
   job whether to migrate them or keep clearly labelled R examples.
   The rewritten chapter 2 answers are inline and do not link to the
   old solution file.
6. **Interactive browser cells:** not implemented. Chapter 1 explicitly
   says the book currently shows static rendered examples, provides local
   DB Browser/R instructions and links to browser practice in the course.
7. **Part II data refresh:** deliberately not performed. Its existing
   ecom examples and optional external-database/DuckDB examples remain.
   DuckDB and production chunks already marked `eval=FALSE` remain so.
8. **Publishing:** no push or deployment. Generated site/downloads remain
   in the temporary render copy; committed `docs/` is untouched.

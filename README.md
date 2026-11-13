# R, Databases & SQL

![Cover](img/rdbsql.png)

Learn SQL with public flight data, then use databases from R with DBI and
dbplyr. R users who know SQL can start at Part II.

📖 **Read the book:** https://rdbsql.rsquaredacademy.com

[![Launch in Posit Cloud](https://img.shields.io/badge/Posit_Cloud-Launch-blue)](https://posit.cloud/content/430439)
[![Open in Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/rsquaredacademy-publications/rdbsql)

## Syllabus

| Part | Chapter | You will learn |
|:--|:--|:--|
| I: SQL | Databases, tables and queries | Tables, keys, queries, flight data and local setup |
| I | Selecting, sorting and filtering | `SELECT`, `LIMIT`, `ORDER BY`, `WHERE`, logical conditions, `IN`, `BETWEEN`, `LIKE` |
| I | Summaries and groups | Aggregates, aliases, distinct values and groups |
| I | Joining two tables | Matching keys, inner and left joins, SQLite version support |
| II: SQL from R | DBI | Connections, queries, fetching and writing data |
| II | dbplyr | Lazy queries, collecting results, joins and filtering joins |
| II | Production R Patterns | Credentials, parameters, transactions and pooling |
| II | DuckDB + Parquet | Querying analytical data and files |
| Appendix | DBI Cheat Sheet | One-page R command reference |

Part I outline slots 3, 5 and 7 are comments only until those chapters are
written. The Part I chapters (1, 2, 4 and 6) include expandable exercise
answers; Part II exercise solutions live in [`solutions/`](solutions/).

Part I SQL chunks use `data/flights.sqlite`, built locally from the CC0
**nycflights13** package. The generated file is over 20 MB and is ignored by
Git. Install `nycflights13`, `DBI` and `RSQLite`, then run
`Rscript scripts/build-db.R` from the book root. A Part I render also builds
the file if absent. The build adds ISO `flight_date` text to `flights` and
stores `time_hour` as UTC text in both tables that contain it.

Part II keeps its existing data. The scripts in [`code/`](code/) retain
the earlier R/ecom examples, including legacy SQL scripts; they are not
the source for the new Part I chapters. `solutions/sql-basics.md` likewise
retains the earlier ecom exercises; use the answers in `sql-basics.qmd`
for the rewritten chapter.

## Zero-setup environments

- **Tier 0 (primary):** Posit Cloud project — 1-click RStudio in the browser (link above; clone this repo via New Project → From Git URL).
- **Alternative:** GitHub Codespaces — click the badge above; the `.devcontainer` boots R 4.4.2 + Quarto + packages automatically.
- **Local:** R (4.4+) + RSQLite + Quarto CLI 1.10.18+. Part I also needs nycflights13; Part II uses the packages named in its chapters.

## Develop

```bash
Rscript scripts/build-db.R         # create/reuse the Part I database
Rscript scripts/verify-flights.R   # check source data, SQLite facts and SQL examples
Rscript scripts/verify.R           # run the legacy code/*.R examples
```

CI renders HTML, Typst PDF, and ePub and deploys `docs/` via GitHub Pages. `master` is the production branch.
For this restructure, render only in a temporary copy outside the worktree
created with `git archive HEAD` plus any uncommitted changes. Run renders
through `bash ~/.claude/bin/heavy-slot.sh ebk-sql1 <command>` so local checks
share the build limit. Rendering in the worktree rewrites the CI-owned `docs/`.

## License

CC BY-NC-SA 4.0.

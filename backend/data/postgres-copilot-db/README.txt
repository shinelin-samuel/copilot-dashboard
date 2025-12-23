Postgres Sakila conversion notes:

- `postgres-sakila-schema.sql` creates the Postgres-compatible schema (tables, indexes, triggers, views).
- `postgres-sakila-drop-objects.sql` drops views, triggers, tables and the trigger function.
- `postgres-sakila-delete-data.sql` truncates all Sakila tables (use with care).
- `postgres-sakila-insert-data.sql` contains a placeholder and short example inserts.

- To migrate actual data from `backend/data/sqlite-sakila.db` use:
  - `backend/scripts/migrate_sakila.py` (ships with the project) OR
  - `pgloader` to import the sqlite DB into the Postgres database:
      pgloader sqlite:///path/to/sqlite-sakila.db postgresql://user:pass@host:port/dbname

- Recommended workflow:
  1) Create database (e.g. `copilot`) in Postgres.
  2) Run `psql -d copilot -f postgres-copilot-db/postgres-sakila-schema.sql` to create schema.
  3) Use the migration script or pgloader to populate data.


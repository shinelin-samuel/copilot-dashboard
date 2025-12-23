-- postgres-copilot-db/postgres-sakila-delete-data.sql
/*
Truncate all Sakila tables (preserves schema). Use with caution.
*/

BEGIN;
TRUNCATE TABLE payment, rental, inventory, film_text, film_category, film_actor, film,
               customer, store, staff, address, city, country, category, language, actor
RESTART IDENTITY CASCADE;
COMMIT;


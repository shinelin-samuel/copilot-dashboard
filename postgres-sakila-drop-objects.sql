-- postgres-copilot-db/postgres-sakila-drop-objects.sql
/*
Drops views, triggers, trigger function, and tables in an order that avoids FK conflicts.
*/

BEGIN;
-- Drop views
DROP VIEW IF EXISTS sales_by_film_category CASCADE;
DROP VIEW IF EXISTS sales_by_store CASCADE;
DROP VIEW IF EXISTS staff_list CASCADE;
DROP VIEW IF EXISTS film_list CASCADE;
DROP VIEW IF EXISTS customer_list CASCADE;

-- Drop triggers (they are per-table)
DROP TRIGGER IF EXISTS actor_trigger_biu ON actor;
DROP TRIGGER IF EXISTS country_trigger_biu ON country;
DROP TRIGGER IF EXISTS city_trigger_biu ON city;
DROP TRIGGER IF EXISTS address_trigger_biu ON address;
DROP TRIGGER IF EXISTS language_trigger_biu ON language;
DROP TRIGGER IF EXISTS category_trigger_biu ON category;
DROP TRIGGER IF EXISTS store_trigger_biu ON store;
DROP TRIGGER IF EXISTS customer_trigger_biu ON customer;
DROP TRIGGER IF EXISTS film_trigger_biu ON film;
DROP TRIGGER IF EXISTS film_actor_trigger_biu ON film_actor;
DROP TRIGGER IF EXISTS film_category_trigger_biu ON film_category;
DROP TRIGGER IF EXISTS inventory_trigger_biu ON inventory;
DROP TRIGGER IF EXISTS staff_trigger_biu ON staff;
DROP TRIGGER IF EXISTS payment_trigger_biu ON payment;
DROP TRIGGER IF EXISTS rental_trigger_biu ON rental;

-- Drop tables (drop in order to avoid FK conflicts)
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS rental CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS film_text CASCADE;
DROP TABLE IF EXISTS film_category CASCADE;
DROP TABLE IF EXISTS film_actor CASCADE;
DROP TABLE IF EXISTS film CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS store CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS address CASCADE;
DROP TABLE IF EXISTS city CASCADE;
DROP TABLE IF EXISTS country CASCADE;
DROP TABLE IF EXISTS category CASCADE;
DROP TABLE IF EXISTS language CASCADE;
DROP TABLE IF EXISTS actor CASCADE;

-- Drop trigger function
DROP FUNCTION IF EXISTS set_last_update() CASCADE;
COMMIT;


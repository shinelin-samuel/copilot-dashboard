-- postgres-copilot-db/postgres-sakila-schema.sql
/*
Postgres-compatible schema for Sakila (converted from sqlite-sakila-schema.sql).
Creates tables, indexes, constraints, trigger function to set last_update, and views.
This file is intended to be run against the target database (for example: copilot).
*/

BEGIN;

-- Reusable trigger function to set last_update
CREATE OR REPLACE FUNCTION set_last_update()
RETURNS trigger AS $$
BEGIN
  NEW.last_update := CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- actor
CREATE TABLE IF NOT EXISTS actor (
  actor_id integer NOT NULL,
  first_name varchar(45) NOT NULL,
  last_name varchar(45) NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (actor_id)
);
CREATE INDEX IF NOT EXISTS idx_actor_last_name ON actor(last_name);
DROP TRIGGER IF EXISTS actor_trigger_biu ON actor;
CREATE TRIGGER actor_trigger_biu
    BEFORE INSERT OR UPDATE ON actor
    FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- country
CREATE TABLE IF NOT EXISTS country (
  country_id smallint NOT NULL,
  country varchar(50) NOT NULL,
  last_update timestamp WITHOUT time zone,
  PRIMARY KEY (country_id)
);
-- replace CREATE TRIGGER IF NOT EXISTS with DROP + CREATE
DROP TRIGGER IF EXISTS country_trigger_biu ON country;
CREATE TRIGGER country_trigger_biu
  BEFORE INSERT OR UPDATE ON country
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- city
CREATE TABLE IF NOT EXISTS city (
  city_id integer NOT NULL,
  city varchar(50) NOT NULL,
  country_id smallint NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (city_id),
  CONSTRAINT fk_city_country FOREIGN KEY (country_id) REFERENCES country (country_id) ON DELETE NO ACTION ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_fk_country_id ON city(country_id);
DROP TRIGGER IF EXISTS city_trigger_biu ON city;
CREATE TRIGGER city_trigger_biu BEFORE INSERT OR UPDATE ON city
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- address
CREATE TABLE IF NOT EXISTS address (
  address_id integer NOT NULL,
  address varchar(50) NOT NULL,
  address2 varchar(50),
  district varchar(20) NOT NULL,
  city_id integer NOT NULL,
  postal_code varchar(10),
  phone varchar(20) NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (address_id),
  CONSTRAINT fk_address_city FOREIGN KEY (city_id) REFERENCES city (city_id) ON DELETE NO ACTION ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_fk_city_id ON address(city_id);
DROP TRIGGER IF EXISTS address_trigger_biu ON address;
CREATE TRIGGER address_trigger_biu BEFORE INSERT OR UPDATE ON address
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- language
CREATE TABLE IF NOT EXISTS language (
  language_id smallint NOT NULL,
  name char(20) NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (language_id)
);
DROP TRIGGER IF EXISTS language_trigger_biu ON language;
CREATE TRIGGER language_trigger_biu BEFORE INSERT OR UPDATE ON language
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- category
CREATE TABLE IF NOT EXISTS category (
  category_id smallint NOT NULL,
  name varchar(25) NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (category_id)
);
DROP TRIGGER IF EXISTS category_trigger_biu ON category;
CREATE TRIGGER category_trigger_biu BEFORE INSERT OR UPDATE ON category
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- staff (created before store because store FK references staff in some schemas)
CREATE TABLE IF NOT EXISTS staff (
  staff_id smallint NOT NULL,
  first_name varchar(45) NOT NULL,
  last_name varchar(45) NOT NULL,
  address_id integer NOT NULL,
  picture bytea,
  email varchar(50),
  store_id integer NOT NULL,
  active smallint DEFAULT 1 NOT NULL,
  username varchar(16) NOT NULL,
  password varchar(40),
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (staff_id)
);
CREATE INDEX IF NOT EXISTS idx_fk_staff_store_id ON staff(store_id);
CREATE INDEX IF NOT EXISTS idx_fk_staff_address_id ON staff(address_id);
DROP TRIGGER IF EXISTS staff_trigger_biu ON staff;
CREATE TRIGGER staff_trigger_biu BEFORE INSERT OR UPDATE ON staff
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- store
CREATE TABLE IF NOT EXISTS store (
  store_id integer NOT NULL,
  manager_staff_id smallint NOT NULL,
  address_id integer NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (store_id),
  CONSTRAINT fk_store_staff FOREIGN KEY (manager_staff_id) REFERENCES staff (staff_id) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT fk_store_address FOREIGN KEY (address_id) REFERENCES address (address_id) ON DELETE NO ACTION ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_store_fk_manager_staff_id ON store(manager_staff_id);
CREATE INDEX IF NOT EXISTS idx_fk_store_address ON store(address_id);
DROP TRIGGER IF EXISTS store_trigger_biu ON store;
CREATE TRIGGER store_trigger_biu BEFORE INSERT OR UPDATE ON store
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- customer
CREATE TABLE IF NOT EXISTS customer (
  customer_id integer NOT NULL,
  store_id integer NOT NULL,
  first_name varchar(45) NOT NULL,
  last_name varchar(45) NOT NULL,
  email varchar(50),
  address_id integer NOT NULL,
  active char(1) DEFAULT 'Y' NOT NULL,
  create_date timestamp WITHOUT time zone NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (customer_id),
  CONSTRAINT fk_customer_store FOREIGN KEY (store_id) REFERENCES store (store_id) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT fk_customer_address FOREIGN KEY (address_id) REFERENCES address (address_id) ON DELETE NO ACTION ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_customer_fk_store_id ON customer(store_id);
CREATE INDEX IF NOT EXISTS idx_customer_fk_address_id ON customer(address_id);
CREATE INDEX IF NOT EXISTS idx_customer_last_name ON customer(last_name);
DROP TRIGGER IF EXISTS customer_trigger_biu ON customer;
CREATE TRIGGER customer_trigger_biu BEFORE INSERT OR UPDATE ON customer
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- film
CREATE TABLE IF NOT EXISTS film (
  film_id integer NOT NULL,
  title varchar(255) NOT NULL,
  description text,
  release_year varchar(4),
  language_id smallint NOT NULL,
  original_language_id smallint,
  rental_duration smallint DEFAULT 3 NOT NULL,
  rental_rate numeric(4,2) DEFAULT 4.99 NOT NULL,
  length smallint,
  replacement_cost numeric(5,2) DEFAULT 19.99 NOT NULL,
  rating varchar(10) DEFAULT 'G',
  special_features varchar(100),
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (film_id),
  CONSTRAINT fk_film_language FOREIGN KEY (language_id) REFERENCES language (language_id),
  CONSTRAINT fk_film_language_original FOREIGN KEY (original_language_id) REFERENCES language (language_id)
);
CREATE INDEX IF NOT EXISTS idx_fk_language_id ON film(language_id);
CREATE INDEX IF NOT EXISTS idx_fk_original_language_id ON film(original_language_id);
DROP TRIGGER IF EXISTS film_trigger_biu ON film;
CREATE TRIGGER film_trigger_biu BEFORE INSERT OR UPDATE ON film
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- film_actor
CREATE TABLE IF NOT EXISTS film_actor (
  actor_id integer NOT NULL,
  film_id integer NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (actor_id, film_id),
  CONSTRAINT fk_film_actor_actor FOREIGN KEY (actor_id) REFERENCES actor (actor_id) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT fk_film_actor_film FOREIGN KEY (film_id) REFERENCES film (film_id) ON DELETE NO ACTION ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_fk_film_actor_film ON film_actor(film_id);
CREATE INDEX IF NOT EXISTS idx_fk_film_actor_actor ON film_actor(actor_id);
DROP TRIGGER IF EXISTS film_actor_trigger_biu ON film_actor;
CREATE TRIGGER film_actor_trigger_biu BEFORE INSERT OR UPDATE ON film_actor
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- film_category
CREATE TABLE IF NOT EXISTS film_category (
  film_id integer NOT NULL,
  category_id smallint NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (film_id, category_id),
  CONSTRAINT fk_film_category_film FOREIGN KEY (film_id) REFERENCES film (film_id) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT fk_film_category_category FOREIGN KEY (category_id) REFERENCES category (category_id) ON DELETE NO ACTION ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_fk_film_category_film ON film_category(film_id);
CREATE INDEX IF NOT EXISTS idx_fk_film_category_category ON film_category(category_id);
DROP TRIGGER IF EXISTS film_category_trigger_biu ON film_category;
CREATE TRIGGER film_category_trigger_biu BEFORE INSERT OR UPDATE ON film_category
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- film_text
CREATE TABLE IF NOT EXISTS film_text (
  film_id smallint NOT NULL,
  title varchar(255) NOT NULL,
  description text,
  PRIMARY KEY (film_id)
);

-- inventory
CREATE TABLE IF NOT EXISTS inventory (
  inventory_id integer NOT NULL,
  film_id integer NOT NULL,
  store_id integer NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (inventory_id),
  CONSTRAINT fk_inventory_store FOREIGN KEY (store_id) REFERENCES store (store_id) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT fk_inventory_film FOREIGN KEY (film_id) REFERENCES film (film_id) ON DELETE NO ACTION ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_fk_film_id ON inventory(film_id);
CREATE INDEX IF NOT EXISTS idx_fk_film_id_store_id ON inventory(store_id,film_id);
DROP TRIGGER IF EXISTS inventory_trigger_biu ON inventory;
CREATE TRIGGER inventory_trigger_biu BEFORE INSERT OR UPDATE ON inventory
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- payment and rental are created after rental table exists to satisfy FK order
CREATE TABLE IF NOT EXISTS payment (
  payment_id integer NOT NULL,
  customer_id integer NOT NULL,
  staff_id smallint NOT NULL,
  rental_id integer,
  amount numeric(5,2) NOT NULL,
  payment_date timestamp WITHOUT time zone NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (payment_id)
);
CREATE INDEX IF NOT EXISTS idx_fk_staff_id ON payment(staff_id);
CREATE INDEX IF NOT EXISTS idx_fk_customer_id ON payment(customer_id);
DROP TRIGGER IF EXISTS payment_trigger_biu ON payment;
CREATE TRIGGER payment_trigger_biu BEFORE INSERT OR UPDATE ON payment
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

CREATE TABLE IF NOT EXISTS rental (
  rental_id integer NOT NULL,
  rental_date timestamp WITHOUT time zone NOT NULL,
  inventory_id integer NOT NULL,
  customer_id integer NOT NULL,
  return_date timestamp WITHOUT time zone,
  staff_id smallint NOT NULL,
  last_update timestamp WITHOUT time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (rental_id)
);
CREATE INDEX IF NOT EXISTS idx_rental_fk_inventory_id ON rental(inventory_id);
CREATE INDEX IF NOT EXISTS idx_rental_fk_customer_id ON rental(customer_id);
CREATE INDEX IF NOT EXISTS idx_rental_fk_staff_id ON rental(staff_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_rental_uq ON rental (rental_date, inventory_id, customer_id);
DROP TRIGGER IF EXISTS rental_trigger_biu ON rental;
CREATE TRIGGER rental_trigger_biu BEFORE INSERT OR UPDATE ON rental
  FOR EACH ROW EXECUTE FUNCTION set_last_update();

-- staff/store/payment/rental foreign keys applied after tables exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_store_staff') THEN
    EXECUTE 'ALTER TABLE store ADD CONSTRAINT fk_store_staff FOREIGN KEY (manager_staff_id) REFERENCES staff (staff_id) ON DELETE NO ACTION ON UPDATE CASCADE';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_store_address') THEN
    EXECUTE 'ALTER TABLE store ADD CONSTRAINT fk_store_address FOREIGN KEY (address_id) REFERENCES address (address_id) ON DELETE NO ACTION ON UPDATE CASCADE';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_customer_store') THEN
    EXECUTE 'ALTER TABLE customer ADD CONSTRAINT fk_customer_store FOREIGN KEY (store_id) REFERENCES store (store_id) ON DELETE NO ACTION ON UPDATE CASCADE';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_customer_address') THEN
    EXECUTE 'ALTER TABLE customer ADD CONSTRAINT fk_customer_address FOREIGN KEY (address_id) REFERENCES address (address_id) ON DELETE NO ACTION ON UPDATE CASCADE';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_inventory_store') THEN
    EXECUTE 'ALTER TABLE inventory ADD CONSTRAINT fk_inventory_store FOREIGN KEY (store_id) REFERENCES store (store_id) ON DELETE NO ACTION ON UPDATE CASCADE';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_inventory_film') THEN
    EXECUTE 'ALTER TABLE inventory ADD CONSTRAINT fk_inventory_film FOREIGN KEY (film_id) REFERENCES film (film_id) ON DELETE NO ACTION ON UPDATE CASCADE';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_payment_rental') THEN
    EXECUTE 'ALTER TABLE payment ADD CONSTRAINT fk_payment_rental FOREIGN KEY (rental_id) REFERENCES rental (rental_id) ON DELETE SET NULL ON UPDATE CASCADE';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_payment_customer') THEN
    EXECUTE 'ALTER TABLE payment ADD CONSTRAINT fk_payment_customer FOREIGN KEY (customer_id) REFERENCES customer (customer_id)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_payment_staff') THEN
    EXECUTE 'ALTER TABLE payment ADD CONSTRAINT fk_payment_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_rental_staff') THEN
    EXECUTE 'ALTER TABLE rental ADD CONSTRAINT fk_rental_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_rental_inventory') THEN
    EXECUTE 'ALTER TABLE rental ADD CONSTRAINT fk_rental_inventory FOREIGN KEY (inventory_id) REFERENCES inventory (inventory_id)';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_rental_customer') THEN
    EXECUTE 'ALTER TABLE rental ADD CONSTRAINT fk_rental_customer FOREIGN KEY (customer_id) REFERENCES customer (customer_id)';
  END IF;
END;
$$;

-- views
CREATE OR REPLACE VIEW customer_list AS
SELECT cu.customer_id AS ID,
       cu.first_name || ' ' || cu.last_name AS name,
       a.address AS address,
       a.postal_code AS zip_code,
       a.phone AS phone,
       city.city AS city,
       country.country AS country,
       CASE WHEN cu.active = 'Y' THEN 'active' ELSE '' END AS notes,
       cu.store_id AS SID
FROM customer AS cu
JOIN address AS a ON cu.address_id = a.address_id
JOIN city ON a.city_id = city.city_id
JOIN country ON city.country_id = country.country_id;

CREATE OR REPLACE VIEW film_list AS
SELECT f.film_id AS FID,
       f.title AS title,
       f.description AS description,
       c.name AS category,
       f.rental_rate AS price,
       f.length AS length,
       f.rating AS rating,
       (SELECT string_agg(a.first_name || ' ' || a.last_name, ', ') FROM actor a JOIN film_actor fa ON a.actor_id = fa.actor_id WHERE fa.film_id = f.film_id) AS actors
FROM film f
LEFT JOIN film_category fc ON f.film_id = fc.film_id
LEFT JOIN category c ON fc.category_id = c.category_id;

CREATE OR REPLACE VIEW staff_list AS
SELECT s.staff_id AS ID,
       s.first_name || ' ' || s.last_name AS name,
       a.address AS address,
       a.postal_code AS zip_code,
       a.phone AS phone,
       city.city AS city,
       country.country AS country,
       s.store_id AS SID
FROM staff AS s
JOIN address AS a ON s.address_id = a.address_id
JOIN city ON a.city_id = city.city_id
JOIN country ON city.country_id = country.country_id;

CREATE OR REPLACE VIEW sales_by_store AS
SELECT
  s.store_id,
  c.city || ',' || cy.country AS store,
  m.first_name || ' ' || m.last_name AS manager,
  SUM(p.amount) AS total_sales
FROM payment AS p
INNER JOIN rental AS r ON p.rental_id = r.rental_id
INNER JOIN inventory AS i ON r.inventory_id = i.inventory_id
INNER JOIN store AS s ON i.store_id = s.store_id
INNER JOIN address AS a ON s.address_id = a.address_id
INNER JOIN city AS c ON a.city_id = c.city_id
INNER JOIN country AS cy ON c.country_id = cy.country_id
INNER JOIN staff AS m ON s.manager_staff_id = m.staff_id
GROUP BY s.store_id, c.city || ',' || cy.country, m.first_name || ' ' || m.last_name;

CREATE OR REPLACE VIEW sales_by_film_category AS
SELECT
  c.name AS category,
  SUM(p.amount) AS total_sales
FROM payment AS p
INNER JOIN rental AS r ON p.rental_id = r.rental_id
INNER JOIN inventory AS i ON r.inventory_id = i.inventory_id
INNER JOIN film AS f ON i.film_id = f.film_id
INNER JOIN film_category AS fc ON f.film_id = fc.film_id
INNER JOIN category AS c ON fc.category_id = c.category_id
GROUP BY c.name;

COMMIT;


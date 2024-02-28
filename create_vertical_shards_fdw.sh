#!/bin/bash

POSTGRES_NODE1_HOST=postgres_node1
POSTGRES_NODE1_USER=postgresnode1user
POSTGRES_NODE1_DB=sharding

# Create and fill book_categories table

create_table_categories_stmt="\
  CREATE TABLE IF NOT EXISTS book_categories (\
    category_id integer NOT NULL, \
    category_name varchar(100), \
    CONSTRAINT book_categories_pk PRIMARY KEY (category_id)\
  );\
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$create_table_categories_stmt"

fill_table_categories_stmt="\
  INSERT INTO book_categories VALUES \
                              (1, 'Fiction'), \
                              (2, 'Non-fiction'), \
                              (3, 'Horror'), \
                              (4, 'Fantasy'), \
                              (5, 'Biography'), \
                              (6, 'Thriller'), \
                              (7, 'Romance'), \
                              (8, 'Science'), \
                              (9, 'Poetry'), \
                              (10, 'Romance') \
  ;\
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$fill_table_categories_stmt"

# Create books table for rules and relations

create_table_books_stmt="\
  CREATE TABLE IF NOT EXISTS books ( \
    id SERIAL NOT NULL, \
    title varchar(100) NOT NULL, \
    category_id integer NOT NULL, \
    author character varying(100) not null, \
    year integer not null \
  ) PARTITION BY RANGE (category_id); \
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$create_table_books_stmt"

# Create books_1_4 table for storing books with category_id >= 1 and <= 4

create_table_books_1_4_stmt="\
  CREATE TABLE IF NOT EXISTS books_1_4 \
  PARTITION OF books \
  FOR VALUES FROM (1) TO (5); \
  \
  ALTER TABLE books_1_4 ADD PRIMARY KEY (id);
  ALTER TABLE books_1_4 ADD CONSTRAINT books_1_4_category_id_check CHECK (category_id >= 1 AND category_id <= 4);
  ALTER TABLE books_1_4 ADD CONSTRAINT books_1_4_category_id_fk FOREIGN KEY (category_id) REFERENCES book_categories (category_id);
  CREATE INDEX IF NOT EXISTS books_1_4_category_id_idx ON books_1_4 USING btree (category_id); \
  CREATE INDEX IF NOT EXISTS books_1_4_year_idx ON books_1_4 USING btree (year); \
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$create_table_books_1_4_stmt"

# Create books_5_7 table for storing books with category_id >= 5 and <= 7

create_table_books_5_7_stmt="\
  CREATE TABLE IF NOT EXISTS books_5_7 \
  PARTITION OF books \
  FOR VALUES FROM (5) TO (8); \
  \
  ALTER TABLE books_5_7 ADD PRIMARY KEY (id);
  ALTER TABLE books_5_7 ADD CONSTRAINT books_5_7_category_id_check CHECK (category_id >= 5 AND category_id <= 7);
  ALTER TABLE books_5_7 ADD CONSTRAINT books_5_7_category_id_fk FOREIGN KEY (category_id) REFERENCES book_categories (category_id);
  CREATE INDEX IF NOT EXISTS books_5_7_category_id_idx ON books_5_7 USING btree (category_id); \
  CREATE INDEX IF NOT EXISTS books_5_7_year_idx ON books_5_7 USING btree (year); \
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$create_table_books_5_7_stmt"

# Create books_5_7 table for storing books with category_id >= 5 and <= 7

create_table_books_8_10_stmt="\
  CREATE TABLE IF NOT EXISTS books_8_10 \
  PARTITION OF books \
  FOR VALUES FROM (8) TO (11); \
  \
  ALTER TABLE books_8_10 ADD PRIMARY KEY (id);
  ALTER TABLE books_8_10 ADD CONSTRAINT books_8_10_category_id_check CHECK (category_id >= 8 AND category_id <= 10);
  ALTER TABLE books_8_10 ADD CONSTRAINT books_8_10_category_id_fk FOREIGN KEY (category_id) REFERENCES book_categories (category_id);
  CREATE INDEX IF NOT EXISTS books_8_10_category_id_idx ON books_8_10 USING btree (category_id); \
  CREATE INDEX IF NOT EXISTS books_8_10_year_idx ON books_8_10 USING btree (year); \
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$create_table_books_8_10_stmt"

# Create rules on books on nothing

create_nothing_rules_stmt="\
  CREATE RULE books_insert_nothing AS \
    ON INSERT TO books \
    DO INSTEAD NOTHING; \
  \
  CREATE RULE books_updae_nothing AS \
    ON UPDATE TO books \
    DO INSTEAD NOTHING; \
  \
  CREATE RULE books_delete_nothing AS \
    ON DELETE TO books \
    DO INSTEAD NOTHING; \
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$create_nothing_rules_stmt"

# Create rules on books on insert

create_insert_rules_stmt="\
  CREATE RULE books_insert_books AS \
    ON INSERT TO books \
      WHERE (category_id >= 1 AND category_id <= 4) \
    DO INSTEAD \
      INSERT INTO books_1_4 VALUES (NEW.*); \
  \
  CREATE RULE books_insert_books_5_7 AS \
    ON INSERT TO books \
      WHERE (category_id >= 5 AND category_id <= 7) \
    DO INSTEAD \
      INSERT INTO books_5_7 VALUES (NEW.*); \
  \
  CREATE RULE books_insert_books_8_10 AS \
    ON INSERT TO books \
      WHERE (category_id >= 8 AND category_id <= 10) \
    DO INSTEAD \
      INSERT INTO books_8_10 VALUES (NEW.*);
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$create_insert_rules_stmt"

# Create rules on books on update

create_update_rules_stmt="\
  CREATE RULE books_update_books_1_4_to_1_4 AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 1 AND NEW.category_id <= 4 AND OLD.category_id >= 1 AND OLD.category_id <= 4) \
    DO INSTEAD ( \
      UPDATE books_1_4 SET \
        id = NEW.id, \
        title = NEW.title, \
        category_id = NEW.category_id, \
        author = NEW.author, \
        year = NEW.year \
      WHERE id = OLD.id; \
    ); \
  \
  CREATE RULE books_update_books_5_7_to_1_4_insert AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 1 AND NEW.category_id <= 4 AND OLD.category_id >= 5 AND OLD.category_id <= 7) \
    DO INSTEAD ( \
      INSERT INTO books_1_4 VALUES (NEW.*); \
    ); \
  \
  CREATE RULE books_update_books_5_7_to_1_4_delete AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 1 AND NEW.category_id <= 4 AND OLD.category_id >= 5 AND OLD.category_id <= 7) \
    DO INSTEAD ( \
      DELETE FROM books_5_7 WHERE id = OLD.id; \
    ); \
  \
  CREATE RULE books_update_books_8_10_to_1_4_insert AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 1 AND NEW.category_id <= 4 AND OLD.category_id >= 8 AND OLD.category_id <= 10) \
    DO INSTEAD ( \
      INSERT INTO books_1_4 VALUES (NEW.*); \
    ); \
  \
  CREATE RULE books_update_books_8_10_to_1_4_delete AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 1 AND NEW.category_id <= 4 AND OLD.category_id >= 8 AND OLD.category_id <= 10) \
    DO INSTEAD ( \
      DELETE FROM books_8_10 WHERE id = OLD.id; \
    ); \
  \
  CREATE RULE books_update_books_5_7_to_5_7 AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 5 AND NEW.category_id <= 7 AND OLD.category_id >= 5 AND OLD.category_id <= 7) \
    DO INSTEAD ( \
      UPDATE books_5_7 SET \
        id = NEW.id, \
        title = NEW.title, \
        category_id = NEW.category_id, \
        author = NEW.author, \
        year = NEW.year \
      WHERE id = OLD.id; \
    ); \
  \
  CREATE RULE books_update_books_1_4_to_5_7_insert AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 5 AND NEW.category_id <= 7 AND OLD.category_id >= 1 AND OLD.category_id <= 4) \
    DO INSTEAD ( \
      INSERT INTO books_5_7 VALUES (NEW.*); \
    ); \
  \
  CREATE RULE books_update_books_1_4_to_5_7_delete AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 5 AND NEW.category_id <= 7 AND OLD.category_id >= 1 AND OLD.category_id <= 4) \
    DO INSTEAD ( \
      DELETE FROM books_1_4 WHERE id = OLD.id; \
    ); \
  \
  CREATE RULE books_update_books_8_10_to_5_7_insert AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 5 AND NEW.category_id <= 7 AND OLD.category_id >= 8 AND OLD.category_id <= 10) \
    DO INSTEAD ( \
      INSERT INTO books_5_7 VALUES (NEW.*); \
    ); \
  \
  CREATE RULE books_update_books_8_10_to_5_7_delete AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 5 AND NEW.category_id <= 7 AND OLD.category_id >= 8 AND OLD.category_id <= 10) \
    DO INSTEAD ( \
      DELETE FROM books_8_10 WHERE id = OLD.id; \
    ); \
  \
  CREATE RULE books_update_books_8_10_to_8_10 AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 8 AND NEW.category_id <= 10 AND OLD.category_id >= 8 AND OLD.category_id <= 10) \
    DO INSTEAD ( \
      UPDATE books_8_10 SET \
        id = NEW.id, \
        title = NEW.title, \
        category_id = NEW.category_id, \
        author = NEW.author, \
        year = NEW.year \
      WHERE id = OLD.id; \
    ); \
  \
  CREATE RULE books_update_books_1_4_to_8_10_insert AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 8 AND NEW.category_id <= 10 AND OLD.category_id >= 1 AND OLD.category_id <= 4) \
    DO INSTEAD ( \
      INSERT INTO books_8_10 VALUES (NEW.*); \
    ); \
  \
  CREATE RULE books_update_books_1_4_to_8_10_delete AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 8 AND NEW.category_id <= 10 AND OLD.category_id >= 1 AND OLD.category_id <= 4) \
    DO INSTEAD ( \
      DELETE FROM books_1_4 WHERE id = OLD.id; \
    ); \
  \
  CREATE RULE books_update_books_5_7_to_8_10_insert AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 8 AND NEW.category_id <= 10 AND OLD.category_id >= 5 AND OLD.category_id <= 7) \
    DO INSTEAD ( \
      INSERT INTO books_8_10 VALUES (NEW.*); \
    ); \
  \
  CREATE RULE books_update_books_5_7_to_8_10_delete AS \
    ON UPDATE TO books \
      WHERE (NEW.category_id >= 8 AND NEW.category_id <= 10 AND OLD.category_id >= 5 AND OLD.category_id <= 7) \
    DO INSTEAD ( \
      DELETE FROM books_5_7 WHERE id = OLD.id; \
    ); \
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$create_update_rules_stmt"

# Create rules on books on delete

create_delete_rules_stmt="\
  CREATE RULE books_delete_books AS \
    ON DELETE TO books \
      WHERE (category_id >= 1 AND category_id <= 4) \
    DO INSTEAD \
      DELETE FROM books_1_4 WHERE id = OLD.id; \
  \
  CREATE RULE books_delete_books_5_7 AS \
    ON DELETE TO books \
      WHERE (category_id >= 5 AND category_id <= 7) \
    DO INSTEAD \
      DELETE FROM books_5_7 WHERE id = OLD.id; \
  \
  CREATE RULE books_delete_books_8_10 AS \
    ON DELETE TO books \
      WHERE (category_id >= 8 AND category_id <= 10) \
    DO INSTEAD \
      DELETE FROM books_8_10 WHERE id = OLD.id; \
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$create_delete_rules_stmt"

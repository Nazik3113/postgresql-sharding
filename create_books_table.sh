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

# Create books table

create_table_books_stmt="\
  CREATE TABLE IF NOT EXISTS books ( \
    id SERIAL NOT NULL, \
    title varchar(100) NOT NULL, \
    category_id integer NOT NULL, \
    author character varying(100) not null, \
    year integer not null, \
    CONSTRAINT books_pk PRIMARY KEY (id) \
  ); \
  CREATE INDEX IF NOT EXISTS books_category_id_idx ON books USING btree (category_id); \
  CREATE INDEX IF NOT EXISTS books_year_idx ON books USING btree (year); \
"
docker exec $POSTGRES_NODE1_HOST psql -h localhost -U $POSTGRES_NODE1_USER -d $POSTGRES_NODE1_DB -c "$create_table_books_stmt"

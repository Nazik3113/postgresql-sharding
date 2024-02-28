# PostgreSQL SHARDING

## Results

| Shard      | Select 1 million rows | Insert 1 million rows |
| ---------- | --------------------- | --------------------- |
| Horizontal |         6.21m         |         5.51m         |
| Vertical   |         2.2m          |         2.35m         |
| No         |         1.35m         |         1.44m         |


## Run applications

```bash
  sudo bash setup.sh
```

### It will run the applications:

- PostgreSQL Node 1 on Port `5433`
- PostgreSQL Node 2 on Port `5434`
- PostgreSQL Node 3 on Port `5435`
- Pgadmin on Port `5051`

### Setup Horizontal Shard:

```bash
  bash create_horizontal_shards_fdw.sh
```

### Setup Vertical Shard:

```bash
  bash create_vertical_shards_fdw.sh
```

### Setup regular table:

```bash
  bash create_books_table.sh
```

## Measurements

Measurements are in folder `measure`, to run them you need to have installed:

- Elixir 1.16.0
- Erlang 26.2.1

### Run application

```bash
  iex -S mix run
```

### Run Select Measurements

```bash
iex(1)> Measure.run_select_measure()
```

### Run Insert Measurements

```bash
iex(1)> Measure.run_insert_measure()
```
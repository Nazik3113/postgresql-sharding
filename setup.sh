#!/bin/bash

docker-compose down -v

mkdir -p ./postgres_node1/data 
rm -rf ./postgres_node1/data/*
mkdir -p ./postgres_node2/data 
rm -rf ./postgres_node2/data/*
mkdir -p ./postgres_node3/data 
rm -rf ./postgres_node3/data/*

docker-compose up -d
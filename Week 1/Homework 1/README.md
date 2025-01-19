# Homework 1: Docker, SQL and Terraform for Data Engineering Zoomcamp 2025

## Question 1. Understanding docker first run

For running docker with the python:3.12.8 image in an interactive mode and using the entrypoint bash we need to use the following command:

`docker run -it --entrypoint bash python:3.12.8`

As a result you'll get the following result, where with command `pip --version` you can check version of `pip` 

```bash
Status: Downloaded newer image for python:3.12.8
root@3d9c046dc905:/# pip --version
pip 24.3.1 from /usr/local/lib/python3.12/site-packages/pip (python 3.12)
```

So, the answer is `24.3.1`

## Question 2. Understanding Docker networking and docker-compose

To answer on this question I need to provide a range of manipulations.

`docker-compose up --build`

After it in another terminal we can run 

```bash
docker build -t taxi_ingest:v001 .

URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz"

docker run -it \
  --network=pg-network \
  taxi_ingest:v001 \
    --user=postgres \
    --password=postgres \
    --host=db \
    --port=5432 \
    --db=ny_taxi \
    --table_name=green_tripdata \
    --url=${URL}
```
where --network is a netwokr's name, created from the name of the directory plus "_default", where was launched `docker-compose.yaml` if the network name is not explicitly specified in the `docker-compose.yaml` file.

Now, we can login in browser by address `http://127.0.0.1:8080/` with data from `pgadmin`, and then create a server by using the data from `postgres`. There we can see a fresh-created database with table `yellow_taxi_trips`

So, because PgAdmin and PostgresDB work in one network, PgAdmin uses PostgresDB's service name (namely `db`) and the internal port inside the Docker network (namely `5432`)

That's why right answer is `db:5432`


## Question 3. Trip Segmentation Count

To answer this question we run the following commands in the PgAdmin:

1. Up to 1 mile:
```sql
select count(1) from green_tripdata
where (trip_distance<=1)
```
The responce is `104838`

2. In between 1 (exclusive) and 3 miles (inclusive):
```sql
select count(1) from green_tripdata
where (trip_distance>1) and (trip_distance<=3)
```
The responce is `199013`

3. In between 3 (exclusive) and 7 miles (inclusive):
```sql
select count(1) from green_tripdata
where (trip_distance>3) and (trip_distance<=7)
```
The responce is `109645`

4. In between 7 (exclusive) and 10 miles (inclusive):
```sql
select count(1) from green_tripdata
where (trip_distance>7) and (trip_distance<=10)
```
The responce is `27688`

5. Over 10 miles:
```sql
select count(1) from green_tripdata
where (trip_distance>10)
```
The responce is `35202`

## Question 4. Longest trip for each day

To answer this question we can use this code:
```sql 
select "lpep_pickup_datetime", "trip_distance" from green_tripdata
order by "trip_distance" desc
limit 1
```
And the answer is:
```
+---+----------------------+---------------+
|   | lpep_pickup_datetime | trip_distance |
+---+----------------------+---------------+
| 1 | 2019-10-31 23:23:41  |    515.89     |
+---+----------------------+---------------+
```
So, the right answer is `2019-10-31`


## Question 5. Three biggest pickup zones

To answer this question we can use this code:

```sql
select 
	z."Zone", 
	sum(t."total_amount") as "Locations_amount"
from 
	green_tripdata t 
left join 
	public.taxi_zone_lookup z 
	on t."PULocationID" = z."LocationID"
where 
	DATE(TO_TIMESTAMP(t."lpep_pickup_datetime", 'YYYY-MM-DD HH24:MI:SS')) = '2019-10-18' 
group by 
	z."Zone"
having
	sum(t."total_amount") >= 13000 
order by 
	"Locations_amount" desc
```
And the answer is:
```
+---+---------------------+--------------------+
|   |        Zone         |   Locations_amount |
+---+---------------------+--------------------+
| 1 |   East Harlem North | 18686.680000000088 |
+---+---------------------+--------------------+
| 2 |   East Harlem South | 16797.260000000064 |
+---+---------------------+--------------------+
| 3 | Morningside Heights | 13029.790000000035 |
+---+---------------------+--------------------+
```
namely, East Harlem North, East Harlem South, Morningside Heights


## Question 6. Largest tip

To answer this question we can use this code:

```sql
select zdo."Zone" as "Drop Out Zone", 
	max(t."tip_amount") as "Max tips"
from 
	green_tripdata t 
join 
	public.taxi_zone_lookup zpu 
	on t."PULocationID" = zpu."LocationID"
join 
	public.taxi_zone_lookup zdo 
	on t."DOLocationID" = zdo."LocationID"
where 
	zpu."Zone" = 'East Harlem North' 
group by 
	zdo."Zone"
order by 
	"Max tips" desc
limit 1
```

And the answer is:
```
+---+---------------+----------+
|   | Drop Out Zone | Max tips |
+---+---------------+----------+
| 1 |   JFK Airport |     87.3 |
+---+---------------+----------+
```
namely, `JFK Airport` is the drop off zone that had the largest tip ($87.3)


## Question 7. Terraform Workflow

The right answer is terraform init, terraform apply -auto-approve, terraform destroy
/* SAN FRANCISCO BIKESHARE TRIPS ANALYSIS */

/* Data from 
`bigquery-public-data.san_francisco.bikeshare_trips`
in Google's BigQuery */



/* 1. Kept observations where the start_date was in 2015 */
SELECT *
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
WHERE EXTRACT(YEAR FROM start_date) = 2015



/* 2. Found the average number of trips per bike in 2015. */
WITH tab AS
( SELECT bike_number, COUNT(trip_id) AS trips
FROM `sf_bikeshare_2015`
GROUP BY bike_number
ORDER BY bike_number )

SELECT AVG(tab.trips) FROM tab
/* 529. */



/* 3. Found out which month has the highest number of trips per bike. */
WITH tab AS
( SELECT EXTRACT(MONTH FROM start_date) AS month, bike_number, COUNT(trip_id) AS trips, 
FROM `sf_bikeshare_2015`
GROUP BY month, bike_number
ORDER BY month, bike_number )

SELECT *,
avg(trips) over (partition by month) AS avg_trips
FROM tab
ORDER BY avg_trips DESC
/* October. */



/* 4. Found the monthly average number of trips per bike. */
WITH  tab3 AS 
( WITH tab2 AS
( WITH tab AS
( SELECT EXTRACT(MONTH FROM start_date) AS month, bike_number, COUNT(trip_id) AS trips, 
FROM `sf_bikeshare_2015`
GROUP BY month, bike_number
ORDER BY month, bike_number )

SELECT *,
avg(trips) over (partition by month) AS avg_trips
FROM tab
ORDER BY avg_trips DESC )

SELECT month, COUNT(bike_number) AS bike_nr, AVG(avg_trips) AS avg_trips
FROM tab2
GROUP BY month
ORDER BY month )

SELECT AVG(avg_trips) FROM tab3;
/* 48.05 */



/* 5. Found out which bike has made the most trips. */
SELECT bike_number, COUNT(trip_id) AS trips
FROM `sf_bikeshare_2015`
GROUP BY bike_number
ORDER BY trips DESC
/* Bike 508 with 1094 trips. */



/* 6. Wrote a query that, for each bike_number, keeps only the start_date of the first trip
it took in 2015 to find out which bike_number had the latest start_date, and in which month it was. */
SELECT bike_number, MIN(start_date) AS first_trip_start_date
FROM `sf_bikeshare_2015`
GROUP BY bike_number
ORDER BY first_trip_start_date DESC;
/* Bike 49 on september 3rd.
This result is odd. It’s possible that the bike was acquired later in the year.
I would check whether it’s been used consistently since that day. */



/* 7. Wrote a query that shows, for each month, the number of bikes that started their first trip on that month. */
WITH tab2 AS (
WITH tab AS (
SELECT bike_number, MIN(start_date) AS first_trip_start_date
FROM `sf_bikeshare_2015`
GROUP BY bike_number
ORDER BY first_trip_start_date DESC )

SELECT bike_number, first_trip_start_date, EXTRACT(MONTH from first_trip_start_date) AS month
FROM tab
GROUP BY bike_number, tab.first_trip_start_date
ORDER BY first_trip_start_date DESC)

SELECT distinct month, COUNT(tab2.first_trip_start_date) AS first_trip_nr_bikes
FROM tab2
GROUP BY tab2.MONTH
ORDER BY tab2.MONTH;

SELECT extract(month from start_date) as month, count(bike_number) as nr_bikes
FROM
 (SELECT *,
   rank() over (partition by bike_number order by start_date) as rank_bike_asc
FROM `sf_bikeshare_2015`
 order by bike_number, start_date)
WHERE rank_bike_asc = 1
GROUP by month
ORDER BY month
/* Most bikes started in January, with only a few added during the year. 
It makes sense if the ones that started in January had been brought sometime before 2015. */



/* 8. The subscriber_type column has two categories: 
Subscriber = annual or 30-day member 
Customer = 24-hour or 3-day member */
SELECT c_subscription_type,
 count(trip_id) as nr_trips,
 cast(sum(duration_sec)/60/60/24 as INT) as tot_duration_day,
 round((sum(duration_sec)/60)/count(trip_id), 2) as avg_duration_trip_min 
FROM `sf_bikeshare_2015`
GROUP BY c_subscription_type
/* It looks like people who choose to subscribe do more frequent trips but much shorter. */



/* 9. On the San Francisco Municipal Transportation Agency website, 
https://www.sfmta.com/blog/bikeshare-station-expansion-and-e-bike-price-changes#:~:text=Before%20and%20throughout%20the%20pandemic,per%20minute%20for%20non%2Dmembers.
I can see there are different fares based on your type of subscription: 
$0.20/min for Subscribers 
$0.30/min for Customers 
Add a new column called “revenue” that shows how much revenue was generated by each subscriber_type in 2015 */
SELECT c_subscription_type,
 count(trip_id) as nr_trips,
 cast(sum(duration_sec)/60/60/24 as INT) as tot_duration_day,
 round((sum(duration_sec)/60)/count(trip_id), 2) as avg_duration_trip_min,
 CASE WHEN c_subscription_type = 'Customer' then round(0.3 * sum(duration_sec)/60, 2)
     WHEN c_subscription_type = 'Subscriber' then round(0.2 * sum(duration_sec)/60, 2)
 END AS revenue
FROM `sf_bikeshare_2015`
GROUP BY c_subscription_type 

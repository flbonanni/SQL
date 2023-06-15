/* SOLAR POWER GENERATORS ANALYSIS */

/* Data from
https://www.kaggle.com/datasets/anikannal/solar-power-generation-data?select=Plant_1_Weather_Sensor_Data.csv */



/* 1. Setting up two tables, one for Generation Data and one for Weather Sensor Data */
CREATE TABLE SolarPower.Generation_Data AS
SELECT *
FROM `SolarPower.Plant_1_Generation_Data`
UNION ALL
SELECT *
FROM `SolarPower.Plant_2_Generation_Data`;

CREATE TABLE SolarPower.Weather_Sensor_Data AS
SELECT *
FROM `SolarPower.Plant_1_Weather_Sensor_Data`
UNION ALL
SELECT *
FROM `SolarPower.Plant_2_Weather_Sensor_Data`;



/* 2. Finding out how many inverters there are in each plant. */ 
SELECT DISTINCT p1gd.SOURCE_KEY, p1wsd.SOURCE_KEY
FROM `SolarPower.Plant_1_Generation_Data` AS p1gd
LEFT JOIN `SolarPower.Plant_1_Weather_Sensor_Data` as p1wsd
on p1gd.SOURCE_KEY = p1wsd.SOURCE_KEY
/* 22 in each. */



/* 3. Finding out how many days of observations we have for each plant. */
SELECT plant_id, count(distinct extract(date from date_time)) as nr_days
FROM SolarPower.Generation_data
GROUP BY plant_id; 
/* 34. */



/* 4. Finding out which inverter generated the highest total yield and which plant it belongs to? */
SELECT TOTAL_YIELD
FROM `SolarPower.Plant_1_Generation_Data`
ORDER BY TOTAL_YIELD DESC
/* Plant 1’s inverter generated 7846821.0 while plant 2’s 2247916295.0. Plant 2’s inverter generated more. */



/* 5. Showing the average AC and DC Power generated, grouped by each power plant. */
SELECT PLANT_ID, AVG_AC, AVG_DC
FROM (SELECT PLANT_ID, AVG(AC_POWER) AS AVG_AC, AVG(DC_POWER) AS AVG_DC
      FROM`SolarPower.Generation_data`
      GROUP BY PLANT_ID
)
/* 
PLANT_ID 4136001 | AVG_AC 241.27782520089687 | AVG_DC 246.70196088781
PLANT_ID 4135001 | AVG_AC 307.80275226551606 | AVG_DC 3147.426211226 */



/* 6. In the process of DC-to-AC conversion, no inverter can achieve 100% efficiency. 
This means that the output (AC) energy is not as high as the input (DC) energy. 
The efficiency of the inverter, calculated as AC Power / DC Power, generally ranges from 95% to 98%. 
Let's find out the overall average inverter efficiency for each Plant. */
SELECT PLANT_ID,
AVG(DC_POWER) AS avg_dc_power,
AVG(AC_POWER) AS avg_ac_power,
 AVG(AC_POWER)/AVG(DC_POWER) AS avg_eff
FROM (SELECT PLANT_ID, AC_POWER, DC_POWER
      FROM`SolarPower.Generation_data`
      GROUP BY PLANT_ID, AC_POWER, DC_POWER
)
GROUP BY PLANT_ID 
/* 
PLANT 4136001 | avg_dc_power 522.21795691609191 | avg_ac_power 510.73647309757717 | avg_eff 0.9780140003489
PLANT 4135001 | avg_dc_power 5923.2347551800513 | avg_ac_power 579.26253924704406 | avg_eff 0.097794965620
DC power for plant 4135001 looks like a typo. 
It could be fixed with: */
SELECT DC/10
	FROM `SolarPower.Generation_data` as GD
FULL OUTER JOIN `SolarPower.Weather_sensor_data` as WSD
On GD.SOURCE_KEY = WSD.SOURCE_KEY
HAVING PLANT_ID = 4135001



/* 7. On plant_id = 4136001, wrote a query that shows the average DA and AC Power
as well as the average inverter efficiency for each hour of the day. */
SELECT HOUR AS TIME_HOUR,
AVG(AC) AS AVG_AC, 
AVG(DC) AS AVG_DC,
ROUND(AVG(CASE WHEN AC <> 0 then AC end)/avg(case when DC <> 0  then DC end)*100,2) as pct_inverter_efficiency
FROM (SELECT PLANT_ID, AC_POWER AS AC, DC_POWER AS DC, EXTRACT(HOUR FROM DATE_TIME) AS HOUR
      FROM`SolarPower.Generation_data`
      WHERE PLANT_ID = 4136001
      GROUP BY PLANT_ID, DATE_TIME, AC_POWER, DC_POWER
)
GROUP BY HOUR
ORDER BY TIME_HOUR
/*TIME_HOUR	AVG_AC	                AVG_DC	                pct_inverter_efficiency
    0	    0.0 	                0.0	
    1	    0.0	                    0.0	
    2	    0.0	                    0.0	
    3	    0.0	                    0.0	
    4	    0.0	                    0.0	
    5	    0.053452380952380953	0.055344611528822064    96.58
    6	    58.939370923627237	    60.673691878813287	    97.14
    7	    239.47451346492997	    244.28385124135104	    98.03
    8	    498.18579172610561	    508.21048400244473	    98.03
    9	    684.92640891495182	    699.88372762638448	    97.86
    10	    775.56514440131934	    793.58795834898376	    97.73
    11	    853.69541887763148	    874.11780051914525	    97.66
    12	    895.77406467585092	    917.41179618317449	    97.64
    13	    795.53017784365306	    814.5040026382942	    97.67
    14	    709.34504131767915	    725.441267693073	    97.78
    15	    591.33560562138769	    603.89105809818568	    97.92
    16	    400.18980899560029	    408.17601775294509	    98.04
    17	    181.82487278852068	    185.66405917237515	    97.93
    18	    39.2204718985386	    40.457082984613372	    96.94
    19	    0.0	0.0	
    20	    0.0	0.0	
    21	    0.0	0.0	
    22	    0.0	0.0	
    23	    0.0	0.0	*/
/* There zeros in the resulting table because solar energy doesn’t work at night. */



/* 8. Finding out how many inverters (source_key) there are in the Generation_Data table? */
SELECT COUNT(DISTINCT SOURCE_KEY) AS how_many_inverters
FROM`SolarPower.Generation_data`
/* 44. */
/* And in the Weather_Sensor_Data table there are 2. */



/* 9. Checking whether there are any source keys in the Weather_Sensor_Data table
that are also present in the Generation_Data table. */
SELECT DISTINCT SOURCE_KEY
FROM `SolarPower.Generation_data`
WHERE source_key in (select distinct source_key
FROM `SolarPower.Weather_sensor_data`)
/* The answer is no. */



/* 10. Created a new clean table with the typo from point 6 fixed */
CREATE TABLE SolarPower.Generation_Data_Clean AS
SELECT *, `plant_1` AS plant_nr
FROM (
     		 SELECT DATE_TIME, PLANT_ID, SOURCE_KEY, DC_POWER/10 AS DC_POWER, AC_POWER, DAILY_YIELD, TOTAL_YIELD
      		FROM `SolarPower.Plant_1_Generation_Data`
)	
UNION ALL
SELECT *, `plant_2` AS plant_nr
FROM `SolarPower.Plant_2_Generation_Data`



/* 11. The Weather_Sensor_Data table stores records of the average ambient (outdoor temp)
and module (photovoltaic panel temp) temperatures as well as irradiation levels
(the amount of the sun's power detected by a sensor). Found out what the average ambient
temperature, module temperature and irradiation by hour of day are. */
SELECT HOUR AS TIME_HOUR, AVG(AMBIENT_TEMPERATURE) AS AMB_TEMP, AVG(MODULE_TEMPERATURE) AS MOD_TEMP, AVG(IRRADIATION) AS IRR_LEV
FROM (SELECT EXTRACT(HOUR FROM DATE_TIME) AS HOUR, AMBIENT_TEMPERATURE, MODULE_TEMPERATURE, IRRADIATION
        FROM `SolarPower.Weather_sensor_data`
)
GROUP BY HOUR
ORDER BY TIME_HOUR
/* Temperature and irradiation are inversely proportional. */



/* Using a JOIN and SUBQUERIES, merged the output table from point 7
(using the new “Clean” table and without the filter on the power plant)
to the table produced after fixing the typo.
Added the PLANT_ID to both outputs so that I can use that in the JOIN as well. */
SELECT GDC.PLANT_ID, GDC.hour_of_day as hour_of_day, AVG(DC_POWER) AS avg_dc_power, AVG(AC_POWER) AS avg_ac_power, AVG(inverter) AS inverter_efficiency,
      WSD.PLANT_ID, AVG(AMBIENT_TEMPERATURE) AS avg_amb_temp, AVG(MODULE_TEMPERATURE) AS avg_mod_temp,
ROUND(AVG(CASE WHEN AC_POWER <> 0 then AC_POWER end)/avg(case when DC_POWER <> 0  then DC_POWER end)*100,2) as pct_inverter_efficiency
FROM (SELECT
      PLANT_ID,
      EXTRACT(HOUR FROM DATE_TIME) AS hour_of_day, 
      DC_POWER,
      AC_POWER,
      AC_POWER/DC_POWER AS inverter
        FROM `SolarPower.Generation_Data_Clean`
        WHERE DC_POWER > 0
      GROUP BY PLANT_ID, hour_of_day, DC_POWER, AC_POWER
) AS GDC
LEFT JOIN
(SELECT 
      PLANT_ID,
      EXTRACT(HOUR FROM DATE_TIME) AS hour_of_day, 
      AMBIENT_TEMPERATURE,
      MODULE_TEMPERATURE,
      IRRADIATION
      FROM `SolarPower.Weather_sensor_data`
      GROUP BY PLANT_ID, hour_of_day, AMBIENT_TEMPERATURE,MODULE_TEMPERATURE, IRRADIATION
) AS WSD
on GDC.PLANT_ID = WSD.PLANT_ID

GROUP BY GDC.PLANT_ID, hour_of_day, WSD.PLANT_ID
ORDER BY GDC.PLANT_ID, GDC.hour_of_day
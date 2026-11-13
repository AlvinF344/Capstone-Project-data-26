---------------------------------------------------------------------
-- Part A1 — First queries 
---------------------------------------------------------------------

--Q1.1 Show the first 10 rows of patients.
SELECT * from patients LIMIT  10;
-- select all rows from the patients table showing the first 10 entries
----------------------------------------------------------------------

--Q1.2 List the patients older than 80 (patient_id, age, sex, glucose_mg_dl), oldest first. Look at the first row: what is wrong?
SELECT  patient_id, age, sex, glucose_mg_dl 
FROM patients 
WHERE age > 80 
ORDER BY age DESC;
--age of patient P144 is 278(error in data entry)
----------------------------------------------------------------------

--Q1.3 List the care centres located in Wallonia, sorted by name. Hint: WHERE region LIKE 'Wallonie%'
SELECT * FROM care_centres;

SELECT centre_name, region FROM care_centres
WHERE region LIKE 'Wallonie%'
ORDER BY centre_name ASC;
-----------------------------------------------------------------------

--Q1.4 List the different blood groups, without repeating them. Hint: SELECT DISTINCT 

SELECT * FROM patients;

SELECT DISTINCT blood_group FROM patients;
------------------------------------------------------------------------

--Q1.5 List the patients whose glucose is 126 mg/dL or more (patient_id, age, glucose_mg_dl), highest 
--glucose first. How many rows do you get?

SELECT patient_id, age, glucose_mg_dl 
FROM patients
WHERE glucose_mg_dl >= 126
ORDER BY glucose_mg_dl DESC;
-- 50 rows
------------------------------------------------------------------------

--Q1.6 Show all treatments of patient P335, sorted by start date.

SELECT * FROM treatments;

SELECT patient_id, start_date
FROM treatments
WHERE patient_id = 'P335'
ORDER BY start_date ASC;
-------------------------------------------------------------------------

--Q1.7 Show all measurements of patient P365 (date, glucose, weight, HbA1c), sorted by date. When does 
--this patient's history start? 
SELECT * FROM glucose_history;

SELECT patient_id, measure_date, glucose_mg_dl, weight_kg, HbA1c_pct
FROM glucose_history
WHERE patient_id = 'P365'
ORDER BY measure_date ASC;
--LIMIT 1
-- Patient P365 history start: 2020-04-05
--------------------------------------------------------------------------

--Q1.8 List the patients whose sex is not recorded at all. Hint: an empty value is NULL, and you test it with 
--IS NULL, not with = NULL.
SELECT * FROM  patients;

SELECT patient_id, sex
FROM patients
WHERE sex IS NULL;


------------------------------------------------------------------------------
--Part A2 — Counting and grouping
------------------------------------------------------------------------------

--Q2.1 How many rows are there in patients, in glucose_history and in consultations? (one query 
--each)
SELECT count(*) AS p_count FROM  patients; --rows in patients  1,500
SELECT count(*) AS g_hist_count FROM  glucose_history; --rows in glucose_history  11,565
SELECT count(*) AS consult_count FROM  consultations; --rows in consultations  3,609

--------------------------------------------------------------------------------
--Q2.2 Return the minimum, maximum and average age (2 decimals), and the average glucose (1 
--decimal), of all patients. Is the average age reliable?
SELECT * FROM patients;

SELECT ROUND(MIN(age), 2) AS min_age, ROUND(MAX(age), 2) AS max_age,
	   ROUND(AVG(age), 2) AS avg_age, ROUND(avg(glucose_mg_dl)) AS avg_glucose
FROM patients;
--No, there is an error in entry of max_age

---------------------------------------------------------------------------------
--Q2.3 Count the patients for each value of sex. How many different values do you see? How many 
--patients are really women, men, or unknown? [X1] Hint: SELECT sex, COUNT(*) FROM patients 
--GROUP BY sex
SELECT DISTINCT sex, count(*) FROM patients
GROUP BY sex
ORDER BY sex;
--12 different values
--women: femme+F+f+Femme = 929
--men:   H+M+h+homme+m = 566
--unkonwn: na+NA = 2
--null: 3

----------------------------------------------------------------------------------
--Q2.4 Same question for corticosteroids. Which values should not be there? [X3]
SELECT corticosteroids, count(*) FROM patients
GROUP BY corticosteroids;
--no : non = 1364
--yes: Oui = 128
--unknown: NA+Na+na = 6
--the Null values shouldn't be there.(2)

----------------------------------------------------------------------------------
--Q2.5 Same question for activity_level in lifestyle. What is wrong?
SELECT * FROM lifestyle;

SELECT activity_level, count(*) FROM lifestyle
GROUP BY activity_level;
--There are two entries for Faible(uppercase and lowercase)

----------------------------------------------------------------------------------

--Q2.6 Count the measurements per year, with the number of different patients each year. What is 
--unusual about 2020 to 2023?
SELECT * FROM glucose_history;

SELECT substr(measure_date::text, 1, 4) AS year, 
       count(*) AS n_measurements,
       count(DISTINCT  patient_id) AS p_count 
FROM glucose_history
GROUP BY YEAR;
--from 2020-2023: the patient count is the same 46, as well as the n_measurements 92.
----------------------------------------------------------------------------------

--Q2.7 For each drug_class in treatments, count the rows and the different patients, most frequent first.

SELECT * FROM treatments;

SELECT drug_class, count(*) AS n_rows, 
	   count(DISTINCT patient_id) AS n_patients
FROM treatments
GROUP BY drug_class
ORDER BY n_patients DESC;

----------------------------------------------------------------------------------

--Q2.8 Duplicates. Find the rows that appear twice in consultations, then in family_history. 

SELECT * FROM consultations;
SELECT * FROM family_history;

SELECT * FROM consultations
GROUP BY patient_id, consult_date, consult_type, provider, reason
HAVING count(*)>1; -- 1 duplicate

SELECT * FROM family_history
GROUP BY patient_id, relative, condition
HAVING count(*)>1; -- 10 duplicates

---------------------------------------------------------------------------------
--Q2.9 Find the patients who have two measurements on the same date in glucose_history. 

SELECT * FROM glucose_history;

SELECT patient_id, measure_date FROM glucose_history
GROUP BY patient_id, measure_date 
HAVING COUNT(*) > 1;

---------------------------------------------------------------------------------
--Q2.10 Which glucose values appear most often in glucose_history? Show the top 5. Is the first one 
--realistic?

SELECT glucose_mg_dl, count(*) AS g_val_count  FROM glucose_history
GROUP BY glucose_mg_dl
ORDER BY g_val_count DESC
LIMIT 5;
--With such a high count(114) for glucose_mg_dl of 58 seems a bit unrealistic.


---------------------------------------------------------------------------------
--Part A3 — Cleaning the data
---------------------------------------------------------------------------------

--Q3.1 Apply R1 with three UPDATE statements, then count the patients per sex again.

SELECT DISTINCT sex, count(*) FROM patients
GROUP BY sex
ORDER BY sex; ------ Before update: distinct count of patients per sex

UPDATE patients SET sex = 'F' WHERE LOWER(sex) IN ('f', 'femme'); 
UPDATE patients SET sex = 'M' WHERE LOWER(sex) IN ('m', 'homme', 'h');
UPDATE patients SET sex = 'Unknown' WHERE sex NOT IN ('F','M') OR sex IS NULL;


SELECT DISTINCT sex, count(*) FROM patients
GROUP BY sex
ORDER BY sex; ------ After update: distinct count of patients per sex

-------------------------------------------------------------------------------

--Q3.2  Before applying R2, check that none of these patients actually receives a corticosteroid: list the 
--      rows of treatments where drug_class = 'Corticoïdes' and whose patient has a strange 
--      corticosteroids value. How many rows do you get? Then apply R2 and count again
SELECT * FROM treatments t; -- visualize
SELECT * FROM patients p ;  -- visualize

SELECT * FROM treatments t 
WHERE t.drug_class = 'Corticoïdes'; -- check for patients with drug_class 'Corticoïdes'


SELECT * FROM patients p 
WHERE p.corticosteroids NOT IN ('Oui', 'Non')
OR p.corticosteroids IS NULL ; -- check for strange/missing values (8)

SELECT * FROM treatments 
WHERE drug_class = 'Corticoïdes'
	AND patient_id IN (
		SELECT patient_id FROM patients 
		WHERE corticosteroids NOT IN ('Oui', 'Non') 
		OR corticosteroids IS NULL 
		); -- check for patients receiving treatment for corticosteroids
------------- no patients/rows found

UPDATE patients SET corticosteroids = 'Non' WHERE LOWER(corticosteroids) IN ('na')
OR corticosteroids IS NULL;

SELECT * FROM patients p 
WHERE p.corticosteroids NOT IN ('Oui', 'Non')
OR p.corticosteroids IS NULL ; -- check list again after update.

SELECT DISTINCT(corticosteroids), count(*) FROM patients p
GROUP BY p.corticosteroids ;


------------------------------------------------------------------------------

--Q3.3 Apply R3, then compute the minimum, maximum and average age again. How much did the 
--average change?
SELECT * FROM patients WHERE age > 100;

SELECT age, COUNT(*) AS age_count
FROM patients
GROUP BY age
ORDER BY age DESC;

SELECT MIN(age) AS min_age, MAX(age) AS max_age, round(AVG(age),2)  AS avg_age
FROM patients p; -- before update compute min(18), max(278), avg(50.9)  age 

UPDATE patients SET age = NULL  WHERE age > 100;

SELECT MIN(age) AS min_age, MAX(age) AS max_age, round(AVG(age),2)  AS avg_age
FROM patients p; -- after update compute min(18), max(85), avg(50.75)  age
--- the average age reduced by 0.15 after the update
-----------------------------------------------------------------------------

--Q3.4 Apply R4

SELECT DISTINCT(activity_level) FROM lifestyle;

UPDATE lifestyle SET activity_level = 'Faible' WHERE lower(activity_level) = 'faible';

-----------------------------------------------------------------------------

--Q3.5 Apply R5 by creating two clean copies, then count their rows:

SELECT count(*) FROM consultations c; -- 3609

CREATE TABLE consultations_clean AS SELECT DISTINCT * FROM consultations;

SELECT count(*) FROM consultations_clean; -- 3608
---------------------------------------------------------------------------
SELECT count(*) FROM family_history fh; -- 1662

CREATE TABLE family_history_clean AS SELECT DISTINCT * FROM family_history;

SELECT count(*) FROM family_history_clean; -- 1652


----------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
Part A4 — Analysis on clean data
----------------------------------------------------------------------------------------

-- Q4.1 For each sex, give the number of patients, their percentage (1 decimal) and their average age.

SELECT count(*) FROM patients p;

SELECT sex, count(*) AS n_sex , 
	   ROUND(100 * COUNT(*) / 1500, 1) AS pct_sex,  -- 1500 total count of patients
	   round(AVG(age),2) AS avg_age
	   FROM patients p 
GROUP BY sex 
ORDER BY sex;

------------------------------------------------------------------------------------------

-- Q4.2 Count the patients in each glucose category, with their average age. Complete this query:

SELECT CASE WHEN glucose_mg_dl < 100 THEN 'Normal' 
			WHEN glucose_mg_dl < 126 THEN 'Impaired' 
			ELSE 'Diabetes range' END AS glucose_category, 
	COUNT(*) AS n_patients, round(AVG(age),2) AS avg_age
FROM patients 
GROUP BY glucose_category;

--------------------------------------------------------------------------------------------

-- Q4.3 Count the consultations per year in consultations_clean. By how many percent did they grow 
-- from 2024 to 2025 (calculate by hand)? Why should 2023 and 2026 not be compared with the other 
-- years?

SELECT * FROM consultations_clean cc;

SELECT substr(cc.consult_date::text, 1, 4) AS YEAR,
	   count(*) AS consult_count
FROM consultations_clean cc 
GROUP BY year
ORDER BY year;

--- growth percentage 2024-2025: ((1715 - 1471)/ 1471)*100 =  16.58% increase

--- 2023: 88 consultations, looks like incomplete data, few consultations.
--- 2026: is an on going year, we still need to collect data.(maybe at the end of the year)
--- conclusion: not a good idea to compare data with other years, as data is incomplete to check for growth in consultations.

------------------------------------------------------------------------------------------------

-- Q4.4 Count the consultations per type, most frequent first

SELECT * FROM consultations_clean cc;

SELECT cc.consult_type, count(*) AS n_consult_type FROM consultations_clean cc 
GROUP BY cc.consult_type 
ORDER BY cc.consult_type DESC;

-------------------------------------------------------------------------------------------------

--Q4.5 How many measurements show a glucose of 126 mg/dL or more, and how many different patients do they concern?

SELECT * FROM glucose_history gh;
SELECT * FROM patients p ;

SELECT COUNT(*) AS measurements_ge_126,
       COUNT(DISTINCT patient_id) AS patients_concerned
FROM glucose_history gh  
WHERE glucose_mg_dl >= 126;

-- measurements >= 126: 50
-- different patients_concerned: 50

---------------------------------------------------------------------------------------------------

-- Q4.6 Give the number of measurements and the average HbA1c (2 decimals) per year. Does HbA1c change over time? 

SELECT * FROM glucose_history gh;

SELECT substr(measure_date::text, 1, 4) AS year, count(*),
	   round(AVG(hba1c_pct)::numeric, 2) AS avg_hba1c 
FROM glucose_history gh
GROUP BY year
ORDER BY year;

-- hba1c appears to increase from 2023 to 2025 and then remains constant from 2025 to 2026
-- Therefore, HbA1c does change over time, although the magnitude of the change is relatively small.

----------------------------------------------------------------------------------------------------

-- Q4.7 How many treatments are still ongoing (no end date), not counting the rows Aucun traitement? 

SELECT * FROM treatments t;

SELECT count(*)AS n_ongoing_treatment FROM treatments t 
WHERE t.end_date IS NULL
AND t.drug_name NOT IN ('Aucun traitement');

-- treatments still going on : 1194

----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
Part A5 — Combining tables
----------------------------------------------------------------------------------------------------

-- Q5.1 Join patients and lifestyle to give the number of patients and their average glucose for each 
-- do stress level. What do you notice?

SELECT l.stress_level,
       COUNT(*) AS n_patients, 
       round(AVG(p.glucose_mg_dl)::NUMERIC, 2) AS avg_glucose
FROM patients p
JOIN lifestyle l
    ON p.patient_id = l.patient_id
GROUP BY l.stress_level
ORDER BY l.stress_level;

-- There appears to be positive association between stress level and avg glucose 
-- high stress level corresponds to high avg_glucose
-- weak stress level corresponds to low avg_glucose

--------------------------------------------------------------------------------------------------------

-- Q5.2 Same question for activity_level, then for smoker. Which factor seems linked to glucose, and 
-- which does not?

SELECT l.activity_level,
       COUNT(*) AS n_patients, 
       round(AVG(p.glucose_mg_dl)::NUMERIC, 2) AS avg_glucose
FROM patients p
JOIN lifestyle l
    ON p.patient_id = l.patient_id
GROUP BY l.activity_level
ORDER BY l.activity_level;

-- There appears to be negative association between activity level and avg glucose 
-- high activity level corresponds to low avg_glucose
-- weak activity level corresponds to high avg_glucose



SELECT l.smoker,
       COUNT(*) AS n_patients, 
       round(AVG(p.glucose_mg_dl)::NUMERIC, 2) AS avg_glucose
FROM patients p
JOIN lifestyle l
    ON p.patient_id = l.patient_id
GROUP BY l.smoker
ORDER BY l.smoker;

-- non_smokers appears to have low avg_glucose compared to smokers.
-- but the difference is very minimal. 

-- conclusion: activity level appears to be linked with glucose

-------------------------------------------------------------------------------------------

-- Q5.3 Count the patients per region. You need patient_centre and care_centres.

SELECT * FROM patient_centre pc;
SELECT * FROM care_centres cc ;

SELECT 
	cc.region , 
	count(*) AS n_patients
FROM patient_centre pc 
JOIN care_centres cc 
	ON cc.centre_id = pc.centre_id
GROUP BY cc.region;

-------------------------------------------------------------------------------------------

-- Q5.4 Give the number of patients and the average glucose for each type of care centre. This time you 
-- need three tables.

SELECT * FROM patient_centre pc ;
SELECT * FROM care_centres cc ;
SELECT * FROM patients p ;

SELECT cc.centre_type , count(*) AS n_patients,
	   round(AVG(p.glucose_mg_dl)::NUMERIC, 2) AS avg_glucose
FROM patient_centre pc 
JOIN care_centres cc 
	ON cc.centre_id = pc.centre_id
JOIN patients p 
	ON pc.patient_id = p.patient_id
GROUP BY cc.centre_type;

---------------------------------------------------------------------------------------------

-- Q5.5 Compare the patients who have at least one relative with type 2 diabetes with the others: number 
-- of patients and average glucose for each group.

SELECT * FROM family_history_clean fhc;

-- 	Patients with a relative with type 2 diabetes
SELECT
	'Family T2D: Yes' AS  group_name,
	count(*) AS n_patients,
	round(AVG(glucose_mg_dl)::numeric, 2) AS avg_glucose
	FROM patients
WHERE patient_id IN (
	SELECT patient_id 
	FROM family_history_clean
	WHERE condition = 'Diabète de type 2'
	);


-- 	Patients without a relative with type 2 diabetes
SELECT 
	'Family T2D: No' AS group_name,
	count(*) AS n_patients,
	round(AVG(glucose_mg_dl)::numeric, 2) AS avg_glucose
	FROM patients
WHERE patient_id NOT IN (
	SELECT patient_id 
	FROM family_history_clean
	WHERE condition = 'Diabète de type 2'
	);
	
--------------------------------------------------------------------------------------------

-- Q5.6 For each antidiabetic drug, give the number of patients and their average glucose. Why is glucose 
-- so high for the three rare drugs?

SELECT * FROM treatments t ;

SELECT
	t.drug_name, 
	count(DISTINCT t.patient_id) AS n_patients,
	round(AVG(glucose_mg_dl)::numeric, 2) AS avg_glucose
FROM treatments t 
JOIN patients p 
	ON t.patient_id = p.patient_id
WHERE t.drug_class = 'Antidiabétiques'
GROUP BY t.drug_name
ORDER BY n_patients DESC; 

-- It appears that 
-- The three rare drugs (Empagliflozin, Insulin glargine, and Semaglutide) 
-- are associated with much higher average glucose levels (144-158 mg/dL).
-- More likely, they are prescribed to patients with more severe diabetes, who already have higher glucose
-- levels. In addition, the number of patients taking these drugs is very small (9-12).

-----------------------------------------------------------------------------------------------

-- Q5.7 Critical thinking. Count the patients per stress level among those who received an antidepressant, 
-- then among the others. Would you expect this result? What does it say about the data?

SELECT * FROM lifestyle l;
SELECT * FROM treatments t;

-- patients who received Antidépresseurs
SELECT 
	l.stress_level,
	count(DISTINCT l.patient_id ) AS n_patients	
FROM lifestyle l 
WHERE l.patient_id  IN (
	SELECT t.patient_id 
	FROM treatments t
	WHERE t.drug_class = 'Antidépresseurs'
	)
GROUP BY l.stress_level;


-- All other patients, who did not receive Antidépresseurs

SELECT 
	l.stress_level,
	count(DISTINCT l.patient_id ) AS n_patients	
FROM lifestyle l 
WHERE l.patient_id  IN (
	SELECT t.patient_id 
	FROM treatments t
	WHERE t.drug_class NOT IN ('Antidépresseurs')
	)
GROUP BY l.stress_level;

-- the result is not what we would normally expect. 
-- Antidepressant use does not appear strongly linked to stress level, 
-- suggesting the dataset is artificial and contains relationships that may not reflect real-world clinical patterns.


--------------------------------------------------------------------------------------------------------------

-- Q5.8 Find the last measurement date in glucose_history (MAX). Then list the treatments that start 
-- after that date. Is that possible?

SELECT * FROM glucose_history gh;
SELECT * FROM treatments t;

SELECT *
FROM treatments
WHERE start_date > (
    SELECT MAX(measure_date)
    FROM glucose_history
)
ORDER BY start_date;

-- Conclusion:
-- Six treatments start after the last glucose measurement date (2026-06-28).
-- This is unusual because the dataset contains no measurements recorded after that date.
-- This indicates a data-quality issue or inconsistency in the dataset timeline.
-- Such records should be investigated before performing further analyses.

------------------------------------------------------------------------------------------------------------



































 




















































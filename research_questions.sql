-- Otázka č. 1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
WITH salary_changes AS (
    SELECT
        industry_name,
        payroll_year,
        ROUND(AVG(average_wages)) AS avg_salary,
        LAG(ROUND(AVG(average_wages))) OVER (PARTITION BY industry_name ORDER BY payroll_year) AS prev_salary    
    FROM t_jana_veverkova_project_SQL_primary_final
    GROUP BY industry_name, payroll_year
)
SELECT *
FROM salary_changes
WHERE avg_salary < prev_salary
ORDER BY industry_name, payroll_year;

-- Otázka č. 2: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední
-- srovnatelné období v dostupných datech cen a mezd?
-- Vyhledání kategorií pro mléko a chléb
SELECT DISTINCT 
    food_category_name,
    MIN(payroll_year) AS first_year,
    MAX(payroll_year) AS last_year
FROM t_jana_veverkova_project_SQL_primary_final
WHERE (
    food_category_name ILIKE '%Mléko%' 
    OR food_category_name ILIKE '%mleko%'
    OR food_category_name ILIKE '%Chléb%'
    OR food_category_name ILIKE '%chleb%'
)
AND food_price IS NOT NULL
GROUP BY food_category_name
ORDER BY food_category_name;

-- Kontrola dat prvního roku pro mléko a chléb
SELECT DISTINCT
    payroll_year,
    food_category_name,
    food_price
FROM t_jana_veverkova_project_SQL_primary_final
WHERE food_category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
    AND food_price IS NOT NULL
ORDER BY payroll_year;

-- Kontrola dat posledního roku pro mléko a chléb
SELECT DISTINCT
    payroll_year,
    food_category_name,
    food_price
FROM t_jana_veverkova_project_SQL_primary_final
WHERE food_category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
    AND food_price IS NOT NULL
ORDER BY payroll_year DESC;

-- Výpočet kupní síly pro mléko a chléb v prvním a posledním roce
SELECT
    food_category_name,
    payroll_year,
    ROUND(AVG(average_wages)) AS average_wages,
    ROUND(CAST(AVG(food_price) AS NUMERIC), 2) AS food_price,
    ROUND(AVG(average_wages)/AVG(food_price)) AS amount_can_buy
FROM t_jana_veverkova_project_SQL_primary_final
WHERE food_category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
    AND payroll_year IN (2006, 2018)
    AND food_price IS NOT NULL
GROUP BY food_category_name, payroll_year;

-- Otázka č. 3: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
WITH year_changes AS (
    SELECT
        food_category_name,
        payroll_year,
        AVG(food_price) AS avg_price,
        LAG(AVG(food_price)) OVER (PARTITION BY food_category_name ORDER BY payroll_year) AS prev_price,
        ROUND(CAST(
            (AVG(food_price) - LAG(AVG(food_price)) OVER (PARTITION BY food_category_name ORDER BY payroll_year))/
            LAG(AVG(food_price)) OVER (PARTITION BY food_category_name ORDER BY payroll_year) * 100
            AS NUMERIC), 2) AS year_to_year_change
    FROM t_jana_veverkova_project_SQL_primary_final
    WHERE food_price IS NOT NULL 
        AND food_category_name IS NOT NULL
    GROUP BY food_category_name, payroll_year
    ORDER BY food_category_name
)
SELECT 
    food_category_name,
    ROUND(AVG(year_to_year_change), 2) AS avg_year_change
FROM year_changes 
WHERE year_to_year_change IS NOT NULL
GROUP BY food_category_name 
HAVING ROUND(AVG(year_to_year_change), 2) > 0
ORDER BY avg_year_change;

-- Otázka č. 4: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
WITH price_changes AS (
    SELECT
        payroll_year,
        AVG(food_price) AS avg_price,  
        LAG(AVG(food_price)) OVER (ORDER BY payroll_year) AS prev_price,
        ROUND(CAST(
            (AVG(food_price) - LAG(AVG(food_price)) OVER (ORDER BY payroll_year))
            / LAG(AVG(food_price)) OVER (ORDER BY payroll_year) * 100
            AS NUMERIC), 2) AS price_growth
    FROM t_jana_veverkova_project_SQL_primary_final
    WHERE food_price IS NOT NULL
    GROUP BY payroll_year 
),
salary_changes AS (
    SELECT
        payroll_year,
        AVG(average_wages) AS avg_salary,
        LAG(AVG(average_wages)) OVER (ORDER BY payroll_year) AS prev_salary,
        ROUND(CAST(
            (AVG(average_wages) - LAG(AVG(average_wages)) OVER (ORDER BY payroll_year))
            / LAG(AVG(average_wages)) OVER (ORDER BY payroll_year) * 100
            AS NUMERIC), 2) AS salary_growth
    FROM t_jana_veverkova_project_SQL_primary_final
    GROUP BY payroll_year
)
SELECT
    p.payroll_year,
    p.price_growth,
    s.salary_growth,
    COALESCE(ROUND(CAST(p.price_growth - s.salary_growth AS NUMERIC), 2), 0) AS difference
FROM price_changes p
JOIN salary_changes s ON p.payroll_year = s.payroll_year
WHERE p.price_growth IS NOT NULL
    AND (p.price_growth - s.salary_growth) > 10
ORDER BY difference DESC;

-- Otázka č. 5: Má výška HDP vliv na změny ve mzdách a cenách potravin?
--Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin
-- či mzdách ve stejném nebo následujícím roce výraznějším růstem?
-- Vytvoření pohledu pro přehled růstu
CREATE OR REPLACE VIEW v_jana_veverkova_growth_overview AS
WITH gdp_growth_calc AS (
    -- Výpočet meziročních změn HDP, mezd a cen potravin
    SELECT 
        payroll_year,
        gdp,
        LAG(gdp) OVER (ORDER BY payroll_year) AS previous_gdp,
        ROUND(CAST((gdp - LAG(gdp) OVER (ORDER BY payroll_year)) /
            LAG(gdp) OVER (ORDER BY payroll_year) * 100 AS NUMERIC), 2) AS gdp_growth,
        average_wages,
        LAG(average_wages) OVER (ORDER BY payroll_year) AS previous_average_wages,
        food_price,
        LAG(food_price) OVER (ORDER BY payroll_year) AS previous_food_price
    FROM t_jana_veverkova_project_SQL_secondary_final
)
-- Finální výpočet včetně meziročních změn v procentech
SELECT 
    payroll_year,
    gdp,
    previous_gdp,
    gdp_growth,
    average_wages,
    previous_average_wages,
    ROUND(CAST((average_wages - previous_average_wages) / 
        previous_average_wages * 100 AS NUMERIC), 2) AS wages_growth,
    food_price,
    previous_food_price,
    ROUND(CAST((food_price - previous_food_price) / 
        previous_food_price * 100 AS NUMERIC), 2) AS food_price_growth,
    LAG(gdp_growth) OVER (ORDER BY payroll_year) AS previous_year_gdp_growth
FROM gdp_growth_calc;

-- Analýza vztahů mezi HDP, mzdami a cenami potravin
SELECT
    payroll_year AS rok,
    gdp_growth AS rust_hdp,
    wages_growth AS rust_mezd,
    food_price_growth AS rust_cen_potravin,
    previous_year_gdp_growth AS rust_hdp_predchozi_rok,
    CASE
        WHEN gdp_growth > 5 THEN 'výrazný růst HDP'
        WHEN gdp_growth < -2 THEN 'výrazný pokles HDP'
        WHEN gdp_growth < 0 THEN 'mírný pokles HDP'
        ELSE 'mírný růst HDP'
    END AS hdp_kategorie,
    CASE
        WHEN ABS(wages_growth - gdp_growth) <= 1 THEN 'koreluje s HDP'
        WHEN wages_growth > gdp_growth THEN 'mzdy rostou rychleji než HDP'
        ELSE 'HDP roste rychleji než mzdy'
    END AS vztah_mzdy_hdp,
    CASE 
        WHEN ABS(food_price_growth - gdp_growth) <= 1 THEN 'koreluje s HDP'
        WHEN food_price_growth > gdp_growth THEN 'ceny potravin rostou rychleji'
        ELSE 'HDP roste rychleji než ceny potravin'        
    END AS vztah_cen_potravin_hdp,
    CASE
        WHEN ABS(wages_growth - previous_year_gdp_growth) <= 1 THEN 'koreluje s HDP předchozího roku'
        WHEN wages_growth > previous_year_gdp_growth THEN 'mzdy rostou rychleji než loňské HDP'
        ELSE 'loňské HDP rostlo rychleji než mzdy'
    END AS vztah_mzdy_lonske_hdp,
    CASE
        WHEN ABS(food_price_growth - previous_year_gdp_growth) <= 1 THEN 'koreluje s HDP předchozího roku'
        WHEN food_price_growth > previous_year_gdp_growth THEN 'ceny potravin rostou rychleji než loňské HDP'
        ELSE 'loňské HDP rostlo rychleji než ceny potravin'
    END AS vztah_cen_potravin_lonske_hdp    
FROM v_jana_veverkova_growth_overview
WHERE payroll_year > 2006
ORDER BY payroll_year;

-- Korelační analýza - zjištění statistické souvislosti mezi ukazateli
SELECT
    CORR(gdp_growth, wages_growth) AS korelace_hdp_mzdy,
    CORR(gdp_growth, food_price_growth) AS korelace_hdp_ceny_potravin,
    CORR(previous_year_gdp_growth, wages_growth) AS korelace_lonske_hdp_mzdy,
    CORR(previous_year_gdp_growth, food_price_growth) AS korelace_lonske_hdp_ceny_potravin
FROM v_jana_veverkova_growth_overview
WHERE payroll_year > 2006;

-- Doplňkový dotaz - počet let, kdy mzdy korelovaly s HDP
SELECT
    SUM(CASE 
        WHEN ABS(wages_growth - gdp_growth) <= 1 THEN 1 
        ELSE 0 
    END) AS pocet_korelace_mzdy_hdp
FROM v_jana_veverkova_growth_overview
WHERE payroll_year > 2006;

-- Doplňkový dotaz - počet let, kdy mzdy rostly rychleji než HDP
SELECT
    SUM(CASE 
        WHEN wages_growth > gdp_growth AND ABS(wages_growth - gdp_growth) > 1 THEN 1 
        ELSE 0 
    END) AS pocet_mzdy_rychleji
FROM v_jana_veverkova_growth_overview
WHERE payroll_year > 2006;

-- Doplňkový dotaz - počet let, kdy HDP rostlo rychleji než mzdy
SELECT
    SUM(CASE 
        WHEN wages_growth < gdp_growth AND ABS(wages_growth - gdp_growth) > 1 THEN 1 
        ELSE 0 
    END) AS pocet_hdp_rychleji_nez_mzdy
FROM v_jana_veverkova_growth_overview
WHERE payroll_year > 2006;

-- Doplňkový dotaz - počet let, kdy ceny potravin korelovaly s HDP
SELECT
    SUM(CASE 
        WHEN ABS(food_price_growth - gdp_growth) <= 1 THEN 1 
        ELSE 0 
    END) AS pocet_korelace_ceny_hdp
FROM v_jana_veverkova_growth_overview
WHERE payroll_year > 2006;

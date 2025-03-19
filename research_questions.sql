---- otázka č. 1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
with salary_changes as (
	select
	industry_name,
	payroll_year,
	round(avg(average_wages)) as avg_salary,
	lag (round(avg(average_wages))) over (partition by industry_name order by payroll_year)	as prev_salary	
	from t_jana_veverkova_project_SQL_primary_final
	group by industry_name, payroll_year
)
select *
from salary_changes
where avg_salary < prev_salary
order by industry_name, payroll_year;

---- otázka č. 2: Kolik je možné si koupit litrů mléka
-- a kilogramů chleba za první a poslední srovnatelné období v 
--dostupných datech cen a mezd? 

select distinct 
    food_category_name,
    min(payroll_year) as first_year,
    max(payroll_year) as last_year
from t_jana_veverkova_project_SQL_primary_final
where (
    food_category_name ilike '%Mléko%' 
    or food_category_name ilike '%mleko%'
    or food_category_name ilike '%Chléb%'
    or food_category_name ilike '%chleb%'
)
and food_price is not null
group by food_category_name
order by food_category_name; ----- dlouhý čas, ale vyhledá mléko i chleba s roky

select distinct
    payroll_year,
    food_category_name,
    food_price
from t_jana_veverkova_project_SQL_primary_final
where food_category_name in ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
    and food_price is not null
order by payroll_year; --2006

select distinct
    payroll_year,
    food_category_name,
    food_price
from t_jana_veverkova_project_SQL_primary_final
where food_category_name in ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
    and food_price is not null
order by payroll_year desc ; -- 2018

select
food_category_name,
payroll_year,
round(avg(average_wages)) as average_wages,
round(cast(avg(food_price) as numeric), 2) as food_price,
round(avg(average_wages)/avg(food_price)) as amount_can_buy
from t_jana_veverkova_project_SQL_primary_final
where food_category_name in ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
	and payroll_year in ( 2006, 2018)
	and food_price is not NUll
group by food_category_name, payroll_year;


----Otázka číslo 3:
--Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

with year_changes as (
 	select
        food_category_name,
        payroll_year,
        avg(food_price) as avg_price,
        lag(avg(food_price)) over (partition by food_category_name order by payroll_year) as prev_price,
        round(cast(
        	(avg(food_price) - lag(avg(food_price)) over (partition by food_category_name order by payroll_year))/
        	lag(avg(food_price)) over (partition by food_category_name order by payroll_year) *100
        	as numeric), 2) as year_to_year_change
 	from t_jana_veverkova_project_SQL_primary_final
 	where food_price is not null 
 		and food_category_name is not null
 	group by food_category_name, payroll_year
 	order by food_category_name
 )
 select 
 	food_category_name,
 	round(avg(year_to_year_change), 2) as avg_year_change
  from year_changes 
  where year_to_year_change is not null
  group by food_category_name 
  having round(avg(year_to_year_change), 2) > 0
  order by avg_year_change ;


---- otázka č. 4:Existuje rok,ve kterém byl meziroční nárůst cen
-- potravin výrazně vyšší než růst mezd (větší než 10 %)?


with price_changes as (
    select
        payroll_year,
        avg(food_price) as avg_price,  
        lag(avg(food_price)) over (order by payroll_year) as prev_price,
        round(cast(
            (avg(food_price) - lag(avg(food_price)) over (order by payroll_year))
            / lag(avg(food_price)) over (order by payroll_year) * 100
        as numeric), 2) as price_growth
    from t_jana_veverkova_project_SQL_primary_final
    where food_price is not null
    group by payroll_year 
 ),
salary_changes as (
    select
        payroll_year,
        avg(average_wages) as avg_salary,
        lag(avg(average_wages)) over (order by payroll_year) as prev_salary,
        round(cast(
            (avg(average_wages) - lag(avg(average_wages)) over (order by payroll_year))
            / lag(avg(average_wages)) over (order by payroll_year) * 100
        as numeric), 2) as salary_growth
    from t_jana_veverkova_project_SQL_primary_final
    group by payroll_year
)
select
    p.payroll_year,
    p.price_growth,
    s.salary_growth,
    coalesce(round(cast(p.price_growth - s.salary_growth as numeric), 2), 0) as difference
from price_changes p
join salary_changes s on p.payroll_year = s.payroll_year
where p.price_growth is not null
	and (p.price_growth - s.salary_growth) > 10
order by difference desc;

---- 5. otázka: Má výška HDP vliv na změny ve mzdách a cenách potravin? 
-- Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to
-- na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem

create or replace view v_jana_veverkova_growth_overview as
with gdp_growth_calc as (
	-- Výpočet meziročních změn HDP, mezd a cen potravin
    select 
        payroll_year,
        gdp,
        lag(gdp) over (order by payroll_year) as previous_gdp,
        round(cast((gdp - lag(gdp) over (order by payroll_year)) /
            lag(gdp) over (order by payroll_year) * 100 as numeric), 2) AS gdp_growth,
        average_wages,
        lag(average_wages) over (order by payroll_year) as previous_average_wages,
        food_price,
        lag(food_price) over (order by payroll_year) as previous_food_price
    from  t_jana_veverkova_project_SQL_secondary_final
)
-- Finální výpočet včetně meziročních změn v procentech
select 
    payroll_year,
    gdp,
    previous_gdp,
    gdp_growth,
    average_wages,
    previous_average_wages,
    round(cast((average_wages - previous_average_wages) / 
        previous_average_wages * 100 as numeric), 2) as wages_growth,
    food_price,
    previous_food_price,
    round(cast((food_price - previous_food_price) / 
        previous_food_price * 100 as numeric), 2) as food_price_growth,
    lag(gdp_growth) over (order by payroll_year) as previous_year_gdp_growth
from gdp_growth_calc;

select
	payroll_year as rok,
	gdp_growth as rust_hdp,
	wages_growth as rust_mezd,
	food_price_growth as rust_cen_potravin,
	previous_year_gdp_growth as rust_hdp_predchozi_rok,
	case
		when gdp_growth > 5 then 'výrazný růst HDP'
		when gdp_growth < -2 then 'výrazný pokles HDP'
		when gdp_growth < 0 then 'mírný pokles HDP'
		else 'mírný růst HDP'
	end as hdp_kategorie,
	case
		when abs(wages_growth - gdp_growth) <= 1  then 'koreluje s HDP'
		when wages_growth > gdp_growth then 'mzdy rostou rychleji než HDP'
		else 'HDP roste rychleji než mzdy'
	end as vztah_mzdy_hdp,
	case 
		when abs(food_price_growth - gdp_growth) <= 1 then 'koreluje s HDP'
		when food_price_growth > gdp_growth then 'ceny potravin rostou rychleji'
		else 'HDP roste rychleji než ceny potravin'		
	end as vztah_cen_potravin_hdp,
	case
		when abs(wages_growth - previous_year_gdp_growth) <= 1 then 'koreluje s HDP předchozího roku'
		when wages_growth > previous_year_gdp_growth then 'mzdy rostou rychleji než loňské HDP'
		else 'loňské HDP rostlo rychleji než mzdy'
	end as vztah_mzdy_lonske_hdp,
	case
		when abs(food_price_growth -previous_year_gdp_growth) <= 1 then 'koreluje s HDP předchozího roku'
		when food_price_growth > previous_year_gdp_growth then 'ceny potravin rostou rychleji než loňské HDP'
		else 'loňské HDP rostlo rychleji než ceny potravin'
	end as vztah_cen_potravin_lonske_hdp	
from v_jana_veverkova_growth_overview
where payroll_year > 2006
order by payroll_year;

-- Korelační analýza - zjištění statistické souvislosti mezi ukazateli
select
    corr(gdp_growth, wages_growth) as korelace_hdp_mzdy,
    corr(gdp_growth, food_price_growth) as korelace_hdp_ceny_potravin,
    corr(previous_year_gdp_growth, wages_growth) as korelace_lonske_hdp_mzdy,
    corr(previous_year_gdp_growth, food_price_growth) as korelace_lonske_hdp_ceny_potravin
from v_jana_veverkova_growth_overview
where payroll_year > 2006;

-- Doplňkový dotaz - počet let, kdy mzdy korelovaly s HDP
select
    sum(case 
        when abs(wages_growth - gdp_growth) <= 1 then 1 
        else 0 
    end) as pocet_korelace_mzdy_hdp
from v_jana_veverkova_growth_overview
where payroll_year > 2006; ------ 3 roky

-- Doplňkový dotaz - počet let, kdy mzdy rostly rychleji než HDP
select
    sum(case 
        when wages_growth > gdp_growth and abs(wages_growth - gdp_growth) > 1 then 1 
        else 0 
    end) as pocet_mzdy_rychleji
from v_jana_veverkova_growth_overview
where payroll_year > 2006;

-- Doplňkový dotaz - počet let, kdy HDP rostlo rychleji než mzdy
select
    sum(case 
        when wages_growth < gdp_growth and abs(wages_growth - gdp_growth) > 1 then 1 
        else 0 
    end) as pocet_hdp_rychleji_nez_mzdy
from v_jana_veverkova_growth_overview
where payroll_year > 2006;

-- Doplňkový dotaz - počet let, kdy ceny potravin korelovaly s HDP
select
    sum(case 
        when abs(food_price_growth - gdp_growth) <= 1 then 1 
        else 0 
    end) as pocet_korelace_ceny_hdp
from v_jana_veverkova_growth_overview
where payroll_year > 2006;

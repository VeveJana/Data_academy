create table t_jana_veverkova_project_SQL_secondary_final as
select
	cp.payroll_year,
	e.gdp,
	avg(cp.value) as average_wages,
	avg(cp2.value) as food_price
from czechia_payroll cp
join economies e on e.year = cp.payroll_year
	and e.country = 'Czech Republic'
left join czechia_price cp2
	on date_part ('year', cp2.date_from) = cp.payroll_year
where cp.value_type_code = 5958
	and cp2.value is not null
	and cp.value is not null
group by cp.payroll_year, e.gdp
order by cp.payroll_year;



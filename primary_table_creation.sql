create table t_jana_veverkova_project_SQL_primary_final as
select 
    cp.payroll_year,
    cp.value as average_wages,
    cpib.name as industry_name,
    cp2.value as food_price,
    cp2.category_code,
    cpc.name as food_category_name,
    cpc.price_value,
    cpc.price_unit
from czechia_payroll cp
join czechia_payroll_industry_branch as cpib
    on cp.industry_branch_code = cpib.code
left join czechia_price as cp2
    on date_part('year', cp2.date_from) = cp.payroll_year
    and date_part('quarter', cp2.date_from) = cp.payroll_quarter
left join czechia_price_category cpc
    on cp2.category_code = cpc.code
where cp.value_type_code = 5958  
order by
    cp.payroll_year;

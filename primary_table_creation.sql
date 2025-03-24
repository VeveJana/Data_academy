CREATE TABLE t_jana_veverkova_project_SQL_primary_final AS
SELECT 
    cp.payroll_year,
    cp.value AS average_wages,
    cpib.name AS industry_name,
    cp2.value AS food_price,
    cp2.category_code,
    cpc.name AS food_category_name,
    cpc.price_value,
    cpc.price_unit
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch AS cpib
    ON cp.industry_branch_code = cpib.code
LEFT JOIN czechia_price AS cp2
    ON DATE_PART('year', cp2.date_from) = cp.payroll_year
    AND DATE_PART('quarter', cp2.date_from) = cp.payroll_quarter
LEFT JOIN czechia_price_category cpc
    ON cp2.category_code = cpc.code
WHERE cp.value_type_code = 5958  
ORDER BY
    cp.payroll_year;

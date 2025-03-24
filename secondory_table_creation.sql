CREATE TABLE t_jana_veverkova_project_SQL_secondary_final AS
SELECT
    cp.payroll_year,
    e.gdp,
    AVG(cp.value) AS average_wages,
    AVG(cp2.value) AS food_price
FROM czechia_payroll cp
JOIN economies e 
    ON e.year = cp.payroll_year
    AND e.country = 'Czech Republic'
LEFT JOIN czechia_price cp2
    ON DATE_PART('year', cp2.date_from) = cp.payroll_year
WHERE cp.value_type_code = 5958
    AND cp2.value IS NOT NULL
    AND cp.value IS NOT NULL
GROUP BY cp.payroll_year, e.gdp
ORDER BY cp.payroll_year;

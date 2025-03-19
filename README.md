# Analýza vztahu mezd, cen potravin a HDP v České republice

## Popis projektu
Tento projekt analyzuje data o mzdách, cenách potravin a HDP v České republice za období 2006-2018. Cílem je zodpovědět několik výzkumných otázek týkajících se vztahů mezi těmito ekonomickými ukazateli a identifikovat zajímavé trendy a korelace.

## Použitá data
Projekt pracuje s daty z Portálu otevřených dat ČR, která jsou zpracována do dvou hlavních tabulek:
- `t_jana_veverkova_project_SQL_primary_final` - obsahuje data o mzdách v různých odvětvích a cenách potravin
- `t_jana_veverkova_project_SQL_secondary_final` - obsahuje agregovaná data o HDP, průměrných mzdách a cenách potravin

## Struktura repozitáře
- `primary_table_creation.sql` - skript pro vytvoření primární tabulky s daty o mzdách a cenách potravin
- `secondary_table_creation.sql` - skript pro vytvoření sekundární tabulky s daty o HDP
- `research_questions.sql` - dotazy pro zodpovězení výzkumných otázek 1-5
- `analysis_results.pdf` - dokument s odpověďmi na výzkumné otázky

## Výzkumné otázky
Projekt se zabývá následujícími výzkumnými otázkami:

1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
3. Která kategorie potravin zdražuje nejpomaleji?
4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
5. Má výška HDP vliv na změny ve mzdách a cenách potravin?

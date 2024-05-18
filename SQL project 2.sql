SELECT * FROM project.coviddeaths
order by 1, 2;

SELECT * FROM project.covidvaccinations
order by 1, 2;

SELECT location, date, total_cases, new_cases, total_deaths, population 
from project.coviddeaths
order by  1, 2;

-- Looking at Total Cases vs Total Deaths and likelihood of covid dying in India

SELECT location, date, total_cases, total_deaths, (total_cases/ total_deaths)* 100 AS DeathPercentage
from project.coviddeaths
where location= 'India'
order by 1, 3;

-- Looking at Total Cases vs Population and percentage of polpuation got covid

SELECT location, date, total_cases, population, (total_cases/ population)* 100 AS CovidPopulationPercentage
from project.coviddeaths
where location= 'India'
order by 1, 3;

-- Looking at countries with Highest Infection Rate compared to Population

SELECT location,  population, MAX(total_cases) AS HighestIfectionCount,
 MAX((total_cases/ population))* 100 AS CovidPopulationPercentage
from project.coviddeaths
GROUP BY location,  population
order by CovidPopulationPercentage desc;

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM project.coviddeaths
WHERE continent <> ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Looking information by continent 

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM project.coviddeaths
WHERE continent = ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

 -- Global Numbers 
 
 SELECT DATE, sum(cast(new_cases as unsigned)) AS totalcases, sum(cast(new_deaths as unsigned)) AS totaldeaths, 
 sum(cast(new_deaths as unsigned))/ sum(cast(new_cases as unsigned))* 100 as deathpercentage 
 from project.coviddeaths
 where continent<> ''
 group by date
 order by 2;
 
-- Looking into average daily cases and deaths

SELECT date, avg(cast(new_cases as unsigned)) AS averagecases, 
avg(cast(new_deaths as unsigned)) AS averagedeaths,
avg(cast(new_deaths as unsigned))/ avg(cast(new_cases as unsigned))* 100 as percetage
from project.coviddeaths
where continent<> '' 
group by date
order by averagecases;

-- Looking into percentage change in new cases compared to the previous day

WITH cases_per_day AS  
(SELECT date, new_cases, 
row_number() OVER(order by date) rn1 
from  project.coviddeaths)
SELECT t1.date, t1.new_cases,
round(coalesce((t1.new_cases- t2.new_cases)*1.0/ t2.new_cases,0)*100,2)
 as percentage_increase
from cases_per_day t1
left join cases_per_day t2 on t1.rn1= t2.rn1+1;

-- Looking into percentage change in deaths compared to the previous day

WITH deaths_per_day AS 
(SELECT date, new_deaths,
row_number() OVER(order by date) rn1
from project.coviddeaths)
SELECT t1.date, t1.new_deaths,
round(coalesce((t1.new_deaths- t2.new_deaths)*1.0/t2.new_deaths,0)*100,2) 
as percentage_change
from deaths_per_day t1
left join deaths_per_day t2 on t1.rn1= t2.rn1+1;

-- Looking into covidvaccinations

-- Looking at Total Population vs Vaccination

SELECT v.continent, v.location, v.date, d.population, 
nullif(v.new_vaccinations, '') as new_vacciantions
FROM project.covidvaccinations v
JOIN  project.coviddeaths d 
ON v.location= d.location
AND v.date= d.date
where v.continent<> ''
order by 1, 2, 3;

-- Looking into rolling total of people vaccinated and its percentage

WITH population_vs_vaccination (continent, location, date, population, new_vaccinations, Rolling_Total) as
(SELECT  v.continent, v.location, v.date, d.population,
nullif(v.new_vaccinations, '') as new_vacciantions,
 SUM(convert(new_vaccinations, unsigned)) 
over(partition by v.location order by v.location, v.date) as Rolling_Total
FROM project.covidvaccinations v
JOIN  project.coviddeaths d 
ON v.location= d.location
AND v.date= d.date
where v.continent<> '')
SELECT *, round((Rolling_Total/population)* 100,2) AS Percentage
FROM population_vs_vaccination;

-- Temp Table  

CREATE TABLE project.VaccinatedPopulationPercent (
continent varchar(355),
location varchar(355),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_Total numeric
);

Insert into project.VaccinatedPopulationPercent
SELECT  v.continent, v.location, v.date, d.population,
 CASE
    WHEN v.new_vaccinations = '' THEN NULL 
    ELSE v.new_vaccinations 
    END AS new_vaccinations,
    SUM(
    CASE WHEN v.new_vaccinations = '' THEN 0 
    ELSE v.new_vaccinations END) 
    OVER (PARTITION BY v.location ORDER BY v.location, d.date) 
    AS Rolling_Total
FROM project.covidvaccinations v
JOIN  project.coviddeaths d 
ON v.location= d.location
AND v.date= d.date;

SELECT *, round((Rolling_Total/population)* 100,2) AS Percentage
FROM VaccinatedPopulationPercent;

-- Creating View to store data for later visualization

CREATE VIEW  VaccinatedPopulationPercen  AS 
SELECT  v.continent, v.location, v.date, d.population,
 CASE
    WHEN v.new_vaccinations = '' THEN NULL 
    ELSE v.new_vaccinations 
    END AS new_vaccinations,
    SUM(
    CASE WHEN v.new_vaccinations = '' THEN 0 
    ELSE v.new_vaccinations END) 
    OVER (PARTITION BY v.location ORDER BY v.location, d.date) 
    AS Rolling_Total
FROM project.covidvaccinations v
JOIN  project.coviddeaths d 
ON v.location= d.location
AND v.date= d.date;


SELECT * FROM VaccinatedPopulationPercen



 
SELECT * 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

--SELECT * 
--FROM PortfolioProject.dbo.CovidVaccinations
--ORDER BY location, date

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY location, date

-- Total Cases vs. Total Deaths IN US

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as PercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states'
ORDER BY location, date

-- Total Cases vs. Population
-- Percent of population got Covid-19 IN US
SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentageCase
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states'
ORDER BY location, date

-- Country that have highest rate compare to population

SELECT location, population, MAX(total_cases) as HighestInfection, MAX((total_cases/population))*100 as PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC

-- Country that have highest death count

SELECT location, population, MAX(cast(total_deaths as int)) as DeathCounts
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY DeathCounts DESC

-- Sum it to Continent

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCounts
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
GROUP BY location
ORDER BY TotalDeathCounts DESC

-- Gobal numbers
SELECT date, SUM(new_cases) as Total_cases, SUM(CAST(new_deaths as INT)) as Total_Death, 
		SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 as PercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Looking at Total Population vs. Vaccinations

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, population,  new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths as dea
JOIN PortfolioProject.dbo.CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY dea.location, dea.date
)
SELECT *, (RollingPeopleVaccinated/population)*100 as PercentagePeopleVaccinated
FROM PopvsVac


-- TEMP TABLE

DROP TABLE if exists #PercentageVaccinated
CREATE TABLE #PercentageVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

INSERT INTO #PercentageVaccinated
SELECT dea.continent, dea.location, dea.date, population,  new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths as dea
JOIN PortfolioProject.dbo.CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY dea.location, dea.date

SELECT *, (rollingpeoplevaccinated/population)*100 as PercentagePeopleVaccinated
FROM #PercentageVaccinated

-- Create view to store data for visualizations
CREATE VIEW PercentagePopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, population,  new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject.dbo.CovidDeaths as dea
JOIN PortfolioProject.dbo.CovidVaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY dea.location, dea.date
DROP VIEW PercentageVaccinated
SELECT *, (RollingPeopleVaccinated/population)*100 as PercentageVaccinated
FROM PercentagePopulationVaccinated


-- Query used for tableau project

-- 1. Total Cases vs. Total Deaths

SELECT SUM(new_cases) as Total_cases, SUM(CAST(new_deaths as INT)) as Total_Death, 
		SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 as PercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
-- GROUP BY date

-- Double Check base off data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


--SELECT SUM(new_cases) as Total_cases, SUM(CAST(new_deaths as INT)) as Total_Death, 
--		SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 as PercentageDeath
--FROM PortfolioProject..CovidDeaths
--WHERE location = 'world'


-- 2. Total Death in every continent

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

SELECT location, SUM(CAST(new_deaths as INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- 3. % People Infected

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 
	as PercentagePeopleInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentagePeopleInfected DESC

-- 4. 

SELECT location, population, date, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 
	as PercentagePeopleInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population, date
ORDER BY PercentagePeopleInfected DESC
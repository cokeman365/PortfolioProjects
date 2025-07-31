SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE CONTINENT IS NOT NULL
ORDER BY 3,4;


SELECT * 
FROM PortfolioProject..CovidVaccinations
WHERE CONTINENT IS NOT NULL

ORDER BY 3,4;

--Select the Data that we are going to use

SELECT Location, date, total_cases, new_cases, total_deaths,new_deaths,population
FROM PortfolioProject..CovidDeaths
WHERE CONTINENT IS NOT NULL
ORDER BY Location,date;

--Looking at Total Cases Vs Total Deaths
--Demonstrates likelihood of dying from COVID in the United States between 2020-2024
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE total_cases > 0 --To avoid a division by zero error a
AND Location LIKE '%states%' 
AND Location NOT LIKE '%virgin%'
AND CONTINENT IS NOT NULL
ORDER BY 1,2;

--Looking at Total Cases VS Population
--Shows percentage of total population that contracted COVID
SELECT Location, date, total_cases, population as Population, (total_cases/population)*100 as TotalPopPercentage
FROM PortfolioProject..CovidDeaths
WHERE total_cases >= 0 --To avoid a division by zero error a
--AND Location LIKE '%states%' 
--AND Location NOT LIKE '%virgin%'
AND CONTINENT IS NOT NULL

ORDER BY 1,2;


--Looking at Countries with Highest Infection Rate when compared to Population
SELECT Location,Population, MAX(total_cases) AS PeakInfectionCases, MAX((total_cases/population))*100 as
	PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE CONTINENT IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

--Looking at Countries with Highest Death Count when compared to Population
SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE CONTINENT IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;


--Time to Narrow it Down By Continent

--Continents with Highest Death Count
SELECT Continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC;


 
--Global Figures

SELECT SUM(new_cases) AS total_cases, 
SUM(CAST(new_deaths as int)) AS total_deaths,
SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS TotalPercentage
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2;


--Observing at Total Population vs Vaccinations
--the INT data type can’t handle the size — it maxes out at 2,147,483,647.
--This change avoids overflow and allows you to track even large cumulative totals safely.


--Need to create a CTE or Temp table to use a new column

SELECT dea.continent, dea.location, dea.date, dea.population, CONVERT(BIGINT, vac.new_vaccinations) AS new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Counting_Vaccinated
	,(Counting_Vaccinated/population)*100 as 
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location= vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location,dea.date;

---USING CTE
WITH PopVsVac (Continent,location, Date, Population,new_vaccinations, Counting_Vaccinated,PercentVaccinated)

AS
(
SELECT 
	dea.continent,
	dea.location, 
	dea.date, 
	dea.population, 
	CONVERT(BIGINT, vac.new_vaccinations) AS new_vaccinations,
	SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Counting_Vaccinated,
	(SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / dea.population) * 100 AS PercentVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location= vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location,dea.date
)
SELECT *
FROM PopVsVac
ORDER by location,date

--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated

(
Continent NVARCHAR(255),
Location NVARCHAR(255),
DATE DATETIME,
Population NUMERIC,
new_vaccinations NUMERIC,
Counting_Vaccinated NUMERIC,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, CONVERT(BIGINT, vac.new_vaccinations) AS new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Counting_Vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location= vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location,dea.date;

SELECT *,(Counting_Vaccinated/population)*100 AS PercentVaccinated
FROM #PercentPopulationVaccinated
ORDER by location,date

--Creating View for Storing Data for later Visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, CONVERT(BIGINT, vac.new_vaccinations) AS new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Counting_Vaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location= vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL;
--ORDER BY dea.location,dea.date;




--SELECT TOP 100 * FROM [dbo].[CovidDeaths]
--ORDER BY 3, 4;

--SELECT TOP 100 * FROM [dbo].[CovidVaccinations]
--ORDER BY 3, 4;


--Select Data that we are  going to be using 

--SELECT dbo.CovidDeaths.location, date, total_cases, new_cases, total_deaths, population
--FROM [dbo].[CovidDeaths]
--ORDER BY 1,2 



--Looking at Total Cases vs Total Deaths
--Shows the likelihood of dying if you contract covid in your country
--SELECT dbo.CovidDeaths.location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS DeathPercentage
--FROM [dbo].[CovidDeaths]
--WHERE location='Turkey'
--ORDER BY 1,2 


--Total Cases vs Population
--Shows what percentage of the population got covid
--SELECT dbo.CovidDeaths.location, date, total_cases,population, ROUND((total_cases/population)*100,4) AS PercentPopulationInfected
--FROM [dbo].[CovidDeaths]
--WHERE location='Turkey'
--ORDER BY 1,2 

--Looking at countries that has highest infection rate compared to population
--Aggregate function yani MIN, MAX, COUNT, SUM SELECT komutundan sonra çaðýrýldýðý zaman bütün çaðýrýlanlar AGG function içerisinde 
--olmak zorunda, aþaðýdaki örnekteki gibi location population gibi aggregate function içerisinde olmayan kolonlar varsa bunlarý GROUP BY dan sonra eklemek
--zorundayýz. Eklemezsek ve her kolon aggregate function içerisinde deðilse error verir.

--SELECT dbo.CovidDeaths.location, population, MAX(total_cases) AS HighestCaseNumber ,population, 
--ROUND((MAX(total_cases/population))*100,4) AS MaxPercentPopulationInfected
--FROM [dbo].[CovidDeaths]
--GROUP BY dbo.CovidDeaths.location, population
--ORDER BY 1,2 

--Alttaki sorgu doðru çünkü MAX(total_cases) en son ölüm oranýný veriyor. Ara rakamlar deðil bir ülke 
--için olan toplam caseleri. MAX(total_cases/populatin) ise her row için bu hesabý yapýp sonra en büyük olanýný getiriyor. 
--SELECT 
--location,
--population,
--MAX(total_cases) as MaksimumCaseNumber,
--ROUND(MAX(total_cases)/population*100, 2) AS CasePopulationRate 
--FROM [dbo].[CovidDeaths]
--GROUP BY population,location
--ORDER BY 4 DESC


--The Countries With Highest Death Count per Population

--CAST(........AS..... Wanted Data Type) komutu ile sorgunun içerisinde veri çeþidini deðiþtirebiliriz. 
--Bu yöntem ile tabloda o kolonun veri çeþidi deðiþmez. Sadece o sorgu içinde deðiþir.

--SELECT location, population, MAX(cast(total_deaths as int)) AS MaksimumDeath
--,ROUND((MAX(total_deaths)/population)*100, 2) AS TotalDeathPerPopulation
--FROM [dbo].[CovidDeaths]
--WHERE continent IS NOT NULL
--GROUP BY location, population
--ORDER BY 3 DESC

--lets breaks things down by continent

--Aþaðýdaki sorgulardan alttaki location kýrýlýmlý olan daha doðru rakamlar veriyor. Bu yanlýþlýk sorgudan deðil veri setinden 
--kaynaklanýyor.

--SELECT continent, MAX(CAST(total_deaths AS int)) AS MaxDeathNumber
--FROM [dbo].[CovidDeaths]
--WHERE continent IS NOT NULL
--GROUP BY continent

--SELECT location, MAX(CAST(total_deaths AS int)) AS MaxDeathNumber
--FROM [dbo].[CovidDeaths]
--WHERE continent IS NULL
--GROUP BY location

--Showing Continets With The Highest Death Count

--SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathNumberIventially
--FROM [dbo].[CovidDeaths]
--WHERE continent IS NOT NULL
--GROUP BY continent
--ORDER BY 2 DESC

--GLOBAL NUMBERS

--SELECT 
--date,
--SUM(new_cases) AS TotalCases,
--SUM(CAST(new_deaths AS int)) AS TotalDeaths,
--(SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
--FROM [dbo].[CovidDeaths]
--WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY 1,2



--Total Population vs Total Vaccination

SELECT DEA.location, DEA.population, SUM(cast(new_vaccinations as int)) AS VaccinationNumber,  (SUM(cast(new_vaccinations as int))/population)*100 AS Rate
FROM  [dbo].[CovidDeaths] DEA
JOIN [dbo].[CovidVaccinations] VAC
ON DEA.location=VAC.location
AND DEA.date=VAC.date
--WHERE DEA.location='Turkey'
AND DEA.continent IS NOT NULL
GROUP BY DEA.location, population
ORDER BY Rate DESC


SELECT A.continent, A.location, A.date, A.population, B.new_vaccinations,
SUM(CONVERT(int, B.new_vaccinations)) OVER(Partition By A.location ORDER BY A.location, A.date)
AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM [dbo].[CovidDeaths] [A]
JOIN [dbo].[CovidVaccinations] [B]
ON [A].location=[B].location
AND [A].date=[B].date
WHERE A.continent IS NOT NULL
order by 2,3


-- USE CTE

With PopvsVac (continent, location, date, population,new_vaccination,RollingPeopleVaccinated)
as (
SELECT A.continent, A.location, A.date, A.population, B.new_vaccinations,
SUM(CONVERT(int, B.new_vaccinations)) OVER(Partition By A.location ORDER BY A.location, A.date)
AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM [dbo].[CovidDeaths] [A]
JOIN [dbo].[CovidVaccinations] [B]
ON [A].location=[B].location
AND [A].date=[B].date
WHERE A.continent IS NOT NULL
--order by 2,3
)

SELECT *, (RollingPeopleVaccinated/population)*100 AS Rate 
FROM PopvsVac


--TEMP TABLE



drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT A.continent, A.location, A.date, A.population, B.new_vaccinations,
SUM(CONVERT(int, B.new_vaccinations)) OVER(Partition By A.location ORDER BY A.location, A.date)
AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM [dbo].[CovidDeaths] [A]
JOIN [dbo].[CovidVaccinations] [B]
ON [A].location=[B].location
AND [A].date=[B].date
--WHERE A.continent IS NOT NULL
--order by 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 AS Rate 
FROM #PercentPopulationVaccinated


--Creating View to store data for Later Visualistions


Create View PercentPopulationVaccinated as
SELECT A.continent, A.location, A.date, A.population, B.new_vaccinations,
SUM(CONVERT(int, B.new_vaccinations)) OVER(Partition By A.location ORDER BY A.location, A.date)
AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM [dbo].[CovidDeaths] [A]
JOIN [dbo].[CovidVaccinations] [B]
ON [A].location=[B].location
AND [A].date=[B].date
WHERE A.continent IS NOT NULL
--order by 2,3


SELECT * FROM  PercentPopulationVaccinated
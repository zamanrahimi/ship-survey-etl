-- Bronze → Silver: SELECT TOP 5 from ship_survey.csv. Only this result is written to silver (ship_survey_top5.csv).
-- Run in database ShipSurveyDB (workflow creates it once and connects with -d ShipSurveyDB).
-- CREATE EXTERNAL DATA SOURCE is not allowed in master, so we use a user database.
-- Storage account placeholder YOUR_STORAGE_ACCOUNT is replaced at run time (e.g. by GitHub Actions).

-- Workspace Managed Identity to read bronze (database-scoped in user db)
-- Drop if exist (ignore errors on first run); then CREATE so BronzeADLS always exists for the SELECT
BEGIN TRY
    DROP EXTERNAL DATA SOURCE BronzeADLS;
END TRY
BEGIN CATCH
    SELECT 0; -- ignore drop error on first run (may add one row to output; workflow strips footer)
END CATCH;

BEGIN TRY
    DROP DATABASE SCOPED CREDENTIAL [https://YOUR_STORAGE_ACCOUNT.blob.core.windows.net/ship-bronze-data];
END TRY
BEGIN CATCH
    SELECT 0; -- ignore drop error on first run
END CATCH;

CREATE DATABASE SCOPED CREDENTIAL [https://YOUR_STORAGE_ACCOUNT.blob.core.windows.net/ship-bronze-data]
WITH IDENTITY = 'Managed Identity';

CREATE EXTERNAL DATA SOURCE BronzeADLS WITH (
    LOCATION = 'https://YOUR_STORAGE_ACCOUNT.blob.core.windows.net/ship-bronze-data',
    CREDENTIAL = [https://YOUR_STORAGE_ACCOUNT.blob.core.windows.net/ship-bronze-data]
);

SELECT TOP 5
    survey_id,
    response_date,
    vessel_name,
    vessel_type,
    flag_country,
    crew_size,
    safety_rating,
    satisfaction_rating,
    maintenance_rating,
    port_of_survey
FROM OPENROWSET(
    BULK 'ship_survey.csv',
    DATA_SOURCE = 'BronzeADLS',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS bronze;

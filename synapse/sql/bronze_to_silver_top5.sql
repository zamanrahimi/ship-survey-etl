-- Bronze → Silver: SELECT TOP 5 from ship_survey.csv. Only this result is written to silver (ship_survey_top5.csv).
-- Run in database ShipSurveyDB (workflow creates it once and connects with -d ShipSurveyDB).
-- CREATE EXTERNAL DATA SOURCE is not allowed in master, so we use a user database.
-- Storage account placeholder YOUR_STORAGE_ACCOUNT is replaced at run time (e.g. by GitHub Actions).

-- Workspace Managed Identity to read bronze (database-scoped in user db)
IF NOT EXISTS (SELECT 1 FROM sys.database_scoped_credentials WHERE name = 'https://YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/ship-bronze-data')
    CREATE DATABASE SCOPED CREDENTIAL [https://YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/ship-bronze-data]
    WITH IDENTITY = 'Managed Identity';

IF NOT EXISTS (SELECT 1 FROM sys.external_data_sources WHERE name = 'BronzeADLS')
    CREATE EXTERNAL DATA SOURCE BronzeADLS WITH (
        LOCATION = 'https://YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/ship-bronze-data',
        CREDENTIAL = [https://YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/ship-bronze-data]
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

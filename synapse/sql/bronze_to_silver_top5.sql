-- Bronze → Silver: SELECT TOP 5 from ship_survey.csv in bronze. Result is written to silver (ship_survey_top5.csv).
-- Run in database ShipSurveyDB. YOUR_STORAGE_ACCOUNT is replaced at run time (e.g. by GitHub Actions).
--
-- SQL users (e.g. sqladmin from GitHub Actions) cannot use Entra to access storage. They must use a
-- database-scoped credential. BronzeCredential with IDENTITY = 'Managed Identity' uses the Synapse
-- workspace Managed Identity (Terraform grants it Storage Blob Data Contributor on the account).

BEGIN TRY
    DROP EXTERNAL DATA SOURCE BronzeADLS;
END TRY
BEGIN CATCH
    SELECT 0;
END CATCH;

BEGIN TRY
    DROP DATABASE SCOPED CREDENTIAL BronzeCredential;
END TRY
BEGIN CATCH
    SELECT 0;
END CATCH;

CREATE DATABASE SCOPED CREDENTIAL BronzeCredential
WITH IDENTITY = 'Managed Identity';

CREATE EXTERNAL DATA SOURCE BronzeADLS WITH (
    LOCATION = 'https://YOUR_STORAGE_ACCOUNT.blob.core.windows.net/ship-bronze-data/',
    CREDENTIAL = BronzeCredential
);
GO

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

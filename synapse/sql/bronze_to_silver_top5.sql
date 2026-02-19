-- Bronze → Silver: SELECT TOP 5 from ship_survey.csv in bronze. Result is written to silver (ship_survey_top5.csv).
-- Run in database ShipSurveyDB. Placeholders replaced at run time: YOUR_STORAGE_ACCOUNT, YOUR_MASTER_KEY_PASSWORD.
--
-- Database-scoped credentials require a database master key. SQL users need the credential (Managed Identity)
-- to access storage; Terraform grants the workspace identity Storage Blob Data Contributor.

-- Ensure database master key exists (required before CREATE DATABASE SCOPED CREDENTIAL)
BEGIN TRY
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'YOUR_MASTER_KEY_PASSWORD';
END TRY
BEGIN CATCH
    -- Ignore if key already exists (e.g. from a previous run)
    SELECT 0;
END CATCH;

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

-- Bronze → Silver: SELECT TOP 5 from ship_survey.csv. Only this result is written to silver (ship_survey_top5.csv).
-- Run in database ShipSurveyDB (workflow creates it once and connects with -d ShipSurveyDB).
-- BronzeADLS = external data source pointing at the bronze container; workspace Managed Identity is used automatically (no credential).
-- Storage account placeholder YOUR_STORAGE_ACCOUNT is replaced at run time (e.g. by GitHub Actions).

-- Drop if exists (ignore on first run); then CREATE so BronzeADLS exists for the SELECT
BEGIN TRY
    DROP EXTERNAL DATA SOURCE BronzeADLS;
END TRY
BEGIN CATCH
    SELECT 0;
END CATCH;

-- No CREDENTIAL = serverless uses workspace Managed Identity (Terraform already granted it Storage Blob Data Contributor)
CREATE EXTERNAL DATA SOURCE BronzeADLS WITH (
    LOCATION = 'https://YOUR_STORAGE_ACCOUNT.blob.core.windows.net/ship-bronze-data'
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

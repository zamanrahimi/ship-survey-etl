-- Bronze → Silver: SELECT TOP 5 from ship_survey.csv in bronze. Result is written to silver (ship_survey_top5.csv).
-- Run in database ShipSurveyDB. YOUR_STORAGE_ACCOUNT is replaced at run time (e.g. by GitHub Actions).
-- Full path in BULK so there is no ambiguity: we read from bronze container in that storage account.

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
    BULK 'abfss://ship-bronze-data@YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/ship_survey.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS bronze;

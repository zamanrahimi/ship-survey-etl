-- Bronze → Silver: SELECT TOP 5 from ship_survey.csv. Only this result is written to silver (ship_survey_top5.csv).
-- Change the query for other analytics; the workflow uploads whatever this script returns to ship-silver-data.
-- Storage account placeholder is replaced at run time (e.g. by GitHub Actions) with actual value.

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
    BULK 'https://YOUR_STORAGE_ACCOUNT.dfs.core.windows.net/ship-bronze-data/ship_survey.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    HEADER_ROW = TRUE
) AS bronze;

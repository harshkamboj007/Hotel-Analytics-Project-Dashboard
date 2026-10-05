-- =============================================================================
-- USING THE HOTELDATABASE 
-- =============================================================================
USE hoteldatabase;
GO

-- =============================================================================
-- SCHEMA INITIALIZATION
-- =============================================================================
CREATE SCHEMA silver;
GO

-- =============================================================================
-- SILVER LAYER
-- =============================================================================
DROP TABLE IF EXISTS silver.hotel_data;
GO

CREATE TABLE silver.hotel_data (
    hotel                       NVARCHAR(50),
    lead_time                   INT,
    arrival_date                DATE,
    total_stay_nights           INT,
    total_guests                INT,
    meal                        NVARCHAR(20),
    country                     NVARCHAR(20),
    market_segment              NVARCHAR(50),
    distribution_channel        NVARCHAR(50),
    is_repeated_guest           INT,
    total_previous_bookings     INT,
    room_changed                INT,
    booking_changes             INT,
    deposit_type                NVARCHAR(20),
    agent                       INT,
    company                     INT,
    days_in_waiting_list        INT,
    customer_type               NVARCHAR(50),
    adr                         DECIMAL(10,2),
    required_car_parking_spaces INT,
    total_of_special_requests   INT,
    booking_status              NVARCHAR(20),
    reservation_status_date     DATE
);
GO

-- =============================================================================
-- STORED PROCEDURE: DATA CLEANSING & INSERTION (BRONZE -> SILVER)
-- =============================================================================
CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
  
    DECLARE @start_time DATETIME, 
            @end_time   DATETIME;

    BEGIN TRY
        SET @start_time = GETDATE();
        
        PRINT '==================================================';
        PRINT 'STARTING SILVER LAYER LOAD: silver.hotel_data';
        PRINT '==================================================';
        
        PRINT '>> Truncating table: silver.hotel_data';
        TRUNCATE TABLE silver.hotel_data;
  
        PRINT '>> Inserting data to table: silver.hotel_data';

        INSERT INTO silver.hotel_data (
            hotel,
            lead_time,
            arrival_date,
            total_stay_nights,
            total_guests,
            meal,
            country,
            market_segment,
            distribution_channel,
            is_repeated_guest,
            total_previous_bookings,
            room_changed,
            booking_changes,
            deposit_type,
            agent,
            company,
            days_in_waiting_list,
            customer_type,
            adr,
            required_car_parking_spaces,
            total_of_special_requests,
            booking_status,
            reservation_status_date
        )
        SELECT 
            TRIM(hotel) AS hotel,
    
            TRY_CAST(lead_time AS INT) AS lead_time,
    
            -- Safe Arrival Date Construction
            DATEFROMPARTS(
                        CAST(arrival_date_year AS INT),
                        MONTH(CAST(arrival_date_month + ' 1, ' + arrival_date_year AS DATE)),
                        CAST(arrival_date_day_of_month AS INT)
            ) AS arrival_date,
    
            -- Safe Stay Duration Aggregation
            COALESCE(TRY_CAST(stays_in_weekend_nights AS INT), 0) + 
            COALESCE(TRY_CAST(stays_in_week_nights AS INT), 0) AS total_stay_nights,
    
            -- Safe Guest Count Aggregation
            COALESCE(TRY_CAST(adults AS INT), 0) + 
            COALESCE(TRY_CAST(children AS INT), 0) + 
            COALESCE(TRY_CAST(babies AS INT), 0) AS total_śguests,
    
            TRIM(meal) AS meal,
            TRIM(country) AS country,
            TRIM(market_segment) AS market_segment,
            TRIM(distribution_channel) AS distribution_channel,
    
            TRY_CAST(is_repeated_guest AS INT) AS is_repeated_guest,
    
            -- Safe Previous Bookings Aggregation
            COALESCE(TRY_CAST(previous_cancellations AS INT), 0) + 
            COALESCE(TRY_CAST(previous_bookings_not_canceled AS INT), 0) AS total_previous_bookings,
    
            CASE 
                WHEN TRIM(reserved_room_type) <> TRIM(assigned_room_type) THEN 1 
                ELSE 0
            END AS room_changed,
    
            TRY_CAST(booking_changes AS INT) AS booking_changes,
            TRIM(deposit_type) AS deposit_type,
    
            -- Agent & Company String Cleansing
            TRY_CAST(NULLIF(TRIM(LOWER(agent)), 'null') AS INT) AS agent,
            TRY_CAST(NULLIF(TRIM(LOWER(company)), 'null') AS INT) AS company,
    
            TRY_CAST(days_in_waiting_list AS INT) AS days_in_waiting_list,
            TRIM(customer_type) AS customer_type,
            TRY_CAST(adr AS DECIMAL(10,2)) AS adr,
            TRY_CAST(required_car_parking_spaces AS INT) AS required_car_parking_spaces,
            TRY_CAST(total_of_special_requests AS INT) AS total_of_special_requests,
    
            CASE
                WHEN TRY_CAST(is_canceled AS INT) = 1 THEN 'Canceled'
                WHEN TRIM(reservation_status) = 'No-Show' THEN 'No-Show'
                WHEN TRIM(reservation_status) = 'Check-Out' THEN 'Check-Out'
                ELSE 'Other'
            END AS booking_status,
    
            TRY_CONVERT(DATE, reservation_status_date, 105) AS reservation_status_date
        FROM bronze.hotel_data;
    
        SET @end_time = GETDATE();
        
        PRINT '>> LOAD COMPLETED SUCCESSFULLY';
        PRINT '>> Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds';
        PRINT '==================================================';
    END TRY 
    BEGIN CATCH 
        PRINT '==================================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number:  ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
        PRINT 'Error State:   ' + CAST(ERROR_STATE() AS NVARCHAR(10));
        PRINT '==================================================';
    END CATCH
END;
GO

-- =============================================================================
-- EXECUTION
-- =============================================================================
EXEC silver.load_silver
GO

SELECT * FROM silver.hotel_data
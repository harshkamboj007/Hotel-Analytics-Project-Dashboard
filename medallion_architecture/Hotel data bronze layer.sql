-- =============================================================================
-- CREATING DATABASE
-- =============================================================================

create database HotelDatabase

-- =============================================================================
-- USING THE HOTELDATABASE 
-- =============================================================================

USE hoteldatabase;
GO
-- =============================================================================
-- CREATING BRONZE SCHEMA
-- =============================================================================

CREATE SCHEMA bronze;
GO

-- =============================================================================
-- BRONZE TABLE DDL (RAW LANDING ZONE - LOOSELY TYPED)
-- =============================================================================
DROP TABLE IF EXISTS bronze.hotel_data;
GO

CREATE TABLE bronze.hotel_data (
    hotel                       NVARCHAR(50),
    is_canceled                 NVARCHAR(10),
    lead_time                   NVARCHAR(10),
    arrival_date_year           NVARCHAR(10),
    arrival_date_month          NVARCHAR(20),
    arrival_date_week_number    NVARCHAR(10),
    arrival_date_day_of_month   NVARCHAR(10),
    stays_in_weekend_nights     NVARCHAR(10),
    stays_in_week_nights        NVARCHAR(10),
    adults                      NVARCHAR(10),
    children                    NVARCHAR(20),
    babies                      NVARCHAR(10),
    meal                        NVARCHAR(20),
    country                     NVARCHAR(20),
    market_segment              NVARCHAR(50),
    distribution_channel        NVARCHAR(50),
    is_repeated_guest           NVARCHAR(10),
    previous_cancellations      NVARCHAR(10),
    previous_bookings_not_canceled NVARCHAR(10),
    reserved_room_type          NVARCHAR(20),
    assigned_room_type          NVARCHAR(20),
    booking_changes             NVARCHAR(10),
    deposit_type                NVARCHAR(20),
    agent                       NVARCHAR(20),
    company                     NVARCHAR(20),
    days_in_waiting_list        NVARCHAR(10),
    customer_type               NVARCHAR(50),
    adr                         NVARCHAR(20),
    required_car_parking_spaces NVARCHAR(10),
    total_of_special_requests   NVARCHAR(10),
    reservation_status          NVARCHAR(50),
    reservation_status_date     NVARCHAR(50)
);
GO

-- =============================================================================
-- STORED PROCEDURE: BRONZE LAYER ETL INGESTION
-- =============================================================================
CREATE OR ALTER PROCEDURE bronze.load_bronze 
AS
BEGIN
  
    DECLARE @start_time DATETIME, 
            @end_time   DATETIME;

    BEGIN TRY
        SET @start_time = GETDATE();
        
        PRINT '==================================================';
        PRINT 'STARTING BRONZE LAYER LOAD: bronze.hotel_data';
        PRINT '==================================================';
        
        PRINT '>> Truncating table: bronze.hotel_data';
        TRUNCATE TABLE bronze.hotel_data;

        PRINT '>> Bulk inserting raw data from CSV...';
        BULK INSERT bronze.hotel_data
        FROM 'C:\Users\Harsh Kamboj\OneDrive\Desktop\Practise and Data\Healthcare data\hotel_bookings.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

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
EXEC bronze.load_bronze;
GO
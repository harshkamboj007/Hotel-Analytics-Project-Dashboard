-- =============================================================================
-- USING THE HOTELDATABASE 
-- =============================================================================
USE hoteldatabase;
GO

-- =============================================================================
-- SCHEMA INITIALIZATION
-- =============================================================================
CREATE SCHEMA gold
GO

-- =============================================================================
-- GOLD VIEW CREATION 
-- =============================================================================
CREATE OR ALTER VIEW gold.hotel_data AS
SELECT
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
FROM silver.hotel_data;
GO

-- =============================================================================
-- VERIFICATION
-- =============================================================================
SELECT * FROM gold.hotel_data;
GO
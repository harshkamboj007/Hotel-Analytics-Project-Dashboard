-- =============================================================================
--      converting the different columns of date into one single column
-- =============================================================================
select DATEFROMPARTS(
        CAST(arrival_date_year AS INT),
        MONTH(CAST(arrival_date_month + ' 1, ' + arrival_date_year AS DATE)), -- '1' is used for changing the data type of VARCHAR to DATE.
        cast(arrival_date_day_of_month as int)
    ) AS arrival_date
from bronze.hotel_data



-- =============================================================================
--            Adding total stay column in place of two separate columns
-- =============================================================================
select 
	stays_in_weekend_nights + stays_in_week_nights  as total_stay_nights
from bronze.hotel_data



-- =============================================================================
--         checking for any distinct invalid values in the guest columns
-- =============================================================================
select distinct adults from bronze.hotel_data
select distinct children from bronze.hotel_data
select distinct babies from bronze.hotel_data



-- =============================================================================
-- handling the invalid data inside the children column and coverting the datatype to int
-- =============================================================================
select 
	COALESCE(TRY_CAST(adults AS INT), 0) + 
    COALESCE(TRY_CAST(children AS INT), 0) + 
    COALESCE(TRY_CAST(babies AS INT), 0) AS total_guests
from bronze.hotel_data



-- =============================================================================
--                adding new column in place of two columns
-- =============================================================================
select 
	previous_cancellations + previous_bookings_not_canceled as total_previous_bookings
from bronze.hotel_data



-- =============================================================================
-- assigning 1 or 0 int to room changed for building an business insight from this.
-- =============================================================================
select 
case 
	when reserved_room_type <> assigned_room_type then 1 
	else 0
	end as room_changed
from bronze.hotel_data



-- =============================================================================
--         checking for invalid data inside the agent and company column
-- =============================================================================
select distinct agent from bronze.hotel_data
where agent is null or upper(trim(agent)) IN ('NULL','', 'NA','N/A')

select distinct company from bronze.hotel_data
where company is null or upper(trim(company)) IN ('NULL','', 'NA','N/A')



-- =============================================================================
--        handling invalid data inside the agent and company column
-- =============================================================================
select case 
		when trim(agent) = 'NULL' then NULL
		else try_cast(agent as int) 
	end as agent
from bronze.hotel_data



-- =============================================================================
-- merging the data of two columns into one(is_canceled and reservation_status)
-- =============================================================================
select
	case
		when is_canceled = 1 then 'Canceled'
		when reservation_status = 'No-Show' then 'No-Show'
		when reservation_status = 'Check-Out' then 'Check-Out'
		else 'other'
	end as booking_status
from bronze.hotel_data



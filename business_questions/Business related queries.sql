	/*====================================================================
  HOTEL BOOKING ANALYSIS
  SQL Portfolio Project
  Database: Ecommerce / Hotel Analytics
  Source Table: gold.hotel_data

  Purpose:
  This script contains progressively advanced SQL analyses covering:
    1. Basic booking and hotel KPIs
    2. Segmentation and cancellation analysis
    3. Revenue and customer behavior analysis
    4. Advanced analysis using CTEs and window functions

  Key metrics:
    - Bookings
    - ADR (Average Daily Rate)
    - Stay duration
    - Revenue
    - Cancellation rate
    - Lead-time analysis
====================================================================*/


/********************************************************************
  LEVEL 1 — BASIC HOTEL PERFORMANCE ANALYSIS
********************************************************************/

-- Q1. How many bookings does each hotel receive?
SELECT
    hotel,
    COUNT(*) AS total_bookings
FROM gold.hotel_data
GROUP BY hotel
ORDER BY total_bookings DESC;


-- Q2. What is the average ADR for each hotel?
SELECT
    hotel,
    ROUND(AVG(adr), 2) AS avg_adr
FROM gold.hotel_data
GROUP BY hotel
ORDER BY avg_adr DESC;


-- Q3. What is the average length of stay for each hotel?
SELECT
    hotel,
    ROUND(AVG(total_stay_nights), 2) AS avg_stay_nights
FROM gold.hotel_data
GROUP BY hotel
ORDER BY avg_stay_nights DESC;


-- Q4. How many bookings were made in each month?
-- Month number is included to ensure chronological ordering.
SELECT
    YEAR(arrival_date) AS year_number,
    MONTH(arrival_date) AS month_number,
    DATENAME(MONTH, arrival_date) AS month_name,
    COUNT(*) AS total_bookings
FROM gold.hotel_data
GROUP BY
    YEAR(arrival_date),
    MONTH(arrival_date),
    DATENAME(MONTH, arrival_date)
ORDER BY
    year_number,
    month_number;


-- Q5. How many guests stayed at each hotel?
SELECT
    hotel,
    SUM(total_guests) AS total_guests
FROM gold.hotel_data
GROUP BY hotel
ORDER BY total_guests DESC;


-- Q6. What percentage of all bookings were cancelled by hotel?
-- This measures each hotel's share of ALL bookings that were cancelled.
WITH cancelled_cte AS (
    SELECT
        hotel,
        COUNT(*) AS cancelled_bookings
    FROM gold.hotel_data
    WHERE booking_status = 'canceled'
    GROUP BY hotel
)
SELECT
    hotel,
    cancelled_bookings,
    ROUND(
        cancelled_bookings * 100.0 /
        (SELECT COUNT(*) FROM gold.hotel_data),
        2
    ) AS cancellation_share_of_total_bookings
FROM cancelled_cte
ORDER BY cancellation_share_of_total_bookings DESC;


/********************************************************************
  LEVEL 2 — SEGMENTATION AND CANCELLATION ANALYSIS
********************************************************************/

-- Q7. Which market segment generates the most bookings?
SELECT TOP 1
    market_segment,
    COUNT(*) AS total_bookings
FROM gold.hotel_data
GROUP BY market_segment
ORDER BY total_bookings DESC;


-- Q8. What is the average ADR for each market segment?
SELECT
    market_segment,
    ROUND(AVG(adr), 2) AS avg_adr
FROM gold.hotel_data
GROUP BY market_segment
ORDER BY avg_adr DESC;


-- Q9. What percentage of cancelled bookings comes from each market segment?
WITH cancellation_cte AS (
    SELECT
        market_segment,
        COUNT(*) AS cancelled_bookings
    FROM gold.hotel_data
    WHERE booking_status = 'canceled'
    GROUP BY market_segment
)
SELECT
    market_segment,
    cancelled_bookings,
    ROUND(
        cancelled_bookings * 100.0 /
        SUM(cancelled_bookings) OVER(),
        2
    ) AS cancellation_share
FROM cancellation_cte
ORDER BY cancellation_share DESC;


-- Q10. How does average lead time differ between cancelled
-- and non-cancelled bookings?
SELECT
    booking_status,
    ROUND(AVG(lead_time), 2) AS avg_lead_time
FROM gold.hotel_data
GROUP BY booking_status
ORDER BY avg_lead_time DESC;


-- Q11. How does lead time affect the cancellation rate?
WITH lead_time_cte AS (
    SELECT
        CASE
            WHEN lead_time <= 30 THEN '0-30 days'
            WHEN lead_time <= 60 THEN '31-60 days'
            WHEN lead_time <= 90 THEN '61-90 days'
            WHEN lead_time <= 180 THEN '91-180 days'
            ELSE '181+ days'
        END AS lead_time_group,
        booking_status
    FROM gold.hotel_data
)
SELECT
    lead_time_group,
    COUNT(*) AS total_bookings,
    SUM(
        CASE
            WHEN booking_status = 'canceled' THEN 1
            ELSE 0
        END
    ) AS cancelled_bookings,
    ROUND(
        SUM(
            CASE
                WHEN booking_status = 'canceled' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate
FROM lead_time_cte
GROUP BY lead_time_group
ORDER BY
    CASE lead_time_group
        WHEN '0-30 days' THEN 1
        WHEN '31-60 days' THEN 2
        WHEN '61-90 days' THEN 3
        WHEN '91-180 days' THEN 4
        ELSE 5
    END;


-- Q12. How do average ADR and booking volume vary by month?
SELECT
    YEAR(arrival_date) as year,
    MONTH(arrival_date) AS month_number,
    DATENAME(MONTH, arrival_date) AS month_name,
    COUNT(*) AS total_bookings,
    ROUND(AVG(adr), 2) AS avg_adr
FROM gold.hotel_data
GROUP BY
    YEAR(arrival_date),
    MONTH(arrival_date),
    DATENAME(MONTH, arrival_date)
ORDER BY YEAR, month_number;


-- Q13. What is the average length of stay for each market segment?
SELECT
    market_segment,
    ROUND(AVG(total_stay_nights), 2) AS avg_stay_nights
FROM gold.hotel_data
GROUP BY market_segment
ORDER BY avg_stay_nights DESC;


-- Q14. Which distribution channels generate the most bookings?
SELECT
    distribution_channel,
    COUNT(*) AS total_bookings
FROM gold.hotel_data
GROUP BY distribution_channel
ORDER BY total_bookings DESC;


-- Q15. How do distribution channels compare in terms of
-- cancellation rate and share of cancelled bookings?
WITH channel_cancellation AS (
    SELECT
        distribution_channel,
        COUNT(*) AS total_bookings,
        SUM(
            CASE
                WHEN booking_status = 'canceled' THEN 1
                ELSE 0
            END
        ) AS cancelled_bookings
    FROM gold.hotel_data
    GROUP BY distribution_channel
)
SELECT
    distribution_channel,
    total_bookings,
    cancelled_bookings,
    ROUND(
        cancelled_bookings * 100.0 / total_bookings,
        2
    ) AS cancellation_rate,
    ROUND(
        cancelled_bookings * 100.0 /
        SUM(cancelled_bookings) OVER(),
        2
    ) AS cancellation_share
FROM channel_cancellation
ORDER BY cancellation_rate DESC;


/********************************************************************
  LEVEL 3 — REVENUE, CUSTOMER AND MONTHLY TREND ANALYSIS
********************************************************************/

-- Revenue definition used in this project:
-- ADR × total stay nights

-- Q16. What is the total revenue generated by each hotel?
SELECT
    hotel,
    SUM(adr * total_stay_nights) AS total_revenue
FROM gold.hotel_data
GROUP BY hotel
ORDER BY total_revenue DESC;


-- Q17. Which months generate the highest total revenue?
SELECT TOP 5
    MONTH(arrival_date) AS month_number,
    DATENAME(MONTH, arrival_date) AS month_name,
    SUM(adr * total_stay_nights) AS total_revenue
FROM gold.hotel_data
GROUP BY
    MONTH(arrival_date),
    DATENAME(MONTH, arrival_date)
ORDER BY total_revenue DESC;


-- Q18. What is the month-over-month revenue change?
WITH revenue_cte AS (
    SELECT
        YEAR(arrival_date) AS year_number,
        MONTH(arrival_date) AS month_number,
        DATENAME(MONTH, arrival_date) AS month_name,
        SUM(adr * total_stay_nights) AS total_revenue
    FROM gold.hotel_data
    GROUP BY
        YEAR(arrival_date),
        MONTH(arrival_date),
        DATENAME(MONTH, arrival_date)
),
revenue_comparison_cte AS (
    SELECT
        *,
        LAG(total_revenue) OVER (
            ORDER BY year_number, month_number
        ) AS previous_month_revenue
    FROM revenue_cte
)
SELECT
    year_number,
    month_name,
    total_revenue,
    previous_month_revenue,
    ROUND(
        (total_revenue - previous_month_revenue) * 100.0 /
        NULLIF(previous_month_revenue, 0),
        2
    ) AS mom_revenue_change
FROM revenue_comparison_cte
ORDER BY year_number, month_number;



-- Q19. What percentage of total revenue comes from each market segment?
WITH revenue_cte AS (
    SELECT
        market_segment,
        SUM(adr * total_stay_nights) AS total_revenue
    FROM gold.hotel_data
    GROUP BY market_segment
)
SELECT
    market_segment,
    total_revenue,
    ROUND(
        total_revenue * 100.0 /
        SUM(total_revenue) OVER(),
        2
    ) AS revenue_share
FROM revenue_cte
ORDER BY revenue_share DESC;


-- Q20. How does ADR differ between repeat and non-repeat guests?
SELECT
    CASE
        WHEN is_repeated_guest = 1 THEN 'Repeat Guest'
        ELSE 'Non-Repeat Guest'
    END AS guest_type,
    ROUND(AVG(adr), 2) AS avg_adr
FROM gold.hotel_data
GROUP BY is_repeated_guest
ORDER BY avg_adr DESC;


-- Q21. How does cancellation behavior differ between repeat
-- and non-repeat guests?
SELECT
    CASE
        WHEN is_repeated_guest = 1 THEN 'Repeat Guest'
        ELSE 'Non-Repeat Guest'
    END AS guest_type,
    COUNT(*) AS total_bookings,
    SUM(
        CASE
            WHEN booking_status = 'canceled' THEN 1
            ELSE 0
        END
    ) AS cancelled_bookings,
    ROUND(
        SUM(
            CASE
                WHEN booking_status = 'canceled' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate
FROM gold.hotel_data
GROUP BY is_repeated_guest
ORDER BY cancellation_rate DESC;


-- Q22. What percentage of bookings involved a room change?
SELECT
    CASE
        WHEN room_changed = 1 THEN 'Room Changed'
        ELSE 'Room Not Changed'
    END AS room_change_status,
    COUNT(*) AS total_bookings,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER(),
        2
    ) AS booking_share
FROM gold.hotel_data
GROUP BY room_changed
ORDER BY booking_share DESC;


/********************************************************************
  LEVEL 4 — ADVANCED ANALYSIS
********************************************************************/

-- Q23. How is revenue distributed across different stay-length buckets?
WITH stay_length_cte AS (
    SELECT
        CASE
            WHEN total_stay_nights <= 5 THEN 'Short Stay'
            WHEN total_stay_nights <= 10 THEN 'Mid Stay'
            WHEN total_stay_nights <= 20 THEN 'Long Stay'
            ELSE 'Longer Stay'
        END AS stay_bucket,
        adr * total_stay_nights AS total_revenue
    FROM gold.hotel_data
),
bucket_revenue AS (
    SELECT
        stay_bucket,
        COUNT(*) AS total_bookings,
        SUM(total_revenue) AS total_revenue
    FROM stay_length_cte
    GROUP BY stay_bucket
)
SELECT
    stay_bucket,
    total_bookings,
    total_revenue,
    ROUND(
        total_revenue * 100.0 /
        SUM(total_revenue) OVER(),
        2
    ) AS revenue_share,
    ROUND(
        total_bookings * 100.0 /
        sum(total_bookings) OVER(),
        2
    ) AS booking_share
FROM bucket_revenue
ORDER BY total_bookings DESC;


-- Q24. Which hotel and market-segment combinations generate
-- the highest revenue?
SELECT TOP 6
    hotel,
    market_segment,
    SUM(adr * total_stay_nights) AS total_revenue
FROM gold.hotel_data
GROUP BY
    hotel,
    market_segment
ORDER BY total_revenue DESC;



-- Q25. How did cancelled bookings change compared with the previous month?
WITH cancellation_cte AS (
    SELECT
        YEAR(arrival_date) AS year_number,
        MONTH(arrival_date) AS month_number,
        DATENAME(MONTH, arrival_date) AS month_name,
        SUM(
            CASE
                WHEN booking_status = 'canceled' THEN 1
                ELSE 0
            END
        ) AS cancelled_bookings
    FROM gold.hotel_data
    GROUP BY
        YEAR(arrival_date),
        MONTH(arrival_date),
        DATENAME(MONTH, arrival_date)
),
cancellation_comparison_cte AS (
    SELECT
        *,
        LAG(cancelled_bookings) OVER (
            ORDER BY year_number, month_number
        ) AS previous_month_cancellations
    FROM cancellation_cte
)
SELECT
    year_number,
    month_name,
    cancelled_bookings,
    previous_month_cancellations,
    ROUND(
        (cancelled_bookings - previous_month_cancellations) * 100.0 /
        NULLIF(previous_month_cancellations, 0),
        2
    ) AS percentage_change_in_cancellations
FROM cancellation_comparison_cte
ORDER BY year_number, month_number;



-- Q26. Which months have average booking revenue above the
-- overall average booking revenue?
SELECT
    YEAR(arrival_date) AS year_number,
    MONTH(arrival_date) AS month_number,
    DATENAME(MONTH, arrival_date) AS month_name,
    ROUND(
        SUM(adr * total_stay_nights) / COUNT(*),
        2
    ) AS avg_booking_revenue
FROM gold.hotel_data
GROUP BY
    YEAR(arrival_date),
    MONTH(arrival_date),
    DATENAME(MONTH, arrival_date)
HAVING
    SUM(adr * total_stay_nights) / COUNT(*) >
    (
        SELECT
            SUM(adr * total_stay_nights) / COUNT(*)
        FROM gold.hotel_data
    )
ORDER BY
    year_number,
    month_number;


-- Q27. How do lead-time groups compare in terms of ADR,
-- booking volume and cancellation rate?
WITH lead_time_cte AS (
    SELECT
        adr,
        CASE
            WHEN lead_time <= 30 THEN '0-30 days'
            WHEN lead_time <= 60 THEN '31-60 days'
            WHEN lead_time <= 90 THEN '61-90 days'
            WHEN lead_time <= 180 THEN '91-180 days'
            ELSE '181+ days'
        END AS lead_time_group,
        booking_status,
        AVG(adr) OVER() AS overall_avg_adr
    FROM gold.hotel_data
)
SELECT
    lead_time_group,
    COUNT(*) AS total_bookings,
    ROUND(AVG(adr), 2) AS avg_adr,
    ROUND(MAX(overall_avg_adr), 2) AS overall_avg_adr,
    SUM(
        CASE
            WHEN booking_status = 'canceled' THEN 1
            ELSE 0
        END
    ) AS cancelled_bookings,
    ROUND(
        SUM(
            CASE
                WHEN booking_status = 'canceled' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate
FROM lead_time_cte
GROUP BY
    lead_time_group
ORDER BY
    CASE lead_time_group
        WHEN '0-30 days' THEN 1
        WHEN '31-60 days' THEN 2
        WHEN '61-90 days' THEN 3
        WHEN '91-180 days' THEN 4
        ELSE 5
    END;


/********************************************************************
  END OF HOTEL BOOKING ANALYSIS
********************************************************************/v
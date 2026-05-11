with trips as (

    select * from {{ ref('fct_trips') }}

)

select
    pickup_date,

    count(*) as total_trips,
    sum(passenger_count) as total_passengers,

    -- distance & duration
    avg(trip_distance) as avg_trip_distance_mi,
    avg(trip_duration_min) as avg_trip_duration_min,

    -- revenue
    sum(fare_amount) as total_fare,
    sum(tip_amount) as total_tips,
    sum(total_amount) as total_revenue,
    avg(total_amount) as avg_revenue_per_trip,

    -- segment counts
    countif(is_airport_pickup) as airport_trips,
    countif(is_weekend) as weekend_trips,
    countif(is_night) as night_trips

from trips
group by pickup_date

with trips as (

    select * from {{ ref('fct_trips') }}

)

select
    pickup_date,
    pickup_location_id,
    pickup_borough,
    pickup_zone,

    count(*) as total_trips,
    sum(passenger_count) as total_passengers,

    -- distance & duration
    avg(trip_distance) as avg_trip_distance_mi,
    avg(trip_duration_min) as avg_trip_duration_min,

    -- revenue
    sum(fare_amount) as total_fare,
    sum(tip_amount) as total_tips,
    sum(total_amount) as total_revenue

from trips
group by
    pickup_date,
    pickup_location_id,
    pickup_borough,
    pickup_zone

select
    pickup_date,
    pickup_location_id,
    pickup_borough,
    pickup_zone,

    count(*) as total_trips,
    sum(passenger_count) as total_passengers,

    -- distance & duration
    sum(trip_distance) as total_trip_distance_mi,
    sum(trip_duration_min) as total_trip_duration_min,
    avg(trip_distance) as avg_trip_distance_mi,
    avg(trip_duration_min) as avg_trip_duration_min,

    -- revenue
    sum(fare_amount) as total_fare,
    sum(tip_amount) as total_tips,
    sum(total_amount) as total_revenue,

    -- segments
    countif(is_airport_pickup) as airport_trips,
    countif(is_weekend) as weekend_trips,
    countif(is_night) as night_trips

from {{ ref('fct_trips') }}
group by
    pickup_date,
    pickup_location_id,
    pickup_borough,
    pickup_zone

select
    pickup_date,

    sum(total_trips) as total_trips,
    sum(total_passengers) as total_passengers,

    -- distance & duration
    safe_divide(sum(total_trip_distance_mi), sum(total_trips)) as avg_trip_distance_mi,
    safe_divide(sum(total_trip_duration_min), sum(total_trips)) as avg_trip_duration_min,

    -- revenue
    sum(total_fare) as total_fare,
    sum(total_tips) as total_tips,
    sum(total_revenue) as total_revenue,
    safe_divide(sum(total_revenue), sum(total_trips)) as avg_revenue_per_trip,

    -- segment counts
    sum(airport_trips) as airport_trips,
    sum(weekend_trips) as weekend_trips,
    sum(night_trips) as night_trips

from {{ ref('fct_daily_zone_metrics') }}
group by pickup_date

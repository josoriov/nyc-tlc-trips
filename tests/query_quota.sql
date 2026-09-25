with usage as (
    select coalesce(sum(total_bytes_billed), 0) as bytes_billed
    from `region-US`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
    where creation_time >= timestamp_trunc(current_timestamp(), month)
      and job_type = 'QUERY'
      and (statement_type is null or statement_type != 'SCRIPT')
)

select
    round(bytes_billed / pow(1024, 4), 3) as query_tib,
    round(100 * bytes_billed / pow(1024, 4), 1) as quota_percent
from usage
where bytes_billed >= 0.8 * pow(1024, 4)

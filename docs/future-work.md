# Future work

Desirable, non-blocking improvements for this portfolio project.

- **Visual proof**: add one sample results table alongside the architecture diagram in the README.
- **Dashboard**: `models/exposures.yml` references `nyc_taxi_demand_dashboard`; build and link it (e.g. Looker Studio) or remove the exposure.
- **Reproducibility**: add `requirements.txt` and `require-dbt-version` to `dbt_project.yml`.
- **Test depth**: source freshness tests plus unique/not_null on `fct_trips.trip_id`.
- **History**: squash the early ad-hoc commits into conventional messages.
- **AI/ML**: add a genuine demand-forecast model if targeting AI Engineer roles.
- **Naming**: align the LICENSE copyright holder with the commit author identity.

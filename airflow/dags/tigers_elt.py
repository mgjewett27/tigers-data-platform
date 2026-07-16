from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import os

# Tasks source the Tigers project's .env and call its venv/dbt by path,
# keeping Airflow's deps separate from the project's.
ENV = 'set -a && source "$HOME/tigers-data-platform/.env" && set +a && '
ALERT_EMAIL = os.environ.get("ALERT_EMAIL")

default_args = {
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "email": [ALERT_EMAIL] if ALERT_EMAIL else [],
    "email_on_failure": True,
    "email_on_retry": False,
}

with DAG(
    dag_id="tigers_elt",
    start_date=datetime(2026, 1, 1),
    schedule="0 12 * * *",     # daily ~7-8am ET, after prior day's games go final
    catchup=False,
    default_args=default_args,
    tags=["tigers", "elt"],
) as dag:

    ingest = BashOperator(
        task_id="ingest",
        bash_command=(
            ENV
            + 'cd "$HOME/tigers-data-platform" && '
            + '"$HOME/tigers-data-platform/.venv/bin/python" ingest_tigers.py'
        ),
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=(
            ENV
            + 'cd "$HOME/tigers-data-platform/Tigers_2026" && '
            + '"$HOME/tigers-data-platform/.venv/bin/dbt" build'
        ),
    )

    ingest >> dbt_build
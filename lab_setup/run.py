# work in progress file

import argparse
import os
import re
import sys
from pathlib import Path

from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))

from app.snowflake_client import SnowflakeClient  # noqa: E402
from app.config import SnowflakeConfig  # noqa: E402

SQL_SCRIPTS_DIR = Path(__file__).resolve().parent / "sql_scripts"

SECTION_DESCRIPTIONS = {
    "a_configuration.sql": "Configuration",
    "b_create_attendee_roles_and_users.sql": "Create attendee roles and users",
    "c_template_database.sql": "Template database",
    "d_git_repository_access.sql": "Git repository access",
    "e_template_tables.sql": "Template tables",
    "f_load_seed_data.sql": "Load seed data",
    "g_clone_attendee_databases.sql": "Clone attendee databases",
    "h_grant_attendee_database_access.sql": "Grant attendee database access",
}


def load_config() -> SnowflakeConfig:
    load_dotenv(REPO_ROOT / "backend" / ".env")
    return SnowflakeConfig(
        host=os.environ["SNOWFLAKE_HOST"],
        pat=os.environ["SNOWFLAKE_PAT"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        role=os.environ["SNOWFLAKE_ROLE"],
        database=None,
        schema=None,
    )


def render(sql: str, num_users: int, hol_password: str) -> str:
    sql = sql.replace("{{NUM_USERS}}", str(num_users))
    sql = sql.replace("{{HOL_PASSWORD}}", hol_password)
    return sql


def split_statements(sql: str) -> list[str]:
    """Split a script into individual statements on top-level semicolons,
    respecting $$ ... $$ blocks (EXECUTE IMMEDIATE bodies) so semicolons
    inside them don't split the statement early."""
    statements = []
    buf = []
    in_dollar_block = False
    for line in sql.splitlines():
        if line.strip().startswith("--"):
            continue
        buf.append(line)
        if "$$" in line:
            in_dollar_block = not in_dollar_block
        stripped = line.strip()
        if not in_dollar_block and stripped.endswith(";"):
            statement = "\n".join(buf).strip()
            if statement:
                statements.append(statement)
            buf = []
    trailing = "\n".join(buf).strip()
    if trailing:
        statements.append(trailing)
    return statements


def format_result(rows: list[dict]) -> str:
    if not rows:
        return "(no rows returned)"
    if len(rows) == 1 and len(rows[0]) == 1:
        return next(iter(rows[0].values())) or "(empty)"
    lines = []
    for row in rows:
        lines.append(", ".join(f"{k}={v}" for k, v in row.items()))
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--num-users", type=int, default=25)
    parser.add_argument("--hol-password", required=True)
    parser.add_argument(
        "--only",
        help="Run a single script by filename (e.g. f_load_seed_data.sql)",
    )
    args = parser.parse_args()

    config = load_config()
    client = SnowflakeClient(config)

    script_paths = sorted(SQL_SCRIPTS_DIR.glob("*.sql"))
    if args.only:
        script_paths = [p for p in script_paths if p.name == args.only]
        if not script_paths:
            print(f"No script named {args.only!r} found in {SQL_SCRIPTS_DIR}")
            sys.exit(1)

    total = len(script_paths)
    for step, path in enumerate(script_paths, start=1):
        description = SECTION_DESCRIPTIONS.get(path.name, path.name)
        print(f"\n[{step}/{total}] {path.name} — {description}")

        sql = render(path.read_text(), args.num_users, args.hol_password)
        statements = split_statements(sql)
        for stmt_num, statement in enumerate(statements, start=1):
            preview = re.sub(r"\s+", " ", statement).strip()
            if len(preview) > 100:
                preview = preview[:100] + "..."
            print(f"  ({stmt_num}/{len(statements)}) {preview}")

            try:
                rows = client.query(statement)
            except Exception as e:
                print(f"  FAILED: {e}")
                print(f"\nAborted at [{step}/{total}] {path.name}, statement {stmt_num}.")
                sys.exit(1)

            result = format_result(rows)
            for line in result.splitlines():
                print(f"      {line}")

        print(f"  [{step}/{total}] done: {description}")

    print(f"\nAll {total} sections completed successfully.")


if __name__ == "__main__":
    main()

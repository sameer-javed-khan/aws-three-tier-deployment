"""The only tier that talks to PostgreSQL; timestamps originate here."""
from datetime import datetime, timezone
import logging
import os

from fastapi import FastAPI, Query, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict, Field
import psycopg
from psycopg.rows import dict_row

logger = logging.getLogger("uvicorn.error")
app = FastAPI(title="Timestamp Notebook", docs_url=None, redoc_url=None, openapi_url=None)


class EntryInput(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")
    text: str = Field(min_length=1, max_length=2000)


class Entry(BaseModel):
    id: int
    text: str
    created_at: datetime


def connect():
    # Separate connection fields avoid URL-escaping problems in passwords.
    return psycopg.connect(
        host=os.environ["DB_HOST"], port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.getenv("DB_NAME", "notesdb"), user=os.getenv("DB_USER", "record_app"),
        password=os.environ["DB_PASSWORD"], connect_timeout=5, row_factory=dict_row,
        options="-c statement_timeout=5000 -c timezone=UTC",
    )


@app.exception_handler(psycopg.Error)
async def database_error(request: Request, exc: psycopg.Error):
    # Do not expose database credentials or connection details to the browser.
    logger.error("Database operation failed: %s", type(exc).__name__)
    return JSONResponse(status_code=503, content={"detail": "Database unavailable. Check the backend and database services."})


@app.middleware("http")
async def no_cache(request: Request, call_next):
    response = await call_next(request)
    response.headers["Cache-Control"] = "no-store"
    return response


@app.get("/api/health")
def health():
    with connect() as conn:
        conn.execute("SELECT 1 FROM entries LIMIT 1")
    return {"status": "ok", "database": "reachable"}


@app.post("/api/entries", response_model=Entry, status_code=201)
def insert_entry(entry: EntryInput):
    timestamp = datetime.now(timezone.utc)
    with connect() as conn:
        row = conn.execute(
            "INSERT INTO entries (text, created_at) VALUES (%s, %s) RETURNING id, text, created_at",
            (entry.text, timestamp),
        ).fetchone()
    return row


@app.get("/api/entries", response_model=list[Entry])
def retrieve_entries(limit: int = Query(default=100, ge=1, le=100)):
    with connect() as conn:
        return conn.execute(
            "SELECT id, text, created_at FROM entries ORDER BY id DESC LIMIT %s", (limit,),
        ).fetchall()

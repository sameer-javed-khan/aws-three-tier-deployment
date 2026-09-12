-- Run as the database administrator, connected to notesdb.
-- Create the record_app login separately; no passwords belong in this file.
CREATE TABLE IF NOT EXISTS public.entries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    text TEXT NOT NULL CHECK (char_length(btrim(text)) BETWEEN 1 AND 2000),
    created_at TIMESTAMPTZ NOT NULL
);
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE notesdb TO record_app;
GRANT USAGE ON SCHEMA public TO record_app;
GRANT SELECT, INSERT ON public.entries TO record_app;
GRANT USAGE, SELECT ON SEQUENCE public.entries_id_seq TO record_app;

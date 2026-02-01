CREATE TABLE public.events (
    id character varying(128) NOT NULL,
    app_name character varying(128) NOT NULL,
    user_id character varying(128) NOT NULL,
    session_id character varying(128) NOT NULL,
    invocation_id character varying(256) NOT NULL,
    author character varying(256) NOT NULL,
    actions bytea NOT NULL,
    long_running_tool_ids_json text,
    branch character varying(256),
    "timestamp" timestamp without time zone NOT NULL,
    content jsonb,
    grounding_metadata jsonb,
    custom_metadata jsonb,
    usage_metadata jsonb,
    citation_metadata jsonb,
    partial boolean,
    turn_complete boolean,
    error_code character varying(256),
    error_message character varying(1024),
    interrupted boolean,
    input_transcription jsonb,
    output_transcription jsonb
);

ALTER TABLE public.events OWNER TO postgres;

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id, app_name, user_id, session_id);

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_app_name_user_id_session_id_fkey FOREIGN KEY (app_name, user_id, session_id) REFERENCES public.sessions(app_name, user_id, id) ON DELETE CASCADE;

CREATE TABLE public.events (
    id character varying(128) NOT NULL,
    app_name character varying(128) NOT NULL,
    user_id character varying(128) NOT NULL,
    session_id character varying(128) NOT NULL,
    invocation_id character varying(256) NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    event_data jsonb
);

ALTER TABLE public.events OWNER TO postgres;

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id, app_name, user_id, session_id);

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_app_name_user_id_session_id_fkey FOREIGN KEY (app_name, user_id, session_id) REFERENCES public.sessions(app_name, user_id, id) ON DELETE CASCADE;

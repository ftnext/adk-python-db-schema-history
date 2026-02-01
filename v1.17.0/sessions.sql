CREATE TABLE public.sessions (
    app_name character varying(128) NOT NULL,
    user_id character varying(128) NOT NULL,
    id character varying(128) NOT NULL,
    state jsonb NOT NULL,
    create_time timestamp without time zone NOT NULL,
    update_time timestamp without time zone NOT NULL
);

ALTER TABLE public.sessions OWNER TO postgres;

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (app_name, user_id, id);

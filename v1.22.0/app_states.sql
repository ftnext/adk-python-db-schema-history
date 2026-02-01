CREATE TABLE public.app_states (
    app_name character varying(128) NOT NULL,
    state jsonb NOT NULL,
    update_time timestamp without time zone NOT NULL
);

ALTER TABLE public.app_states OWNER TO postgres;

ALTER TABLE ONLY public.app_states
    ADD CONSTRAINT app_states_pkey PRIMARY KEY (app_name);

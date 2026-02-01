CREATE TABLE public.user_states (
    app_name character varying(128) NOT NULL,
    user_id character varying(128) NOT NULL,
    state jsonb NOT NULL,
    update_time timestamp without time zone NOT NULL
);

ALTER TABLE public.user_states OWNER TO postgres;

ALTER TABLE ONLY public.user_states
    ADD CONSTRAINT user_states_pkey PRIMARY KEY (app_name, user_id);

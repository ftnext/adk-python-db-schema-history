CREATE TABLE public.adk_internal_metadata (
    key character varying(128) NOT NULL,
    value character varying(256) NOT NULL
);

ALTER TABLE public.adk_internal_metadata OWNER TO postgres;

ALTER TABLE ONLY public.adk_internal_metadata
    ADD CONSTRAINT adk_internal_metadata_pkey PRIMARY KEY (key);

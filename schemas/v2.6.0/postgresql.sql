CREATE TABLE "public"."adk_internal_metadata" (
    "key" character varying(128) NOT NULL,
    "value" character varying(256) NOT NULL,
    CONSTRAINT adk_internal_metadata_pkey PRIMARY KEY ("key")
);

CREATE TABLE "public"."app_states" (
    "app_name" character varying(128) NOT NULL,
    "state" jsonb NOT NULL,
    "update_time" timestamp NOT NULL,
    CONSTRAINT app_states_pkey PRIMARY KEY ("app_name")
);

CREATE TABLE "public"."events" (
    "id" character varying(128) NOT NULL,
    "app_name" character varying(128) NOT NULL,
    "user_id" character varying(128) NOT NULL,
    "session_id" character varying(128) NOT NULL,
    "invocation_id" character varying(256) NOT NULL,
    "timestamp" timestamp NOT NULL,
    "event_data" jsonb,
    CONSTRAINT events_pkey PRIMARY KEY ("id", "app_name", "user_id", "session_id")
);

CREATE INDEX idx_events_app_user_session_ts ON public.events USING btree (app_name, user_id, session_id, "timestamp" DESC);

ALTER TABLE ONLY "public"."events" ADD CONSTRAINT "events_app_name_user_id_session_id_fkey" FOREIGN KEY ("app_name", "user_id", "session_id") REFERENCES "public"."sessions" ("app_name", "user_id", "id") ON UPDATE NO ACTION ON DELETE CASCADE;

CREATE TABLE "public"."sessions" (
    "app_name" character varying(128) NOT NULL,
    "user_id" character varying(128) NOT NULL,
    "id" character varying(128) NOT NULL,
    "state" jsonb NOT NULL,
    "create_time" timestamp NOT NULL,
    "update_time" timestamp NOT NULL,
    CONSTRAINT sessions_pkey PRIMARY KEY ("app_name", "user_id", "id")
);

CREATE TABLE "public"."user_states" (
    "app_name" character varying(128) NOT NULL,
    "user_id" character varying(128) NOT NULL,
    "state" jsonb NOT NULL,
    "update_time" timestamp NOT NULL,
    CONSTRAINT user_states_pkey PRIMARY KEY ("app_name", "user_id")
);

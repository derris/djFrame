CREATE TABLE django_session
(
  session_key character varying(40) NOT NULL,
  session_data text NOT NULL,
  expire_date timestamp with time zone NOT NULL,
  CONSTRAINT django_session_pkey PRIMARY KEY (session_key)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE django_session
  OWNER TO "yardAdmin";;

-- Index: django_session_expire_date

-- DROP INDEX django_session_expire_date;

CREATE INDEX django_session_expire_date
  ON django_session
  USING btree
  (expire_date);;

-- Index: django_session_session_key_like

-- DROP INDEX django_session_session_key_like;

CREATE INDEX django_session_session_key_like
  ON django_session
  USING btree
  (session_key COLLATE pg_catalog."default" varchar_pattern_ops);;

CREATE TABLE django_content_type
(
  id serial NOT NULL,
  name character varying(100) NOT NULL,
  app_label character varying(100) NOT NULL,
  model character varying(100) NOT NULL,
  CONSTRAINT django_content_type_pkey PRIMARY KEY (id),
  CONSTRAINT django_content_type_app_label_model_key UNIQUE (app_label, model)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE django_content_type
  OWNER TO "yardAdmin";;


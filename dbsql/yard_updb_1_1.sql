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

ALTER TABLE contract
  ADD COLUMN pre_inport_date date;
COMMENT ON COLUMN contract.pre_inport_date IS '预计到港日期';

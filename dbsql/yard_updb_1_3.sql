CREATE TABLE oper_log
(
  id serial NOT NULL,
  table_name character varying(30) NOT NULL, -- 表名
  key_value integer NOT NULL, -- 发生变化行的id
  oper_name character varying(30) NOT NULL, -- 操作员
  oper_type character varying(10) NOT NULL, -- 操作类型：增加、删除、修改
  oper_time timestamp without time zone NOT NULL, -- 操作时间
  oper_func_name character varying(50) NOT NULL, -- 操作func
  col1 character varying(200),
  col2 character varying(200),
  col3 character varying(200),
  col4 character varying(200),
  col5 character varying(200),
  col6 character varying(200),
  col7 character varying(200),
  col8 character varying(200),
  col9 character varying(200),
  col10 character varying(200),
  col11 character varying(200),
  col12 character varying(200),
  col13 character varying(200),
  col14 character varying(200),
  col15 character varying(200),
  col16 character varying(200),
  col17 character varying(200),
  col18 character varying(200),
  col19 character varying(200),
  col20 character varying(200),
  col21 character varying(200),
  col22 character varying(200),
  col23 character varying(200),
  col24 character varying(200),
  col25 character varying(200),
  col26 character varying(200),
  col27 character varying(200),
  col28 character varying(200),
  col29 character varying(200),
  col30 character varying(200),
  col31 character varying(200),
  col32 character varying(200),
  col33 character varying(200),
  col34 character varying(200),
  col35 character varying(200),
  col36 character varying(200),
  col37 character varying(200),
  col38 character varying(200),
  col39 character varying(200),
  col40 character varying(200),
  CONSTRAINT pk_oper_log PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE oper_log
  OWNER TO "yardAdmin";;
COMMENT ON TABLE oper_log
  IS '日志';;
COMMENT ON COLUMN oper_log.table_name IS '表名';;
COMMENT ON COLUMN oper_log.key_value IS '发生变化行的id';;
COMMENT ON COLUMN oper_log.oper_name IS '操作员';;
COMMENT ON COLUMN oper_log.oper_type IS '操作类型：增加、删除、修改';;
COMMENT ON COLUMN oper_log.oper_time IS '操作时间';;
COMMENT ON COLUMN oper_log.oper_func_name IS '操作func';;
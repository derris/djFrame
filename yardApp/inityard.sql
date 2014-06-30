--创建数据库
CREATE DATABASE {database_name}
  WITH OWNER = "yardAdmin"
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'zh_CN.UTF-8'
       LC_CTYPE = 'zh_CN.UTF-8'
       CONNECTION LIMIT = -1;
--系统表       
 CREATE TABLE sys_menu
(
  id serial NOT NULL,
  menuname character varying(50) NOT NULL, 
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  parent_id integer DEFAULT 0, -- 父功能ID
  menushowname character varying(50) NOT NULL, -- 菜单显示名称
  sortno smallint, -- 序号
  sys_flag boolean NOT NULL DEFAULT false, -- 系统功能，禁止用户一切操作
  CONSTRAINT pk_sys_menu PRIMARY KEY (id),
  CONSTRAINT fk_sys_menu_parent FOREIGN KEY (parent_id)
      REFERENCES sys_menu (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT uk_sys_menu_menu UNIQUE (menuname)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE sys_menu
  OWNER TO "yardAdmin";
COMMENT ON TABLE sys_menu
  IS '系统功能表';
COMMENT ON COLUMN sys_menu.menuname IS '功能名称';
COMMENT ON COLUMN sys_menu.parent_id IS '父功能ID
';
COMMENT ON COLUMN sys_menu.menushowname IS '菜单显示名称';
COMMENT ON COLUMN sys_menu.sortno IS '序号';
COMMENT ON COLUMN sys_menu.sys_flag IS '系统功能，禁止用户一切操作';

CREATE TABLE sys_func
(
  funcname character varying(50) NOT NULL, -- 权限名称
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  id serial NOT NULL,
  ref_tables character varying(100) NOT NULL DEFAULT ''::character varying, -- 涉及表，多表用‘，’分隔
  CONSTRAINT pk_sys_func PRIMARY KEY (id),
  CONSTRAINT uk_sys_func_func UNIQUE (funcname)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE sys_func
  OWNER TO "yardAdmin";
COMMENT ON TABLE sys_func
  IS '系统权限表';
COMMENT ON COLUMN sys_func.funcname IS '权限名称';
COMMENT ON COLUMN sys_func.ref_tables IS '涉及表，多表用‘，’分隔';

CREATE TABLE sys_menu_func
(
  id serial NOT NULL,
  menu_id integer NOT NULL, -- 功能ID
  func_id integer NOT NULL, -- 权限ID
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  CONSTRAINT pk_sys_menu_func PRIMARY KEY (id),
  CONSTRAINT fk_sys_menufunc_func FOREIGN KEY (func_id)
      REFERENCES sys_func (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_sys_menufunc_menu FOREIGN KEY (menu_id)
      REFERENCES sys_menu (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT uk_sys_menu_func UNIQUE (menu_id, func_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE sys_menu_func
  OWNER TO "yardAdmin";
COMMENT ON TABLE sys_menu_func
  IS '功能权限表';
COMMENT ON COLUMN sys_menu_func.menu_id IS '功能ID';
COMMENT ON COLUMN sys_menu_func.func_id IS '权限ID';

CREATE TABLE sys_code
(
  id serial NOT NULL,
  fld_eng character varying(20) NOT NULL, -- 英文字段名
  fld_chi character varying(30) NOT NULL, -- 中文字段名
  cod_name character varying(20) NOT NULL, -- 值名称
  fld_ext1 character varying(20) NOT NULL DEFAULT ''::character varying, -- 字段扩展1
  seq smallint NOT NULL, -- 序号
  fld_ext2 character varying(20) NOT NULL DEFAULT ''::character varying, -- 字段扩展值2
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  CONSTRAINT pk_sys_code PRIMARY KEY (id),
  CONSTRAINT uk_sys_code UNIQUE (fld_eng, cod_name)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE sys_code
  OWNER TO "yardAdmin";
COMMENT ON TABLE sys_code
  IS '系统参数表用户不可见';
COMMENT ON COLUMN sys_code.fld_eng IS '英文字段名';
COMMENT ON COLUMN sys_code.fld_chi IS '中文字段名';
COMMENT ON COLUMN sys_code.cod_name IS '值名称';
COMMENT ON COLUMN sys_code.fld_ext1 IS '字段扩展1';
COMMENT ON COLUMN sys_code.seq IS '序号';
COMMENT ON COLUMN sys_code.fld_ext2 IS '字段扩展值2';

INSERT INTO sys_menu(
            id, menuname, rec_nam, rec_tim, upd_nam, upd_tim, remark, parent_id, 
            menushowname, sortno, sys_flag)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 
            ?, ?, ?);



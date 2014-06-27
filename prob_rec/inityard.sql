CREATE DATABASE {database_name}
  WITH OWNER = "yardAdmin"
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'zh_CN.UTF-8'
       LC_CTYPE = 'zh_CN.UTF-8'
       CONNECTION LIMIT = -1;
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
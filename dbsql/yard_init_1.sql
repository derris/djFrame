--创建数据库
CREATE DATABASE {database_name}  WITH OWNER = "yardAdmin"
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'zh_CN.UTF-8'
       LC_CTYPE = 'zh_CN.UTF-8'
       CONNECTION LIMIT = -1;;
--创建系统权限表       
CREATE TABLE sys_menu
(
  id serial NOT NULL ,
  menuname character varying(50) NOT NULL, -- 功能名称
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
);;
ALTER TABLE sys_menu
  OWNER TO "yardAdmin";;
COMMENT ON TABLE sys_menu
  IS '系统功能表';;
COMMENT ON COLUMN sys_menu.menuname IS '功能名称';;
COMMENT ON COLUMN sys_menu.parent_id IS '父功能ID';;
COMMENT ON COLUMN sys_menu.menushowname IS '菜单显示名称';;
COMMENT ON COLUMN sys_menu.sortno IS '序号';;
COMMENT ON COLUMN sys_menu.sys_flag IS '系统功能，禁止用户一切操作';;
INSERT INTO sys_menu VALUES (0, '根节点', 1, '2014-02-24 10:57:39.013142', NULL, NULL, '', 0, '根节点', 1, true);;
INSERT INTO sys_menu VALUES (4, '系统管理', 1, '2014-02-24 08:56:51.619241', 1, '2014-02-24 08:29:12', '', 0, '系统管理', 1, true);;
INSERT INTO sys_menu VALUES (8, '基础数据管理', 1, '2014-02-25 11:00:30', 1, '2014-04-24 07:51:40', '', 0, '基础数据管理', 3, false);;
INSERT INTO sys_menu VALUES (13, '进口货运', 1, '2014-02-25 11:05:42', 1, '2014-04-24 07:51:40', '', 0, '进口货运', 4, false);;
INSERT INTO sys_menu VALUES (21, '商务', 1, '2014-02-25 11:30:27', 1, '2014-04-24 07:51:40', '', 0, '商务', 5, false);;
INSERT INTO sys_menu VALUES (43, '协议管理', 1, '2014-06-05 14:50:31', NULL, NULL, '', 0, '协议管理', 6, false);;
INSERT INTO sys_menu VALUES (33, '系统配置管理', 1, '2014-04-24 15:51:39', NULL, NULL, '', 0, '系统配置管理', 2, false);;

INSERT INTO sys_menu VALUES (5, '权限维护', 1, '2014-02-24 09:04:26.771803', NULL, NULL, '', 4, '权限维护', 2, true);;
INSERT INTO sys_menu VALUES (6, '功能权限维护', 1, '2014-02-24 09:05:06.975367', NULL, NULL, '', 4, '功能权限维护', 3, true);;
INSERT INTO sys_menu VALUES (7, '系统参数维护', 1, '2014-02-25 10:58:28', NULL, NULL, '', 4, '系统参数维护', 4, true);;
INSERT INTO sys_menu VALUES (18, '委托维护', 1, '2014-02-25 11:19:59', NULL, NULL, '', 13, '委托维护', 1, false);;
INSERT INTO sys_menu VALUES (3, '功能维护', 1, '2014-02-24 08:53:47.818424', 1, '2014-02-28 00:06:05', '', 4, '功能维护', 1, true);;
INSERT INTO sys_menu VALUES (32, '委托查询', 1, '2014-03-24 15:44:35', NULL, NULL, '', 13, '委托查询', 3, false);;
INSERT INTO sys_menu VALUES (19, '控货', 1, '2014-02-25 11:28:14', 1, '2014-03-24 07:44:35', '', 13, '控货', 6, false);;
INSERT INTO sys_menu VALUES (20, '委托费用维护', 1, '2014-02-25 11:29:48', 1, '2014-03-24 07:44:35', '', 13, '委托费用维护', 2, false);;
INSERT INTO sys_menu VALUES (31, '收款/付款', 1, '2014-03-19 09:21:20', NULL, NULL, '', 21, '收款/付款', 1, false);;
INSERT INTO sys_menu VALUES (22, '核销', 1, '2014-02-25 11:39:56', 1, '2014-03-19 01:21:20', '', 21, '核销', 2, false);;
INSERT INTO sys_menu VALUES (23, '取消核销', 1, '2014-02-25 11:39:56', 1, '2014-04-09 02:33:45', '', 21, '取消核销', 3, false);;
INSERT INTO sys_menu VALUES (25, '核销查询', 1, '2014-02-25 15:10:24', 1, '2014-04-10 02:40:53', '', 21, '核销查询', 4, false);;
INSERT INTO sys_menu VALUES (34, '密码修改', 1, '2014-04-24 15:53:50', NULL, NULL, '', 33, '密码修改', 1, false);;
INSERT INTO sys_menu VALUES (39, '账单', 1, '2014-05-06 16:37:55', NULL, NULL, '', 21, '账单', 5, false);;
INSERT INTO sys_menu VALUES (40, '业务明细报表', 1, '2014-05-08 15:12:17', NULL, NULL, '', 13, '业务明细报表', 4, false);;
INSERT INTO sys_menu VALUES (41, '业务汇总报表', 1, '2014-05-09 13:05:49', NULL, NULL, '', 13, '业务汇总报表', 5, false);;
INSERT INTO sys_menu VALUES (42, '费用报表定义', 1, '2014-05-20 15:09:45', NULL, NULL, '', 21, '费用报表定义', 6, false);;

INSERT INTO sys_menu VALUES (44, '协议维护', 1, '2014-06-05 14:51:19', NULL, NULL, '', 43, '协议维护', 1, false);;
INSERT INTO sys_menu VALUES (15, '委托动态类型维护', 1, '2014-02-25 11:15:17', 1, '2014-06-25 06:32:29', '', 8, '委托动态类型维护', 6, false);;
INSERT INTO sys_menu VALUES (29, '付款方式维护', 1, '2014-03-03 14:41:29', 1, '2014-06-27 02:56:36', '', 8, '付款方式维护', 8, false);;
INSERT INTO sys_menu VALUES (30, '客户维护', 1, '2014-03-15 21:43:10', 1, '2014-06-27 02:56:36', '', 8, '客户维护', 9, false);;

INSERT INTO sys_menu VALUES (9, '用户维护', 1, '2014-02-25 11:03:01', 1, '2014-06-27 02:49:46', '', 33, '用户维护', 2, false);;
INSERT INTO sys_menu VALUES (10, '岗位维护', 1, '2014-02-25 11:03:01', 1, '2014-06-27 02:49:46', '', 33, '岗位维护', 3, false);;
INSERT INTO sys_menu VALUES (11, '岗位用户维护', 1, '2014-02-25 11:03:01', 1, '2014-06-27 02:49:46', '', 33, '岗位用户维护', 4, false);;
INSERT INTO sys_menu VALUES (12, '岗位权限维护', 1, '2014-02-25 11:03:01', 1, '2014-06-27 02:49:46', '', 33, '岗位权限维护', 5, false);;
INSERT INTO sys_menu VALUES (45, '协议要素维护', 1, '2014-06-13 15:47:15', 1, '2014-06-27 02:54:47', '', 4, '协议要素维护', 5, true);;
INSERT INTO sys_menu VALUES (47, '协议模式定义', 1, '2014-06-17 10:37:33', 1, '2014-06-27 02:54:47', '', 4, '协议模式定义', 6, true);;
INSERT INTO sys_menu VALUES (48, '协议费用模式维护', 1, '2014-06-19 09:45:41', 1, '2014-06-27 02:54:47', '', 43, '协议费用模式维护', 3, true);;
INSERT INTO sys_menu VALUES (46, '协议要素内容维护', 1, '2014-06-13 17:05:36', 1, '2014-06-27 02:55:27', '', 43, '协议要素内容维护', 2, false);;
INSERT INTO sys_menu VALUES (49, '协议费率维护', 1, '2014-06-19 14:02:37', 1, '2014-06-27 02:55:27', '', 43, '协议费率维护', 4, false);;
INSERT INTO sys_menu VALUES (14, '箱型维护', 1, '2014-02-25 11:13:33', 1, '2014-06-27 02:56:36', '', 8, '箱型维护', 1, false);;
INSERT INTO sys_menu VALUES (35, '发货地维护', 1, '2014-04-24 18:12:20', 1, '2014-06-27 02:56:36', '', 8, '发货地维护', 2, false);;
INSERT INTO sys_menu VALUES (38, '产地维护', 1, '2014-05-05 18:01:46', 1, '2014-06-27 02:56:36', '', 8, '产地维护', 3, false);;
INSERT INTO sys_menu VALUES (37, '货物分类维护', 1, '2014-05-05 17:48:18', 1, '2014-06-27 02:56:36', '', 8, '货物分类维护', 4, false);;
INSERT INTO sys_menu VALUES (36, '货物维护', 1, '2014-05-05 17:39:26', 1, '2014-06-27 02:56:36', '', 8, '货物维护', 5, false);;
INSERT INTO sys_menu VALUES (16, '费用名称维护', 1, '2014-02-25 11:18:14', 1, '2014-06-27 02:56:36', '', 8, '费用名称维护', 7, false);;
INSERT INTO sys_menu VALUES (51, '协议费用生成', 1, '2014-02-25 11:18:14', 1, '2014-06-27 02:56:36', '', 21, '协议费用生成', 7, false);;
SELECT pg_catalog.setval('sys_menu_id_seq', 51, true);;
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
);;
ALTER TABLE sys_func
  OWNER TO "yardAdmin";;
COMMENT ON TABLE sys_func
  IS '系统权限表';;
COMMENT ON COLUMN sys_func.funcname IS '权限名称';;
COMMENT ON COLUMN sys_func.ref_tables IS '涉及表，多表用‘，’分隔';;

INSERT INTO sys_func VALUES ('功能查询', 1, '2014-02-26 09:58:42', 1, '2014-05-26 00:13:41', '', 1, 'sys_menu');;
INSERT INTO sys_func VALUES ('功能维护', 1, '2014-02-26 09:58:42', 1, '2014-05-26 00:13:41', '', 2, 'sys_menu');;
INSERT INTO sys_func VALUES ('权限查询', 1, '2014-02-26 09:59:14', 1, '2014-05-26 00:13:41', '', 3, 'sys_func');;
INSERT INTO sys_func VALUES ('权限维护', 1, '2014-02-26 09:59:14', 1, '2014-05-26 00:13:41', '', 4, 'sys_func');;
INSERT INTO sys_func VALUES ('功能权限查询', 1, '2014-03-01 09:26:20', 1, '2014-05-26 00:13:41', '', 7, 'sys_menu_func');;
INSERT INTO sys_func VALUES ('功能权限维护', 1, '2014-03-01 09:26:20', 1, '2014-05-26 00:15:07', '', 8, 'sys_menu_func');;
INSERT INTO sys_func VALUES ('系统参数查询', 1, '2014-03-01 09:26:53', 1, '2014-05-26 00:15:07', '', 9, 'sys_code');;
INSERT INTO sys_func VALUES ('系统参数维护', 1, '2014-03-01 09:26:53', 1, '2014-05-26 00:15:07', '', 10, 'sys_code');;
INSERT INTO sys_func VALUES ('岗位查询', 1, '2014-03-01 09:27:29', 1, '2014-05-26 00:15:07', '', 12, 's_post');;
INSERT INTO sys_func VALUES ('岗位维护', 1, '2014-03-01 09:27:29', 1, '2014-05-26 00:15:07', '', 13, 's_post');;
INSERT INTO sys_func VALUES ('岗位用户查询', 1, '2014-03-01 09:27:49', 1, '2014-05-26 00:15:07', '', 14, 's_postuser');;
INSERT INTO sys_func VALUES ('岗位用户维护', 1, '2014-03-01 09:27:49', 1, '2014-05-26 00:15:07', '', 15, 's_postuser');;
INSERT INTO sys_func VALUES ('用户查询', 1, '2014-03-01 09:30:58', 1, '2014-05-26 00:16:21', '', 16, 's_user');;
INSERT INTO sys_func VALUES ('用户维护', 1, '2014-03-01 09:30:58', 1, '2014-05-26 00:16:21', '', 17, 's_user');;
INSERT INTO sys_func VALUES ('箱型查询', 1, '2014-03-03 16:07:17', 1, '2014-05-26 00:16:21', '', 18, 'c_cntr_type');;
INSERT INTO sys_func VALUES ('箱型维护', 1, '2014-03-03 16:07:17', 1, '2014-05-26 00:16:21', '', 19, 'c_cntr_type');;
INSERT INTO sys_func VALUES ('动态类型查询', 1, '2014-03-03 16:21:26', 1, '2014-05-26 00:16:21', '', 22, 'c_contract_action');;
INSERT INTO sys_func VALUES ('产地查询', 1, '2014-05-05 18:02:07', 1, '2014-05-26 00:28:57', '', 62, 'c_place');;
INSERT INTO sys_func VALUES ('产地维护', 1, '2014-05-05 18:02:08', 1, '2014-05-26 00:28:57', '', 63, 'c_place');;
INSERT INTO sys_func VALUES ('动态类型维护', 1, '2014-03-03 16:21:26', 1, '2014-05-26 00:28:57', '', 23, 'c_contract_action');;
INSERT INTO sys_func VALUES ('发货地查询', 1, '2014-04-24 18:13:05', 1, '2014-05-26 00:28:57', '', 56, 'c_dispatch');;
INSERT INTO sys_func VALUES ('发货地维护', 1, '2014-04-24 18:13:05', 1, '2014-05-26 00:28:57', '', 57, 'c_dispatch');;
INSERT INTO sys_func VALUES ('费用报表头查询', 1, '2014-05-20 15:21:10', 1, '2014-05-26 00:30:13', '', 68, 'c_rpt');;
INSERT INTO sys_func VALUES ('委托维护', 1, '2014-03-26 10:41:14', 1, '2014-06-05 02:48:35', '', 38, 'contract,contract_action,contract_cntr');;
INSERT INTO sys_func VALUES ('费用报表项目查询', 1, '2014-05-20 15:21:10', 1, '2014-05-26 00:30:13', '', 69, 'c_rpt_item');;
INSERT INTO sys_func VALUES ('委托锁定', 1, '2014-03-26 12:49:23', 1, '2014-06-05 02:52:08', '', 39, 'contract');;
INSERT INTO sys_func VALUES ('费用名称查询', 1, '2014-03-03 16:39:33', 1, '2014-05-26 00:31:02', '', 24, 'c_fee');;
INSERT INTO sys_func VALUES ('费用名称维护', 1, '2014-03-03 16:39:33', 1, '2014-05-26 00:31:02', '', 25, 'c_fee');;
INSERT INTO sys_func VALUES ('付款方式查询', 1, '2014-03-26 10:34:27', 1, '2014-05-26 00:31:02', '', 30, 'c_pay_type');;
INSERT INTO sys_func VALUES ('付款方式维护', 1, '2014-03-26 10:34:27', 1, '2014-05-26 00:31:02', '', 31, 'c_pay_type');;
INSERT INTO sys_func VALUES ('岗位权限查询', 1, '2014-03-26 10:35:23', 1, '2014-05-26 00:31:02', '', 32, 's_postmenufunc');;
INSERT INTO sys_func VALUES ('岗位权限维护', 1, '2014-03-26 10:35:23', 1, '2014-05-26 00:31:02', '', 33, 's_postmenufunc');;
INSERT INTO sys_func VALUES ('核销', 1, '2014-04-09 10:29:32', 1, '2014-05-26 00:32:32', '', 48, 'pre_fee,act_fee');;
INSERT INTO sys_func VALUES ('费用报表头维护', 1, '2014-05-27 16:31:43', NULL, NULL, '', 72, 'c_rpt');;
INSERT INTO sys_func VALUES ('费用报表项目维护', 1, '2014-05-28 10:58:55', NULL, NULL, '', 73, 'c_rpt_item');;
INSERT INTO sys_func VALUES ('费用报表项目费用查询', 1, '2014-05-20 15:21:10', 1, '2014-05-29 00:12:42', '', 70, 'c_rpt_fee');;
INSERT INTO sys_func VALUES ('费用报表项目费用维护', 1, '2014-05-29 08:13:58', 1, '2014-05-29 00:20:28', '', 74, 'c_rpt_fee');;
INSERT INTO sys_func VALUES ('客户查询', 1, '2014-03-15 21:43:57', 1, '2014-06-05 02:36:55', '', 26, 'c_client');;
INSERT INTO sys_func VALUES ('客户维护', 1, '2014-03-15 21:43:57', 1, '2014-06-05 02:36:55', '', 27, 'c_client');;
INSERT INTO sys_func VALUES ('委托查询', 1, '2014-03-26 10:40:48', 1, '2014-06-05 02:46:53', '', 34, 'contract');;
INSERT INTO sys_func VALUES ('委托动态查询', 1, '2014-03-26 10:40:48', 1, '2014-06-05 02:46:53', '', 35, 'contract_action');;
INSERT INTO sys_func VALUES ('委托箱查询', 1, '2014-03-26 10:40:48', 1, '2014-06-05 02:46:53', '', 36, 'contract_cntr');;
INSERT INTO sys_func VALUES ('提单查询', 1, '2014-03-26 10:40:48', 1, '2014-06-05 02:47:30', '', 37, 'contract');;
INSERT INTO sys_func VALUES ('核销删除查询', 1, '2014-04-16 12:45:33', 1, '2014-06-05 02:52:08', '', 51, 'act_fee,pre_fee');;
INSERT INTO sys_func VALUES ('委托解锁', 1, '2014-03-26 12:49:23', 1, '2014-06-05 02:52:08', '', 40, 'contract');;
INSERT INTO sys_func VALUES ('委托应收查询', 1, '2014-03-29 11:31:25', 1, '2014-06-05 02:52:08', '', 41, 'pre_fee');;
INSERT INTO sys_func VALUES ('委托应付查询', 1, '2014-03-29 11:31:25', 1, '2014-06-05 02:52:08', '', 42, 'pre_fee');;
INSERT INTO sys_func VALUES ('应收付费用维护', 1, '2014-03-29 11:31:25', 1, '2014-06-05 02:52:08', '', 43, 'pre_fee');;
INSERT INTO sys_func VALUES ('应收付费用锁定', 1, '2014-03-31 14:04:02', 1, '2014-06-05 02:52:08', '', 44, 'pre_fee');;
INSERT INTO sys_func VALUES ('应收付费用解锁', 1, '2014-03-31 14:04:02', 1, '2014-06-05 02:52:08', '', 45, 'pre_fee');;
INSERT INTO sys_func VALUES ('实收付未核销查询', 1, '2014-04-09 10:28:53', 1, '2014-06-05 02:52:08', '', 46, 'act_fee');;
INSERT INTO sys_func VALUES ('应收付未核销查询', 1, '2014-04-09 10:29:18', 1, '2014-06-05 02:52:08', '', 47, 'pre_fee');;
INSERT INTO sys_func VALUES ('已收付费用查询', 1, '2014-04-16 12:41:48', 1, '2014-06-05 02:52:08', '', 49, 'act_fee');;
INSERT INTO sys_func VALUES ('已收付费用维护', 1, '2014-04-16 12:41:48', 1, '2014-06-05 02:52:08', '', 50, 'act_fee');;
INSERT INTO sys_func VALUES ('核销删除', 1, '2014-04-16 12:45:33', 1, '2014-06-05 02:52:08', '', 52, 'act_fee,pre_fee');;
INSERT INTO sys_func VALUES ('核销汇总查询', 1, '2014-04-16 12:46:47', 1, '2014-06-05 02:52:08', '', 53, 'act_fee,pre_fee');;
INSERT INTO sys_func VALUES ('核销明细查询', 1, '2014-04-16 12:46:47', 1, '2014-06-05 02:52:08', '', 54, 'act_fee,pre_fee');;
INSERT INTO sys_func VALUES ('密码修改', 1, '2014-04-24 15:54:21', 1, '2014-06-05 02:52:08', '', 55, 's_user');;
INSERT INTO sys_func VALUES ('货物查询', 1, '2014-05-05 17:49:21', 1, '2014-06-05 02:52:08', '', 58, 'c_cargo');;
INSERT INTO sys_func VALUES ('货物维护', 1, '2014-05-05 17:49:21', 1, '2014-06-05 02:52:08', '', 59, 'c_cargo');;
INSERT INTO sys_func VALUES ('货物分类查询', 1, '2014-05-05 17:49:21', 1, '2014-06-05 02:52:08', '', 60, 'c_cargo_type');;
INSERT INTO sys_func VALUES ('货物分类维护', 1, '2014-05-05 17:49:21', 1, '2014-06-05 02:52:08', '', 61, 'c_cargo_type');;
INSERT INTO sys_func VALUES ('客户费用明细报表', 1, '2014-05-06 16:38:30', 1, '2014-06-05 02:52:42', '', 64, 'contract,pre_fee');;
INSERT INTO sys_func VALUES ('业务明细报表查询', 1, '2014-05-08 15:13:14', 1, '2014-06-05 02:52:42', '', 65, 'contract,contract_action,contract_cntr');;
INSERT INTO sys_func VALUES ('业务汇总报表查询', 1, '2014-05-09 13:06:01', 1, '2014-06-05 02:52:42', '', 66, 'contract,contract_action,contract_cntr');;
INSERT INTO sys_func VALUES ('协议查询', 1, '2014-06-05 14:52:27', NULL, NULL, '', 76, 'p_protocol');;
INSERT INTO sys_func VALUES ('协议维护', 1, '2014-06-05 14:52:27', NULL, NULL, '', 77, 'p_protocol');;
INSERT INTO sys_func VALUES ('协议要素查询', 1, '2014-06-13 15:48:03', NULL, NULL, '', 78, 'p_fee_ele');;
INSERT INTO sys_func VALUES ('协议要素维护', 1, '2014-06-13 15:48:03', NULL, NULL, '', 79, 'p_fee_ele');;
INSERT INTO sys_func VALUES ('协议要素内容查询', 1, '2014-06-13 17:08:16', NULL, NULL, '', 80, 'p_fee_ele_lov');;
INSERT INTO sys_func VALUES ('协议要素内容维护', 1, '2014-06-13 17:08:16', NULL, NULL, '', 81, 'p_fee_ele_lov');;
INSERT INTO sys_func VALUES ('协议要素内容初始化', 1, '2014-06-13 17:08:16', NULL, NULL, '', 82, 'p_fee_ele_lov');;
INSERT INTO sys_func VALUES ('协议模式查询', 1, '2014-06-17 10:38:09', NULL, NULL, '', 83, 'p_fee_mod');;
INSERT INTO sys_func VALUES ('协议模式维护', 1, '2014-06-17 10:38:09', NULL, NULL, '', 84, 'p_fee_mod');;
INSERT INTO sys_func VALUES ('协议费用模式查询', 1, '2014-06-19 09:50:24', NULL, NULL, '', 85, 'p_protocol_fee_mod');;
INSERT INTO sys_func VALUES ('协议费用模式维护', 1, '2014-06-19 09:50:24', NULL, NULL, '', 86, 'p_protocol_fee_mod');;
INSERT INTO sys_func VALUES ('协议模式结构查询', 1, '2014-06-23 08:55:21', NULL, NULL, '', 87, 'p_fee_mod,p_fee_ele,p_fee_ele_lov');;
INSERT INTO sys_func VALUES ('协议费率维护', 1, '2014-06-23 08:58:08', 1, '2014-06-23 00:58:50', '', 88, 'p_protocol_rat');;
INSERT INTO sys_func VALUES ('协议费率查询', 1, '2014-06-23 08:59:13', 1, '2014-06-23 00:59:03', '', 89, 'p_protocol_rat');;
INSERT INTO sys_func VALUES ('模式描述查询', 1, '2014-06-23 08:59:13', 1, '2014-06-23 00:59:03', '', 90, 'p_fee_mod');;
INSERT INTO sys_func VALUES ('协议费用生成', 1, '2014-06-23 08:59:13', 1, '2014-06-23 00:59:03', '', 91, 'pre_fee');;
SELECT pg_catalog.setval('sys_func_id_seq', 91, true);;
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
);;
ALTER TABLE sys_menu_func
  OWNER TO "yardAdmin";;
COMMENT ON TABLE sys_menu_func
  IS '功能权限表';;
COMMENT ON COLUMN sys_menu_func.menu_id IS '功能ID';;
COMMENT ON COLUMN sys_menu_func.func_id IS '权限ID';;
INSERT INTO sys_menu_func VALUES (1, 3, 1, 1, '2014-02-28 09:15:46.284318', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (2, 3, 2, 1, '2014-03-01 07:32:45', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (10, 5, 3, 1, '2014-03-01 09:29:38', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (11, 5, 2, 1, '2014-03-01 09:29:38', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (12, 6, 7, 1, '2014-03-01 09:29:47', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (13, 6, 8, 1, '2014-03-01 09:29:47', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (14, 7, 9, 1, '2014-03-01 09:29:59', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (15, 7, 10, 1, '2014-03-01 09:29:59', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (16, 9, 16, 1, '2014-03-01 09:31:12', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (17, 9, 17, 1, '2014-03-01 09:31:12', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (18, 10, 12, 1, '2014-03-01 09:31:26', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (19, 10, 13, 1, '2014-03-01 09:31:26', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (20, 11, 14, 1, '2014-03-01 09:47:24', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (21, 11, 15, 1, '2014-03-01 09:47:31', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (22, 11, 12, 1, '2014-03-01 09:48:46', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (23, 12, 12, 1, '2014-03-01 09:48:54', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (24, 14, 18, 1, '2014-03-03 16:07:36', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (25, 14, 19, 1, '2014-03-03 16:07:36', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (28, 15, 22, 1, '2014-03-03 16:22:00', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (29, 15, 23, 1, '2014-03-03 16:22:00', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (30, 16, 24, 1, '2014-03-03 16:40:03', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (31, 16, 25, 1, '2014-03-03 16:40:03', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (32, 30, 26, 1, '2014-03-15 21:44:15', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (33, 30, 27, 1, '2014-03-15 21:44:15', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (36, 29, 30, 1, '2014-03-26 10:36:25', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (37, 29, 31, 1, '2014-03-26 10:36:25', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (38, 12, 32, 1, '2014-03-26 10:36:46', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (39, 12, 33, 1, '2014-03-26 10:36:46', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (40, 18, 34, 1, '2014-03-26 10:46:52', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (41, 18, 35, 1, '2014-03-26 10:46:52', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (42, 18, 36, 1, '2014-03-26 10:46:52', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (43, 18, 37, 1, '2014-03-26 10:46:52', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (44, 18, 38, 1, '2014-03-26 10:46:52', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (45, 18, 39, 1, '2014-03-26 12:49:44', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (46, 18, 40, 1, '2014-03-26 12:49:44', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (47, 20, 37, 1, '2014-03-28 10:17:29', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (48, 20, 41, 1, '2014-03-29 11:31:48', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (49, 20, 42, 1, '2014-03-29 11:31:48', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (50, 20, 43, 1, '2014-03-29 11:31:48', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (51, 20, 44, 1, '2014-03-31 14:04:27', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (52, 20, 45, 1, '2014-03-31 14:04:28', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (53, 22, 46, 1, '2014-04-09 10:30:52', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (54, 22, 47, 1, '2014-04-09 10:30:52', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (55, 22, 48, 1, '2014-04-09 10:30:52', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (56, 32, 34, 1, '2014-04-16 11:00:38', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (57, 32, 35, 1, '2014-04-16 11:01:55', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (58, 32, 36, 1, '2014-04-16 11:01:55', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (59, 32, 41, 1, '2014-04-16 11:01:55', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (60, 32, 42, 1, '2014-04-16 11:01:55', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (61, 31, 49, 1, '2014-04-16 12:42:22', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (62, 31, 50, 1, '2014-04-16 12:42:22', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (63, 23, 51, 1, '2014-04-16 12:45:58', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (64, 23, 52, 1, '2014-04-16 12:45:58', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (65, 25, 53, 1, '2014-04-16 12:47:05', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (66, 25, 54, 1, '2014-04-16 12:47:05', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (67, 34, 55, 1, '2014-04-24 15:54:32', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (68, 35, 56, 1, '2014-04-24 18:13:22', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (69, 35, 57, 1, '2014-04-24 18:13:22', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (70, 36, 58, 1, '2014-05-05 18:02:25', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (71, 36, 59, 1, '2014-05-05 18:02:25', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (72, 37, 60, 1, '2014-05-05 18:02:37', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (73, 37, 61, 1, '2014-05-05 18:02:37', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (74, 38, 62, 1, '2014-05-05 18:02:49', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (75, 38, 63, 1, '2014-05-05 18:02:49', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (76, 39, 64, 1, '2014-05-06 16:38:41', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (77, 40, 65, 1, '2014-05-08 15:13:37', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (78, 41, 66, 1, '2014-05-16 14:41:44', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (80, 42, 68, 1, '2014-05-20 15:21:41', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (81, 42, 69, 1, '2014-05-20 15:21:41', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (82, 42, 70, 1, '2014-05-20 15:21:41', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (83, 42, 73, 1, '2014-05-28 11:03:29', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (84, 42, 72, 1, '2014-05-28 11:03:29', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (85, 42, 74, 1, '2014-05-29 08:14:18', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (86, 44, 76, 1, '2014-06-05 14:52:56', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (87, 44, 77, 1, '2014-06-05 14:52:56', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (88, 45, 78, 1, '2014-06-13 15:48:35', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (89, 45, 79, 1, '2014-06-13 15:48:35', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (90, 46, 80, 1, '2014-06-13 17:08:50', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (91, 46, 81, 1, '2014-06-13 17:08:50', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (92, 46, 82, 1, '2014-06-13 17:08:50', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (93, 47, 76, 1, '2014-06-18 10:26:04', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (94, 47, 24, 1, '2014-06-18 10:26:04', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (95, 47, 83, 1, '2014-06-18 10:26:30', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (96, 47, 84, 1, '2014-06-19 09:47:04', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (97, 48, 76, 1, '2014-06-19 09:47:53', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (98, 48, 24, 1, '2014-06-19 09:47:53', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (100, 48, 85, 1, '2014-06-19 09:50:44', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (101, 48, 86, 1, '2014-06-19 09:50:44', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (102, 49, 76, 1, '2014-06-19 14:03:12', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (103, 49, 85, 1, '2014-06-20 08:59:27', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (104, 49, 87, 1, '2014-06-23 08:55:35', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (105, 49, 88, 1, '2014-06-23 08:58:36', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (106, 49, 89, 1, '2014-06-23 08:59:40', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (107, 46, 78, 1, '2014-06-23 08:59:40', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (108, 48, 90, 1, '2014-06-23 08:59:40', NULL, NULL, '');;
INSERT INTO sys_menu_func VALUES (109, 51, 91, 1, '2014-06-23 08:59:40', NULL, NULL, '');;
SELECT pg_catalog.setval('sys_menu_func_id_seq', 109, true);;
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
);;
ALTER TABLE sys_code
  OWNER TO "yardAdmin";;
COMMENT ON TABLE sys_code
  IS '系统参数表用户不可见';;
COMMENT ON COLUMN sys_code.fld_eng IS '英文字段名';;
COMMENT ON COLUMN sys_code.fld_chi IS '中文字段名';;
COMMENT ON COLUMN sys_code.cod_name IS '值名称';;
COMMENT ON COLUMN sys_code.fld_ext1 IS '字段扩展1';;
COMMENT ON COLUMN sys_code.seq IS '序号';;
COMMENT ON COLUMN sys_code.fld_ext2 IS '字段扩展值2';;

--
CREATE OR REPLACE FUNCTION fun4tri_s_user()
  RETURNS trigger AS
$BODY$begin
     if TG_OP = 'INSERT' then     
	if (NEW.username = 'Admin' or NEW.username = '管理员' or NEW.id = 1 or NEW.id = 2)then
		raise exception '禁止增加系统管理员';
	end if; 
	return NEW;    
     end if;
     if TG_OP = 'UPDATE' then
	if (OLD.username = 'Admin' or OLD.id = 1) then
		raise exception '禁止修改系统管理员';
	end if;    
	if ((OLD.username = '管理员' or OLD.id = 2 ) and (OLD.username <> NEW.username or OLD.id <> NEW.id)) then
		raise exception '禁止修改系统管理员';
	end if;    	
	return NEW;
     end if;
     if TG_OP = 'DELETE' then
	if (OLD.username = 'Admin' or OLD.username = '管理员' or OLD.id = 1 or OLD.id = 2) then
		raise exception '禁止删除系统管理员';
	end if;
     end if;
   return OLD;
end;     $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;;
ALTER FUNCTION fun4tri_s_user()
  OWNER TO "yardAdmin";;

CREATE TABLE s_user
(
  id serial NOT NULL,
  username character varying(10) NOT NULL, -- 用户名
  password character varying(40) NOT NULL, -- 密码
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  lock boolean NOT NULL DEFAULT false, -- 锁住
  CONSTRAINT pk_s_user PRIMARY KEY (id),
  CONSTRAINT uk_s_user UNIQUE (username)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE s_user
  OWNER TO "yardAdmin";;
COMMENT ON TABLE s_user
  IS '用户表';;
COMMENT ON COLUMN s_user.username IS '用户名';;
COMMENT ON COLUMN s_user.password IS '密码';;
COMMENT ON COLUMN s_user.lock IS '锁住';;


INSERT INTO s_user VALUES (1, 'Admin', 'zht+dh=sql2', 1, '2014-02-21 14:33:46.185167', NULL, NULL, '', false);;
INSERT INTO s_user VALUES (2, '管理员', {user_pw}, 1, '2014-03-01 07:25:54', NULL, NULL, '', false);;

SELECT pg_catalog.setval('s_user_id_seq', 2, true);;

CREATE TRIGGER tri_s_user
  BEFORE INSERT OR UPDATE OR DELETE
  ON s_user
  FOR EACH ROW
  EXECUTE PROCEDURE fun4tri_s_user();;

CREATE TABLE s_post
(
  id serial NOT NULL,
  postname character varying(20) NOT NULL, -- 岗位名称
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  CONSTRAINT pk_s_post PRIMARY KEY (id),
  CONSTRAINT uk_s_post UNIQUE (postname)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE s_post
  OWNER TO "yardAdmin";;
COMMENT ON TABLE s_post
  IS '岗位表';;
COMMENT ON COLUMN s_post.postname IS '岗位名称';;

INSERT INTO s_post VALUES (1, '管理员', 1, '2014-02-28 09:10:50', NULL, NULL, '');;
SELECT pg_catalog.setval('s_post_id_seq', 2, true);;
CREATE OR REPLACE FUNCTION fun4tri_s_post()
  RETURNS trigger AS
$BODY$begin
     if TG_OP = 'INSERT' then     
	if (NEW.postname = '管理员' or NEW.id = 1)then
		raise exception '禁止增加管理员岗位';
	end if; 
	return NEW;    
     end if;
     if TG_OP = 'UPDATE' then
	if (OLD.postname = '管理员' or OLD.id = 1 )then
		raise exception '禁止修改管理员岗位';
	end if;    	
	return NEW;
     end if;
     if TG_OP = 'DELETE' then
	if (OLD.postname = '管理员' or OLD.id = 1 ) then
		raise exception '禁止删除管理员岗位';
	end if;
     end if;
     return OLD;
end;  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;;
ALTER FUNCTION fun4tri_s_post()
  OWNER TO "yardAdmin";;

CREATE TRIGGER tri_s_post
  BEFORE INSERT OR UPDATE OR DELETE
  ON s_post
  FOR EACH ROW
  EXECUTE PROCEDURE fun4tri_s_post();;
  
CREATE TABLE s_postuser
(
  post_id integer NOT NULL, -- 岗位ID
  user_id integer NOT NULL, -- 用户ID
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  id serial NOT NULL,
  CONSTRAINT pk_s_postuser PRIMARY KEY (id),
  CONSTRAINT fk_s_postuser_post FOREIGN KEY (post_id)
      REFERENCES s_post (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_s_postuser_user FOREIGN KEY (user_id)
      REFERENCES s_user (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT uk_s_postuser UNIQUE (post_id, user_id)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE s_postuser
  OWNER TO "yardAdmin";;
COMMENT ON TABLE s_postuser
  IS '岗位用户表';;
COMMENT ON COLUMN s_postuser.post_id IS '岗位ID';;
COMMENT ON COLUMN s_postuser.user_id IS '用户ID';;
INSERT INTO s_postuser VALUES (1, 2, 1, '2014-03-01 09:00:35', NULL, NULL, '', 1);;
SELECT pg_catalog.setval('s_postuser_id_seq', 2, true);;

CREATE OR REPLACE FUNCTION fun4tri_s_postuser()
  RETURNS trigger AS
$BODY$begin
     if TG_OP = 'INSERT' then     
	if (NEW.user_id = 1 or NEW.user_id = 2 )then
		raise exception '禁止增加管理员';
	end if; 
	return NEW;    
     end if;
     if TG_OP = 'UPDATE' then
	if (OLD.user_id = 1 or OLD.user_id = 2 )then
		raise exception '禁止修改管理员';
	end if;    	
	return NEW;
     end if;
     if TG_OP = 'DELETE' then
	if (OLD.user_id = 1 or OLD.user_id = 2 ) then
		raise exception '禁止删除管理员';
	end if;
     end if;
     return OLD;
end; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;;
ALTER FUNCTION fun4tri_s_postuser()
  OWNER TO "yardAdmin";;

CREATE TRIGGER tri_s_postuser
  BEFORE INSERT OR UPDATE OR DELETE
  ON s_postuser
  FOR EACH ROW
  EXECUTE PROCEDURE fun4tri_s_postuser();;

CREATE TABLE s_postmenu
(
  post_id integer NOT NULL, -- 岗位ID
  menu_id integer NOT NULL, -- 功能ID
  active boolean NOT NULL DEFAULT true, -- 显示(激活)
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  id serial NOT NULL,
  CONSTRAINT pk_s_postmenu PRIMARY KEY (id),
  CONSTRAINT fk_s_postmenu_menu FOREIGN KEY (menu_id)
      REFERENCES sys_menu (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_s_postmenu_post FOREIGN KEY (post_id)
      REFERENCES s_post (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT uk_s_postmenu UNIQUE (post_id, menu_id)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE s_postmenu
  OWNER TO "yardAdmin";;
COMMENT ON TABLE s_postmenu  IS '岗位功能表';;
COMMENT ON COLUMN s_postmenu.post_id IS '岗位ID';;
COMMENT ON COLUMN s_postmenu.menu_id IS '功能ID';;
COMMENT ON COLUMN s_postmenu.active IS '显示(激活)';;

INSERT INTO s_postmenu VALUES (1, 33, true, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '', 1);;
INSERT INTO s_postmenu VALUES (1, 34, true, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '', 2);;
INSERT INTO s_postmenu VALUES (1, 9, true, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '', 3);;
INSERT INTO s_postmenu VALUES (1, 10, true, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '', 4);;
INSERT INTO s_postmenu VALUES (1, 11, true, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '', 5);;
INSERT INTO s_postmenu VALUES (1, 12, true, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '', 6);;
SELECT pg_catalog.setval('s_postmenu_id_seq', 7, true);;

CREATE OR REPLACE FUNCTION fun4tri_s_postmenu()
  RETURNS trigger AS
$BODY$
declare 
     menu_sys_flag boolean;
begin

     if TG_OP = 'INSERT' then     
	select sys_flag into menu_sys_flag from sys_menu
	where id = NEW.menu_id;
	if menu_sys_flag = true then
		raise exception '禁止添加系统功能';
	end if;
     
	if (NEW.post_id = 1 ) then
		raise exception '禁止增加管理员岗位权限';
	end if; 
	return NEW;    
     end if;
     if TG_OP = 'UPDATE' then
	if (OLD.post_id = 1 ) then
		raise exception '禁止修改管理员岗位权限';
	end if;    	
	return NEW;
     end if;
     if TG_OP = 'DELETE' then
	if (OLD.post_id = 1) then
		raise exception '禁止删除管理员岗位权限';
	end if;
     end if;
     return OLD;
end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;;
ALTER FUNCTION fun4tri_s_postmenu()
  OWNER TO "yardAdmin";;

CREATE TRIGGER tri_s_postmenu
  BEFORE INSERT OR UPDATE OR DELETE
  ON s_postmenu
  FOR EACH ROW
  EXECUTE PROCEDURE fun4tri_s_postmenu();;

CREATE TABLE s_postmenufunc
(
  id serial NOT NULL,
  post_id integer NOT NULL, -- 岗位ID
  menu_id integer NOT NULL, -- 功能ID
  func_id integer NOT NULL, -- 功能ID
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  CONSTRAINT pk_s_postmenufunc PRIMARY KEY (id),
  CONSTRAINT fk_s_postmenufunc FOREIGN KEY (menu_id)
      REFERENCES sys_menu (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_s_postmenufunc_func FOREIGN KEY (func_id)
      REFERENCES sys_func (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_s_postmenufunc_post FOREIGN KEY (post_id)
      REFERENCES s_post (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT uk_s_postmenufunc UNIQUE (post_id, menu_id, func_id)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE s_postmenufunc
  OWNER TO "yardAdmin";;
COMMENT ON TABLE s_postmenufunc
  IS '岗位权限表';;
COMMENT ON COLUMN s_postmenufunc.post_id IS '岗位ID';;
COMMENT ON COLUMN s_postmenufunc.menu_id IS '功能ID';;
COMMENT ON COLUMN s_postmenufunc.func_id IS '功能ID';;

INSERT INTO s_postmenufunc VALUES (1, 1, 34, 55, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;
INSERT INTO s_postmenufunc VALUES (2, 1, 9, 16, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;
INSERT INTO s_postmenufunc VALUES (3, 1, 9, 17, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;
INSERT INTO s_postmenufunc VALUES (4, 1, 10, 12, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;
INSERT INTO s_postmenufunc VALUES (5, 1, 10, 13, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;
INSERT INTO s_postmenufunc VALUES (6, 1, 11, 14, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;
INSERT INTO s_postmenufunc VALUES (7, 1, 11, 15, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;
INSERT INTO s_postmenufunc VALUES (8, 1, 11, 12, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;
INSERT INTO s_postmenufunc VALUES (9, 1, 12, 12, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;
INSERT INTO s_postmenufunc VALUES (10, 1, 12, 32, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;
INSERT INTO s_postmenufunc VALUES (11, 1, 12, 33, 1, '2014-07-01 00:48:06.217065', NULL, NULL, '');;

SELECT pg_catalog.setval('s_postmenufunc_id_seq', 12, true);;
CREATE TRIGGER tri_s_postmenufunc
  BEFORE INSERT OR UPDATE OR DELETE
  ON s_postmenufunc
  FOR EACH ROW
  EXECUTE PROCEDURE fun4tri_s_postmenu();;
CREATE TABLE s_filter_head
(
  id serial NOT NULL,
  datagrid character varying(100) NOT NULL DEFAULT ''::character varying, -- datagrid名称
  filter_type character(1) NOT NULL DEFAULT 'G'::character varying, -- 'G'-全局 'P'-个人
  filter_owner integer, -- 查询条件所有者
  filter_name character varying(50) NOT NULL, -- 查询条件名称
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  CONSTRAINT pk_s_filter PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE s_filter_head
  OWNER TO "yardAdmin";;
COMMENT ON TABLE s_filter_head
  IS '查询条件头';;
COMMENT ON COLUMN s_filter_head.datagrid IS 'datagrid名称';;
COMMENT ON COLUMN s_filter_head.filter_type IS '''G''-全局 ''P''-个人';;
COMMENT ON COLUMN s_filter_head.filter_owner IS '查询条件所有者';;
COMMENT ON COLUMN s_filter_head.filter_name IS '查询条件名称';;


-- Index: idx_s_filter

-- DROP INDEX idx_s_filter;

CREATE INDEX idx_s_filter
  ON s_filter_head
  USING btree
  (datagrid COLLATE pg_catalog."default");;


CREATE TABLE s_filter_body
(
  id serial NOT NULL,
  filter_id integer NOT NULL,
  content_col character varying(30) NOT NULL DEFAULT ''::character varying, -- 条件字段名
  content_value character varying(50) NOT NULL DEFAULT ''::character varying, -- 条件值
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  content_type character(1) NOT NULL DEFAULT 'W'::bpchar, -- 内容类型'W'-where 'S'-order 'C'-col
  content_condition character varying(10) NOT NULL DEFAULT ''::character varying, -- 内容条件
  value_text character varying(100) NOT NULL DEFAULT ''::character varying,
  display_value character varying(100) NOT NULL DEFAULT ''::character varying,
  CONSTRAINT pk_s_filter_body PRIMARY KEY (id),
  CONSTRAINT fk_filter_id FOREIGN KEY (filter_id)
      REFERENCES s_filter_head (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE s_filter_body
  OWNER TO "yardAdmin";;
COMMENT ON COLUMN s_filter_body.content_col IS '条件字段名';;
COMMENT ON COLUMN s_filter_body.content_value IS '条件值';;
COMMENT ON COLUMN s_filter_body.content_type IS '内容类型''W''-where ''S''-order ''C''-col';;
COMMENT ON COLUMN s_filter_body.content_condition IS '内容条件';;
CREATE TABLE c_cargo_type
(
  id serial NOT NULL,
  type_name character varying(20) NOT NULL DEFAULT ''::character varying, -- 货物分类名称
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50),
  CONSTRAINT pk_c_cargo_type PRIMARY KEY (id),
  CONSTRAINT uk_c_cargo_type UNIQUE (type_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_cargo_type
  OWNER TO "yardAdmin";;
COMMENT ON COLUMN c_cargo_type.type_name IS '货物分类名称';;



CREATE TABLE c_cargo
(
  id serial NOT NULL,
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50),
  cargo_name character varying(20) NOT NULL DEFAULT ''::character varying,
  CONSTRAINT pk_c_cargo PRIMARY KEY (id),
  CONSTRAINT uk_c_cargo UNIQUE (cargo_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_cargo
  OWNER TO "yardAdmin";;
COMMENT ON TABLE c_cargo
  IS '货物名称';;


CREATE TABLE p_protocol
(
  id serial NOT NULL,
  protocol_name character varying(50) NOT NULL, -- 协议名称
  write_date date, -- 签订日期
  validate_date date, -- 有效日期
  remark character varying(50),
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  CONSTRAINT pk_p_protocol PRIMARY KEY (id),
  CONSTRAINT uk_p_protocol UNIQUE (protocol_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE p_protocol
  OWNER TO "yardAdmin";;
COMMENT ON TABLE p_protocol
  IS '协议头表';;
COMMENT ON COLUMN p_protocol.protocol_name IS '协议名称';;
COMMENT ON COLUMN p_protocol.write_date IS '签订日期';;
COMMENT ON COLUMN p_protocol.validate_date IS '有效日期';;


CREATE TABLE c_client
(
  id serial NOT NULL,
  client_name character varying(50) NOT NULL, -- 客户名称
  client_flag boolean NOT NULL DEFAULT false, -- 委托方标识
  custom_flag boolean NOT NULL DEFAULT false, -- 报关行标识
  ship_corp_flag boolean NOT NULL DEFAULT false, -- 船公司标识
  yard_flag boolean NOT NULL DEFAULT false, -- 场站标识
  port_flag boolean NOT NULL DEFAULT false, -- 码头标识
  financial_flag boolean NOT NULL DEFAULT false, -- 财务往来单位标识
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  landtrans_flag boolean NOT NULL DEFAULT false, -- 车队标示
  credit_flag boolean NOT NULL DEFAULT false, -- 信用证单位标识
  protocol_id integer, -- 协议ID
  CONSTRAINT pk_c_client PRIMARY KEY (id),
  CONSTRAINT fk_c_client_protocol FOREIGN KEY (protocol_id)
      REFERENCES p_protocol (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT uk_c_client UNIQUE (client_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_client
  OWNER TO "yardAdmin";;
COMMENT ON TABLE c_client
  IS '基础代码客户代码表';;
COMMENT ON COLUMN c_client.client_name IS '客户名称';;
COMMENT ON COLUMN c_client.client_flag IS '委托方标识';;
COMMENT ON COLUMN c_client.custom_flag IS '报关行标识';;
COMMENT ON COLUMN c_client.ship_corp_flag IS '船公司标识';;
COMMENT ON COLUMN c_client.yard_flag IS '场站标识';;
COMMENT ON COLUMN c_client.port_flag IS '码头标识';;
COMMENT ON COLUMN c_client.financial_flag IS '财务往来单位标识';;
COMMENT ON COLUMN c_client.landtrans_flag IS '车队标示';;
COMMENT ON COLUMN c_client.credit_flag IS '信用证单位标识';;
COMMENT ON COLUMN c_client.protocol_id IS '协议ID';;

CREATE TABLE c_cntr_type
(
  id serial NOT NULL,
  cntr_type character varying(4) NOT NULL, -- 箱型代码
  cntr_type_name character varying(20) NOT NULL DEFAULT ''::character varying, -- 箱型名称
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  CONSTRAINT pk_c_cntr_type PRIMARY KEY (id),
  CONSTRAINT uk_c_cntr_type UNIQUE (cntr_type)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_cntr_type
  OWNER TO "yardAdmin";;
COMMENT ON COLUMN c_cntr_type.cntr_type IS '箱型代码';;
COMMENT ON COLUMN c_cntr_type.cntr_type_name IS '箱型名称';;

INSERT INTO c_cntr_type VALUES (1, '20GP', '20尺干箱', 1, '2014-03-03 13:30:32', NULL, NULL, '');;
INSERT INTO c_cntr_type VALUES (2, '40GP', '40尺干箱', 1, '2014-03-03 13:30:33', NULL, NULL, '');;
INSERT INTO c_cntr_type VALUES (3, '40HC', '40尺超高干箱', 1, '2014-03-03 13:30:33', NULL, NULL, '');;
INSERT INTO c_cntr_type VALUES (4, '45HC', '45尺超高干箱', 1, '2014-04-23 14:11:46', NULL, NULL, '');;
SELECT pg_catalog.setval('c_cntr_type_id_seq', 4, true);;

CREATE TABLE c_contract_action
(
  id serial NOT NULL,
  action_name character varying(20) NOT NULL, -- 动态名称
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  require_flag boolean NOT NULL DEFAULT false, -- 必备标识
  sortno smallint NOT NULL, -- 动态序号
  CONSTRAINT pk_c_contract_action PRIMARY KEY (id),
  CONSTRAINT uk_c_contract_action UNIQUE (action_name),
  CONSTRAINT uk_c_contract_action_sort UNIQUE (sortno)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_contract_action
  OWNER TO "yardAdmin";;
COMMENT ON TABLE c_contract_action
  IS '基础代码委托动态代码表';;
COMMENT ON COLUMN c_contract_action.action_name IS '动态名称';;
COMMENT ON COLUMN c_contract_action.require_flag IS '必备标识';;
COMMENT ON COLUMN c_contract_action.sortno IS '动态序号';;

INSERT INTO c_contract_action VALUES (1, '报检', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 1);;
INSERT INTO c_contract_action VALUES (3, '押箱', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 3);;
INSERT INTO c_contract_action VALUES (4, '验货', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 4);;
INSERT INTO c_contract_action VALUES (5, '熏蒸', '', 1, '2014-03-03 14:12:04', NULL, NULL, false, 5);;
INSERT INTO c_contract_action VALUES (6, '取样', '', 1, '2014-03-03 14:12:04', NULL, NULL, false, 6);;
INSERT INTO c_contract_action VALUES (8, '拆箱完成', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 8);;
INSERT INTO c_contract_action VALUES (9, '检尺', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 9);;
INSERT INTO c_contract_action VALUES (10, '还箱', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 10);;
INSERT INTO c_contract_action VALUES (2, '报关', '', 1, '2014-03-03 14:12:04', 1, '2014-04-11 05:48:13', true, 2);;
INSERT INTO c_contract_action VALUES (7, '拆箱', '', 1, '2014-03-03 14:12:04', 1, '2014-06-25 07:14:19', true, 7);;

SELECT pg_catalog.setval('c_contract_action_id_seq', 10, true);;
CREATE TABLE c_dispatch
(
  id serial NOT NULL,
  place_name character varying(30) NOT NULL DEFAULT ''::character varying, -- 发货地名称
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  CONSTRAINT pk_c_dispatch PRIMARY KEY (id),
  CONSTRAINT uk_dispatch UNIQUE (place_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_dispatch
  OWNER TO "yardAdmin";;
COMMENT ON TABLE c_dispatch
  IS '发货地表';;
COMMENT ON COLUMN c_dispatch.place_name IS '发货地名称';;
INSERT INTO c_dispatch VALUES (1, '美国', '', 1, '2014-04-24 18:16:46', NULL, NULL);;
INSERT INTO c_dispatch VALUES (2, '欧洲', '', 1, '2014-04-24 18:16:46', NULL, NULL);;

SELECT pg_catalog.setval('c_dispatch_id_seq', 2, true);;
CREATE TABLE c_place
(
  id serial NOT NULL,
  place_name character varying(20) NOT NULL DEFAULT ''::character varying,
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50),
  CONSTRAINT pk_c_place PRIMARY KEY (id),
  CONSTRAINT uk_c_place UNIQUE (place_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_place
  OWNER TO "yardAdmin";;
INSERT INTO c_place VALUES (1, '罗马尼亚', 1, '2014-05-05 18:13:24', NULL, NULL, '');;
INSERT INTO c_place VALUES (3, '乌拉圭', 1, '2014-05-05 18:14:06', NULL, NULL, '');;
INSERT INTO c_place VALUES (4, '法国', 1, '2014-05-08 09:13:17', NULL, NULL, '');;
INSERT INTO c_place VALUES (5, '哥斯达黎加', 1, '2014-05-08 09:13:17', NULL, NULL, '');;
INSERT INTO c_place VALUES (6, '乌克兰', 1, '2014-05-08 09:13:17', NULL, NULL, '');;
INSERT INTO c_place VALUES (7, '美国', 1, '2014-05-08 09:13:17', NULL, NULL, '');;
INSERT INTO c_place VALUES (8, '加拿大', 1, '2014-05-08 09:13:17', NULL, NULL, '');;
INSERT INTO c_place VALUES (9, '立陶宛', 1, '2014-05-08 09:13:17', NULL, NULL, '');;
INSERT INTO c_place VALUES (10, '拉脱维亚', 1, '2014-05-08 09:13:17', NULL, NULL, '');;
INSERT INTO c_place VALUES (11, '爱沙尼亚', 1, '2014-05-08 09:13:17', NULL, NULL, '');;
INSERT INTO c_place VALUES (12, '德国', 1, '2014-05-08 09:13:17', NULL, NULL, '');;
INSERT INTO c_place VALUES (13, '巴西', 1, '2014-05-08 09:13:30', NULL, NULL, '');;
INSERT INTO c_place VALUES (14, '新西兰', 1, '2014-05-08 09:13:46', NULL, NULL, '');;
INSERT INTO c_place VALUES (15, '俄罗斯', 1, '2014-05-08 09:14:06', NULL, NULL, '');;
INSERT INTO c_place VALUES (16, '智利', 1, '2014-05-08 09:14:06', NULL, NULL, '');;
INSERT INTO c_place VALUES (17, '波兰', 1, '2014-05-08 09:14:06', 1, '2014-05-08 01:14:27', '');;
INSERT INTO c_place VALUES (18, '斯洛伐克', 1, '2014-05-08 09:14:38', NULL, NULL, '');;

SELECT pg_catalog.setval('c_place_id_seq', 18, true);;

CREATE TABLE c_fee
(
  id serial NOT NULL,
  fee_name character varying(20) NOT NULL, -- 费用名称
  protocol_flag boolean NOT NULL DEFAULT false, -- 协议费用标识
  remark character varying(50) NOT NULL DEFAULT ''::character varying, -- 备注
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  pair_flag boolean NOT NULL DEFAULT false, -- true 插入应付自动生成应收，模拟代收代付
  CONSTRAINT pk_c_fee PRIMARY KEY (id),
  CONSTRAINT uk_c_fee UNIQUE (fee_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_fee
  OWNER TO "yardAdmin";;
COMMENT ON TABLE c_fee
  IS '基础代码费用名称';;
COMMENT ON COLUMN c_fee.fee_name IS '费用名称';;
COMMENT ON COLUMN c_fee.protocol_flag IS '协议费用标识';;
COMMENT ON COLUMN c_fee.remark IS '备注';;
COMMENT ON COLUMN c_fee.pair_flag IS 'true 插入应付自动生成应收，模拟代收代付';;
INSERT INTO c_fee VALUES (1, '包干费', true, '', 1, '2014-03-04 08:26:50', NULL, NULL, false);;
INSERT INTO c_fee VALUES (2, '码头超期费', false, '', 1, '2014-03-04 08:26:50', NULL, NULL, true);;
INSERT INTO c_fee VALUES (3, '码头堆存费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, true);;
INSERT INTO c_fee VALUES (4, '码头搬移费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, true);;
INSERT INTO c_fee VALUES (5, '海关验货费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, false);;
INSERT INTO c_fee VALUES (6, '商检熏蒸费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, true);;
INSERT INTO c_fee VALUES (7, '商检熏蒸场地费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, true);;
INSERT INTO c_fee VALUES (8, '商检熏蒸拖车费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, true);;
INSERT INTO c_fee VALUES (11, '滞报金', false, '', 1, '2014-04-28 15:21:54', NULL, NULL, true);;
SELECT pg_catalog.setval('c_fee_id_seq', 11, true);;
CREATE TABLE c_pay_type
(
  id serial NOT NULL,
  pay_name character varying(20) NOT NULL, -- 付款方式名陈
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  CONSTRAINT pk_c_pay_type PRIMARY KEY (id),
  CONSTRAINT uk_c_pay_type UNIQUE (pay_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_pay_type
  OWNER TO "yardAdmin";;
COMMENT ON TABLE c_pay_type
  IS '付款方式';;
COMMENT ON COLUMN c_pay_type.pay_name IS '付款方式名陈';;
INSERT INTO c_pay_type VALUES (1, '现金', 1, '2014-03-04 09:58:57', NULL, NULL, '');;
INSERT INTO c_pay_type VALUES (2, '支票', 1, '2014-03-04 09:58:57', NULL, NULL, '');;
INSERT INTO c_pay_type VALUES (3, '银行转账', 1, '2014-03-04 09:58:57', NULL, NULL, '');;
INSERT INTO c_pay_type VALUES (4, '承兑', 1, '2014-04-23 14:31:51', NULL, NULL, '');;

SELECT pg_catalog.setval('c_pay_type_id_seq', 4, true);;

CREATE TABLE c_rpt
(
  id serial NOT NULL,
  rpt_name character varying(30) NOT NULL, -- 报表名称
  remark character varying(50),
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  CONSTRAINT pk_c_rpt PRIMARY KEY (id),
  CONSTRAINT uk_c_rpt UNIQUE (rpt_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_rpt
  OWNER TO "yardAdmin";;
COMMENT ON TABLE c_rpt
  IS '费用报表名称';;
COMMENT ON COLUMN c_rpt.rpt_name IS '报表名称';;

CREATE TABLE c_rpt_item
(
  id serial NOT NULL,
  item_name character varying(30) NOT NULL, -- 项目名称
  rpt_id integer NOT NULL, -- 报表id
  remark character varying(50),
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  sort_no integer, -- 序号
  CONSTRAINT pk_c_rpt_item PRIMARY KEY (id),
  CONSTRAINT fk_rpt_item FOREIGN KEY (rpt_id)
      REFERENCES c_rpt (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_rpt_item
  OWNER TO "yardAdmin";;
COMMENT ON TABLE c_rpt_item
  IS '费用报表项目';;
COMMENT ON COLUMN c_rpt_item.item_name IS '项目名称';;
COMMENT ON COLUMN c_rpt_item.rpt_id IS '报表id';;
COMMENT ON COLUMN c_rpt_item.sort_no IS '序号';;
CREATE TABLE c_rpt_fee
(
  id serial NOT NULL,
  rpt_id integer NOT NULL, -- 报表id
  item_id integer NOT NULL, -- 项目id
  fee_id integer NOT NULL, -- 费用id
  remark character varying(50),
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  CONSTRAINT pk_c_rpt_fee PRIMARY KEY (id),
  CONSTRAINT fk_c_rpt_fee_item FOREIGN KEY (item_id)
      REFERENCES c_rpt_item (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_c_rpt_fee_rpt FOREIGN KEY (rpt_id)
      REFERENCES c_rpt (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_rpt_fee_fee FOREIGN KEY (fee_id)
      REFERENCES c_fee (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT uk_c_rpt_fee UNIQUE (rpt_id, item_id, fee_id)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE c_rpt_fee
  OWNER TO "yardAdmin";;
COMMENT ON TABLE c_rpt_fee
  IS '费用报表项目费用';;
COMMENT ON COLUMN c_rpt_fee.rpt_id IS '报表id';;
COMMENT ON COLUMN c_rpt_fee.item_id IS '项目id';;
COMMENT ON COLUMN c_rpt_fee.fee_id IS '费用id';;

CREATE TABLE contract
(
  id serial NOT NULL,
  bill_no character varying(25) NOT NULL, -- 提单号
  client_id integer NOT NULL, -- 委托方ID
  contract_type integer NOT NULL DEFAULT 1, -- 委托类型 外键 sys_code.id ...
  cargo_fee_type integer, -- 货物费用计费类型...
  cargo_piece integer, -- 货物件数
  cargo_weight numeric(13,2), -- 货物重量公斤
  cargo_volume numeric(13,3), -- 货物体积立方米
  booking_date date, -- 接单日期
  in_port_date date, -- 到港日期
  return_cntr_date date, -- 还箱日期
  custom_id integer, -- 报关行
  ship_corp_id integer, -- 船公司
  port_id integer, -- 码头id
  yard_id integer, -- 场站id
  finish_flag boolean DEFAULT false, -- 委托完结标识
  finish_time timestamp without time zone, -- 委托完结时间
  remark character varying(50) NOT NULL DEFAULT ''::character varying, -- 备注
  rec_nam integer NOT NULL, -- 创建人员
  rec_tim timestamp without time zone NOT NULL, -- 创建时间
  upd_nam integer, -- 修改人员
  upd_tim timestamp without time zone, -- 修改时间
  vslvoy character varying(40) NOT NULL DEFAULT ''::character varying, -- 船名航次
  contract_no character varying(20) NOT NULL DEFAULT ''::character varying, -- 合同号
  dispatch_place integer NOT NULL, -- 发货地ID
  custom_title1 character varying(30) NOT NULL DEFAULT ''::character varying, -- 报关抬头1
  custom_title2 character varying(30) NOT NULL DEFAULT ''::character varying, -- 报关抬头2
  landtrans_id integer, -- 陆运车队ID
  check_yard_id integer, -- 查验场站ID
  unbox_yard_id integer, -- 拆箱场站
  credit_id integer, -- 信用证公司ID
  cargo_name integer, -- 货物名称ID
  origin_place integer, -- 产地ID
  cargo_type integer, -- 货物分类ID
  cntr_freedays integer, -- 箱使天数
  CONSTRAINT pk_contract PRIMARY KEY (id),
  CONSTRAINT fk_contract_cargoname FOREIGN KEY (cargo_name)
      REFERENCES c_cargo (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_cargotype FOREIGN KEY (cargo_type)
      REFERENCES c_cargo_type (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_checkyard FOREIGN KEY (check_yard_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_client FOREIGN KEY (client_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_credit FOREIGN KEY (credit_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_custom FOREIGN KEY (custom_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_dispatch FOREIGN KEY (dispatch_place)
      REFERENCES c_dispatch (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_landtrans FOREIGN KEY (landtrans_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_originplace FOREIGN KEY (origin_place)
      REFERENCES c_place (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_port FOREIGN KEY (port_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_ship_corp FOREIGN KEY (ship_corp_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_unboxyard FOREIGN KEY (unbox_yard_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_contract_yard FOREIGN KEY (yard_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT uk_contract UNIQUE (bill_no)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE contract
  OWNER TO "yardAdmin";;
COMMENT ON TABLE contract
  IS '委托表';;
COMMENT ON COLUMN contract.bill_no IS '提单号';;
COMMENT ON COLUMN contract.client_id IS '委托方ID';;
COMMENT ON COLUMN contract.contract_type IS '委托类型 外键 sys_code.id 本系统无用  赋缺省值';;
COMMENT ON COLUMN contract.cargo_fee_type IS '货物费用计费类型 本系统无用赋缺省值';;
COMMENT ON COLUMN contract.cargo_piece IS '货物件数';;
COMMENT ON COLUMN contract.cargo_weight IS '货物重量公斤';;
COMMENT ON COLUMN contract.cargo_volume IS '货物体积立方米';;
COMMENT ON COLUMN contract.booking_date IS '接单日期';;
COMMENT ON COLUMN contract.in_port_date IS '到港日期';;
COMMENT ON COLUMN contract.return_cntr_date IS '还箱日期';;
COMMENT ON COLUMN contract.custom_id IS '报关行';;
COMMENT ON COLUMN contract.ship_corp_id IS '船公司';;
COMMENT ON COLUMN contract.port_id IS '码头id';;
COMMENT ON COLUMN contract.yard_id IS '场站id';;
COMMENT ON COLUMN contract.finish_flag IS '委托完结标识';;
COMMENT ON COLUMN contract.finish_time IS '委托完结时间';;
COMMENT ON COLUMN contract.remark IS '备注';;
COMMENT ON COLUMN contract.rec_nam IS '创建人员';;
COMMENT ON COLUMN contract.rec_tim IS '创建时间';;
COMMENT ON COLUMN contract.upd_nam IS '修改人员';;
COMMENT ON COLUMN contract.upd_tim IS '修改时间';;
COMMENT ON COLUMN contract.vslvoy IS '船名航次';;
COMMENT ON COLUMN contract.contract_no IS '合同号';;
COMMENT ON COLUMN contract.dispatch_place IS '发货地ID';;
COMMENT ON COLUMN contract.custom_title1 IS '报关抬头1';;
COMMENT ON COLUMN contract.custom_title2 IS '报关抬头2';;
COMMENT ON COLUMN contract.landtrans_id IS '陆运车队ID';;
COMMENT ON COLUMN contract.check_yard_id IS '查验场站ID';;
COMMENT ON COLUMN contract.unbox_yard_id IS '拆箱场站';;
COMMENT ON COLUMN contract.credit_id IS '信用证公司ID';;
COMMENT ON COLUMN contract.cargo_name IS '货物名称ID';;
COMMENT ON COLUMN contract.origin_place IS '产地ID';;
COMMENT ON COLUMN contract.cargo_type IS '货物分类ID';;
COMMENT ON COLUMN contract.cntr_freedays IS '箱使天数';;
CREATE INDEX fki_contract_custom
  ON contract
  USING btree
  (custom_id);;

CREATE OR REPLACE FUNCTION fun4tri_contract()
  RETURNS trigger AS
$BODY$
DECLARE
	count_fee integer;
BEGIN
	if TG_OP = 'DELETE' then
	   if OLD.finish_flag = true then
		RAISE EXCEPTION '委托锁定不能删除';
	   end if;
	   return OLD;
	end if;
	if TG_OP = 'UPDATE' then
	   if OLD.finish_flag = true and NEW.finish_flag = true then
		RAISE EXCEPTION '委托锁定不能修改';
	   end if;
	end if;
        NEW.upd_tim := current_timestamp;
        RETURN NEW;
    END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;;
ALTER FUNCTION fun4tri_contract()
  OWNER TO "yardAdmin";;

CREATE TRIGGER tri_contract
  BEFORE UPDATE
  ON contract
  FOR EACH ROW
  EXECUTE PROCEDURE fun4tri_contract();;
CREATE TABLE contract_action
(
  id serial NOT NULL,
  contract_id integer NOT NULL, -- 委托id
  action_id integer NOT NULL, -- 计划id
  finish_flag boolean NOT NULL DEFAULT false, -- 完成标识
  finish_time timestamp without time zone, -- 完成时间
  remark character varying(50) NOT NULL DEFAULT ''::character varying, -- 备注
  rec_nam integer NOT NULL, -- 创建人员
  rec_tim timestamp without time zone NOT NULL, -- 创建时间
  upd_nam integer, -- 修改人员
  upd_tim timestamp without time zone, -- 修改时间
  CONSTRAINT pk_contract_action PRIMARY KEY (id),
  CONSTRAINT "fk_contract-action_contract" FOREIGN KEY (contract_id)
      REFERENCES contract (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_contract_action_action FOREIGN KEY (action_id)
      REFERENCES c_contract_action (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT uk_contract_action UNIQUE (contract_id, action_id)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE contract_action
  OWNER TO "yardAdmin";;
COMMENT ON TABLE contract_action
  IS '委托计划表';;
COMMENT ON COLUMN contract_action.contract_id IS '委托id';;
COMMENT ON COLUMN contract_action.action_id IS '计划id';;
COMMENT ON COLUMN contract_action.finish_flag IS '完成标识';;
COMMENT ON COLUMN contract_action.finish_time IS '完成时间';;
COMMENT ON COLUMN contract_action.remark IS '备注';;
COMMENT ON COLUMN contract_action.rec_nam IS '创建人员';;
COMMENT ON COLUMN contract_action.rec_tim IS '创建时间';;
COMMENT ON COLUMN contract_action.upd_nam IS '修改人员';;
COMMENT ON COLUMN contract_action.upd_tim IS '修改时间';;
CREATE OR REPLACE FUNCTION fun4tri_contract_action()
  RETURNS trigger AS
$BODY$declare
	contract_lock boolean;
begin
	select finish_flag into contract_lock from contract 
	where id = NEW.contract_id;
	if contract_lock = true then
		raise exception '委托已锁定';
	end if;
		if TG_OP = 'UPDATE' then
	   
	NEW.upd_tim := current_timestamp;
	return NEW;
	end if;
	if TG_OP = 'DELETE' then
	return OLD;
	end if;
end;	$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;;
ALTER FUNCTION fun4tri_contract_action()
  OWNER TO "yardAdmin";;

CREATE TRIGGER tri_contract_action
  BEFORE UPDATE OR DELETE
  ON contract_action
  FOR EACH ROW
  EXECUTE PROCEDURE fun4tri_contract_action();;
CREATE TABLE contract_cntr
(
  id serial NOT NULL,
  cntr_num integer, -- 箱量
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  cntr_type integer NOT NULL, -- 箱型
  contract_id integer NOT NULL, -- 委托ID
  check_num integer, -- 查验箱量
  CONSTRAINT pk_contract_cntr PRIMARY KEY (id),
  CONSTRAINT fk_contract_cntr_contract FOREIGN KEY (contract_id)
      REFERENCES contract (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_contract_cntr_type FOREIGN KEY (cntr_type)
      REFERENCES c_cntr_type (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE contract_cntr
  OWNER TO "yardAdmin";;
COMMENT ON TABLE contract_cntr
  IS '委托箱量';;
COMMENT ON COLUMN contract_cntr.cntr_num IS '箱量';;
COMMENT ON COLUMN contract_cntr.cntr_type IS '箱型';;
COMMENT ON COLUMN contract_cntr.contract_id IS '委托ID';;
COMMENT ON COLUMN contract_cntr.check_num IS '查验箱量';;
CREATE TRIGGER tri_contract_cntr
  BEFORE UPDATE OR DELETE
  ON contract_cntr
  FOR EACH ROW
  EXECUTE PROCEDURE fun4tri_contract_action();;
CREATE TABLE pre_fee
(
  id serial NOT NULL,
  contract_id integer NOT NULL, -- 委托ID
  fee_typ character(1) NOT NULL, -- 费用类型，应收/应付 I/O
  fee_cod integer NOT NULL, -- 费用名称
  client_id integer NOT NULL, -- 客户ID
  amount numeric(10,2), -- 金额
  fee_tim timestamp without time zone NOT NULL, -- 费用产生时间
  lock_flag boolean NOT NULL DEFAULT false, -- 费用锁定
  fee_financial_tim timestamp without time zone, -- 财务统计时间
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  ex_from character varying(36) NOT NULL DEFAULT ''::character varying, -- 来源号
  ex_over character varying(36) NOT NULL DEFAULT ''::character varying, -- 结单号
  ex_feeid character varying(1) NOT NULL DEFAULT 'O'::character varying, -- 生成标记'O'原生'E'核销拆分
  audit_id boolean NOT NULL DEFAULT false,
  audit_tim timestamp without time zone, -- 核销时间
  currency_cod character varying(3) NOT NULL DEFAULT 'RMB'::character varying, -- 货币种类
  create_flag character varying(1) NOT NULL DEFAULT 'M'::character varying, -- 费用产生方式 'M'-手工录入 'P'-协议计费
  CONSTRAINT pk_pre_fee PRIMARY KEY (id),
  CONSTRAINT fk_pre_fee_client FOREIGN KEY (client_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_pre_fee_cod FOREIGN KEY (fee_cod)
      REFERENCES c_fee (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_pre_fee_contract FOREIGN KEY (contract_id)
      REFERENCES contract (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE pre_fee
  OWNER TO "yardAdmin";;
COMMENT ON TABLE pre_fee
  IS '应收应付费用';;
COMMENT ON COLUMN pre_fee.contract_id IS '委托ID';;
COMMENT ON COLUMN pre_fee.fee_typ IS '费用类型，应收/应付 I/O';;
COMMENT ON COLUMN pre_fee.fee_cod IS '费用名称';;
COMMENT ON COLUMN pre_fee.client_id IS '客户ID';;
COMMENT ON COLUMN pre_fee.amount IS '金额';;
COMMENT ON COLUMN pre_fee.fee_tim IS '费用产生时间';;
COMMENT ON COLUMN pre_fee.lock_flag IS '费用锁定';;
COMMENT ON COLUMN pre_fee.fee_financial_tim IS '财务统计时间';;
COMMENT ON COLUMN pre_fee.ex_from IS '来源号';;
COMMENT ON COLUMN pre_fee.ex_over IS '结单号';;
COMMENT ON COLUMN pre_fee.ex_feeid IS '生成标记''O''原生''E''核销拆分';;
COMMENT ON COLUMN pre_fee.audit_tim IS '核销时间';;
COMMENT ON COLUMN pre_fee.currency_cod IS '货币种类';;
COMMENT ON COLUMN pre_fee.create_flag IS '费用产生方式 ''M''-手工录入 ''P''-协议计费';;


CREATE TABLE act_fee
(
  id serial NOT NULL,
  client_id integer NOT NULL, -- 客户ID
  fee_typ character(1) NOT NULL, -- 已收/已付 I/O
  amount numeric(10,2) NOT NULL,
  invoice_no character varying(30) NOT NULL DEFAULT ''::character varying, -- 发票号
  check_no character varying(30) NOT NULL DEFAULT ''::character varying, -- 支票号
  pay_type integer NOT NULL, -- 付款方式
  fee_tim timestamp without time zone NOT NULL, -- 付款时间
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  ex_from character varying(36) NOT NULL DEFAULT ''::character varying, -- 来源号
  ex_over character varying(36) NOT NULL DEFAULT ''::character varying, -- 完结号
  ex_feeid character varying(1) NOT NULL DEFAULT 'O'::character varying, -- 生成标识'O'原生 'E'核销拆分
  audit_id boolean DEFAULT false,
  audit_tim timestamp without time zone, -- 核销时间
  accept_no character varying(30) NOT NULL DEFAULT ''::character varying, -- 承兑号
  currency_cod character varying(3) NOT NULL DEFAULT 'RMB'::character varying, -- 货币种类
  CONSTRAINT pk_act_fee PRIMARY KEY (id),
  CONSTRAINT fk_act_fee_client FOREIGN KEY (client_id)
      REFERENCES c_client (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_act_fee_pay FOREIGN KEY (pay_type)
      REFERENCES c_pay_type (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE act_fee
  OWNER TO "yardAdmin";;
COMMENT ON TABLE act_fee
  IS '实际费用，已收/已付';;
COMMENT ON COLUMN act_fee.client_id IS '客户ID';;
COMMENT ON COLUMN act_fee.fee_typ IS '已收/已付 I/O';;
COMMENT ON COLUMN act_fee.invoice_no IS '发票号';;
COMMENT ON COLUMN act_fee.check_no IS '支票号';;
COMMENT ON COLUMN act_fee.pay_type IS '付款方式';;
COMMENT ON COLUMN act_fee.fee_tim IS '付款时间';;
COMMENT ON COLUMN act_fee.ex_from IS '来源号';;
COMMENT ON COLUMN act_fee.ex_over IS '完结号';;
COMMENT ON COLUMN act_fee.ex_feeid IS '生成标识''O''原生 ''E''核销拆分';;
COMMENT ON COLUMN act_fee.audit_tim IS '核销时间';;
COMMENT ON COLUMN act_fee.accept_no IS '承兑号';;
COMMENT ON COLUMN act_fee.currency_cod IS '货币种类';;

CREATE INDEX idx_act_fee_audit
  ON act_fee
  USING btree
  (audit_id);;

CREATE INDEX idx_act_fee_audit_tim
  ON act_fee
  USING btree
  (audit_tim);;


CREATE INDEX idx_act_fee_ex_from
  ON act_fee
  USING btree
  (ex_from COLLATE pg_catalog."default");;

CREATE INDEX idx_act_fee_ex_over
  ON act_fee
  USING btree
  (ex_over COLLATE pg_catalog."default");;


--协议
CREATE TABLE p_fee_ele
(
  id serial NOT NULL,
  ele_name character varying(30) NOT NULL, -- 要素名称
  init_data_sql character varying(100) NOT NULL DEFAULT ''::character varying, -- 初始化要素内容sql语句
  remark character varying(50),
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  CONSTRAINT pk_p_fee_ele PRIMARY KEY (id),
  CONSTRAINT uk_p_fee_ele UNIQUE (ele_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE p_fee_ele
  OWNER TO "yardAdmin";;
COMMENT ON TABLE p_fee_ele
  IS '协议要素表';;
COMMENT ON COLUMN p_fee_ele.ele_name IS '要素名称';;
COMMENT ON COLUMN p_fee_ele.init_data_sql IS '初始化要素内容sql语句';;
INSERT INTO p_fee_ele VALUES (1, '箱型', 'select trim(to_char(id,"9999999999")) lov_cod,cntr_type lov_name from c_cntr_type', '代码表的id转换为字符型，字段名称固定为lov_cod和lov_name', 1, '2014-06-13 16:01:00', 1, '2014-06-13 08:09:46');;
INSERT INTO p_fee_ele VALUES (2, '发货地', 'select trim(to_char(id,"9999999999")) lov_cod,place_name lov_name from c_dispatch', '', 1, '2014-06-13 16:17:17', NULL, NULL);;
INSERT INTO p_fee_ele VALUES (3, '货物分类', 'select trim(to_char(id,"9999999999")) lov_cod,type_name lov_name from c_cargo_type', '', 1, '2014-06-13 16:18:46', NULL, NULL);;
INSERT INTO p_fee_ele VALUES (4, '免费天数', '', '', 1, '2014-06-20 10:44:39', NULL, NULL);;

SELECT pg_catalog.setval('p_fee_ele_id_seq', 4, true);;

CREATE TABLE p_fee_mod
(
  id serial NOT NULL,
  mod_name character varying(20) NOT NULL, -- 费用模式名称
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  col_1 integer, -- 模式要素1
  col_2 integer, -- 模式要素2
  col_3 integer, -- 模式要素3
  col_4 integer, -- 模式要素4
  col_5 integer, -- 模式要素5
  col_6 integer, -- 模式要素6
  col_7 integer, -- 模式要素7
  col_8 integer, -- 模式要素8
  col_9 integer, -- 模式要素9
  col_10 integer, -- 模式要素10
  mod_descript character varying(200) NOT NULL DEFAULT ''::character varying, -- 模式描述
	deal_process character varying(50) NOT NULL DEFAULT ''::character varying, -- 模式绑定存储过程
  CONSTRAINT pk_p_fee_mod PRIMARY KEY (id),
  CONSTRAINT fk_p_fee_mod_1 FOREIGN KEY (col_1)
      REFERENCES p_fee_ele (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_p_fee_mod_10 FOREIGN KEY (col_10)
      REFERENCES p_fee_ele (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_p_fee_mod_2 FOREIGN KEY (col_2)
      REFERENCES p_fee_ele (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_p_fee_mod_3 FOREIGN KEY (col_3)
      REFERENCES p_fee_ele (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_p_fee_mod_4 FOREIGN KEY (col_4)
      REFERENCES p_fee_ele (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_p_fee_mod_5 FOREIGN KEY (col_5)
      REFERENCES p_fee_ele (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_p_fee_mod_6 FOREIGN KEY (col_6)
      REFERENCES p_fee_ele (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_p_fee_mod_7 FOREIGN KEY (col_7)
      REFERENCES p_fee_ele (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_p_fee_mod_8 FOREIGN KEY (col_8)
      REFERENCES p_fee_ele (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT fk_p_fee_mod_9 FOREIGN KEY (col_9)
      REFERENCES p_fee_ele (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT uk_p_fee_mod UNIQUE (mod_name)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE p_fee_mod
  OWNER TO "yardAdmin";;
COMMENT ON TABLE p_fee_mod
  IS '费用模式头表';;
COMMENT ON COLUMN p_fee_mod.mod_name IS '费用模式名称';;
COMMENT ON COLUMN p_fee_mod.col_1 IS '模式要素1';;
COMMENT ON COLUMN p_fee_mod.col_2 IS '模式要素2';;
COMMENT ON COLUMN p_fee_mod.col_3 IS '模式要素3';;
COMMENT ON COLUMN p_fee_mod.col_4 IS '模式要素4';;
COMMENT ON COLUMN p_fee_mod.col_5 IS '模式要素5';;
COMMENT ON COLUMN p_fee_mod.col_6 IS '模式要素6';;
COMMENT ON COLUMN p_fee_mod.col_7 IS '模式要素7';;
COMMENT ON COLUMN p_fee_mod.col_8 IS '模式要素8';;
COMMENT ON COLUMN p_fee_mod.col_9 IS '模式要素9';;
COMMENT ON COLUMN p_fee_mod.col_10 IS '模式要素10';;
COMMENT ON COLUMN p_fee_mod.mod_descript IS '模式描述';;
COMMENT ON COLUMN p_fee_mod.deal_process IS '模式绑定存储过程';;

CREATE TABLE p_protocol_fee_mod
(
  id serial NOT NULL,
  protocol_id integer NOT NULL, -- 协议id
  fee_id integer NOT NULL, -- 费用名称id
  mod_id integer NOT NULL, -- 模式id
  sort_no integer , -- 模式序号
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  active_flag boolean NOT NULL DEFAULT true, -- 激活
  CONSTRAINT pk_p_protocol_fee_mod PRIMARY KEY (id),
  CONSTRAINT fk_p_protocol_fee_mod_f FOREIGN KEY (fee_id)
      REFERENCES c_fee (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_p_protocol_fee_mod_m FOREIGN KEY (mod_id)
      REFERENCES p_fee_mod (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_p_protocol_fee_mod_p FOREIGN KEY (protocol_id)
      REFERENCES p_protocol (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT uk_p_protocol_fee_mod UNIQUE (protocol_id, fee_id, mod_id)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE p_protocol_fee_mod
  OWNER TO "yardAdmin";;
COMMENT ON TABLE p_protocol_fee_mod
  IS '协议费用模式表';;
COMMENT ON COLUMN p_protocol_fee_mod.protocol_id IS '协议id';;
COMMENT ON COLUMN p_protocol_fee_mod.fee_id IS '费用名称id';;
COMMENT ON COLUMN p_protocol_fee_mod.mod_id IS '模式id';;
COMMENT ON COLUMN p_protocol_fee_mod.sort_no IS '模式序号';;
COMMENT ON COLUMN p_protocol_fee_mod.active_flag IS '激活';;
CREATE TABLE p_protocol_rat
(
  id serial NOT NULL,
  protocol_id integer NOT NULL, -- 协议id
  fee_id integer NOT NULL, -- 费用id
  mod_id integer NOT NULL, -- 模式id
  fee_ele1 character varying(10) NOT NULL DEFAULT ''::character varying,
  fee_ele2 character varying(10) NOT NULL DEFAULT ''::character varying,
  fee_ele3 character varying(10) NOT NULL DEFAULT ''::character varying,
  fee_ele4 character varying(10) NOT NULL DEFAULT ''::character varying,
  fee_ele5 character varying(10) NOT NULL DEFAULT ''::character varying,
  fee_ele6 character varying(10) NOT NULL DEFAULT ''::character varying,
  fee_ele7 character varying(10) NOT NULL DEFAULT ''::character varying,
  fee_ele8 character varying(10) NOT NULL DEFAULT ''::character varying,
  fee_ele9 character varying(10) NOT NULL DEFAULT ''::character varying,
  fee_ele10 character varying(10) NOT NULL DEFAULT ''::character varying,
  fee_rat numeric(8,2) NOT NULL DEFAULT 0, -- 费率
  discount_rat numeric(8,2), -- 折扣金额
  remark character varying(50) NOT NULL DEFAULT ''::character varying,
  rec_nam integer NOT NULL,
  rec_tim timestamp without time zone NOT NULL,
  upd_nam integer,
  upd_tim timestamp without time zone,
  CONSTRAINT pk_p_protocol_rat PRIMARY KEY (id),
  CONSTRAINT fk_p_protocol_rat_fee FOREIGN KEY (fee_id)
      REFERENCES c_fee (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_p_protocol_rat_mod FOREIGN KEY (mod_id)
      REFERENCES p_fee_mod (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT fk_p_protocol_rat_protocol FOREIGN KEY (protocol_id)
      REFERENCES p_protocol (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE CASCADE,
	CONSTRAINT uk_p_protocol_rat UNIQUE (protocol_id, fee_id, mod_id, fee_ele1, fee_ele2, fee_ele3, fee_ele4, fee_ele5, fee_ele6, fee_ele7, 			fee_ele8, fee_ele9, fee_ele10)
)
WITH (
  OIDS=FALSE
);;
ALTER TABLE p_protocol_rat
  OWNER TO "yardAdmin";;
COMMENT ON TABLE p_protocol_rat
  IS '协议费率表';;
COMMENT ON COLUMN p_protocol_rat.protocol_id IS '协议id';;
COMMENT ON COLUMN p_protocol_rat.fee_id IS '费用id';;
COMMENT ON COLUMN p_protocol_rat.mod_id IS '模式id';;
COMMENT ON COLUMN p_protocol_rat.fee_rat IS '费率';;
COMMENT ON COLUMN p_protocol_rat.discount_rat IS '折扣金额';;










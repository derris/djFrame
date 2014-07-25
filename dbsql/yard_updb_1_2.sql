INSERT INTO sys_menu VALUES (52, '协议费率复制', 1, '2014-02-25 11:18:14', 1, '2014-06-27 02:56:36', '', 43, '协议费率复制', 5, false);;
SELECT pg_catalog.setval('sys_menu_id_seq', 52, true);;
INSERT INTO sys_func VALUES ('协议费率复制', 1, '2014-06-23 08:59:13', 1, '2014-06-23 00:59:03', '', 92, 'p_protocol_fee_mod,p_protocol_rat');;
SELECT pg_catalog.setval('sys_func_id_seq', 92, true);;
INSERT INTO sys_menu_func VALUES (110, 52, 92, 1, '2014-06-23 08:59:40', NULL, NULL, '');;
SELECT pg_catalog.setval('sys_menu_func_id_seq', 110, true);;
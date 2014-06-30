﻿--
-- PostgreSQL database dump
--

-- Dumped from database version 9.1.13
-- Dumped by pg_dump version 9.2.4
-- Started on 2014-06-30 13:12:13 CST

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

DROP DATABASE yard;
--
-- TOC entry 2594 (class 1262 OID 27682)
-- Name: yard; Type: DATABASE; Schema: -; Owner: yardAdmin
--

CREATE DATABASE yard WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'zh_CN.UTF-8' LC_CTYPE = 'zh_CN.UTF-8';


ALTER DATABASE yard OWNER TO "yardAdmin";

\connect yard

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 6 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 2595 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 248 (class 3079 OID 11652)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2597 (class 0 OID 0)
-- Dependencies: 248
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 260 (class 1255 OID 27683)
-- Name: f_create_lump_fee(integer, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: yardAdmin
--

CREATE FUNCTION f_create_lump_fee(p_contract_id integer, p_tim timestamp without time zone, oper_id integer, OUT ov_rtn character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  vi_fee_id c_fee.id%TYPE;
  vi_count integer;
  vf_amount pre_fee.amount%TYPE;
  vi_client_id contract.client_id%TYPE;  
begin
  ov_rtn := 'SUC';
  select id into vi_fee_id from c_fee where fee_name = '包干费';
  select count(1) into vi_count from pre_fee p  where p.contract_id = p_contract_id and p.fee_typ = 'I' and p.fee_cod = vi_fee_id;
  if vi_count > 0 then
     ov_rtn := 'SUC';
     return;
  end if;
  select client_id into vi_client_id from contract where id = p_contract_id;
  --select to_char(now(),'yyyy-mm-dd hh24:mi:ss') into vc_time;
  
  select sum(COALESCE(cc.cntr_num,0) * COALESCE(p.rate,0)) into vf_amount
     from contract c,contract_cntr cc,c_fee_protocol p
    where c.id = p_contract_id
      and c.id = cc.contract_id
      and c.client_id = p.client_id
      and p.fee_id = vi_fee_id
      and p.contract_type = c.contract_type
      and p.fee_cal_type = cc.cntr_type;
   if vf_amount > 0 then
      insert into pre_fee(contract_id,fee_typ,fee_cod,client_id,amount,fee_tim,fee_financial_tim,rec_nam,rec_tim)
      values(p_contract_id,'I',vi_fee_id,vi_client_id,vf_amount,p_tim,p_tim,oper_id,p_tim);
   end if;
return;
end;$$;


ALTER FUNCTION public.f_create_lump_fee(p_contract_id integer, p_tim timestamp without time zone, oper_id integer, OUT ov_rtn character varying) OWNER TO "yardAdmin";

--
-- TOC entry 261 (class 1255 OID 27684)
-- Name: f_create_protocol_fee(integer, integer); Type: FUNCTION; Schema: public; Owner: yardAdmin
--

CREATE FUNCTION f_create_protocol_fee(p_contract_id integer, oper_id integer, OUT ov_rtn character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare
  cur_protocol_fee cursor for select id,fee_name from c_fee where protocol_flag = true;
  cur_pair_fee cursor for select p.fee_cod,p.fee_tim,p.fee_financial_tim,p.amount
     from pre_fee p,c_fee c
     where p.contract_id = p_contract_id
       and p.fee_typ = 'O'
       and p.lock_flag = false and p.audit_id = false and p.ex_feeid = 'O'
       and p.fee_cod = c.id
       and c.pair_flag = true
       and p.fee_cod not in(
          select ip.fee_cod from pre_fee ip
          where ip.contract_id = p_contract_id and ip.fee_typ = 'I'
       );
  vi_count integer;
  vi_client_id contract.client_id%TYPE;
  vt_time pre_fee.fee_tim%TYPE;  
  
begin

  select count(1) into vi_count from pre_fee p
  where p.contract_id = p_contract_id
    and (p.lock_flag = true or p.audit_id = true);
  if vi_count > 0 then
    ov_rtn := 'ERR:此委托存在已锁定或核销的费用，不能产生协议费用';
    return;
  end if;
  select client_id into vi_client_id from contract where id = p_contract_id;
  select current_timestamp(0)::timestamp without time zone into vt_time;
  --循环处理协议费用
  
  for vcur_protocol_fee in cur_protocol_fee loop
     if vcur_protocol_fee.fee_name = '包干费' then
        --select f_create_lump_fee(contract_id,oper_id) into vc_tt;
        perform f_create_lump_fee(p_contract_id,vt_time,oper_id);        
     end if;
  end loop;
  --循环已录入应付费用,对代收代付费用产生对应的应收费用
  for vcur_pair_fee in cur_pair_fee loop
     insert into pre_fee (contract_id,fee_typ,fee_cod,client_id,amount,fee_tim,
                          fee_financial_tim,rec_nam,rec_tim)
     values(p_contract_id,'I',vcur_pair_fee.fee_cod,vi_client_id,vcur_pair_fee.amount,vt_time,
            vcur_pair_fee.fee_financial_tim,oper_id,vt_time);
  end loop;
  ov_rtn := 'SUC';  
  return ;
Exception
When Others Then    
    raise exception 'ERR:数据库错误号-%',SQLSTATE;    
end;
$$;


ALTER FUNCTION public.f_create_protocol_fee(p_contract_id integer, oper_id integer, OUT ov_rtn character varying) OWNER TO "yardAdmin";

--
-- TOC entry 262 (class 1255 OID 27685)
-- Name: fun4tri_c_fee(); Type: FUNCTION; Schema: public; Owner: yardAdmin
--

CREATE FUNCTION fun4tri_c_fee() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	if TG_OP = 'UPDATE' then
		if OLD.id in (1,2,3,4,5,6,7,8,11) and OLD.fee_name <> NEW.fee_name then
			RAISE EXCEPTION '基础费用不能修改';
		end if;
		NEW.upd_tim := current_timestamp;
		return NEW;
	end if;
	if TG_OP = 'DELETE' then
		if OLD.id in (1,2,3,4,5,6,7,8,11)  then
			RAISE EXCEPTION '基础费用不能删除';
		end if;
		return OLD;
	end if;
    END;
$$;


ALTER FUNCTION public.fun4tri_c_fee() OWNER TO "yardAdmin";

--
-- TOC entry 263 (class 1255 OID 27686)
-- Name: fun4tri_contract(); Type: FUNCTION; Schema: public; Owner: yardAdmin
--

CREATE FUNCTION fun4tri_contract() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.fun4tri_contract() OWNER TO "yardAdmin";

--
-- TOC entry 264 (class 1255 OID 27687)
-- Name: fun4tri_contract_action(); Type: FUNCTION; Schema: public; Owner: yardAdmin
--

CREATE FUNCTION fun4tri_contract_action() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare
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
end;	$$;


ALTER FUNCTION public.fun4tri_contract_action() OWNER TO "yardAdmin";

--
-- TOC entry 265 (class 1255 OID 27688)
-- Name: fun4tri_s_postmenufunc(); Type: FUNCTION; Schema: public; Owner: yardAdmin
--

CREATE FUNCTION fun4tri_s_postmenufunc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$declare 
     menu_sys_flag boolean;
begin
     select sys_flag into menu_sys_flag from sys_menu
     where id = NEW.menu_id;
     if menu_sys_flag = true then
        raise exception '禁止添加系统功能';
     end if;
     RETURN NEW;
end;     $$;


ALTER FUNCTION public.fun4tri_s_postmenufunc() OWNER TO "yardAdmin";

--
-- TOC entry 266 (class 1255 OID 27689)
-- Name: fun4tri_s_user(); Type: FUNCTION; Schema: public; Owner: yardAdmin
--

CREATE FUNCTION fun4tri_s_user() RETURNS trigger
    LANGUAGE plpgsql
    AS $$begin
     if TG_OP = 'INSERT' then
     
     if NEW.username = 'Admin' then
	raise exception '禁止修改系统管理员';
     end if; 
     return NEW;    
     end if;
     if TG_OP = 'UPDATE' then
     if OLD.username = 'Admin' then
	raise exception '禁止修改系统管理员';
     end if;     
     return NEW;
     end if;
   return OLD;
end;     $$;


ALTER FUNCTION public.fun4tri_s_user() OWNER TO "yardAdmin";

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 161 (class 1259 OID 27690)
-- Name: act_fee; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE act_fee (
    id integer NOT NULL,
    client_id integer NOT NULL,
    fee_typ character(1) NOT NULL,
    amount numeric(10,2) NOT NULL,
    invoice_no character varying(30) DEFAULT ''::character varying NOT NULL,
    check_no character varying(30) DEFAULT ''::character varying NOT NULL,
    pay_type integer NOT NULL,
    fee_tim timestamp without time zone NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    ex_from character varying(36) DEFAULT ''::character varying NOT NULL,
    ex_over character varying(36) DEFAULT ''::character varying NOT NULL,
    ex_feeid character varying(1) DEFAULT 'O'::character varying NOT NULL,
    audit_id boolean DEFAULT false,
    audit_tim timestamp without time zone,
    accept_no character varying(30) DEFAULT ''::character varying NOT NULL,
    currency_cod character varying(3) DEFAULT 'RMB'::character varying NOT NULL
);


ALTER TABLE public.act_fee OWNER TO "yardAdmin";

--
-- TOC entry 2598 (class 0 OID 0)
-- Dependencies: 161
-- Name: TABLE act_fee; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE act_fee IS '实际费用，已收/已付';


--
-- TOC entry 2599 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.client_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.client_id IS '客户ID';


--
-- TOC entry 2600 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.fee_typ; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.fee_typ IS '已收/已付 I/O';


--
-- TOC entry 2601 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.invoice_no; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.invoice_no IS '发票号';


--
-- TOC entry 2602 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.check_no; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.check_no IS '支票号';


--
-- TOC entry 2603 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.pay_type; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.pay_type IS '付款方式';


--
-- TOC entry 2604 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.fee_tim; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.fee_tim IS '付款时间';


--
-- TOC entry 2605 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.ex_from; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.ex_from IS '来源号';


--
-- TOC entry 2606 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.ex_over; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.ex_over IS '完结号';


--
-- TOC entry 2607 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.ex_feeid; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.ex_feeid IS '生成标识''O''原生 ''E''核销拆分';


--
-- TOC entry 2608 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.audit_tim; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.audit_tim IS '核销时间';


--
-- TOC entry 2609 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.accept_no; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.accept_no IS '承兑号';


--
-- TOC entry 2610 (class 0 OID 0)
-- Dependencies: 161
-- Name: COLUMN act_fee.currency_cod; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN act_fee.currency_cod IS '货币种类';


--
-- TOC entry 162 (class 1259 OID 27701)
-- Name: act_fee_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE act_fee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.act_fee_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2611 (class 0 OID 0)
-- Dependencies: 162
-- Name: act_fee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE act_fee_id_seq OWNED BY act_fee.id;


--
-- TOC entry 163 (class 1259 OID 27703)
-- Name: auth_group; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE auth_group (
    id integer NOT NULL,
    name character varying(80) NOT NULL
);


ALTER TABLE public.auth_group OWNER TO "yardAdmin";

--
-- TOC entry 164 (class 1259 OID 27706)
-- Name: auth_group_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE auth_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_group_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2612 (class 0 OID 0)
-- Dependencies: 164
-- Name: auth_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE auth_group_id_seq OWNED BY auth_group.id;


--
-- TOC entry 165 (class 1259 OID 27708)
-- Name: auth_group_permissions; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE auth_group_permissions (
    id integer NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_group_permissions OWNER TO "yardAdmin";

--
-- TOC entry 166 (class 1259 OID 27711)
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE auth_group_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_group_permissions_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2613 (class 0 OID 0)
-- Dependencies: 166
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE auth_group_permissions_id_seq OWNED BY auth_group_permissions.id;


--
-- TOC entry 167 (class 1259 OID 27713)
-- Name: auth_permission; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE auth_permission (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);


ALTER TABLE public.auth_permission OWNER TO "yardAdmin";

--
-- TOC entry 168 (class 1259 OID 27716)
-- Name: auth_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE auth_permission_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_permission_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2614 (class 0 OID 0)
-- Dependencies: 168
-- Name: auth_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE auth_permission_id_seq OWNED BY auth_permission.id;


--
-- TOC entry 169 (class 1259 OID 27718)
-- Name: auth_user; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE auth_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone NOT NULL,
    is_superuser boolean NOT NULL,
    username character varying(30) NOT NULL,
    first_name character varying(30) NOT NULL,
    last_name character varying(30) NOT NULL,
    email character varying(75) NOT NULL,
    is_staff boolean NOT NULL,
    is_active boolean NOT NULL,
    date_joined timestamp with time zone NOT NULL
);


ALTER TABLE public.auth_user OWNER TO "yardAdmin";

--
-- TOC entry 170 (class 1259 OID 27721)
-- Name: auth_user_groups; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE auth_user_groups (
    id integer NOT NULL,
    user_id integer NOT NULL,
    group_id integer NOT NULL
);


ALTER TABLE public.auth_user_groups OWNER TO "yardAdmin";

--
-- TOC entry 171 (class 1259 OID 27724)
-- Name: auth_user_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE auth_user_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_user_groups_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2615 (class 0 OID 0)
-- Dependencies: 171
-- Name: auth_user_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE auth_user_groups_id_seq OWNED BY auth_user_groups.id;


--
-- TOC entry 172 (class 1259 OID 27726)
-- Name: auth_user_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE auth_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_user_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2616 (class 0 OID 0)
-- Dependencies: 172
-- Name: auth_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE auth_user_id_seq OWNED BY auth_user.id;


--
-- TOC entry 173 (class 1259 OID 27728)
-- Name: auth_user_user_permissions; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE auth_user_user_permissions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    permission_id integer NOT NULL
);


ALTER TABLE public.auth_user_user_permissions OWNER TO "yardAdmin";

--
-- TOC entry 174 (class 1259 OID 27731)
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE auth_user_user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_user_user_permissions_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2617 (class 0 OID 0)
-- Dependencies: 174
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE auth_user_user_permissions_id_seq OWNED BY auth_user_user_permissions.id;


--
-- TOC entry 175 (class 1259 OID 27733)
-- Name: c_cargo; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_cargo (
    id integer NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50),
    cargo_name character varying(20) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.c_cargo OWNER TO "yardAdmin";

--
-- TOC entry 2618 (class 0 OID 0)
-- Dependencies: 175
-- Name: TABLE c_cargo; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE c_cargo IS '货物名称';


--
-- TOC entry 176 (class 1259 OID 27737)
-- Name: c_cargo_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_cargo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_cargo_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2619 (class 0 OID 0)
-- Dependencies: 176
-- Name: c_cargo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_cargo_id_seq OWNED BY c_cargo.id;


--
-- TOC entry 177 (class 1259 OID 27739)
-- Name: c_cargo_type; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_cargo_type (
    id integer NOT NULL,
    type_name character varying(20) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50)
);


ALTER TABLE public.c_cargo_type OWNER TO "yardAdmin";

--
-- TOC entry 2620 (class 0 OID 0)
-- Dependencies: 177
-- Name: COLUMN c_cargo_type.type_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_cargo_type.type_name IS '货物分类名称';


--
-- TOC entry 178 (class 1259 OID 27743)
-- Name: c_cargo_type_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_cargo_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_cargo_type_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2621 (class 0 OID 0)
-- Dependencies: 178
-- Name: c_cargo_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_cargo_type_id_seq OWNED BY c_cargo_type.id;


--
-- TOC entry 179 (class 1259 OID 27745)
-- Name: c_client; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_client (
    id integer NOT NULL,
    client_name character varying(50) NOT NULL,
    client_flag boolean DEFAULT false NOT NULL,
    custom_flag boolean DEFAULT false NOT NULL,
    ship_corp_flag boolean DEFAULT false NOT NULL,
    yard_flag boolean DEFAULT false NOT NULL,
    port_flag boolean DEFAULT false NOT NULL,
    financial_flag boolean DEFAULT false NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    landtrans_flag boolean DEFAULT false NOT NULL,
    credit_flag boolean DEFAULT false NOT NULL,
    protocol_id integer
);


ALTER TABLE public.c_client OWNER TO "yardAdmin";

--
-- TOC entry 2622 (class 0 OID 0)
-- Dependencies: 179
-- Name: TABLE c_client; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE c_client IS '基础代码客户代码表';


--
-- TOC entry 2623 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN c_client.client_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_client.client_name IS '客户名称';


--
-- TOC entry 2624 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN c_client.client_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_client.client_flag IS '委托方标识';


--
-- TOC entry 2625 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN c_client.custom_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_client.custom_flag IS '报关行标识';


--
-- TOC entry 2626 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN c_client.ship_corp_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_client.ship_corp_flag IS '船公司标识';


--
-- TOC entry 2627 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN c_client.yard_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_client.yard_flag IS '场站标识';


--
-- TOC entry 2628 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN c_client.port_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_client.port_flag IS '码头标识';


--
-- TOC entry 2629 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN c_client.financial_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_client.financial_flag IS '财务往来单位标识';


--
-- TOC entry 2630 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN c_client.landtrans_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_client.landtrans_flag IS '车队标示';


--
-- TOC entry 2631 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN c_client.credit_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_client.credit_flag IS '信用证单位标识';


--
-- TOC entry 2632 (class 0 OID 0)
-- Dependencies: 179
-- Name: COLUMN c_client.protocol_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_client.protocol_id IS '协议ID';


--
-- TOC entry 180 (class 1259 OID 27757)
-- Name: c_client_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_client_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_client_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2633 (class 0 OID 0)
-- Dependencies: 180
-- Name: c_client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_client_id_seq OWNED BY c_client.id;


--
-- TOC entry 181 (class 1259 OID 27759)
-- Name: c_cntr_type; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_cntr_type (
    id integer NOT NULL,
    cntr_type character varying(4) NOT NULL,
    cntr_type_name character varying(20) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.c_cntr_type OWNER TO "yardAdmin";

--
-- TOC entry 2634 (class 0 OID 0)
-- Dependencies: 181
-- Name: COLUMN c_cntr_type.cntr_type; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_cntr_type.cntr_type IS '箱型代码';


--
-- TOC entry 2635 (class 0 OID 0)
-- Dependencies: 181
-- Name: COLUMN c_cntr_type.cntr_type_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_cntr_type.cntr_type_name IS '箱型名称';


--
-- TOC entry 182 (class 1259 OID 27764)
-- Name: c_cntr_type_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_cntr_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_cntr_type_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2636 (class 0 OID 0)
-- Dependencies: 182
-- Name: c_cntr_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_cntr_type_id_seq OWNED BY c_cntr_type.id;


--
-- TOC entry 183 (class 1259 OID 27766)
-- Name: c_contract_action; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_contract_action (
    id integer NOT NULL,
    action_name character varying(20) NOT NULL,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    require_flag boolean DEFAULT false NOT NULL,
    sortno smallint NOT NULL
);


ALTER TABLE public.c_contract_action OWNER TO "yardAdmin";

--
-- TOC entry 2637 (class 0 OID 0)
-- Dependencies: 183
-- Name: TABLE c_contract_action; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE c_contract_action IS '基础代码委托动态代码表';


--
-- TOC entry 2638 (class 0 OID 0)
-- Dependencies: 183
-- Name: COLUMN c_contract_action.action_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_contract_action.action_name IS '动态名称';


--
-- TOC entry 2639 (class 0 OID 0)
-- Dependencies: 183
-- Name: COLUMN c_contract_action.require_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_contract_action.require_flag IS '必备标识';


--
-- TOC entry 2640 (class 0 OID 0)
-- Dependencies: 183
-- Name: COLUMN c_contract_action.sortno; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_contract_action.sortno IS '动态序号';


--
-- TOC entry 184 (class 1259 OID 27771)
-- Name: c_contract_action_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_contract_action_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_contract_action_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2641 (class 0 OID 0)
-- Dependencies: 184
-- Name: c_contract_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_contract_action_id_seq OWNED BY c_contract_action.id;


--
-- TOC entry 185 (class 1259 OID 27773)
-- Name: c_dispatch; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_dispatch (
    id integer NOT NULL,
    place_name character varying(30) DEFAULT ''::character varying NOT NULL,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone
);


ALTER TABLE public.c_dispatch OWNER TO "yardAdmin";

--
-- TOC entry 2642 (class 0 OID 0)
-- Dependencies: 185
-- Name: TABLE c_dispatch; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE c_dispatch IS '发货地表';


--
-- TOC entry 2643 (class 0 OID 0)
-- Dependencies: 185
-- Name: COLUMN c_dispatch.place_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_dispatch.place_name IS '发货地名称';


--
-- TOC entry 186 (class 1259 OID 27778)
-- Name: c_dispatch_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_dispatch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_dispatch_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2644 (class 0 OID 0)
-- Dependencies: 186
-- Name: c_dispatch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_dispatch_id_seq OWNED BY c_dispatch.id;


--
-- TOC entry 187 (class 1259 OID 27780)
-- Name: c_fee; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_fee (
    id integer NOT NULL,
    fee_name character varying(20) NOT NULL,
    protocol_flag boolean DEFAULT false NOT NULL,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    pair_flag boolean DEFAULT false NOT NULL
);


ALTER TABLE public.c_fee OWNER TO "yardAdmin";

--
-- TOC entry 2645 (class 0 OID 0)
-- Dependencies: 187
-- Name: TABLE c_fee; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE c_fee IS '基础代码费用名称';


--
-- TOC entry 2646 (class 0 OID 0)
-- Dependencies: 187
-- Name: COLUMN c_fee.fee_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_fee.fee_name IS '费用名称';


--
-- TOC entry 2647 (class 0 OID 0)
-- Dependencies: 187
-- Name: COLUMN c_fee.protocol_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_fee.protocol_flag IS '协议费用标识';


--
-- TOC entry 2648 (class 0 OID 0)
-- Dependencies: 187
-- Name: COLUMN c_fee.remark; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_fee.remark IS '备注';


--
-- TOC entry 2649 (class 0 OID 0)
-- Dependencies: 187
-- Name: COLUMN c_fee.pair_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_fee.pair_flag IS 'true 插入应付自动生成应收，模拟代收代付';


--
-- TOC entry 188 (class 1259 OID 27792)
-- Name: c_fee_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_fee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_fee_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2650 (class 0 OID 0)
-- Dependencies: 188
-- Name: c_fee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_fee_id_seq OWNED BY c_fee.id;


--
-- TOC entry 189 (class 1259 OID 27802)
-- Name: c_pay_type; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_pay_type (
    id integer NOT NULL,
    pay_name character varying(20) NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.c_pay_type OWNER TO "yardAdmin";

--
-- TOC entry 2651 (class 0 OID 0)
-- Dependencies: 189
-- Name: TABLE c_pay_type; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE c_pay_type IS '付款方式';


--
-- TOC entry 2652 (class 0 OID 0)
-- Dependencies: 189
-- Name: COLUMN c_pay_type.pay_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_pay_type.pay_name IS '付款方式名陈';


--
-- TOC entry 190 (class 1259 OID 27806)
-- Name: c_pay_type_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_pay_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_pay_type_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2653 (class 0 OID 0)
-- Dependencies: 190
-- Name: c_pay_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_pay_type_id_seq OWNED BY c_pay_type.id;


--
-- TOC entry 191 (class 1259 OID 27808)
-- Name: c_place; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_place (
    id integer NOT NULL,
    place_name character varying(20) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50)
);


ALTER TABLE public.c_place OWNER TO "yardAdmin";

--
-- TOC entry 192 (class 1259 OID 27812)
-- Name: c_place_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_place_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_place_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2654 (class 0 OID 0)
-- Dependencies: 192
-- Name: c_place_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_place_id_seq OWNED BY c_place.id;


--
-- TOC entry 231 (class 1259 OID 28408)
-- Name: c_rpt; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_rpt (
    id integer NOT NULL,
    rpt_name character varying(30) NOT NULL,
    remark character varying(50),
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone
);


ALTER TABLE public.c_rpt OWNER TO "yardAdmin";

--
-- TOC entry 2655 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE c_rpt; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE c_rpt IS '费用报表名称';


--
-- TOC entry 2656 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN c_rpt.rpt_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_rpt.rpt_name IS '报表名称';


--
-- TOC entry 235 (class 1259 OID 28432)
-- Name: c_rpt_fee; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_rpt_fee (
    id integer NOT NULL,
    rpt_id integer NOT NULL,
    item_id integer NOT NULL,
    fee_id integer NOT NULL,
    remark character varying(50),
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone
);


ALTER TABLE public.c_rpt_fee OWNER TO "yardAdmin";

--
-- TOC entry 2657 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE c_rpt_fee; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE c_rpt_fee IS '费用报表项目费用';


--
-- TOC entry 2658 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN c_rpt_fee.rpt_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_rpt_fee.rpt_id IS '报表id';


--
-- TOC entry 2659 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN c_rpt_fee.item_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_rpt_fee.item_id IS '项目id';


--
-- TOC entry 2660 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN c_rpt_fee.fee_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_rpt_fee.fee_id IS '费用id';


--
-- TOC entry 234 (class 1259 OID 28430)
-- Name: c_rpt_fee_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_rpt_fee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_rpt_fee_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2661 (class 0 OID 0)
-- Dependencies: 234
-- Name: c_rpt_fee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_rpt_fee_id_seq OWNED BY c_rpt_fee.id;


--
-- TOC entry 230 (class 1259 OID 28406)
-- Name: c_rpt_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_rpt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_rpt_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2662 (class 0 OID 0)
-- Dependencies: 230
-- Name: c_rpt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_rpt_id_seq OWNED BY c_rpt.id;


--
-- TOC entry 233 (class 1259 OID 28419)
-- Name: c_rpt_item; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE c_rpt_item (
    id integer NOT NULL,
    item_name character varying(30) NOT NULL,
    rpt_id integer NOT NULL,
    remark character varying(50),
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    sort_no integer
);


ALTER TABLE public.c_rpt_item OWNER TO "yardAdmin";

--
-- TOC entry 2663 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE c_rpt_item; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE c_rpt_item IS '费用报表项目';


--
-- TOC entry 2664 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN c_rpt_item.item_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_rpt_item.item_name IS '项目名称';


--
-- TOC entry 2665 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN c_rpt_item.rpt_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_rpt_item.rpt_id IS '报表id';


--
-- TOC entry 2666 (class 0 OID 0)
-- Dependencies: 233
-- Name: COLUMN c_rpt_item.sort_no; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN c_rpt_item.sort_no IS '序号';


--
-- TOC entry 232 (class 1259 OID 28417)
-- Name: c_rpt_item_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE c_rpt_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.c_rpt_item_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2667 (class 0 OID 0)
-- Dependencies: 232
-- Name: c_rpt_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE c_rpt_item_id_seq OWNED BY c_rpt_item.id;


--
-- TOC entry 193 (class 1259 OID 27814)
-- Name: contract; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE contract (
    id integer NOT NULL,
    bill_no character varying(25) NOT NULL,
    client_id integer NOT NULL,
    contract_type integer DEFAULT 1 NOT NULL,
    cargo_fee_type integer,
    cargo_piece integer,
    cargo_weight numeric(13,2),
    cargo_volume numeric(13,3),
    booking_date date,
    in_port_date date,
    return_cntr_date date,
    custom_id integer,
    ship_corp_id integer,
    port_id integer,
    yard_id integer,
    finish_flag boolean DEFAULT false,
    finish_time timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    vslvoy character varying(40) DEFAULT ''::character varying NOT NULL,
    contract_no character varying(20) DEFAULT ''::character varying NOT NULL,
    dispatch_place integer NOT NULL,
    custom_title1 character varying(30) DEFAULT ''::character varying NOT NULL,
    custom_title2 character varying(30) DEFAULT ''::character varying NOT NULL,
    landtrans_id integer,
    check_yard_id integer,
    unbox_yard_id integer,
    credit_id integer,
    cargo_name integer,
    origin_place integer,
    cargo_type integer,
    cntr_freedays integer
);


ALTER TABLE public.contract OWNER TO "yardAdmin";

--
-- TOC entry 2668 (class 0 OID 0)
-- Dependencies: 193
-- Name: TABLE contract; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE contract IS '委托表';


--
-- TOC entry 2669 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.bill_no; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.bill_no IS '提单号';


--
-- TOC entry 2670 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.client_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.client_id IS '委托方ID';


--
-- TOC entry 2671 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.contract_type; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.contract_type IS '委托类型 外键 sys_code.id 
本系统无用  赋缺省值';


--
-- TOC entry 2672 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.cargo_fee_type; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.cargo_fee_type IS '货物费用计费类型
本系统无用赋缺省值';


--
-- TOC entry 2673 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.cargo_piece; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.cargo_piece IS '货物件数';


--
-- TOC entry 2674 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.cargo_weight; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.cargo_weight IS '货物重量公斤';


--
-- TOC entry 2675 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.cargo_volume; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.cargo_volume IS '货物体积立方米';


--
-- TOC entry 2676 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.booking_date; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.booking_date IS '接单日期';


--
-- TOC entry 2677 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.in_port_date; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.in_port_date IS '到港日期';


--
-- TOC entry 2678 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.return_cntr_date; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.return_cntr_date IS '还箱日期';


--
-- TOC entry 2679 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.custom_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.custom_id IS '报关行';


--
-- TOC entry 2680 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.ship_corp_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.ship_corp_id IS '船公司';


--
-- TOC entry 2681 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.port_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.port_id IS '码头id';


--
-- TOC entry 2682 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.yard_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.yard_id IS '场站id';


--
-- TOC entry 2683 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.finish_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.finish_flag IS '委托完结标识';


--
-- TOC entry 2684 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.finish_time; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.finish_time IS '委托完结时间';


--
-- TOC entry 2685 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.remark; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.remark IS '备注';


--
-- TOC entry 2686 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.rec_nam; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.rec_nam IS '创建人员';


--
-- TOC entry 2687 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.rec_tim; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.rec_tim IS '创建时间';


--
-- TOC entry 2688 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.upd_nam; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.upd_nam IS '修改人员';


--
-- TOC entry 2689 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.upd_tim; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.upd_tim IS '修改时间';


--
-- TOC entry 2690 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.vslvoy; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.vslvoy IS '船名航次';


--
-- TOC entry 2691 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.contract_no; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.contract_no IS '合同号';


--
-- TOC entry 2692 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.dispatch_place; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.dispatch_place IS '发货地ID';


--
-- TOC entry 2693 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.custom_title1; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.custom_title1 IS '报关抬头1';


--
-- TOC entry 2694 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.custom_title2; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.custom_title2 IS '报关抬头2';


--
-- TOC entry 2695 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.landtrans_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.landtrans_id IS '陆运车队ID';


--
-- TOC entry 2696 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.check_yard_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.check_yard_id IS '查验场站ID';


--
-- TOC entry 2697 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.unbox_yard_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.unbox_yard_id IS '拆箱场站';


--
-- TOC entry 2698 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.credit_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.credit_id IS '信用证公司ID';


--
-- TOC entry 2699 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.cargo_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.cargo_name IS '货物名称ID';


--
-- TOC entry 2700 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.origin_place; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.origin_place IS '产地ID';


--
-- TOC entry 2701 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.cargo_type; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.cargo_type IS '货物分类ID';


--
-- TOC entry 2702 (class 0 OID 0)
-- Dependencies: 193
-- Name: COLUMN contract.cntr_freedays; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract.cntr_freedays IS '箱使天数';


--
-- TOC entry 194 (class 1259 OID 27824)
-- Name: contract_action; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE contract_action (
    id integer NOT NULL,
    contract_id integer NOT NULL,
    action_id integer NOT NULL,
    finish_flag boolean DEFAULT false NOT NULL,
    finish_time timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone
);


ALTER TABLE public.contract_action OWNER TO "yardAdmin";

--
-- TOC entry 2703 (class 0 OID 0)
-- Dependencies: 194
-- Name: TABLE contract_action; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE contract_action IS '委托计划表';


--
-- TOC entry 2704 (class 0 OID 0)
-- Dependencies: 194
-- Name: COLUMN contract_action.contract_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_action.contract_id IS '委托id';


--
-- TOC entry 2705 (class 0 OID 0)
-- Dependencies: 194
-- Name: COLUMN contract_action.action_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_action.action_id IS '计划id';


--
-- TOC entry 2706 (class 0 OID 0)
-- Dependencies: 194
-- Name: COLUMN contract_action.finish_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_action.finish_flag IS '完成标识';


--
-- TOC entry 2707 (class 0 OID 0)
-- Dependencies: 194
-- Name: COLUMN contract_action.finish_time; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_action.finish_time IS '完成时间';


--
-- TOC entry 2708 (class 0 OID 0)
-- Dependencies: 194
-- Name: COLUMN contract_action.remark; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_action.remark IS '备注';


--
-- TOC entry 2709 (class 0 OID 0)
-- Dependencies: 194
-- Name: COLUMN contract_action.rec_nam; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_action.rec_nam IS '创建人员';


--
-- TOC entry 2710 (class 0 OID 0)
-- Dependencies: 194
-- Name: COLUMN contract_action.rec_tim; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_action.rec_tim IS '创建时间';


--
-- TOC entry 2711 (class 0 OID 0)
-- Dependencies: 194
-- Name: COLUMN contract_action.upd_nam; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_action.upd_nam IS '修改人员';


--
-- TOC entry 2712 (class 0 OID 0)
-- Dependencies: 194
-- Name: COLUMN contract_action.upd_tim; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_action.upd_tim IS '修改时间';


--
-- TOC entry 195 (class 1259 OID 27829)
-- Name: contract_action_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE contract_action_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contract_action_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2713 (class 0 OID 0)
-- Dependencies: 195
-- Name: contract_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE contract_action_id_seq OWNED BY contract_action.id;


--
-- TOC entry 196 (class 1259 OID 27831)
-- Name: contract_cntr; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE contract_cntr (
    id integer NOT NULL,
    cntr_num integer,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    cntr_type integer NOT NULL,
    contract_id integer NOT NULL,
    check_num integer
);


ALTER TABLE public.contract_cntr OWNER TO "yardAdmin";

--
-- TOC entry 2714 (class 0 OID 0)
-- Dependencies: 196
-- Name: TABLE contract_cntr; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE contract_cntr IS '委托箱量';


--
-- TOC entry 2715 (class 0 OID 0)
-- Dependencies: 196
-- Name: COLUMN contract_cntr.cntr_num; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_cntr.cntr_num IS '箱量';


--
-- TOC entry 2716 (class 0 OID 0)
-- Dependencies: 196
-- Name: COLUMN contract_cntr.cntr_type; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_cntr.cntr_type IS '箱型';


--
-- TOC entry 2717 (class 0 OID 0)
-- Dependencies: 196
-- Name: COLUMN contract_cntr.contract_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_cntr.contract_id IS '委托ID';


--
-- TOC entry 2718 (class 0 OID 0)
-- Dependencies: 196
-- Name: COLUMN contract_cntr.check_num; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN contract_cntr.check_num IS '查验箱量';


--
-- TOC entry 197 (class 1259 OID 27835)
-- Name: contract_cntr_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE contract_cntr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contract_cntr_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2719 (class 0 OID 0)
-- Dependencies: 197
-- Name: contract_cntr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE contract_cntr_id_seq OWNED BY contract_cntr.id;


--
-- TOC entry 198 (class 1259 OID 27837)
-- Name: contract_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE contract_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contract_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2720 (class 0 OID 0)
-- Dependencies: 198
-- Name: contract_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE contract_id_seq OWNED BY contract.id;


--
-- TOC entry 199 (class 1259 OID 27839)
-- Name: django_admin_log; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    user_id integer NOT NULL,
    content_type_id integer,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);


ALTER TABLE public.django_admin_log OWNER TO "yardAdmin";

--
-- TOC entry 200 (class 1259 OID 27846)
-- Name: django_admin_log_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE django_admin_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_admin_log_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2721 (class 0 OID 0)
-- Dependencies: 200
-- Name: django_admin_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE django_admin_log_id_seq OWNED BY django_admin_log.id;


--
-- TOC entry 201 (class 1259 OID 27848)
-- Name: django_content_type; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE django_content_type (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);


ALTER TABLE public.django_content_type OWNER TO "yardAdmin";

--
-- TOC entry 202 (class 1259 OID 27851)
-- Name: django_content_type_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE django_content_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.django_content_type_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2722 (class 0 OID 0)
-- Dependencies: 202
-- Name: django_content_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE django_content_type_id_seq OWNED BY django_content_type.id;


--
-- TOC entry 203 (class 1259 OID 27853)
-- Name: django_session; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);


ALTER TABLE public.django_session OWNER TO "yardAdmin";

--
-- TOC entry 239 (class 1259 OID 28474)
-- Name: p_fee_ele; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE p_fee_ele (
    id integer NOT NULL,
    ele_name character varying(30) NOT NULL,
    init_data_sql character varying(100) DEFAULT ''::character varying NOT NULL,
    remark character varying(50),
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone
);


ALTER TABLE public.p_fee_ele OWNER TO "yardAdmin";

--
-- TOC entry 2723 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE p_fee_ele; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE p_fee_ele IS '协议要素表';


--
-- TOC entry 2724 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN p_fee_ele.ele_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_ele.ele_name IS '要素名称';


--
-- TOC entry 2725 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN p_fee_ele.init_data_sql; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_ele.init_data_sql IS '初始化要素内容sql语句';


--
-- TOC entry 238 (class 1259 OID 28472)
-- Name: p_fee_ele_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE p_fee_ele_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.p_fee_ele_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2726 (class 0 OID 0)
-- Dependencies: 238
-- Name: p_fee_ele_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE p_fee_ele_id_seq OWNED BY p_fee_ele.id;


--
-- TOC entry 241 (class 1259 OID 28485)
-- Name: p_fee_ele_lov; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE p_fee_ele_lov (
    id integer NOT NULL,
    ele_id integer NOT NULL,
    lov_cod character varying(10) NOT NULL,
    lov_name character varying(20) NOT NULL,
    remark character varying(50),
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone
);


ALTER TABLE public.p_fee_ele_lov OWNER TO "yardAdmin";

--
-- TOC entry 2727 (class 0 OID 0)
-- Dependencies: 241
-- Name: TABLE p_fee_ele_lov; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE p_fee_ele_lov IS '协议要素内容表';


--
-- TOC entry 2728 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN p_fee_ele_lov.ele_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_ele_lov.ele_id IS '要素id';


--
-- TOC entry 2729 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN p_fee_ele_lov.lov_cod; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_ele_lov.lov_cod IS '要素内容代码';


--
-- TOC entry 2730 (class 0 OID 0)
-- Dependencies: 241
-- Name: COLUMN p_fee_ele_lov.lov_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_ele_lov.lov_name IS '要素内容名称';


--
-- TOC entry 240 (class 1259 OID 28483)
-- Name: p_fee_ele_lov_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE p_fee_ele_lov_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.p_fee_ele_lov_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2731 (class 0 OID 0)
-- Dependencies: 240
-- Name: p_fee_ele_lov_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE p_fee_ele_lov_id_seq OWNED BY p_fee_ele_lov.id;


--
-- TOC entry 243 (class 1259 OID 28509)
-- Name: p_fee_mod; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE p_fee_mod (
    id integer NOT NULL,
    mod_name character varying(20) NOT NULL,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    col_1 integer,
    col_2 integer,
    col_3 integer,
    col_4 integer,
    col_5 integer,
    col_6 integer,
    col_7 integer,
    col_8 integer,
    col_9 integer,
    col_10 integer,
    mod_descript character varying(500) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.p_fee_mod OWNER TO "yardAdmin";

--
-- TOC entry 2732 (class 0 OID 0)
-- Dependencies: 243
-- Name: TABLE p_fee_mod; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE p_fee_mod IS '费用模式头表';


--
-- TOC entry 2733 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.mod_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.mod_name IS '费用模式名称';


--
-- TOC entry 2734 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.col_1; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.col_1 IS '模式要素1';


--
-- TOC entry 2735 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.col_2; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.col_2 IS '模式要素2';


--
-- TOC entry 2736 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.col_3; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.col_3 IS '模式要素3';


--
-- TOC entry 2737 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.col_4; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.col_4 IS '模式要素4';


--
-- TOC entry 2738 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.col_5; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.col_5 IS '模式要素5';


--
-- TOC entry 2739 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.col_6; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.col_6 IS '模式要素6';


--
-- TOC entry 2740 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.col_7; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.col_7 IS '模式要素7';


--
-- TOC entry 2741 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.col_8; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.col_8 IS '模式要素8';


--
-- TOC entry 2742 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.col_9; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.col_9 IS '模式要素9';


--
-- TOC entry 2743 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.col_10; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.col_10 IS '模式要素10';


--
-- TOC entry 2744 (class 0 OID 0)
-- Dependencies: 243
-- Name: COLUMN p_fee_mod.mod_descript; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_fee_mod.mod_descript IS '模式自解析描述';


--
-- TOC entry 242 (class 1259 OID 28507)
-- Name: p_fee_mod_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE p_fee_mod_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.p_fee_mod_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2745 (class 0 OID 0)
-- Dependencies: 242
-- Name: p_fee_mod_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE p_fee_mod_id_seq OWNED BY p_fee_mod.id;


--
-- TOC entry 237 (class 1259 OID 28464)
-- Name: p_protocol; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE p_protocol (
    id integer NOT NULL,
    protocol_name character varying(50) NOT NULL,
    write_date date,
    validate_date date,
    remark character varying(50),
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone
);


ALTER TABLE public.p_protocol OWNER TO "yardAdmin";

--
-- TOC entry 2746 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE p_protocol; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE p_protocol IS '协议头表';


--
-- TOC entry 2747 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN p_protocol.protocol_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol.protocol_name IS '协议名称';


--
-- TOC entry 2748 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN p_protocol.write_date; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol.write_date IS '签订日期';


--
-- TOC entry 2749 (class 0 OID 0)
-- Dependencies: 237
-- Name: COLUMN p_protocol.validate_date; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol.validate_date IS '有效日期';


--
-- TOC entry 245 (class 1259 OID 28582)
-- Name: p_protocol_fee_mod; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE p_protocol_fee_mod (
    id integer NOT NULL,
    protocol_id integer NOT NULL,
    fee_id integer NOT NULL,
    mod_id integer NOT NULL,
    sort_no integer NOT NULL,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    active_flag boolean DEFAULT true NOT NULL
);


ALTER TABLE public.p_protocol_fee_mod OWNER TO "yardAdmin";

--
-- TOC entry 2750 (class 0 OID 0)
-- Dependencies: 245
-- Name: TABLE p_protocol_fee_mod; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE p_protocol_fee_mod IS '协议费用模式表';


--
-- TOC entry 2751 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN p_protocol_fee_mod.protocol_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol_fee_mod.protocol_id IS '协议id';


--
-- TOC entry 2752 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN p_protocol_fee_mod.fee_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol_fee_mod.fee_id IS '费用名称id';


--
-- TOC entry 2753 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN p_protocol_fee_mod.mod_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol_fee_mod.mod_id IS '模式id';


--
-- TOC entry 2754 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN p_protocol_fee_mod.sort_no; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol_fee_mod.sort_no IS '模式序号';


--
-- TOC entry 2755 (class 0 OID 0)
-- Dependencies: 245
-- Name: COLUMN p_protocol_fee_mod.active_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol_fee_mod.active_flag IS '激活';


--
-- TOC entry 244 (class 1259 OID 28580)
-- Name: p_protocol_fee_mod_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE p_protocol_fee_mod_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.p_protocol_fee_mod_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2756 (class 0 OID 0)
-- Dependencies: 244
-- Name: p_protocol_fee_mod_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE p_protocol_fee_mod_id_seq OWNED BY p_protocol_fee_mod.id;


--
-- TOC entry 236 (class 1259 OID 28462)
-- Name: p_protocol_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE p_protocol_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.p_protocol_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2757 (class 0 OID 0)
-- Dependencies: 236
-- Name: p_protocol_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE p_protocol_id_seq OWNED BY p_protocol.id;


--
-- TOC entry 247 (class 1259 OID 28614)
-- Name: p_protocol_rat; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE p_protocol_rat (
    id integer NOT NULL,
    protocol_id integer NOT NULL,
    fee_id integer NOT NULL,
    mod_id integer NOT NULL,
    fee_ele1 character varying(10) DEFAULT ''::character varying NOT NULL,
    fee_ele2 character varying(10) DEFAULT ''::character varying NOT NULL,
    fee_ele3 character varying(10) DEFAULT ''::character varying NOT NULL,
    fee_ele4 character varying(10) DEFAULT ''::character varying NOT NULL,
    fee_ele5 character varying(10) DEFAULT ''::character varying NOT NULL,
    fee_ele6 character varying(10) DEFAULT ''::character varying NOT NULL,
    fee_ele7 character varying(10) DEFAULT ''::character varying NOT NULL,
    fee_ele8 character varying(10) DEFAULT ''::character varying NOT NULL,
    fee_ele9 character varying(10) DEFAULT ''::character varying NOT NULL,
    fee_ele10 character varying(10) DEFAULT ''::character varying NOT NULL,
    fee_rat numeric(8,2) DEFAULT 0 NOT NULL,
    discount_rat numeric(8,2),
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone
);


ALTER TABLE public.p_protocol_rat OWNER TO "yardAdmin";

--
-- TOC entry 2758 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE p_protocol_rat; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE p_protocol_rat IS '协议费率表';


--
-- TOC entry 2759 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN p_protocol_rat.protocol_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol_rat.protocol_id IS '协议id';


--
-- TOC entry 2760 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN p_protocol_rat.fee_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol_rat.fee_id IS '费用id';


--
-- TOC entry 2761 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN p_protocol_rat.mod_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol_rat.mod_id IS '模式id';


--
-- TOC entry 2762 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN p_protocol_rat.fee_rat; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol_rat.fee_rat IS '费率';


--
-- TOC entry 2763 (class 0 OID 0)
-- Dependencies: 247
-- Name: COLUMN p_protocol_rat.discount_rat; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN p_protocol_rat.discount_rat IS '折扣金额';


--
-- TOC entry 246 (class 1259 OID 28612)
-- Name: p_protocol_rat_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE p_protocol_rat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.p_protocol_rat_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2764 (class 0 OID 0)
-- Dependencies: 246
-- Name: p_protocol_rat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE p_protocol_rat_id_seq OWNED BY p_protocol_rat.id;


--
-- TOC entry 204 (class 1259 OID 27859)
-- Name: pre_fee; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE pre_fee (
    id integer NOT NULL,
    contract_id integer NOT NULL,
    fee_typ character(1) NOT NULL,
    fee_cod integer NOT NULL,
    client_id integer NOT NULL,
    amount numeric(10,2),
    fee_tim timestamp without time zone NOT NULL,
    lock_flag boolean DEFAULT false NOT NULL,
    fee_financial_tim timestamp without time zone,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    ex_from character varying(36) DEFAULT ''::character varying NOT NULL,
    ex_over character varying(36) DEFAULT ''::character varying NOT NULL,
    ex_feeid character varying(1) DEFAULT 'O'::character varying NOT NULL,
    audit_id boolean DEFAULT false NOT NULL,
    audit_tim timestamp without time zone,
    currency_cod character varying(3) DEFAULT 'RMB'::character varying NOT NULL
);


ALTER TABLE public.pre_fee OWNER TO "yardAdmin";

--
-- TOC entry 2765 (class 0 OID 0)
-- Dependencies: 204
-- Name: TABLE pre_fee; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE pre_fee IS '应收应付费用';


--
-- TOC entry 2766 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.contract_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.contract_id IS '委托ID';


--
-- TOC entry 2767 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.fee_typ; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.fee_typ IS '费用类型，应收/应付 I/O';


--
-- TOC entry 2768 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.fee_cod; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.fee_cod IS '费用名称';


--
-- TOC entry 2769 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.client_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.client_id IS '客户ID';


--
-- TOC entry 2770 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.amount; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.amount IS '金额';


--
-- TOC entry 2771 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.fee_tim; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.fee_tim IS '费用产生时间';


--
-- TOC entry 2772 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.lock_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.lock_flag IS '费用锁定';


--
-- TOC entry 2773 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.fee_financial_tim; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.fee_financial_tim IS '财务统计时间';


--
-- TOC entry 2774 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.ex_from; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.ex_from IS '来源号';


--
-- TOC entry 2775 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.ex_over; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.ex_over IS '结单号';


--
-- TOC entry 2776 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.ex_feeid; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.ex_feeid IS '生成标记''O''原生''E''核销拆分';


--
-- TOC entry 2777 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.audit_tim; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.audit_tim IS '核销时间';


--
-- TOC entry 2778 (class 0 OID 0)
-- Dependencies: 204
-- Name: COLUMN pre_fee.currency_cod; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN pre_fee.currency_cod IS '货币种类';


--
-- TOC entry 205 (class 1259 OID 27868)
-- Name: pre_fee_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE pre_fee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pre_fee_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2779 (class 0 OID 0)
-- Dependencies: 205
-- Name: pre_fee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE pre_fee_id_seq OWNED BY pre_fee.id;


--
-- TOC entry 229 (class 1259 OID 28380)
-- Name: s_filter_body; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE s_filter_body (
    id integer NOT NULL,
    filter_id integer NOT NULL,
    content_col character varying(30) DEFAULT ''::character varying NOT NULL,
    content_value character varying(50) DEFAULT ''::character varying NOT NULL,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    content_type character(1) DEFAULT 'W'::bpchar NOT NULL,
    content_condition character varying(10) DEFAULT ''::character varying NOT NULL,
    value_text character varying(100) DEFAULT ''::character varying NOT NULL,
    display_value character varying(100) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.s_filter_body OWNER TO "yardAdmin";

--
-- TOC entry 2780 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN s_filter_body.content_col; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_filter_body.content_col IS '条件字段名';


--
-- TOC entry 2781 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN s_filter_body.content_value; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_filter_body.content_value IS '条件值';


--
-- TOC entry 2782 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN s_filter_body.content_type; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_filter_body.content_type IS '内容类型''W''-where ''S''-order ''C''-col';


--
-- TOC entry 2783 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN s_filter_body.content_condition; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_filter_body.content_condition IS '内容条件';


--
-- TOC entry 228 (class 1259 OID 28378)
-- Name: s_filter_body_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE s_filter_body_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.s_filter_body_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2784 (class 0 OID 0)
-- Dependencies: 228
-- Name: s_filter_body_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE s_filter_body_id_seq OWNED BY s_filter_body.id;


--
-- TOC entry 227 (class 1259 OID 28353)
-- Name: s_filter_head; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE s_filter_head (
    id integer NOT NULL,
    datagrid character varying(100) DEFAULT ''::character varying NOT NULL,
    filter_type character(1) DEFAULT 'G'::character varying NOT NULL,
    filter_owner integer,
    filter_name character varying(50) NOT NULL,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone
);


ALTER TABLE public.s_filter_head OWNER TO "yardAdmin";

--
-- TOC entry 2785 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE s_filter_head; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE s_filter_head IS '查询条件头';


--
-- TOC entry 2786 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN s_filter_head.datagrid; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_filter_head.datagrid IS 'datagrid名称';


--
-- TOC entry 2787 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN s_filter_head.filter_type; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_filter_head.filter_type IS '''G''-全局 ''P''-个人';


--
-- TOC entry 2788 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN s_filter_head.filter_owner; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_filter_head.filter_owner IS '查询条件所有者';


--
-- TOC entry 2789 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN s_filter_head.filter_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_filter_head.filter_name IS '查询条件名称';


--
-- TOC entry 226 (class 1259 OID 28351)
-- Name: s_filter_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE s_filter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.s_filter_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2790 (class 0 OID 0)
-- Dependencies: 226
-- Name: s_filter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE s_filter_id_seq OWNED BY s_filter_head.id;


--
-- TOC entry 206 (class 1259 OID 27870)
-- Name: s_post; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE s_post (
    id integer NOT NULL,
    postname character varying(20) NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.s_post OWNER TO "yardAdmin";

--
-- TOC entry 2791 (class 0 OID 0)
-- Dependencies: 206
-- Name: TABLE s_post; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE s_post IS '岗位表';


--
-- TOC entry 2792 (class 0 OID 0)
-- Dependencies: 206
-- Name: COLUMN s_post.postname; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_post.postname IS '岗位名称';


--
-- TOC entry 207 (class 1259 OID 27874)
-- Name: s_post_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE s_post_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.s_post_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2793 (class 0 OID 0)
-- Dependencies: 207
-- Name: s_post_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE s_post_id_seq OWNED BY s_post.id;


--
-- TOC entry 208 (class 1259 OID 27876)
-- Name: s_postmenu; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE s_postmenu (
    post_id integer NOT NULL,
    menu_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.s_postmenu OWNER TO "yardAdmin";

--
-- TOC entry 2794 (class 0 OID 0)
-- Dependencies: 208
-- Name: TABLE s_postmenu; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE s_postmenu IS '岗位功能表';


--
-- TOC entry 2795 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN s_postmenu.post_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_postmenu.post_id IS '岗位ID';


--
-- TOC entry 2796 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN s_postmenu.menu_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_postmenu.menu_id IS '功能ID
';


--
-- TOC entry 2797 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN s_postmenu.active; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_postmenu.active IS '显示(激活)';


--
-- TOC entry 209 (class 1259 OID 27881)
-- Name: s_postmenu_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE s_postmenu_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.s_postmenu_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2798 (class 0 OID 0)
-- Dependencies: 209
-- Name: s_postmenu_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE s_postmenu_id_seq OWNED BY s_postmenu.id;


--
-- TOC entry 210 (class 1259 OID 27883)
-- Name: s_postmenufunc; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE s_postmenufunc (
    id integer NOT NULL,
    post_id integer NOT NULL,
    menu_id integer NOT NULL,
    func_id integer NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.s_postmenufunc OWNER TO "yardAdmin";

--
-- TOC entry 2799 (class 0 OID 0)
-- Dependencies: 210
-- Name: TABLE s_postmenufunc; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE s_postmenufunc IS '岗位权限表';


--
-- TOC entry 2800 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN s_postmenufunc.post_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_postmenufunc.post_id IS '岗位ID';


--
-- TOC entry 2801 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN s_postmenufunc.menu_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_postmenufunc.menu_id IS '功能ID';


--
-- TOC entry 2802 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN s_postmenufunc.func_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_postmenufunc.func_id IS '功能ID';


--
-- TOC entry 211 (class 1259 OID 27887)
-- Name: s_postmenufunc_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE s_postmenufunc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.s_postmenufunc_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2803 (class 0 OID 0)
-- Dependencies: 211
-- Name: s_postmenufunc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE s_postmenufunc_id_seq OWNED BY s_postmenufunc.id;


--
-- TOC entry 212 (class 1259 OID 27889)
-- Name: s_postuser; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE s_postuser (
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.s_postuser OWNER TO "yardAdmin";

--
-- TOC entry 2804 (class 0 OID 0)
-- Dependencies: 212
-- Name: TABLE s_postuser; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE s_postuser IS '岗位用户表';


--
-- TOC entry 2805 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN s_postuser.post_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_postuser.post_id IS '岗位ID
';


--
-- TOC entry 2806 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN s_postuser.user_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_postuser.user_id IS '用户ID
';


--
-- TOC entry 213 (class 1259 OID 27893)
-- Name: s_postuser_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE s_postuser_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.s_postuser_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2807 (class 0 OID 0)
-- Dependencies: 213
-- Name: s_postuser_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE s_postuser_id_seq OWNED BY s_postuser.id;


--
-- TOC entry 214 (class 1259 OID 27895)
-- Name: s_user; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE s_user (
    id integer NOT NULL,
    username character varying(10) NOT NULL,
    password character varying(40) NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    lock boolean DEFAULT false NOT NULL
);


ALTER TABLE public.s_user OWNER TO "yardAdmin";

--
-- TOC entry 2808 (class 0 OID 0)
-- Dependencies: 214
-- Name: TABLE s_user; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE s_user IS '用户表';


--
-- TOC entry 2809 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN s_user.username; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_user.username IS '用户名';


--
-- TOC entry 2810 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN s_user.password; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_user.password IS '密码';


--
-- TOC entry 2811 (class 0 OID 0)
-- Dependencies: 214
-- Name: COLUMN s_user.lock; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN s_user.lock IS '锁住';


--
-- TOC entry 215 (class 1259 OID 27900)
-- Name: s_user_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE s_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.s_user_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2812 (class 0 OID 0)
-- Dependencies: 215
-- Name: s_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE s_user_id_seq OWNED BY s_user.id;


--
-- TOC entry 216 (class 1259 OID 27902)
-- Name: seq_4_auditfee; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE seq_4_auditfee
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.seq_4_auditfee OWNER TO "yardAdmin";

--
-- TOC entry 217 (class 1259 OID 27904)
-- Name: seq_html; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE seq_html
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.seq_html OWNER TO "yardAdmin";

--
-- TOC entry 218 (class 1259 OID 27906)
-- Name: sys_code; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE sys_code (
    id integer NOT NULL,
    fld_eng character varying(20) NOT NULL,
    fld_chi character varying(30) NOT NULL,
    cod_name character varying(20) NOT NULL,
    fld_ext1 character varying(20) DEFAULT ''::character varying NOT NULL,
    seq smallint NOT NULL,
    fld_ext2 character varying(20) DEFAULT ''::character varying NOT NULL,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone
);


ALTER TABLE public.sys_code OWNER TO "yardAdmin";

--
-- TOC entry 2813 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE sys_code; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE sys_code IS '系统参数表用户不可见';


--
-- TOC entry 2814 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN sys_code.fld_eng; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_code.fld_eng IS '英文字段名';


--
-- TOC entry 2815 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN sys_code.fld_chi; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_code.fld_chi IS '中文字段名';


--
-- TOC entry 2816 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN sys_code.cod_name; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_code.cod_name IS '值名称';


--
-- TOC entry 2817 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN sys_code.fld_ext1; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_code.fld_ext1 IS '字段扩展1';


--
-- TOC entry 2818 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN sys_code.seq; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_code.seq IS '序号';


--
-- TOC entry 2819 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN sys_code.fld_ext2; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_code.fld_ext2 IS '字段扩展值2';


--
-- TOC entry 219 (class 1259 OID 27912)
-- Name: sys_code_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE sys_code_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_code_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2820 (class 0 OID 0)
-- Dependencies: 219
-- Name: sys_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE sys_code_id_seq OWNED BY sys_code.id;


--
-- TOC entry 220 (class 1259 OID 27914)
-- Name: sys_func; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE sys_func (
    funcname character varying(50) NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    id integer NOT NULL,
    ref_tables character varying(100) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.sys_func OWNER TO "yardAdmin";

--
-- TOC entry 2821 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE sys_func; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE sys_func IS '系统权限表';


--
-- TOC entry 2822 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN sys_func.funcname; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_func.funcname IS '权限名称';


--
-- TOC entry 2823 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN sys_func.ref_tables; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_func.ref_tables IS '涉及表，多表用‘，’分隔';


--
-- TOC entry 221 (class 1259 OID 27918)
-- Name: sys_menu; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE sys_menu (
    id integer NOT NULL,
    menuname character varying(50) NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL,
    parent_id integer DEFAULT 0,
    menushowname character varying(50) NOT NULL,
    sortno smallint,
    sys_flag boolean DEFAULT false NOT NULL
);


ALTER TABLE public.sys_menu OWNER TO "yardAdmin";

--
-- TOC entry 2824 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE sys_menu; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE sys_menu IS '系统功能表';


--
-- TOC entry 2825 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN sys_menu.menuname; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_menu.menuname IS '功能名称';


--
-- TOC entry 2826 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN sys_menu.parent_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_menu.parent_id IS '父功能ID
';


--
-- TOC entry 2827 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN sys_menu.menushowname; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_menu.menushowname IS '菜单显示名称';


--
-- TOC entry 2828 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN sys_menu.sortno; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_menu.sortno IS '序号';


--
-- TOC entry 2829 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN sys_menu.sys_flag; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_menu.sys_flag IS '系统功能，禁止用户一切操作';


--
-- TOC entry 222 (class 1259 OID 27924)
-- Name: sys_func_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE sys_func_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_func_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2830 (class 0 OID 0)
-- Dependencies: 222
-- Name: sys_func_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE sys_func_id_seq OWNED BY sys_menu.id;


--
-- TOC entry 223 (class 1259 OID 27926)
-- Name: sys_func_id_seq1; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE sys_func_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_func_id_seq1 OWNER TO "yardAdmin";

--
-- TOC entry 2831 (class 0 OID 0)
-- Dependencies: 223
-- Name: sys_func_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE sys_func_id_seq1 OWNED BY sys_func.id;


--
-- TOC entry 224 (class 1259 OID 27928)
-- Name: sys_menu_func; Type: TABLE; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE TABLE sys_menu_func (
    id integer NOT NULL,
    menu_id integer NOT NULL,
    func_id integer NOT NULL,
    rec_nam integer NOT NULL,
    rec_tim timestamp without time zone NOT NULL,
    upd_nam integer,
    upd_tim timestamp without time zone,
    remark character varying(50) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.sys_menu_func OWNER TO "yardAdmin";

--
-- TOC entry 2832 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE sys_menu_func; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON TABLE sys_menu_func IS '功能权限表';


--
-- TOC entry 2833 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN sys_menu_func.menu_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_menu_func.menu_id IS '功能ID';


--
-- TOC entry 2834 (class 0 OID 0)
-- Dependencies: 224
-- Name: COLUMN sys_menu_func.func_id; Type: COMMENT; Schema: public; Owner: yardAdmin
--

COMMENT ON COLUMN sys_menu_func.func_id IS '权限ID';


--
-- TOC entry 225 (class 1259 OID 27932)
-- Name: sys_menu_func_id_seq; Type: SEQUENCE; Schema: public; Owner: yardAdmin
--

CREATE SEQUENCE sys_menu_func_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_menu_func_id_seq OWNER TO "yardAdmin";

--
-- TOC entry 2835 (class 0 OID 0)
-- Dependencies: 225
-- Name: sys_menu_func_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: yardAdmin
--

ALTER SEQUENCE sys_menu_func_id_seq OWNED BY sys_menu_func.id;


--
-- TOC entry 2131 (class 2604 OID 27934)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY act_fee ALTER COLUMN id SET DEFAULT nextval('act_fee_id_seq'::regclass);


--
-- TOC entry 2133 (class 2604 OID 27935)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_group ALTER COLUMN id SET DEFAULT nextval('auth_group_id_seq'::regclass);


--
-- TOC entry 2134 (class 2604 OID 27936)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_group_permissions ALTER COLUMN id SET DEFAULT nextval('auth_group_permissions_id_seq'::regclass);


--
-- TOC entry 2135 (class 2604 OID 27937)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_permission ALTER COLUMN id SET DEFAULT nextval('auth_permission_id_seq'::regclass);


--
-- TOC entry 2136 (class 2604 OID 27938)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_user ALTER COLUMN id SET DEFAULT nextval('auth_user_id_seq'::regclass);


--
-- TOC entry 2137 (class 2604 OID 27939)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_user_groups ALTER COLUMN id SET DEFAULT nextval('auth_user_groups_id_seq'::regclass);


--
-- TOC entry 2138 (class 2604 OID 27940)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_user_user_permissions ALTER COLUMN id SET DEFAULT nextval('auth_user_user_permissions_id_seq'::regclass);


--
-- TOC entry 2140 (class 2604 OID 27941)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_cargo ALTER COLUMN id SET DEFAULT nextval('c_cargo_id_seq'::regclass);


--
-- TOC entry 2142 (class 2604 OID 27942)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_cargo_type ALTER COLUMN id SET DEFAULT nextval('c_cargo_type_id_seq'::regclass);


--
-- TOC entry 2152 (class 2604 OID 27943)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_client ALTER COLUMN id SET DEFAULT nextval('c_client_id_seq'::regclass);


--
-- TOC entry 2155 (class 2604 OID 27944)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_cntr_type ALTER COLUMN id SET DEFAULT nextval('c_cntr_type_id_seq'::regclass);


--
-- TOC entry 2158 (class 2604 OID 27945)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_contract_action ALTER COLUMN id SET DEFAULT nextval('c_contract_action_id_seq'::regclass);


--
-- TOC entry 2161 (class 2604 OID 27946)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_dispatch ALTER COLUMN id SET DEFAULT nextval('c_dispatch_id_seq'::regclass);


--
-- TOC entry 2165 (class 2604 OID 27947)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_fee ALTER COLUMN id SET DEFAULT nextval('c_fee_id_seq'::regclass);


--
-- TOC entry 2167 (class 2604 OID 27950)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_pay_type ALTER COLUMN id SET DEFAULT nextval('c_pay_type_id_seq'::regclass);


--
-- TOC entry 2169 (class 2604 OID 27951)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_place ALTER COLUMN id SET DEFAULT nextval('c_place_id_seq'::regclass);


--
-- TOC entry 2231 (class 2604 OID 28411)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_rpt ALTER COLUMN id SET DEFAULT nextval('c_rpt_id_seq'::regclass);


--
-- TOC entry 2233 (class 2604 OID 28435)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_rpt_fee ALTER COLUMN id SET DEFAULT nextval('c_rpt_fee_id_seq'::regclass);


--
-- TOC entry 2232 (class 2604 OID 28422)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_rpt_item ALTER COLUMN id SET DEFAULT nextval('c_rpt_item_id_seq'::regclass);


--
-- TOC entry 2177 (class 2604 OID 27952)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract ALTER COLUMN id SET DEFAULT nextval('contract_id_seq'::regclass);


--
-- TOC entry 2180 (class 2604 OID 27953)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract_action ALTER COLUMN id SET DEFAULT nextval('contract_action_id_seq'::regclass);


--
-- TOC entry 2182 (class 2604 OID 27954)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract_cntr ALTER COLUMN id SET DEFAULT nextval('contract_cntr_id_seq'::regclass);


--
-- TOC entry 2183 (class 2604 OID 27955)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY django_admin_log ALTER COLUMN id SET DEFAULT nextval('django_admin_log_id_seq'::regclass);


--
-- TOC entry 2185 (class 2604 OID 27956)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY django_content_type ALTER COLUMN id SET DEFAULT nextval('django_content_type_id_seq'::regclass);


--
-- TOC entry 2235 (class 2604 OID 28477)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_ele ALTER COLUMN id SET DEFAULT nextval('p_fee_ele_id_seq'::regclass);


--
-- TOC entry 2237 (class 2604 OID 28488)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_ele_lov ALTER COLUMN id SET DEFAULT nextval('p_fee_ele_lov_id_seq'::regclass);


--
-- TOC entry 2238 (class 2604 OID 28512)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod ALTER COLUMN id SET DEFAULT nextval('p_fee_mod_id_seq'::regclass);


--
-- TOC entry 2234 (class 2604 OID 28467)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_protocol ALTER COLUMN id SET DEFAULT nextval('p_protocol_id_seq'::regclass);


--
-- TOC entry 2241 (class 2604 OID 28585)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_protocol_fee_mod ALTER COLUMN id SET DEFAULT nextval('p_protocol_fee_mod_id_seq'::regclass);


--
-- TOC entry 2244 (class 2604 OID 28617)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_protocol_rat ALTER COLUMN id SET DEFAULT nextval('p_protocol_rat_id_seq'::regclass);


--
-- TOC entry 2192 (class 2604 OID 27957)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY pre_fee ALTER COLUMN id SET DEFAULT nextval('pre_fee_id_seq'::regclass);


--
-- TOC entry 2223 (class 2604 OID 28383)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_filter_body ALTER COLUMN id SET DEFAULT nextval('s_filter_body_id_seq'::regclass);


--
-- TOC entry 2219 (class 2604 OID 28356)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_filter_head ALTER COLUMN id SET DEFAULT nextval('s_filter_id_seq'::regclass);


--
-- TOC entry 2195 (class 2604 OID 27958)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_post ALTER COLUMN id SET DEFAULT nextval('s_post_id_seq'::regclass);


--
-- TOC entry 2198 (class 2604 OID 27959)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_postmenu ALTER COLUMN id SET DEFAULT nextval('s_postmenu_id_seq'::regclass);


--
-- TOC entry 2200 (class 2604 OID 27960)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_postmenufunc ALTER COLUMN id SET DEFAULT nextval('s_postmenufunc_id_seq'::regclass);


--
-- TOC entry 2202 (class 2604 OID 27961)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_postuser ALTER COLUMN id SET DEFAULT nextval('s_postuser_id_seq'::regclass);


--
-- TOC entry 2205 (class 2604 OID 27962)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_user ALTER COLUMN id SET DEFAULT nextval('s_user_id_seq'::regclass);


--
-- TOC entry 2209 (class 2604 OID 27963)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY sys_code ALTER COLUMN id SET DEFAULT nextval('sys_code_id_seq'::regclass);


--
-- TOC entry 2211 (class 2604 OID 27964)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY sys_func ALTER COLUMN id SET DEFAULT nextval('sys_func_id_seq1'::regclass);


--
-- TOC entry 2216 (class 2604 OID 27965)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY sys_menu ALTER COLUMN id SET DEFAULT nextval('sys_func_id_seq'::regclass);


--
-- TOC entry 2218 (class 2604 OID 27966)
-- Name: id; Type: DEFAULT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY sys_menu_func ALTER COLUMN id SET DEFAULT nextval('sys_menu_func_id_seq'::regclass);


--
-- TOC entry 2503 (class 0 OID 27690)
-- Dependencies: 161
-- Data for Name: act_fee; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO act_fee VALUES (21, 55, 'I', 99999.00, '', '', 1, '2014-05-15 11:15:10', 1, '2014-05-15 11:15:13', NULL, NULL, '', '', '', 'O', false, NULL, '', 'RMB');
INSERT INTO act_fee VALUES (22, 53, 'I', 8888888.00, '', '', 3, '2014-06-26 13:29:29', 1, '2014-06-26 13:29:08', NULL, NULL, '', '', '17', 'O', true, '2014-06-26 16:05:06', '', 'RMB');
INSERT INTO act_fee VALUES (28, 53, 'I', 8887899.00, '', '', 3, '2014-06-26 16:05:06', 1, '2014-06-26 16:05:06', NULL, NULL, '核销自动生成', '17', '18', 'E', true, '2014-06-26 16:05:10', '', 'RMB');
INSERT INTO act_fee VALUES (29, 53, 'I', 8887233.00, '', '', 3, '2014-06-26 16:05:10', 1, '2014-06-26 16:05:10', NULL, NULL, '核销自动生成', '18', '', 'E', false, NULL, '', 'RMB');


--
-- TOC entry 2836 (class 0 OID 0)
-- Dependencies: 162
-- Name: act_fee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('act_fee_id_seq', 29, true);


--
-- TOC entry 2505 (class 0 OID 27703)
-- Dependencies: 163
-- Data for Name: auth_group; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--



--
-- TOC entry 2837 (class 0 OID 0)
-- Dependencies: 164
-- Name: auth_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('auth_group_id_seq', 1, false);


--
-- TOC entry 2507 (class 0 OID 27708)
-- Dependencies: 165
-- Data for Name: auth_group_permissions; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--



--
-- TOC entry 2838 (class 0 OID 0)
-- Dependencies: 166
-- Name: auth_group_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('auth_group_permissions_id_seq', 1, false);


--
-- TOC entry 2509 (class 0 OID 27713)
-- Dependencies: 167
-- Data for Name: auth_permission; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO auth_permission VALUES (1, 'Can add log entry', 1, 'add_logentry');
INSERT INTO auth_permission VALUES (2, 'Can change log entry', 1, 'change_logentry');
INSERT INTO auth_permission VALUES (3, 'Can delete log entry', 1, 'delete_logentry');
INSERT INTO auth_permission VALUES (4, 'Can add permission', 2, 'add_permission');
INSERT INTO auth_permission VALUES (5, 'Can change permission', 2, 'change_permission');
INSERT INTO auth_permission VALUES (6, 'Can delete permission', 2, 'delete_permission');
INSERT INTO auth_permission VALUES (7, 'Can add group', 3, 'add_group');
INSERT INTO auth_permission VALUES (8, 'Can change group', 3, 'change_group');
INSERT INTO auth_permission VALUES (9, 'Can delete group', 3, 'delete_group');
INSERT INTO auth_permission VALUES (10, 'Can add user', 4, 'add_user');
INSERT INTO auth_permission VALUES (11, 'Can change user', 4, 'change_user');
INSERT INTO auth_permission VALUES (12, 'Can delete user', 4, 'delete_user');
INSERT INTO auth_permission VALUES (13, 'Can add content type', 5, 'add_contenttype');
INSERT INTO auth_permission VALUES (14, 'Can change content type', 5, 'change_contenttype');
INSERT INTO auth_permission VALUES (15, 'Can delete content type', 5, 'delete_contenttype');
INSERT INTO auth_permission VALUES (16, 'Can add session', 6, 'add_session');
INSERT INTO auth_permission VALUES (17, 'Can change session', 6, 'change_session');
INSERT INTO auth_permission VALUES (18, 'Can delete session', 6, 'delete_session');


--
-- TOC entry 2839 (class 0 OID 0)
-- Dependencies: 168
-- Name: auth_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('auth_permission_id_seq', 18, true);


--
-- TOC entry 2511 (class 0 OID 27718)
-- Dependencies: 169
-- Data for Name: auth_user; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO auth_user VALUES (1, 'pbkdf2_sha256$12000$3jjm9jpUglTT$vA1wcUUsxCiZMAziXSVydwrMB3JuqJnZkH8TwR3Li9k=', '2014-01-17 14:48:18.621678+08', true, 'Admin', '', '', 'supermanqd@163.com', true, true, '2014-01-15 09:26:45.428015+08');


--
-- TOC entry 2512 (class 0 OID 27721)
-- Dependencies: 170
-- Data for Name: auth_user_groups; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--



--
-- TOC entry 2840 (class 0 OID 0)
-- Dependencies: 171
-- Name: auth_user_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('auth_user_groups_id_seq', 1, false);


--
-- TOC entry 2841 (class 0 OID 0)
-- Dependencies: 172
-- Name: auth_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('auth_user_id_seq', 1, true);


--
-- TOC entry 2515 (class 0 OID 27728)
-- Dependencies: 173
-- Data for Name: auth_user_user_permissions; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--



--
-- TOC entry 2842 (class 0 OID 0)
-- Dependencies: 174
-- Name: auth_user_user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('auth_user_user_permissions_id_seq', 1, false);


--
-- TOC entry 2517 (class 0 OID 27733)
-- Dependencies: 175
-- Data for Name: c_cargo; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_cargo VALUES (2, 1, '2014-05-05 18:11:23', NULL, NULL, '', '云杉');
INSERT INTO c_cargo VALUES (3, 1, '2014-05-05 18:12:42', NULL, NULL, '', '樟松');
INSERT INTO c_cargo VALUES (4, 1, '2014-05-08 09:05:12', NULL, NULL, '', '黄松');
INSERT INTO c_cargo VALUES (5, 1, '2014-05-08 09:05:25', NULL, NULL, '', '樟子松板材');
INSERT INTO c_cargo VALUES (6, 1, '2014-05-08 09:06:09', NULL, NULL, '', 'SPF');
INSERT INTO c_cargo VALUES (7, 1, '2014-05-08 09:06:22', NULL, NULL, '', '白冷杉');
INSERT INTO c_cargo VALUES (8, 1, '2014-05-08 09:06:36', NULL, NULL, '', '辐射松板材');
INSERT INTO c_cargo VALUES (9, 1, '2014-05-08 09:06:50', NULL, NULL, '', '翠柏');
INSERT INTO c_cargo VALUES (10, 1, '2014-05-08 09:07:41', NULL, NULL, '', '桦木');
INSERT INTO c_cargo VALUES (11, 1, '2014-05-08 09:10:13', NULL, NULL, '', '巴西松');


--
-- TOC entry 2843 (class 0 OID 0)
-- Dependencies: 176
-- Name: c_cargo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_cargo_id_seq', 11, true);


--
-- TOC entry 2519 (class 0 OID 27739)
-- Dependencies: 177
-- Data for Name: c_cargo_type; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_cargo_type VALUES (2, '原木', 1, '2014-05-05 18:12:09', NULL, NULL, '');
INSERT INTO c_cargo_type VALUES (3, '板材', 1, '2014-05-05 18:12:27', NULL, NULL, '');
INSERT INTO c_cargo_type VALUES (5, 'test', 1, '2014-06-30 00:00:00', NULL, NULL, NULL);
INSERT INTO c_cargo_type VALUES (4, 'test1', 1, '2014-06-30 00:00:00', NULL, NULL, NULL);
INSERT INTO c_cargo_type VALUES (6, 'test4', 1, '2014-06-30 00:00:00', NULL, NULL, NULL);


--
-- TOC entry 2844 (class 0 OID 0)
-- Dependencies: 178
-- Name: c_cargo_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_cargo_type_id_seq', 5, true);


--
-- TOC entry 2521 (class 0 OID 27745)
-- Dependencies: 179
-- Data for Name: c_client; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_client VALUES (42, '万丰', true, false, false, false, false, true, 1, '2014-04-24 09:21:17', 1, '2014-04-24 01:21:45', '', false, false, NULL);
INSERT INTO c_client VALUES (44, '人人国际', true, false, false, false, false, true, 1, '2014-04-24 09:23:17', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (45, '中福恒昌', true, false, false, false, false, true, 1, '2014-04-24 09:23:33', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (46, '众利源', true, false, false, false, false, true, 1, '2014-04-24 09:23:50', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (47, '松芹', true, false, false, false, false, true, 1, '2014-04-24 09:25:02', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (48, '中瑞荣达', true, false, false, false, false, true, 1, '2014-04-24 09:25:22', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (49, '南北木业', true, false, false, false, false, true, 1, '2014-04-24 09:26:04', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (52, '汇鑫同兴', true, false, false, false, false, true, 1, '2014-04-24 09:27:36', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (43, '河北家然', true, false, false, false, false, true, 1, '2014-04-24 09:22:20', 1, '2014-04-24 01:30:29', '', false, false, NULL);
INSERT INTO c_client VALUES (54, '上海力逐', true, false, false, false, false, true, 1, '2014-04-24 09:30:37', 1, '2014-04-24 01:31:59', '', false, false, NULL);
INSERT INTO c_client VALUES (51, '青岛莆商', true, false, false, false, false, true, 1, '2014-04-24 09:26:54', 1, '2014-04-24 01:32:40', '', false, false, NULL);
INSERT INTO c_client VALUES (50, '良友（仁昌）', true, false, false, false, false, true, 1, '2014-04-24 09:26:27', 1, '2014-04-24 01:33:18', '', false, false, NULL);
INSERT INTO c_client VALUES (55, '高密广森', true, false, false, false, false, true, 1, '2014-04-24 09:35:11', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (59, '华成泰', true, false, false, false, false, true, 1, '2014-04-24 09:37:14', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (61, '武旺车队', false, false, false, false, false, true, 1, '2014-05-08 09:11:46', NULL, NULL, '', true, false, NULL);
INSERT INTO c_client VALUES (62, '高超车队', false, false, false, false, false, true, 1, '2014-05-08 09:12:04', NULL, NULL, '', true, false, NULL);
INSERT INTO c_client VALUES (60, '森润', true, false, false, false, false, true, 1, '2014-04-24 09:37:26', 1, '2014-05-13 11:21:12', '', false, false, NULL);
INSERT INTO c_client VALUES (57, '枣庄辰旭', true, false, false, false, false, true, 1, '2014-04-24 09:35:40', 1, '2014-05-13 11:22:06', '', false, false, NULL);
INSERT INTO c_client VALUES (56, '寿光富士', true, false, false, false, false, true, 1, '2014-04-24 09:35:22', 1, '2014-05-13 11:22:10', '', false, false, NULL);
INSERT INTO c_client VALUES (63, '三期', false, false, false, false, true, false, 1, '2014-05-13 19:23:40', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (64, '四期', false, false, false, false, true, false, 1, '2014-05-13 19:23:48', 1, '2014-05-13 11:23:52', '', false, false, NULL);
INSERT INTO c_client VALUES (65, '加工厂', false, false, false, true, false, false, 1, '2014-05-13 19:24:28', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (66, '南港', false, false, false, true, false, false, 1, '2014-05-13 19:24:44', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (67, '中林', false, false, false, true, false, false, 1, '2014-05-13 19:24:53', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (68, '万友货场', false, false, false, true, false, false, 1, '2014-05-13 19:25:33', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (69, '中林货场', false, false, false, true, false, false, 1, '2014-05-13 19:25:44', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (70, '北方市场', false, false, false, true, false, false, 1, '2014-05-13 19:25:56', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (71, '大窑仓库', false, false, false, true, false, false, 1, '2014-05-13 19:26:07', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (39, '中良伟业', true, false, false, false, false, true, 1, '2014-04-23 14:16:09', 1, '2014-05-13 11:26:53', '', false, false, NULL);
INSERT INTO c_client VALUES (58, '和林', true, false, false, false, false, true, 1, '2014-04-24 09:36:38', 1, '2014-05-13 11:27:02', '', false, false, NULL);
INSERT INTO c_client VALUES (72, 'MSC', false, false, true, false, false, false, 1, '2014-05-20 09:10:20', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (73, '马士基', false, false, true, false, false, false, 1, '2014-05-20 09:10:39', 1, '2014-05-20 01:10:46', '', false, false, NULL);
INSERT INTO c_client VALUES (74, '韩进', false, false, true, false, false, false, 1, '2014-05-20 09:10:57', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (75, '中海', false, false, true, false, false, false, 1, '2014-05-20 09:11:06', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (76, '韩国现代', false, false, true, false, false, false, 1, '2014-05-20 09:11:17', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (77, '太平船务', false, false, true, false, false, false, 1, '2014-05-20 09:11:27', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (78, '达飞', false, false, true, false, false, false, 1, '2014-05-20 09:11:51', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (79, '赫布罗特', false, false, true, false, false, false, 1, '2014-05-20 09:12:01', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (80, '长荣', false, false, true, false, false, false, 1, '2014-05-20 09:12:11', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (81, '东方海外', false, false, true, false, false, false, 1, '2014-05-20 09:12:37', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (82, '阳明', false, false, true, false, false, false, 1, '2014-05-20 09:12:47', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (83, '长锦商船', false, false, true, false, false, false, 1, '2014-05-20 09:13:18', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (84, '中远', false, false, true, false, false, false, 1, '2014-05-20 09:17:20', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (85, '大阪三井', false, false, true, false, false, false, 1, '2014-05-20 09:17:29', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (86, '北欧亚', false, false, true, false, false, false, 1, '2014-05-20 09:18:05', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (87, 'ZIM', false, false, true, false, false, false, 1, '2014-05-20 09:24:01', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (88, 'MCC', false, false, true, false, false, false, 1, '2014-05-20 09:24:09', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (89, 'NYK', false, false, true, false, false, false, 1, '2014-05-20 09:24:20', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (90, 'KLINE', false, false, true, false, false, false, 1, '2014-05-20 09:25:09', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (91, '澳航', false, false, true, false, false, false, 1, '2014-05-20 09:25:21', NULL, NULL, '', false, false, NULL);
INSERT INTO c_client VALUES (92, '青岛建发', false, false, false, false, false, false, 1, '2014-05-21 08:32:59', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (93, '福州建发', false, false, false, false, false, false, 1, '2014-05-21 08:33:11', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (94, '上海迈林', false, false, false, false, false, false, 1, '2014-05-21 08:33:26', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (95, '厦门速传', false, false, false, false, false, false, 1, '2014-05-21 08:33:42', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (96, '北新建材', false, false, false, false, false, false, 1, '2014-05-21 08:34:00', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (97, '莆田标准', false, false, false, false, false, false, 1, '2014-05-21 08:34:18', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (98, '江苏外贸', false, false, false, false, false, false, 1, '2014-05-21 08:34:40', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (99, '江苏舜天', false, false, false, false, false, false, 1, '2014-05-21 08:34:51', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (100, '江苏汇鸿', false, false, false, false, false, false, 1, '2014-05-21 08:40:20', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (101, '上海大威', false, false, false, false, false, false, 1, '2014-05-21 08:40:59', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (102, '上海建发', false, false, false, false, false, false, 1, '2014-05-21 08:41:09', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (103, '天津建发', false, false, false, false, false, false, 1, '2014-05-21 08:41:17', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (104, '福建海虹', false, false, false, false, false, false, 1, '2014-05-21 08:42:00', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (105, '福建振海', false, false, false, false, false, false, 1, '2014-05-21 08:42:21', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (106, '日照港信', false, false, false, false, false, false, 1, '2014-05-23 09:46:06', NULL, NULL, '', false, true, NULL);
INSERT INTO c_client VALUES (53, '红日森林', true, false, false, false, false, true, 1, '2014-04-24 09:28:50', 1, '2014-06-27 02:22:13', '', false, false, 1);


--
-- TOC entry 2845 (class 0 OID 0)
-- Dependencies: 180
-- Name: c_client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_client_id_seq', 106, true);


--
-- TOC entry 2523 (class 0 OID 27759)
-- Dependencies: 181
-- Data for Name: c_cntr_type; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_cntr_type VALUES (1, '20GP', '20尺干箱', 1, '2014-03-03 13:30:32', NULL, NULL, '');
INSERT INTO c_cntr_type VALUES (2, '40GP', '40尺干箱', 1, '2014-03-03 13:30:33', NULL, NULL, '');
INSERT INTO c_cntr_type VALUES (3, '40HC', '40尺超高干箱', 1, '2014-03-03 13:30:33', NULL, NULL, '');
INSERT INTO c_cntr_type VALUES (4, '45HC', '45尺超高干箱', 1, '2014-04-23 14:11:46', NULL, NULL, '');


--
-- TOC entry 2846 (class 0 OID 0)
-- Dependencies: 182
-- Name: c_cntr_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_cntr_type_id_seq', 4, true);


--
-- TOC entry 2525 (class 0 OID 27766)
-- Dependencies: 183
-- Data for Name: c_contract_action; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_contract_action VALUES (1, '报检', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 1);
INSERT INTO c_contract_action VALUES (3, '押箱', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 3);
INSERT INTO c_contract_action VALUES (4, '验货', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 4);
INSERT INTO c_contract_action VALUES (5, '熏蒸', '', 1, '2014-03-03 14:12:04', NULL, NULL, false, 5);
INSERT INTO c_contract_action VALUES (6, '取样', '', 1, '2014-03-03 14:12:04', NULL, NULL, false, 6);
INSERT INTO c_contract_action VALUES (8, '拆箱完成', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 8);
INSERT INTO c_contract_action VALUES (9, '检尺', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 9);
INSERT INTO c_contract_action VALUES (10, '还箱', '', 1, '2014-03-03 14:12:04', NULL, NULL, true, 10);
INSERT INTO c_contract_action VALUES (2, '报关', '', 1, '2014-03-03 14:12:04', 1, '2014-04-11 05:48:13', true, 2);
INSERT INTO c_contract_action VALUES (7, '拆箱', '', 1, '2014-03-03 14:12:04', 1, '2014-06-25 07:14:19', true, 7);


--
-- TOC entry 2847 (class 0 OID 0)
-- Dependencies: 184
-- Name: c_contract_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_contract_action_id_seq', 10, true);


--
-- TOC entry 2527 (class 0 OID 27773)
-- Dependencies: 185
-- Data for Name: c_dispatch; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_dispatch VALUES (1, '美国', '', 1, '2014-04-24 18:16:46', NULL, NULL);
INSERT INTO c_dispatch VALUES (2, '欧洲', '', 1, '2014-04-24 18:16:46', NULL, NULL);


--
-- TOC entry 2848 (class 0 OID 0)
-- Dependencies: 186
-- Name: c_dispatch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_dispatch_id_seq', 2, true);


--
-- TOC entry 2529 (class 0 OID 27780)
-- Dependencies: 187
-- Data for Name: c_fee; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_fee VALUES (1, '包干费', true, '', 1, '2014-03-04 08:26:50', NULL, NULL, false);
INSERT INTO c_fee VALUES (2, '码头超期费', false, '', 1, '2014-03-04 08:26:50', NULL, NULL, true);
INSERT INTO c_fee VALUES (3, '码头堆存费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, true);
INSERT INTO c_fee VALUES (4, '码头搬移费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, true);
INSERT INTO c_fee VALUES (5, '海关验货费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, false);
INSERT INTO c_fee VALUES (6, '商检熏蒸费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, true);
INSERT INTO c_fee VALUES (7, '商检熏蒸场地费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, true);
INSERT INTO c_fee VALUES (8, '商检熏蒸拖车费', false, '', 1, '2014-03-04 08:29:03', NULL, NULL, true);
INSERT INTO c_fee VALUES (11, '滞报金', false, '', 1, '2014-04-28 15:21:54', NULL, NULL, true);


--
-- TOC entry 2849 (class 0 OID 0)
-- Dependencies: 188
-- Name: c_fee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_fee_id_seq', 11, true);


--
-- TOC entry 2531 (class 0 OID 27802)
-- Dependencies: 189
-- Data for Name: c_pay_type; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_pay_type VALUES (1, '现金', 1, '2014-03-04 09:58:57', NULL, NULL, '');
INSERT INTO c_pay_type VALUES (2, '支票', 1, '2014-03-04 09:58:57', NULL, NULL, '');
INSERT INTO c_pay_type VALUES (3, '银行转账', 1, '2014-03-04 09:58:57', NULL, NULL, '');
INSERT INTO c_pay_type VALUES (4, '承兑', 1, '2014-04-23 14:31:51', NULL, NULL, '');


--
-- TOC entry 2850 (class 0 OID 0)
-- Dependencies: 190
-- Name: c_pay_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_pay_type_id_seq', 4, true);


--
-- TOC entry 2533 (class 0 OID 27808)
-- Dependencies: 191
-- Data for Name: c_place; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_place VALUES (1, '罗马尼亚', 1, '2014-05-05 18:13:24', NULL, NULL, '');
INSERT INTO c_place VALUES (3, '乌拉圭', 1, '2014-05-05 18:14:06', NULL, NULL, '');
INSERT INTO c_place VALUES (4, '法国', 1, '2014-05-08 09:13:17', NULL, NULL, '');
INSERT INTO c_place VALUES (5, '哥斯达黎加', 1, '2014-05-08 09:13:17', NULL, NULL, '');
INSERT INTO c_place VALUES (6, '乌克兰', 1, '2014-05-08 09:13:17', NULL, NULL, '');
INSERT INTO c_place VALUES (7, '美国', 1, '2014-05-08 09:13:17', NULL, NULL, '');
INSERT INTO c_place VALUES (8, '加拿大', 1, '2014-05-08 09:13:17', NULL, NULL, '');
INSERT INTO c_place VALUES (9, '立陶宛', 1, '2014-05-08 09:13:17', NULL, NULL, '');
INSERT INTO c_place VALUES (10, '拉脱维亚', 1, '2014-05-08 09:13:17', NULL, NULL, '');
INSERT INTO c_place VALUES (11, '爱沙尼亚', 1, '2014-05-08 09:13:17', NULL, NULL, '');
INSERT INTO c_place VALUES (12, '德国', 1, '2014-05-08 09:13:17', NULL, NULL, '');
INSERT INTO c_place VALUES (13, '巴西', 1, '2014-05-08 09:13:30', NULL, NULL, '');
INSERT INTO c_place VALUES (14, '新西兰', 1, '2014-05-08 09:13:46', NULL, NULL, '');
INSERT INTO c_place VALUES (15, '俄罗斯', 1, '2014-05-08 09:14:06', NULL, NULL, '');
INSERT INTO c_place VALUES (16, '智利', 1, '2014-05-08 09:14:06', NULL, NULL, '');
INSERT INTO c_place VALUES (17, '波兰', 1, '2014-05-08 09:14:06', 1, '2014-05-08 01:14:27', '');
INSERT INTO c_place VALUES (18, '斯洛伐克', 1, '2014-05-08 09:14:38', NULL, NULL, '');


--
-- TOC entry 2851 (class 0 OID 0)
-- Dependencies: 192
-- Name: c_place_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_place_id_seq', 18, true);


--
-- TOC entry 2573 (class 0 OID 28408)
-- Dependencies: 231
-- Data for Name: c_rpt; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_rpt VALUES (1, '客户账单', NULL, 1, '2014-05-27 16:33:58', NULL, NULL);


--
-- TOC entry 2577 (class 0 OID 28432)
-- Dependencies: 235
-- Data for Name: c_rpt_fee; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_rpt_fee VALUES (2, 1, 1, 1, NULL, 1, '2014-05-29 13:12:08', NULL, NULL);
INSERT INTO c_rpt_fee VALUES (3, 1, 2, 11, NULL, 1, '2014-05-29 13:12:20', NULL, NULL);
INSERT INTO c_rpt_fee VALUES (4, 1, 3, 7, NULL, 1, '2014-05-29 13:12:30', NULL, NULL);
INSERT INTO c_rpt_fee VALUES (5, 1, 3, 8, NULL, 1, '2014-05-29 13:12:30', NULL, NULL);
INSERT INTO c_rpt_fee VALUES (6, 1, 4, 4, NULL, 1, '2014-05-29 14:18:06', NULL, NULL);
INSERT INTO c_rpt_fee VALUES (7, 1, 4, 2, NULL, 1, '2014-05-29 14:18:06', NULL, NULL);
INSERT INTO c_rpt_fee VALUES (8, 1, 4, 3, NULL, 1, '2014-05-29 14:18:06', NULL, NULL);
INSERT INTO c_rpt_fee VALUES (9, 1, 2, 5, NULL, 1, '2014-05-29 14:18:15', NULL, NULL);


--
-- TOC entry 2852 (class 0 OID 0)
-- Dependencies: 234
-- Name: c_rpt_fee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_rpt_fee_id_seq', 9, true);


--
-- TOC entry 2853 (class 0 OID 0)
-- Dependencies: 230
-- Name: c_rpt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_rpt_id_seq', 3, true);


--
-- TOC entry 2575 (class 0 OID 28419)
-- Dependencies: 233
-- Data for Name: c_rpt_item; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO c_rpt_item VALUES (1, '包干费', 1, NULL, 1, '2014-05-28 11:10:58', 1, '2014-05-29 00:27:13', 1);
INSERT INTO c_rpt_item VALUES (3, '商检费用', 1, NULL, 1, '2014-05-29 09:07:57', NULL, NULL, 3);
INSERT INTO c_rpt_item VALUES (4, '码头费用', 1, NULL, 1, '2014-05-29 09:08:07', 1, '2014-06-04 23:51:07', 2);
INSERT INTO c_rpt_item VALUES (2, '海关费用', 1, NULL, 1, '2014-05-28 11:11:03', 1, '2014-06-04 23:51:20', 4);


--
-- TOC entry 2854 (class 0 OID 0)
-- Dependencies: 232
-- Name: c_rpt_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('c_rpt_item_id_seq', 5, true);


--
-- TOC entry 2535 (class 0 OID 27814)
-- Dependencies: 193
-- Data for Name: contract; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO contract VALUES (10, '563178209', 39, 1, NULL, 837, 397933.00, 409.508, '2014-04-18', '2014-05-05', NULL, NULL, NULL, NULL, NULL, false, NULL, '', 1, '2014-04-23 14:20:36', NULL, '2014-04-24 18:15:03.332742', 'LICA MAERSK/433N', '', 1, '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO contract VALUES (11, '562709562', 53, 1, NULL, NULL, NULL, NULL, '2014-04-21', '2014-04-14', NULL, NULL, NULL, NULL, NULL, false, NULL, '', 1, '2014-04-24 09:43:42', 1, '2014-04-24 18:15:03.332742', '', '', 1, '', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO contract VALUES (12, '951383492', 53, 1, NULL, 1653, 458050.23, 518.981, '2014-04-16', '2014-04-08', '2014-04-18', NULL, NULL, NULL, NULL, false, NULL, '', 1, '2014-04-24 16:27:54', 1, '2014-05-06 06:53:35.551885', 'CMA CGM RABELAIS A28E', '999', 2, '', '', NULL, NULL, NULL, NULL, 2, 1, 2, 12);
INSERT INTO contract VALUES (15, 'csdsresd', 55, 1, NULL, 23, 212.00, 121.000, '2014-05-13', '2014-05-13', '2014-05-29', NULL, NULL, NULL, 57, false, NULL, '', 1, '2014-05-13 15:32:19', NULL, NULL, 'ddd', 'ddd', 1, 'dd', 'ddd', 62, 56, 56, 58, 11, 11, 3, 4);


--
-- TOC entry 2536 (class 0 OID 27824)
-- Dependencies: 194
-- Data for Name: contract_action; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO contract_action VALUES (10, 10, 1, false, NULL, '', 1, '2014-04-23 14:22:47', NULL, NULL);
INSERT INTO contract_action VALUES (11, 10, 3, false, NULL, '', 1, '2014-04-23 14:22:47', NULL, NULL);
INSERT INTO contract_action VALUES (12, 10, 10, false, NULL, '', 1, '2014-04-23 14:22:47', NULL, NULL);
INSERT INTO contract_action VALUES (13, 12, 1, true, NULL, '', 1, '2014-05-06 16:01:05', NULL, NULL);
INSERT INTO contract_action VALUES (14, 15, 2, false, NULL, '', 1, '2014-05-13 15:32:19', NULL, NULL);


--
-- TOC entry 2855 (class 0 OID 0)
-- Dependencies: 195
-- Name: contract_action_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('contract_action_id_seq', 14, true);


--
-- TOC entry 2538 (class 0 OID 27831)
-- Dependencies: 196
-- Data for Name: contract_cntr; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO contract_cntr VALUES (9, 14, 1, '2014-04-23 14:20:55', NULL, NULL, '', 2, 10, NULL);
INSERT INTO contract_cntr VALUES (11, 11, 1, '2014-05-06 16:00:36', NULL, NULL, '', 2, 12, 2);


--
-- TOC entry 2856 (class 0 OID 0)
-- Dependencies: 197
-- Name: contract_cntr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('contract_cntr_id_seq', 11, true);


--
-- TOC entry 2857 (class 0 OID 0)
-- Dependencies: 198
-- Name: contract_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('contract_id_seq', 15, true);


--
-- TOC entry 2541 (class 0 OID 27839)
-- Dependencies: 199
-- Data for Name: django_admin_log; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--



--
-- TOC entry 2858 (class 0 OID 0)
-- Dependencies: 200
-- Name: django_admin_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('django_admin_log_id_seq', 1, false);


--
-- TOC entry 2543 (class 0 OID 27848)
-- Dependencies: 201
-- Data for Name: django_content_type; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO django_content_type VALUES (1, 'log entry', 'admin', 'logentry');
INSERT INTO django_content_type VALUES (2, 'permission', 'auth', 'permission');
INSERT INTO django_content_type VALUES (3, 'group', 'auth', 'group');
INSERT INTO django_content_type VALUES (4, 'user', 'auth', 'user');
INSERT INTO django_content_type VALUES (5, 'content type', 'contenttypes', 'contenttype');
INSERT INTO django_content_type VALUES (6, 'session', 'sessions', 'session');


--
-- TOC entry 2859 (class 0 OID 0)
-- Dependencies: 202
-- Name: django_content_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('django_content_type_id_seq', 6, true);


--
-- TOC entry 2545 (class 0 OID 27853)
-- Dependencies: 203
-- Data for Name: django_session; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO django_session VALUES ('rwaw7bfzffn5cmu4e1uz4evkosb4a9j7', 'OTQ3ZjE3YTIyNzM2OWFhNWM3YmIyZDUwMjMwNWE1MGFhMTMzZmQ2NDp7Il9hdXRoX3VzZXJfYmFja2VuZCI6ImRqYW5nby5jb250cmliLmF1dGguYmFja2VuZHMuTW9kZWxCYWNrZW5kIiwiX2F1dGhfdXNlcl9pZCI6MX0=', '2014-01-31 14:44:07.239491+08');
INSERT INTO django_session VALUES ('5rr7ps6ils4yj9mqyk8hz60csuoa5lg7', 'OTQ3ZjE3YTIyNzM2OWFhNWM3YmIyZDUwMjMwNWE1MGFhMTMzZmQ2NDp7Il9hdXRoX3VzZXJfYmFja2VuZCI6ImRqYW5nby5jb250cmliLmF1dGguYmFja2VuZHMuTW9kZWxCYWNrZW5kIiwiX2F1dGhfdXNlcl9pZCI6MX0=', '2014-01-31 14:48:18.626959+08');
INSERT INTO django_session VALUES ('htcmdnbb0ulrhp25ua8c0cbv1de8krat', 'YjM0ZTk5NDRjZGJiODY2ZmQ0ZjEzNGRiZTk2Y2UxNGU1ZTRhNDA4YTp7InVzZXJpZCI6MSwibG9nb24iOnRydWV9', '2014-03-07 14:37:44.219924+08');
INSERT INTO django_session VALUES ('s5x49kqeux5p7vpjntamfi2a5eyvviy1', 'ODNlMmE4ZDNlM2NhODRmNmEyMDQzOGYzYWM1MzJkYzNlZmJhNjRlNTp7InVzZXJpZCI6NiwibG9nb24iOnRydWV9', '2014-05-09 14:06:06.108695+08');
INSERT INTO django_session VALUES ('8k0q4omimtkmvfybyrb3b0a4olrw7v6g', 'ODNlMmE4ZDNlM2NhODRmNmEyMDQzOGYzYWM1MzJkYzNlZmJhNjRlNTp7InVzZXJpZCI6NiwibG9nb24iOnRydWV9', '2014-05-05 10:44:19.16433+08');
INSERT INTO django_session VALUES ('f042vpepl5xjvp7w8co6ezs7egj6cd0w', 'YjM0ZTk5NDRjZGJiODY2ZmQ0ZjEzNGRiZTk2Y2UxNGU1ZTRhNDA4YTp7InVzZXJpZCI6MSwibG9nb24iOnRydWV9', '2014-05-07 09:35:26.565729+08');
INSERT INTO django_session VALUES ('6qj2wn8dukqnermfw0vrh2nja7v1q9gi', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-05-07 09:38:57.509758+08');
INSERT INTO django_session VALUES ('009nt961i62b5wzkasclj4rbptthogpm', 'YjM0ZTk5NDRjZGJiODY2ZmQ0ZjEzNGRiZTk2Y2UxNGU1ZTRhNDA4YTp7InVzZXJpZCI6MSwibG9nb24iOnRydWV9', '2014-05-07 10:16:16.955584+08');
INSERT INTO django_session VALUES ('tgu3pzkzlt2w9hwbr2u2bj1jqoy37ur8', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-05-14 09:27:04.950852+08');
INSERT INTO django_session VALUES ('ewulu1njpl95pka5nwv1efmodd9p6cer', 'YmViMmE3YzkwNTU2NWNiMDUwOTBhM2ExMGZjNzU1Y2M1YjllZjMwMDp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjZ9', '2014-05-19 11:32:28.414055+08');
INSERT INTO django_session VALUES ('4i63a3ybxhdsdsxwnw3uhs0x2z0ydbdz', 'YmViMmE3YzkwNTU2NWNiMDUwOTBhM2ExMGZjNzU1Y2M1YjllZjMwMDp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjZ9', '2014-05-07 14:52:34.243206+08');
INSERT INTO django_session VALUES ('uxkaxbp88emvkao1yh7x8ruvgp34ajrg', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-05-07 20:21:44.398898+08');
INSERT INTO django_session VALUES ('gmdmrmlewuxcwhz1gbsafar5mi63tzfc', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-05-08 10:38:30.813399+08');
INSERT INTO django_session VALUES ('z0hk180qi9psehry1rj3fupuoh8722p8', 'YjM0ZTk5NDRjZGJiODY2ZmQ0ZjEzNGRiZTk2Y2UxNGU1ZTRhNDA4YTp7InVzZXJpZCI6MSwibG9nb24iOnRydWV9', '2014-06-27 13:01:08.310292+08');
INSERT INTO django_session VALUES ('qeu384e0pcj83qd8wmkyb944tox80gey', 'YmViMmE3YzkwNTU2NWNiMDUwOTBhM2ExMGZjNzU1Y2M1YjllZjMwMDp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjZ9', '2014-06-03 11:12:29.851925+08');
INSERT INTO django_session VALUES ('b68rljlehq4dik4xkzk9vujsb9jhty67', 'YmViMmE3YzkwNTU2NWNiMDUwOTBhM2ExMGZjNzU1Y2M1YjllZjMwMDp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjZ9', '2014-05-21 20:18:01.960398+08');
INSERT INTO django_session VALUES ('tse66m0klkg4ixcodjaps6o4k9a4mcje', 'YjM0ZTk5NDRjZGJiODY2ZmQ0ZjEzNGRiZTk2Y2UxNGU1ZTRhNDA4YTp7InVzZXJpZCI6MSwibG9nb24iOnRydWV9', '2014-06-26 13:13:11.765631+08');
INSERT INTO django_session VALUES ('0uimk2hbc3gvy2nt76dm657a78b6tx6u', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-06-19 12:52:23.344949+08');
INSERT INTO django_session VALUES ('jttnbe3yy6x22ny9dfh8vxdpszu8jzk7', 'YjM0ZTk5NDRjZGJiODY2ZmQ0ZjEzNGRiZTk2Y2UxNGU1ZTRhNDA4YTp7InVzZXJpZCI6MSwibG9nb24iOnRydWV9', '2014-06-27 17:02:34.124365+08');
INSERT INTO django_session VALUES ('el28y0ffbm59nkcfo5170wwlbxvei2u9', 'YmViMmE3YzkwNTU2NWNiMDUwOTBhM2ExMGZjNzU1Y2M1YjllZjMwMDp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjZ9', '2014-06-23 10:05:20.302245+08');
INSERT INTO django_session VALUES ('ulm6mdmhj8fojjkthgoyokvvidi5ba7q', 'OTEwZjZiYjhiNTk0MmM2YzNmYTExYWY5MWQ4NzE2ZmM0ZjdiYTViOTp7fQ==', '2014-06-27 18:28:44.690147+08');
INSERT INTO django_session VALUES ('75veij6ldhfdfd5kuxhyq2kexs630bak', 'OTEwZjZiYjhiNTk0MmM2YzNmYTExYWY5MWQ4NzE2ZmM0ZjdiYTViOTp7fQ==', '2014-06-27 18:29:42.402527+08');
INSERT INTO django_session VALUES ('onajvlliyd8frntndbvj59bzf6vt8y2x', 'YjM0ZTk5NDRjZGJiODY2ZmQ0ZjEzNGRiZTk2Y2UxNGU1ZTRhNDA4YTp7InVzZXJpZCI6MSwibG9nb24iOnRydWV9', '2014-06-26 18:15:19.71395+08');
INSERT INTO django_session VALUES ('39lb0q9gl1qj89qqyb3u1tdwbvcfgtsc', 'YmViMmE3YzkwNTU2NWNiMDUwOTBhM2ExMGZjNzU1Y2M1YjllZjMwMDp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjZ9', '2014-06-26 09:28:10.21047+08');
INSERT INTO django_session VALUES ('yibqkipkacwcntfwjnruk5z3908njp2f', 'YmViMmE3YzkwNTU2NWNiMDUwOTBhM2ExMGZjNzU1Y2M1YjllZjMwMDp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjZ9', '2014-06-04 08:23:40.008225+08');
INSERT INTO django_session VALUES ('usf7ako5qshmv9mrz716qjihx6cy6bcq', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-06-26 22:16:06.463158+08');
INSERT INTO django_session VALUES ('2dpd2htmj8spyhii6wwbjv0wyaify5s8', 'YjM0ZTk5NDRjZGJiODY2ZmQ0ZjEzNGRiZTk2Y2UxNGU1ZTRhNDA4YTp7InVzZXJpZCI6MSwibG9nb24iOnRydWV9', '2014-07-09 09:03:28.131304+08');
INSERT INTO django_session VALUES ('zqc1vdw4ab4gmq1hhywkmobkyauvo8i6', 'YjM0ZTk5NDRjZGJiODY2ZmQ0ZjEzNGRiZTk2Y2UxNGU1ZTRhNDA4YTp7InVzZXJpZCI6MSwibG9nb24iOnRydWV9', '2014-06-30 12:48:42.653339+08');
INSERT INTO django_session VALUES ('kpenqt2ukrowmy34u0iorc94bj9fwsam', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-07-09 16:30:22.016435+08');
INSERT INTO django_session VALUES ('nuqfhliky149l2479epv0p5ea7w63pq5', 'ODNlMmE4ZDNlM2NhODRmNmEyMDQzOGYzYWM1MzJkYzNlZmJhNjRlNTp7InVzZXJpZCI6NiwibG9nb24iOnRydWV9', '2014-05-27 09:16:20.238777+08');
INSERT INTO django_session VALUES ('ocpb3cytmee7m2veshqx82y9sbpdhtk4', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-06-26 18:31:21.017856+08');
INSERT INTO django_session VALUES ('u5j0fwbenxgmlf2j2o8tjoqvh7rvdv74', 'ODNlMmE4ZDNlM2NhODRmNmEyMDQzOGYzYWM1MzJkYzNlZmJhNjRlNTp7InVzZXJpZCI6NiwibG9nb24iOnRydWV9', '2014-06-09 10:05:03.548053+08');
INSERT INTO django_session VALUES ('iucqfn61ub3x6gaw6u2h3o1yivqmbcrc', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-06-03 08:44:49.654574+08');
INSERT INTO django_session VALUES ('tjmvsi9iqsjzuaak0o7r1bw38gf1h46q', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-06-03 08:45:50.402849+08');
INSERT INTO django_session VALUES ('111xv56ovm11hgp4iwjpepkr9pjsxujy', 'YzA3MzY5ZWE3ZjM4MjJiNWFmMjE4ZjBjYTIzNmRiYmIxZGMwZjI0Nzp7ImxvZ29uIjp0cnVlLCJ1c2VyaWQiOjF9', '2014-06-27 12:57:35.21314+08');


--
-- TOC entry 2581 (class 0 OID 28474)
-- Dependencies: 239
-- Data for Name: p_fee_ele; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO p_fee_ele VALUES (1, '箱型', 'select trim(to_char(id,"9999999999")) lov_cod,cntr_type lov_name from c_cntr_type', '代码表的id转换为字符型，字段名称固定为lov_cod和lov_name', 1, '2014-06-13 16:01:00', 1, '2014-06-13 08:09:46');
INSERT INTO p_fee_ele VALUES (2, '发货地', 'select trim(to_char(id,"9999999999")) lov_cod,place_name lov_name from c_dispatch', '', 1, '2014-06-13 16:17:17', NULL, NULL);
INSERT INTO p_fee_ele VALUES (3, '货物分类', 'select trim(to_char(id,"9999999999")) lov_cod,type_name lov_name from c_cargo_type', '', 1, '2014-06-13 16:18:46', NULL, NULL);
INSERT INTO p_fee_ele VALUES (4, '免费天数', '', '', 1, '2014-06-20 10:44:39', NULL, NULL);


--
-- TOC entry 2860 (class 0 OID 0)
-- Dependencies: 238
-- Name: p_fee_ele_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('p_fee_ele_id_seq', 4, true);


--
-- TOC entry 2583 (class 0 OID 28485)
-- Dependencies: 241
-- Data for Name: p_fee_ele_lov; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO p_fee_ele_lov VALUES (4, 2, '2', '欧洲', NULL, 1, '2014-06-17 23:34:00.900007', NULL, NULL);
INSERT INTO p_fee_ele_lov VALUES (5, 3, '2', '原木', NULL, 1, '2014-06-18 00:18:33.078555', NULL, NULL);
INSERT INTO p_fee_ele_lov VALUES (6, 3, '3', '板材', NULL, 1, '2014-06-18 00:18:33.078555', NULL, NULL);
INSERT INTO p_fee_ele_lov VALUES (7, 2, '1', '美国', NULL, 1, '2014-06-18 00:20:18.125905', NULL, NULL);
INSERT INTO p_fee_ele_lov VALUES (8, 1, '1', '20GP', NULL, 1, '2014-06-18 00:34:31.238552', NULL, NULL);
INSERT INTO p_fee_ele_lov VALUES (9, 1, '2', '40GP', NULL, 1, '2014-06-18 00:34:31.238552', NULL, NULL);
INSERT INTO p_fee_ele_lov VALUES (10, 1, '3', '40HC', NULL, 1, '2014-06-18 00:34:31.238552', NULL, NULL);
INSERT INTO p_fee_ele_lov VALUES (11, 1, '4', '45HC', NULL, 1, '2014-06-18 00:34:31.238552', NULL, NULL);


--
-- TOC entry 2861 (class 0 OID 0)
-- Dependencies: 240
-- Name: p_fee_ele_lov_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('p_fee_ele_lov_id_seq', 11, true);


--
-- TOC entry 2585 (class 0 OID 28509)
-- Dependencies: 243
-- Data for Name: p_fee_mod; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO p_fee_mod VALUES (2, '包干费模式', '', 1, '2014-06-17 15:20:29', NULL, NULL, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '');
INSERT INTO p_fee_mod VALUES (3, '月结堆存费模式', '', 1, '2014-06-20 10:45:40', 1, '2014-06-23 07:09:37', 3, 4, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '');


--
-- TOC entry 2862 (class 0 OID 0)
-- Dependencies: 242
-- Name: p_fee_mod_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('p_fee_mod_id_seq', 3, true);


--
-- TOC entry 2579 (class 0 OID 28464)
-- Dependencies: 237
-- Data for Name: p_protocol; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO p_protocol VALUES (1, '红日森林', '2014-06-05', '2016-06-30', '', 1, '2014-06-05 15:03:08', NULL, NULL);


--
-- TOC entry 2587 (class 0 OID 28582)
-- Dependencies: 245
-- Data for Name: p_protocol_fee_mod; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO p_protocol_fee_mod VALUES (3, 1, 1, 2, 1, '', 1, '2014-06-19 15:13:18', NULL, NULL, true);
INSERT INTO p_protocol_fee_mod VALUES (6, 1, 3, 3, 1, '', 1, '2014-06-23 09:33:16', NULL, NULL, true);


--
-- TOC entry 2863 (class 0 OID 0)
-- Dependencies: 244
-- Name: p_protocol_fee_mod_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('p_protocol_fee_mod_id_seq', 6, true);


--
-- TOC entry 2864 (class 0 OID 0)
-- Dependencies: 236
-- Name: p_protocol_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('p_protocol_id_seq', 1, true);


--
-- TOC entry 2589 (class 0 OID 28614)
-- Dependencies: 247
-- Data for Name: p_protocol_rat; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO p_protocol_rat VALUES (3, 1, 3, 3, '2', '11', '1', '', '', '', '', '', '', '', 11.00, NULL, '', 1, '2014-06-23 15:46:26', NULL, NULL);
INSERT INTO p_protocol_rat VALUES (4, 1, 1, 2, '2', '3', '', '', '', '', '', '', '', '', 222.00, NULL, '', 1, '2014-06-23 15:47:12', NULL, NULL);
INSERT INTO p_protocol_rat VALUES (5, 1, 1, 2, '2', '2', '', '', '', '', '', '', '', '', 333.00, NULL, '', 1, '2014-06-27 10:08:44', NULL, NULL);
INSERT INTO p_protocol_rat VALUES (6, 1, 1, 2, '3', '1', '', '', '', '', '', '', '', '', 111.00, NULL, '', 1, '2014-06-27 10:08:44', NULL, NULL);


--
-- TOC entry 2865 (class 0 OID 0)
-- Dependencies: 246
-- Name: p_protocol_rat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('p_protocol_rat_id_seq', 6, true);


--
-- TOC entry 2546 (class 0 OID 27859)
-- Dependencies: 204
-- Data for Name: pre_fee; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO pre_fee VALUES (46, 10, 'I', 1, 39, 700.00, '2014-04-23 06:44:48', false, '2014-04-23 06:44:48', 1, '2014-04-23 06:44:48', NULL, NULL, '', '', '', 'O', false, NULL, '');
INSERT INTO pre_fee VALUES (47, 10, 'O', 2, 42, 333.00, '2014-04-24 00:00:00', false, '2014-04-24 00:00:00', 1, '2014-04-24 15:50:15', NULL, NULL, '', '', '', 'O', false, NULL, '');
INSERT INTO pre_fee VALUES (48, 10, 'I', 2, 39, 333.00, '2014-04-24 07:50:22', false, '2014-04-24 00:00:00', 1, '2014-04-24 07:50:22', NULL, NULL, '', '', '', 'O', false, NULL, '');
INSERT INTO pre_fee VALUES (51, 12, 'O', 3, 46, 2322.00, '2014-06-05 00:00:00', false, '2014-06-05 00:00:00', 1, '2014-06-05 08:45:40', NULL, NULL, '', '', '', 'O', false, NULL, '');
INSERT INTO pre_fee VALUES (50, 12, 'I', 1, 53, 3300.00, '2014-04-24 00:00:00', false, '2014-04-24 00:00:00', 1, '2014-04-24 16:40:51', 1, '2014-05-06 06:20:25', '', '', '', 'O', false, NULL, '');
INSERT INTO pre_fee VALUES (55, 11, 'I', 4, 53, 777.00, '2014-06-05 00:00:00', false, '2014-06-05 00:00:00', 1, '2014-06-05 08:46:23', NULL, NULL, '', '', '', 'O', false, NULL, '');
INSERT INTO pre_fee VALUES (49, 12, 'I', 2, 53, 22.00, '2014-04-24 00:00:00', false, '2014-04-24 00:00:00', 1, '2014-04-24 16:35:46', 1, '2014-05-06 06:20:25', '', '', '', 'O', false, NULL, '');
INSERT INTO pre_fee VALUES (52, 11, 'I', 5, 53, 434.00, '2014-06-05 00:00:00', false, '2014-06-05 00:00:00', 1, '2014-06-05 08:46:23', NULL, NULL, '', '', '17', 'O', true, '2014-06-26 16:05:06', '');
INSERT INTO pre_fee VALUES (53, 11, 'I', 6, 53, 555.00, '2014-06-05 00:00:00', false, '2014-06-05 00:00:00', 1, '2014-06-05 08:46:23', NULL, NULL, '', '', '17', 'O', true, '2014-06-26 16:05:06', '');
INSERT INTO pre_fee VALUES (54, 11, 'I', 1, 53, 666.00, '2014-06-05 00:00:00', false, '2014-06-05 00:00:00', 1, '2014-06-05 08:46:23', NULL, NULL, '', '', '18', 'O', true, '2014-06-26 16:05:10', '');


--
-- TOC entry 2866 (class 0 OID 0)
-- Dependencies: 205
-- Name: pre_fee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('pre_fee_id_seq', 55, true);


--
-- TOC entry 2571 (class 0 OID 28380)
-- Dependencies: 229
-- Data for Name: s_filter_body; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO s_filter_body VALUES (176, 15, 'username', 'uuu', '', 1, '2014-05-15 08:47:50', NULL, NULL, 'W', '等于', 'uuu', 'uuu');
INSERT INTO s_filter_body VALUES (177, 15, 'lock', '', '', 1, '2014-05-15 08:47:50', NULL, NULL, 'S', '降序', '', '');
INSERT INTO s_filter_body VALUES (178, 15, 'username', '', '', 1, '2014-05-15 08:47:50', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (179, 15, 'lock', '', '', 1, '2014-05-15 08:47:50', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (180, 16, 'cargo_type', '3,2', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'W', '属于', '板材,原木', '板材,原木');
INSERT INTO s_filter_body VALUES (181, 16, 'contract_no', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'S', '升序', '', '');
INSERT INTO s_filter_body VALUES (182, 16, 'dispatch_place', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'S', '降序', '', '');
INSERT INTO s_filter_body VALUES (183, 16, 'bill_no', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (184, 16, 'vslvoy', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (185, 16, 'contract_no', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (186, 16, 'cargo_type', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (187, 16, 'cargo_name', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (188, 16, 'origin_place', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (189, 16, 'dispatch_place', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (190, 16, 'client_id', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (191, 16, 'custom_title1', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (192, 16, 'custom_title2', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (193, 16, 'booking_date', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (194, 16, 'in_port_date', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (195, 16, 'return_cntr_date', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (196, 16, 'custom_id', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (197, 16, 'ship_corp_id', '', '', 1, '2014-05-15 08:56:47', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (198, 16, 'port_id', '', '', 1, '2014-05-15 08:56:48', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (199, 16, 'yard_id', '', '', 1, '2014-05-15 08:56:48', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (200, 16, 'landtrans_id', '', '', 1, '2014-05-15 08:56:48', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (201, 16, 'check_yard_id', '', '', 1, '2014-05-15 08:56:48', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (202, 16, 'unbox_yard_id', '', '', 1, '2014-05-15 08:56:48', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (203, 16, 'credit_id', '', '', 1, '2014-05-15 08:56:48', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (204, 16, 'cntr_freedays', '', '', 1, '2014-05-15 08:56:48', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (205, 16, 'finish_flag', '', '', 1, '2014-05-15 08:56:48', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (206, 16, 'finish_time', '', '', 1, '2014-05-15 08:56:48', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (207, 16, 'remark', '', '', 1, '2014-05-15 08:56:48', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (208, 17, 'username', 'uuu', '', 1, '2014-05-21 07:45:38', NULL, NULL, 'W', '等于', 'uuu', 'uuu');
INSERT INTO s_filter_body VALUES (209, 17, 'username', '', '', 1, '2014-05-21 07:45:38', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (210, 17, 'lock', '', '', 1, '2014-05-21 07:45:38', NULL, NULL, 'C', '', '', '');
INSERT INTO s_filter_body VALUES (211, 17, 'remark', '', '', 1, '2014-05-21 07:45:38', NULL, NULL, 'C', '', '', '');


--
-- TOC entry 2867 (class 0 OID 0)
-- Dependencies: 228
-- Name: s_filter_body_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('s_filter_body_id_seq', 211, true);


--
-- TOC entry 2569 (class 0 OID 28353)
-- Dependencies: 227
-- Data for Name: s_filter_head; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO s_filter_head VALUES (15, 'basedata-user-datagrid', 'P', 1, 'uuu', '', 1, '2014-05-15 08:47:50', NULL, NULL);
INSERT INTO s_filter_head VALUES (16, 'control-contract-datagrid', 'G', 1, 'www', '', 1, '2014-05-15 08:56:47', NULL, NULL);
INSERT INTO s_filter_head VALUES (17, 'basedata-user-datagrid', 'G', 6, 'uuu', '', 1, '2014-05-21 07:45:38', NULL, NULL);


--
-- TOC entry 2868 (class 0 OID 0)
-- Dependencies: 226
-- Name: s_filter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('s_filter_id_seq', 17, true);


--
-- TOC entry 2548 (class 0 OID 27870)
-- Dependencies: 206
-- Data for Name: s_post; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO s_post VALUES (3, '单证', 1, '2014-02-28 09:10:50', NULL, NULL, '');
INSERT INTO s_post VALUES (2, '商务', 1, '2014-02-28 09:10:35', 1, '2014-05-23 02:40:13', '1');


--
-- TOC entry 2869 (class 0 OID 0)
-- Dependencies: 207
-- Name: s_post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('s_post_id_seq', 3, true);


--
-- TOC entry 2550 (class 0 OID 27876)
-- Dependencies: 208
-- Data for Name: s_postmenu; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO s_postmenu VALUES (3, 8, true, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '', 34);
INSERT INTO s_postmenu VALUES (3, 14, true, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '', 35);
INSERT INTO s_postmenu VALUES (3, 15, true, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '', 36);
INSERT INTO s_postmenu VALUES (3, 30, true, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '', 37);
INSERT INTO s_postmenu VALUES (3, 13, true, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '', 38);
INSERT INTO s_postmenu VALUES (3, 18, true, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '', 39);
INSERT INTO s_postmenu VALUES (3, 20, true, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '', 40);
INSERT INTO s_postmenu VALUES (3, 32, true, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '', 41);
INSERT INTO s_postmenu VALUES (2, 8, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 43);
INSERT INTO s_postmenu VALUES (2, 9, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 44);
INSERT INTO s_postmenu VALUES (2, 10, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 45);
INSERT INTO s_postmenu VALUES (2, 11, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 46);
INSERT INTO s_postmenu VALUES (2, 12, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 47);
INSERT INTO s_postmenu VALUES (2, 14, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 48);
INSERT INTO s_postmenu VALUES (2, 15, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 49);
INSERT INTO s_postmenu VALUES (2, 16, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 51);
INSERT INTO s_postmenu VALUES (2, 29, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 53);
INSERT INTO s_postmenu VALUES (2, 30, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 54);
INSERT INTO s_postmenu VALUES (2, 13, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 55);
INSERT INTO s_postmenu VALUES (2, 18, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 56);
INSERT INTO s_postmenu VALUES (2, 20, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 57);
INSERT INTO s_postmenu VALUES (2, 32, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 58);
INSERT INTO s_postmenu VALUES (2, 21, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 60);
INSERT INTO s_postmenu VALUES (2, 31, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 61);
INSERT INTO s_postmenu VALUES (2, 22, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 62);
INSERT INTO s_postmenu VALUES (2, 23, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 63);
INSERT INTO s_postmenu VALUES (2, 25, true, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '', 64);
INSERT INTO s_postmenu VALUES (2, 33, true, 1, '2014-04-24 07:54:43.950847', NULL, NULL, '', 65);
INSERT INTO s_postmenu VALUES (2, 34, true, 1, '2014-04-24 07:54:43.950847', NULL, NULL, '', 66);
INSERT INTO s_postmenu VALUES (3, 33, true, 1, '2014-04-24 07:54:48.866659', NULL, NULL, '', 67);
INSERT INTO s_postmenu VALUES (3, 34, true, 1, '2014-04-24 07:54:48.866659', NULL, NULL, '', 68);
INSERT INTO s_postmenu VALUES (2, 35, true, 1, '2014-04-24 10:12:59.202582', NULL, NULL, '', 69);
INSERT INTO s_postmenu VALUES (2, 36, true, 1, '2014-05-05 10:00:14.757916', NULL, NULL, '', 70);
INSERT INTO s_postmenu VALUES (2, 37, true, 1, '2014-05-05 10:00:14.757916', NULL, NULL, '', 71);
INSERT INTO s_postmenu VALUES (2, 38, true, 1, '2014-05-05 10:00:14.757916', NULL, NULL, '', 72);
INSERT INTO s_postmenu VALUES (2, 39, true, 1, '2014-05-06 08:37:37.430316', NULL, NULL, '', 73);
INSERT INTO s_postmenu VALUES (2, 40, true, 1, '2014-05-12 01:36:36.985389', NULL, NULL, '', 74);
INSERT INTO s_postmenu VALUES (2, 41, true, 1, '2014-05-16 06:42:04.815942', NULL, NULL, '', 75);
INSERT INTO s_postmenu VALUES (2, 42, true, 1, '2014-06-12 01:00:40.204024', NULL, NULL, '', 76);
INSERT INTO s_postmenu VALUES (2, 43, true, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '', 77);
INSERT INTO s_postmenu VALUES (2, 44, true, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '', 78);
INSERT INTO s_postmenu VALUES (2, 46, true, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '', 79);
INSERT INTO s_postmenu VALUES (2, 49, true, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '', 80);


--
-- TOC entry 2870 (class 0 OID 0)
-- Dependencies: 209
-- Name: s_postmenu_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('s_postmenu_id_seq', 80, true);


--
-- TOC entry 2552 (class 0 OID 27883)
-- Dependencies: 210
-- Data for Name: s_postmenufunc; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO s_postmenufunc VALUES (14, 3, 14, 18, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (15, 3, 14, 19, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (16, 3, 15, 22, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (17, 3, 15, 23, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (18, 3, 30, 26, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (19, 3, 30, 27, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (20, 3, 18, 34, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (21, 3, 18, 35, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (22, 3, 18, 36, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (23, 3, 18, 37, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (24, 3, 18, 38, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (25, 3, 18, 39, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (26, 3, 18, 40, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (27, 3, 20, 37, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (28, 3, 20, 41, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (29, 3, 20, 42, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (30, 3, 20, 43, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (31, 3, 20, 44, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (32, 3, 20, 45, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (33, 3, 32, 34, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (34, 3, 32, 35, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (35, 3, 32, 36, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (36, 3, 32, 41, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (37, 3, 32, 42, 1, '2014-04-17 01:29:35.469572', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (38, 2, 9, 16, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (39, 2, 9, 17, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (40, 2, 10, 12, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (41, 2, 10, 13, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (42, 2, 11, 14, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (43, 2, 11, 15, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (44, 2, 11, 12, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (45, 2, 12, 12, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (46, 2, 12, 32, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (47, 2, 12, 33, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (48, 2, 14, 18, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (49, 2, 14, 19, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (50, 2, 15, 22, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (51, 2, 15, 23, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (54, 2, 16, 24, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (55, 2, 16, 25, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (58, 2, 29, 30, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (59, 2, 29, 31, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (60, 2, 30, 26, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (61, 2, 30, 27, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (62, 2, 18, 34, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (63, 2, 18, 35, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (64, 2, 18, 36, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (65, 2, 18, 37, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (66, 2, 18, 38, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (67, 2, 18, 39, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (68, 2, 18, 40, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (69, 2, 20, 37, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (70, 2, 20, 41, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (71, 2, 20, 42, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (72, 2, 20, 43, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (73, 2, 20, 44, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (74, 2, 20, 45, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (75, 2, 32, 34, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (76, 2, 32, 35, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (77, 2, 32, 36, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (78, 2, 32, 41, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (79, 2, 32, 42, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (80, 2, 31, 49, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (81, 2, 31, 50, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (82, 2, 22, 46, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (83, 2, 22, 47, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (84, 2, 22, 48, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (85, 2, 23, 51, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (86, 2, 23, 52, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (87, 2, 25, 53, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (88, 2, 25, 54, 1, '2014-04-17 01:29:51.280174', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (89, 2, 34, 55, 1, '2014-04-24 07:54:43.950847', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (90, 3, 34, 55, 1, '2014-04-24 07:54:48.866659', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (91, 2, 35, 56, 1, '2014-04-24 10:12:59.202582', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (92, 2, 35, 57, 1, '2014-04-24 10:12:59.202582', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (93, 2, 36, 58, 1, '2014-05-05 10:00:14.757916', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (94, 2, 36, 59, 1, '2014-05-05 10:00:14.757916', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (95, 2, 37, 60, 1, '2014-05-05 10:00:14.757916', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (96, 2, 37, 61, 1, '2014-05-05 10:00:14.757916', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (97, 2, 38, 62, 1, '2014-05-05 10:00:14.757916', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (98, 2, 38, 63, 1, '2014-05-05 10:00:14.757916', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (99, 2, 39, 64, 1, '2014-05-06 08:37:37.430316', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (100, 2, 40, 65, 1, '2014-05-12 01:36:36.985389', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (101, 2, 41, 66, 1, '2014-05-16 06:42:04.815942', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (102, 2, 42, 68, 1, '2014-06-12 01:00:40.204024', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (103, 2, 42, 69, 1, '2014-06-12 01:00:40.204024', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (104, 2, 42, 70, 1, '2014-06-12 01:00:40.204024', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (105, 2, 42, 73, 1, '2014-06-12 01:00:40.204024', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (106, 2, 42, 72, 1, '2014-06-12 01:00:40.204024', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (107, 2, 42, 74, 1, '2014-06-12 01:00:40.204024', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (108, 2, 44, 76, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (109, 2, 44, 77, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (110, 2, 46, 80, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (111, 2, 46, 81, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (112, 2, 46, 82, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (113, 2, 49, 76, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (114, 2, 49, 85, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (115, 2, 49, 87, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (116, 2, 49, 88, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '');
INSERT INTO s_postmenufunc VALUES (117, 2, 49, 89, 1, '2014-06-27 02:51:18.769944', NULL, NULL, '');


--
-- TOC entry 2871 (class 0 OID 0)
-- Dependencies: 211
-- Name: s_postmenufunc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('s_postmenufunc_id_seq', 117, true);


--
-- TOC entry 2554 (class 0 OID 27889)
-- Dependencies: 212
-- Data for Name: s_postuser; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO s_postuser VALUES (2, 4, 1, '2014-03-01 09:00:35', NULL, NULL, '', 1);
INSERT INTO s_postuser VALUES (2, 6, 1, '2014-04-17 08:56:55', NULL, NULL, '', 2);
INSERT INTO s_postuser VALUES (3, 6, 1, '2014-04-17 08:57:03', NULL, NULL, '', 3);


--
-- TOC entry 2872 (class 0 OID 0)
-- Dependencies: 213
-- Name: s_postuser_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('s_postuser_id_seq', 5, true);


--
-- TOC entry 2556 (class 0 OID 27895)
-- Dependencies: 214
-- Data for Name: s_user; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO s_user VALUES (1, 'Admin', 'Admin', 1, '2014-02-21 14:33:46.185167', NULL, NULL, '', false);
INSERT INTO s_user VALUES (4, '管理员', 'ok', 1, '2014-03-01 07:25:54', NULL, NULL, '', false);
INSERT INTO s_user VALUES (5, 'xxx', 'ok', 1, '2014-03-04 09:40:34', NULL, NULL, '', false);
INSERT INTO s_user VALUES (6, 'uuu', 'ok', 1, '2014-03-24 14:01:13', NULL, NULL, '', false);
INSERT INTO s_user VALUES (7, 'yyy', 'ok', 1, '2014-03-24 14:19:54', NULL, NULL, '', false);


--
-- TOC entry 2873 (class 0 OID 0)
-- Dependencies: 215
-- Name: s_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('s_user_id_seq', 10, true);


--
-- TOC entry 2874 (class 0 OID 0)
-- Dependencies: 216
-- Name: seq_4_auditfee; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('seq_4_auditfee', 18, true);


--
-- TOC entry 2875 (class 0 OID 0)
-- Dependencies: 217
-- Name: seq_html; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('seq_html', 683, true);


--
-- TOC entry 2560 (class 0 OID 27906)
-- Dependencies: 218
-- Data for Name: sys_code; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO sys_code VALUES (1, 'contract_type', '委托类型', '进口货运', '', 1, '', '', 1, '2014-02-27 16:34:45', NULL, NULL);
INSERT INTO sys_code VALUES (2, 'contract_type', '委托类型', '出口货运', '', 2, '', '', 1, '2014-02-27 16:34:45', NULL, NULL);
INSERT INTO sys_code VALUES (8, 'fee_cal_type', '计费单位', '20尺', '', 1, '', '', 1, '2014-03-04 08:33:26', NULL, NULL);
INSERT INTO sys_code VALUES (9, 'fee_cal_type', '计费单位', '40尺', '', 2, '', '', 1, '2014-03-04 08:33:26', NULL, NULL);


--
-- TOC entry 2876 (class 0 OID 0)
-- Dependencies: 219
-- Name: sys_code_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('sys_code_id_seq', 9, true);


--
-- TOC entry 2562 (class 0 OID 27914)
-- Dependencies: 220
-- Data for Name: sys_func; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO sys_func VALUES ('功能查询', 1, '2014-02-26 09:58:42', 1, '2014-05-26 00:13:41', '', 1, 'sys_menu');
INSERT INTO sys_func VALUES ('功能维护', 1, '2014-02-26 09:58:42', 1, '2014-05-26 00:13:41', '', 2, 'sys_menu');
INSERT INTO sys_func VALUES ('权限查询', 1, '2014-02-26 09:59:14', 1, '2014-05-26 00:13:41', '', 3, 'sys_func');
INSERT INTO sys_func VALUES ('权限维护', 1, '2014-02-26 09:59:14', 1, '2014-05-26 00:13:41', '', 4, 'sys_func');
INSERT INTO sys_func VALUES ('功能权限查询', 1, '2014-03-01 09:26:20', 1, '2014-05-26 00:13:41', '', 7, 'sys_menu_func');
INSERT INTO sys_func VALUES ('功能权限维护', 1, '2014-03-01 09:26:20', 1, '2014-05-26 00:15:07', '', 8, 'sys_menu_func');
INSERT INTO sys_func VALUES ('系统参数查询', 1, '2014-03-01 09:26:53', 1, '2014-05-26 00:15:07', '', 9, 'sys_code');
INSERT INTO sys_func VALUES ('系统参数维护', 1, '2014-03-01 09:26:53', 1, '2014-05-26 00:15:07', '', 10, 'sys_code');
INSERT INTO sys_func VALUES ('岗位查询', 1, '2014-03-01 09:27:29', 1, '2014-05-26 00:15:07', '', 12, 's_post');
INSERT INTO sys_func VALUES ('岗位维护', 1, '2014-03-01 09:27:29', 1, '2014-05-26 00:15:07', '', 13, 's_post');
INSERT INTO sys_func VALUES ('岗位用户查询', 1, '2014-03-01 09:27:49', 1, '2014-05-26 00:15:07', '', 14, 's_postuser');
INSERT INTO sys_func VALUES ('岗位用户维护', 1, '2014-03-01 09:27:49', 1, '2014-05-26 00:15:07', '', 15, 's_postuser');
INSERT INTO sys_func VALUES ('用户查询', 1, '2014-03-01 09:30:58', 1, '2014-05-26 00:16:21', '', 16, 's_user');
INSERT INTO sys_func VALUES ('用户维护', 1, '2014-03-01 09:30:58', 1, '2014-05-26 00:16:21', '', 17, 's_user');
INSERT INTO sys_func VALUES ('箱型查询', 1, '2014-03-03 16:07:17', 1, '2014-05-26 00:16:21', '', 18, 'c_cntr_type');
INSERT INTO sys_func VALUES ('箱型维护', 1, '2014-03-03 16:07:17', 1, '2014-05-26 00:16:21', '', 19, 'c_cntr_type');
INSERT INTO sys_func VALUES ('动态类型查询', 1, '2014-03-03 16:21:26', 1, '2014-05-26 00:16:21', '', 22, 'c_contract_action');
INSERT INTO sys_func VALUES ('产地查询', 1, '2014-05-05 18:02:07', 1, '2014-05-26 00:28:57', '', 62, 'c_place');
INSERT INTO sys_func VALUES ('产地维护', 1, '2014-05-05 18:02:08', 1, '2014-05-26 00:28:57', '', 63, 'c_place');
INSERT INTO sys_func VALUES ('动态类型维护', 1, '2014-03-03 16:21:26', 1, '2014-05-26 00:28:57', '', 23, 'c_contract_action');
INSERT INTO sys_func VALUES ('发货地查询', 1, '2014-04-24 18:13:05', 1, '2014-05-26 00:28:57', '', 56, 'c_dispatch');
INSERT INTO sys_func VALUES ('发货地维护', 1, '2014-04-24 18:13:05', 1, '2014-05-26 00:28:57', '', 57, 'c_dispatch');
INSERT INTO sys_func VALUES ('费用报表头查询', 1, '2014-05-20 15:21:10', 1, '2014-05-26 00:30:13', '', 68, 'c_rpt');
INSERT INTO sys_func VALUES ('委托维护', 1, '2014-03-26 10:41:14', 1, '2014-06-05 02:48:35', '', 38, 'contract,contract_action,contract_cntr');
INSERT INTO sys_func VALUES ('费用报表项目查询', 1, '2014-05-20 15:21:10', 1, '2014-05-26 00:30:13', '', 69, 'c_rpt_item');
INSERT INTO sys_func VALUES ('委托锁定', 1, '2014-03-26 12:49:23', 1, '2014-06-05 02:52:08', '', 39, 'contract');
INSERT INTO sys_func VALUES ('费用名称查询', 1, '2014-03-03 16:39:33', 1, '2014-05-26 00:31:02', '', 24, 'c_fee');
INSERT INTO sys_func VALUES ('费用名称维护', 1, '2014-03-03 16:39:33', 1, '2014-05-26 00:31:02', '', 25, 'c_fee');
INSERT INTO sys_func VALUES ('付款方式查询', 1, '2014-03-26 10:34:27', 1, '2014-05-26 00:31:02', '', 30, 'c_pay_type');
INSERT INTO sys_func VALUES ('付款方式维护', 1, '2014-03-26 10:34:27', 1, '2014-05-26 00:31:02', '', 31, 'c_pay_type');
INSERT INTO sys_func VALUES ('岗位权限查询', 1, '2014-03-26 10:35:23', 1, '2014-05-26 00:31:02', '', 32, 's_postmenufunc');
INSERT INTO sys_func VALUES ('岗位权限维护', 1, '2014-03-26 10:35:23', 1, '2014-05-26 00:31:02', '', 33, 's_postmenufunc');
INSERT INTO sys_func VALUES ('核销', 1, '2014-04-09 10:29:32', 1, '2014-05-26 00:32:32', '', 48, 'pre_fee,act_fee');
INSERT INTO sys_func VALUES ('费用报表头维护', 1, '2014-05-27 16:31:43', NULL, NULL, '', 72, 'c_rpt');
INSERT INTO sys_func VALUES ('费用报表项目维护', 1, '2014-05-28 10:58:55', NULL, NULL, '', 73, 'c_rpt_item');
INSERT INTO sys_func VALUES ('费用报表项目费用查询', 1, '2014-05-20 15:21:10', 1, '2014-05-29 00:12:42', '', 70, 'c_rpt_fee');
INSERT INTO sys_func VALUES ('费用报表项目费用维护', 1, '2014-05-29 08:13:58', 1, '2014-05-29 00:20:28', '', 74, 'c_rpt_fee');
INSERT INTO sys_func VALUES ('客户查询', 1, '2014-03-15 21:43:57', 1, '2014-06-05 02:36:55', '', 26, 'c_client');
INSERT INTO sys_func VALUES ('客户维护', 1, '2014-03-15 21:43:57', 1, '2014-06-05 02:36:55', '', 27, 'c_client');
INSERT INTO sys_func VALUES ('委托查询', 1, '2014-03-26 10:40:48', 1, '2014-06-05 02:46:53', '', 34, 'contract');
INSERT INTO sys_func VALUES ('委托动态查询', 1, '2014-03-26 10:40:48', 1, '2014-06-05 02:46:53', '', 35, 'contract_action');
INSERT INTO sys_func VALUES ('委托箱查询', 1, '2014-03-26 10:40:48', 1, '2014-06-05 02:46:53', '', 36, 'contract_cntr');
INSERT INTO sys_func VALUES ('提单查询', 1, '2014-03-26 10:40:48', 1, '2014-06-05 02:47:30', '', 37, 'contract');
INSERT INTO sys_func VALUES ('核销删除查询', 1, '2014-04-16 12:45:33', 1, '2014-06-05 02:52:08', '', 51, 'act_fee,pre_fee');
INSERT INTO sys_func VALUES ('委托解锁', 1, '2014-03-26 12:49:23', 1, '2014-06-05 02:52:08', '', 40, 'contract');
INSERT INTO sys_func VALUES ('委托应收查询', 1, '2014-03-29 11:31:25', 1, '2014-06-05 02:52:08', '', 41, 'pre_fee');
INSERT INTO sys_func VALUES ('委托应付查询', 1, '2014-03-29 11:31:25', 1, '2014-06-05 02:52:08', '', 42, 'pre_fee');
INSERT INTO sys_func VALUES ('应收付费用维护', 1, '2014-03-29 11:31:25', 1, '2014-06-05 02:52:08', '', 43, 'pre_fee');
INSERT INTO sys_func VALUES ('应收付费用锁定', 1, '2014-03-31 14:04:02', 1, '2014-06-05 02:52:08', '', 44, 'pre_fee');
INSERT INTO sys_func VALUES ('应收付费用解锁', 1, '2014-03-31 14:04:02', 1, '2014-06-05 02:52:08', '', 45, 'pre_fee');
INSERT INTO sys_func VALUES ('实收付未核销查询', 1, '2014-04-09 10:28:53', 1, '2014-06-05 02:52:08', '', 46, 'act_fee');
INSERT INTO sys_func VALUES ('应收付未核销查询', 1, '2014-04-09 10:29:18', 1, '2014-06-05 02:52:08', '', 47, 'pre_fee');
INSERT INTO sys_func VALUES ('已收付费用查询', 1, '2014-04-16 12:41:48', 1, '2014-06-05 02:52:08', '', 49, 'act_fee');
INSERT INTO sys_func VALUES ('已收付费用维护', 1, '2014-04-16 12:41:48', 1, '2014-06-05 02:52:08', '', 50, 'act_fee');
INSERT INTO sys_func VALUES ('核销删除', 1, '2014-04-16 12:45:33', 1, '2014-06-05 02:52:08', '', 52, 'act_fee,pre_fee');
INSERT INTO sys_func VALUES ('核销汇总查询', 1, '2014-04-16 12:46:47', 1, '2014-06-05 02:52:08', '', 53, 'act_fee,pre_fee');
INSERT INTO sys_func VALUES ('核销明细查询', 1, '2014-04-16 12:46:47', 1, '2014-06-05 02:52:08', '', 54, 'act_fee,pre_fee');
INSERT INTO sys_func VALUES ('密码修改', 1, '2014-04-24 15:54:21', 1, '2014-06-05 02:52:08', '', 55, 's_user');
INSERT INTO sys_func VALUES ('货物查询', 1, '2014-05-05 17:49:21', 1, '2014-06-05 02:52:08', '', 58, 'c_cargo');
INSERT INTO sys_func VALUES ('货物维护', 1, '2014-05-05 17:49:21', 1, '2014-06-05 02:52:08', '', 59, 'c_cargo');
INSERT INTO sys_func VALUES ('货物分类查询', 1, '2014-05-05 17:49:21', 1, '2014-06-05 02:52:08', '', 60, 'c_cargo_type');
INSERT INTO sys_func VALUES ('货物分类维护', 1, '2014-05-05 17:49:21', 1, '2014-06-05 02:52:08', '', 61, 'c_cargo_type');
INSERT INTO sys_func VALUES ('客户费用明细报表', 1, '2014-05-06 16:38:30', 1, '2014-06-05 02:52:42', '', 64, 'contract,pre_fee');
INSERT INTO sys_func VALUES ('业务明细报表查询', 1, '2014-05-08 15:13:14', 1, '2014-06-05 02:52:42', '', 65, 'contract,contract_action,contract_cntr');
INSERT INTO sys_func VALUES ('业务汇总报表查询', 1, '2014-05-09 13:06:01', 1, '2014-06-05 02:52:42', '', 66, 'contract,contract_action,contract_cntr');
INSERT INTO sys_func VALUES ('协议查询', 1, '2014-06-05 14:52:27', NULL, NULL, '', 76, 'p_protocol');
INSERT INTO sys_func VALUES ('协议维护', 1, '2014-06-05 14:52:27', NULL, NULL, '', 77, 'p_protocol');
INSERT INTO sys_func VALUES ('协议要素查询', 1, '2014-06-13 15:48:03', NULL, NULL, '', 78, 'p_fee_ele');
INSERT INTO sys_func VALUES ('协议要素维护', 1, '2014-06-13 15:48:03', NULL, NULL, '', 79, 'p_fee_ele');
INSERT INTO sys_func VALUES ('协议要素内容查询', 1, '2014-06-13 17:08:16', NULL, NULL, '', 80, 'p_fee_ele_lov');
INSERT INTO sys_func VALUES ('协议要素内容维护', 1, '2014-06-13 17:08:16', NULL, NULL, '', 81, 'p_fee_ele_lov');
INSERT INTO sys_func VALUES ('协议要素内容初始化', 1, '2014-06-13 17:08:16', NULL, NULL, '', 82, 'p_fee_ele_lov');
INSERT INTO sys_func VALUES ('协议模式查询', 1, '2014-06-17 10:38:09', NULL, NULL, '', 83, 'p_fee_mod');
INSERT INTO sys_func VALUES ('协议模式维护', 1, '2014-06-17 10:38:09', NULL, NULL, '', 84, 'p_fee_mod');
INSERT INTO sys_func VALUES ('协议费用模式查询', 1, '2014-06-19 09:50:24', NULL, NULL, '', 85, 'p_protocol_fee_mod');
INSERT INTO sys_func VALUES ('协议费用模式维护', 1, '2014-06-19 09:50:24', NULL, NULL, '', 86, 'p_protocol_fee_mod');
INSERT INTO sys_func VALUES ('协议模式结构查询', 1, '2014-06-23 08:55:21', NULL, NULL, '', 87, 'p_fee_mod,p_fee_ele,p_fee_ele_lov');
INSERT INTO sys_func VALUES ('协议费率维护', 1, '2014-06-23 08:58:08', 1, '2014-06-23 00:58:50', '', 88, 'p_protocol_rat');
INSERT INTO sys_func VALUES ('协议费率查询', 1, '2014-06-23 08:59:13', 1, '2014-06-23 00:59:03', '', 89, 'p_protocol_rat');


--
-- TOC entry 2877 (class 0 OID 0)
-- Dependencies: 222
-- Name: sys_func_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('sys_func_id_seq', 49, true);


--
-- TOC entry 2878 (class 0 OID 0)
-- Dependencies: 223
-- Name: sys_func_id_seq1; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('sys_func_id_seq1', 89, true);


--
-- TOC entry 2563 (class 0 OID 27918)
-- Dependencies: 221
-- Data for Name: sys_menu; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO sys_menu VALUES (5, '权限维护', 1, '2014-02-24 09:04:26.771803', NULL, NULL, '', 4, '权限维护', 2, true);
INSERT INTO sys_menu VALUES (6, '功能权限维护', 1, '2014-02-24 09:05:06.975367', NULL, NULL, '', 4, '功能权限维护', 3, true);
INSERT INTO sys_menu VALUES (0, '根节点', 1, '2014-02-24 10:57:39.013142', NULL, NULL, '', 0, '根节点', 1, true);
INSERT INTO sys_menu VALUES (4, '系统管理', 1, '2014-02-24 08:56:51.619241', 1, '2014-02-24 08:29:12', '', 0, '系统管理', 1, true);
INSERT INTO sys_menu VALUES (7, '系统参数维护', 1, '2014-02-25 10:58:28', NULL, NULL, '', 4, '系统参数维护', 4, true);
INSERT INTO sys_menu VALUES (18, '委托维护', 1, '2014-02-25 11:19:59', NULL, NULL, '', 13, '委托维护', 1, false);
INSERT INTO sys_menu VALUES (3, '功能维护', 1, '2014-02-24 08:53:47.818424', 1, '2014-02-28 00:06:05', '', 4, '功能维护', 1, true);
INSERT INTO sys_menu VALUES (32, '委托查询', 1, '2014-03-24 15:44:35', NULL, NULL, '', 13, '委托查询', 3, false);
INSERT INTO sys_menu VALUES (19, '控货', 1, '2014-02-25 11:28:14', 1, '2014-03-24 07:44:35', '', 13, '控货', 6, false);
INSERT INTO sys_menu VALUES (20, '委托费用维护', 1, '2014-02-25 11:29:48', 1, '2014-03-24 07:44:35', '', 13, '委托费用维护', 2, false);
INSERT INTO sys_menu VALUES (31, '收款/付款', 1, '2014-03-19 09:21:20', NULL, NULL, '', 21, '收款/付款', 1, false);
INSERT INTO sys_menu VALUES (22, '核销', 1, '2014-02-25 11:39:56', 1, '2014-03-19 01:21:20', '', 21, '核销', 2, false);
INSERT INTO sys_menu VALUES (23, '取消核销', 1, '2014-02-25 11:39:56', 1, '2014-04-09 02:33:45', '', 21, '取消核销', 3, false);
INSERT INTO sys_menu VALUES (25, '核销查询', 1, '2014-02-25 15:10:24', 1, '2014-04-10 02:40:53', '', 21, '核销查询', 4, false);
INSERT INTO sys_menu VALUES (8, '基础数据管理', 1, '2014-02-25 11:00:30', 1, '2014-04-24 07:51:40', '', 0, '基础数据管理', 3, false);
INSERT INTO sys_menu VALUES (13, '进口货运', 1, '2014-02-25 11:05:42', 1, '2014-04-24 07:51:40', '', 0, '进口货运', 4, false);
INSERT INTO sys_menu VALUES (21, '商务', 1, '2014-02-25 11:30:27', 1, '2014-04-24 07:51:40', '', 0, '商务', 5, false);
INSERT INTO sys_menu VALUES (34, '密码修改', 1, '2014-04-24 15:53:50', NULL, NULL, '', 33, '密码修改', 1, false);
INSERT INTO sys_menu VALUES (39, '账单', 1, '2014-05-06 16:37:55', NULL, NULL, '', 21, '账单', 5, false);
INSERT INTO sys_menu VALUES (40, '业务明细报表', 1, '2014-05-08 15:12:17', NULL, NULL, '', 13, '业务明细报表', 4, false);
INSERT INTO sys_menu VALUES (41, '业务汇总报表', 1, '2014-05-09 13:05:49', NULL, NULL, '', 13, '业务汇总报表', 5, false);
INSERT INTO sys_menu VALUES (42, '费用报表定义', 1, '2014-05-20 15:09:45', NULL, NULL, '', 21, '费用报表定义', 6, false);
INSERT INTO sys_menu VALUES (43, '协议管理', 1, '2014-06-05 14:50:31', NULL, NULL, '', 0, '协议管理', 6, false);
INSERT INTO sys_menu VALUES (44, '协议维护', 1, '2014-06-05 14:51:19', NULL, NULL, '', 43, '协议维护', 1, false);
INSERT INTO sys_menu VALUES (15, '委托动态类型维护', 1, '2014-02-25 11:15:17', 1, '2014-06-25 06:32:29', '', 8, '委托动态类型维护', 6, false);
INSERT INTO sys_menu VALUES (29, '付款方式维护', 1, '2014-03-03 14:41:29', 1, '2014-06-27 02:56:36', '', 8, '付款方式维护', 8, false);
INSERT INTO sys_menu VALUES (30, '客户维护', 1, '2014-03-15 21:43:10', 1, '2014-06-27 02:56:36', '', 8, '客户维护', 9, false);
INSERT INTO sys_menu VALUES (33, '系统配置管理', 1, '2014-04-24 15:51:39', NULL, NULL, '', 0, '系统配置管理', 2, false);
INSERT INTO sys_menu VALUES (9, '用户维护', 1, '2014-02-25 11:03:01', 1, '2014-06-27 02:49:46', '', 33, '用户维护', 2, false);
INSERT INTO sys_menu VALUES (10, '岗位维护', 1, '2014-02-25 11:03:01', 1, '2014-06-27 02:49:46', '', 33, '岗位维护', 3, false);
INSERT INTO sys_menu VALUES (11, '岗位用户维护', 1, '2014-02-25 11:03:01', 1, '2014-06-27 02:49:46', '', 33, '岗位用户维护', 4, false);
INSERT INTO sys_menu VALUES (12, '岗位权限维护', 1, '2014-02-25 11:03:01', 1, '2014-06-27 02:49:46', '', 33, '岗位权限维护', 5, false);
INSERT INTO sys_menu VALUES (45, '协议要素维护', 1, '2014-06-13 15:47:15', 1, '2014-06-27 02:54:47', '', 4, '协议要素维护', 5, true);
INSERT INTO sys_menu VALUES (47, '协议模式定义', 1, '2014-06-17 10:37:33', 1, '2014-06-27 02:54:47', '', 4, '协议模式定义', 6, true);
INSERT INTO sys_menu VALUES (48, '协议费用模式维护', 1, '2014-06-19 09:45:41', 1, '2014-06-27 02:54:47', '', 4, '协议费用模式维护', 7, true);
INSERT INTO sys_menu VALUES (46, '协议要素内容维护', 1, '2014-06-13 17:05:36', 1, '2014-06-27 02:55:27', '', 43, '协议要素内容维护', 2, false);
INSERT INTO sys_menu VALUES (49, '协议费率维护', 1, '2014-06-19 14:02:37', 1, '2014-06-27 02:55:27', '', 43, '协议费率维护', 3, false);
INSERT INTO sys_menu VALUES (14, '箱型维护', 1, '2014-02-25 11:13:33', 1, '2014-06-27 02:56:36', '', 8, '箱型维护', 1, false);
INSERT INTO sys_menu VALUES (35, '发货地维护', 1, '2014-04-24 18:12:20', 1, '2014-06-27 02:56:36', '', 8, '发货地维护', 2, false);
INSERT INTO sys_menu VALUES (38, '产地维护', 1, '2014-05-05 18:01:46', 1, '2014-06-27 02:56:36', '', 8, '产地维护', 3, false);
INSERT INTO sys_menu VALUES (37, '货物分类维护', 1, '2014-05-05 17:48:18', 1, '2014-06-27 02:56:36', '', 8, '货物分类维护', 4, false);
INSERT INTO sys_menu VALUES (36, '货物维护', 1, '2014-05-05 17:39:26', 1, '2014-06-27 02:56:36', '', 8, '货物维护', 5, false);
INSERT INTO sys_menu VALUES (16, '费用名称维护', 1, '2014-02-25 11:18:14', 1, '2014-06-27 02:56:36', '', 8, '费用名称维护', 7, false);


--
-- TOC entry 2566 (class 0 OID 27928)
-- Dependencies: 224
-- Data for Name: sys_menu_func; Type: TABLE DATA; Schema: public; Owner: yardAdmin
--

INSERT INTO sys_menu_func VALUES (1, 3, 1, 1, '2014-02-28 09:15:46.284318', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (2, 3, 2, 1, '2014-03-01 07:32:45', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (10, 5, 3, 1, '2014-03-01 09:29:38', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (11, 5, 2, 1, '2014-03-01 09:29:38', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (12, 6, 7, 1, '2014-03-01 09:29:47', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (13, 6, 8, 1, '2014-03-01 09:29:47', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (14, 7, 9, 1, '2014-03-01 09:29:59', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (15, 7, 10, 1, '2014-03-01 09:29:59', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (16, 9, 16, 1, '2014-03-01 09:31:12', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (17, 9, 17, 1, '2014-03-01 09:31:12', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (18, 10, 12, 1, '2014-03-01 09:31:26', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (19, 10, 13, 1, '2014-03-01 09:31:26', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (20, 11, 14, 1, '2014-03-01 09:47:24', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (21, 11, 15, 1, '2014-03-01 09:47:31', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (22, 11, 12, 1, '2014-03-01 09:48:46', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (23, 12, 12, 1, '2014-03-01 09:48:54', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (24, 14, 18, 1, '2014-03-03 16:07:36', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (25, 14, 19, 1, '2014-03-03 16:07:36', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (28, 15, 22, 1, '2014-03-03 16:22:00', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (29, 15, 23, 1, '2014-03-03 16:22:00', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (30, 16, 24, 1, '2014-03-03 16:40:03', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (31, 16, 25, 1, '2014-03-03 16:40:03', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (32, 30, 26, 1, '2014-03-15 21:44:15', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (33, 30, 27, 1, '2014-03-15 21:44:15', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (36, 29, 30, 1, '2014-03-26 10:36:25', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (37, 29, 31, 1, '2014-03-26 10:36:25', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (38, 12, 32, 1, '2014-03-26 10:36:46', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (39, 12, 33, 1, '2014-03-26 10:36:46', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (40, 18, 34, 1, '2014-03-26 10:46:52', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (41, 18, 35, 1, '2014-03-26 10:46:52', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (42, 18, 36, 1, '2014-03-26 10:46:52', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (43, 18, 37, 1, '2014-03-26 10:46:52', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (44, 18, 38, 1, '2014-03-26 10:46:52', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (45, 18, 39, 1, '2014-03-26 12:49:44', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (46, 18, 40, 1, '2014-03-26 12:49:44', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (47, 20, 37, 1, '2014-03-28 10:17:29', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (48, 20, 41, 1, '2014-03-29 11:31:48', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (49, 20, 42, 1, '2014-03-29 11:31:48', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (50, 20, 43, 1, '2014-03-29 11:31:48', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (51, 20, 44, 1, '2014-03-31 14:04:27', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (52, 20, 45, 1, '2014-03-31 14:04:28', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (53, 22, 46, 1, '2014-04-09 10:30:52', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (54, 22, 47, 1, '2014-04-09 10:30:52', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (55, 22, 48, 1, '2014-04-09 10:30:52', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (56, 32, 34, 1, '2014-04-16 11:00:38', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (57, 32, 35, 1, '2014-04-16 11:01:55', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (58, 32, 36, 1, '2014-04-16 11:01:55', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (59, 32, 41, 1, '2014-04-16 11:01:55', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (60, 32, 42, 1, '2014-04-16 11:01:55', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (61, 31, 49, 1, '2014-04-16 12:42:22', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (62, 31, 50, 1, '2014-04-16 12:42:22', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (63, 23, 51, 1, '2014-04-16 12:45:58', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (64, 23, 52, 1, '2014-04-16 12:45:58', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (65, 25, 53, 1, '2014-04-16 12:47:05', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (66, 25, 54, 1, '2014-04-16 12:47:05', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (67, 34, 55, 1, '2014-04-24 15:54:32', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (68, 35, 56, 1, '2014-04-24 18:13:22', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (69, 35, 57, 1, '2014-04-24 18:13:22', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (70, 36, 58, 1, '2014-05-05 18:02:25', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (71, 36, 59, 1, '2014-05-05 18:02:25', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (72, 37, 60, 1, '2014-05-05 18:02:37', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (73, 37, 61, 1, '2014-05-05 18:02:37', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (74, 38, 62, 1, '2014-05-05 18:02:49', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (75, 38, 63, 1, '2014-05-05 18:02:49', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (76, 39, 64, 1, '2014-05-06 16:38:41', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (77, 40, 65, 1, '2014-05-08 15:13:37', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (78, 41, 66, 1, '2014-05-16 14:41:44', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (80, 42, 68, 1, '2014-05-20 15:21:41', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (81, 42, 69, 1, '2014-05-20 15:21:41', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (82, 42, 70, 1, '2014-05-20 15:21:41', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (83, 42, 73, 1, '2014-05-28 11:03:29', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (84, 42, 72, 1, '2014-05-28 11:03:29', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (85, 42, 74, 1, '2014-05-29 08:14:18', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (86, 44, 76, 1, '2014-06-05 14:52:56', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (87, 44, 77, 1, '2014-06-05 14:52:56', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (88, 45, 78, 1, '2014-06-13 15:48:35', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (89, 45, 79, 1, '2014-06-13 15:48:35', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (90, 46, 80, 1, '2014-06-13 17:08:50', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (91, 46, 81, 1, '2014-06-13 17:08:50', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (92, 46, 82, 1, '2014-06-13 17:08:50', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (93, 47, 76, 1, '2014-06-18 10:26:04', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (94, 47, 24, 1, '2014-06-18 10:26:04', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (95, 47, 83, 1, '2014-06-18 10:26:30', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (96, 47, 84, 1, '2014-06-19 09:47:04', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (97, 48, 76, 1, '2014-06-19 09:47:53', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (98, 48, 24, 1, '2014-06-19 09:47:53', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (100, 48, 85, 1, '2014-06-19 09:50:44', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (101, 48, 86, 1, '2014-06-19 09:50:44', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (102, 49, 76, 1, '2014-06-19 14:03:12', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (103, 49, 85, 1, '2014-06-20 08:59:27', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (104, 49, 87, 1, '2014-06-23 08:55:35', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (105, 49, 88, 1, '2014-06-23 08:58:36', NULL, NULL, '');
INSERT INTO sys_menu_func VALUES (106, 49, 89, 1, '2014-06-23 08:59:40', NULL, NULL, '');


--
-- TOC entry 2879 (class 0 OID 0)
-- Dependencies: 225
-- Name: sys_menu_func_id_seq; Type: SEQUENCE SET; Schema: public; Owner: yardAdmin
--

SELECT pg_catalog.setval('sys_menu_func_id_seq', 106, true);


--
-- TOC entry 2264 (class 2606 OID 27968)
-- Name: auth_group_name_key; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);


--
-- TOC entry 2270 (class 2606 OID 27970)
-- Name: auth_group_permissions_group_id_permission_id_key; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_key UNIQUE (group_id, permission_id);


--
-- TOC entry 2273 (class 2606 OID 27972)
-- Name: auth_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 2267 (class 2606 OID 27974)
-- Name: auth_group_pkey; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);


--
-- TOC entry 2276 (class 2606 OID 27976)
-- Name: auth_permission_content_type_id_codename_key; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_key UNIQUE (content_type_id, codename);


--
-- TOC entry 2278 (class 2606 OID 27978)
-- Name: auth_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);


--
-- TOC entry 2286 (class 2606 OID 27980)
-- Name: auth_user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_user_groups
    ADD CONSTRAINT auth_user_groups_pkey PRIMARY KEY (id);


--
-- TOC entry 2289 (class 2606 OID 27982)
-- Name: auth_user_groups_user_id_group_id_key; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_user_groups
    ADD CONSTRAINT auth_user_groups_user_id_group_id_key UNIQUE (user_id, group_id);


--
-- TOC entry 2280 (class 2606 OID 27984)
-- Name: auth_user_pkey; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_user
    ADD CONSTRAINT auth_user_pkey PRIMARY KEY (id);


--
-- TOC entry 2292 (class 2606 OID 27986)
-- Name: auth_user_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 2295 (class 2606 OID 27988)
-- Name: auth_user_user_permissions_user_id_permission_id_key; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_user_id_permission_id_key UNIQUE (user_id, permission_id);


--
-- TOC entry 2282 (class 2606 OID 27990)
-- Name: auth_user_username_key; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY auth_user
    ADD CONSTRAINT auth_user_username_key UNIQUE (username);


--
-- TOC entry 2347 (class 2606 OID 27992)
-- Name: django_admin_log_pkey; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);


--
-- TOC entry 2350 (class 2606 OID 27994)
-- Name: django_content_type_app_label_model_key; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_key UNIQUE (app_label, model);


--
-- TOC entry 2352 (class 2606 OID 27996)
-- Name: django_content_type_pkey; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);


--
-- TOC entry 2355 (class 2606 OID 27998)
-- Name: django_session_pkey; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);


--
-- TOC entry 2262 (class 2606 OID 28000)
-- Name: pk_act_fee; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY act_fee
    ADD CONSTRAINT pk_act_fee PRIMARY KEY (id);


--
-- TOC entry 2297 (class 2606 OID 28002)
-- Name: pk_c_cargo; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_cargo
    ADD CONSTRAINT pk_c_cargo PRIMARY KEY (id);


--
-- TOC entry 2301 (class 2606 OID 28004)
-- Name: pk_c_cargo_type; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_cargo_type
    ADD CONSTRAINT pk_c_cargo_type PRIMARY KEY (id);


--
-- TOC entry 2305 (class 2606 OID 28006)
-- Name: pk_c_client; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_client
    ADD CONSTRAINT pk_c_client PRIMARY KEY (id);


--
-- TOC entry 2309 (class 2606 OID 28008)
-- Name: pk_c_cntr_type; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_cntr_type
    ADD CONSTRAINT pk_c_cntr_type PRIMARY KEY (id);


--
-- TOC entry 2313 (class 2606 OID 28010)
-- Name: pk_c_contract_action; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_contract_action
    ADD CONSTRAINT pk_c_contract_action PRIMARY KEY (id);


--
-- TOC entry 2319 (class 2606 OID 28012)
-- Name: pk_c_dispatch; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_dispatch
    ADD CONSTRAINT pk_c_dispatch PRIMARY KEY (id);


--
-- TOC entry 2323 (class 2606 OID 28014)
-- Name: pk_c_fee; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_fee
    ADD CONSTRAINT pk_c_fee PRIMARY KEY (id);


--
-- TOC entry 2327 (class 2606 OID 28020)
-- Name: pk_c_pay_type; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_pay_type
    ADD CONSTRAINT pk_c_pay_type PRIMARY KEY (id);


--
-- TOC entry 2331 (class 2606 OID 28022)
-- Name: pk_c_place; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_place
    ADD CONSTRAINT pk_c_place PRIMARY KEY (id);


--
-- TOC entry 2401 (class 2606 OID 28414)
-- Name: pk_c_rpt; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_rpt
    ADD CONSTRAINT pk_c_rpt PRIMARY KEY (id);


--
-- TOC entry 2407 (class 2606 OID 28437)
-- Name: pk_c_rpt_fee; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_rpt_fee
    ADD CONSTRAINT pk_c_rpt_fee PRIMARY KEY (id);


--
-- TOC entry 2405 (class 2606 OID 28424)
-- Name: pk_c_rpt_item; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_rpt_item
    ADD CONSTRAINT pk_c_rpt_item PRIMARY KEY (id);


--
-- TOC entry 2336 (class 2606 OID 28024)
-- Name: pk_contract; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT pk_contract PRIMARY KEY (id);


--
-- TOC entry 2340 (class 2606 OID 28026)
-- Name: pk_contract_action; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY contract_action
    ADD CONSTRAINT pk_contract_action PRIMARY KEY (id);


--
-- TOC entry 2344 (class 2606 OID 28028)
-- Name: pk_contract_cntr; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY contract_cntr
    ADD CONSTRAINT pk_contract_cntr PRIMARY KEY (id);


--
-- TOC entry 2415 (class 2606 OID 28480)
-- Name: pk_p_fee_ele; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_fee_ele
    ADD CONSTRAINT pk_p_fee_ele PRIMARY KEY (id);


--
-- TOC entry 2419 (class 2606 OID 28490)
-- Name: pk_p_fee_ele_lov; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_fee_ele_lov
    ADD CONSTRAINT pk_p_fee_ele_lov PRIMARY KEY (id);


--
-- TOC entry 2423 (class 2606 OID 28515)
-- Name: pk_p_fee_mod; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT pk_p_fee_mod PRIMARY KEY (id);


--
-- TOC entry 2411 (class 2606 OID 28469)
-- Name: pk_p_protocol; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_protocol
    ADD CONSTRAINT pk_p_protocol PRIMARY KEY (id);


--
-- TOC entry 2427 (class 2606 OID 28588)
-- Name: pk_p_protocol_fee_mod; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_protocol_fee_mod
    ADD CONSTRAINT pk_p_protocol_fee_mod PRIMARY KEY (id, protocol_id);


--
-- TOC entry 2431 (class 2606 OID 28619)
-- Name: pk_p_protocol_rat; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_protocol_rat
    ADD CONSTRAINT pk_p_protocol_rat PRIMARY KEY (id);


--
-- TOC entry 2358 (class 2606 OID 28030)
-- Name: pk_pre_fee; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY pre_fee
    ADD CONSTRAINT pk_pre_fee PRIMARY KEY (id);


--
-- TOC entry 2397 (class 2606 OID 28367)
-- Name: pk_s_filter; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_filter_head
    ADD CONSTRAINT pk_s_filter PRIMARY KEY (id);


--
-- TOC entry 2399 (class 2606 OID 28390)
-- Name: pk_s_filter_body; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_filter_body
    ADD CONSTRAINT pk_s_filter_body PRIMARY KEY (id);


--
-- TOC entry 2360 (class 2606 OID 28032)
-- Name: pk_s_post; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_post
    ADD CONSTRAINT pk_s_post PRIMARY KEY (id);


--
-- TOC entry 2364 (class 2606 OID 28034)
-- Name: pk_s_postmenu; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_postmenu
    ADD CONSTRAINT pk_s_postmenu PRIMARY KEY (id);


--
-- TOC entry 2368 (class 2606 OID 28036)
-- Name: pk_s_postmenufunc; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_postmenufunc
    ADD CONSTRAINT pk_s_postmenufunc PRIMARY KEY (id);


--
-- TOC entry 2372 (class 2606 OID 28038)
-- Name: pk_s_postuser; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_postuser
    ADD CONSTRAINT pk_s_postuser PRIMARY KEY (id);


--
-- TOC entry 2376 (class 2606 OID 28040)
-- Name: pk_s_user; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_user
    ADD CONSTRAINT pk_s_user PRIMARY KEY (id);


--
-- TOC entry 2380 (class 2606 OID 28042)
-- Name: pk_sys_code; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY sys_code
    ADD CONSTRAINT pk_sys_code PRIMARY KEY (id);


--
-- TOC entry 2384 (class 2606 OID 28044)
-- Name: pk_sys_func; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY sys_func
    ADD CONSTRAINT pk_sys_func PRIMARY KEY (id);


--
-- TOC entry 2388 (class 2606 OID 28046)
-- Name: pk_sys_menu; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY sys_menu
    ADD CONSTRAINT pk_sys_menu PRIMARY KEY (id);


--
-- TOC entry 2392 (class 2606 OID 28048)
-- Name: pk_sys_menu_func; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY sys_menu_func
    ADD CONSTRAINT pk_sys_menu_func PRIMARY KEY (id);


--
-- TOC entry 2299 (class 2606 OID 28050)
-- Name: uk_c_cargo; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_cargo
    ADD CONSTRAINT uk_c_cargo UNIQUE (cargo_name);


--
-- TOC entry 2303 (class 2606 OID 28052)
-- Name: uk_c_cargo_type; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_cargo_type
    ADD CONSTRAINT uk_c_cargo_type UNIQUE (type_name);


--
-- TOC entry 2307 (class 2606 OID 28054)
-- Name: uk_c_client; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_client
    ADD CONSTRAINT uk_c_client UNIQUE (client_name);


--
-- TOC entry 2311 (class 2606 OID 28056)
-- Name: uk_c_cntr_type; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_cntr_type
    ADD CONSTRAINT uk_c_cntr_type UNIQUE (cntr_type);


--
-- TOC entry 2315 (class 2606 OID 28058)
-- Name: uk_c_contract_action; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_contract_action
    ADD CONSTRAINT uk_c_contract_action UNIQUE (action_name);


--
-- TOC entry 2317 (class 2606 OID 28060)
-- Name: uk_c_contract_action_sort; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_contract_action
    ADD CONSTRAINT uk_c_contract_action_sort UNIQUE (sortno);


--
-- TOC entry 2325 (class 2606 OID 28062)
-- Name: uk_c_fee; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_fee
    ADD CONSTRAINT uk_c_fee UNIQUE (fee_name);


--
-- TOC entry 2329 (class 2606 OID 28068)
-- Name: uk_c_pay_type; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_pay_type
    ADD CONSTRAINT uk_c_pay_type UNIQUE (pay_name);


--
-- TOC entry 2333 (class 2606 OID 28070)
-- Name: uk_c_place; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_place
    ADD CONSTRAINT uk_c_place UNIQUE (place_name);


--
-- TOC entry 2403 (class 2606 OID 28416)
-- Name: uk_c_rpt; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_rpt
    ADD CONSTRAINT uk_c_rpt UNIQUE (rpt_name);


--
-- TOC entry 2409 (class 2606 OID 28439)
-- Name: uk_c_rpt_fee; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_rpt_fee
    ADD CONSTRAINT uk_c_rpt_fee UNIQUE (rpt_id, item_id, fee_id);


--
-- TOC entry 2338 (class 2606 OID 28072)
-- Name: uk_contract; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT uk_contract UNIQUE (bill_no);


--
-- TOC entry 2342 (class 2606 OID 28074)
-- Name: uk_contract_action; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY contract_action
    ADD CONSTRAINT uk_contract_action UNIQUE (contract_id, action_id);


--
-- TOC entry 2321 (class 2606 OID 28076)
-- Name: uk_dispatch; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY c_dispatch
    ADD CONSTRAINT uk_dispatch UNIQUE (place_name);


--
-- TOC entry 2417 (class 2606 OID 28482)
-- Name: uk_p_fee_ele; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_fee_ele
    ADD CONSTRAINT uk_p_fee_ele UNIQUE (ele_name);


--
-- TOC entry 2421 (class 2606 OID 28492)
-- Name: uk_p_fee_ele_lov; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_fee_ele_lov
    ADD CONSTRAINT uk_p_fee_ele_lov UNIQUE (ele_id, lov_cod);


--
-- TOC entry 2425 (class 2606 OID 28517)
-- Name: uk_p_fee_mod; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT uk_p_fee_mod UNIQUE (mod_name);


--
-- TOC entry 2413 (class 2606 OID 28471)
-- Name: uk_p_protocol; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_protocol
    ADD CONSTRAINT uk_p_protocol UNIQUE (protocol_name);


--
-- TOC entry 2429 (class 2606 OID 28590)
-- Name: uk_p_protocol_fee_mod; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY p_protocol_fee_mod
    ADD CONSTRAINT uk_p_protocol_fee_mod UNIQUE (protocol_id, fee_id, mod_id);


--
-- TOC entry 2362 (class 2606 OID 28078)
-- Name: uk_s_post; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_post
    ADD CONSTRAINT uk_s_post UNIQUE (postname);


--
-- TOC entry 2366 (class 2606 OID 28080)
-- Name: uk_s_postmenu; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_postmenu
    ADD CONSTRAINT uk_s_postmenu UNIQUE (post_id, menu_id);


--
-- TOC entry 2370 (class 2606 OID 28082)
-- Name: uk_s_postmenufunc; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_postmenufunc
    ADD CONSTRAINT uk_s_postmenufunc UNIQUE (post_id, menu_id, func_id);


--
-- TOC entry 2374 (class 2606 OID 28084)
-- Name: uk_s_postuser; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_postuser
    ADD CONSTRAINT uk_s_postuser UNIQUE (post_id, user_id);


--
-- TOC entry 2378 (class 2606 OID 28086)
-- Name: uk_s_user; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY s_user
    ADD CONSTRAINT uk_s_user UNIQUE (username);


--
-- TOC entry 2382 (class 2606 OID 28088)
-- Name: uk_sys_code; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY sys_code
    ADD CONSTRAINT uk_sys_code UNIQUE (fld_eng, cod_name);


--
-- TOC entry 2386 (class 2606 OID 28090)
-- Name: uk_sys_func_func; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY sys_func
    ADD CONSTRAINT uk_sys_func_func UNIQUE (funcname);


--
-- TOC entry 2394 (class 2606 OID 28092)
-- Name: uk_sys_menu_func; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY sys_menu_func
    ADD CONSTRAINT uk_sys_menu_func UNIQUE (menu_id, func_id);


--
-- TOC entry 2390 (class 2606 OID 28094)
-- Name: uk_sys_menu_menu; Type: CONSTRAINT; Schema: public; Owner: yardAdmin; Tablespace: 
--

ALTER TABLE ONLY sys_menu
    ADD CONSTRAINT uk_sys_menu_menu UNIQUE (menuname);


--
-- TOC entry 2265 (class 1259 OID 28095)
-- Name: auth_group_name_like; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX auth_group_name_like ON auth_group USING btree (name varchar_pattern_ops);


--
-- TOC entry 2268 (class 1259 OID 28096)
-- Name: auth_group_permissions_group_id; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX auth_group_permissions_group_id ON auth_group_permissions USING btree (group_id);


--
-- TOC entry 2271 (class 1259 OID 28097)
-- Name: auth_group_permissions_permission_id; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX auth_group_permissions_permission_id ON auth_group_permissions USING btree (permission_id);


--
-- TOC entry 2274 (class 1259 OID 28098)
-- Name: auth_permission_content_type_id; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX auth_permission_content_type_id ON auth_permission USING btree (content_type_id);


--
-- TOC entry 2284 (class 1259 OID 28099)
-- Name: auth_user_groups_group_id; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX auth_user_groups_group_id ON auth_user_groups USING btree (group_id);


--
-- TOC entry 2287 (class 1259 OID 28100)
-- Name: auth_user_groups_user_id; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX auth_user_groups_user_id ON auth_user_groups USING btree (user_id);


--
-- TOC entry 2290 (class 1259 OID 28101)
-- Name: auth_user_user_permissions_permission_id; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX auth_user_user_permissions_permission_id ON auth_user_user_permissions USING btree (permission_id);


--
-- TOC entry 2293 (class 1259 OID 28102)
-- Name: auth_user_user_permissions_user_id; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX auth_user_user_permissions_user_id ON auth_user_user_permissions USING btree (user_id);


--
-- TOC entry 2283 (class 1259 OID 28103)
-- Name: auth_user_username_like; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX auth_user_username_like ON auth_user USING btree (username varchar_pattern_ops);


--
-- TOC entry 2345 (class 1259 OID 28104)
-- Name: django_admin_log_content_type_id; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX django_admin_log_content_type_id ON django_admin_log USING btree (content_type_id);


--
-- TOC entry 2348 (class 1259 OID 28105)
-- Name: django_admin_log_user_id; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX django_admin_log_user_id ON django_admin_log USING btree (user_id);


--
-- TOC entry 2353 (class 1259 OID 28106)
-- Name: django_session_expire_date; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX django_session_expire_date ON django_session USING btree (expire_date);


--
-- TOC entry 2356 (class 1259 OID 28107)
-- Name: django_session_session_key_like; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX django_session_session_key_like ON django_session USING btree (session_key varchar_pattern_ops);


--
-- TOC entry 2334 (class 1259 OID 28108)
-- Name: fki_contract_custom; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX fki_contract_custom ON contract USING btree (custom_id);


--
-- TOC entry 2257 (class 1259 OID 28109)
-- Name: idx_act_fee_audit; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX idx_act_fee_audit ON act_fee USING btree (audit_id);


--
-- TOC entry 2258 (class 1259 OID 28110)
-- Name: idx_act_fee_audit_tim; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX idx_act_fee_audit_tim ON act_fee USING btree (audit_tim);


--
-- TOC entry 2259 (class 1259 OID 28111)
-- Name: idx_act_fee_ex_from; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX idx_act_fee_ex_from ON act_fee USING btree (ex_from);


--
-- TOC entry 2260 (class 1259 OID 28112)
-- Name: idx_act_fee_ex_over; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX idx_act_fee_ex_over ON act_fee USING btree (ex_over);


--
-- TOC entry 2395 (class 1259 OID 28368)
-- Name: idx_s_filter; Type: INDEX; Schema: public; Owner: yardAdmin; Tablespace: 
--

CREATE INDEX idx_s_filter ON s_filter_head USING btree (datagrid);


--
-- TOC entry 2496 (class 2620 OID 28113)
-- Name: tri_c_fee; Type: TRIGGER; Schema: public; Owner: yardAdmin
--

CREATE TRIGGER tri_c_fee BEFORE DELETE OR UPDATE ON c_fee FOR EACH ROW EXECUTE PROCEDURE fun4tri_c_fee();


--
-- TOC entry 2497 (class 2620 OID 28114)
-- Name: tri_contract; Type: TRIGGER; Schema: public; Owner: yardAdmin
--

CREATE TRIGGER tri_contract BEFORE UPDATE ON contract FOR EACH ROW EXECUTE PROCEDURE fun4tri_contract();


--
-- TOC entry 2498 (class 2620 OID 28115)
-- Name: tri_contract_action; Type: TRIGGER; Schema: public; Owner: yardAdmin
--

CREATE TRIGGER tri_contract_action BEFORE DELETE OR UPDATE ON contract_action FOR EACH ROW EXECUTE PROCEDURE fun4tri_contract_action();


--
-- TOC entry 2499 (class 2620 OID 28116)
-- Name: tri_contract_cntr; Type: TRIGGER; Schema: public; Owner: yardAdmin
--

CREATE TRIGGER tri_contract_cntr BEFORE DELETE OR UPDATE ON contract_cntr FOR EACH ROW EXECUTE PROCEDURE fun4tri_contract_action();


--
-- TOC entry 2500 (class 2620 OID 28117)
-- Name: tri_s_postmenu; Type: TRIGGER; Schema: public; Owner: yardAdmin
--

CREATE TRIGGER tri_s_postmenu BEFORE INSERT ON s_postmenu FOR EACH ROW EXECUTE PROCEDURE fun4tri_s_postmenufunc();


--
-- TOC entry 2501 (class 2620 OID 28118)
-- Name: tri_s_postmenufunc; Type: TRIGGER; Schema: public; Owner: yardAdmin
--

CREATE TRIGGER tri_s_postmenufunc BEFORE INSERT ON s_postmenufunc FOR EACH ROW EXECUTE PROCEDURE fun4tri_s_postmenufunc();


--
-- TOC entry 2502 (class 2620 OID 28119)
-- Name: tri_s_user; Type: TRIGGER; Schema: public; Owner: yardAdmin
--

CREATE TRIGGER tri_s_user BEFORE INSERT OR DELETE OR UPDATE ON s_user FOR EACH ROW EXECUTE PROCEDURE fun4tri_s_user();


--
-- TOC entry 2434 (class 2606 OID 28120)
-- Name: auth_group_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 2437 (class 2606 OID 28125)
-- Name: auth_user_groups_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_user_groups
    ADD CONSTRAINT auth_user_groups_group_id_fkey FOREIGN KEY (group_id) REFERENCES auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 2439 (class 2606 OID 28130)
-- Name: auth_user_user_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_user_user_permissions
    ADD CONSTRAINT auth_user_user_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES auth_permission(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 2459 (class 2606 OID 28135)
-- Name: content_type_id_refs_id_93d2d1f8; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY django_admin_log
    ADD CONSTRAINT content_type_id_refs_id_93d2d1f8 FOREIGN KEY (content_type_id) REFERENCES django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 2436 (class 2606 OID 28140)
-- Name: content_type_id_refs_id_d043b34a; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_permission
    ADD CONSTRAINT content_type_id_refs_id_d043b34a FOREIGN KEY (content_type_id) REFERENCES django_content_type(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 2432 (class 2606 OID 28145)
-- Name: fk_act_fee_client; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY act_fee
    ADD CONSTRAINT fk_act_fee_client FOREIGN KEY (client_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2433 (class 2606 OID 28150)
-- Name: fk_act_fee_pay; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY act_fee
    ADD CONSTRAINT fk_act_fee_pay FOREIGN KEY (pay_type) REFERENCES c_pay_type(id) ON DELETE RESTRICT;


--
-- TOC entry 2441 (class 2606 OID 28708)
-- Name: fk_c_client_protocol; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_client
    ADD CONSTRAINT fk_c_client_protocol FOREIGN KEY (protocol_id) REFERENCES p_protocol(id) ON DELETE RESTRICT;


--
-- TOC entry 2477 (class 2606 OID 28445)
-- Name: fk_c_rpt_fee_item; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_rpt_fee
    ADD CONSTRAINT fk_c_rpt_fee_item FOREIGN KEY (item_id) REFERENCES c_rpt_item(id) ON DELETE CASCADE;


--
-- TOC entry 2476 (class 2606 OID 28440)
-- Name: fk_c_rpt_fee_rpt; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_rpt_fee
    ADD CONSTRAINT fk_c_rpt_fee_rpt FOREIGN KEY (rpt_id) REFERENCES c_rpt(id) ON DELETE CASCADE;


--
-- TOC entry 2455 (class 2606 OID 28160)
-- Name: fk_contract-action_contract; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract_action
    ADD CONSTRAINT "fk_contract-action_contract" FOREIGN KEY (contract_id) REFERENCES contract(id) ON DELETE CASCADE;


--
-- TOC entry 2456 (class 2606 OID 28165)
-- Name: fk_contract_action_action; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract_action
    ADD CONSTRAINT fk_contract_action_action FOREIGN KEY (action_id) REFERENCES c_contract_action(id) ON DELETE RESTRICT;


--
-- TOC entry 2442 (class 2606 OID 28170)
-- Name: fk_contract_cargoname; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_cargoname FOREIGN KEY (cargo_name) REFERENCES c_cargo(id) ON DELETE RESTRICT;


--
-- TOC entry 2443 (class 2606 OID 28175)
-- Name: fk_contract_cargotype; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_cargotype FOREIGN KEY (cargo_type) REFERENCES c_cargo_type(id) ON DELETE RESTRICT;


--
-- TOC entry 2444 (class 2606 OID 28180)
-- Name: fk_contract_checkyard; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_checkyard FOREIGN KEY (check_yard_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2445 (class 2606 OID 28185)
-- Name: fk_contract_client; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_client FOREIGN KEY (client_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2457 (class 2606 OID 28190)
-- Name: fk_contract_cntr_contract; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract_cntr
    ADD CONSTRAINT fk_contract_cntr_contract FOREIGN KEY (contract_id) REFERENCES contract(id) ON DELETE CASCADE;


--
-- TOC entry 2458 (class 2606 OID 28195)
-- Name: fk_contract_cntr_type; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract_cntr
    ADD CONSTRAINT fk_contract_cntr_type FOREIGN KEY (cntr_type) REFERENCES c_cntr_type(id) ON DELETE RESTRICT;


--
-- TOC entry 2446 (class 2606 OID 28200)
-- Name: fk_contract_credit; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_credit FOREIGN KEY (credit_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2447 (class 2606 OID 28205)
-- Name: fk_contract_custom; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_custom FOREIGN KEY (custom_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2448 (class 2606 OID 28210)
-- Name: fk_contract_dispatch; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_dispatch FOREIGN KEY (dispatch_place) REFERENCES c_dispatch(id) ON DELETE RESTRICT;


--
-- TOC entry 2449 (class 2606 OID 28215)
-- Name: fk_contract_landtrans; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_landtrans FOREIGN KEY (landtrans_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2450 (class 2606 OID 28220)
-- Name: fk_contract_originplace; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_originplace FOREIGN KEY (origin_place) REFERENCES c_place(id) ON DELETE RESTRICT;


--
-- TOC entry 2451 (class 2606 OID 28225)
-- Name: fk_contract_port; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_port FOREIGN KEY (port_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2452 (class 2606 OID 28230)
-- Name: fk_contract_ship_corp; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_ship_corp FOREIGN KEY (ship_corp_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2453 (class 2606 OID 28235)
-- Name: fk_contract_unboxyard; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_unboxyard FOREIGN KEY (unbox_yard_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2454 (class 2606 OID 28240)
-- Name: fk_contract_yard; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT fk_contract_yard FOREIGN KEY (yard_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2474 (class 2606 OID 28391)
-- Name: fk_filter_id; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_filter_body
    ADD CONSTRAINT fk_filter_id FOREIGN KEY (filter_id) REFERENCES s_filter_head(id) ON DELETE CASCADE;


--
-- TOC entry 2479 (class 2606 OID 28493)
-- Name: fk_p_fee_ele_lov; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_ele_lov
    ADD CONSTRAINT fk_p_fee_ele_lov FOREIGN KEY (ele_id) REFERENCES p_fee_ele(id) ON DELETE CASCADE;


--
-- TOC entry 2480 (class 2606 OID 28518)
-- Name: fk_p_fee_mod_1; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT fk_p_fee_mod_1 FOREIGN KEY (col_1) REFERENCES p_fee_ele(id) ON DELETE RESTRICT;


--
-- TOC entry 2489 (class 2606 OID 28563)
-- Name: fk_p_fee_mod_10; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT fk_p_fee_mod_10 FOREIGN KEY (col_10) REFERENCES p_fee_ele(id) ON DELETE RESTRICT;


--
-- TOC entry 2481 (class 2606 OID 28523)
-- Name: fk_p_fee_mod_2; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT fk_p_fee_mod_2 FOREIGN KEY (col_2) REFERENCES p_fee_ele(id) ON DELETE RESTRICT;


--
-- TOC entry 2482 (class 2606 OID 28528)
-- Name: fk_p_fee_mod_3; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT fk_p_fee_mod_3 FOREIGN KEY (col_3) REFERENCES p_fee_ele(id) ON DELETE RESTRICT;


--
-- TOC entry 2483 (class 2606 OID 28533)
-- Name: fk_p_fee_mod_4; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT fk_p_fee_mod_4 FOREIGN KEY (col_4) REFERENCES p_fee_ele(id) ON DELETE RESTRICT;


--
-- TOC entry 2484 (class 2606 OID 28538)
-- Name: fk_p_fee_mod_5; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT fk_p_fee_mod_5 FOREIGN KEY (col_5) REFERENCES p_fee_ele(id) ON DELETE RESTRICT;


--
-- TOC entry 2485 (class 2606 OID 28543)
-- Name: fk_p_fee_mod_6; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT fk_p_fee_mod_6 FOREIGN KEY (col_6) REFERENCES p_fee_ele(id) ON DELETE RESTRICT;


--
-- TOC entry 2486 (class 2606 OID 28548)
-- Name: fk_p_fee_mod_7; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT fk_p_fee_mod_7 FOREIGN KEY (col_7) REFERENCES p_fee_ele(id) ON DELETE RESTRICT;


--
-- TOC entry 2487 (class 2606 OID 28553)
-- Name: fk_p_fee_mod_8; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT fk_p_fee_mod_8 FOREIGN KEY (col_8) REFERENCES p_fee_ele(id) ON DELETE RESTRICT;


--
-- TOC entry 2488 (class 2606 OID 28558)
-- Name: fk_p_fee_mod_9; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_fee_mod
    ADD CONSTRAINT fk_p_fee_mod_9 FOREIGN KEY (col_9) REFERENCES p_fee_ele(id) ON DELETE RESTRICT;


--
-- TOC entry 2491 (class 2606 OID 28596)
-- Name: fk_p_protocol_fee_mod_f; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_protocol_fee_mod
    ADD CONSTRAINT fk_p_protocol_fee_mod_f FOREIGN KEY (fee_id) REFERENCES c_fee(id) ON DELETE CASCADE;


--
-- TOC entry 2492 (class 2606 OID 28601)
-- Name: fk_p_protocol_fee_mod_m; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_protocol_fee_mod
    ADD CONSTRAINT fk_p_protocol_fee_mod_m FOREIGN KEY (mod_id) REFERENCES p_fee_mod(id) ON DELETE CASCADE;


--
-- TOC entry 2490 (class 2606 OID 28591)
-- Name: fk_p_protocol_fee_mod_p; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_protocol_fee_mod
    ADD CONSTRAINT fk_p_protocol_fee_mod_p FOREIGN KEY (protocol_id) REFERENCES p_protocol(id) ON DELETE CASCADE;


--
-- TOC entry 2494 (class 2606 OID 28625)
-- Name: fk_p_protocol_rat_fee; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_protocol_rat
    ADD CONSTRAINT fk_p_protocol_rat_fee FOREIGN KEY (fee_id) REFERENCES c_fee(id) ON DELETE CASCADE;


--
-- TOC entry 2495 (class 2606 OID 28630)
-- Name: fk_p_protocol_rat_mod; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_protocol_rat
    ADD CONSTRAINT fk_p_protocol_rat_mod FOREIGN KEY (mod_id) REFERENCES p_fee_mod(id) ON DELETE CASCADE;


--
-- TOC entry 2493 (class 2606 OID 28620)
-- Name: fk_p_protocol_rat_protocol; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY p_protocol_rat
    ADD CONSTRAINT fk_p_protocol_rat_protocol FOREIGN KEY (protocol_id) REFERENCES p_protocol(id) ON DELETE CASCADE;


--
-- TOC entry 2461 (class 2606 OID 28265)
-- Name: fk_pre_fee_client; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY pre_fee
    ADD CONSTRAINT fk_pre_fee_client FOREIGN KEY (client_id) REFERENCES c_client(id) ON DELETE RESTRICT;


--
-- TOC entry 2462 (class 2606 OID 28270)
-- Name: fk_pre_fee_cod; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY pre_fee
    ADD CONSTRAINT fk_pre_fee_cod FOREIGN KEY (fee_cod) REFERENCES c_fee(id) ON DELETE RESTRICT;


--
-- TOC entry 2463 (class 2606 OID 28275)
-- Name: fk_pre_fee_contract; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY pre_fee
    ADD CONSTRAINT fk_pre_fee_contract FOREIGN KEY (contract_id) REFERENCES contract(id) ON DELETE RESTRICT;


--
-- TOC entry 2478 (class 2606 OID 28450)
-- Name: fk_rpt_fee_fee; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_rpt_fee
    ADD CONSTRAINT fk_rpt_fee_fee FOREIGN KEY (fee_id) REFERENCES c_fee(id) ON DELETE CASCADE;


--
-- TOC entry 2475 (class 2606 OID 28425)
-- Name: fk_rpt_item; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY c_rpt_item
    ADD CONSTRAINT fk_rpt_item FOREIGN KEY (rpt_id) REFERENCES c_rpt(id) ON DELETE CASCADE;


--
-- TOC entry 2464 (class 2606 OID 28280)
-- Name: fk_s_postmenu_menu; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_postmenu
    ADD CONSTRAINT fk_s_postmenu_menu FOREIGN KEY (menu_id) REFERENCES sys_menu(id) ON DELETE CASCADE;


--
-- TOC entry 2465 (class 2606 OID 28285)
-- Name: fk_s_postmenu_post; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_postmenu
    ADD CONSTRAINT fk_s_postmenu_post FOREIGN KEY (post_id) REFERENCES s_post(id) ON DELETE CASCADE;


--
-- TOC entry 2466 (class 2606 OID 28290)
-- Name: fk_s_postmenufunc; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_postmenufunc
    ADD CONSTRAINT fk_s_postmenufunc FOREIGN KEY (menu_id) REFERENCES sys_menu(id) ON DELETE CASCADE;


--
-- TOC entry 2467 (class 2606 OID 28295)
-- Name: fk_s_postmenufunc_func; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_postmenufunc
    ADD CONSTRAINT fk_s_postmenufunc_func FOREIGN KEY (func_id) REFERENCES sys_func(id) ON DELETE CASCADE;


--
-- TOC entry 2468 (class 2606 OID 28300)
-- Name: fk_s_postmenufunc_post; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_postmenufunc
    ADD CONSTRAINT fk_s_postmenufunc_post FOREIGN KEY (post_id) REFERENCES s_post(id) ON DELETE CASCADE;


--
-- TOC entry 2469 (class 2606 OID 28305)
-- Name: fk_s_postuser_post; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_postuser
    ADD CONSTRAINT fk_s_postuser_post FOREIGN KEY (post_id) REFERENCES s_post(id) ON DELETE CASCADE;


--
-- TOC entry 2470 (class 2606 OID 28310)
-- Name: fk_s_postuser_user; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY s_postuser
    ADD CONSTRAINT fk_s_postuser_user FOREIGN KEY (user_id) REFERENCES s_user(id) ON DELETE CASCADE;


--
-- TOC entry 2471 (class 2606 OID 28315)
-- Name: fk_sys_menu_parent; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY sys_menu
    ADD CONSTRAINT fk_sys_menu_parent FOREIGN KEY (parent_id) REFERENCES sys_menu(id);


--
-- TOC entry 2472 (class 2606 OID 28320)
-- Name: fk_sys_menufunc_func; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY sys_menu_func
    ADD CONSTRAINT fk_sys_menufunc_func FOREIGN KEY (func_id) REFERENCES sys_func(id) ON DELETE CASCADE;


--
-- TOC entry 2473 (class 2606 OID 28325)
-- Name: fk_sys_menufunc_menu; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY sys_menu_func
    ADD CONSTRAINT fk_sys_menufunc_menu FOREIGN KEY (menu_id) REFERENCES sys_menu(id) ON DELETE CASCADE;


--
-- TOC entry 2435 (class 2606 OID 28330)
-- Name: group_id_refs_id_f4b32aac; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_group_permissions
    ADD CONSTRAINT group_id_refs_id_f4b32aac FOREIGN KEY (group_id) REFERENCES auth_group(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 2438 (class 2606 OID 28335)
-- Name: user_id_refs_id_40c41112; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_user_groups
    ADD CONSTRAINT user_id_refs_id_40c41112 FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 2440 (class 2606 OID 28340)
-- Name: user_id_refs_id_4dc23c39; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY auth_user_user_permissions
    ADD CONSTRAINT user_id_refs_id_4dc23c39 FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 2460 (class 2606 OID 28345)
-- Name: user_id_refs_id_c0d12874; Type: FK CONSTRAINT; Schema: public; Owner: yardAdmin
--

ALTER TABLE ONLY django_admin_log
    ADD CONSTRAINT user_id_refs_id_c0d12874 FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED;


--
-- TOC entry 2596 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2014-06-30 13:12:16 CST

--
-- PostgreSQL database dump complete
--


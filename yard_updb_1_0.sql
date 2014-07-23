CREATE OR REPLACE FUNCTION f_create_protocol_fee(p_client_id integer, p_begin_date date, p_end_date date, p_financial_date date, oper_id integer)
  RETURNS character varying AS
$BODY$
declare
	cur_contract cursor for
		select c.id,c.client_id,c.bill_no
		from contract c
		where (c.client_id = p_client_id or p_client_id is null)
		and c.in_port_date between p_begin_date and p_end_date;
	cur_pair_fee cursor(cp_contract_id integer) for
		select p.fee_cod,p.fee_tim,p.fee_financial_tim,p.amount,p.currency_cod
		from pre_fee p,c_fee c
		where p.contract_id = cp_contract_id
		and p.fee_typ = 'O'
		and p.ex_feeid = 'O'
		and p.fee_cod = c.id
		and c.pair_flag = true
		and p.fee_cod not in(
			select ip.fee_cod from pre_fee ip
			where ip.contract_id = cp_contract_id and ip.fee_typ = 'I'
		);
	cur_fee_mod cursor(cp_protocol_id integer) for
		select p.fee_id,p.mod_id
		from p_protocol_fee_mod p
		where p.protocol_id = cp_protocol_id and p.active_flag;
	vi_count integer;
	vi_protocol_id c_client.protocol_id%TYPE;
	vc_mod_process p_fee_mod.deal_process%TYPE;
	vt_time date;
	vc_call_function_result character varying;
	vc_t character varying;
begin
  --select current_timestamp(0)::timestamp without time zone into vt_time;
  select current_date into vt_time;
  for vcur_contract in cur_contract loop
	--检查委托是否已进行过协议计费
	select count(1) into vi_count from pre_fee p
	where p.contract_id = vcur_contract.id and p.create_flag = 'P' and (p.lock_flag or p.audit_id or (p.ex_feeid = 'E'));
	if vi_count > 0 then
		return 'ERR:提单号' || vcur_contract.bill_no || '已有协议费用核销或锁定';
	end if;
	--根据委托客户取绑定的协议
	select protocol_id into vi_protocol_id from c_client c where c.id = vcur_contract.client_id;
	if vi_protocol_id is null then
		--客户未绑定协议
		continue;
	end if;
	for vcur_fee_mod in cur_fee_mod(vi_protocol_id) loop
		select deal_process into vc_mod_process from p_fee_mod where id = vcur_fee_mod.mod_id;
		if (vc_mod_process is null or char_length(trim(vc_mod_process)) = 0 ) then
			--模式未绑定存储过程
			continue;
		end if;
		--调用模式绑定存储过程
		--perform vc_mod_process(vcur_contract.id,vi_protocol_id,vcur_fee_mod.fee_id,vcur_fee_mod.mod_id,vt_time,p_financial_date,oper_id);
		-- vc_call_function := vc_mod_process || '(' || cast(vcur_contract.id as character varying) || ',' || cast(vi_protocol_id as character varying) || ','
-- 			 || cast(vcur_fee_mod.fee_id as character varying) || ',' || cast(vcur_fee_mod.mod_id as character varying) || ',' ||
-- 			 '''' || cast(vt_time as character varying) || '''' || ',' || '''' || cast(p_financial_date as character varying) || '''' || ','
-- 			 || cast(oper_id as character varying) || ');';
		vc_t := 'select ' || vc_mod_process || '(%1,%2,%3,%4,%5,%6,%7)';
		--EXECUTE vc_t into vc_call_function_result using vcur_contract.id,vi_protocol_id,vcur_fee_mod.fee_id,vcur_fee_mod.mod_id,vt_time,p_financial_date,oper_id;
		EXECUTE 'select ' || vc_mod_process || '($1,$2,$3,$4,$5,$6,$7)' into vc_call_function_result using vcur_contract.id,vi_protocol_id,vcur_fee_mod.fee_id,vcur_fee_mod.mod_id,vt_time,p_financial_date,oper_id;
		--select f_mod_fee_1(12,1,1,2,'2014-01-01','2014-10-01',1) into vc_call_function_result;
	end loop;
	--循环已录入应付费用,对代收代付费用产生对应的应收费用
	for vcur_pair_fee in cur_pair_fee(vcur_contract.id) loop
		insert into pre_fee (contract_id,fee_typ,fee_cod,client_id,amount,fee_tim,fee_financial_tim,rec_nam,rec_tim,
					ex_feeid,currency_cod,create_flag)
		values(vcur_contract.id,'I',vcur_pair_fee.fee_cod,vcur_contract.client_id,vcur_pair_fee.amount,vt_time,p_financial_date,oper_id,vt_time,
					'O',vcur_pair_fee.currency_cod,'P');
	end loop;
  end loop;
  return 'SUC';
Exception
When Others Then
    raise exception 'ERR:数据库错误号-%',SQLSTATE;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;;
ALTER FUNCTION f_create_protocol_fee(integer, date, date, date, integer)
  OWNER TO "yardAdmin";;

CREATE OR REPLACE FUNCTION f_mod_fee_1(p_contract_id integer, p_protocol_id integer, p_fee_id integer, p_mod_id integer, p_time date, p_financial_date date, p_oper_id integer)
  RETURNS character varying AS
$BODY$
declare
	cur_data cursor for
		select c.bill_no,c.client_id,sum(COALESCE(cc.cntr_num,0) * (COALESCE(p.fee_rat,0) - COALESCE(p.discount_rat,0))) amount
		from contract c,contract_cntr cc,p_protocol_rat p
		where c.id = p_contract_id and c.id = cc.contract_id
		and p.protocol_id = p_protocol_id and p.fee_id = p_fee_id and p.mod_id = p_mod_id
		and p.fee_ele1 = cast(c.cargo_type as character varying) and p.fee_ele2 = cast(cc.cntr_type as character varying)
		group by c.bill_no,c.client_id;

begin
	for vcur_data in cur_data loop
		insert into pre_fee(contract_id,fee_typ,fee_cod,client_id,amount,fee_tim,fee_financial_tim,rec_nam,rec_tim,ex_feeid,create_flag)
		values(p_contract_id,'I',p_fee_id,vcur_data.client_id,vcur_data.amount,p_time,p_financial_date,p_oper_id,p_time,'O','P');
	end loop;
	return 'SUC';

end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;;
ALTER FUNCTION f_mod_fee_1(integer, integer, integer, integer, date, date, integer)
  OWNER TO "yardAdmin";;


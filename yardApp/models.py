from django.db import models

# Create your models here.

class BaseModel(models.Model):
    ''''''
    remark = models.CharField('备注',blank=True,max_length=50,null=True)
    rec_nam = models.IntegerField('创建人员')
    rec_tim = models.DateTimeField('创建时间')
    upd_nam = models.IntegerField('修改人员',blank=True,null=True)
    upd_tim = models.DateTimeField('修改时间',blank=True,null=True)
    class Meta:
        abstract = True
class Client(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    client_name = models.CharField('客户名称',max_length=50,unique=True)
    client_flag = models.NullBooleanField('委托方标识')
    custom_flag = models.NullBooleanField('报关行标识')
    ship_corp_flag = models.NullBooleanField('船公司标识')
    yard_flag = models.NullBooleanField('场站标识')
    port_flag = models.NullBooleanField('码头标识')
    financial_flag = models.NullBooleanField('财务往来单位标识')
    landtrans_flag = models.NullBooleanField('车队标识')
    credit_flag = models.NullBooleanField('信用证公司标识')
    def __str__(self):
        return self.client_name
    class Meta:
        db_table = 'c_client'
class SysCode(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    fld_eng = models.CharField('英文字段名',max_length=20)
    fld_chi = models.CharField('中文字段名',max_length=30)
    cod_name = models.CharField('值名称',max_length=20)
    fld_ext1 = models.CharField('字段扩展值1',blank=True,max_length=20,null=True)
    fld_ext2 = models.CharField('字段扩展值2',blank=True,max_length=20,null=True)
    seq = models.SmallIntegerField('序号')
    def __str__(self):
        return self.fld_chi + ':' + self.cod_name
    class Meta:
        db_table = 'sys_code'
class User(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    username = models.CharField('用户',max_length=10)
    password = models.CharField('密码',max_length=40)
    lock = models.NullBooleanField('锁住',blank=True,null=True)
    def __str__(self):
        return self.username
    class Meta:
        db_table = 's_user'
class Post(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    postname = models.CharField('岗位名称',max_length=20)
    def __str__(self):
        return self.postname
    class Meta:
        db_table = 's_post'
class PostUser(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    post_id = models.ForeignKey('Post',verbose_name='岗位',related_name='post_postuser',db_column='post_id')
    user_id = models.ForeignKey('User',verbose_name='用户',related_name='user_postuser',db_column='user_id')
    def __str__(self):
        return self.post_id.postname + '/' + self.user_id.username
    class Meta:
        db_table = 's_postuser'

class PostMenu(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    post_id = models.ForeignKey('Post',verbose_name='岗位',related_name='post_postmenu',db_column='post_id')
    menu_id = models.ForeignKey('SysMenu',verbose_name='功能',related_name='menu_postmenu',db_column='menu_id')
    active = models.NullBooleanField('显示',blank=True,null=True)
    def __str__(self):
        return self.post_id.postname + '/' + self.menu_id.menuname
    class Meta:
        db_table = 's_postmenu'
class PostMenuFunc(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    post_id = models.ForeignKey('Post',verbose_name='岗位',related_name='post_postmenufunc',db_column='post_id')
    menu_id = models.ForeignKey('SysMenu',verbose_name='功能',related_name='menu_postmenufunc',db_column='menu_id')
    func_id = models.ForeignKey('SysFunc',verbose_name='权限',related_name='func_postmenufunc',db_column='func_id')
    def __str__(self):
        return self.post_id.postname + '/' + self.menu_id.menuname + '/' + self.func_id.funcname
    class Meta:
        db_table = 's_postmenufunc'
class SysMenu(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    menuname = models.CharField('功能名称',max_length=50)
    menushowname = models.CharField('功能显示名称',max_length=50)
    parent_id = models.ForeignKey('SysMenu',limit_choices_to={'parent_id':0},related_name='menu_sysmenu',verbose_name='父功能',db_column='parent_id')
    sortno = models.SmallIntegerField('序号',blank=True,null=True)
    sys_flag = models.NullBooleanField('系统功能标识',blank=True,null=True)
    def __str__(self):
        return self.menushowname
    class Meta:
        db_table = 'sys_menu'
class SysFunc(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    funcname = models.CharField('权限名称',max_length=50)
    ref_tables = models.CharField('涉及表',max_length=100,blank=True,null=True)
    def __str__(self):
        return self.funcname
    class Meta:
        db_table = 'sys_func'
class SysMenuFunc(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    menu_id = models.ForeignKey('SysMenu',verbose_name='功能',related_name='menu_sysmenufunc',db_column='menu_id')
    func_id = models.ForeignKey('SysFunc',verbose_name='权限',related_name='func_sysmenufunc',db_column='func_id')
    def __str__(self):
        return self.menu_id.menuname + '/' + self.func_id.funcname
    class Meta:
        db_table = 'sys_menu_func'
class CntrType(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    cntr_type = models.CharField('箱型',max_length=4)
    cntr_type_name = models.CharField('箱型描述',max_length=20)
    def __str__(self):
        return self.cntr_type
    class Meta:
        db_table = 'c_cntr_type'
class Action(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    action_name = models.CharField('动态名称',max_length=20)
    require_flag = models.NullBooleanField('必有标识',blank=True,null=True)
    sortno = models.SmallIntegerField('序号')
    def __str__(self):
        return self.action_name
    class Meta:
        db_table = 'c_contract_action'
class Cargo(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    cargo_name = models.CharField('货物名称',max_length=20)
    def __str__(self):
        return self.cargo_name
    class Meta:
        db_table = 'c_cargo'
class CargoType(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    type_name = models.CharField('货物分类名称',max_length=20)
    def __str__(self):
        return self.type_name
    class Meta:
        db_table = 'c_cargo_type'
class Place(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    place_name = models.CharField('地点名称',max_length=20)
    def __str__(self):
        return self.place_name
    class Meta:
        db_table = 'c_place'
class Dispatch(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    place_name = models.CharField('发货地',max_length=30)
    def __str__(self):
        return self.place_name
    class Meta:
        db_table = 'c_dispatch'
class FeeCod(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    fee_name = models.CharField('费用名称',max_length=20)
    protocol_flag = models.NullBooleanField('协议费用标识')
    pair_flag = models.NullBooleanField('代付标识',blank=True,null=True)
    def __str__(self):
        return self.fee_name
    class Meta:
        db_table = 'c_fee'
class PayType(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    pay_name = models.CharField('付款方式',max_length=20)
    def __str__(self):
        return self.pay_name
    class Meta:
        db_table = 'c_pay_type'
class Contract(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    bill_no = models.CharField('提单号',max_length=25,unique=True)
    client_id = models.ForeignKey('Client',verbose_name='客户',limit_choices_to={'client_flag':True},related_name='client_contract',db_column='client_id')
    #contract_type = models.ForeignKey('SysCode',verbose_name='委托类型',limit_choices_to={'fld_eng':'contract_type'},related_name='contract_type_contract',db_column='contract_type')
    #cargo_fee_type = models.ForeignKey('SysCode',verbose_name='货物费用计费类型',limit_choices_to={'fld_eng':'fee_cal_type'},related_name='cargo_fee_type_contract',db_column='cargo_fee_type')
    cargo_piece = models.IntegerField('货物件数',blank=True,null=True)
    cargo_weight = models.DecimalField('货物重量',blank=True,decimal_places=2,max_digits=13,null=True)
    cargo_volume = models.DecimalField('货物体积',blank=True,decimal_places=3,max_digits=13,null=True)
    booking_date = models.DateField('接单日期',blank=True,null=True)
    in_port_date = models.DateField('到港日期',blank=True,null=True)
    return_cntr_date = models.DateField('还箱日期',blank=True,null=True)
    custom_id = models.ForeignKey('Client',blank=True,null=True,limit_choices_to={'custom_flag':True},verbose_name='报关行',related_name='custom_contract',db_column='custom_id')
    ship_corp_id = models.ForeignKey('Client',blank=True,null=True,limit_choices_to={'ship_corp_flag':True},verbose_name='船公司',related_name='ship_corp_contract',db_column='ship_corp_id')
    port_id = models.ForeignKey('Client',blank=True,null=True,verbose_name='码头',limit_choices_to={'port_flag':True},related_name='port_contract',db_column='port_id')
    yard_id = models.ForeignKey('Client',blank=True,null=True,verbose_name='还箱场站',limit_choices_to={'yard_flag':True},related_name='yard_contract',db_column='yard_id')
    finish_time = models.DateTimeField('完成时间',blank=True,null=True)
    finish_flag = models.NullBooleanField('完成标识',blank=True,null=True)
    vslvoy = models.CharField('船名航次',max_length=40,blank=True,null=True)
    contract_no = models.CharField('合同号',max_length=20,blank=True,null=True)
    dispatch_place = models.ForeignKey('Dispatch',verbose_name='发货地',related_name='dispatchplace_contract',db_column='dispatch_place')
    custom_title1 = models.CharField('报关抬头1',max_length=30,blank=True,null=True)
    custom_title2 = models.CharField('报关抬头2',max_length=30,blank=True,null=True)
    landtrans_id = models.ForeignKey('Client',blank=True,null=True,verbose_name='车队',limit_choices_to={'landtrans_flag':True},related_name='landtrans_contract',db_column='landtrans_id')
    check_yard_id = models.ForeignKey('Client',blank=True,null=True,verbose_name='查验场站',limit_choices_to={'yard_flag':True},related_name='checkyard_contract',db_column='check_yard_id')
    unbox_yard_id = models.ForeignKey('Client',blank=True,null=True,verbose_name='拆箱场站',limit_choices_to={'yard_flag':True},related_name='unboxyard_contract',db_column='unbox_yard_id')
    credit_id = models.ForeignKey('Client',blank=True,null=True,verbose_name='信用证公司',limit_choices_to={'credit_flag':True},related_name='credit_contract',db_column='credit_id')
    cargo_name = models.ForeignKey('Cargo',blank=True,null=True,verbose_name='货物',related_name='cargo_contract',db_column='cargo_name')
    origin_place = models.ForeignKey('Place',blank=True,null=True,verbose_name='产地',related_name='place_contract',db_column='origin_place')
    cargo_type = models.ForeignKey('CargoType',blank=True,null=True,verbose_name='货物分类',related_name='cargotype_contract',db_column='cargo_type')
    cntr_freedays = models.IntegerField('箱使天数',blank=True,null=True)
    def __str__(self):
        return self.bill_no
    class Meta:
        db_table = 'contract'
class ContractAction(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    contract_id = models.ForeignKey('Contract',related_name='contract_contractaction',verbose_name='委托',db_column='contract_id')
    action_id = models.ForeignKey('Action',related_name='action_contractaction',verbose_name='委托动态',db_column='action_id')
    finish_flag = models.NullBooleanField('完成标识',blank=True,null=True)
    finish_time = models.DateTimeField('完成时间',blank=True,null=True)
    def __str__(self):
        return self.contract_id.bill_no + '/' + self.action_id.action_name
    class Meta:
        db_table = 'contract_action'
class ContractCntr(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    contract_id = models.ForeignKey('Contract',related_name='contract_contractcntr',verbose_name='委托',db_column='contract_id')
    cntr_type = models.ForeignKey('CntrType',related_name='cntrtype_contractcntr',verbose_name='箱型',db_column='cntr_type')
    cntr_num = models.IntegerField('箱量')
    check_num = models.IntegerField('查验箱量',blank=True,null=True)
    def __str__(self):
        return self.contract_id.bill_no + '/' + self.cntr_type + '/' + str(self.cntr_num)
    class Meta:
        db_table = 'contract_cntr'
class PreFee(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    contract_id = models.ForeignKey('Contract',related_name='contract_prefee',verbose_name='委托',db_column='contract_id')
    fee_typ = models.CharField('费用类型',max_length=1,choices=(('I','应收'),('O','应付')))
    fee_cod = models.ForeignKey('FeeCod',related_name='feecod_prefee',verbose_name='费用名称',db_column='fee_cod')
    client_id = models.ForeignKey('Client',related_name='client_prefee',limit_choices_to={'financial_flag':True},verbose_name='客户',db_column='client_id')
    amount = models.DecimalField('金额',blank=True,null=True,max_digits=10,decimal_places=2)
    fee_tim = models.DateTimeField('费用时间')
    fee_financial_tim = models.DateTimeField('财务统计时间')
    lock_flag = models.NullBooleanField('锁定',blank=True,null=True)
    ex_feeid = models.CharField('生成方式',max_length=1,choices=(('O','原生'),('E','拆分')))
    ex_from = models.CharField('来源号',max_length=36,blank=True,null=True)
    ex_over = models.CharField('完结号',max_length=36,blank=True,null=True)
    audit_id =  models.NullBooleanField('核销',blank=True,null=True)
    audit_tim = models.DateTimeField('核销时间')
    def __str__(self):
        return self.contract_id.bill_no + '/' + self.fee_typ + '/' + self.fee_cod.fee_name + '/' + self.client_id.client_name + '/' + str(self.amount)
    class Meta:
        db_table = 'pre_fee'
class ActFee(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    client_id = models.ForeignKey('Client',related_name='client_actfee',limit_choices_to={'financial_flag':True},verbose_name='客户',db_column='client_id')
    fee_typ = models.CharField('费用类型',max_length=1,choices=(('I','已收'),('O','已付')))
    amount = models.DecimalField('金额',blank=True,null=True,max_digits=10,decimal_places=2)
    invoice_no = models.CharField('发票号',max_length=30,blank=True,null=True)
    check_no = models.CharField('支票号',max_length=30,blank=True,null=True)
    accept_no = models.CharField('承兑号',max_length=30,blank=True,null=True)
    pay_type = models.ForeignKey('PayType',related_name='paytype_actfee',verbose_name='付费类型',db_column='pay_type')
    fee_tim = models.DateTimeField('付费时间')
    ex_feeid = models.CharField('生成标记',max_length=1,choices=(('O','原生'),('E','拆分')))
    ex_from = models.CharField('来源号',max_length=36,blank=True,null=True)
    ex_over = models.CharField('完结号',max_length=36,blank=True,null=True)
    audit_id =  models.NullBooleanField('核销',blank=True,null=True)
    audit_tim = models.DateTimeField('核销时间')
    def __str__(self):
        return self.client_id.client_name + '/' + self.fee_typ + '/' + self.pay_type.pay_name + '/' + str(self.amount)
    class Meta:
        db_table = 'act_fee'
class FilterHead(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    datagrid = models.CharField('datagrid名称',max_length=100)
    filter_type = models.CharField('查询类型',max_length=1,choices=(('G','全局'),('P','个人')))
    filter_owner = models.ForeignKey('User',related_name='user_filterhead',verbose_name='查询人员',db_column='filter_owner')
    filter_name = models.CharField('查询名称',max_length=50)
    def __str__(self):
        return self.filter_name
    class Meta:
        db_table = 's_filter_head'
class FilterBody(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    filter_id = models.ForeignKey('FilterHead',related_name='filterhead_filtebody',verbose_name='查询头',db_column='filter_id')
    content_type = models.CharField('查询内容类型',max_length=1,choices=(('W','where条件'),('S','排序条件'),('C','字段列表')))
    content_col = models.CharField('查询字段名',max_length=30)
    content_condition = models.CharField('查询条件',max_length=10,blank=True,null=True)
    content_value = models.CharField('查询值',max_length=50,blank=True,null=True)
    value_text = models.CharField('字面值',max_length=100,blank=True,null=True)
    display_value = models.CharField('显示值',max_length=100,blank=True,null=True)
    class Meta:
        db_table = 's_filter_body'
class Rpt(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    rpt_name = models.CharField('报表名称',max_length=30)
    def __str__(self):
        return self.rpt_name
    class Meta:
        db_table = 'c_rpt'
class RptItem(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    item_name = models.CharField('报表项目名称',max_length=30)
    rpt_id = models.ForeignKey('Rpt',related_name='rpt_rptitem',verbose_name='报表id',db_column='rpt_id')
    sort_no = models.IntegerField('序号',blank=True,null=True)
    def __str__(self):
        return self.item_name
    class Meta:
        db_table = 'c_rpt_item'
class RptItemFee(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    rpt_id = models.ForeignKey('Rpt',related_name='rpt_rptitemfee',verbose_name='报表id',db_column='rpt_id')
    item_id = models.ForeignKey('RptItem',related_name='rptitem_rptitemfee',verbose_name='报表项目id',db_column='item_id')
    fee_id = models.ForeignKey('FeeCod',related_name='fee_rptitemfee',verbose_name='费用id',db_column='fee_id')
    class Meta:
        db_table = 'c_rpt_fee'
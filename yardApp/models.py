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
    def __str__(self):
        return self.client_name
    class Meta:
        db_table = 'c_client'
class Contract(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    bill_no = models.CharField('提单号',max_length=25,unique=True)
    cargo_name = models.CharField('货物名称',blank=True,max_length=30,null=True)
    origin_place = models.CharField('产地',blank=True,max_length=30,null=True)
    client_id = models.ForeignKey('Client',verbose_name='客户',related_name='client_contract',db_column='client_id')
    contract_type = models.ForeignKey('SysCode',verbose_name='委托类型',related_name='contract_type_contract',db_column='contract_type')
    cargo_fee_type = models.ForeignKey('SysCode',verbose_name='货物费用计费类型',related_name='cargo_fee_type_contract',db_column='cargo_fee_type')
    cargo_piece = models.IntegerField('货物件数',blank=True,null=True)
    cargo_weight = models.DecimalField('货物重量',blank=True,decimal_places=2,max_digits=13,null=True)
    cargo_volume = models.DecimalField('货物体积',blank=True,decimal_places=3,max_digits=13,null=True)
    booking_date = models.DateField('接单日期',blank=True,null=True)
    in_port_date = models.DateField('到港日期',blank=True,null=True)
    return_cntr_date = models.DateField('还箱日期',blank=True,null=True)
    custom_id = models.ForeignKey('Client',blank=True,null=True,verbose_name='报关行',related_name='custom_contract',db_column='custom_id')
    ship_corp_id = models.ForeignKey('Client',blank=True,null=True,verbose_name='船公司',related_name='ship_corp_contract',db_column='ship_corp_id')
    port_id = models.ForeignKey('Client',blank=True,null=True,verbose_name='码头',related_name='port_contract',db_column='port_id')
    yard_id = models.ForeignKey('Client',blank=True,null=True,verbose_name='场站',related_name='yard_contract',db_column='yard_id')
    finish_tim = models.DateTimeField('完成时间',blank=True,null=True)
    finish_flag = models.NullBooleanField('完成标识',blank=True,null=True)
    def __str__(self):
        return self.bill_no
    class Meta:
        db_table = 'contract'
class contractAction(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    contract_id = models.ForeignKey('Contract',related_name='contract_contractaction',verbose_name='委托')
    action_id = models.ForeignKey('ContractActionCod',related_name='action_contractaction',verbose_name='委托动态')
    finish_flag = models.NullBooleanField('完成标识',blank=True,null=True)
    finish_time = models.DateTimeField('完成时间',blank=True,null=True)
    class Meta:
        db_table = 'contract_action'
class ContractActionCod(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    action_name = models.CharField('委托动态名称',max_length=20,unique=True)
    def __str__(self):
        return self.action_name
    class Meta:
        db_table = 'c_contract_action'
class FeeCod(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    fee_name = models.CharField('费用名称',max_length=20,unique=True)
    protocol_flag = models.NullBooleanField('协议费用标识')
    def __str__(self):
        return self.fee_name
    class Meta:
        db_table = 'c_fee'
class FeeProtocol(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    client_id = models.ForeignKey('Client',verbose_name='客户ID')
    fee_id = models.ForeignKey('FeeCod',verbose_name='费用代码')
    contract_type = models.ForeignKey('SysCode',related_name='contract_type_feeprotocol',verbose_name='业务类型')
    fee_cal_type = models.ForeignKey('SysCode',related_name='fee_cal_type_feeprotocol',verbose_name='计费方式')
    rate = models.DecimalField('费率',max_digits=8,decimal_places=2)
    free_day = models.SmallIntegerField('免费天数',blank=True,null=True)
    class Meta:
        db_table = 'c_fee_protocol'
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
class PostMenu(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    post_id = models.ForeignKey('Post',verbose_name='岗位',related_name='post_postmenu',db_column='post_id')
    menu_id = models.ForeignKey('SysMenu',verbose_name='功能',related_name='menu_postmenu',db_column='menu_id')
    active = models.NullBooleanField('显示',blank=True,null=True)
class PostFunc(BaseModel):
    id = models.AutoField('pk',primary_key=True)
    post_id = models.ForeignKey('Post',verbose_name='岗位',related_name='post_postfunc',db_column='post_id')
    func_id = models.ForeignKey('SysFunc',verbose_name='权限',related_name='func_postfunc',db_column='func_id')
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

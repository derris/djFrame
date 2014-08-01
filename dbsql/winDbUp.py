#!/usr/bin/env python
import tkinter as tk
import tkinter.ttk as ttk
from tkinter import messagebox

import os
g_cwd = os.getcwd() if os.getcwd()[-1] == os.sep else os.getcwd() + os.sep

g_sepSql = []

class Application(tk.Frame):    
    global g_cwd #
    global g_sepSql #
    #
    def __init__(self, master=None):
        tk.Frame.__init__(self, master)
        self.grid(sticky=tk.N+tk.S+tk.E+tk.W)
        self.createWidgets()   
        self.click_listfile()        
    # 列出指定路径下的所有文件
    def click_listfile(self):
        l_dir = self.textDir.get('0.0', tk.END).strip()
        l_dir = l_dir if l_dir[-1] == os.sep else l_dir + os.sep
        if os.path.isdir(l_dir):
            g_cwd = l_dir
            self.ListFile.delete(0, tk.END)
            # list file name
            for iFile in os.listdir(l_dir):
                if os.path.isfile(l_dir + iFile):
                    self.ListFile.insert(tk.END, iFile)
        else:
            messagebox.showerror('错误','指定目录不存在：' + l_dir)            
    # 读出指定的文件内容，列出相应的索引。
    def click_read(self):
        l_file = self.ListFile.get(tk.ACTIVE)
        if os.path.isfile(g_cwd + l_file):
            self.tab.select(0)
            try:
                self.textSql.delete(0.0, tk.END)  
                self.textSql.insert(0.0, open(l_file, 'r', encoding="utf8").read())
            except Exception as e:
                messagebox.showerror('错误', str(e.args))  
        else:
            messagebox.showerror('错误','指定文件不存在：' + g_cwd + l_file)      
    #
    def click_analyze(self): 
        self.tab.select(1)
        try:
            global g_sepSql #
            g_sepSql = []            
            g_sepSql = self.textSql.get('0.0', tk.END).split(';;')
            l_idxSql = ""
            for iSql in zip(range(len(g_sepSql)), g_sepSql):                
                l_idxSql = l_idxSql + str(iSql[0]) + " : " + iSql[1] + os.linesep                    
            self.textAnalyze.delete(0.0, tk.END)
            self.textAnalyze.insert(0.0, l_idxSql)
            self.textS2.delete(0.0, tk.END)
            self.textS2.insert(0.0, len(g_sepSql) - 1)
        except Exception as e:
            messagebox.showerror('错误',str(e.args))
    #
    def click_execute(self):
        if messagebox.askyesno('注意','运行前先分析，将执行指定行的sql语句，确认么？'):        
            self.textResult.delete(0.0, tk.END)           
            self.tab.select(2)                               
            try:
                import psycopg2
                conTarget = psycopg2.connect(host='localhost', port=5432, user='yardAdmin', password='zht+dh=sql2', database='yard')
                conTarget.autocommit = False
                curTarget = conTarget.cursor()  
                l_start = int(self.textS1.get(0.0, tk.END))
                l_end = int(self.textS2.get(0.0, tk.END))
                #messagebox.showerror('错误', "%s %s %s " % (str(l_start), str(l_end), str(g_sepSql) )  )
                for i in range(l_start, l_end):
                    if len(g_sepSql[i].strip()) > 4:
                        self.textResult.insert(0.0, (g_sepSql[i]))
                        curTarget.execute(g_sepSql[i])        
                conTarget.commit()
                self.textResult.insert(0.0, "数据库成功完成")
            except Exception as e:                
                self.textResult.insert(0.0, str(e.args))
                conTarget.rollback()
    #
    def createWidgets(self):
        top=self.winfo_toplevel()
        top.rowconfigure(0, weight=1)
        top.columnconfigure(0, weight=1)
        ######################### 行
        l_row1 = 0
        l_row2 = 1
        l_row3 = 2
        self.rowconfigure(l_row1, weight=0)
        self.rowconfigure(l_row2, weight=1)
        self.rowconfigure(l_row3, weight=0)
        ######################### 列
        l_col1 = 0
        l_col2 = 1
        self.columnconfigure(l_col1, weight=0)
        self.columnconfigure(l_col2, weight=1)                    
        ########################## l_row1 l_col1
        self.panes1 = tk.PanedWindow(self, orient = tk.HORIZONTAL,height=30)
        self.textDir = tk.Text(self.panes1, width=20)
        self.textDir.insert(0.0,g_cwd)    
        self.panes1.add(self.textDir) # 当前目录               ##### 列出当前目录下文件
        self.panes1.add(tk.Button(self.panes1,text = "列出", command=self.click_listfile)) 
        self.panes1.grid(row=l_row1, column=l_col1, sticky=tk.E+tk.W) 
        ########################## l_row1 l_col2
        self.panes2 = tk.PanedWindow(self, orient = tk.HORIZONTAL, height=30)
        self.panes2.add(tk.Button(self.panes2, text = " 分析 ", width=6, command=self.click_analyze)) #
        self.textS1 = tk.Text(self.panes2, width=5)
        self.textS1.insert(0.0, "0")           
        self.panes2.add(self.textS1) # 执行范围1
        self.panes2.add(tk.Label(self.panes2,text = "到", width=3,anchor=tk.W)) # label       
        self.textS2 = tk.Text(self.panes2,width=5)
        self.textS2.insert(0.0, "0")           
        self.panes2.add(self.textS2) # 执行范围2              #####  执行文件        
        self.panes2.add(tk.Button(self.panes2, text = " 执行 ", width=6, command=self.click_execute)) #
        #
        self.panes2.grid(row=l_row1,  padx=(5,0), column=l_col2, sticky=tk.E+tk.W) 
        self.panes2.add(tk.Label(self.panes2,text = ""))   # 占位置
        ########################## l_row2 l_col1
        self.ListFile = tk.Listbox(self) #, selectmode = tk.MULTIPLE)
        #
        self.ListFile.grid(row=l_row2, column=l_col1,sticky=tk.E+tk.W+tk.N+tk.S)      
        ##########################  l_row2 l_col2  
        self.tab = ttk.Notebook(self)   
        # tab1
        self.tab1 = ttk.PanedWindow(self, orient = tk.HORIZONTAL)
        self.textSql = tk.Text(self.tab1)            ######### sql文件内容。
        self.textSql_sv = ttk.Scrollbar(self.tab1, orient=tk.VERTICAL, command=self.textSql.yview) 
        self.textSql['yscrollcommand'] = self.textSql_sv.set                
        self.tab1.add(self.textSql, weight=1)
        self.tab1.add(self.textSql_sv, weight=0)
        self.tab.add( self.tab1 )   
        # tab2
        self.tab2 = ttk.PanedWindow(self, orient = tk.HORIZONTAL)
        self.textAnalyze = tk.Text(self.tab2)         ######### sql分析内容。 
        self.textAnalyze_sv = ttk.Scrollbar(self.tab2, orient=tk.VERTICAL, command=self.textAnalyze.yview) 
        self.textAnalyze['yscrollcommand'] = self.textAnalyze_sv.set           
        self.tab2.add(self.textAnalyze, weight=1)
        self.tab2.add(self.textAnalyze_sv, weight=0)
        self.tab.add( self.tab2 )         
        #tab3
        self.tab3 = ttk.PanedWindow(self, orient = tk.HORIZONTAL)
        self.textResult = tk.Text(self.tab3)         ######### execute内容。 
        self.textResult_sv = ttk.Scrollbar(self.tab3, orient=tk.VERTICAL, command=self.textResult.yview) 
        self.textResult['yscrollcommand'] = self.textResult_sv.set           
        self.tab3.add(self.textResult, weight=1)
        self.tab3.add(self.textResult_sv, weight=0)
        self.tab.add( self.tab3 ) 
        #table
        self.tab.tab(0, text=' sql内容 ')
        self.tab.tab(1, text=' 文件分析 ')
        self.tab.tab(2, text=' 执行结果 ')
        self.tab.grid(row=l_row2, column=l_col2, padx=(5,0), sticky=tk.E+tk.W+tk.N+tk.S)
        ##########################  l_row3 l_col1 
        self.read = tk.Button(self, text='  读出  ', command=self.click_read)
        self.read.grid(row=l_row3, column=l_col1, sticky=tk.E)    
        ##########################  l_row3 l_col2
        self.quit = tk.Button(self, text='  退出  ', command=self.quit)
        self.quit.grid(row=l_row3, column=l_col2, sticky=tk.E)    
app = Application()
app.master.title('Sample application')
app.mainloop()
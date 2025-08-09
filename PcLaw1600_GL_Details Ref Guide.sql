/****** Object:  View [dbo].[PCLaw_GeneralLedger_Details]    Script Date: 08/15/2012 09:03:07 ******/
SET
	ANSI_NULLS ON
GO
SET
	QUOTED_IDENTIFIER ON
GO
	CREATE view [dbo].[EXT_GeneralLedger_Details] as -- Journal entries

---------------------------------------------------------------------
1 - COMPLETED
---------------------------------------------------------------------
select
	'GJEntry' as TableName,
	'JE' as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(j.GJEntryDate) as GLDate,
	case
		when g.GJAllocationAmount > 0 then convert(money, GJAllocationAmount)
		else convert(money, 0.00)
	end as DebitAmount,
	case
		when g.GJAllocationAmount < 0 then convert(money, GJAllocationAmount * -1)
		else convert(money, 0.00)
	end as CreditAmount,
	j.GJEntryExpl as comment
from
	GJEntry j
	join GJAlloc g on j.GJEntryID = GJAllocationGJID
	join GLAcct a on g.GLAcctID = a.GLAcctID
	join TranIDX x on j.GJEntryID = x.TranIndexSequenceID
where
	x.TranIndexStatus = 0
union
all -- Entries to Bank Account GL - off by 4395.50 in Rcpts entries: 2515161, 2547418, 4152570, 4152612 have no GBAllocs so not in bank. -- AM
---------------------------------------------------------------------
2 - COMPLETED
---------------------------------------------------------------------
select
	'GBComm' as TableName,
	'PP' as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(GBankCommInfDate) as GLDate,
	Case
		when GBankCommInfEntryType in (1300, 1301, 1303) then convert(money, GBankCommInfAmount)
		else convert(money, 0.00)
	end as DebitAmount,
	Case
		when GBankCommInfEntryType in (1300, 1301, 1303) then convert(money, 0.00)
		else convert(money, GBankCommInfAmount)
	end as CreditAmount,
	GBankCommInfPaidTo as comment
from
	GBComm Comm
	join GBAcctI I on Comm.GBankCommInfAccountID = I.GBankAcctInfBankAccountID
	join GLAcct a on I.GBankAcctInfGLAccountID = a.GLAcctID
where
	GBankCommInfStatus = 0
	and GBankCommInfEntryType > 1200
	and GBankCommInfEntryType < 1500
union
all -- Retainer usages and payments - 
---------------------------------------------------------------------
3 - COMPLETED
---------------------------------------------------------------------
select
	'GBAlloc' as TableName,
	Case
		when GBankAllocInfEntryType in (1103) then 'RU'
		when GBankAllocInfEntryType in (1100, 1101, 1102, 1104) then 'PD'
		when GBankAllocInfEntryType in (2000, 2001) then 'TL' -- Tranaction Levy
		--when GBankAllocInfEntryType in (1200) then 'OB' -- Opening Balance
		else 'PP'
	end as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(GBankCommInfDate) as GLDate,
	--   Debit side for cheque entries
	Case
		when GBankAllocInfEntryType in (1400, 2001, 2000) then convert(money, GBankAllocInfAmount)
		else convert(money, 0.00)
	end as DebitAmount,
	--   Credit side for reciepts
	Case
		when GBankAllocInfEntryType in (1100, 1101, 1102, 1103, 1104, 1300, 1301) then convert(money, GBankAllocInfAmount)
		else convert(money, 0.00)
	end as CreditAmount,
	GBankAllocInfExplanation as comment
from
	GBAlloc Alloc
	join GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
	join GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
where
	GBankCommInfStatus = 0
	and GBankAllocInfENtryType not in (1600, 1650, 1651, 1652, 6500) -- Expense recoveries and tax entries and AP entries
	and GBankAllocInfEntryType not in (1803, 1899, 1200) -- 1899 are write offs and are done later, 1200 is an OB,
	and GBankCommInfEntryType not IN (1900, 1901, 1902, 1903, 1904, 1905) -- 1901,1902, and 1903,1904 are balance forwards in the suspense account
	and GBankAllocInfAmount <> 0
union
all -- Expense Recoveries
---------------------------------------------------------------------
4 - COMPLETED
---------------------------------------------------------------------
select
	'GBAlloc' as TableName,
	'CER' as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(GBankCommInfDate) as GLDate,
	convert(money, 0.00) as DebitAmount,
	convert(money, GBankAllocInfAmount) as CreditAmount,
	GBankAllocInfExplanation as comment
from
	GBAlloc Alloc
	join GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
	join GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
	left join TranIDX t on Alloc.GBankAllocInfAllocID = t.TranIndexSequenceID
where
	TranIndexStatus = 0 --and t.MatterID <> 0
	and GBankAllocInfEntryType in (1400, 1600)
	and alloc.MatterID <> 0
union
all -- Expense Recoveries into the 1210 Account (summary of all CER types)
---------------------------------------------------------------------
5 - COMPLETED
---------------------------------------------------------------------
select
	'GBAlloc' as TableName,
	'CER' as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(GBankCommInfDate) as GLDate,
	convert(money, GBankAllocInfAmount) as DebitAmount,
	convert(money, 0.00) as CreditAmount,
	GBankAllocInfExplanation as comment
from
	GBAlloc Alloc
	join GLAcct a on a.GLAccountNickName = '12010'
	join GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
	left join TranIDX t on Alloc.GBankAllocInfAllocID = t.TranIndexSequenceID
where
	TranIndexStatus = 0 --and t.MatterID <> 0
	and GBankAllocInfEntryType in (1400, 1600)
	and alloc.MatterID <> 0
union
all -- Trust Details
---------------------------------------------------------------------
6 - COMPLETED
---------------------------------------------------------------------
select
	'TBComm' as TableName,
	Case
		when TBankCommInfEntryType in (2050, 2054) then 'TD'
		else 'TC'
	end as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(TBankCommInfDate) as GLDate,
	Case
		when TBankCommInfEntryType in (2050, 2054) then convert(money, TBankCommInfAmount)
		else convert(money, 0.00)
	end as DebitAmount,
	Case
		when TBankCommInfEntryType in (2050, 2054) then convert(money, 0.00)
		else convert(money, TBankCommInfAmount)
	end as CreditAmount,
	TBankCommInfPaidTo as comment
from
	TBComm Comm
	join TBAcctI I on Comm.TBankCommInfAccountID = I.TBankAcctInfBankAccountID
	join GLAcct a on I.TBankAcctInfGLAccountID = a.GLAcctID
where
	TBankCommInfStatus = 0
	and TBankCommInfEntryType not in (1552, 1553, 2501) -- not sure why this item is excluded from the reports
union
all -- Trust Details into the Trust Funds Owed Account (2100)
---------------------------------------------------------------------
7
---------------------------------------------------------------------
select
	'TBComm' as TableName,
	Case
		when TBankCommInfEntryType = 2050 then 'TD'
		else 'TC'
	end as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(TBankCommInfDate) as GLDate,
	Case
		when TBankAllocInfoEntryType in (2050, 2054) then convert(money, 0.00)
		else convert(money, TBankAllocInfoAmount)
	end as DebitAmount,
	Case
		when TBankAllocInfoEntryType in (2050, 2054) then convert(money, TBankAllocInfoAmount)
		else convert(money, 0.00)
	end as CreditAmount,
	TBankAllocInfExplanation as comment
from
	TBAlloc Alloc
	join GLAcct a on '23010' = a.GLAccountNickName
	join TBComm Comm on Alloc.TBankAllocInfoCheckID = Comm.TBankCommInfSequenceID
where
	TBankAllocInfoStatus = 0
	and TBankCommInfEntryType not in (1552, 1553, 2501) -- not sure why this item is excluded from the reports
union
all -- AP Details
---------------------------------------------------------------------
8
---------------------------------------------------------------------
select
	'GBAlloc',
	'AP' as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(APInvoiceEntryDate) as GLDate,
	--case when I.APInvoiceTotBasePST = I.APInvoiceTotPaid then 0 else Alloc.GBankAllocInfAmount end as DebitAmount,
	convert(money, Alloc.GBankAllocInfAmount) as DebitAmount,
	convert(money, 0.00) as CreditAmount,
	APInvoiceExpl as comment
from
	APInv I
	join GBAlloc Alloc on I.APInvoiceID = Alloc.GBankAllocInfCheckID
	join GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
	left join ActCode C on Alloc.GBankAllocInfActivityID = C.ActivityCodesID
	left join MattInf m on Alloc.MatterID = m.MatterID
where
	APInvoiceStatus = 0 --and I.APInvoiceTotBasePST <> 0
union
all -- Accounts Payable (Acct 2000)
---------------------------------------------------------------------
9
---------------------------------------------------------------------
select
	'GBAlloc',
	'AP' as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(APInvoiceEntryDate) as GLDate,
	convert(money, 0.00) as DebitAmount,
	convert(money, GBankAllocInfAmount) as CreditAmount,
	APInvoiceExpl as comment --select SUM(GBankAllocInfAmount)
from
	APInv I
	join GBAlloc Alloc on I.APInvoiceID = Alloc.GBankAllocInfCheckID
	join GLAcct a on '22010' = a.GLAccountNickName
	left join ActCode C on Alloc.GBankAllocInfActivityID = C.ActivityCodesID
	left join MattInf m on Alloc.MatterID = m.MatterID
where
	APInvoiceStatus = 0
union
all -- Matter Specific AP Items
---------------------------------------------------------------------
10
---------------------------------------------------------------------
select
	'GBAlloc',
	'AP' as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(APInvoiceEntryDate) as GLDate,
	--case when I.APInvoiceTotBasePST = I.APInvoiceTotPaid then 0 else Alloc.GBankAllocInfAmount end as DebitAmount,
	convert(money, 0.00) as DebitAmount,
	convert(money, Alloc.GBankAllocInfAmount) as CreditAmount,
	APInvoiceExpl as comment
from
	APInv I
	join GBAlloc Alloc on I.APInvoiceID = Alloc.GBankAllocInfCheckID
	join GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
	left join ActCode C on Alloc.GBankAllocInfActivityID = C.ActivityCodesID
	left join MattInf m on Alloc.MatterID = m.MatterID
where
	APInvoiceStatus = 0
	and m.MatterID <> 0
union
all -- Matter Specific AP Items into the 1210 account (Client Disb Recoverable)
---------------------------------------------------------------------
11
---------------------------------------------------------------------
select
	'GBAlloc',
	'AP' as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(APInvoiceEntryDate) as GLDate,
	--case when I.APInvoiceTotBasePST = I.APInvoiceTotPaid then 0 else Alloc.GBankAllocInfAmount end as DebitAmount,
	convert(money, Alloc.GBankAllocInfAmount) as DebitAmount,
	convert(money, 0.00) as CreditAmount,
	APInvoiceExpl as comment
from
	APInv I
	join GBAlloc Alloc on I.APInvoiceID = Alloc.GBankAllocInfCheckID
	join GLAcct a on a.GLAccountNickName = '12010'
	left join ActCode C on Alloc.GBankAllocInfActivityID = C.ActivityCodesID
	left join MattInf m on Alloc.MatterID = m.MatterID
where
	APInvoiceStatus = 0
	and m.MatterID <> 0
union
all -- Fee Accounts
---------------------------------------------------------------------
12
---------------------------------------------------------------------
select
	'ARLwySpl',
	'AR',
	gl.GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(ARLawyerSplitDate),
	convert(money, 0.00) as DebitAmount,
	convert(money, ARLawyerSplitAmount) as CreditAmount,
	'Fees - ' + l.LawInfNickName
from
	dbo.ARInv i
	join dbo.ARLwySpl s on i.InvoiceID = s.InvoiceID
	join GLAcct gl on s.ARLawyerSplitLawyerID = gl.GLAccountForLawyer
	and gl.GLAccountSpecAcct = 13
	and gl.GLAccountStatus = 0
	join LawInf l on s.ARLawyerSplitLawyerID = l.LawyerID
where
	i.ARInvoiceStatus = 0
	and ARLawyerSplitEntryType = 3
	and ARLawyerSplitStatus = 0
union
all -- Fees AR account (1200)
---------------------------------------------------------------------
13
---------------------------------------------------------------------
select
	'ARLwySpl',
	'AR',
	GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(ARLawyerSplitDate),
	convert(money, ARLawyerSplitAmount) as DebitAmount,
	convert(money, 0.00) as CreditAmount,
	'Fees - ' + l.LawInfNickName
from
	dbo.ARInv i
	join dbo.ARLwySpl s on i.InvoiceID = s.InvoiceID
	join GLAcct gl on gl.GLAccountNickName = '12020'
	join LawInf l on s.ARLawyerSplitLawyerID = l.LawyerID
where
	i.ARInvoiceStatus = 0
	and ARLawyerSplitEntryType = 3
	and ARLawyerSplitStatus = 0
	and ARLawyerSplitAmount <> 0
union
all -- Write offs (per Lawyer AND per account - includes write-offs to all accounts)
---------------------------------------------------------------------
14
---------------------------------------------------------------------
select
	'ARLwySpl',
	'WO',
	s.ARLawyerSplitGLID as GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(ARLawyerSplitDate),
	convert(money, ARLawyerSplitAmount * -1.0) as DebitAmount,
	convert(money, 0.00) as CreditAmount,
	wo.ARWriteOffExplanation
from
	dbo.ARInv i
	join dbo.ARLwySpl s on i.InvoiceID = s.InvoiceID
	join TranIDX t on s.WOID = t.TranIndexSequenceID
	join GLAcct gl on s.ARLawyerSplitGLID = gl.GLAcctID
	left join LawInf l on s.ARLawyerSplitLawyerID = l.LawyerID
	join ARWO wo on s.WOID = wo.WOID
where
	t.TranIndexStatus = 0
union
all -- Write offs per Lawyer for 1200 Account
---------------------------------------------------------------------
15
---------------------------------------------------------------------
select
	'ARLwySpl',
	'WO',
	GLAcctID as GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(ARLawyerSplitDate),
	convert(money, 0.00) as DebitAmount,
	convert(money, ARLawyerSplitAmount * -1.0) as CreditAmount,
	wo.ARWriteOffExplanation
from
	dbo.ARInv i
	join dbo.ARLwySpl s on i.InvoiceID = s.InvoiceID
	join TranIDX t on s.WOID = t.TranIndexSequenceID
	join GLAcct gl on gl.GLAccountNickName = '12020'
	left join LawInf l on s.ARLawyerSplitLawyerID = l.LawyerID
	join ARWO wo on s.WOID = wo.WOID
where
	t.TranIndexStatus = 0
union
all -- AR Invoiced Disbs to 1200 Acct
---------------------------------------------------------------------
16
---------------------------------------------------------------------
select
	'ARInv',
	'AR Disbs',
	GLAcctID as GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(i.ARInvoiceDate),
	convert(money, i.ARInvoiceDisbs) as DebitAmount,
	convert(money, 0.00) as CreditAmount,
	'AR Invoice Disbs for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber)
from
	ARInv i
	join GLAcct gl on gl.GLAccountNickName = '12020'
where
	i.ARInvoiceStatus = 0
	and i.ARInvoiceDisbs <> 0
union
all -- AR Invoiced HST Fees to 1200 Acct
---------------------------------------------------------------------
17
---------------------------------------------------------------------
select
	'ARInv',
	'AR HST Fees',
	GLAcctID as GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(i.ARInvoiceDate),
	convert(money, i.ARInvoiceGSTFees) as DebitAmount,
	convert(money, 0.00) as CreditAmount,
	'AR Invoice HST Fees for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber)
from
	ARInv i
	join GLAcct gl on gl.GLAccountNickName = '12020'
where
	i.ARInvoiceStatus = 0
	and i.ARInvoiceGSTFees <> 0
union
all -- AR Invoiced HST Disbs to 1200 Acct
---------------------------------------------------------------------
18
---------------------------------------------------------------------
select
	'ARInv',
	'AR HST Disbs',
	GLAcctID as GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(i.ARInvoiceDate),
	convert(money, i.ARInvoiceGSTDisbs) as DebitAmount,
	convert(money, 0.00) as CreditAmount,
	'AR Invoice HST Disbs for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber)
from
	ARInv i
	join GLAcct gl on gl.GLAccountNickName = '12020'
where
	i.ARInvoiceStatus = 0
	and i.ARInvoiceGSTDisbs <> 0
union
all -- AR Invoiced HST Fees to 2400 Acct
---------------------------------------------------------------------
19
---------------------------------------------------------------------
select
	'ARInv',
	'AR HST Fees',
	GLAcctID as GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(i.ARInvoiceDate),
	convert(money, 0.00) as DebitAmount,
	convert(money, i.ARInvoiceGSTFees) as CreditAmount,
	'AR Invoice HST Fees for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber)
from
	ARInv i
	join GLAcct gl on gl.GLAccountNickName = '22060'
where
	i.ARInvoiceStatus = 0
	and i.ARInvoiceGSTFees <> 0
union
all -- AR Invoiced HST Fees to 2400 Acct
---------------------------------------------------------------------
20
---------------------------------------------------------------------
select
	'ARInv',
	'AR HST Disbs',
	GLAcctID as GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(i.ARInvoiceDate),
	convert(money, 0.00) as DebitAmount,
	convert(money, i.ARInvoiceGSTDisbs) as CreditAmount,
	'AR Invoice HST Disbs for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber)
from
	ARInv i
	join GLAcct gl on gl.GLAccountNickName = '22060'
where
	i.ARInvoiceStatus = 0
	and i.ARInvoiceGSTDisbs <> 0
union
all -- AR Retainers Used to 1200 Acct
---------------------------------------------------------------------
21
---------------------------------------------------------------------
select
	'GBRcptA',
	'AR Retainer Usage',
	GLAcctID as GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(r.GBankARRcptAllocDate),
	convert(money, 0.00) as DebitAmount,
	convert(money, r.GBankARRcptAllocAmount) as CreditAmount,
	'AR Invoice Retainers Used for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber)
from
	ARInv i
	join GBRcptA r on i.InvoiceID = r.GBankARRcptAllocInvID
	join GLAcct gl on gl.GLAccountNickName = '12020' -- join GLAcct gl on gl.GLAcctID = 9
where
	i.ARInvoiceStatus = 0
	and GBankARRcptAllocEntryType = 6
union
all -- AR Invoiced Disbs to 1210 Acct
---------------------------------------------------------------------
22
---------------------------------------------------------------------
select
	'ARInv',
	'AR Disbs',
	GLAcctID as GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(i.ARInvoiceDate),
	convert(money, 0.00) as DebitAmount,
	convert(money, i.ARInvoiceDisbs) as CreditAmount,
	'AR Invoice Disbs for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber)
from
	ARInv i
	join GLAcct gl on gl.GLAccountNickName = '12010'
where
	i.ARInvoiceStatus = 0
	and i.ARInvoiceDisbs <> 0
union
all -- AR Retainers Used to 1210 Acct
---------------------------------------------------------------------
23
---------------------------------------------------------------------
select
	'GBRcptA',
	'AR Retainer Usage',
	GLAcctID as GLAcctID,
	gl.GLAccountAcctName,
	gl.GLAccountNickName,
	gl.GLAccountStatus,
	gl.GLAccountCategory,
	(r.GBankARRcptAllocDate),
	convert(money, r.GBankARRcptAllocAmount) as DebitAmount,
	convert(money, 0.00) as CreditAmount,
	'AR Invoice Retainers Used for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber) as Comment
from
	ARInv i
	join GBRcptA r on i.InvoiceID = r.GBankARRcptAllocInvID
	join GLAcct gl on gl.GLAccountNickName = '12010'
where
	i.ARInvoiceStatus = 0
	and GBankARRcptAllocEntryType = 2
union
all -- TransLevy Payments (Total Trans Levy) -- Acct 2460
---------------------------------------------------------------------
24
---------------------------------------------------------------------
select
	'GBAlloc' as TableName,
	Case
		when GBankAllocInfEntryType in (1103) then 'RU'
		when GBankAllocInfEntryType in (1104) then 'PD'
		when GBankAllocInfEntryType in (2000, 2001) then 'TL'
		else 'PP'
	end as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(GBankCommInfDate) as GLDate,
	convert(money, 0.00) as DebitAmount,
	convert(money, GBankAllocInfAmount) as CreditAmount,
	GBankAllocInfExplanation as comment
from
	GBAlloc Alloc
	join GLAcct a on a.GLAccountNickName = '22070'
	join GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
where
	GBankAllocInfStatus = 0
	and GBankAllocInfEntryType in (2000, 2001) -- Only TL
union
all -- TransLevy Recovery into 5300 account - NM Good
---------------------------------------------------------------------
25
---------------------------------------------------------------------
select
	'GBAlloc' as TableName,
	Case
		when GBankAllocInfEntryType in (1103) then 'RU'
		when GBankAllocInfEntryType in (1104) then 'PD'
		when GBankAllocInfEntryType in (2000, 2001) then 'TL'
		else 'PP'
	end as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(GBankCommInfDate) as GLDate,
	convert(money, 0.00) as DebitAmount,
	convert(money, GBankAllocInfAmount) as CreditAmount,
	GBankAllocInfExplanation as comment
from
	GBAlloc Alloc
	join GLAcct a on a.GLAccountNickName = '47012'
	join GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
where
	GBankAllocInfStatus = 0
	and GBankAllocInfEntryType in (2000, 2001) -- Only TL
union
all -- TransLevy Total into 5300 account
---------------------------------------------------------------------
26
---------------------------------------------------------------------
select
	'GBAlloc' as TableName,
	Case
		when GBankAllocInfEntryType in (1103) then 'RU'
		when GBankAllocInfEntryType in (1104) then 'PD'
		when GBankAllocInfEntryType in (2000, 2001) then 'TL'
		else 'PP'
	end as Journal,
	a.GLAcctID,
	a.GLAccountAcctName,
	a.GLAccountNickName,
	a.GLAccountStatus,
	a.GLAccountCategory,
	(GBankCommInfDate) as GLDate,
	convert(money, GBankAllocInfAmount) as DebitAmount,
	convert(money, 0.00) as CreditAmount,
	GBankAllocInfExplanation as comment
from
	GBAlloc Alloc
	join GLAcct a on a.GLAccountNickName = '47012'
	join GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
where
	GBankAllocInfStatus = 0
	and GBankAllocInfEntryType in (2000, 2001) -- Only TL
GO
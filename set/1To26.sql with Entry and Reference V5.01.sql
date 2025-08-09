/****** Object:  View [dbo].[PCLaw_GeneralLedger_Details]    Script Date: 08/15/2012 09:03:07 ******/
SELECT
	*
	--SUM(DebitAmount), SUM(CreditAmount)
FROM
	(
		select
		    '1' as Sno,
			'GJEntry' as TableName,
			'GJ' as Journal,
			a.GLAcctID,
			a.GLAccountAcctName,
			a.GLAccountNickName,
			a.GLAccountStatus,
			a.GLAccountCategory,
			(j.GJEntryDate) as GLDate,
			case
				when g.GJAllocationAmount > 0 then ABS(convert(money, GJAllocationAmount))
				else convert(money, 0.00)
			end as DebitAmount,
			case
				when g.GJAllocationAmount < 0 then ABS(convert(money, GJAllocationAmount))
				else convert(money, 0.00)
			end as CreditAmount,
			j.GJEntryExpl as comment,
			'Journal Entry' as GBankCommInfPaidTo,
			j.GJEntryRef as ReferenceNumber,
			j.GJEntryID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].GJEntry j
			join [PCLAWDB_32130].[dbo].GJAlloc g on j.GJEntryID = GJAllocationGJID
			join [PCLAWDB_32130].[dbo].GLAcct a on g.GLAcctID = a.GLAcctID
			join [PCLAWDB_32130].[dbo].TranIDX x on j.GJEntryID = x.TranIndexSequenceID 
			where x.TranIndexStatus = 0
			--2
		union
		all -- Entries to Bank Account GL - off by 4395.50 in Rcpts entries: 2515161, 2547418, 4152570, 4152612 have no GBAllocs so not in bank. -- AM
		select
		 '2' as Sno,
			'GBComm' as TableName,
			'GB' as Journal,
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
			--Alloc.GBankAllocInfExplanation as comment,
			'' as comment,
			comm.GBankCommInfPaidTo,
			Comm.GBankCommInfCheck as ReferenceNumber,
			Comm.GBankCommInfID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].GBComm Comm
			join [PCLAWDB_32130].[dbo].GBAcctI I on Comm.GBankCommInfAccountID = I.GBankAcctInfBankAccountID
			join [PCLAWDB_32130].[dbo].GLAcct a on I.GBankAcctInfGLAccountID = a.GLAcctID
			--join (select GBankAllocInfCheckID, GBankAllocInfExplanation from [PCLAWDB_32130].[dbo].GBAlloc group by GBankAllocInfCheckID, GBankAllocInfExplanation) Alloc 
			--on Comm.GBankCommInfID = Alloc.GBankAllocInfCheckID
			where GBankCommInfStatus = 0 and GBankCommInfEntryType >1200 and GBankCommInfEntryType <1500 
			--3
		union
		all -- Retainer usages and payments - 
		select
		'3' as Sno,
			'GBAlloc' as TableName,
			Case
				when GBankAllocInfEntryType in (1103) then 'RU'
				when GBankAllocInfEntryType in (1100, 1101, 1102, 1104) then 'GB'
				when GBankAllocInfEntryType in (2000, 2001) then 'TL' -- Tranaction Levy
				--when GBankAllocInfEntryType in (1200) then 'OB' -- Opening Balance
				else 'GB'
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
			GBankAllocInfExplanation as comment,
			comm.GBankCommInfPaidTo,
			Comm.GBankCommInfCheck as ReferenceNumber,
			Comm.GBankCommInfID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].GBAlloc Alloc
			join [PCLAWDB_32130].[dbo].GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
			join [PCLAWDB_32130].[dbo].GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
			where  GBankCommInfStatus = 0 
			and GBankAllocInfENtryType not in (1600, 1650, 1651, 1652, 6500) -- Expense recoveries and tax entries and AP entries
			and GBankAllocInfEntryType not in (1803,1899,1200) -- 1899 are write offs and are done later, 1200 is an OB,
			and GBankCommInfEntryType not IN (1900,1901,1902,1903,1904,1905) -- 1901,1902, and 1903,1904 are balance forwards in the suspense account
			and GBankAllocInfAmount<>0 
			--4
		union
		all -- Expense Recoveries
		select
		'4' as Sno,
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
			GBankAllocInfExplanation as comment,
			comm.GBankCommInfPaidTo,
			comm.GBankCommInfCheck as ReferenceNumber,
			Alloc.GBankAllocInfAllocID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].GBAlloc Alloc
			join [PCLAWDB_32130].[dbo].GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
			join [PCLAWDB_32130].[dbo].GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
			left join [PCLAWDB_32130].[dbo].TranIDX t on Alloc.GBankAllocInfAllocID = t.TranIndexSequenceID 
			where TranIndexStatus = 0 --and t.MatterID <> 0
			and GBankAllocInfEntryType in (1400,1600)
			and alloc.MatterID<>0
			--5
		union
		all -- Expense Recoveries into the 1210 Account (summary of all CER types)
		select
		'5' as Sno,
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
			GBankAllocInfExplanation as comment,
			comm.GBankCommInfPaidTo,
			comm.GBankCommInfCheck as ReferenceNumber,
			Alloc.GBankAllocInfAllocID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].GBAlloc Alloc
			join [PCLAWDB_32130].[dbo].GLAcct a on a.GLAccountNickName = '12010'
			join [PCLAWDB_32130].[dbo].GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
			left join [PCLAWDB_32130].[dbo].TranIDX t on Alloc.GBankAllocInfAllocID = t.TranIndexSequenceID 
			where TranIndexStatus = 0 --and t.MatterID <> 0
			and GBankAllocInfEntryType in (1400,1600)
			and alloc.MatterID<>0
			--6
		union
		all -- Trust Details
		select
		'6' as Sno,
			'TBComm' as TableName,
			'TB' as Journal,
			a.GLAcctID,
			a.GLAccountAcctName,
			a.GLAccountNickName,
			a.GLAccountStatus,
			a.GLAccountCategory,
			(TBankCommInfDate) as GLDate,
			Case
				when TBankCommInfEntryType in (2050, 2054) or (TBankCommInfEntryType not in (2050, 2054) AND TBankAllocInfoAmount < 0) 
				then convert(money, ABS(TBankAllocInfoAmount))
				else convert(money, 0.00)
			end as DebitAmount,
			Case
				when TBankCommInfEntryType not in (2050, 2054) AND TBankAllocInfoAmount >= 0 then convert(money, TBankAllocInfoAmount)
				else convert(money, 0.00)
			end as CreditAmount,
			Alloc.TBankAllocInfExplanation as comment,
			TBankCommInfPaidTo as GBankCommInfPaidTo,
			Comm.TBankCommInfCheck as ReferenceNumber,
			Comm.TBankCommInfSequenceID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].TBComm Comm
			join [PCLAWDB_32130].[dbo].TBAcctI I on Comm.TBankCommInfAccountID = I.TBankAcctInfBankAccountID
			join [PCLAWDB_32130].[dbo].GLAcct a on I.TBankAcctInfGLAccountID = a.GLAcctID
			join [PCLAWDB_32130].[dbo].TBAlloc Alloc on Alloc.TBankAllocInfoCheckID = Comm.TBankCommInfSequenceID 
			where TBankCommInfStatus = 0 and TBankCommInfEntryType not in (1552, 1553, 2501) -- not sure why this item is excluded from the reports
			--7
		union
		all -- Trust Details into the Trust Funds Owed Account (2100)
		select
		'7' as Sno,
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
			TBankAllocInfExplanation as comment,
			TBankCommInfPaidTo as GBankCommInfPaidTo,
			Comm.TBankCommInfCheck as ReferenceNumber,
			Comm.TBankCommInfSequenceID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].TBAlloc Alloc
			join [PCLAWDB_32130].[dbo].GLAcct a on '23010' = a.GLAccountNickName
			join [PCLAWDB_32130].[dbo].TBComm Comm on Alloc.TBankAllocInfoCheckID = Comm.TBankCommInfSequenceID 
			where TBankAllocInfoStatus = 0 and TBankCommInfEntryType not in (1552, 1553, 2501) -- not sure why this item is excluded from the reports
			--8
		/*union
		all -- AP Details
		select
		'8' as Sno,
			'GBAlloc',
			'AP1' as Journal,
			a.GLAcctID,
			a.GLAccountAcctName,
			a.GLAccountNickName,
			a.GLAccountStatus,
			a.GLAccountCategory,
			(APInvoiceEntryDate) as GLDate,
			--case when I.APInvoiceTotBasePST = I.APInvoiceTotPaid then 0 else Alloc.GBankAllocInfAmount end as DebitAmount,
			convert(money, Alloc.GBankAllocInfAmount) as DebitAmount,
			convert(money, 0.00) as CreditAmount,
			APInvoiceExpl as comment,
			v.APVendorListSortName as GBankCommInfPaidTo,
			I.APInvoiceInvNumr as ReferenceNumber,
			I.APInvoiceID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].APInv I
			join [PCLAWDB_32130].[dbo].GBAlloc Alloc on I.APInvoiceID = Alloc.GBankAllocInfCheckID
			join [PCLAWDB_32130].[dbo].GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
			left join [PCLAWDB_32130].[dbo].ActCode C on Alloc.GBankAllocInfActivityID = C.ActivityCodesID
			left join [PCLAWDB_32130].[dbo].MattInf m on Alloc.MatterID = m.MatterID 
			left join [PCLAWDB_32130].[dbo].APVendLi v on I.APInvoiceVendorID = v.APVendorListID
			where APInvoiceStatus = 0 --and I.APInvoiceTotBasePST <> 0
			--9
		union
		all -- Accounts Payable (Acct 2000)
		select
		'9' as Sno,
			'GBAlloc',
			'AP2' as Journal,
			a.GLAcctID,
			a.GLAccountAcctName,
			a.GLAccountNickName,
			a.GLAccountStatus,
			a.GLAccountCategory,
			(APInvoiceEntryDate) as GLDate,
			convert(money, 0.00) as DebitAmount,
			convert(money, GBankAllocInfAmount) as CreditAmount,
			APInvoiceExpl as comment,
			v.APVendorListSortName as GBankCommInfPaidTo,
			I.APInvoiceInvNumr as ReferenceNumber,
			I.APInvoiceID as EntryNumber --select SUM(GBankAllocInfAmount)
		from
			[PCLAWDB_32130].[dbo].APInv I
			join [PCLAWDB_32130].[dbo].GBAlloc Alloc on I.APInvoiceID = Alloc.GBankAllocInfCheckID
			join [PCLAWDB_32130].[dbo].GLAcct a on '5010' = a.GLAccountNickName
			left join [PCLAWDB_32130].[dbo].ActCode C on Alloc.GBankAllocInfActivityID = C.ActivityCodesID
			left join [PCLAWDB_32130].[dbo].MattInf m on Alloc.MatterID = m.MatterID
			left join [PCLAWDB_32130].[dbo].APVendLi v on I.APInvoiceVendorID = v.APVendorListID
			where APInvoiceStatus = 0
			--10*/
		union
		all -- Matter Specific AP Items
		select
		'10' as Sno,
			'GBAlloc',
			'AP3' as Journal,
			a.GLAcctID,
			a.GLAccountAcctName,
			a.GLAccountNickName,
			a.GLAccountStatus,
			a.GLAccountCategory,
			(APInvoiceEntryDate) as GLDate,
			--case when I.APInvoiceTotBasePST = I.APInvoiceTotPaid then 0 else Alloc.GBankAllocInfAmount end as DebitAmount,
			convert(money, 0.00) as DebitAmount,
			convert(money, Alloc.GBankAllocInfAmount) as CreditAmount,
			APInvoiceExpl as comment,
			v.APVendorListSortName as GBankCommInfPaidTo,
			I.APInvoiceInvNumr as ReferenceNumber,
			I.APInvoiceID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].APInv I
			join [PCLAWDB_32130].[dbo].GBAlloc Alloc on I.APInvoiceID = Alloc.GBankAllocInfCheckID
			join [PCLAWDB_32130].[dbo].GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
			left join [PCLAWDB_32130].[dbo].ActCode C on Alloc.GBankAllocInfActivityID = C.ActivityCodesID
			left join [PCLAWDB_32130].[dbo].MattInf m on Alloc.MatterID = m.MatterID 
			left join [PCLAWDB_32130].[dbo].APVendLi v on I.APInvoiceVendorID = v.APVendorListID
			where APInvoiceStatus = 0 and m.MatterID <> 0
			--11
		/*union
		all -- Matter Specific AP Items into the 1210 account (Client Disb Recoverable)
		select
		'11' as Sno,
			'GBAlloc',
			'AP4' as Journal,
			a.GLAcctID,
			a.GLAccountAcctName,
			a.GLAccountNickName,
			a.GLAccountStatus,
			a.GLAccountCategory,
			(APInvoiceEntryDate) as GLDate,
			--case when I.APInvoiceTotBasePST = I.APInvoiceTotPaid then 0 else Alloc.GBankAllocInfAmount end as DebitAmount,
			convert(money, Alloc.GBankAllocInfAmount) as DebitAmount,
			convert(money, 0.00) as CreditAmount,
			APInvoiceExpl as comment,
			v.APVendorListSortName as GBankCommInfPaidTo,
			I.APInvoiceInvNumr as ReferenceNumber,
			I.APInvoiceID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].APInv I
			join [PCLAWDB_32130].[dbo].GBAlloc Alloc on I.APInvoiceID = Alloc.GBankAllocInfCheckID
			join [PCLAWDB_32130].[dbo].GLAcct a on a.GLAccountNickName = '5010'
			left join [PCLAWDB_32130].[dbo].ActCode C on Alloc.GBankAllocInfActivityID = C.ActivityCodesID
			left join [PCLAWDB_32130].[dbo].MattInf m on Alloc.MatterID = m.MatterID
			left join [PCLAWDB_32130].[dbo].APVendLi v on I.APInvoiceVendorID = v.APVendorListID
			where APInvoiceStatus = 0 and m.MatterID <> 0
			--12*/
		union
		all -- Fee Accounts
		select
		'12' as Sno,
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
			'Fees - ' + l.LawInfNickName,
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].ARLwySpl s on i.InvoiceID = s.InvoiceID
			join [PCLAWDB_32130].[dbo].GLAcct gl on s.ARLawyerSplitLawyerID = gl.GLAccountForLawyer
			and gl.GLAccountSpecAcct = 13
			and gl.GLAccountStatus = 0
			join [PCLAWDB_32130].[dbo].LawInf l on s.ARLawyerSplitLawyerID = l.LawyerID --where i.ARInvoiceStatus = 0  and ARLawyerSplitEntryType=3 and ARLawyerSplitStatus=0
			--13
		union
		all -- Fees AR account (1200)
		select
		'13' as Sno,
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
			'Fees - ' + l.LawInfNickName,
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].ARLwySpl s on i.InvoiceID = s.InvoiceID
			join [PCLAWDB_32130].[dbo].GLAcct gl on gl.GLAccountNickName = '12020'
			join [PCLAWDB_32130].[dbo].LawInf l on s.ARLawyerSplitLawyerID = l.LawyerID --where i.ARInvoiceStatus = 0 and ARLawyerSplitEntryType=3 and ARLawyerSplitStatus=0 and ARLawyerSplitAmount<>0
			--14
		union
		all -- Write offs (per Lawyer AND per account - includes write-offs to all accounts)
		select
		'14' as Sno,
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
			wo.ARWriteOffExplanation,
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].ARLwySpl s on i.InvoiceID = s.InvoiceID
			join [PCLAWDB_32130].[dbo].TranIDX t on s.WOID = t.TranIndexSequenceID
			join [PCLAWDB_32130].[dbo].GLAcct gl on s.ARLawyerSplitGLID = gl.GLAcctID
			left join [PCLAWDB_32130].[dbo].LawInf l on s.ARLawyerSplitLawyerID = l.LawyerID
			join [PCLAWDB_32130].[dbo].ARWO wo on s.WOID = wo.WOID --where t.TranIndexStatus = 0
			--15
		union
		all -- Write offs per Lawyer for 1200 Account
		select
		'15' as Sno,
			'ARLwySpl',
			'WO',
			GLAcctID as GLAcctID,
			gl.GLAccountAcctName,
			gl.GLAccountNickName,
			gl.GLAccountStatus,
			gl.GLAccountCategory,
			(ARLawyerSplitDate),
			convert(money, 0.00) as DebitAmount,
			convert(money, ARLawyerSplitAmount * -1) as CreditAmount,
			wo.ARWriteOffExplanation,
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].ARLwySpl s on i.InvoiceID = s.InvoiceID
			join [PCLAWDB_32130].[dbo].TranIDX t on s.WOID = t.TranIndexSequenceID
			join [PCLAWDB_32130].[dbo].GLAcct gl on gl.GLAccountNickName = '12020'
			left join [PCLAWDB_32130].[dbo].LawInf l on s.ARLawyerSplitLawyerID = l.LawyerID
			join [PCLAWDB_32130].[dbo].ARWO wo on s.WOID = wo.WOID --where t.TranIndexStatus = 0
			--16
		union
		all -- AR Invoiced Disbs to 1200 Acct
		select
		'16' as Sno,
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
			'AR Invoice Disbs for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber),
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].GLAcct gl on gl.GLAccountNickName = '12020' --where i.ARInvoiceStatus = 0 and i.ARInvoiceDisbs <> 0
			--17
		union
		all -- AR Invoiced HST Fees to 1200 Acct
		select
		'17' as Sno,
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
			'AR Invoice HST Fees for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber),
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].GLAcct gl on gl.GLAccountNickName = '12020' --where i.ARInvoiceStatus = 0 and i.ARInvoiceGSTFees <> 0
			--18
		union
		all -- AR Invoiced HST Disbs to 1200 Acct
		select
		'18' as Sno,
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
			'AR Invoice HST Disbs for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber),
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].GLAcct gl on gl.GLAccountNickName = '12020' --where i.ARInvoiceStatus = 0 and i.ARInvoiceGSTDisbs <> 0
			--19
		union
		all -- AR Invoiced HST Fees to 2400 Acct
		select
		'19' as Sno,
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
			'AR Invoice HST Fees for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber),
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].GLAcct gl on gl.GLAccountNickName = '22060' --where i.ARInvoiceStatus = 0 and i.ARInvoiceGSTFees <> 0
			--20
		union
		all -- AR Invoiced HST Fees to 2400 Acct
		select
		'20' as Sno,
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
			'AR Invoice HST Disbs for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber),
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].GLAcct gl on gl.GLAccountNickName = '22060' --where i.ARInvoiceStatus = 0 and i.ARInvoiceGSTDisbs <> 0
			--21
		union
		all -- AR Retainers Used to 1200 Acct
		select
		'21' as Sno,
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
			'AR Invoice Retainers Used for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber),
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].GBRcptA r on i.InvoiceID = r.GBankARRcptAllocInvID
			join [PCLAWDB_32130].[dbo].GLAcct gl on gl.GLAccountNickName = '12020' -- join GLAcct gl on gl.GLAcctID = 9
			--where i.ARInvoiceStatus = 0 and GBankARRcptAllocEntryType = 6
			--22
		union
		all -- AR Invoiced Disbs to 1210 Acct
		select
		'22' as Sno,
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
			'AR Invoice Disbs for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber),
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].GLAcct gl on gl.GLAccountNickName = '12010' --where i.ARInvoiceStatus = 0 and i.ARInvoiceDisbs <> 0
			--23
		union
		all -- AR Retainers Used to 1210 Acct
		select
		'23' as Sno,
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
			'AR Invoice Retainers Used for Invoice: ' + convert(varchar(25), i.ARInvoiceInvNumber) as Comment,
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].ARInv i
			join [PCLAWDB_32130].[dbo].GBRcptA r on i.InvoiceID = r.GBankARRcptAllocInvID
			join [PCLAWDB_32130].[dbo].GLAcct gl on gl.GLAccountNickName = '12010' --where i.ARInvoiceStatus = 0 and GBankARRcptAllocEntryType = 2
			--24
		union
		all -- TransLevy Payments (Total Trans Levy) -- Acct 2460
		select
		'24' as Sno,
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
			GBankAllocInfExplanation as comment,
			comm.GBankCommInfPaidTo,
			Comm.GBankCommInfCheck as ReferenceNumber,
			Comm.GBankCommInfID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].GBAlloc Alloc
			join [PCLAWDB_32130].[dbo].GLAcct a on a.GLAccountNickName = '22070'
			join [PCLAWDB_32130].[dbo].GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID --where GBankAllocInfStatus = 0 
			--	and GBankAllocInfEntryType in (2000,2001) -- Only TL
			--25
		union
		all -- TransLevy Recovery into 5300 account - NM Good
		select
		'25' as Sno,
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
			GBankAllocInfExplanation as comment,
			comm.GBankCommInfPaidTo,
			Comm.GBankCommInfCheck as ReferenceNumber,
			Comm.GBankCommInfID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].GBAlloc Alloc
			join [PCLAWDB_32130].[dbo].GLAcct a on a.GLAccountNickName = '47012'
			join [PCLAWDB_32130].[dbo].GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID --where GBankAllocInfStatus = 0 
			--	and GBankAllocInfEntryType in (2000,2001) -- Only TL
			--26
		union
		all -- TransLevy Total into 5300 account
		select
		'26' as Sno,
			'GBAlloc' as TableName,
			Case
				when Alloc.GBankAllocInfEntryType in (1103) then 'RU'
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
			GBankAllocInfExplanation as comment,
			comm.GBankCommInfPaidTo,
			Comm.GBankCommInfCheck as ReferenceNumber,
			Comm.GBankCommInfID as EntryNumber
		from
			[PCLAWDB_32130].[dbo].GBAlloc Alloc
			join [PCLAWDB_32130].[dbo].GLAcct a on a.GLAccountNickName = '47012'
			join [PCLAWDB_32130].[dbo].GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
		where
			GBankAllocInfStatus = 0
			and GBankAllocInfEntryType in (2000, 2001) -- Only TL
	) AS T --group by t.Journal
where
	--ReferenceNumber = '211940'
	--GLAccountNickName = '2100'
	--t.Entrynumber = 1923312
	T.Journal = 'GB' and
	t.ReferenceNumber = '211819'and	
	T.GLDate BETWEEN 20240101 AND 20240131
	-- T.GLDate BETWEEN 20240101 AND 20240131 AND T.ReferenceNumber IN ('23133094', '23132901', '23132048', '12/05/23')
	--ORDER BY T.ReferenceNumber ASC
	--GROUP BY T.TableName, T.Journal, T.GLAcctID, T.GLAccountAcctName, T.GLAccountNickName, T.GLAccountStatus, T.GLAccountCategory, T.
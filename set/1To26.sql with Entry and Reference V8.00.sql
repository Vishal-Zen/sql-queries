/****** Object:  View [dbo].[PCLaw_GeneralLedger_Details]    Script Date: 08/15/2012 09:03:07 ******/
SELECT * 
	--SUM(DebitAmount), SUM(CreditAmount), SUM(DebitAmount)-SUM(CreditAmount) AS TB_amount
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
        where
            x.TranIndexStatus = 0 --2
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
            CASE
                WHEN GBankCommInfEntryType IN (1300, 1301, 1303)
                AND GBankCommInfAmount >= 0 THEN CONVERT(money, GBankCommInfAmount)
                WHEN GBankCommInfEntryType NOT IN (1300, 1301, 1303)
                AND GBankCommInfAmount < 0 THEN ABS(CONVERT(money, GBankCommInfAmount))
                ELSE 0.00
            END AS DebitAmount,
            -- CreditAmount logic
            CASE
                WHEN GBankCommInfEntryType NOT IN (1300, 1301, 1303)
                AND GBankCommInfAmount >= 0 THEN CONVERT(money, GBankCommInfAmount)
                WHEN GBankCommInfEntryType IN (1300, 1301, 1303)
                AND GBankCommInfAmount < 0 THEN ABS(CONVERT(money, GBankCommInfAmount))
                ELSE 0.00
            END AS CreditAmount,
            --Alloc.GBankAllocInfExplanation as comment,
            '' as comment,
            comm.GBankCommInfPaidTo,
            Comm.GBankCommInfCheck as ReferenceNumber,
            Comm.GBankCommInfID as EntryNumber
        from
            [PCLAWDB_32130].[dbo].GBComm Comm
            join [PCLAWDB_32130].[dbo].GBAcctI I on Comm.GBankCommInfAccountID = I.GBankAcctInfBankAccountID
            join [PCLAWDB_32130].[dbo].GLAcct a on I.GBankAcctInfGLAccountID = a.GLAcctID --join (select GBankAllocInfCheckID, GBankAllocInfExplanation from [PCLAWDB_32130].[dbo].GBAlloc group by GBankAllocInfCheckID, GBankAllocInfExplanation) Alloc 
            --on Comm.GBankCommInfID = Alloc.GBankAllocInfCheckID
        where
            GBankCommInfStatus = 0
            and GBankCommInfEntryType > 1200
            and GBankCommInfEntryType < 1500 --3
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
            CASE
                WHEN GBankAllocInfEntryType IN (1400, 2001, 2000)
                AND GBankAllocInfAmount >= 0 THEN CONVERT(money, GBankAllocInfAmount)
                WHEN GBankAllocInfEntryType IN (1100, 1101, 1102, 1103, 1104, 1300, 1301)
                AND GBankAllocInfAmount < 0 THEN ABS(CONVERT(money, GBankAllocInfAmount))
                ELSE 0.00
            END AS DebitAmount,
            -- CreditAmount logic
            CASE
                WHEN GBankAllocInfEntryType IN (1100, 1101, 1102, 1103, 1104, 1300, 1301)
                AND GBankAllocInfAmount >= 0 THEN CONVERT(money, GBankAllocInfAmount)
                WHEN GBankAllocInfEntryType IN (1400, 2001, 2000)
                AND GBankAllocInfAmount < 0 THEN ABS(CONVERT(money, GBankAllocInfAmount))
                ELSE 0.00
            END AS CreditAmount,
            GBankAllocInfExplanation as comment,
            comm.GBankCommInfPaidTo,
            Comm.GBankCommInfCheck as ReferenceNumber,
            Comm.GBankCommInfID as EntryNumber
        from
            [PCLAWDB_32130].[dbo].GBAlloc Alloc
            join [PCLAWDB_32130].[dbo].GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
            join [PCLAWDB_32130].[dbo].GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
        where
            GBankCommInfStatus = 0
            and GBankAllocInfENtryType not in (1600, 1650, 1651, 1652, 6500) -- Expense recoveries and tax entries and AP entries
            and GBankAllocInfEntryType not in (1803, 1899, 1200) -- 1899 are write offs and are done later, 1200 is an OB,
            and GBankCommInfEntryType not IN (1900, 1901, 1902, 1903, 1904, 1905) -- 1901,1902, and 1903,1904 are balance forwards in the suspense account
            and GBankAllocInfAmount <> 0 --4
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
            CASE
                WHEN GBankAllocInfAmount < 0 THEN ABS(CONVERT(money, GBankAllocInfAmount))
                ELSE CONVERT(money, 0.00)
            END AS DebitAmount,
            -- CreditAmount logic
            CASE
                WHEN GBankAllocInfAmount >= 0 THEN CONVERT(money, GBankAllocInfAmount)
                ELSE CONVERT(money, 0.00)
            END AS CreditAmount,
            GBankAllocInfExplanation as comment,
            comm.GBankCommInfPaidTo,
            comm.GBankCommInfCheck as ReferenceNumber,
            Alloc.GBankAllocInfAllocID as EntryNumber
        from
            [PCLAWDB_32130].[dbo].GBAlloc Alloc
            join [PCLAWDB_32130].[dbo].GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
            join [PCLAWDB_32130].[dbo].GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
            left join [PCLAWDB_32130].[dbo].TranIDX t on Alloc.GBankAllocInfAllocID = t.TranIndexSequenceID
        where
            TranIndexStatus = 0 --and t.MatterID <> 0
            and GBankAllocInfEntryType in (1400, 1600)
            and alloc.MatterID <> 0 --5
        union
        all -- Expense Recoveries into the 1210 Account (summary of all CER types)
        select
            '5' as Sno,
            'GBAlloc' as TableName,
            'CER' as Journal,
            MAX(a.GLAcctID) as GLAcctID,
            MAX(a.GLAccountAcctName) as GLAccountAcctName,
            MAX(a.GLAccountNickName) as GLAccountNickName,
            MAX(a.GLAccountStatus) as GLAccountStatus,
            MAX(a.GLAccountCategory) as GLAccountCategory,
            MAX((GBankCommInfDate)) as GBankCommInfDate,
            case when SUM(convert(money, GBankAllocInfAmount)) >= 0
            then SUM(convert(money, GBankAllocInfAmount)) else 0 end as DebitAmount,
            case when SUM(convert(money, GBankAllocInfAmount)) < 0
            then ABS(SUM(convert(money, GBankAllocInfAmount))) else 0 end as CreditAmount,
            'Total of Recoveries' as comment,
            '' as GBankCommInfPaidTo,
            '' as ReferenceNumber,
            '' as EntryNumber
        from
            [PCLAWDB_32130].[dbo].GBAlloc Alloc
            join [PCLAWDB_32130].[dbo].GLAcct a on a.GLAccountNickName = '5010'
            join [PCLAWDB_32130].[dbo].GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
            left join [PCLAWDB_32130].[dbo].TranIDX t on Alloc.GBankAllocInfAllocID = t.TranIndexSequenceID
        where
            TranIndexStatus = 0 --and t.MatterID <> 0
            and GBankAllocInfEntryType in (1400, 1600)
            and alloc.MatterID <> 0 --6
        GROUP BY
          SUBSTRING(CAST(GBankCommInfDate AS VARCHAR), 1, 4),
          SUBSTRING(CAST(GBankCommInfDate AS VARCHAR), 5, 2)
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
                when TBankCommInfEntryType in (2050, 2054)
                or (
                    TBankCommInfEntryType not in (2050, 2054)
                    AND TBankAllocInfoAmount < 0
                ) then convert(money, ABS(TBankAllocInfoAmount))
                else convert(money, 0.00)
            end as DebitAmount,
            Case
                when TBankCommInfEntryType not in (2050, 2054)
                AND TBankAllocInfoAmount >= 0 then convert(money, TBankAllocInfoAmount)
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
        where
            TBankCommInfStatus = 0
            and TBankCommInfEntryType not in (1552, 1553, 2501) -- not sure why this item is excluded from the reports
            --7
		union
        all
		select
		'7' as Sno,
			'TBComm' as TableName,
			'TB' as Journal,
			MAX(a.GLAcctID) AS GLAcctID,
			MAX(a.GLAccountAcctName) AS GLAccountAcctName,
			MAX(a.GLAccountNickName) AS GLAccountNickName,
			MAX(a.GLAccountStatus) AS GLAccountStatus,
			MAX(a.GLAccountCategory) AS GLAccountCategory,
			MAX((TBankCommInfDate)) as GLDate,
			SUM(Case
				when TBankAllocInfoEntryType in (2050, 2054) then convert(money, 0.00)
				else convert(money, TBankAllocInfoAmount)
			end) as DebitAmount,
			SUM(Case
				when TBankAllocInfoEntryType in (2050, 2054) then convert(money, TBankAllocInfoAmount)
				else convert(money, 0.00)
			end) as CreditAmount,
			MAX(Case
				when TBankAllocInfoEntryType in (2050, 2054) then 'Receipts' 
				else 'Disbursements' end) as comment,
			'' as GBankCommInfPaidTo,
			'' as ReferenceNumber,
			'' as EntryNumber
		from
			[PCLAWDB_32130].[dbo].TBAlloc Alloc
			join [PCLAWDB_32130].[dbo].GLAcct a on '2100' = a.GLAccountNickName
			join [PCLAWDB_32130].[dbo].TBComm Comm on Alloc.TBankAllocInfoCheckID = Comm.TBankCommInfSequenceID 
			join [PCLAWDB_32130].[dbo].TBAcctI I on Comm.TBankCommInfAccountID = I.TBankAcctInfBankAccountID
            join [PCLAWDB_32130].[dbo].GLAcct b on I.TBankAcctInfGLAccountID = b.GLAcctID
			where TBankAllocInfoStatus = 0 and TBankCommInfEntryType not in (1552, 1553, 2501) 
		GROUP BY
          SUBSTRING(CAST(TBankCommInfDate AS VARCHAR), 1, 4),
          SUBSTRING(CAST(TBankCommInfDate AS VARCHAR), 5, 2),
		  b.GLAcctID,
		  TBankAllocInfoEntryType
        union
        all -- Matter Specific AP Items
        select
            '10' as Sno,
            'GBAlloc',
            'AP' as Journal,
            a.GLAcctID,
            a.GLAccountAcctName,
            a.GLAccountNickName,
            a.GLAccountStatus,
            a.GLAccountCategory,
            (APInvoiceEntryDate) as GLDate,
            --case when I.APInvoiceTotBasePST = I.APInvoiceTotPaid then 0 else Alloc.GBankAllocInfAmount end as DebitAmount,
            CASE
                WHEN Alloc.GBankAllocInfAmount < 0 THEN convert(money, ABS(Alloc.GBankAllocInfAmount))
                ELSE convert(money, 0.00)
            END AS DebitAmount,
            CASE
                WHEN Alloc.GBankAllocInfAmount >= 0 THEN convert(money, Alloc.GBankAllocInfAmount)
                ELSE convert(money, 0.00)
            END AS CreditAmount,
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
        where
            APInvoiceStatus = 0
            and m.MatterID <> 0 --11
        union
        all -- Matter Specific AP Items into the 1210 account (Client Disb Recoverable)
        select
            '11' as Sno,
            'GBAlloc',
            'AP' as Journal,
            a.GLAcctID,
            a.GLAccountAcctName,
            a.GLAccountNickName,
            a.GLAccountStatus,
            a.GLAccountCategory,
            (APInvoiceEntryDate) as GLDate,
            --case when I.APInvoiceTotBasePST = I.APInvoiceTotPaid then 0 else Alloc.GBankAllocInfAmount end as DebitAmount,
            CASE
                WHEN Alloc.GBankAllocInfAmount >= 0 THEN convert(money, Alloc.GBankAllocInfAmount)
                ELSE convert(money, 0.00)
            END AS DebitAmount,
            CASE
                WHEN Alloc.GBankAllocInfAmount < 0 THEN convert(money, ABS(Alloc.GBankAllocInfAmount))
                ELSE convert(money, 0.00)
            END AS CreditAmount,
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
        where
            APInvoiceStatus = 0
            and m.MatterID <> 0 --12
    ) AS T--group by t.Journal
where
    --Journal in ('TB')
    --Sno In('5') 
    --ReferenceNumber = '211940'
    --GLAccountAcctName IN ('Fee Income')
    --GLAccountNickName = '2100'
    --AND
	T.GLDate BETWEEN 20240101 AND 20240131 
	--and T.Journal != 'GB'
    -- T.GLDate BETWEEN 20240101 AND 20240131 AND T.ReferenceNumber IN ('23133094', '23132901', '23132048', '12/05/23')
    --ORDER BY T.ReferenceNumber ASC
    --GROUP BY T.TableName, T.Journal, T.GLAcctID, T.GLAccountAcctName, T.GLAccountNickName, T.GLAccountStatus, T.GLAccountCategory, T.
    --GROUP BY T.GLAccountAcctName
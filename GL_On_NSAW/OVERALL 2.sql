/****** Object:  View dbo].PCLaw_GeneralLedger_Details]    Script Date: 08/15/2012 09:03:07 ******/
SELECT
    * --SUM(DebitAmount), SUM(CreditAmount), SUM(DebitAmount)-SUM(CreditAmount) AS TB_amount
FROM
    (
        SELECT
            '1' Sno,
            'GJEntry' TableName,
            'GJ' Journal,
            a.GLAcctID,
            a.GLAccountAcctName,
            a.GLAccountNickName,
            a.GLAccountStatus,
            a.GLAccountCategory,
            TO_CHAR(j.GJEntryDate, 'YYYYMMDD') as GLDate,
            CASE
                WHEN g.GJAllocationAmount > 0 THEN ABS(TO_NUMBER(g.GJAllocationAmount))
                ELSE TO_NUMBER(0.00)
            END DebitAmount,
            case
                WHEN g.GJAllocationAmount < 0 THEN ABS(TO_NUMBER(GJAllocationAmount))
                ELSE TO_NUMBER(0.00)
            END CreditAmount,
            j.GJEntryExpl Explaination,
            'Journal Entry' GBankCommInfPaidTo,
            j.GJEntryRef ReferenceNumber,
            j.GJEntryID EntryNumber
        FROM
            PCLAW_GJEntry j
            JOIN PCLAW_GJAlloc g ON j.GJEntryID = g.GJAllocationGJID
            JOIN PCLAW_GLAcct a ON g.GLAcctID = a.GLAcctID
            JOIN PCLAW_TranIDX x ON j.GJEntryID = x.TranIndexSequenceID
        WHERE
            x.TranIndexStatus = 0
        union
        all
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
            TO_CHAR(GBankCommInfDate, 'YYYYMMDD') as GLDate,
            --   Debit side for cheque entries
            CASE
                WHEN GBankAllocInfEntryType IN (1400, 2001, 2000)
                AND GBankAllocInfAmount >= 0 THEN TO_NUMBER(GBankAllocInfAmount)
                WHEN GBankAllocInfEntryType IN (1100, 1101, 1102, 1103, 1104, 1300, 1301)
                AND GBankAllocInfAmount < 0 THEN ABS(TO_NUMBER(GBankAllocInfAmount))
                ELSE 0.00
            END AS DebitAmount,
            -- CreditAmount logic
            CASE
                WHEN GBankAllocInfEntryType IN (1100, 1101, 1102, 1103, 1104, 1300, 1301)
                AND GBankAllocInfAmount >= 0 THEN TO_NUMBER(GBankAllocInfAmount)
                WHEN GBankAllocInfEntryType IN (1400, 2001, 2000)
                AND GBankAllocInfAmount < 0 THEN ABS(TO_NUMBER(GBankAllocInfAmount))
                ELSE 0.00
            END AS CreditAmount,
            GBankAllocInfExplanation as Explanation,
            comm.GBankCommInfPaidTo,
            Comm.GBankCommInfCheck as ReferenceNumber,
            Comm.GBankCommInfID as EntryNumber
        from
            PCLAW_GBAlloc Alloc
            join PCLAW_GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
            join PCLAW_GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
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
            TO_CHAR(GBankCommInfDate, 'YYYYMMDD') as GLDate,
            CASE
                WHEN GBankAllocInfAmount < 0 THEN ABS(TO_NUMBER(GBankAllocInfAmount))
                ELSE TO_NUMBER(0.00)
            END AS DebitAmount,
            -- CreditAmount logic
            CASE
                WHEN GBankAllocInfAmount >= 0 THEN TO_NUMBER(GBankAllocInfAmount)
                ELSE TO_NUMBER(0.00)
            END AS CreditAmount,
            GBankAllocInfExplanation as Explanation,
            comm.GBankCommInfPaidTo,
            comm.GBankCommInfCheck as ReferenceNumber,
            Alloc.GBankAllocInfAllocID as EntryNumber
        from
            PCLAW_GBAlloc Alloc
            join PCLAW_GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
            join PCLAW_GBComm Comm on Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
            left join PCLAW_TranIDX t on Alloc.GBankAllocInfAllocID = t.TranIndexSequenceID
        where
            TranIndexStatus = 0 --and t.MatterID <> 0
            and GBankAllocInfEntryType in (1400, 1600)
            and alloc.MatterID <> 0 --5
        union
        all -- Expense Recoveries into the 1210 Account (summary of all CER types)
        SELECT
            '5' AS Sno,
            'GBAlloc' AS TableName,
            'CER' AS Journal,
            MAX(a.GLAcctID) AS GLAcctID,
            MAX(a.GLAccountAcctName) AS GLAccountAcctName,
            MAX(a.GLAccountNickName) AS GLAccountNickName,
            MAX(a.GLAccountStatus) AS GLAccountStatus,
            MAX(a.GLAccountCategory) AS GLAccountCategory,
            MAX(TO_CHAR(Comm.GBankCommInfDate, 'YYYYMMDD')) AS GLDate,
            -- ✅ FIXED
            CASE
                WHEN SUM(TO_NUMBER(Alloc.GBankAllocInfAmount)) >= 0 THEN SUM(TO_NUMBER(Alloc.GBankAllocInfAmount))
                ELSE 0
            END AS DebitAmount,
            CASE
                WHEN SUM(TO_NUMBER(Alloc.GBankAllocInfAmount)) < 0 THEN ABS(SUM(TO_NUMBER(Alloc.GBankAllocInfAmount)))
                ELSE 0
            END AS CreditAmount,
            'Total of Recoveries' AS Explanation,
            '' AS GBankCommInfPaidTo,
            '' AS ReferenceNumber,
            '' AS EntryNumber
        FROM
            PCLAW_GBAlloc Alloc
            JOIN PCLAW_GLAcct a ON a.GLAccountNickName = '5010'
            JOIN PCLAW_GBComm Comm ON Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
            LEFT JOIN PCLAW_TranIDX t ON Alloc.GBankAllocInfAllocID = t.TranIndexSequenceID
        WHERE
            t.TranIndexStatus = 0
            AND Alloc.GBankAllocInfEntryType IN (1400, 1600)
            AND Alloc.MatterID <> 0
        GROUP BY
            SUBSTR(TO_CHAR(Comm.GBankCommInfDate, 'YYYYMMDD'), 1, 4),
            SUBSTR(TO_CHAR(Comm.GBankCommInfDate, 'YYYYMMDD'), 5, 2)
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
            TO_CHAR(TBankCommInfDate, 'YYYYMMDD') as GLDate,
            Case
                when TBankCommInfEntryType in (2050, 2054)
                or (
                    TBankCommInfEntryType not in (2050, 2054)
                    AND TBankAllocInfoAmount < 0
                ) then TO_NUMBER(ABS(TBankAllocInfoAmount))
                else TO_NUMBER(0.00)
            end as DebitAmount,
            Case
                when TBankCommInfEntryType not in (2050, 2054)
                AND TBankAllocInfoAmount >= 0 then TO_NUMBER(TBankAllocInfoAmount)
                else TO_NUMBER(0.00)
            end as CreditAmount,
            Alloc.TBankAllocInfExplanation as Explanation,
            TBankCommInfPaidTo as GBankCommInfPaidTo,
            Comm.TBankCommInfCheck as ReferenceNumber,
            Comm.TBankCommInfSequenceID as EntryNumber
        from
            PCLAW_TBComm Comm
            join PCLAW_TBAcctI I on Comm.TBankCommInfAccountID = I.TBankAcctInfBankAccountID
            join PCLAW_GLAcct a on I.TBankAcctInfGLAccountID = a.GLAcctID
            join PCLAW_TBAlloc Alloc on Alloc.TBankAllocInfoCheckID = Comm.TBankCommInfSequenceID
        where
            TBankCommInfStatus = 0
            and TBankCommInfEntryType not in (1552, 1553, 2501) -- not sure why this item is excluded from the reports
            --7
        union
        all
        SELECT
            '7' AS Sno,
            'TBComm' AS TableName,
            'TB' AS Journal,
            MAX(a.GLAcctID) AS GLAcctID,
            MAX(a.GLAccountAcctName) AS GLAccountAcctName,
            MAX(a.GLAccountNickName) AS GLAccountNickName,
            MAX(a.GLAccountStatus) AS GLAccountStatus,
            MAX(a.GLAccountCategory) AS GLAccountCategory,
            MAX(TO_CHAR(TBankCommInfDate, 'YYYYMMDD')) AS GLDate,
            SUM(
                CASE
                    WHEN TBankAllocInfoEntryType IN (2050, 2054) THEN TO_NUMBER(0.00)
                    ELSE TO_NUMBER(TBankAllocInfoAmount)
                END
            ) AS DebitAmount,
            SUM(
                CASE
                    WHEN TBankAllocInfoEntryType IN (2050, 2054) THEN TO_NUMBER(TBankAllocInfoAmount)
                    ELSE TO_NUMBER(0.00)
                END
            ) AS CreditAmount,
            MAX(
                CASE
                    WHEN TBankAllocInfoEntryType IN (2050, 2054) THEN 'Receipts'
                    ELSE 'Disbursements'
                END
            ) AS Explanation,
            '' AS GBankCommInfPaidTo,
            '' AS ReferenceNumber,
            '' AS EntryNumber
        FROM
            PCLAW_TBAlloc Alloc
            JOIN PCLAW_GLAcct a ON '2100' = a.GLAccountNickName
            JOIN PCLAW_TBComm Comm ON Alloc.TBankAllocInfoCheckID = Comm.TBankCommInfSequenceID
            JOIN PCLAW_TBAcctI I ON Comm.TBankCommInfAccountID = I.TBankAcctInfBankAccountID
            JOIN PCLAW_GLAcct b ON I.TBankAcctInfGLAccountID = b.GLAcctID
        WHERE
            TBankAllocInfoStatus = 0
            AND TBankCommInfEntryType NOT IN (1552, 1553, 2501)
        GROUP BY
            SUBSTR(TO_CHAR(TBankCommInfDate, 'YYYYMMDD'), 1, 4),
            SUBSTR(TO_CHAR(TBankCommInfDate, 'YYYYMMDD'), 5, 2),
            b.GLAcctID,
            TBankAllocInfoEntryType
        union
        all -- Matter Specific AP Items
        select
            '10' as Sno,
            'GBAlloc' as TableName,
            'AP' as Journal,
            a.GLAcctID,
            a.GLAccountAcctName,
            a.GLAccountNickName,
            a.GLAccountStatus,
            a.GLAccountCategory,
            TO_CHAR(APInvoiceEntryDate, 'YYYYMMDD') as GLDate,
            --case when I.APInvoiceTotBasePST = I.APInvoiceTotPaid then 0 else Alloc.GBankAllocInfAmount end as DebitAmount,
            CASE
                WHEN Alloc.GBankAllocInfAmount < 0 THEN TO_NUMBER(ABS(Alloc.GBankAllocInfAmount))
                ELSE TO_NUMBER(0.00)
            END AS DebitAmount,
            CASE
                WHEN Alloc.GBankAllocInfAmount >= 0 THEN TO_NUMBER(Alloc.GBankAllocInfAmount)
                ELSE TO_NUMBER(0.00)
            END AS CreditAmount,
            APInvoiceExpl as Explanation,
            v.APVendorListSortName as GBankCommInfPaidTo,
            I.APInvoiceInvNumr as ReferenceNumber,
            I.APInvoiceID as EntryNumber
        from
            PCLAW_APInv I
            join PCLAW_GBAlloc Alloc on I.APInvoiceID = Alloc.GBankAllocInfCheckID
            join PCLAW_GLAcct a on Alloc.GBankAllocInfGLID = a.GLAcctID
            left join PCLAW_ActCode C on Alloc.GBankAllocInfActivityID = C.ActivityCodesID
            left join PCLAW_MattInf m on Alloc.MatterID = m.MatterID
            left join PCLAW_APVendLi v on I.APInvoiceVendorID = v.APVendorListID
        where
            APInvoiceStatus = 0
            and m.MatterID <> 0 --11
        union
        all -- Matter Specific AP Items into the 1210 account (Client Disb Recoverable)
        select
            '11' as Sno,
            'GBAlloc' as TableName,
            'AP' as Journal,
            a.GLAcctID,
            a.GLAccountAcctName,
            a.GLAccountNickName,
            a.GLAccountStatus,
            a.GLAccountCategory,
            TO_CHAR(APInvoiceEntryDate, 'YYYYMMDD') as GLDate,
            --case when I.APInvoiceTotBasePST = I.APInvoiceTotPaid then 0 else Alloc.GBankAllocInfAmount end as DebitAmount,
            CASE
                WHEN Alloc.GBankAllocInfAmount >= 0 THEN TO_NUMBER(Alloc.GBankAllocInfAmount)
                ELSE TO_NUMBER(0.00)
            END AS DebitAmount,
            CASE
                WHEN Alloc.GBankAllocInfAmount < 0 THEN TO_NUMBER(ABS(Alloc.GBankAllocInfAmount))
                ELSE TO_NUMBER(0.00)
            END AS CreditAmount,
            APInvoiceExpl as Explanation,
            v.APVendorListSortName as GBankCommInfPaidTo,
            I.APInvoiceInvNumr as ReferenceNumber,
            I.APInvoiceID as EntryNumber
        from
            PCLAW_APInv I
            join PCLAW_GBAlloc Alloc on I.APInvoiceID = Alloc.GBankAllocInfCheckID
            join PCLAW_GLAcct a on a.GLAccountNickName = '5010'
            left join PCLAW_ActCode C on Alloc.GBankAllocInfActivityID = C.ActivityCodesID
            left join PCLAW_MattInf m on Alloc.MatterID = m.MatterID
            left join PCLAW_APVendLi v on I.APInvoiceVendorID = v.APVendorListID
        where
            APInvoiceStatus = 0
            and m.MatterID <> 0 --12
    ) T --group by t.Journal
    --Journal in ('TB')
    --Sno In('5') 
    --ReferenceNumber = '211940'
    --GLAccountAcctName IN ('Fee Income')
    --GLAccountNickName = '2100'
    --AND
    --T.GLDate BETWEEN 20240101
   -- AND 20240131 --and T.Journal != 'GB'
    -- T.GLDate BETWEEN 20240101 AND 20240131 AND T.ReferenceNumber IN ('23133094', '23132901', '23132048', '12/05/23')
    --ORDER BY T.ReferenceNumber ASC
    --GROUP BY T.TableName, T.Journal, T.GLAcctID, T.GLAccountAcctName, T.GLAccountNickName, T.GLAccountStatus, T.GLAccountCategory, T.
    --GROUP BY T.GLAccountAcctName
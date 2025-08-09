SELECT
    CAST('1' AS VARCHAR2(10)) AS Sno,
    CAST('GJEntry' AS VARCHAR2(20)) AS TableName,
    CAST('GJ' AS VARCHAR2(10)) AS Journal,
    a.GLAcctID,
    a.GLAccountAcctName,
    a.GLAccountNickName,
    a.GLAccountStatus,
    a.GLAccountCategory,
    TO_CHAR(j.GJEntryDate, 'YYYYMMDD') AS GLDate,
    CASE
        WHEN g.GJAllocationAmount > 0 THEN CAST(ABS(TO_NUMBER(g.GJAllocationAmount)) AS NUMBER)
        ELSE CAST(0 AS NUMBER)
    END AS DebitAmount,
    CASE
        WHEN g.GJAllocationAmount < 0 THEN CAST(ABS(TO_NUMBER(g.GJAllocationAmount)) AS NUMBER)
        ELSE CAST(0 AS NUMBER)
    END AS CreditAmount,
    CAST(j.GJEntryExpl AS VARCHAR2(4000)) AS Explanation,
    CAST('Journal Entry' AS VARCHAR2(255)) AS GBankCommInfPaidTo,
    CAST(j.GJEntryRef AS VARCHAR2(255)) AS ReferenceNumber,
    CAST(j.GJEntryID AS VARCHAR2(255)) AS EntryNumber
FROM
    PCLAW_GJEntry j
    JOIN PCLAW_GJAlloc g ON j.GJEntryID = g.GJAllocationGJID
    JOIN PCLAW_GLAcct a ON g.GLAcctID = a.GLAcctID
    JOIN PCLAW_TranIDX x ON j.GJEntryID = x.TranIndexSequenceID
WHERE
    x.TranIndexStatus = 0
union
all
SELECT
    CAST('3' AS VARCHAR2(10)) AS Sno,
    CAST('GBAlloc' AS VARCHAR2(20)) AS TableName,
    CAST(
        CASE
            WHEN GBankAllocInfEntryType IN (1103) THEN 'RU'
            WHEN GBankAllocInfEntryType IN (1100, 1101, 1102, 1104) THEN 'GB'
            WHEN GBankAllocInfEntryType IN (2000, 2001) THEN 'TL'
            ELSE 'GB'
        END AS VARCHAR2(10)
    ) AS Journal,
    a.GLAcctID,
    a.GLAccountAcctName,
    a.GLAccountNickName,
    a.GLAccountStatus,
    a.GLAccountCategory,
    TO_CHAR(GBankCommInfDate, 'YYYYMMDD') AS GLDate,
    CASE
        WHEN GBankAllocInfEntryType IN (1400, 2001, 2000)
        AND GBankAllocInfAmount >= 0 THEN CAST(TO_NUMBER(GBankAllocInfAmount) AS NUMBER)
        WHEN GBankAllocInfEntryType IN (1100, 1101, 1102, 1103, 1104, 1300, 1301)
        AND GBankAllocInfAmount < 0 THEN CAST(ABS(TO_NUMBER(GBankAllocInfAmount)) AS NUMBER)
        ELSE CAST(0 AS NUMBER)
    END AS DebitAmount,
    CASE
        WHEN GBankAllocInfEntryType IN (1100, 1101, 1102, 1103, 1104, 1300, 1301)
        AND GBankAllocInfAmount >= 0 THEN CAST(TO_NUMBER(GBankAllocInfAmount) AS NUMBER)
        WHEN GBankAllocInfEntryType IN (1400, 2001, 2000)
        AND GBankAllocInfAmount < 0 THEN CAST(ABS(TO_NUMBER(GBankAllocInfAmount)) AS NUMBER)
        ELSE CAST(0 AS NUMBER)
    END AS CreditAmount,
    CAST(GBankAllocInfExplanation AS VARCHAR2(4000)) AS Explanation,
    CAST(Comm.GBankCommInfPaidTo AS VARCHAR2(255)) AS GBankCommInfPaidTo,
    CAST(Comm.GBankCommInfCheck AS VARCHAR2(255)) AS ReferenceNumber,
    CAST(Comm.GBankCommInfID AS VARCHAR2(255)) AS EntryNumber
FROM
    PCLAW_GBAlloc Alloc
    JOIN PCLAW_GLAcct a ON Alloc.GBankAllocInfGLID = a.GLAcctID
    JOIN PCLAW_GBComm Comm ON Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
WHERE
    GBankCommInfStatus = 0
    AND GBankAllocInfEntryType NOT IN (1600, 1650, 1651, 1652, 6500, 1803, 1899, 1200)
    AND GBankCommInfEntryType NOT IN (1900, 1901, 1902, 1903, 1904, 1905)
    AND GBankAllocInfAmount <> 0
Union
all
SELECT
    CAST('4' AS VARCHAR2(10)) AS Sno,
    CAST('GBAlloc' AS VARCHAR2(20)) AS TableName,
    CAST('CER' AS VARCHAR2(10)) AS Journal,
    a.GLAcctID,
    a.GLAccountAcctName,
    a.GLAccountNickName,
    a.GLAccountStatus,
    a.GLAccountCategory,
    TO_CHAR(GBankCommInfDate, 'YYYYMMDD') AS GLDate,
    CASE
        WHEN GBankAllocInfAmount < 0 THEN CAST(ABS(TO_NUMBER(GBankAllocInfAmount)) AS NUMBER)
        ELSE CAST(0 AS NUMBER)
    END AS DebitAmount,
    CASE
        WHEN GBankAllocInfAmount >= 0 THEN CAST(TO_NUMBER(GBankAllocInfAmount) AS NUMBER)
        ELSE CAST(0 AS NUMBER)
    END AS CreditAmount,
    CAST(GBankAllocInfExplanation AS VARCHAR2(4000)) AS Explanation,
    CAST(comm.GBankCommInfPaidTo AS VARCHAR2(255)) AS GBankCommInfPaidTo,
    CAST(comm.GBankCommInfCheck AS VARCHAR2(255)) AS ReferenceNumber,
    CAST(Alloc.GBankAllocInfAllocID AS VARCHAR2(255)) AS EntryNumber
FROM
    PCLAW_GBAlloc Alloc
    JOIN PCLAW_GLAcct a ON Alloc.GBankAllocInfGLID = a.GLAcctID
    JOIN PCLAW_GBComm Comm ON Alloc.GBankAllocInfCheckID = Comm.GBankCommInfID
    LEFT JOIN PCLAW_TranIDX t ON Alloc.GBankAllocInfAllocID = t.TranIndexSequenceID
WHERE
    TranIndexStatus = 0
    AND GBankAllocInfEntryType IN (1400, 1600)
    AND Alloc.MatterID <> 0
union
all
SELECT
    CAST('5' AS VARCHAR2(10)) AS Sno,
    CAST('GBAlloc' AS VARCHAR2(20)) AS TableName,
    CAST('CER' AS VARCHAR2(10)) AS Journal,
    MAX(a.GLAcctID) AS GLAcctID,
    MAX(a.GLAccountAcctName) AS GLAccountAcctName,
    MAX(a.GLAccountNickName) AS GLAccountNickName,
    MAX(a.GLAccountStatus) AS GLAccountStatus,
    MAX(a.GLAccountCategory) AS GLAccountCategory,
    MAX(TO_CHAR(Comm.GBankCommInfDate, 'YYYYMMDD')) AS GLDate,
    CASE
        WHEN SUM(TO_NUMBER(Alloc.GBankAllocInfAmount)) >= 0 THEN CAST(
            SUM(TO_NUMBER(Alloc.GBankAllocInfAmount)) AS NUMBER
        )
        ELSE CAST(0 AS NUMBER)
    END AS DebitAmount,
    CASE
        WHEN SUM(TO_NUMBER(Alloc.GBankAllocInfAmount)) < 0 THEN CAST(
            ABS(SUM(TO_NUMBER(Alloc.GBankAllocInfAmount))) AS NUMBER
        )
        ELSE CAST(0 AS NUMBER)
    END AS CreditAmount,
    CAST('Total of Recoveries' AS VARCHAR2(4000)) AS Explanation,
    CAST('' AS VARCHAR2(255)) AS GBankCommInfPaidTo,
    CAST('' AS VARCHAR2(255)) AS ReferenceNumber,
    CAST('' AS VARCHAR2(255)) AS EntryNumber
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
all
SELECT
    CAST('6' AS VARCHAR2(10)) AS Sno,
    CAST('TBComm' AS VARCHAR2(20)) AS TableName,
    CAST('TB' AS VARCHAR2(10)) AS Journal,
    a.GLAcctID,
    a.GLAccountAcctName,
    a.GLAccountNickName,
    a.GLAccountStatus,
    a.GLAccountCategory,
    TO_CHAR(TBankCommInfDate, 'YYYYMMDD') AS GLDate,
    CASE
        WHEN TBankCommInfEntryType IN (2050, 2054)
        OR (
            TBankCommInfEntryType NOT IN (2050, 2054)
            AND TBankAllocInfoAmount < 0
        ) THEN CAST(ABS(TO_NUMBER(TBankAllocInfoAmount)) AS NUMBER)
        ELSE CAST(0 AS NUMBER)
    END AS DebitAmount,
    CASE
        WHEN TBankCommInfEntryType NOT IN (2050, 2054)
        AND TBankAllocInfoAmount >= 0 THEN CAST(TO_NUMBER(TBankAllocInfoAmount) AS NUMBER)
        ELSE CAST(0 AS NUMBER)
    END AS CreditAmount,
    CAST(Alloc.TBankAllocInfExplanation AS VARCHAR2(4000)) AS Explanation,
    CAST(TBankCommInfPaidTo AS VARCHAR2(255)) AS GBankCommInfPaidTo,
    CAST(Comm.TBankCommInfCheck AS VARCHAR2(255)) AS ReferenceNumber,
    CAST(Comm.TBankCommInfSequenceID AS VARCHAR2(255)) AS EntryNumber
FROM
    PCLAW_TBComm Comm
    JOIN PCLAW_TBAcctI I ON Comm.TBankCommInfAccountID = I.TBankAcctInfBankAccountID
    JOIN PCLAW_GLAcct a ON I.TBankAcctInfGLAccountID = a.GLAcctID
    JOIN PCLAW_TBAlloc Alloc ON Alloc.TBankAllocInfoCheckID = Comm.TBankCommInfSequenceID
WHERE
    TBankCommInfStatus = 0
    AND TBankCommInfEntryType NOT IN (1552, 1553, 2501)
union
all
SELECT
    CAST('7' AS VARCHAR2(10)) AS Sno,
    CAST('TBComm' AS VARCHAR2(20)) AS TableName,
    CAST('TB' AS VARCHAR2(10)) AS Journal,
    MAX(a.GLAcctID) AS GLAcctID,
    MAX(a.GLAccountAcctName) AS GLAccountAcctName,
    MAX(a.GLAccountNickName) AS GLAccountNickName,
    MAX(a.GLAccountStatus) AS GLAccountStatus,
    MAX(a.GLAccountCategory) AS GLAccountCategory,
    MAX(TO_CHAR(TBankCommInfDate, 'YYYYMMDD')) AS GLDate,
    SUM(
        CASE
            WHEN TBankAllocInfoEntryType IN (2050, 2054) THEN CAST(0 AS NUMBER)
            ELSE CAST(TO_NUMBER(TBankAllocInfoAmount) AS NUMBER)
        END
    ) AS DebitAmount,
    SUM(
        CASE
            WHEN TBankAllocInfoEntryType IN (2050, 2054) THEN CAST(TO_NUMBER(TBankAllocInfoAmount) AS NUMBER)
            ELSE CAST(0 AS NUMBER)
        END
    ) AS CreditAmount,
    CAST(
        MAX(
            CASE
                WHEN TBankAllocInfoEntryType IN (2050, 2054) THEN 'Receipts'
                ELSE 'Disbursements'
            END
        ) AS VARCHAR2(4000)
    ) AS Explanation,
    CAST('' AS VARCHAR2(255)) AS GBankCommInfPaidTo,
    CAST('' AS VARCHAR2(255)) AS ReferenceNumber,
    CAST('' AS VARCHAR2(255)) AS EntryNumber
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
all
SELECT
    CAST('10' AS VARCHAR2(10)) AS Sno,
    CAST('GBAlloc' AS VARCHAR2(20)) AS TableName,
    CAST('AP' AS VARCHAR2(10)) AS Journal,
    a.GLAcctID,
    a.GLAccountAcctName,
    a.GLAccountNickName,
    a.GLAccountStatus,
    a.GLAccountCategory,
    TO_CHAR(APInvoiceEntryDate, 'YYYYMMDD') AS GLDate,
    CASE
        WHEN Alloc.GBankAllocInfAmount < 0 THEN CAST(
            ABS(TO_NUMBER(Alloc.GBankAllocInfAmount)) AS NUMBER
        )
        ELSE CAST(0 AS NUMBER)
    END AS DebitAmount,
    CASE
        WHEN Alloc.GBankAllocInfAmount >= 0 THEN CAST(TO_NUMBER(Alloc.GBankAllocInfAmount) AS NUMBER)
        ELSE CAST(0 AS NUMBER)
    END AS CreditAmount,
    CAST(APInvoiceExpl AS VARCHAR2(4000)) AS Explanation,
    CAST(v.APVendorListSortName AS VARCHAR2(255)) AS GBankCommInfPaidTo,
    CAST(I.APInvoiceInvNumr AS VARCHAR2(255)) AS ReferenceNumber,
    CAST(I.APInvoiceID AS VARCHAR2(255)) AS EntryNumber
FROM
    PCLAW_APInv I
    JOIN PCLAW_GBAlloc Alloc ON I.APInvoiceID = Alloc.GBankAllocInfCheckID
    JOIN PCLAW_GLAcct a ON Alloc.GBankAllocInfGLID = a.GLAcctID
    LEFT JOIN PCLAW_ActCode C ON Alloc.GBankAllocInfActivityID = C.ActivityCodesID
    LEFT JOIN PCLAW_MattInf m ON Alloc.MatterID = m.MatterID
    LEFT JOIN PCLAW_APVendLi v ON I.APInvoiceVendorID = v.APVendorListID
WHERE
    APInvoiceStatus = 0
    AND m.MatterID <> 0
union
all
SELECT
    CAST('11' AS VARCHAR2(10)) AS Sno,
    CAST('GBAlloc' AS VARCHAR2(20)) AS TableName,
    CAST('AP' AS VARCHAR2(10)) AS Journal,
    a.GLAcctID,
    a.GLAccountAcctName,
    a.GLAccountNickName,
    a.GLAccountStatus,
    a.GLAccountCategory,
    TO_CHAR(APInvoiceEntryDate, 'YYYYMMDD') AS GLDate,
    CASE
        WHEN Alloc.GBankAllocInfAmount >= 0 THEN CAST(TO_NUMBER(Alloc.GBankAllocInfAmount) AS NUMBER)
        ELSE CAST(0 AS NUMBER)
    END AS DebitAmount,
    CASE
        WHEN Alloc.GBankAllocInfAmount < 0 THEN CAST(
            ABS(TO_NUMBER(Alloc.GBankAllocInfAmount)) AS NUMBER
        )
        ELSE CAST(0 AS NUMBER)
    END AS CreditAmount,
    CAST(APInvoiceExpl AS VARCHAR2(4000)) AS Explanation,
    CAST(v.APVendorListSortName AS VARCHAR2(255)) AS GBankCommInfPaidTo,
    CAST(I.APInvoiceInvNumr AS VARCHAR2(255)) AS ReferenceNumber,
    CAST(I.APInvoiceID AS VARCHAR2(255)) AS EntryNumber
FROM
    PCLAW_APInv I
    JOIN PCLAW_GBAlloc Alloc ON I.APInvoiceID = Alloc.GBankAllocInfCheckID
    JOIN PCLAW_GLAcct a ON a.GLAccountNickName = '5010'
    LEFT JOIN PCLAW_ActCode C ON Alloc.GBankAllocInfActivityID = C.ActivityCodesID
    LEFT JOIN PCLAW_MattInf m ON Alloc.MatterID = m.MatterID
    LEFT JOIN PCLAW_APVendLi v ON I.APInvoiceVendorID = v.APVendorListID
WHERE
    APInvoiceStatus = 0
    AND m.MatterID <> 0
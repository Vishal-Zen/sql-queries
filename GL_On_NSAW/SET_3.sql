SELECT
    '1' Sno,
    'GJEntry' TableName,
    'GJ' Journal,
    a.GLAcctID,
    a.GLAccountAcctName,
    a.GLAccountNickName,
    a.GLAccountStatus,
    a.GLAccountCategory,
    j.GJEntryDate GLDate,
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
    (GBankCommInfDate) as GLDate,
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
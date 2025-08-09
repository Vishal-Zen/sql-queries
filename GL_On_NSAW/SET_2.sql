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
    j.GJEntryExpl Explanation,
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
        AND GBankCommInfAmount >= 0 THEN TO_NUMBER(GBankCommInfAmount)
        WHEN GBankCommInfEntryType NOT IN (1300, 1301, 1303)
        AND GBankCommInfAmount < 0 THEN ABS(TO_NUMBER(GBankCommInfAmount))
        ELSE 0.00
    END AS DebitAmount,
    -- CreditAmount logic
    CASE
        WHEN GBankCommInfEntryType NOT IN (1300, 1301, 1303)
        AND GBankCommInfAmount >= 0 THEN TO_NUMBER(GBankCommInfAmount)
        WHEN GBankCommInfEntryType IN (1300, 1301, 1303)
        AND GBankCommInfAmount < 0 THEN ABS(TO_NUMBER(GBankCommInfAmount))
        ELSE 0.00
    END AS CreditAmount,
    '' as Explanation,
    comm.GBankCommInfPaidTo,
    Comm.GBankCommInfCheck as ReferenceNumber,
    Comm.GBankCommInfID as EntryNumber
from
    PCLAW_GBComm Comm
    join PCLAW_GBAcctI I on Comm.GBankCommInfAccountID = I.GBankAcctInfBankAccountID
    join PCLAW_GLAcct a on I.GBankAcctInfGLAccountID = a.GLAcctID 
where
    GBankCommInfStatus = 0
    and GBankCommInfEntryType > 1200
    and GBankCommInfEntryType < 1500
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

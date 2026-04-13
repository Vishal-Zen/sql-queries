SELECT
    TBC.TBankCommInfDate        AS Date,
    TBC.TBankCommInfPaidTo      AS Paidto,
    TBC.TBankCommInfAccountID   AS Accnt,
    TBC.TBankCommInfCheck       AS Check_Rec,
    TBC.TBankCommInfSequenceID  AS Entrynum,
    TBA.TBankAllocInfExplanation AS Explnation,
    TBA.MatterID                AS Matter,
    M.MatterInfoFileDesc        AS Client,
    TBC.TBankCommInfEntryType   AS TypefromTBComm,
    TBA.TBankAllocInfoEntryType AS TypefromTBAlloc,

    CASE 
        WHEN TBA.TBankAllocInfoEntryType <> '2050' 
        THEN TBA.TBankAllocInfoAmount 
        ELSE 0 
    END AS TBACheque,

    CASE 
        WHEN TBA.TBankAllocInfoEntryType = '2050' 
        THEN TBA.TBankAllocInfoAmount 
        ELSE 0 
    END AS TBARecepit,

    TBC.TBankCommInfAmount      AS TBCEntrytotal

FROM 
    PCLAWDB_32130.dbo.TBComm AS TBC

LEFT JOIN 
    PCLAWDB_32130.dbo.TBAlloc AS TBA
    ON TBC.TBankCommInfSequenceID = TBA.TBankAllocInfoCheckID

LEFT JOIN  
    PCLAWDB_32130.dbo.MattInf AS M
    ON TBA.MatterID = M.MatterID

WHERE
    -- TBC.TBankCommInfSequenceID IN ('1863949','1863951')
    TBC.TBankCommInfDate BETWEEN 20230701 AND 20231231
    AND TBC.TBankCommInfAccountID = '4'
    AND TBC.TBankCommInfCheck <> ''
    AND TBA.TBankAllocInfoStatus = '0'

ORDER BY
    TBC.TBankCommInfDate;

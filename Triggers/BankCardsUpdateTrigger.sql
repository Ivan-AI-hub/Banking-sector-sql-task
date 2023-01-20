USE BankingSector;
GO

DROP TRIGGER BankCardsValidateTrigger
GO


CREATE TRIGGER BankCardsValidateTrigger ON BankCards
FOR UPDATE, INSERT
AS
BEGIN     
	DECLARE @AccountBalance MONEY, @CardsBalance MONEY, @CurrentAccountID INT

	DECLARE cur CURSOR FOR 
	SELECT AccountId
	FROM inserted

	OPEN cur
	FETCH NEXT FROM cur INTO @CurrentAccountID
	WHILE @@FETCH_STATUS = 0
	BEGIN

	SELECT @AccountBalance = Accounts.Balance, @CardsBalance = SUM(BankCards.Balance)
	FROM Accounts JOIN BankCards ON Accounts.Id = BankCards.AccountId
	WHERE Accounts.Id = @CurrentAccountID
	GROUP BY Accounts.Balance

	IF @CardsBalance > @AccountBalance
	BEGIN
	   ROLLBACK TRANSACTION
	   PRINT 'There are not enough funds on the account with id='+ CONVERT(NVARCHAR, @CurrentAccountID) +'. It is not possible to increase the funds on the card.';
	END
	 	FETCH NEXT FROM cur INTO @CurrentAccountID
	   END
   	   
	   CLOSE cur
	   DEALLOCATE cur
END
Go

SELECT Accounts.Id, BankCards.Id, Sum(BankCards.Balance) AS 'card balance', Accounts.Balance
FROM Accounts JOIN BankCards ON Accounts.Id = AccountId
GROUP BY Accounts.Id, BankCards.Id,  Accounts.Balance
Go 

Update BankCards
Set Balance = 100
Where Id < 1010
GO

SELECT Accounts.Id, BankCards.Id, Sum(BankCards.Balance) AS 'card balance', Accounts.Balance
FROM Accounts JOIN BankCards ON Accounts.Id = AccountId
GROUP BY Accounts.Id, BankCards.Id,  Accounts.Balance
Go 
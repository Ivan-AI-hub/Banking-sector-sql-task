USE BankingSector;
GO
DROP PROCEDURE TransferMoney
GO

CREATE PROCEDURE TransferMoney
    @AccountId INT,
	@BankCardId INT,
	@MoneyCount MONEY
AS
BEGIN
	IF NOT EXISTS ( SELECT 1 FROM Accounts  WHERE Id = @AccountId)
	BEGIN
		THROW 50100, 'Account with the same Id is not exist', 1;
	END;

	IF NOT EXISTS ( SELECT 1 FROM BankCards  WHERE Id = @BankCardId)
	BEGIN
		THROW 50100, 'Bank card with the same Id is not exist', 1;
	END; 

	IF NOT EXISTS ( SELECT 1 
						FROM Accounts JOIN BankCards ON Accounts.Id = AccountId 
						WHERE Accounts.Id = @AccountId and BankCards.Id = @BankCardId)
	BEGIN
		THROW 50102, 'The bank card does not belong to this account', 1;
	END;
	

	BEGIN TRANSACTION

		UPDATE BankCards
		Set Balance = Balance + @MoneyCount
		Where Id = @BankCardId

		IF (SELECT Accounts.Balance - SUM(BankCards.Balance)
			FROM Accounts JOIN BankCards ON Accounts.Id = AccountId 
			WHERE Accounts.Id = @AccountId
			GROUP BY Accounts.Balance) < 0
		BEGIN
			ROLLBACK TRANSACTION;
			THROW 50103, 'There are not enough funds on the account', 1;
		END;

	COMMIT TRANSACTION
END;
Go

SELECT Accounts.Id AS 'AccounId', BankCards.Id AS 'CardID', BankCards.Balance AS 'card balance', Accounts.Balance AS 'Account balance'
FROM Accounts JOIN BankCards ON Accounts.Id = AccountId
WHERE AccountId = 1
Go 

EXEC TransferMoney 1, 1, 1;
Go

SELECT Accounts.Id AS 'AccounId', BankCards.Id AS 'CardID', BankCards.Balance AS 'card balance', Accounts.Balance AS 'Account balance'
FROM Accounts JOIN BankCards ON Accounts.Id = AccountId
WHERE AccountId = 1
Go 
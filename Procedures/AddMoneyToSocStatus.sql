USE BankingSector;
GO
DROP PROCEDURE AddMoneyToSocStatus
GO

CREATE PROCEDURE AddMoneyToSocStatus
    @SocialStatusId INT
AS
BEGIN
	IF NOT EXISTS ( SELECT 1 FROM SocialStatuses  WHERE Id = @SocialStatusId)
	BEGIN
		THROW 50100, 'Social status with the same Id is not exist', 1;
	END
	IF NOT EXISTS 
	( 
	  SELECT 1 
	  FROM SocialStatuses
	  JOIN Clients on SocialStatuses.Id = Clients.SocialStatusId
	  JOIN Accounts on Accounts.ClientId = Clients.Id
	  WHERE SocialStatuses.Id = @SocialStatusId
	)
	BEGIN
		THROW 50101, 'The status has no linked accounts', 1;
	END

	UPDATE Accounts
	Set Balance = Balance + 10
	FROM SocialStatuses
		JOIN Clients on SocialStatuses.Id = Clients.SocialStatusId
		JOIN Accounts on Accounts.ClientId = Clients.Id
	Where SocialStatuses.Id = @SocialStatusId
END;
Go

--Insert into SocialStatuses(Name) values ('test')

EXEC AddMoneyToSocStatus 1;
Go

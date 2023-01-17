USE BankingSector;
GO
DROP PROCEDURE AddMoneyToSocStatus
GO

CREATE PROCEDURE AddMoneyToSocStatus
    @SocialStatusId INT
AS
UPDATE Accounts
Set Balance = Balance + 10
FROM SocialStatuses
	JOIN Clients_SocialStatuses on SocialStatuses.Id = Clients_SocialStatuses.SocialStatusId
	JOIN Clients on Clients.Id = Clients_SocialStatuses.ClientId
	JOIN Accounts on Accounts.ClientId = Clients.Id
Where SocialStatuses.Id = @SocialStatusId
Go

EXEC AddMoneyToSocStatus 1501;
Go

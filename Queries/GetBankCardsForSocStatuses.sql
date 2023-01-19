use BankingSector
GO

--With group by
SELECT 
	   SocialStatuses.Id AS 'StatusId',
	   SocialStatuses.Name AS 'StatusName',
	   COUNT(BankCards.Balance) AS 'Cards count'
FROM SocialStatuses
	JOIN Clients_SocialStatuses on SocialStatuses.Id = Clients_SocialStatuses.SocialStatusId
	JOIN Clients on Clients.Id = Clients_SocialStatuses.ClientId
	JOIN Accounts on Accounts.ClientId = Clients.Id
	JOIN BankCards on BankCards.AccountId = Accounts.Id
GROUP BY SocialStatuses.Id, SocialStatuses.Name
ORDER BY [StatusId]
go

--With subquery
SELECT 
	   SocialStatuses.Id AS 'StatusId',
	   SocialStatuses.Name AS 'StatusName',
	   (SELECT COUNT(BankCards.Balance) From BankCards
	   JOIN Accounts on Accounts.Id = BankCards.AccountId
	   JOIN Clients on Clients.Id = Accounts.ClientId
	   JOIN Clients_SocialStatuses on (Clients_SocialStatuses.ClientId = Clients.Id 
	   AND  Clients_SocialStatuses.SocialStatusId = SocialStatuses.Id)) AS 'Cards count'
FROM SocialStatuses
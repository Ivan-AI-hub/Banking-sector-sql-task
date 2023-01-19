use BankingSector
GO

--With group by
SELECT 
	   SocialStatuses.Id AS 'StatusId',
	   SocialStatuses.Name AS 'StatusName',
	   COUNT(BankCards.Balance) AS 'Cards count'
From BankCards
	   RIGHT JOIN Accounts on Accounts.Id = BankCards.AccountId
	   RIGHT JOIN Clients on Clients.Id = Accounts.ClientId
	   JOIN SocialStatuses on SocialStatuses.Id = SocialStatusId
GROUP BY SocialStatuses.Id, SocialStatuses.Name
ORDER BY [StatusId]
go

--With subquery
SELECT 
	   SocialStatuses.Id AS 'StatusId',
	   SocialStatuses.Name AS 'StatusName',
	   (SELECT COUNT(BankCards.Balance) From BankCards
	   JOIN Accounts on Accounts.Id = BankCards.AccountId
	   JOIN Clients on (Clients.Id = Accounts.ClientId and SocialStatuses.Id = SocialStatusId)) AS 'Cards count'
FROM SocialStatuses
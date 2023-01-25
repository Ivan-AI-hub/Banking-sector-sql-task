CREATE DATABASE BankingSector
GO
USE BankingSector
GO

--1 First task
--Create tables
Create table Banks
(
	Id int primary key identity(1,1),
	Name nvarchar(50) not null,
);
go

Create table  Cities
(
	Id int primary key identity(1,1),
	Name nvarchar(50) not null
);
go

Create table  CitiesBanks
(
	Id int primary key identity(1,1),
	BankId int not null,
	CityId int not null,

	CONSTRAINT FK_CitiesBanks_To_Banks FOREIGN KEY (BankId)  REFERENCES Banks (Id) On delete cascade,
	CONSTRAINT FK_CitiesBanks_To_Cities FOREIGN KEY (CityId)  REFERENCES Cities (Id) On delete cascade
);
go

Create table SocialStatuses
(
	Id int primary key identity(1,1),
	Name nvarchar(50) not null,
);
go

Create table Clients
(
	Id int primary key identity(1,1),
	SocialStatusId int not null,
	FirstName nvarchar(50) not null,
	LastName nvarchar(50) not null,

	CONSTRAINT FK_Clients_To_SocialStatuses FOREIGN KEY (SocialStatusId)  REFERENCES SocialStatuses (Id) On delete cascade
);
go


Create table  Accounts
(
	Id int primary key identity(1,1),
	ClientId int not null,
	BankId int not null,
	Balance money not null,

	CONSTRAINT FK_Accounts_To_Banks FOREIGN KEY (BankId)  REFERENCES Banks (Id) On delete cascade,
	CONSTRAINT FK_Accounts_To_Cities FOREIGN KEY (ClientId)  REFERENCES Clients (Id) On delete cascade,

	UNIQUE(ClientId, BankId)
);
go


Create table  BankCards
(
	Id int primary key identity(1,1),
	AccountId int not null,
	Balance money not null,

	CONSTRAINT FK_BankCards_To_Accounts FOREIGN KEY (AccountId)  REFERENCES Accounts (Id) On delete cascade
);
go

--9 Ninth task
--Write a trigger on the Account/Cards tables so that it is impossible to enter values in the balance field if it contradicts the conditions
CREATE TRIGGER BalanceValidateUpdateTrigger ON Accounts
FOR UPDATE
AS
BEGIN
	 IF UPDATE(Balance)
	 BEGIN
		 DECLARE @Balance MONEY, @CardsBalance MONEY

		 SELECT @Balance = inserted.Balance, @CardsBalance = SUM(bc.Balance)
		 FROM inserted 
		 JOIN BankCards AS bc ON inserted.Id = bc.AccountId
		 GROUP BY inserted.Balance

		 IF @CardsBalance > @Balance
		  BEGIN 
			   ROLLBACK TRANSACTION
			   PRINT 'There are not enough funds on the account';
		  END
	  END
END
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

	SELECT @AccountBalance = acc.Balance, @CardsBalance = SUM(bc.Balance)
	FROM Accounts AS acc
	JOIN BankCards AS bc ON acc.Id = AccountId
	WHERE acc.Id = @CurrentAccountID
	GROUP BY acc.Balance

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
GO

--Filling the database with data
DECLARE @OneSideDataCount Int, @ManySideDataCount Int, @Iterator Int
Set @OneSideDataCount = 5
Set @ManySideDataCount = 10
 

begin /*Fill One side tables*/
	Set @Iterator = 0;
	WHILE @Iterator < @OneSideDataCount
		BEGIN
			Insert into Banks(Name) values('Bank' + str(@Iterator))
			Insert into Cities(Name) values('City' + str(@Iterator))
			Insert into SocialStatuses(Name) values('Status' + str(@Iterator))
			Set @Iterator = @Iterator + 1
		END;
end

begin /*Fill Many side tables*/
	Set @Iterator = 0;
	WHILE @Iterator < @ManySideDataCount
		BEGIN
			--Fill CitiesBanks table
			insert into CitiesBanks(BankId, CityId) 
					values
					((SELECT TOP 1 Id FROM Banks order BY NEWID()),
					(SELECT TOP 1 Id FROM Cities order BY NEWID()))
			------------------------------------------

			--Fill Clients table
			Insert into Clients(FirstName, LastName, SocialStatusId) 
			values('FirstName' + str(@Iterator), 'LastName' + str(@Iterator),
			(SELECT TOP 1 Id FROM SocialStatuses order BY NEWID()))
			-------------------------------------------			

			--Fill Accounts table
			insert into Accounts(ClientId, BankId, Balance)
			values 
			((SELECT TOP 1 Id FROM Clients order BY NEWID()),
			(SELECT TOP 1 Id FROM Banks order BY NEWID()),
			RAND()*1000)
			-------------------------------------------			

			--Fill BankCards table
			insert into BankCards(AccountId, Balance)
			values 
			((SELECT TOP 1 Id FROM Accounts order BY NEWID()),
			RAND()*10)
			-------------------------------------------	
			Set @Iterator = @Iterator + 1
		END;
END;
GO

--2 Second task
--Show me a list of banks that have branches in city X (choose one of the cities)
SELECT DISTINCT b.Id AS 'BankId', b.Name AS 'BankName'
FROM Cities
	JOIN CitiesBanks ON Cities.Id = CityId
	JOIN Banks As b ON b.Id = BankId
Where Cities.Name = 'City         0'
GO

--3 Third task
--Get a list of cards with the name of the owner, the balance and the name of the bank
SELECT 
	   bc.Id AS 'CardId',
	   bc.Balance AS 'Balance',
	   cl.FirstName + ' ' + cl.LastName AS 'ClientName',
	   b.Name AS 'Bank name'
FROM BankCards AS bc
	JOIN Accounts on Accounts.Id = AccountId
	JOIN Clients AS cl on cl.Id = ClientId
	JOIN Banks AS b on b.Id = BankId
GO

--4 Fourth task
--Show a list of bank accounts whose balance does not match the amount of the balance on the cards.
SELECT 
	   acc.Id AS 'Account id',
	   acc.Balance As 'Account balance',
	   COUNT(bc.Balance) As 'Cards count',
	   IsNull(SUM(bc.Balance), 0) AS 'Cards balance',
	   IsNull(acc.Balance - SUM(bc.Balance), acc.Balance) AS 'Free balance'
FROM BankCards AS bc
	RIGHT JOIN Accounts AS acc on acc.Id = AccountId
GROUP BY acc.Id, acc.Balance
Having acc.Balance != IsNull(SUM(bc.Balance), 0)
GO

--5 Fifth task
--Output the number of bank cards for each social status (2 implementations, GROUP BY and subquery)

--With group by
SELECT 
	   ss.Id AS 'StatusId',
	   ss.Name AS 'StatusName',
	   COUNT(bc.Balance) AS 'CardsCount'
From BankCards AS bc
	   RIGHT JOIN Accounts on Accounts.Id = bc.AccountId
	   RIGHT JOIN Clients on Clients.Id = Accounts.ClientId
	   RIGHT JOIN SocialStatuses AS ss on ss.Id = SocialStatusId
GROUP BY ss.Id, ss.Name
ORDER BY [StatusId]
go

--With subquery
SELECT 
	   ss.Id AS 'StatusId',
	   ss.Name AS 'StatusName',
	   (SELECT COUNT(bc.Balance) 
	   From BankCards AS bc
	   RIGHT JOIN Accounts AS acc on acc.Id = bc.AccountId
	   RIGHT JOIN Clients on (Clients.Id = acc.ClientId and ss.Id = SocialStatusId)) AS 'CardsCount'
FROM SocialStatuses AS ss
GO

--6 Sixth task
--Write a stored procedure that will add $10 to each bank account for a certain social status
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
	  FROM Accounts
		JOIN Clients on (Accounts.ClientId = Clients.Id and SocialStatusId = @SocialStatusId)
	)
	BEGIN
		THROW 50101, 'The status has no linked accounts', 1;
	END

	UPDATE Accounts
	Set Balance = Balance + 10
	FROM Accounts
		JOIN Clients on (Accounts.ClientId = Clients.Id and SocialStatusId = @SocialStatusId)
END;
Go

--Procedure test
Declare @TestSocStatusId INT
SET @TestSocStatusId = 1

Select acc.Id AS 'AccountId', acc.Balance
FROM Accounts AS acc
	JOIN Clients on (SocialStatusId = @TestSocStatusId and acc.ClientId = Clients.Id)


EXEC AddMoneyToSocStatus @TestSocStatusId;

Select acc.Id AS 'AccountId', acc.Balance
FROM Accounts AS acc
	JOIN Clients on (SocialStatusId = @TestSocStatusId and acc.ClientId = Clients.Id)
Go

--7 Seventh task
--Get a list of available funds for each client.
SELECT 
	cl.Id AS 'ClientId',
	COUNT(acc.Id) AS 'Accounts count',
	IsNull(IsNull(SUM(acc.Balance) - SUM(bc.Balance), SUM(acc.Balance)),0) AS 'FreeBalance'
FROM BankCards AS bc
	RIGHT JOIN Accounts AS acc on acc.Id = AccountId
	RIGHT JOIN Clients as cl on cl.Id = acc.ClientId
GROUP BY cl.Id, cl.FirstName, cl.LastName
GO

--8 Eighth task
--Write a procedure that will transfer a certain amount from the account to the card of this account.
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

		IF (SELECT acc.Balance - SUM(bc.Balance)
			FROM Accounts AS acc
			JOIN BankCards AS bc ON acc.Id = AccountId 
			WHERE acc.Id = @AccountId
			GROUP BY acc.Balance) < 0
		BEGIN
			ROLLBACK TRANSACTION;
			THROW 50103, 'There are not enough funds on the account', 1;
		END;

	COMMIT TRANSACTION
END;
Go

--Procedure test
Declare @TestAccountId INT, @TestBankCardId INT, @TestBalance MONEY
SET @TestAccountId = 1
SET @TestBankCardId = 1
SET @TestBalance = 1

SELECT acc.Id AS 'AccounId', bc.Id AS 'CardID', bc.Balance AS 'Card balance', acc.Balance AS 'Account balance'
FROM Accounts AS acc
JOIN BankCards AS bc
ON acc.Id = AccountId
WHERE AccountId = @TestAccountId and bc.Id = @TestBankCardId

EXEC TransferMoney @TestAccountId, @TestBankCardId, @TestBalance;

SELECT acc.Id AS 'AccounId', bc.Id AS 'CardID', bc.Balance AS 'Card balance', acc.Balance AS 'Account balance'
FROM Accounts AS acc
JOIN BankCards AS bc ON acc.Id = AccountId
WHERE AccountId = @TestAccountId and bc.Id = @TestBankCardId
GO

--Accounts update trigger test
--wrong
Declare @TestAccountId INT
SET @TestAccountId = (SELECT TOP(1) acc.Id 
					  FROM Accounts AS acc
					  JOIN BankCards on acc.Id = AccountId)

SELECT acc.Id, Sum(bc.Balance) AS 'ÑardBalance', acc.Balance
FROM Accounts AS acc 
JOIN BankCards AS bc ON acc.Id = AccountId
GROUP BY acc.Id,  acc.Balance
Having acc.Id = @TestAccountId

Update Accounts
Set Balance = -100
Where Id = @TestAccountId
Go 

--successfully
Declare @TestAccountId INT
SET @TestAccountId = (SELECT TOP(1) acc.Id 
					  FROM Accounts AS acc
					  JOIN BankCards on acc.Id = AccountId)

SELECT acc.Id, Sum(bc.Balance) AS 'ÑardBalance', acc.Balance
FROM Accounts AS acc 
JOIN BankCards AS bc ON acc.Id = AccountId
GROUP BY acc.Id,  acc.Balance
Having acc.Id = @TestAccountId

Update Accounts
Set Balance = 10000
Where Id = @TestAccountId

SELECT acc.Id, Sum(bc.Balance) AS 'ÑardBalance', acc.Balance
FROM Accounts AS acc 
JOIN BankCards AS bc ON acc.Id = AccountId
GROUP BY acc.Id,  acc.Balance
Having acc.Id = @TestAccountId
Go 

--BankCards update trigger test
--successfully
Declare @TestCardId INT, @TestAccountId INT
SET @TestCardId = 1
SET @TestAccountId = (SELECT AccountId FROM BankCards Where Id = @TestCardId)

SELECT acc.Id, Sum(bc.Balance) AS 'ÑardBalance', acc.Balance
FROM Accounts AS acc 
JOIN BankCards AS bc ON acc.Id = AccountId
GROUP BY acc.Id,  acc.Balance
Having acc.Id = @TestAccountId

Update BankCards
Set Balance = 0
Where Id = @TestCardId

SELECT acc.Id, Sum(bc.Balance) AS 'ÑardBalance', acc.Balance
FROM Accounts AS acc 
JOIN BankCards AS bc ON acc.Id = AccountId
GROUP BY acc.Id,  acc.Balance
Having acc.Id = @TestAccountId
Go 

--Wrong
Declare @TestCardId INT, @TestAccountId INT
SET @TestCardId = 1
SET @TestAccountId = (SELECT AccountId FROM BankCards Where Id = @TestCardId)


SELECT acc.Id, Sum(bc.Balance) AS 'ÑardBalance', acc.Balance
FROM Accounts AS acc 
JOIN BankCards AS bc ON acc.Id = AccountId
GROUP BY acc.Id,  acc.Balance
Having acc.Id = @TestAccountId

Update BankCards
Set Balance = 10000
Where Id = @TestCardId
GO
Use master
GO
DROP DATABASE BankingSector
GO
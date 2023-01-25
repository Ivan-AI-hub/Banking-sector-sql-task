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

		 SELECT @Balance = inserted.Balance, @CardsBalance = SUM(BankCards.Balance)
		 FROM inserted JOIN BankCards ON inserted.Id = BankCards.AccountId
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
go

--2 Second task
--Show me a list of banks that have branches in city X (choose one of the cities)
SELECT Banks.Id AS 'BankId', Banks.Name AS 'BankName'
FROM Cities
	JOIN CitiesBanks ON Cities.Id = CityId
	JOIN Banks ON Banks.Id = BankId
Where Cities.Id = 1
GO

--3 Third task
--Get a list of cards with the name of the owner, the balance and the name of the bank
SELECT 
	   BankCards.Id AS 'Card id',
	   BankCards.Balance AS 'Balance',
	   Clients.FirstName + ' ' + Clients.LastName AS 'Client name',
	   Banks.Name AS 'Bank name'
FROM BankCards
	JOIN Accounts on Accounts.Id = AccountId
	JOIN Clients on Clients.Id = ClientId
	JOIN Banks on Banks.Id = BankId
GO

--4 Fourth task
--Show a list of bank accounts whose balance does not match the amount of the balance on the cards.
SELECT 
	   Accounts.Id AS 'Account id',
	   Accounts.Balance As 'Account balance',
	   COUNT(BankCards.Balance) As 'Cards count',
	   IsNull(SUM(BankCards.Balance), 0) AS 'Cards balance',
	   IsNull(Accounts.Balance - SUM(BankCards.Balance), Accounts.Balance) AS 'Free balance'
FROM BankCards
	RIGHT JOIN Accounts on Accounts.Id = AccountId
GROUP BY Accounts.Id, Accounts.Balance
Having Accounts.Balance != IsNull(SUM(BankCards.Balance), 0)
GO

--5 Fifth task
--Output the number of bank cards for each social status (2 implementations, GROUP BY and subquery)

--With group by
SELECT 
	   SocialStatuses.Id AS 'StatusId',
	   SocialStatuses.Name AS 'StatusName',
	   COUNT(BankCards.Balance) AS 'Cards count'
From BankCards
	   RIGHT JOIN Accounts on Accounts.Id = BankCards.AccountId
	   RIGHT JOIN Clients on Clients.Id = Accounts.ClientId
	   RIGHT JOIN SocialStatuses on SocialStatuses.Id = SocialStatusId
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

--Procedure test
Declare @TestSocStatusId INT
SET @TestSocStatusId = 1

Select Accounts.Id AS 'AccountId', Accounts.Balance
FROM SocialStatuses
	JOIN Clients on SocialStatuses.Id = Clients.SocialStatusId
	JOIN Accounts on Accounts.ClientId = Clients.Id
Where SocialStatuses.Id = @TestSocStatusId

EXEC AddMoneyToSocStatus @TestSocStatusId;

Select Accounts.Id AS 'AccountId', Accounts.Balance
FROM SocialStatuses
	JOIN Clients on SocialStatuses.Id = Clients.SocialStatusId
	JOIN Accounts on Accounts.ClientId = Clients.Id
Where SocialStatuses.Id = @TestSocStatusId
Go

--7 Seventh task
--Get a list of available funds for each client.
SELECT 
	Accounts.Id AS 'Account id',
	IsNull(Accounts.Balance - SUM(BankCards.Balance), Accounts.Balance) AS 'Free balance'
FROM BankCards
	RIGHT JOIN Accounts on Accounts.Id = AccountId
GROUP BY Accounts.Id, Accounts.Balance
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

--Procedure test
Declare @TestAccountId INT, @TestBankCardId INT, @TestBalance MONEY
SET @TestAccountId = 1
SET @TestBankCardId = 1
SET @TestBalance = 1

SELECT Accounts.Id AS 'AccounId', BankCards.Id AS 'CardID', BankCards.Balance AS 'Card balance', Accounts.Balance AS 'Account balance'
FROM Accounts JOIN BankCards ON Accounts.Id = AccountId
WHERE AccountId = @TestAccountId and BankCards.Id = @TestBankCardId

EXEC TransferMoney @TestAccountId, @TestBankCardId, @TestBalance;

SELECT Accounts.Id AS 'AccounId', BankCards.Id AS 'CardID', BankCards.Balance AS 'Card balance', Accounts.Balance AS 'Account balance'
FROM Accounts JOIN BankCards ON Accounts.Id = AccountId
WHERE AccountId = @TestAccountId  and BankCards.Id = @TestBankCardId
GO

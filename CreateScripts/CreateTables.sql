use BankingSector

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

Create table  Cities_Banks
(
	Id int primary key identity(1,1),
	BankId int not null,
	CitieId int not null,

	CONSTRAINT FK_Cities_Banks_To_Banks FOREIGN KEY (BankId)  REFERENCES Banks (Id) On delete cascade,
	CONSTRAINT FK_Cities_Banks_To_Cities FOREIGN KEY (CitieId)  REFERENCES Cities (Id) On delete cascade
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

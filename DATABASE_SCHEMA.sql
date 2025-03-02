SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Employes] (
    [EmployeID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Nom] NVARCHAR(100) NULL,
    [Entreprise] NVARCHAR(100) NULL,
    [Poste] NVARCHAR(100) NULL,
    [Coordonnees] NVARCHAR(255) NULL,
    [Email] NVARCHAR(255) NULL,
    [ZoneGeographique] NVARCHAR(100) NULL,
    [EligibleTransport] BIT NULL DEFAULT (1)
);

CREATE TABLE [dbo].[Absences] (
    [AbsenceID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [EmployeID] INT NULL,
    [DateAbsence] DATE NULL,
    [Motif] NVARCHAR(255) NULL,
    FOREIGN KEY ([EmployeID]) REFERENCES [dbo].[Employes]([EmployeID])
);

CREATE TABLE [dbo].[Conducteurs] (
    [ConducteurID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Nom] NVARCHAR(100) NULL,
    [Affectation] NVARCHAR(255) NULL,
    [Experience] NVARCHAR(MAX) NULL,
    [Disponible] BIT NULL DEFAULT (1),
    [Qualifications] NVARCHAR(255) NULL
);

CREATE TABLE [dbo].[Vehicules] (
    [VehiculeID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Type] NVARCHAR(50) NULL,
    [Capacite] INT NULL,
    [Immatriculation] NVARCHAR(50) UNIQUE,
    [Maintenance] DATE NULL,
    [ConsommationCarburant] DECIMAL(18, 2) NULL,
    [FraisMaintenance] DECIMAL(18, 2) NULL,
    [ZoneGeographique] NVARCHAR(100) NULL,
    [Disponible] BIT NULL DEFAULT (1),
    [DerniereMaintenance] DATE NULL,
    [Kilometrage] INT NULL
);

CREATE TABLE [dbo].[Trajets] (
    [TrajetID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Itineraire] NVARCHAR(255) NULL,
    [DateDepart] DATE NULL,
    [HeureDepart] TIME(7) NULL,
    [DateArrivee] DATE NULL,
    [HeureArrivee] TIME(7) NULL,
    [PointCollecte] NVARCHAR(255) NULL,
    [PointDepot] NVARCHAR(255) NULL,
    [Distance] DECIMAL(18, 2) NULL,
    [Peages] DECIMAL(18, 2) NULL,
    [Statut] NVARCHAR(50) NULL CHECK ([Statut] IN ('Retarde´', 'Annule´', 'Termine´', 'En cours')),
    [RaisonAnnulation] NVARCHAR(255) NULL,
    [CoutTotal] DECIMAL(18, 2) NULL
);

CREATE TABLE [dbo].[Factures] (
    [FactureID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [TrajetID] INT NULL,
    [EmployeID] INT NULL,
    [VehiculeID] INT NULL,
    [DateFacture] DATE NULL,
    [TotalCost] DECIMAL(18, 2) NULL,
    FOREIGN KEY ([EmployeID]) REFERENCES [dbo].[Employes]([EmployeID]),
    FOREIGN KEY ([TrajetID]) REFERENCES [dbo].[Trajets]([TrajetID]),
    FOREIGN KEY ([VehiculeID]) REFERENCES [dbo].[Vehicules]([VehiculeID])
);

CREATE TABLE [dbo].[Incidents] (
    [IncidentID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [TrajetID] INT NULL,
    [Cause] NVARCHAR(255) NULL,
    [TempsPerdu] INT NULL,
    [Responsable] NVARCHAR(100) NULL,
    [DateIncident] DATE NULL,
    FOREIGN KEY ([TrajetID]) REFERENCES [dbo].[Trajets]([TrajetID])
);

CREATE TABLE [dbo].[Maintenance] (
    [MaintenanceID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [VehiculeID] INT NULL,
    [DateMaintenance] DATE NULL,
    [Description] NVARCHAR(255) NULL,
    [CoutReparation] DECIMAL(18, 2) NULL,
    [CoutPieces] DECIMAL(18, 2) NULL,
    FOREIGN KEY ([VehiculeID]) REFERENCES [dbo].[Vehicules]([VehiculeID])
);

CREATE TABLE [dbo].[Notifications] (
    [NotificationID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Message] NVARCHAR(255) NULL,
    [Destinataire] NVARCHAR(100) NULL,
    [DateNotification] DATE NULL
);

CREATE TABLE [dbo].[Reservations] (
    [ReservationID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [EmployeID] INT NULL,
    [TrajetID] INT NULL,
    [VehiculeID] INT NULL,
    [ConducteurID] INT NULL,
    [DateAffectation] DATE NULL,
    FOREIGN KEY ([ConducteurID]) REFERENCES [dbo].[Conducteurs]([ConducteurID]),
    FOREIGN KEY ([EmployeID]) REFERENCES [dbo].[Employes]([EmployeID]),
    FOREIGN KEY ([TrajetID]) REFERENCES [dbo].[Trajets]([TrajetID]),
    FOREIGN KEY ([VehiculeID]) REFERENCES [dbo].[Vehicules]([VehiculeID])
);
USE TransportDB; -- Replace with your database name
GO

-- Table pour les employ�s
CREATE TABLE Employes (
    EmployeID INT IDENTITY(1,1) PRIMARY KEY,
    Nom NVARCHAR(100),
    Entreprise NVARCHAR(100),
    Poste NVARCHAR(100),
    Coordonnees NVARCHAR(255)
);

-- Table pour les v�hicules
CREATE TABLE Vehicules (
    VehiculeID INT IDENTITY(1,1) PRIMARY KEY,
    Type NVARCHAR(50),
    Capacite INT,
    Immatriculation NVARCHAR(50) UNIQUE,
    Maintenance DATE
);

-- Table pour les trajets
CREATE TABLE Trajets (
    TrajetID INT IDENTITY(1,1) PRIMARY KEY,
    Itineraire NVARCHAR(255),
    DateDepart DATE,
    HeureDepart TIME,
    DateArrivee DATE,
    HeureArrivee TIME,
    PointCollecte NVARCHAR(255),
    PointDepot NVARCHAR(255)
);

-- Table pour les conducteurs
CREATE TABLE Conducteurs (
    ConducteurID INT IDENTITY(1,1) PRIMARY KEY,
    Nom NVARCHAR(100),
    Affectation NVARCHAR(255),
    HistoriqueConduite NVARCHAR(MAX)
);

-- Table pour les r�servations et affectations
CREATE TABLE Reservations (
    ReservationID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeID INT,
    TrajetID INT,
    VehiculeID INT,
    ConducteurID INT,
    FOREIGN KEY (EmployeID) REFERENCES Employes(EmployeID),
    FOREIGN KEY (TrajetID) REFERENCES Trajets(TrajetID),
    FOREIGN KEY (VehiculeID) REFERENCES Vehicules(VehiculeID),
    FOREIGN KEY (ConducteurID) REFERENCES Conducteurs(ConducteurID)
);

CREATE TABLE Evaluations (
    EvaluationID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeID INT,
    TrajetID INT,
    Score INT CHECK (Score BETWEEN 1 AND 10), -- Score entre 1 et 10
    Commentaire NVARCHAR(500),
    DateEvaluation DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (EmployeID) REFERENCES Employes(EmployeID),
    FOREIGN KEY (TrajetID) REFERENCES Trajets(TrajetID)
);

CREATE TABLE Points (
    PointID INT IDENTITY(1,1) PRIMARY KEY,
    Nom NVARCHAR(255),
    Latitude FLOAT,
    Longitude FLOAT,
    Type NVARCHAR(50) CHECK (Type IN ('Collecte', 'Depot'))
);

CREATE TABLE EvaluationsVehicules (
    EvaluationID INT IDENTITY(1,1) PRIMARY KEY,
    VehiculeID INT,
    EmployeID INT,
    Note INT CHECK (Note BETWEEN 1 AND 5),
    Commentaire NVARCHAR(500),
    DateEvaluation DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (VehiculeID) REFERENCES Vehicules(VehiculeID),
    FOREIGN KEY (EmployeID) REFERENCES Employes(EmployeID)
);

USE TransportDB;
GO

-- Table pour les absences
CREATE TABLE Absences (
    AbsenceID INT IDENTITY(1,1) PRIMARY KEY, -- Identifiant unique de l'absence
    EmployeID INT, -- Identifiant de l'employé absent
    DateAbsence DATE, -- Date de l'absence
    Motif NVARCHAR(255), -- Motif de l'absence (optionnel)
    FOREIGN KEY (EmployeID) REFERENCES Employes(EmployeID) -- Clé étrangère vers la table Employes
);
GO


USE TransportDB;
GO

-- Table pour les factures
CREATE TABLE Factures (
    FactureID INT IDENTITY(1,1) PRIMARY KEY, -- Identifiant unique de la facture
    TrajetID INT, -- Identifiant du trajet facturé
    EmployeID INT, -- Identifiant de l'employé impliqué
    VehiculeID INT, -- Identifiant du véhicule utilisé
    DateFacture DATE, -- Date de génération de la facture
    TotalCost DECIMAL(18, 2), -- Coût total de la facture
    FOREIGN KEY (TrajetID) REFERENCES Trajets(TrajetID), -- Clé étrangère vers la table Trajets
    FOREIGN KEY (EmployeID) REFERENCES Employes(EmployeID), -- Clé étrangère vers la table Employes
    FOREIGN KEY (VehiculeID) REFERENCES Vehicules(VehiculeID) -- Clé étrangère vers la table Vehicules
);
GO



USE TransportDB;
GO

-- Table pour les incidents
CREATE TABLE Incidents (
    IncidentID INT IDENTITY(1,1) PRIMARY KEY, -- Identifiant unique de l'incident
    TrajetID INT, -- Identifiant du trajet concerné
    Cause NVARCHAR(255), -- Cause de l'incident (météo, panne, accident, etc.)
    TempsPerdu INT, -- Temps perdu en minutes
    Responsable NVARCHAR(100), -- Responsable à notifier
    DateIncident DATE, -- Date de l'incident
    FOREIGN KEY (TrajetID) REFERENCES Trajets(TrajetID) -- Clé étrangère vers la table Trajets
);
GO

-- Table pour les notifications
CREATE TABLE Notifications (
    NotificationID INT IDENTITY(1,1) PRIMARY KEY, -- Identifiant unique de la notification
    Message NVARCHAR(255), -- Message de la notification
    Destinataire NVARCHAR(100), -- Destinataire de la notification
    DateNotification DATE -- Date de la notification
);
GO


USE TransportDB;
GO

-- Table pour la maintenance des véhicules
CREATE TABLE Maintenance (
    MaintenanceID INT IDENTITY(1,1) PRIMARY KEY, -- Identifiant unique de la maintenance
    VehiculeID INT, -- Identifiant du véhicule
    DateMaintenance DATE, -- Date de la maintenance
    Description NVARCHAR(255), -- Description de la maintenance
    CoutReparation DECIMAL(18, 2), -- Coût des réparations
    CoutPieces DECIMAL(18, 2), -- Coût des pièces de remplacement
    FOREIGN KEY (VehiculeID) REFERENCES Vehicules(VehiculeID) -- Clé étrangère vers la table Vehicules
);
GO
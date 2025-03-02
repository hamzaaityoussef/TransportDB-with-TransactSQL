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

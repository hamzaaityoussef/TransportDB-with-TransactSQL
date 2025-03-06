
--1/ proc�dure stock�e qui ins�re un nouvel employ�
CREATE PROCEDURE sp_InsertEmploye
    @Nom NVARCHAR(100),
    @Entreprise NVARCHAR(100),
    @Poste NVARCHAR(100),
    @Coordonnees NVARCHAR(255),
    @Email NVARCHAR(100) 
AS
BEGIN
    
    IF EXISTS (SELECT 1 FROM Employes WHERE Email = @Email)
    BEGIN
        PRINT 'Erreur : Cet email est d�j� utilis� par un autre employ�.';
        RETURN; 
    END

    
    INSERT INTO Employes (Nom, Entreprise, Poste, Coordonnees,Email)
    VALUES (@Nom, @Entreprise, @Poste, @Coordonnees,@Email);

    PRINT 'Nouvel employ� ajout� avec succ�s.';
END
GO



--3/ Proc�dure Stock�e pour Supprimer un Employ� et annuler les trajets r�serv�s	
CREATE PROCEDURE sp_DeleteEmploye
    @EmployeID INT 
AS
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM Employes WHERE EmployeID = @EmployeID)
    BEGIN
        PRINT 'Erreur : L''employ� avec l''ID ' + CAST(@EmployeID AS NVARCHAR) + ' n''existe pas.';
        RETURN;
    END

    
    BEGIN TRY
        BEGIN TRANSACTION; 

        -- Ici, nous annulons simplement les trajets en les supprimant de la table Reservations
        DELETE FROM Reservations
        WHERE EmployeID = @EmployeID;

        DELETE FROM Employes
        WHERE EmployeID = @EmployeID;

        COMMIT TRANSACTION;

        PRINT 'L''employ� avec l''ID ' + CAST(@EmployeID AS NVARCHAR) + ' a �t� supprim� avec succ�s.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        PRINT 'Erreur : ' + ERROR_MESSAGE();
    END CATCH
END
GO







--5/ Proc�dure Stock�e pour Mettre � Jour un V�hicule
CREATE PROCEDURE sp_UpdateVehicule
    @VehiculeID INT, 
    @Type NVARCHAR(50), 
    @Capacite INT, 
    @Immatriculation NVARCHAR(50),
    @Maintenance DATE 
AS
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM Vehicules WHERE VehiculeID = @VehiculeID)
    BEGIN
        PRINT 'Erreur : Le v�hicule avec l''ID ' + CAST(@VehiculeID AS NVARCHAR) + ' n''existe pas.';
        RETURN;
    END

    -- V�rifier les contraintes d'int�grit�
    --  La capacit� ne doit pas d�passer 100
    IF @Capacite > 100
    BEGIN
        PRINT 'Erreur : La capacit� du v�hicule ne peut pas d�passer 100.';
        RETURN;
    END

    -- V�rifier que l'immatriculation n'est pas d�j� utilis�e par un autre v�hicule
    IF EXISTS (SELECT 1 FROM Vehicules WHERE Immatriculation = @Immatriculation AND VehiculeID <> @VehiculeID)
    BEGIN
        PRINT 'Erreur : L''immatriculation ' + @Immatriculation + ' est d�j� utilis�e par un autre v�hicule.';
        RETURN;
    END

    
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Vehicules
        SET 
            Type = @Type,
            Capacite = @Capacite,
            Immatriculation = @Immatriculation,
            Maintenance = @Maintenance
        WHERE VehiculeID = @VehiculeID;

        
        COMMIT TRANSACTION;

       
        PRINT 'Les informations du v�hicule avec l''ID ' + CAST(@VehiculeID AS NVARCHAR) + ' ont �t� mises � jour avec succ�s.';
    END TRY
    BEGIN CATCH
        
        ROLLBACK TRANSACTION;

        
        PRINT 'Erreur : ' + ERROR_MESSAGE();
    END CATCH
END
GO






-- 7/ Proc�dure Stock�e pour V�rifier la Disponibilit� des V�hicules

CREATE PROCEDURE sp_CheckVehiculeDisponibility
    @Date DATE 
AS
BEGIN
    
    SELECT 
        V.VehiculeID,
        V.Type,
        V.Capacite,
        V.Immatriculation,
        V.Maintenance
    FROM 
        Vehicules V
    WHERE 
        
        V.Maintenance IS NULL OR V.Maintenance <> @Date
        AND
        -- V�rifier que le v�hicule n'est pas d�j� r�serv� pour cette date
        NOT EXISTS (
            SELECT 1
            FROM Reservations R
            JOIN Trajets T ON R.TrajetID = T.TrajetID
            WHERE R.VehiculeID = V.VehiculeID
              AND T.DateDepart = @Date
        )
    ORDER BY 
        V.VehiculeID;
END
GO


-- 9 /  proc�dure stock�e pour enregistrer un trajet effectu�

CREATE PROCEDURE EnregistrerTrajetEffectue
    @EmployeID INT,
    @VehiculeID INT,
    @ConducteurID INT,
    @Itineraire NVARCHAR(255),
    @DateDepart DATE,
    @HeureDepart TIME,
    @DateArrivee DATE,
    @HeureArrivee TIME,
    @PointCollecte NVARCHAR(255),
    @PointDepot NVARCHAR(255),
    @DistanceKM DECIMAL(10,2),
    @TarifParKM DECIMAL(10,2),
    @TarifParHeure DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TrajetID INT, @DureeHeures DECIMAL(10,2), @CoutTotal DECIMAL(10,2);
    
    -- Ins�rer un nouveau trajet
    INSERT INTO Trajets (Itineraire, DateDepart, HeureDepart, DateArrivee, HeureArrivee, PointCollecte, PointDepot)
    VALUES (@Itineraire, @DateDepart, @HeureDepart, @DateArrivee, @HeureArrivee, @PointCollecte, @PointDepot);
    
    SET @TrajetID = SCOPE_IDENTITY();
    
    -- Calcul de la dur�e en heures
    SET @DureeHeures = DATEDIFF(MINUTE, CAST(@DateDepart AS DATETIME) + CAST(@HeureDepart AS DATETIME),
                                       CAST(@DateArrivee AS DATETIME) + CAST(@HeureArrivee AS DATETIME)) / 60.0;
    
    -- Calcul du co�t total
    SET @CoutTotal = (@DistanceKM * @TarifParKM) + (@DureeHeures * @TarifParHeure);
    
    -- Enregistrer la r�servation avec les d�tails
    INSERT INTO Reservations (EmployeID, TrajetID, VehiculeID, ConducteurID)
    VALUES (@EmployeID, @TrajetID, @VehiculeID, @ConducteurID);
    
    -- Retourner le co�t total
    SELECT @CoutTotal AS CoutTotal;
END;

-- Question 11 

USE TransportDB;
GO
CREATE PROCEDURE sp_CalculateTotalCostForVehicle
    @VehiculeID INT, -- Identifiant du véhicule
    @StartDate DATE, -- Date de début de la période
    @EndDate DATE, -- Date de fin de la période
    @PrixCarburant DECIMAL(18, 2) -- Prix du carburant par unité (ex: L/km)
AS
BEGIN
    -- Variables pour les coûts
    DECLARE @TotalCost DECIMAL(18, 2) = 0;
    DECLARE @FuelCost DECIMAL(18, 2) = 0;
    DECLARE @TollCost DECIMAL(18, 2) = 0;
    DECLARE @MaintenanceCost DECIMAL(18, 2) = 0;
    DECLARE @Discount DECIMAL(18, 2) = 0; -- Remise applicable

    -- Calculer les coûts pour chaque trajet
    SELECT 
        @FuelCost = SUM(T.Distance * V.ConsommationCarburant * @PrixCarburant), -- Coût du carburant
        @TollCost = SUM(T.Peages), -- Coût des péages
        @MaintenanceCost = SUM(V.FraisMaintenance) -- Coût de maintenance
    FROM 
        Trajets T
    JOIN 
        Reservations R ON T.TrajetID = R.TrajetID -- Relier les trajets aux réservations
    JOIN 
        Vehicules V ON R.VehiculeID = V.VehiculeID -- Relier les réservations aux véhicules
    WHERE 
        R.VehiculeID = @VehiculeID
        AND T.DateDepart BETWEEN @StartDate AND @EndDate;

    -- Appliquer une remise (exemple : 10% de remise)
    SET @Discount = (@FuelCost + @TollCost + @MaintenanceCost) * 0.10;

    -- Calculer le coût total
    SET @TotalCost = (@FuelCost + @TollCost + @MaintenanceCost) - @Discount;

    -- Afficher le résultat
    SELECT 
        @VehiculeID AS VehiculeID,
        @FuelCost AS FuelCost,
        @TollCost AS TollCost,
        @MaintenanceCost AS MaintenanceCost,
        @Discount AS Discount,
        @TotalCost AS TotalCost;
END
GO

-- Question 13

CREATE PROCEDURE sp_GetEmployeesAssignedToVehicle
    @VehiculeID INT, -- Identifiant du véhicule
    @StartDate DATE, -- Date de début de la période
    @EndDate DATE -- Date de fin de la période
AS
BEGIN
    SELECT 
        E.EmployeID,
        E.Nom,
        E.Poste,
        T.TrajetID,
        T.DateDepart,
        T.DateArrivee
    FROM 
        Employes E
    JOIN 
        Reservations R ON E.EmployeID = R.EmployeID -- Relier les employés aux réservations
    JOIN 
        Trajets T ON R.TrajetID = T.TrajetID -- Relier les réservations aux trajets
    WHERE 
        R.VehiculeID = @VehiculeID -- Filtrer par véhicule
        AND T.DateDepart BETWEEN @StartDate AND @EndDate -- Filtrer par période
        AND E.EmployeID NOT IN (
            SELECT EmployeID 
            FROM Absences 
            WHERE DateAbsence BETWEEN @StartDate AND @EndDate -- Exclure les employés absents
        );
END
GO


EXEC sp_GetEmployeesAssignedToVehicle 
    @VehiculeID = 5, 
    @StartDate = '2023-10-01', 
    @EndDate = '2023-10-31';


-- Question 15 : 

CREATE PROCEDURE sp_AssignDriverToVehicle
    @VehiculeID INT, 
    @Date DATE 
AS
BEGIN
    DECLARE @ConducteurID INT;

    -- Trouver un conducteur disponible et qualifié
    SELECT TOP 1
        @ConducteurID = C.ConducteurID
    FROM 
        Conducteurs C
    WHERE 
        C.Disponible = 1 -- Conducteur disponible
        AND C.Experience >= 5 
        AND C.Qualifications LIKE '%Permis D%' 
        AND NOT EXISTS (
            SELECT 1 
            FROM Reservations R 
            JOIN Trajets T ON R.TrajetID = T.TrajetID
            WHERE R.ConducteurID = C.ConducteurID
              AND T.DateDepart = @Date 
        )
    ORDER BY 
        C.Experience DESC;

    -- Affecter le conducteur au véhicule
    IF @ConducteurID IS NOT NULL
    BEGIN
        INSERT INTO Reservations (VehiculeID, ConducteurID, DateAffectation)
        VALUES (@VehiculeID, @ConducteurID, @Date);

        PRINT 'Conducteur ' + CAST(@ConducteurID AS NVARCHAR) + ' affecté au véhicule ' + CAST(@VehiculeID AS NVARCHAR);
    END
    ELSE
    BEGIN
        PRINT 'Aucun conducteur disponible pour cette date.';
    END
END
GO


-- Question 17 :

CREATE PROCEDURE sp_GenerateInvoiceForTrip
    @TrajetID INT -- Identifiant du trajet
AS
BEGIN
    DECLARE @FactureID INT;
    DECLARE @TotalCost DECIMAL(18, 2);

    -- Récupérer les informations du trajet et calculer le coût total
    SELECT 
        @TotalCost = (T.Peages + (V.ConsommationCarburant * T.Distance) + V.FraisMaintenance)
    FROM 
        Trajets T
    JOIN 
        Reservations R ON T.TrajetID = R.TrajetID -- Relier les trajets aux réservations
    JOIN 
        Vehicules V ON R.VehiculeID = V.VehiculeID -- Relier les réservations aux véhicules
    WHERE 
        T.TrajetID = @TrajetID;

    -- Insérer la facture dans la table Factures
    INSERT INTO Factures (TrajetID, EmployeID, VehiculeID, DateFacture, TotalCost)
    SELECT 
        T.TrajetID,
        R.EmployeID,
        R.VehiculeID,
        GETDATE(), -- Date actuelle
        @TotalCost
    FROM 
        Trajets T
    JOIN 
        Reservations R ON T.TrajetID = R.TrajetID
    WHERE 
        T.TrajetID = @TrajetID;

    -- Récupérer l'identifiant de la facture générée
    SET @FactureID = SCOPE_IDENTITY();

    -- Retourner la facture générée
    SELECT 
        F.FactureID,
        F.TrajetID,
        E.Nom AS EmployeeName,
        V.Immatriculation AS VehicleRegistration,
        T.Distance,
        T.Peages AS TollCost,
        V.ConsommationCarburant * T.Distance AS FuelCost,
        V.FraisMaintenance AS MaintenanceCost,
        F.TotalCost
    FROM 
        Factures F
    JOIN 
        Trajets T ON F.TrajetID = T.TrajetID
    JOIN 
        Employes E ON F.EmployeID = E.EmployeID
    JOIN 
        Vehicules V ON F.VehiculeID = V.VehiculeID
    WHERE 
        F.FactureID = @FactureID;
END
GO




-- Question 19 :

CREATE PROCEDURE sp_CalculateTotalTripDuration
    @VehiculeID INT, -- Identifiant du véhicule
    @StartDate DATE, -- Date de début de la période
    @EndDate DATE -- Date de fin de la période
AS
BEGIN
    SELECT 
        V.VehiculeID,
        SUM(DATEDIFF(HOUR, T.DateDepart, T.DateArrivee)) AS TotalDurationHours,
        SUM(DATEDIFF(MINUTE, T.DateDepart, T.DateArrivee)) AS TotalDurationMinutes
    FROM 
        Trajets T
    JOIN 
        Reservations R ON T.TrajetID = R.TrajetID -- Relier les trajets aux réservations
    JOIN 
        Vehicules V ON R.VehiculeID = V.VehiculeID -- Relier les réservations aux véhicules
    WHERE 
        R.VehiculeID = @VehiculeID -- Filtrer par véhicule
        AND T.DateDepart BETWEEN @StartDate AND @EndDate -- Filtrer par période
    GROUP BY 
        V.VehiculeID;
END
GO


--Question 21 :

CREATE PROCEDURE sp_RecordIncident
    @TrajetID INT, -- Identifiant du trajet
    @Cause NVARCHAR(255), -- Cause de l'incident (météo, panne, accident)
    @TempsPerdu INT, -- Temps perdu en minutes
    @Responsable NVARCHAR(100) -- Responsable à notifier
AS
BEGIN
    -- Enregistrer l'incident dans une table Incidents
    INSERT INTO Incidents (TrajetID, Cause, TempsPerdu, Responsable, DateIncident)
    VALUES (@TrajetID, @Cause, @TempsPerdu, @Responsable, GETDATE());

    -- Notifier le responsable (exemple : enregistrer dans une table de notifications)
    INSERT INTO Notifications (Message, Destinataire, DateNotification)
    VALUES ('Un incident a été enregistré pour le trajet ' + CAST(@TrajetID AS NVARCHAR) + '. Cause : ' + @Cause, @Responsable, GETDATE());

    PRINT 'Incident enregistré et responsable notifié.';
END
GO



-- Question 23 :

CREATE PROCEDURE sp_PlanifierTrajets
    @EmployeID INT, -- Identifiant de l'employé
    @ZoneGeographique NVARCHAR(100), -- Zone géographique de l'employé
    @HeureDebut TIME, -- Heure de début du travail
    @HeureFin TIME -- Heure de fin du travail
AS
BEGIN
    -- Trouver un véhicule disponible dans la zone géographique
    SELECT TOP 1
        V.VehiculeID,
        V.Type,
        V.Capacite
    FROM 
        Vehicules V
    WHERE 
        V.Disponible = 1 -- Véhicule disponible
        AND V.ZoneGeographique = @ZoneGeographique -- Zone géographique correspondante
        AND NOT EXISTS (
            SELECT 1 
            FROM Reservations R 
            JOIN Trajets T ON R.TrajetID = T.TrajetID
            WHERE R.VehiculeID = V.VehiculeID
              AND T.HeureDepart BETWEEN @HeureDebut AND @HeureFin -- Vérifier la disponibilité horaire
        )
    ORDER BY 
        V.Capacite DESC; -- Priorité aux véhicules avec la plus grande capacité

    -- Affecter le véhicule à l'employé
    IF @@ROWCOUNT > 0
    BEGIN
        PRINT 'Véhicule trouvé et affecté à l''employé ' + CAST(@EmployeID AS NVARCHAR);
    END
    ELSE
    BEGIN
        PRINT 'Aucun véhicule disponible pour cette zone et cette plage horaire.';
    END
END
GO



-- Question 25 :



CREATE PROCEDURE sp_CalculateMaintenanceCost
    @VehiculeID INT -- Identifiant du véhicule
AS
BEGIN
    DECLARE @TotalCost DECIMAL(18, 2) = 0;

    -- Calculer le coût total des réparations et des pièces de remplacement
    SELECT 
        @TotalCost = SUM(M.CoutReparation + M.CoutPieces)
    FROM 
        Maintenance M
    WHERE 
        M.VehiculeID = @VehiculeID;

    -- Mettre à jour l'historique de maintenance
    UPDATE Vehicules
    SET DerniereMaintenance = GETDATE(),
        FraisMaintenance = @TotalCost
    WHERE 
        VehiculeID = @VehiculeID;

    -- Retourner le coût total
    SELECT 
        @VehiculeID AS VehiculeID,
        @TotalCost AS TotalMaintenanceCost;
END
GO



--Question 29 : 

CREATE PROCEDURE sp_GenerateVehicleUsageReport
    @Mois INT, -- Mois pour le rapport
    @Annee INT -- Année pour le rapport
AS
BEGIN
    SELECT 
        V.VehiculeID,
        V.Type,
        COUNT(T.TrajetID) AS NombreTrajets,
        SUM(T.Distance) AS KilometresParcourus,
        SUM(T.Peages + (V.ConsommationCarburant * T.Distance) + V.FraisMaintenance) AS CoutTotal
    FROM 
        Vehicules V
    JOIN 
        Reservations R ON V.VehiculeID = R.VehiculeID
    JOIN 
        Trajets T ON R.TrajetID = T.TrajetID
    WHERE 
        MONTH(T.DateDepart) = @Mois
        AND YEAR(T.DateDepart) = @Annee
    GROUP BY 
        V.VehiculeID, V.Type;
END
GO








--------------------------------------------------------------------------------------------------
-- part of diae :

-- Question 2 : 

CREATE PROCEDURE CheckInfo
    @EmployeID INT,
    @Nom NVARCHAR(100),
    @Email NVARCHAR(100),
    @DateNaissance DATE
AS
BEGIN
    -- Vérifier le format de l'email
    IF @Email NOT LIKE '%_@__%.__%'
    BEGIN
        PRINT 'Erreur: Format d''email invalide.';
        RETURN;
    END;

    -- Vérifier que la date de naissance est dans le passé
    IF @DateNaissance >= GETDATE()
    BEGIN
        PRINT 'Erreur: Date de naissance invalide.';
        RETURN;
    END;

    -- Si les données sont valides, procéder à la mise à jour
    UPDATE dbo.Employes
    SET Nom = @Nom,
        Email = @Email,
        DateNaissance = @DateNaissance
    WHERE EmployeID = @EmployeID;

    PRINT 'Mise à jour réussie.';
END;

-- test de la Q2  : 
EXEC CheckInfo @EmployeID = 2, @Nom = 'Jean Dupont', @Email = 'jean.dupont', @DateNaissance = '2026-05-15';


-- Question 4 :

CREATE PROCEDURE AjouterVehicule
    @Type NVARCHAR(100),
    @Capacite INT,
    @Maintenance NVARCHAR(MAX)
AS
BEGIN
    -- Vérifier si un véhicule avec les mêmes caractéristiques existe déjà
    IF EXISTS (
        SELECT *
        FROM dbo.Vehicules
        WHERE Type = @Type
          AND Capacite = @Capacite
          AND Maintenance = @Maintenance
    )
    BEGIN
        PRINT 'Un véhicule avec les mêmes caractéristiques existe déjà.';
        RETURN;
    END;

    -- Si aucun véhicule similaire n'existe, ajouter le nouveau véhicule
    INSERT INTO dbo.Vehicules (Type, Capacite, Maintenance)
    VALUES (@Type, @Capacite, @Maintenance);

    PRINT 'Le véhicule a été ajouté avec succès.';
END;

-- Question 6 : 

CREATE PROCEDURE ReserverVehicule
    @EmployeID INT,
    @TrajetID INT,
    @DateDepart DATE,
    @HeureDepart TIME,
    @VehiculeID INT OUTPUT
AS
BEGIN

    -- Check available vehicles at the requested date and time
    DECLARE @AvailableVehiculeID INT;

    SELECT TOP 1 @AvailableVehiculeID = V.VehiculeID
    FROM Vehicules as V
    WHERE V.VehiculeID NOT IN (
        SELECT R.VehiculeID FROM Reservations R
        JOIN Trajets T ON R.TrajetID = T.TrajetID
        WHERE T.DateDepart = @DateDepart AND T.HeureDepart = @HeureDepart
    )
    ORDER BY V.VehiculeID;

    -- If a vehicle is available, make a reservation
    IF @AvailableVehiculeID IS NOT NULL
    BEGIN
        INSERT INTO Reservations (EmployeID, TrajetID, VehiculeID, ConducteurID)
        VALUES (@EmployeID, @TrajetID, @AvailableVehiculeID, NULL);

        SET @VehiculeID = @AvailableVehiculeID;
    END
    ELSE
    BEGIN
        SET @VehiculeID = NULL;
    END
END;

--Question 8 : 
CREATE PROCEDURE AttribuerVehicule
    @EmployeID INT,
    @TrajetID INT,
    @CapaciteRequise INT,
    @TypeVehicule NVARCHAR(50),
    @VehiculeID INT OUTPUT
AS
BEGIN

    
    SELECT TOP 1 @VehiculeID = V.VehiculeID
    FROM Vehicules V
    WHERE V.Capacite >= @CapaciteRequise
      AND V.Type = @TypeVehicule
      AND V.VehiculeID NOT IN (
          SELECT VehiculeID FROM Reservations
          WHERE TrajetID = @TrajetID
      )
    ORDER BY V.Capacite ASC;  

    
    IF @VehiculeID IS NOT NULL
    BEGIN
        INSERT INTO Reservations (EmployeID, TrajetID, VehiculeID, ConducteurID)
        VALUES (@EmployeID, @TrajetID, @VehiculeID, NULL);
    END
END;

-- Question 10 : 

CREATE PROCEDURE GenererRapportTrajets
    @DateDebut DATE,
    @DateFin DATE
AS
BEGIN

    SELECT 
        R.ReservationID,
        E.Nom AS Employe,
        V.Immatriculation AS Vehicule,
        C.Nom AS Conducteur,
        T.Itineraire,
        T.DateDepart,
        T.HeureDepart,
        T.DateArrivee,
        T.HeureArrivee,
        DATEDIFF(HOUR, T.HeureDepart, T.HeureArrivee) AS DureeHeures
    FROM Reservations R
    JOIN Employes E ON R.EmployeID = E.EmployeID
    JOIN Vehicules V ON R.VehiculeID = V.VehiculeID
    JOIN Conducteurs C ON R.ConducteurID = C.ConducteurID
    JOIN Trajets T ON R.TrajetID = T.TrajetID
    WHERE T.DateDepart BETWEEN @DateDebut AND @DateFin
    ORDER BY T.DateDepart;
END;

-- Question 12 :
CREATE PROCEDURE EnregistrerEvaluation
    @EmployeID INT,
    @TrajetID INT,
    @Score INT,
    @Commentaire NVARCHAR(500)
AS
BEGIN

    -- Vérifier si l'employé a bien effectué ce trajet
    IF EXISTS (
        SELECT 1 FROM Reservations
        WHERE EmployeID = @EmployeID AND TrajetID = @TrajetID
    )
    BEGIN
        -- Insérer l'évaluation
        INSERT INTO Evaluations (EmployeID, TrajetID, Score, Commentaire)
        VALUES (@EmployeID, @TrajetID, @Score, @Commentaire);

        PRINT 'Évaluation enregistrée avec succès.';
    END
    ELSE
    BEGIN
        PRINT 'Erreur : L''employé n''a pas effectué ce trajet.';
    END
END;

-- Question 14 :

CREATE PROCEDURE AjouterPoint
    @Nom NVARCHAR(255),
    @Latitude FLOAT,
    @Longitude FLOAT,
    @Type NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Vérifier si un point similaire existe déjà à proximité (moins de 0.01° de différence)
    IF EXISTS (
        SELECT 1 FROM Points
        WHERE ABS(Latitude - @Latitude) < 0.01
        AND ABS(Longitude - @Longitude) < 0.01
    )
    BEGIN
        PRINT 'Erreur : Un point de collecte ou dépôt proche existe déjà.';
    END
    ELSE
    BEGIN
        -- Insérer le nouveau point
        INSERT INTO Points (Nom, Latitude, Longitude, Type)
        VALUES (@Nom, @Latitude, @Longitude, @Type);

        PRINT 'Nouveau point ajouté avec succès.';
    END
END;


-- Question 16 : 

CREATE PROCEDURE VerifierMaintenanceVehicule
    @VehiculeID INT,
    @DateTrajet DATE
AS
BEGIN

    DECLARE @DerniereMaintenance DATE;

    -- Récupérer la dernière date de maintenance du véhicule
    SELECT @DerniereMaintenance = DerniereMaintenance 
    FROM Vehicules 
    WHERE VehiculeID = @VehiculeID;

    -- Vérifier si le véhicule nécessite une maintenance ( la maintenance doit etre faite chaque 6 mois )
    IF @DerniereMaintenance IS NULL OR DATEDIFF(DAY, @DerniereMaintenance, @DateTrajet) > 180
    BEGIN
        PRINT 'Alerte : Le véhicule doit être inspecté avant son affectation.';
    END
    ELSE
    BEGIN
        PRINT 'Le véhicule est en bon état pour être affecté.';
    END
END;

-- Question 18 :
CREATE PROCEDURE AfficherEvaluationsVehicules
AS
BEGIN

    -- Afficher les notes moyennes et les commentaires des employés
    SELECT 
        V.VehiculeID,
        V.Immatriculation,
        EV.Note AS NoteIndividuelle,
        EV.Commentaire
    FROM EvaluationsVehicules EV
    INNER JOIN Vehicules V ON EV.VehiculeID = V.VehiculeID
    ORDER BY V.VehiculeID, EV.Note DESC;
END;

-- Question 20 :

CREATE PROCEDURE MettreAJourStatutTrajet
    @TrajetID INT,
    @NouveauStatut NVARCHAR(50)
AS
BEGIN

    -- Vérifier si le trajet existe
    IF NOT EXISTS (SELECT 1 FROM Trajets WHERE TrajetID = @TrajetID)
    BEGIN
        PRINT ' Erreur : Trajet non trouvé.';
        RETURN;
    END;

    -- Mettre à jour le statut du trajet
    UPDATE Trajets
    SET Statut = @NouveauStatut
    WHERE TrajetID = @TrajetID;

    PRINT ' Statut du trajet mis à jour avec succès.';

    -- Simuler une notification (message)
    PRINT ' Notification envoyée aux parties concernées.';
END;

-- Question 22 :
CREATE PROCEDURE RapportAnnulations
AS
BEGIN

    -- Sélectionner les trajets annulés et compter les occurrences de chaque raison
    SELECT 
        RaisonAnnulation,
        COUNT(*) AS NombreAnnulations
    FROM Trajets
    WHERE RaisonAnnulation IS NOT NULL
    GROUP BY RaisonAnnulation
    ORDER BY NombreAnnulations DESC;
END;

-- Question 24 :

CREATE PROCEDURE AffecterVehiculeParZone
    @EmployeID INT,
    @TrajetID INT,
    @VehiculeID INT OUTPUT
AS
BEGIN

    DECLARE @Zone NVARCHAR(100);

    -- Récupérer la zone géographique de l'employé
    SELECT @Zone = ZoneGeographique FROM Employes WHERE EmployeID = @EmployeID;

    -- Sélectionner le véhicule disponible dans la même zone
    SELECT TOP 1 @VehiculeID = V.VehiculeID
    FROM Vehicules V
    WHERE V.ZoneGeographique = @Zone
      AND V.VehiculeID NOT IN (SELECT VehiculeID FROM Reservations WHERE TrajetID = @TrajetID)
    ORDER BY NEWID();  -- Sélection aléatoire si plusieurs véhicules disponibles

    -- Insérer dans la table des réservations si un véhicule est trouvé
    IF @VehiculeID IS NOT NULL
    BEGIN
        INSERT INTO Reservations (EmployeID, TrajetID, VehiculeID, ConducteurID)
        VALUES (@EmployeID, @TrajetID, @VehiculeID, NULL);
    END
END;

--Question 26 :

CREATE PROCEDURE ValiderEmployeReservation
    @EmployeID INT,
    @EstEligible BIT OUTPUT
AS
BEGIN

    -- Vérifier si l'employé est éligible
    SELECT @EstEligible = EligibleTransport FROM Employes WHERE EmployeID = @EmployeID;
END;


--Question 28 :
CREATE PROCEDURE AuditTrajetsVehicules
AS
BEGIN

    SELECT 
        T.TrajetID,
        E.Nom AS Employe,
        V.Immatriculation AS Vehicule,
        T.Itineraire,
        T.DateDepart,
        T.HeureDepart,
        T.DateArrivee,
        T.HeureArrivee,
        DATEDIFF(MINUTE, T.HeureDepart, T.HeureArrivee) AS DureeMinutes,
        (CASE 
            WHEN DATEDIFF(MINUTE, T.HeureDepart, T.HeureArrivee) > 60 THEN 'Long'
            ELSE 'Court'
        END) AS CategorieDuree
    FROM Trajets T
    INNER JOIN Reservations R ON T.TrajetID = R.TrajetID
    INNER JOIN Employes E ON R.EmployeID = E.EmployeID
    INNER JOIN Vehicules V ON R.VehiculeID = V.VehiculeID
    ORDER BY T.DateDepart DESC;
END;

-- Question 30 : 







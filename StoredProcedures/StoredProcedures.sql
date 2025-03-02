
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

    -- Find the most suitable available vehicle
    SELECT TOP 1 @VehiculeID = V.VehiculeID
    FROM Vehicules V
    WHERE V.Capacite >= @CapaciteRequise
      AND V.Type = @TypeVehicule
      AND V.VehiculeID NOT IN (
          SELECT VehiculeID FROM Reservations
          WHERE TrajetID = @TrajetID
      )
    ORDER BY V.Capacite ASC;  -- Prefer smaller but sufficient vehicles

    -- If a vehicle is available, register the reservation
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







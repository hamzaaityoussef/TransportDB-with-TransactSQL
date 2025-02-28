
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



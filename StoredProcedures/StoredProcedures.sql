
--1/ procédure stockée qui insère un nouvel employé
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
        PRINT 'Erreur : Cet email est déjà utilisé par un autre employé.';
        RETURN; 
    END

    
    INSERT INTO Employes (Nom, Entreprise, Poste, Coordonnees,Email)
    VALUES (@Nom, @Entreprise, @Poste, @Coordonnees,@Email);

    PRINT 'Nouvel employé ajouté avec succès.';
END
GO



--3/ Procédure Stockée pour Supprimer un Employé et annuler les trajets réservés	
CREATE PROCEDURE sp_DeleteEmploye
    @EmployeID INT 
AS
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM Employes WHERE EmployeID = @EmployeID)
    BEGIN
        PRINT 'Erreur : L''employé avec l''ID ' + CAST(@EmployeID AS NVARCHAR) + ' n''existe pas.';
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

        PRINT 'L''employé avec l''ID ' + CAST(@EmployeID AS NVARCHAR) + ' a été supprimé avec succès.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        PRINT 'Erreur : ' + ERROR_MESSAGE();
    END CATCH
END
GO







--5/ Procédure Stockée pour Mettre à Jour un Véhicule
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
        PRINT 'Erreur : Le véhicule avec l''ID ' + CAST(@VehiculeID AS NVARCHAR) + ' n''existe pas.';
        RETURN;
    END

    -- Vérifier les contraintes d'intégrité
    --  La capacité ne doit pas dépasser 100
    IF @Capacite > 100
    BEGIN
        PRINT 'Erreur : La capacité du véhicule ne peut pas dépasser 100.';
        RETURN;
    END

    -- Vérifier que l'immatriculation n'est pas déjà utilisée par un autre véhicule
    IF EXISTS (SELECT 1 FROM Vehicules WHERE Immatriculation = @Immatriculation AND VehiculeID <> @VehiculeID)
    BEGIN
        PRINT 'Erreur : L''immatriculation ' + @Immatriculation + ' est déjà utilisée par un autre véhicule.';
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

       
        PRINT 'Les informations du véhicule avec l''ID ' + CAST(@VehiculeID AS NVARCHAR) + ' ont été mises à jour avec succès.';
    END TRY
    BEGIN CATCH
        
        ROLLBACK TRANSACTION;

        
        PRINT 'Erreur : ' + ERROR_MESSAGE();
    END CATCH
END
GO






-- 7/ Procédure Stockée pour Vérifier la Disponibilité des Véhicules

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
        -- Vérifier que le véhicule n'est pas déjà réservé pour cette date
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
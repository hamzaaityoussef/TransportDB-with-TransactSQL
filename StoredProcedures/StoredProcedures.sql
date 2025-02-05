
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



--Procédure Stockée pour Supprimer un Employé et annuler les trajets réservés	
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
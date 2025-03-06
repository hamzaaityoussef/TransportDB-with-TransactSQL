-- Question 27

CREATE TRIGGER trg_CheckVehicleAvailability
ON Reservations
INSTEAD OF INSERT
AS
BEGIN
    -- Vérifier la disponibilité du véhicule
    IF EXISTS (
        SELECT 1 
        FROM inserted I
        JOIN Vehicules V ON I.VehiculeID = V.VehiculeID
        WHERE V.Disponible = 0 OR V.Maintenance <= GETDATE() -- Véhicule indisponible ou en maintenance
    )
    BEGIN
        RAISERROR('Le véhicule n''est pas disponible pour une réservation.', 16, 1);
        RETURN;
    END

    -- Si le véhicule est disponible, insérer la réservation
    INSERT INTO Reservations (EmployeID, TrajetID, VehiculeID, ConducteurID)
    SELECT 
        EmployeID, 
        TrajetID, 
        VehiculeID, 
        ConducteurID
    FROM 
        inserted;
END
GO

--Question 31

--meme reponse que la question 27


--Question 33

CREATE TRIGGER trg_UpdateVehicleMileage
ON Trajets
AFTER INSERT
AS
BEGIN
    -- Mettre à jour le kilométrage du véhicule
    UPDATE V
    SET Kilometrage = V.Kilometrage + I.Distance
    FROM 
        Vehicules V
    JOIN 
        Reservations R ON V.VehiculeID = R.VehiculeID
    JOIN 
        inserted I ON R.TrajetID = I.TrajetID;
END
GO

--Question 35

CREATE TRIGGER trg_RecalculateTripCost
ON Trajets
AFTER UPDATE
AS
BEGIN
    -- Recalculer le coût du trajet si la distance est mise à jour
    IF UPDATE(Distance)
    BEGIN
        UPDATE T
        SET CoutTotal = (T.Peages + (V.ConsommationCarburant * T.Distance) + V.FraisMaintenance)
        FROM 
            Trajets T
		JOIN 
            Reservations R ON T.TrajetID = R.TrajetID
        JOIN 
            Vehicules V ON R.VehiculeID = V.VehiculeID
        JOIN 
            inserted I ON T.TrajetID = I.TrajetID;
    END
END
GO

--Question 37

CREATE TRIGGER trg_PreventTripWithoutVehicle
ON Trajets
INSTEAD OF INSERT
AS
BEGIN
    -- Vérifier si un véhicule est assigné à l'employé
    IF EXISTS (
        SELECT 1
        FROM inserted I
        LEFT JOIN Reservations R ON I.TrajetID = R.TrajetID
        WHERE R.VehiculeID IS NULL -- Aucun véhicule assigné
    )
    BEGIN
        RAISERROR('Un véhicule doit être assigné à l''employé pour ce trajet.', 16, 1);
        RETURN;
    END

    -- Si un véhicule est assigné, insérer le trajet
    INSERT INTO Trajets (Itineraire, DateDepart, HeureDepart, DateArrivee, HeureArrivee, PointCollecte, PointDepot, Distance, Peages)
    SELECT 
        Itineraire, 
        DateDepart, 
        HeureDepart, 
        DateArrivee, 
        HeureArrivee, 
        PointCollecte, 
        PointDepot, 
        Distance, 
        Peages
    FROM 
        inserted;
END
GO


--Question 39 :  
--je ne peux pas avoir plusieurs triggers INSTEAD OF INSERT sur la même table (Reservations)
--donc je vais utiliser ici  AFTER INSERT (ne peux pas empêcher l'insertion de données, mais ils peuvent annuler
-- la transaction si une condition n'est pas respectée.

CREATE TRIGGER trg_PreventOverlappingReservations
ON Reservations
AFTER INSERT
AS
BEGIN
    -- Vérifier si l'employé a déjà un trajet en cours
    IF EXISTS (
        SELECT 1
        FROM inserted I
        JOIN Reservations R ON I.EmployeID = R.EmployeID
        JOIN Trajets T ON R.TrajetID = T.TrajetID
        WHERE T.DateArrivee > GETDATE() -- Trajet en cours
    )
    BEGIN
        -- Annuler la transaction et afficher un message d'erreur
        RAISERROR('L''employé a déjà un trajet en cours. Impossible d''ajouter une nouvelle réservation.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

--------------------------------------------------------------------------------------------------
-- part of diae :

--Question 30 : 
CREATE TRIGGER trg_AlerteMaintenance
ON Vehicules
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.Kilometrage >= 10000  -- Seuil de kilométrage avant maintenance
        AND i.DerniereMaintenance IS NULL
    )
    BEGIN
        INSERT INTO Notifications (Message, Destinataire, DateNotification)
        VALUES ('Alerte: Un véhicule a dépassé le seuil de kilométrage sans maintenance.', 'Gestionnaire', GETDATE());
    END
END;

-- Question 32 :
CREATE TRIGGER trg_AlerteTrajetsMensuels
ON Reservations
AFTER INSERT
AS
BEGIN
    DECLARE @EmployeID INT, @NombreTrajets INT;

    SELECT @EmployeID = EmployeID FROM inserted;

    SELECT @NombreTrajets = COUNT(*)
    FROM Reservations
    WHERE EmployeID = @EmployeID
    AND MONTH(DateAffectation) = MONTH(GETDATE())
    AND YEAR(DateAffectation) = YEAR(GETDATE());

    IF @NombreTrajets > 10  -- Seuil à ajuster
    BEGIN
        INSERT INTO Notifications (Message, Destinataire, DateNotification)
        VALUES ('Alerte: Un employé a dépassé le nombre autorisé de trajets ce mois.', 'RH', GETDATE());
    END
END;

-- Question 34 :
CREATE TRIGGER trg_PreventDeleteVehicule
ON Vehicules
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN Trajets t ON d.VehiculeID = t.TrajetID
    )
    BEGIN
        RAISERROR ('Suppression impossible: Le véhicule est actuellement utilisé dans un trajet.', 16, 1);
    END
    ELSE
    BEGIN
        DELETE FROM Vehicules WHERE VehiculeID IN (SELECT VehiculeID FROM deleted);
    END
END;

-- Question 36 :
CREATE TRIGGER trg_NotificationKilometrage
ON Vehicules
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.Kilometrage >= 15000 -- Seuil de kilométrage critique
        AND (i.DerniereMaintenance IS NULL OR DATEDIFF(DAY, i.DerniereMaintenance, GETDATE()) > 180) -- Plus de 6 mois sans maintenance
    )
    BEGIN
        INSERT INTO Notifications (Message, Destinataire, DateNotification)
        VALUES ('Alerte: Un véhicule doit être entretenu immédiatement.', 'Responsable Maintenance', GETDATE());
    END
END;

-- Question 38 :
CREATE TRIGGER trg_NotificationAnnulationTrajet
ON Trajets
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.Statut = 'Annule´'
    )
    BEGIN
        INSERT INTO Notifications (Message, Destinataire, DateNotification)
        VALUES ('Un trajet a été annulé. Veuillez en vérifier la raison.', 'Gestionnaire', GETDATE());
    END
END;

-- Question 40 :
CREATE TRIGGER trg_ArchiveTrajets
ON Trajets
AFTER UPDATE
AS
BEGIN
    INSERT INTO Trajets_Archive (TrajetID, Itineraire, DateDepart, HeureDepart, DateArrivee, HeureArrivee, PointCollecte, PointDepot, Distance, Peages, Statut, RaisonAnnulation, CoutTotal)
    SELECT *
    FROM Trajets
    WHERE Statut = 'Termine´' 
    AND DATEDIFF(DAY, DateArrivee, GETDATE()) > 90; -- Archivage après 3 mois

    DELETE FROM Trajets
    WHERE Statut = 'Termine´' 
    AND DATEDIFF(DAY, DateArrivee, GETDATE()) > 90;
END;

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
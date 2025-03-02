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
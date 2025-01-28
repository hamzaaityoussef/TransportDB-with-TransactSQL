# Projet de Gestion des Transports d'Entreprise

## Objectif du Projet
Le projet vise à créer une solution informatique permettant de gérer efficacement les transports des personnels de plusieurs entreprises.

## Composants du Projet

### A. Conception et Développement d’une Base de Données SQL Server
Une base de données relationnelle sera développée sous SQL Server pour stocker toutes les informations nécessaires à la gestion des transports.

### B. Application de Gestion des Transports
Une application sera développée pour interagir avec la base de données SQL Server.

#### Fonctionnalités Clés
- **Gestion des Réservations** : Permettre aux employés de réserver des trajets.
- **Affectation Automatique des Trajets** : Attribuer automatiquement les véhicules.
- **Suivi en Temps Réel** : Visualiser les trajets en cours.

### C. Procédures Stockées et Triggers en T-SQL
Le projet inclut la création de 40 procédures stockées et triggers pour automatiser et sécuriser les opérations de la base de données.

#### Exemples de Procédures Stockées
1. **Insertion d'un Nouvel Employé** :
   ```sql
   CREATE PROCEDURE sp_InsertEmploye
   @Nom NVARCHAR(100),
   @Email NVARCHAR(100)
   AS
   BEGIN
       -- Vérifier que l'email n'existe pas déjà
       IF NOT EXISTS (SELECT 1 FROM Employes WHERE Email = @Email)
       BEGIN
           INSERT INTO Employes (Nom, Email) VALUES (@Nom, @Email);
       END
   END




#for complete ennonce you can check ennonce_projet.pdf

Procédures Stockées
Insertion d'un Nouvel Employé :

Vérifie que l'identifiant et l'email ne sont pas déjà utilisés.

Génère un identifiant unique pour l'employé.

Mise à Jour des Informations d'un Employé :

Vérifie l'intégrité des données (format de l'email, date de naissance, etc.) avant la mise à jour.

Suppression d'un Employé :

Réaffecte ou annule les trajets réservés de l'employé supprimé.

Ajout d'un Véhicule :

Vérifie la disponibilité d'un véhicule avec des caractéristiques similaires avant d’ajouter un nouveau véhicule.

Réservation d'un Véhicule :

Vérifie la disponibilité des véhicules à la date et à l'heure demandées.

Génère un numéro de réservation unique.

Génération de Rapports :

Rapports détaillés des trajets effectués, des coûts, et des performances des véhicules.

Triggers
Vérification de la Disponibilité d'un Véhicule :

Empêche l'ajout d'une réservation si le véhicule est déjà réservé ou en maintenance.

Mise à Jour Automatique du Kilométrage :

Met à jour le kilométrage d'un véhicule lors de l'ajout d'un trajet.

Notification de Maintenance :

Envoie une alerte lorsqu'un véhicule dépasse un certain seuil de kilométrage sans maintenance.

Archivage des Trajets Terminés :

Archive automatiquement les trajets terminés après une certaine période.

Fonctionnalités Clés
Centralisation des Données : Toutes les informations sont stockées dans une base de données unique.

Automatisation : Les processus de réservation, d'affectation et de suivi sont automatisés.

Suivi en Temps Réel : Visualisation des trajets en cours et des états des véhicules.

Reporting Avancé : Génération de rapports détaillés pour l'analyse et la prise de décision.

Technologies Utilisées
Base de Données : Microsoft SQL Server.

Langage de Programmation : T-SQL (pour les procédures stockées et triggers).

Application : Développement d'une interface utilisateur (à définir : web, mobile, ou desktop).

Structure du Projet
Copy
TransportDB-with-TransactSQL/
├── StoredProcedures/       # Dossier pour les procédures stockées
├── Triggers/               # Dossier pour les triggers
├── DatabaseSchema/         # Dossier pour le schéma de la base de données
├── README.md               # Fichier de présentation du projet


Comment Contribuer
Clonez le dépôt :

git clone https://github.com/hamzaaityoussef/TransportDB-with-TransactSQL.git

Créez une branche pour vos modifications :


git checkout -b votre-branche
Soumettez vos modifications via une Pull Request.

Auteurs
Hamza ait youssef

diae khayati

Licence
Ce projet est sous licence MIT.

Ce README.md fournit une vue d'ensemble claire et structurée du projet, facilitant la compréhension et la collaboration. Vous pouvez l'adapter en fonction des besoins spécifiques de votre équipe. 🚀
/*
Create Database & Schemas

Purpose: this script creates the database named dwh_project and sets up three schemas in it: 'bronze', 'silver', and 'gold'.

INFO: this script will not run if a database with the same name already exists...
*/

USE master;

CREATE DATABASE dwh_project;

USE dwh_project;

GO
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;

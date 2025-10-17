USE [Proyecto_ES]

CREATE TABLE dim_time (
	TimeID INT,
	Anio INT, 
	Semestre NVARCHAR(50),
	Cuatrimestre NVARCHAR(50),
	Trimestre NVARCHAR(50),
	Mes INT,
	Dia_semana NVARCHAR(50),
	Dia INT
);
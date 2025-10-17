USE [Proyecto_ES]

CREATE TABLE fact_entrada (
	Folio NVARCHAR (50),
	ClienteID NVARCHAR (50),
	VendedorID NVARCHAR (50),
    ArticuloID NVARCHAR (50), -- D
    Descripcion_Articulo NVARCHAR(200), -- D
    Codigo_Articulo NVARCHAR(50), -- D
	TimeID INT,

    Empresa NVARCHAR(50),
    Almacen NVARCHAR(50), -- D
    Ubicacion NVARCHAR(50), -- D
    Partida INT, -- D
    Operacion NVARCHAR(50),
    
	Moneda NVARCHAR(50),
	Cantidad NUMERIC, -- D 
	Precio_Unitario NUMERIC, -- D
    Unidad NVARCHAR(50), -- UMEDPartida D
    Cantidad_Unidad NUMERIC, -- D

    Pct_Descuento NUMERIC, -- D
    Pct_Descuento_Global NUMERIC,
    Pct_Impuesto NUMERIC, -- D

	Total_Descuento NUMERIC, 
    Total_Descuento_D NUMERIC, -- D

    Total_Importe NUMERIC, 
    Total_Importe_D NUMERIC, -- D

    Total_Impuesto NUMERIC, 
    Total_Impuesto_D NUMERIC, -- D

	Total NUMERIC,
    Total_D NUMERIC, -- D
);
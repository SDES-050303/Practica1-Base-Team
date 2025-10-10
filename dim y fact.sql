/* ============================
   0) BASE DE DATOS
   ============================*/
USE master;
IF DB_ID('Team_autopartes') IS NULL CREATE DATABASE Team_autopartes;
GO
USE Team_autopartes;
GO

/* ============================
   1) DIMENSIONES
   ============================*/

/* 1.1 DimFecha (SCD0) */
IF OBJECT_ID('dbo.DimFecha','U') IS NULL
CREATE TABLE dbo.DimFecha(
  DateKey           INT          NOT NULL PRIMARY KEY, -- yyyymmdd
  Fecha             DATE         NOT NULL,
  Anio              SMALLINT     NOT NULL,
  Semestre          TINYINT      NOT NULL,  -- 1-2
  Cuatrimestre      TINYINT      NOT NULL,  -- 1-3
  Trimestre         TINYINT      NOT NULL,  -- 1-4
  MesNumero         TINYINT      NOT NULL,  -- 1-12
  MesNombre         VARCHAR(20)  NOT NULL,
  Dia               TINYINT      NOT NULL,  -- 1-31
  DiaSemanaNumero   TINYINT      NOT NULL,  -- 1..7
  DiaSemanaNombre   VARCHAR(20)  NOT NULL
);
GO

/* 1.2 DimArticulo (SCD2 light) */
IF OBJECT_ID('dbo.DimArticulo','U') IS NULL
CREATE TABLE dbo.DimArticulo(
  ArticuloKey     INT IDENTITY(1,1)  PRIMARY KEY,
  ArticuloNK      CHAR(20)      NOT NULL,   -- AutopartesO2025.dbo.Articulo.clave
  SKU             VARCHAR(50)   NULL,
  Descripcion     VARCHAR(100)  NOT NULL,
  Marca           VARCHAR(100)  NULL,       -- no existe en OLTP; derivable
  GrupoClave      CHAR(20)      NULL,
  GrupoDesc       VARCHAR(100)  NULL,
  TipoClave       CHAR(20)      NULL,
  TipoDesc        VARCHAR(100)  NULL,
  ClaseClave      CHAR(20)      NULL,
  ClaseDesc       VARCHAR(100)  NULL,
  UnidadMedida    CHAR(20)      NULL,       -- UMedInv
  MonedaArticulo  CHAR(20)      NULL,       -- Articulo.Moneda
  -- control SCD2
  ValidFrom       DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
  ValidTo         DATETIME2(0)  NOT NULL DEFAULT '9999-12-31',
  IsCurrent       BIT           NOT NULL DEFAULT 1,
  HashDiff        VARBINARY(16) NULL
);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_DimArticulo_NK_Current' AND object_id=OBJECT_ID('dbo.DimArticulo'))
  CREATE UNIQUE INDEX UX_DimArticulo_NK_Current ON dbo.DimArticulo(ArticuloNK, ValidTo, IsCurrent);
GO

/* 1.3 DimCliente (SCD1 mínima) */
IF OBJECT_ID('dbo.DimCliente','U') IS NULL
CREATE TABLE dbo.DimCliente(
  ClienteKey     INT IDENTITY(1,1) PRIMARY KEY,
  ClienteNK      CHAR(20)      NOT NULL,   -- Cliente.Clave
  RazonSocial    VARCHAR(100)  NOT NULL,
  Ciudad         VARCHAR(100)  NULL,
  Estado         CHAR(20)      NULL,
  Pais           CHAR(20)      NULL,
  Segmento       CHAR(20)      NULL,       -- ClienteTipo/Grupo si lo usas
  MonedaPref     CHAR(20)      NULL,
  CondicionPago  CHAR(20)      NULL
);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_DimCliente_NK' AND object_id=OBJECT_ID('dbo.DimCliente'))
  CREATE UNIQUE INDEX UX_DimCliente_NK ON dbo.DimCliente(ClienteNK);
GO

/* 1.4 DimVendedor (SCD1 mínima) */
IF OBJECT_ID('dbo.DimVendedor','U') IS NULL
CREATE TABLE dbo.DimVendedor(
  VendedorKey   INT IDENTITY(1,1) PRIMARY KEY,
  VendedorNK    CHAR(20)     NOT NULL,   -- Vendedor.Clave
  Nombre        VARCHAR(100) NOT NULL
);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_DimVendedor_NK' AND object_id=OBJECT_ID('dbo.DimVendedor'))
  CREATE UNIQUE INDEX UX_DimVendedor_NK ON dbo.DimVendedor(VendedorNK);
GO

/* 1.5 DimAlmacen (derivada; no catálogo maestro en OLTP) */
IF OBJECT_ID('dbo.DimAlmacen','U') IS NULL
CREATE TABLE dbo.DimAlmacen(
  AlmacenKey   INT IDENTITY(1,1) PRIMARY KEY,
  AlmacenNK    CHAR(20)     NOT NULL,  -- códigos que vienen en detalles
  Descripcion  VARCHAR(100) NULL
);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_DimAlmacen_NK' AND object_id=OBJECT_ID('dbo.DimAlmacen'))
  CREATE UNIQUE INDEX UX_DimAlmacen_NK ON dbo.DimAlmacen(AlmacenNK);
GO

/* 1.6 DimMoneda (SCD1) */
IF OBJECT_ID('dbo.DimMoneda','U') IS NULL
CREATE TABLE dbo.DimMoneda(
  MonedaKey   INT IDENTITY(1,1) PRIMARY KEY,
  MonedaNK    CHAR(20)     NOT NULL,   -- Moneda.Clave
  Nombre      VARCHAR(100) NOT NULL    -- Moneda.Descripcion
);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_DimMoneda_NK' AND object_id=OBJECT_ID('dbo.DimMoneda'))
  CREATE UNIQUE INDEX UX_DimMoneda_NK ON dbo.DimMoneda(MonedaNK);
GO

/* 1.7 DimCondicionPago (SCD1) */
IF OBJECT_ID('dbo.DimCondicionPago','U') IS NULL
CREATE TABLE dbo.DimCondicionPago(
  CondicionPagoKey INT IDENTITY(1,1) PRIMARY KEY,
  CondicionPagoNK  CHAR(20)     NOT NULL,  -- CondicionPago.Clave
  Descripcion      VARCHAR(100) NOT NULL
);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_DimCondicionPago_NK' AND object_id=OBJECT_ID('dbo.DimCondicionPago'))
  CREATE UNIQUE INDEX UX_DimCondicionPago_NK ON dbo.DimCondicionPago(CondicionPagoNK);
GO

/* 1.8 DimMedioEmbarque (SCD1) */
IF OBJECT_ID('dbo.DimMedioEmbarque','U') IS NULL
CREATE TABLE dbo.DimMedioEmbarque(
  MedioEmbarqueKey INT IDENTITY(1,1) PRIMARY KEY,
  MedioEmbarqueNK  CHAR(20)     NOT NULL,  -- MedioEmbarque.Clave
  Descripcion      VARCHAR(100) NOT NULL
);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='UX_DimMedioEmbarque_NK' AND object_id=OBJECT_ID('dbo.DimMedioEmbarque'))
  CREATE UNIQUE INDEX UX_DimMedioEmbarque_NK ON dbo.DimMedioEmbarque(MedioEmbarqueNK);
GO

/* 1.9 Miembros desconocidos (-1) para FKs opcionales */
IF NOT EXISTS (SELECT 1 FROM dbo.DimCliente WHERE ClienteKey = -1)
BEGIN
  SET IDENTITY_INSERT dbo.DimCliente ON;
  INSERT dbo.DimCliente(ClienteKey,ClienteNK,RazonSocial,Ciudad,Estado,Pais,Segmento,MonedaPref,CondicionPago)
  VALUES(-1,'-1','(Sin cliente)',NULL,NULL,NULL,NULL,NULL,NULL);
  SET IDENTITY_INSERT dbo.DimCliente OFF;
END
IF NOT EXISTS (SELECT 1 FROM dbo.DimVendedor WHERE VendedorKey = -1)
BEGIN
  SET IDENTITY_INSERT dbo.DimVendedor ON;
  INSERT dbo.DimVendedor(VendedorKey,VendedorNK,Nombre)
  VALUES(-1,'-1','(Sin vendedor)');
  SET IDENTITY_INSERT dbo.DimVendedor OFF;
END
IF NOT EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE MonedaKey = -1)
BEGIN
  SET IDENTITY_INSERT dbo.DimMoneda ON;
  INSERT dbo.DimMoneda(MonedaKey,MonedaNK,Nombre) VALUES(-1,'N/A','No especificada');
  SET IDENTITY_INSERT dbo.DimMoneda OFF;
END
IF NOT EXISTS (SELECT 1 FROM dbo.DimCondicionPago WHERE CondicionPagoKey = -1)
BEGIN
  SET IDENTITY_INSERT dbo.DimCondicionPago ON;
  INSERT dbo.DimCondicionPago(CondicionPagoKey,CondicionPagoNK,Descripcion) VALUES(-1,'N/A','No aplica / Desconocida');
  SET IDENTITY_INSERT dbo.DimCondicionPago OFF;
END
IF NOT EXISTS (SELECT 1 FROM dbo.DimMedioEmbarque WHERE MedioEmbarqueKey = -1)
BEGIN
  SET IDENTITY_INSERT dbo.DimMedioEmbarque ON;
  INSERT dbo.DimMedioEmbarque(MedioEmbarqueKey,MedioEmbarqueNK,Descripcion) VALUES(-1,'N/A','No aplica / Desconocido');
  SET IDENTITY_INSERT dbo.DimMedioEmbarque OFF;
END
IF NOT EXISTS (SELECT 1 FROM dbo.DimAlmacen WHERE AlmacenKey = -1)
BEGIN
  SET IDENTITY_INSERT dbo.DimAlmacen ON;
  INSERT dbo.DimAlmacen(AlmacenKey,AlmacenNK,Descripcion) VALUES(-1,'N/A','No especificado');
  SET IDENTITY_INSERT dbo.DimAlmacen OFF;
END
/* (Opcional) Artículo desconocido para cubrir FKs si lo requieres */
IF NOT EXISTS (SELECT 1 FROM dbo.DimArticulo WHERE ArticuloNK='(NA)' AND IsCurrent=1)
  INSERT dbo.DimArticulo(ArticuloNK,SKU,Descripcion,Marca,ValidFrom,ValidTo,IsCurrent)
  VALUES('(NA)',NULL,'(Artículo no asignado)','(No disponible)',SYSUTCDATETIME(),'9999-12-31',1);
GO

/* ============================
   2) HECHOS (una fila por partida)
   ============================*/

/* 2.1 FactEntradas */
IF OBJECT_ID('dbo.FactEntradas','U') IS NULL
CREATE TABLE dbo.FactEntradas(
  FactEntradaKey     BIGINT IDENTITY(1,1) PRIMARY KEY,
  -- FKs
  DateKey            INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimFecha(DateKey),
  ArticuloKey        INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimArticulo(ArticuloKey),
  AlmacenKey         INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimAlmacen(AlmacenKey),
  ClienteKey         INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimCliente(ClienteKey),
  VendedorKey        INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimVendedor(VendedorKey),
  MonedaKey          INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimMoneda(MonedaKey),

  -- Encabezado (degeneradas)
  Empresa            CHAR(20)     NOT NULL,
  Folio              CHAR(10)     NOT NULL,
  DocumentoNK        AS (CONVERT(VARCHAR(31),RTRIM(Empresa)+'-'+RTRIM(Folio))) PERSISTED,
  FechaHora          DATETIME2(0) NOT NULL,

  Subtotal           DECIMAL(18,5) NULL,
  Impuestos          DECIMAL(18,5) NULL,
  TotalImporte       DECIMAL(18,5) NULL,
  TotalDescuento     DECIMAL(18,5) NULL,
  Total              DECIMAL(18,5) NULL,

  -- Detalle (_d)
  Renglon            INT           NOT NULL,
  Cantidad_d         DECIMAL(18,5) NOT NULL CHECK (Cantidad_d >= 0),
  PrecioUnitario_d   DECIMAL(18,5) NULL,
  Descuento_d        DECIMAL(18,5) NULL,
  Impuesto_d         DECIMAL(18,5) NULL,
  Importe_d          DECIMAL(18,5) NULL,

  CONSTRAINT UX_FactEntradas UNIQUE (Empresa, Folio, Renglon)
);
GO
CREATE INDEX IX_FactEntradas_Date      ON dbo.FactEntradas(DateKey);
CREATE INDEX IX_FactEntradas_Cliente   ON dbo.FactEntradas(ClienteKey);
CREATE INDEX IX_FactEntradas_Vendedor  ON dbo.FactEntradas(VendedorKey);
CREATE INDEX IX_FactEntradas_Articulo  ON dbo.FactEntradas(ArticuloKey);
GO

/* 2.2 FactSalidas */
IF OBJECT_ID('dbo.FactSalidas','U') IS NULL
CREATE TABLE dbo.FactSalidas(
  FactSalidaKey      BIGINT IDENTITY(1,1) PRIMARY KEY,
  -- FKs
  DateKey            INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimFecha(DateKey),
  ArticuloKey        INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimArticulo(ArticuloKey),
  AlmacenKey         INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimAlmacen(AlmacenKey),
  ClienteKey         INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimCliente(ClienteKey),
  VendedorKey        INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimVendedor(VendedorKey),
  MonedaKey          INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimMoneda(MonedaKey),
  CondicionPagoKey   INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimCondicionPago(CondicionPagoKey),
  MedioEmbarqueKey   INT          NOT NULL FOREIGN KEY REFERENCES dbo.DimMedioEmbarque(MedioEmbarqueKey),

  -- Encabezado (degeneradas)
  Empresa            CHAR(20)     NOT NULL,
  Folio              CHAR(10)     NOT NULL,
  DocumentoNK        AS (CONVERT(VARCHAR(31),RTRIM(Empresa)+'-'+RTRIM(Folio))) PERSISTED,
  FechaHora          DATETIME2(0) NOT NULL,

  Subtotal           DECIMAL(18,5) NULL,
  Impuestos          DECIMAL(18,5) NULL,
  TotalImporte       DECIMAL(18,5) NULL,
  TotalDescuento     DECIMAL(18,5) NULL,
  Total              DECIMAL(18,5) NULL,

  -- Detalle (_d)
  Renglon            INT           NOT NULL,
  Cantidad_d         DECIMAL(18,5) NOT NULL CHECK (Cantidad_d >= 0),
  PrecioUnitario_d   DECIMAL(18,5) NULL,
  Descuento_d        DECIMAL(18,5) NULL,
  Impuesto_d         DECIMAL(18,5) NULL,
  Importe_d          DECIMAL(18,5) NULL,

  CONSTRAINT UX_FactSalidas UNIQUE (Empresa, Folio, Renglon)
);
GO
CREATE INDEX IX_FactSalidas_Date       ON dbo.FactSalidas(DateKey);
CREATE INDEX IX_FactSalidas_Cliente    ON dbo.FactSalidas(ClienteKey);
CREATE INDEX IX_FactSalidas_Vendedor   ON dbo.FactSalidas(VendedorKey);
CREATE INDEX IX_FactSalidas_Articulo   ON dbo.FactSalidas(ArticuloKey);
GO

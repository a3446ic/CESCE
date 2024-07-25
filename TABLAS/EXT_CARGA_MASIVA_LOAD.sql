CREATE COLUMN TABLE EXT.EXT_CARGA_MASIVA_LOAD(
	NUM_POLIZA NVARCHAR(10),
	CLIENT NVARCHAR(50),
	ESTADO NVARCHAR(10),
	COMPANYIA NVARCHAR(50),
	EFECTO NVARCHAR(10),
	FECHA_VENCIMIENTO NVARCHAR(10),
	FECHA_CREACION NVARCHAR(10),
	TIPOLOGIA NVARCHAR(50),
	FECHA_CONTRATACION NVARCHAR(10),
	PRIMA_NETA NVARCHAR(10),
	RIESGO_POLIZA NVARCHAR(10),
	COLABORADOR NVARCHAR(50),
	CLIENTE_COLABORADOR NVARCHAR(50),
	BATCHNAME NVARCHAR(50),
	MODIF_USER NVARCHAR(50),
	CREATEDATE TIMESTAMP
)
UNLOAD PRIORITY 5 AUTO MERGE;
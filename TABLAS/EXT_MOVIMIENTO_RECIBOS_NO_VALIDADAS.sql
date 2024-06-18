CREATE COLUMN TABLE "EXT"."EXT_MOVIMIENTO_RECIBOS_NO_VALIDADAS"(
	"FECHA_DATOS" VARCHAR(8),
	"COD_OPERACION" VARCHAR(20),
	"NUM_RECIBO" VARCHAR(50),
	"TIPO_MVTO" VARCHAR(3),
	"DESC_MVTO" NVARCHAR(100),
	"NUM_MVTO" VARCHAR(50),
	"FECHA_MVTO" VARCHAR(8),
	"TIPO_RECIBO" VARCHAR(3),
	"DESC_TIPO_RECIBO" NVARCHAR(100),
	"FECHA_EFECTO_ANUALIDAD" VARCHAR(8),
	"FECHA_SITUACION" VARCHAR(8),
	"FECHA_PAGO" VARCHAR(8),
	"FECHA_COBRO" VARCHAR(8),
	"FECHA_EMISION" VARCHAR(8),
	"IMPORTE_TOTAL_RECIBO" VARCHAR(20),
	"IMPORTE_COBRADO" VARCHAR(20),
	"IND_FRACCION" VARCHAR(1),
	"SITUACION_RECIBO" VARCHAR(3),
	"DESC_SITUACION_RECIBO" NVARCHAR(100),
	"IDDIVISA" VARCHAR(3),
	"IDCOMPANIA" VARCHAR(1),
	"IDPAIS" VARCHAR(3),
	"NUM_PERIODO" VARCHAR(3),
	"ID_FORMAPAGO" VARCHAR(3),
	"TIPO_CAMBIO" VARCHAR(13),
	"IDFISCAL_ASEGURADO" VARCHAR(20),
	"NOMBRE_EMPRESA" NVARCHAR(100),
	"COD_RIESGO" VARCHAR(8),
	"COD_GRAVAMEN" VARCHAR(3),
	"IMPORTE_MVTO_RIESGO" VARCHAR(20),
	"COD_AVAL" VARCHAR(30),
	"COD_GARANTIA" VARCHAR(4),
	"NUM_RECIBO_REAL" VARCHAR(6),
	"BATCHNAME" NVARCHAR(90),
	"CREATEDATE" LONGDATE CS_LONGDATE,
	"ESTADOREG" VARCHAR(100)
)
UNLOAD PRIORITY 5 AUTO MERGE;

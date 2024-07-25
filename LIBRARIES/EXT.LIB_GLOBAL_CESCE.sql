CREATE OR REPLACE LIBRARY "EXT"."LIB_GLOBAL_CESCE" LANGUAGE SQLSCRIPT AS
BEGIN
  PUBLIC VARIABLE v_eot                                CONSTANT DATE = TO_DATE('22000101','yyyymmdd');
  PUBLIC VARIABLE cn_DEBUG_OUT                         CONSTANT VARCHAR(50) := 'DEBUG_OUT';
  PUBLIC VARIABLE cn_RAMO_CREDITO                         CONSTANT VARCHAR(20) := 'CREDITO';
  PUBLIC VARIABLE cn_RAMO_CAUCION                         CONSTANT VARCHAR(20) := 'CAUCION';
  PUBLIC FUNCTION getTenantID() RETURNS o_TI VARCHAR(4)
	AS
  
		BEGIN
			SELECT DISTINCT TENANTID
			INTO o_TI
			FROM TCMP.CS_CALENDAR;
		END;
  PUBLIC PROCEDURE w_debug( IN i_Tenant VARCHAR2(4), IN i_txt VARCHAR2(4000), IN i_proceso VARCHAR2(400), INOUT io_valor Number ) LANGUAGE SQLSCRIPT 
	AS
  
		BEGIN
			INSERT INTO "EXT"."CSE_DEBUG" (TENANTID, DATETIME, PROCESO, VALUE, TEXT)
			VALUES (i_Tenant, NOW(), i_proceso, io_valor, i_txt);
			
			io_valor:= io_valor + 1;
			
			COMMIT;
		END;
  PUBLIC PROCEDURE getPeriodName(IN i_Tenant VARCHAR2(4), IN pPlRunSeq BIGINT,  OUT o_PeriodName  VARCHAR(255) ) LANGUAGE SQLSCRIPT
	AS
	
		BEGIN
		
			SELECT PER.NAME INTO o_PeriodName
			FROM TCMP.CS_CALENDAR CAL
			JOIN TCMP.CS_PERIOD PER
				ON CAL.CALENDARSEQ = PER.CALENDARSEQ
			JOIN TCMP.CS_PLRUN PLRUN
				ON PLRUN.CALENDARSEQ = CAL.CALENDARSEQ
				AND PLRUN.PERIODSEQ = PER.PERIODSEQ
			WHERE PER.REMOVEDATE = v_eot
				AND CAL.REMOVEDATE = v_eot
				AND PLRUN.PIPELINERUNSEQ = PPLRUNSEQ;
	
		END;
  PUBLIC PROCEDURE getPeriodSeq(IN i_Tenant VARCHAR2(4), IN i_PeriodName VARCHAR(255) ,  OUT o_PeriodSeq  BIGINT ) LANGUAGE SQLSCRIPT
	AS
		
		BEGIN
		
			SELECT PERIODSEQ INTO o_PeriodSeq
			FROM TCMP.CS_PERIOD  
			WHERE REMOVEDATE = v_eot
				AND NAME = i_PeriodName
				AND TENANTID =i_Tenant;
	
		END;
  PUBLIC PROCEDURE getCalendarName (IN i_Tenant VARCHAR2(4), IN pPlRunSeq BIGINT,  OUT o_CalendarName  VARCHAR(255) ) LANGUAGE SQLSCRIPT
	AS
	
		BEGIN
		
			SELECT CAL.NAME INTO o_CalendarName
			FROM TCMP.CS_PLRUN PLRUN
			INNER JOIN TCMP.CS_CALENDAR CAL
				ON PLRUN.CALENDARSEQ = CAL.CALENDARSEQ
					AND CAL.REMOVEDATE = v_eot
					AND CAL.TENANTID = i_Tenant
			WHERE PLRUN.PIPELINERUNSEQ = pPlRunSeq
				AND PLRUN.TENANTID = i_Tenant;
				
		END;
  PUBLIC PROCEDURE getCalendarSeq(IN i_Tenant VARCHAR2(4), IN i_CalendarName VARCHAR(255),  OUT o_CalendarSeq  BIGINT ) LANGUAGE SQLSCRIPT
	AS
	
		BEGIN
		
			SELECT CAL.CALENDARSEQ INTO o_CalendarSeq 
			FROM TCMP.CS_CALENDAR CAL
			WHERE CAL.TENANTID = i_Tenant
				AND CAL.REMOVEDATE = v_eot
				AND CAL.NAME = i_CalendarName;
		
		END;
  PUBLIC PROCEDURE getProcessingUnitName (IN i_Tenant VARCHAR2(4), IN pPlRunSeq BIGINT,  OUT o_ProcessingUnitName  VARCHAR(255) ) LANGUAGE SQLSCRIPT
	AS
		
		BEGIN
		
			SELECT PU.NAME INTO o_ProcessingUnitName
			FROM TCMP.CS_PLRUN PLRUN
			INNER JOIN TCMP.CS_PROCESSINGUNIT PU
				ON PLRUN.PROCESSINGUNITSEQ = PU.PROCESSINGUNITSEQ
					AND PU.TENANTID = i_Tenant
			WHERE PLRUN.PIPELINERUNSEQ = pPlRunSeq
				AND PLRUN.TENANTID = i_Tenant;
		
		END;
  PUBLIC PROCEDURE getProcessingUnitSeq(IN i_Tenant VARCHAR2(4), IN i_ProcessingUnitName VARCHAR(255),  OUT o_ProcessingUnitSeq  BIGINT ) LANGUAGE SQLSCRIPT
	AS
	
		BEGIN
		
			SELECT PU.PROCESSINGUNITSEQ INTO o_ProcessingUnitSeq 
			FROM TCMP.CS_PROCESSINGUNIT PU
			WHERE PU.TENANTID = i_Tenant
				AND PU.NAME = i_ProcessingUnitName;
				
		END;
  PUBLIC FUNCTION getCurrency(in_currencyId VARCHAR(10), in_currencyISO VARCHAR(10) ) 
  RETURNS currencyId VARCHAR(10), currencyName NVARCHAR(127), currencyISO VARCHAR(10)  LANGUAGE SQLSCRIPT AS

	BEGIN
--Devuelve:
-- currencyId – Id de la divisa CESCE
-- currencyName – Descripción asociada a la divisa
-- currencyISO – codigo ISO de la divisa usada en SAP Commissions

				IF in_currencyId IS not NULL and in_currencyId <> '' THEN
				-- Se busca el CurrencyISO en función del currencyId
					SELECT clas.classifierid, clas.NAME, cgc.GENERICATTRIBUTE2 into currencyId, currencyName, currencyISO
							DEFAULT in_currencyId, '', ''
					FROM cs_category cat, cs_category_classifiers ccc, 
						cs_classifier clas, cs_genericclassifier cgc
					WHERE cat.ruleelementseq = ccc.categoryseq
						AND clas.classifierseq = ccc.classifierseq
						AND clas.classifierseq = cgc.classifierseq
						AND cat.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND cat.ISLAST=1
						AND ccc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND ccc.ISLAST=1
						AND clas.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND clas.ISLAST=1
						AND cgc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND cgc.ISLAST=1
						AND cat.NAME = 'Divisas'
						AND clas.classifierid = in_currencyId;
						
				ELSEIF in_currencyISO  IS not NULL and in_currencyISO <> ''  THEN
				-- Se busca el CurrencyId en función del currencyISO
					SELECT clas.classifierid, clas.NAME, cgc.GENERICATTRIBUTE2 into currencyId, currencyName, currencyISO
							DEFAULT '', '', in_currencyISO
					FROM cs_category cat, cs_category_classifiers ccc, 
						cs_classifier clas, cs_genericclassifier cgc
					WHERE cat.ruleelementseq = ccc.categoryseq
						AND clas.classifierseq = ccc.classifierseq
						AND clas.classifierseq = cgc.classifierseq
						AND cat.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND cat.ISLAST=1
						AND ccc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND ccc.ISLAST=1
						AND clas.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND clas.ISLAST=1
						AND cgc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND cgc.ISLAST=1
						AND cat.NAME = 'Divisas'
						AND cgc.GENERICATTRIBUTE2 = in_currencyISO;
						
				ELSE
					currencyId := NULL;
					currencyName := NULL;
					currencyISO :=  NULL;
				END IF;

			END;
  PUBLIC FUNCTION getProductId(modalidad VARCHAR(3), submodalidad VARCHAR(50), idPais VARCHAR(3), numPoliza VARCHAR(8)) 
  RETURNS productId VARCHAR(10), productDescription NVARCHAR(127), ramo VARCHAR(20), p_emision_sinplan DECIMAL(3,2), p_renovacion_sinplan DECIMAL(3,2), buname NVARCHAR(50), comisionaIS SMALLINT, valorIS DECIMAL(25,10), unittype_valorIS NVARCHAR(50)
  AS
            BEGIN
--Devuelve:
-- productId – Id del producto SAP Commissions asociado a la modalidad, gararantia (si existe) y Pais
-- productDescription – Descripción asociada al producto
-- ramo – Ramo asociado al producto CREDITO o CAUCION
-- p_emision_sinplan – Porcentaje de emisión cuando el producto no está definido por el plan de comisionamiento personalizado
-- p_renovacion_sinplan – Porcentaje de renovación cuando el producto no está definido por el plan de comisionamiento personalizado
-- buname – Nombre de la unidad de Negocio asociado al IDPAIS
-- comisionaIS (comisiona Ingreso por servicios) – 0/1 Indica si el producto comisiona ingresos por servicios.
-- valorIS (valor comisión de ingresos por servicios) – Importe de Comision (FEE) para productos que comisionan Ingresos por servicios
-- unittype_valorIS (unidad del valor de ingresos por servicios) – unidad asociada al Importe de Comision (FEE)


				IF modalidad IS NULL OR modalidad = '' THEN
					productId := NULL;
					productDescription := NULL;
					ramo :=  NULL;
					p_emision_sinplan :=  NULL;
					p_renovacion_sinplan :=  NULL;
				ELSE

					DECLARE buMap VARCHAR(3);

					IF idPais IS NULL OR idPais = '' THEN
						buMap := 1;
						buname := 'Spain';
					ELSE
						SELECT TO_VARCHAR(TO_INTEGER(cgc.GENERICNUMBER1)), cgc.GENERICATTRIBUTE1 into buMap, buname
							DEFAULT '1', 'Spain' 
						FROM cs_category cat, cs_category_classifiers ccc, 
						cs_classifier clas, cs_genericclassifier cgc
						WHERE cat.ruleelementseq = ccc.categoryseq
						AND clas.classifierseq = ccc.classifierseq
						AND clas.classifierseq = cgc.classifierseq
						AND cat.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND cat.ISLAST=1
						AND ccc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND ccc.ISLAST=1
						AND clas.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND clas.ISLAST=1
						AND cgc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND cgc.ISLAST=1
						AND cat.NAME = 'ID Paises'
						AND clas.classifierid = idPais;
					END IF;
					IF submodalidad IS NULL OR submodalidad = '' OR submodalidad = '0' THEN
						SELECT clas.CLASSIFIERID, clas.NAME, cp.GENERICATTRIBUTE1,
							CASE WHEN cp.GENERICBOOLEAN2 = 0 THEN CP.GENERICNUMBER1  ELSE NULL END as P_Emision_SinPlan,
							CASE WHEN cp.GENERICBOOLEAN2 = 0 THEN CP.GENERICNUMBER2  ELSE NULL END as P_Renovacion_SinPlan,
							cp.GENERICBOOLEAN1, cp.PRICE, ut.NAME
							INTO productId, productDescription, ramo, p_emision_sinplan, p_renovacion_sinplan, comisionaIS, valorIS, unittype_valorIS
							DEFAULT modalidad, modalidad, cn_RAMO_CREDITO, NULL, NULL, NULL, NULL, NULL
						FROM TCMP.CS_CLASSIFIER clas, TCMP.CS_PRODUCT cp
							 LEFT JOIN TCMP.CS_UNITTYPE ut on cp.UNITTYPEFORPRICE = ut.UNITTYPESEQ
						WHERE clas.CLASSIFIERSEQ = cp.CLASSIFIERSEQ
						AND clas.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND clas.ISLAST = 1
						AND cp.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND cp.ISLAST = 1
						AND cp.GENERICATTRIBUTE2 = modalidad
						AND cp.GENERICATTRIBUTE4 IS NULL
						-- Si existe cp.GENERICATTRIBUTE6, tiene una expresion regular para identificar el numero de poliza
						AND 1 = CASE WHEN cp.GENERICATTRIBUTE6 IS NULL 
								THEN 1
								ELSE 
									CASE WHEN numPoliza LIKE_REGEXPR cp.GENERICATTRIBUTE6 THEN 1 ELSE 0 END
								END
						AND clas.BUSINESSUNITMAP = buMap;
					ELSE 
						SELECT clas.CLASSIFIERID, clas.NAME, cp.GENERICATTRIBUTE1,
							CASE WHEN cp.GENERICBOOLEAN2 = 0 THEN CP.GENERICNUMBER1  ELSE NULL END as P_Emision_SinPlan,
							CASE WHEN cp.GENERICBOOLEAN2 = 0 THEN CP.GENERICNUMBER2  ELSE NULL END as P_Renovacion_SinPlan,
							cp.GENERICBOOLEAN1, cp.PRICE, ut.NAME
							INTO productId, productDescription, ramo, p_emision_sinplan, p_renovacion_sinplan, comisionaIS, valorIS, unittype_valorIS
							DEFAULT modalidad, modalidad, cn_RAMO_CREDITO, NULL, NULL, NULL, NULL, NULL
						FROM TCMP.CS_CLASSIFIER clas, TCMP.CS_PRODUCT cp
							 LEFT JOIN TCMP.CS_UNITTYPE ut on cp.UNITTYPEFORPRICE = ut.UNITTYPESEQ
						WHERE clas.CLASSIFIERSEQ = cp.CLASSIFIERSEQ
						AND clas.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND clas.ISLAST = 1
						AND cp.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND cp.ISLAST = 1
						AND cp.GENERICATTRIBUTE2 = modalidad
						AND cp.GENERICATTRIBUTE4 = submodalidad
						-- Si existe cp.GENERICATTRIBUTE6, tiene una expresion regular para identificar el numero de poliza
						AND 1 = CASE WHEN cp.GENERICATTRIBUTE6 IS NULL 
								THEN 1
								ELSE 
									CASE WHEN numPoliza LIKE_REGEXPR cp.GENERICATTRIBUTE6 THEN 1 ELSE 0 END
								END
						AND clas.BUSINESSUNITMAP = buMap;
					END IF;
				END IF;

			END;
  PUBLIC FUNCTION getProductDetails(modalidad VARCHAR(3), submodalidad VARCHAR(50), idPais VARCHAR(3), numPoliza VARCHAR(8)) 
  RETURNS TABLE (productId VARCHAR(10), productDescription NVARCHAR(127), ramo VARCHAR(20),
  p_emision_sinplan DECIMAL(3,2), p_renovacion_sinplan DECIMAL(3,2), buname NVARCHAR(50), comisionaIS SMALLINT, valorIS DECIMAL(25,10), 
  unittype_valorIS NVARCHAR(50)) LANGUAGE SQLSCRIPT AS
	BEGIN
--Devuelve:
-- productId – Id del producto SAP Commissions asociado a la modalidad, gararantia (si existe) y Pais
-- productDescription – Descripción asociada al producto
-- ramo – Ramo asociado al producto CREDITO o CAUCION
-- p_emision_sinplan – Porcentaje de emisión cuando el producto no está definido por el plan de comisionamiento personalizado
-- p_renovacion_sinplan – Porcentaje de renovación cuando el producto no está definido por el plan de comisionamiento personalizado
-- buname – Nombre de la unidad de Negocio asociado al IDPAIS
-- comisionaIS (comisiona Ingreso por servicios) – 0/1 Indica si el producto comisiona ingresos por servicios.
-- valorIS (valor comisión de ingresos por servicios) – Importe de Comision (FEE) para productos que comisionan Ingresos por servicios
-- unittype_valorIS (unidad del valor de ingresos por servicios) – unidad asociada al Importe de Comision (FEE)

		declare productId VARCHAR(10);
		declare productDescription NVARCHAR(127);
		declare ramo VARCHAR(20);
		declare p_emision_sinplan DECIMAL(3,2);
		declare p_renovacion_sinplan DECIMAL(3,2);
		declare buname NVARCHAR(50);
		declare comisionaIS SMALLINT;
		declare valorIS DECIMAL(25,10);
		declare unittype_valorIS NVARCHAR(50);
		
				IF modalidad IS NULL OR modalidad = '' THEN
					productId := NULL;
					productDescription := NULL;
					ramo :=  NULL;
					p_emision_sinplan :=  NULL;
					p_renovacion_sinplan :=  NULL;
				ELSE

					DECLARE buMap VARCHAR(3);

					IF idPais IS NULL OR idPais = '' THEN
						buMap := 1;
						buname := 'Spain';
					ELSE
						SELECT TO_VARCHAR(TO_INTEGER(cgc.GENERICNUMBER1)), cgc.GENERICATTRIBUTE1 into buMap, buname
							DEFAULT '1', 'Spain' 
						FROM cs_category cat, cs_category_classifiers ccc, 
						cs_classifier clas, cs_genericclassifier cgc
						WHERE cat.ruleelementseq = ccc.categoryseq
						AND clas.classifierseq = ccc.classifierseq
						AND clas.classifierseq = cgc.classifierseq
						AND cat.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND cat.ISLAST=1
						AND ccc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND ccc.ISLAST=1
						AND clas.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND clas.ISLAST=1
						AND cgc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
						AND cgc.ISLAST=1
						AND cat.NAME = 'ID Paises'
						AND clas.classifierid = idPais;
					END IF;
					IF submodalidad IS NULL OR submodalidad = ''  OR submodalidad = '0' THEN
						SELECT clas.CLASSIFIERID, clas.NAME, cp.GENERICATTRIBUTE1,
							CASE WHEN cp.GENERICBOOLEAN2 = 0 THEN CP.GENERICNUMBER1  ELSE NULL END as P_Emision_SinPlan,
							CASE WHEN cp.GENERICBOOLEAN2 = 0 THEN CP.GENERICNUMBER2  ELSE NULL END as P_Renovacion_SinPlan,
							cp.GENERICBOOLEAN1, cp.PRICE, ut.NAME
							INTO productId, productDescription, ramo, p_emision_sinplan, p_renovacion_sinplan, comisionaIS, valorIS, unittype_valorIS
							DEFAULT modalidad, modalidad, cn_RAMO_CREDITO, NULL, NULL, NULL, NULL, NULL
						FROM TCMP.CS_CLASSIFIER clas, TCMP.CS_PRODUCT cp
							 LEFT JOIN TCMP.CS_UNITTYPE ut on cp.UNITTYPEFORPRICE = ut.UNITTYPESEQ
						WHERE clas.CLASSIFIERSEQ = cp.CLASSIFIERSEQ
						AND clas.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND clas.ISLAST = 1
						AND cp.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND cp.ISLAST = 1
						AND cp.GENERICATTRIBUTE2 = modalidad
						AND cp.GENERICATTRIBUTE4 IS NULL
						-- Si existe cp.GENERICATTRIBUTE6, tiene una expresion regular para identificar el numero de poliza
						AND 1 = CASE WHEN cp.GENERICATTRIBUTE6 IS NULL 
								THEN 1
								ELSE 
									CASE WHEN numPoliza LIKE_REGEXPR cp.GENERICATTRIBUTE6 THEN 1 ELSE 0 END
								END
						AND clas.BUSINESSUNITMAP = buMap;
					ELSE 
						SELECT clas.CLASSIFIERID, clas.NAME, cp.GENERICATTRIBUTE1,
							CASE WHEN cp.GENERICBOOLEAN2 = 0 THEN CP.GENERICNUMBER1  ELSE NULL END as P_Emision_SinPlan,
							CASE WHEN cp.GENERICBOOLEAN2 = 0 THEN CP.GENERICNUMBER2  ELSE NULL END as P_Renovacion_SinPlan,
							cp.GENERICBOOLEAN1, cp.PRICE, ut.NAME
							INTO productId, productDescription, ramo, p_emision_sinplan, p_renovacion_sinplan, comisionaIS, valorIS, unittype_valorIS
							DEFAULT modalidad, modalidad, cn_RAMO_CREDITO, NULL, NULL, NULL, NULL, NULL
						FROM TCMP.CS_CLASSIFIER clas, TCMP.CS_PRODUCT cp
							 LEFT JOIN TCMP.CS_UNITTYPE ut on cp.UNITTYPEFORPRICE = ut.UNITTYPESEQ
						WHERE clas.CLASSIFIERSEQ = cp.CLASSIFIERSEQ
						AND clas.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND clas.ISLAST = 1
						AND cp.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
						AND cp.ISLAST = 1
						AND cp.GENERICATTRIBUTE2 = modalidad
						AND cp.GENERICATTRIBUTE4 = submodalidad
						-- Si existe cp.GENERICATTRIBUTE6, tiene una expresion regular para identificar el numero de poliza
						AND 1 = CASE WHEN cp.GENERICATTRIBUTE6 IS NULL 
								THEN 1
								ELSE 
									CASE WHEN numPoliza LIKE_REGEXPR cp.GENERICATTRIBUTE6 THEN 1 ELSE 0 END
								END
						AND clas.BUSINESSUNITMAP = buMap;
					END IF;
				END IF;
				
				RETURN SELECT :productId as productId, :productDescription as productDescription, :ramo as ramo, 
							  :p_emision_sinplan as p_emision_sinplan, :p_renovacion_sinplan as p_renovacion_sinplan, :buname as buname,
							  :comisionaIS as comisionaIS, :valorIS as valorIS, :unittype_valorIS as unittype_valorIS From DUMMY;

			END;
  PUBLIC FUNCTION getCodGarantia(in_codOperacion VARCHAR(20), in_codRiesgo INTEGER ) 
  RETURNS codGarantia SMALLINT  LANGUAGE SQLSCRIPT AS

	BEGIN
	
		declare codModalidad SMALLINT;
		declare codCober SMALLINT;
		declare codGaran SMALLINT;
		declare codRies SMALLINT;
		declare codAmbito SMALLINT;
		declare codRiesgo VARCHAR(8) := '0';
		
			SELECT CONCAT(codRiesgo, in_codRiesgo) INTO codRiesgo FROM DUMMY;
			SELECT TO_INT(SUBSTRING(in_codOperacion, 0, 3)) INTO codModalidad FROM DUMMY;
			SELECT TO_INT(SUBSTRING(codRiesgo, 0, 2)) INTO codCober FROM DUMMY;
			SELECT TO_INT(SUBSTRING(codRiesgo, 3, 2)) INTO codGaran FROM DUMMY;
			SELECT TO_INT(SUBSTRING(codRiesgo, 5, 2)) INTO codRies FROM DUMMY;
			SELECT TO_INT(SUBSTRING(codRiesgo, 7, 2)) INTO codAmbito FROM DUMMY;

				IF codModalidad < 341 THEN
					IF codGaran = 1 THEN
						IF codRies = 1 THEN
							--MOVE 1 TO WKF-COD-GARANTIA
							codGarantia = 1;
						ELSEIF codRies = 2 THEN 
							--MOVE 2 TO WKF-COD-GARANTIA
							codGarantia = 2;
						END IF;
					ELSEIF codGaran = 2 THEN 
						IF codRies = 1 THEN
							--MOVE 4 TO WKF-COD-GARANTIA
							codGarantia = 4;
						ELSEIF codRies = 2 THEN 
							--MOVE 5 TO WKF-COD-GARANTIA
							codGarantia = 5;
						END IF;
					ELSEIF codGaran = 4 THEN 
						--MOVE 3 TO WKF-COD-GARANTIA
						codGarantia = 3;
					ELSEIF codGaran = 24 THEN 
						--MOVE 24 TO WKF-COD-GARANTIA
						codGarantia = 24;
					END IF;
				ELSE
					IF codGaran = 1 THEN
						IF codRies = 1 THEN
							IF codAmbito = 1 THEN
								--MOVE 6 TO WKF-COD-GARANTIA
								codGarantia = 6;
							ELSEIF codAmbito = 2 THEN 
								--MOVE 7 TO WKF-COD-GARANTIA
								codGarantia = 7;
							END IF;
						ELSEIF codRies = 2 THEN 
							IF codAmbito = 2 THEN
								--MOVE 2 TO WKF-COD-GARANTIA
								codGarantia = 2;
							END IF;
						END IF;
					END IF;
				END IF;

	END;
  PUBLIC FUNCTION getCueRiesgo(in_codRiesgo INTEGER ) 
  RETURNS cueRiesgo SMALLINT  LANGUAGE SQLSCRIPT AS

	BEGIN

		declare codCober SMALLINT;
		declare codRiesgo VARCHAR(8) := '0';
		
			SELECT CONCAT(codRiesgo, in_codRiesgo) INTO codRiesgo FROM DUMMY;
			SELECT TO_INT(SUBSTRING(codRiesgo, 0, 2)) INTO codCober FROM DUMMY;

				IF codCober = 1 THEN
					cueRiesgo = 1;
				ELSEIF codCober = 2 OR codCober = 3 THEN
					cueRiesgo = 2;
				END IF;
	END;
  PUBLIC FUNCTION getCompany(in_idCompanySioc VARCHAR(4), in_idPais VARCHAR(3))
  RETURNS companySapFi VARCHAR(10) LANGUAGE SQLSCRIPT AS
	BEGIN
--Devuelve:
-- companySapFi – Codigo de compania de SAP Financiero

	IF in_idCompanySioc = '' or in_idPais = '' THEN
		companySapFi := Null;
	ELSE
	-- Se busca el CurrencyISO en función del currencyId
		SELECT clas.classifierid into companySapFi
			DEFAULT NULL
		FROM cs_category cat, cs_category_classifiers ccc, 
			cs_classifier clas, cs_genericclassifier cgc
		WHERE cat.ruleelementseq = ccc.categoryseq
			AND clas.classifierseq = ccc.classifierseq
			AND clas.classifierseq = cgc.classifierseq
			AND cat.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
			AND cat.ISLAST=1
			AND ccc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
			AND ccc.ISLAST=1
			AND clas.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
			AND clas.ISLAST=1
			AND cgc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
			AND cgc.ISLAST=1
			AND cat.NAME = 'Empresas'
			AND cgc.GENERICNUMBER1 = in_idPais  -- idpais
			AND cgc.GENERICATTRIBUTE3 =  in_idCompanySioc ;-- id company sioc
		END IF;
	END;
  PUBLIC FUNCTION getMediadorData(in_cod_mediador VARCHAR(4), in_subclave VARCHAR(4))
  RETURNS TABLE (positionname VARCHAR(10), idhost VARCHAR(50), canalDist varchar(1), dirTerritorial VARCHAR(50), idDirTerritorial SMALLINT, buname VARCHAR(50)) LANGUAGE SQLSCRIPT AS
	BEGIN
--Devuelve:
-- positionname – Positionname (si existe)
-- idhost - Id de Host del mediador
-- canalDist - Canal Distribucion CIC
-- dirTerritorial - Nombre Dirección Territorial
-- idDirTerritorial - ID Dirección Territorial
-- buname  - Business Unit Name

		declare positionname VARCHAR(10);
		declare idhost VARCHAR(50);
		declare canalDist varchar(1);
		declare dirTerritorial VARCHAR(50);
		declare idDirTerritorial SMALLINT;
		declare buname VARCHAR(50);

			SELECT TOP 1 POSITIONNAME, IDHOST, CANAL_DIST_CIC, DIR_TERRITORIAL,ID_DIR_TERRITORIAL, BUSINESSUNIT
				INTO positionname, idhost, canalDist, dirTerritorial, idDirTerritorial, buname
				DEFAULT NULL, NULL, NULL, NULL, NULL, NULL
			FROM EXT.MODIFICAR_MEDIADOR med
						WHERE med.COD_MEDIADOR = in_cod_mediador
						AND med.SUBCLAVE = in_subclave;

			RETURN SELECT :positionname as positionname, :idhost as idhost, :canalDist as canalDist, 
							  :dirTerritorial as dirTerritorial, :idDirTerritorial as idDirTerritorial, :buname as buname
							  From DUMMY;

			END;
  PUBLIC FUNCTION getCountry(in_idPais VARCHAR(3))
  RETURNS ISOCode VARCHAR(10) LANGUAGE SQLSCRIPT AS
	BEGIN
--Devuelve:
-- ISOCode – Codigo ISO Del Pais para SAP FI

	IF in_idPais = '' THEN
		ISOCode := Null;
	ELSE
	-- Se busca el CountryISOCode en función del IdPais
		SELECT cgc.GENERICATTRIBUTE2 into ISOCode
			DEFAULT NULL
		FROM cs_category cat, cs_category_classifiers ccc, 
			cs_classifier clas, cs_genericclassifier cgc
		WHERE cat.ruleelementseq = ccc.categoryseq
			AND clas.classifierseq = ccc.classifierseq
			AND clas.classifierseq = cgc.classifierseq
			AND cat.REMOVEDATE = TO_DATE('22000101','yyyymmdd')
			AND cat.ISLAST=1
			AND ccc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
			AND ccc.ISLAST=1
			AND clas.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
			AND clas.ISLAST=1
			AND cgc.REMOVEDATE = TO_DATE('22000101','yyyymmdd') 
			AND cgc.ISLAST=1
			AND cat.NAME = 'ID Paises'
			AND clas.classifierid = in_idPais;
		END IF;
	END;
  PUBLIC FUNCTION conversionImp(num DECIMAL(15,3), longitud SMALLINT)
	RETURNS salida NVARCHAR(20) LANGUAGE SQLSCRIPT AS

	BEGIN
	
		DECLARE ultimoDigito NVARCHAR(1);
		DECLARE nuevoCaracter NVARCHAR(1);

		IF num >= 0 THEN
		
			salida := LPAD(TO_VARCHAR(num, '999999999999999.999'), longitud, 0);
		
		ELSE

			salida := LPAD(TO_VARCHAR(ABS(num), '999999999999999.999'), longitud, 0);
			ultimoDigito := SUBSTR(salida, LENGTH(salida));
			SELECT MAP(ultimoDigito, 0, 'p', 1, 'q', 2, 'r', 3, 's', 4, 't', 5, 'u', 6, 'v', 7, 'w', 8, 'x', 9, 'y') INTO nuevoCaracter DEFAULT ultimoDigito 
			FROM DUMMY;			

			salida := replace_regexpr(ultimoDigito in salida WITH nuevoCaracter FROM LENGTH(salida) OCCURRENCE ALL);
		
		END IF;

	END;
  PUBLIC PROCEDURE ObtenerSigRefFactura(
    IN inMediador VARCHAR(10),
	IN inSociedad VARCHAR(4),
    IN inYear INT,
	OUT v_RefFactura VARCHAR(8) ) LANGUAGE SQLSCRIPT
	AS
	
		BEGIN
		DECLARE vProcedure VARCHAR(127) := 'ObtenerSigRefFactura';
		DECLARE io_contador Number := 0;
		DECLARE i_Tenant VARCHAR(127);
		DECLARE v_UltimoNumero INT;
		DECLARE v_SiguienteNumero INT;
		DECLARE v_CifraSociedad INT;
--		DECLARE v_RefFactura VARCHAR(8);

	DECLARE EXIT HANDLER FOR SQLEXCEPTION

	BEGIN
		CALL w_debug (i_Tenant, vProcedure || '. SQL ERROR_MESSAGE: ' ||
					IFNULL(::SQL_ERROR_MESSAGE,'') || '. SQL_ERROR_CODE: ' || ::SQL_ERROR_CODE, vProcedure, io_contador);
	END;

		SELECT TENANTID INTO i_Tenant FROM CS_TENANT;

		CALL w_debug (i_Tenant,'Inicio proceso ', vProcedure, io_contador);
		CALL w_debug (i_Tenant,'Parametros inMediador ' || inMediador || ' inSociedad ' || inSociedad || ' inYear '  || to_varchar(inYear) , vProcedure, io_contador);
    -- Iniciar la transacción
		--BEGIN TRANSACTION
		-- Obtener el último número de factura
			SELECT UltimoNumero, CIFRA_SOCIEDAD INTO v_UltimoNumero, v_CifraSociedad
				DEFAULT NULL,NULL
			FROM EXT.NUM_FACTURAS
			WHERE POSITIONNAME = :inMediador AND IDSOCIEDAD = :inSociedad AND YEAR = :inYear;
		CALL w_debug (i_Tenant,'Comprueba Ultimo Numero es Nulo ', vProcedure, io_contador);

			-- No hay registros para el cliente y año, establecer el primer número como 1 y determinar la cifra adicional asociada la sociedad
			IF v_UltimoNumero IS NULL THEN
				v_SiguienteNumero := 1;
			-- Hay que obtener la cifra asociada a la SOCIEDAD
				IF inSociedad = 'CE14' THEN 
					v_CifraSociedad := 9;
				ELSE
					v_CifraSociedad := 0;
				END IF;
			ELSE
				v_SiguienteNumero := v_UltimoNumero + 1;
			END IF;
			
			CALL w_debug (i_Tenant,'Siguiente Numero ' || to_varchar(v_SiguienteNumero) || ' cifra sociedad ' || to_varchar(v_CifraSociedad) , vProcedure, io_contador);

		-- Actualizar la tabla con el siguiente número
			MERGE INTO EXT.NUM_FACTURAS
			USING (SELECT :inMediador AS POSITIONNAME, :inSociedad as IDSOCIEDAD, :inYear AS YEAR,
						:v_CifraSociedad as CIFRA_SOCIEDAD, :v_SiguienteNumero AS SiguienteNumero
					FROM DUMMY) AS source
				ON EXT.NUM_FACTURAS.POSITIONNAME = source.POSITIONNAME AND EXT.NUM_FACTURAS.IDSOCIEDAD = source.IDSOCIEDAD AND EXT.NUM_FACTURAS.YEAR = source.YEAR
			WHEN MATCHED THEN
				UPDATE SET EXT.NUM_FACTURAS.UltimoNumero = source.SiguienteNumero
			WHEN NOT MATCHED THEN
				INSERT (POSITIONNAME, IDSOCIEDAD, YEAR, CIFRA_SOCIEDAD, UltimoNumero ) VALUES (source.POSITIONNAME,source.IDSOCIEDAD, source.YEAR, source.CIFRA_SOCIEDAD, source.SiguienteNumero);

		-- Referencia factura: 2 digitos del año + Cifra (9 o 0) + secuencial segun el ultimo numero de factura en 5 posiciones
			SELECT SUBSTRING(TO_NVARCHAR(inYear),3,2) || SUBSTRING(TO_NVARCHAR(:v_CifraSociedad),1,1) || LPAD(TO_NVARCHAR(:v_SiguienteNumero), 5, '0') 
			INTO v_RefFactura FROM DUMMY;

	-- Confirmar la transacción
		--COMMIT;

		END;
  PUBLIC PROCEDURE debug_hist_carga(IN dias SMALLINT) LANGUAGE SQLSCRIPT
	AS
	
		BEGIN
		
		  INSERT INTO EXT.CSE_DEBUG_HIST
		  
		  SELECT * FROM EXT.CSE_DEBUG WHERE DATETIME >= ADD_DAYS(TO_TIMESTAMP(TO_DATE(CURRENT_TIMESTAMP)), -dias);
		  
		  DELETE FROM EXT.CSE_DEBUG WHERE DATETIME IN (SELECT DATETIME FROM EXT.CSE_DEBUG WHERE DATETIME >= ADD_DAYS(TO_TIMESTAMP(TO_DATE(CURRENT_TIMESTAMP)), -dias));
				
		END;
		
	PUBLIC PROCEDURE gestion_backup(IN nombre_tabla NVARCHAR(100), IN unidad_tiempo NVARCHAR(10), IN cantidad_tiempo INT, cReportTable NVARCHAR(100), io_contador INT) LANGUAGE SQLSCRIPT
	AS
		BEGIN
			--Declaración de variables
			DECLARE i_Tenant VARCHAR(4);
			
			--Declaración de cursor para recorrer tablas de backup
			DECLARE CURSOR tablasBorrar  FOR
		    SELECT TABLE_NAME
		    FROM SYS.TABLES
		    WHERE SCHEMA_NAME = 'EXT'
		    AND TABLE_NAME LIKE nombre_tabla || '_BKP_%'
		    AND LENGTH(SUBSTR_AFTER(TABLE_NAME, nombre_tabla||'_BKP_')) = 8
		    AND SUBSTRING(TABLE_NAME, LENGTH(nombre_tabla||'_BKP_')+8) <> 2
		    -- Agregar condiciones unidad_tiempo
		    AND (
		    	(unidad_tiempo = 'YYYY' AND SUBSTR_AFTER(TABLE_NAME, nombre_tabla||'_BKP_') < TO_VARCHAR(ADD_YEARS(CURRENT_DATE, - cantidad_tiempo),'YYYYMMDD'))
		      	OR (unidad_tiempo = 'MM' AND SUBSTR_AFTER(TABLE_NAME, nombre_tabla||'_BKP_') < TO_VARCHAR(ADD_MONTHS(CURRENT_DATE, - cantidad_tiempo),'YYYYMMDD'))
		      	OR (unidad_tiempo = 'DD' AND SUBSTR_AFTER(TABLE_NAME, nombre_tabla||'_BKP_') < TO_VARCHAR(ADD_DAYS(CURRENT_DATE, - cantidad_tiempo),'YYYYMMDD'))
		      );
		   
		   DECLARE EXIT HANDLER FOR SQLEXCEPTION
		    BEGIN
				CALL w_debug (
								i_Tenant,
								'Ocurrió un error: ' || ::SQL_ERROR_MESSAGE || '. Error desde libreria LIB_GLOBAL_CESCE:gestion_backup',
								cReportTable,
								io_contador
							);		    
		        --RESIGNAL;
		    END;
    
		    -- Obtenemos tenant  
		    SELECT TENANTID INTO i_Tenant FROM CS_TENANT;
		    
		    IF (unidad_tiempo IS NULL OR unidad_tiempo = '' OR (unidad_tiempo <> 'YYYY' AND unidad_tiempo <> 'MM' AND unidad_tiempo <> 'DD')) THEN
			   SIGNAL SQL_ERROR_CODE 10005 SET MESSAGE_TEXT = 'Parámetro unidad_tiempo incorrecto: ' || COALESCE(unidad_tiempo, 'NULL');
		    END IF;
		    
		    IF (SELECT TABLE_NAME FROM SYS.TABLES where SCHEMA_NAME='EXT' and TABLE_NAME = nombre_tabla) IS NULL THEN
		    	SIGNAL SQL_ERROR_CODE 10006 SET MESSAGE_TEXT = 'Parámetro nombre_tabla incorrecto: ' || COALESCE(nombre_tabla, 'NULL') || ' no existe';
		    END IF;
		    
		    
		    -- Se crea un backup de la tabla de cartera si no hubiera uno del día
			IF (SELECT TABLE_NAME FROM SYS.TABLES where SCHEMA_NAME='EXT' and TABLE_NAME like (nombre_tabla || '_BKP_' || TO_VARCHAR(CURRENT_DATE, 'YYYYMMDD'))) IS NULL THEN
				EXEC('CREATE COLUMN TABLE EXT.'||nombre_tabla||'_BKP_' || TO_VARCHAR(CURRENT_DATE, 'YYYYMMDD') || ' AS (SELECT * FROM EXT.' || nombre_tabla || ')');
				CALL w_debug (
					i_Tenant,
					'Creado BackUp EXT.' || nombre_tabla ||'_BKP_' || TO_VARCHAR(CURRENT_DATE, 'YYYYMMDD'),
					cReportTable,
					io_contador
				);
			END IF;

			OPEN  tablasBorrar;
				FOR tabla AS tablasBorrar DO
					--EXEC('DROP TABLE EXT.' || tabla.TABLE_NAME);
				  
					CALL w_debug (
			        i_Tenant,
			        'Borrado BackUp ' || tabla.TABLE_NAME || ' desde libreria LIB_GLOBAL_CESCE:delete_backup',
			        cReportTable,
			        io_contador
			    );
				END FOR;
			CLOSE tablasBorrar;
		
			
			
		END;
END
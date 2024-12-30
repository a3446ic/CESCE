def db = resp.dbConnect('datasource.CESCEdb');

def departamento = currentUser.getDepartment()?.getName()?.toUpperCase();
logger.info('departamento: ' + departamento)
userName = currentUser.getName().toUpperCase();
logger.info('Nombre: ' + userName);
userType = currentUser.getUserType();
logger.info('userType: ' + userType)

def filtros = '';
boolean primerFiltro = true;

def mediador = form.getValue('auto_mediador');
def businessUnit = form.getValue('pl_business_unit');
def ramo = form.getValue('pl_ramo')?.toUpperCase();
def dirterritorial = form.getField('pl_direccion_territorial')?.getSelectedLabel();
logger.info('DT: ' + dirterritorial)
def gerentecanal = form.getValue('pl_gerente_canal');
def producto = form.getValue('pl_productos');
def date = form.getValue('date_effective_end_date')?:new Date()?.format('yyyy-MM-dd');

logger.info('businessUnit: ' + businessUnit);

if(businessUnit){
  filtros += " WHERE BUSINESSUNIT = '$businessUnit'";
  primerFiltro = false;
}

if(mediador){
  filtros += primerFiltro ? ' WHERE':' AND';
  def positionName = mediador.substring(0,9);
  logger.debug(positionName);
  filtros += " pco.POSITIONNAME = '$positionName'";
  primerFiltro = false;
}

if(ramo && ramo != 'AMBOS') {
  filtros += primerFiltro ? ' WHERE':' AND';
  filtros += " RAMO = '$ramo'";
  primerFiltro = false;
}

if(dirterritorial){
  filtros += primerFiltro ? ' WHERE':' AND';
  dirterritorial = (dirterritorial != 'OTRO') ? dirterritorial?.toUpperCase() : dirterritorial;
  filtros += " DIR_TERRITORIAL = '$dirterritorial'";
  primerFiltro = false;
}

if(gerentecanal){
  filtros += primerFiltro ? ' WHERE':' AND';
  filtros += " TRIM(GERENTE_CANAL) = '$gerentecanal'";
  primerFiltro = false;
}

if(producto){
  filtros += primerFiltro ? ' WHERE':' AND';
  producto = producto?.split('-')?.getAt(0);
  filtros += " pco.IDPRODUCT = '$producto' ";
  primerFiltro = false;
}

if(date){
  filtros += primerFiltro ? ' WHERE':' AND';
  filtros += """ TO_DATE('$date', 'yyyy-MM-dd') > pco.EFFECTIVESTARTDATE 
				 AND TO_DATE('$date', 'yyyy-MM-dd') < pco.EFFECTIVEENDDATE""";
  primerFiltro = false;
}
logger.debug('MEDIADOR ' + mediador?.toString())
if(filtros == '' && !mediador){
  resp.alert.error("Debes introducir al menos un filtro");
  return;
}

if(departamento != 'CENTRAL CESCE'){
  logger.info('filtros CENTRAL_CESCE: ' + filtros)
  filtros += / AND DIR_TERRITORIAL = '$departamento'/
  
  if(userType == 'gerente_canal'){
    filtros += / AND UPPER(TRIM(GERENTE_CANAL)) LIKE '%$userName%'/
  }
  
} 

if(departamento == 'CENTRAL CESCE' && userType == 'perfil_consulta_espana'){

    //filtros += / AND mom.DIR_TERRITORIAL = '$departamento'/
    filtros += / AND mom.DIR_TERRITORIAL IN ('DT CENTRO','DT NORTE','DT SUR','DT CATALUÑA-BALEARES','DT LEVANTE','DT NOROESTE')/

    if(userType == 'gerente_canal'){
      filtros += / AND UPPER(mom.GERENTE_CANAL) LIKE '%$userName%'/
    }

  }


def lim = 1000;
def offset = 0;
  
def queryselect = """SELECT pco.POSITIONNAME, 
					 CONCAT(CONCAT_NAZ(NOMBRE, ' '),"APELLIDO/RAZON_SOCIAL") as NOMBRE_MEDIADOR,
					 mom.NUM_IDENTIFICACION, 
					 mom.DIR_TERRITORIAL, 
					 mom.GERENTE_CANAL, 
					 mom.BUSINESSUNIT,
					 pco.RAMO, 
					 pco.IDPRODUCT as IDPRODUCTO, 
					 pco.PRODUCTNAME,
					 pco.EFFECTIVESTARTDATE,
					 pco.EFFECTIVEENDDATE,
					 pco.P_EMISION, 
					 pco.P_RENOVACION
					 FROM EXT.MODIFICAR_MEDIADOR mom 
					 INNER JOIN EXT.PLAN_COMISIONAMIENTO pco 
					 ON pco.POSITIONNAME = CONCAT(CONCAT(mom.COD_MEDIADOR, '-'), mom.SUBCLAVE) 
 					 $filtros 
					 ORDER BY pco.POSITIONNAME, pco.RAMO DESC """
  
def countQuery = "SELECT COUNT(*) FROM ($queryselect)"
logger.debug("countQuery" + countQuery)
logger.info('queryselect: ' + queryselect)

def count = db.queryForList(countQuery)?.getAt(0)?.values()?.getAt(0);
logger.debug("", db.queryForList(countQuery))  
logger.debug('count' + count)

def limit = count > 58000 ? 58000 : count;

def results = [];

while(offset < limit){
    
  if(offset + 1000 > limit){
    lim = offset - limit + 1000;
    logger.debug(lim);
    logger.debug(queryselect);
  }
  
  def resultsBucle = db.queryForList(queryselect + "LIMIT $lim OFFSET $offset");

  for(def row:resultsBucle){
    results.add(row);    
  }
    
  offset += 1000;
  logger.debug('offset' + offset);
}

def list = []
  
results?.each{
    
  Map elementMap = new java.util.HashMap()

  elementMap.put("POSITIONNAME", it.POSITIONNAME);
  elementMap.put("NOMBRE_MEDIADOR", it.NOMBRE_MEDIADOR);
  elementMap.put("NUM_IDENTIFICACION", it.NUM_IDENTIFICACION);
  elementMap.put("DIR_TERRITORIAL", it.DIR_TERRITORIAL);
  elementMap.put("GERENTE_CANAL", it.GERENTE_CANAL);
  elementMap.put("BUSINESSUNIT", it.BUSINESSUNIT);
  elementMap.put("RAMO", it.RAMO);
  elementMap.put("IDPRODUCT", it.IDPRODUCTO);
  elementMap.put("PRODUCTNAME", it.PRODUCTNAME);
  elementMap.put("P_EMISION", it.P_EMISION);
  elementMap.put("P_RENOVACION", it.P_RENOVACION);
    
  def fechaInicio = it.EFFECTIVESTARTDATE.toString().split('-').reverse().join('/');
  elementMap.put("EFFECTIVESTARTDATE", fechaInicio);

  logger.info(it.EFFECTIVEENDDATE)
  def fechaFin = it.EFFECTIVEENDDATE.toString().split('-').reverse().join('/');
  elementMap.put("EFFECTIVEENDDATE", (fechaFin?:''));

  logger.info(it);

  list.add(elementMap);
}
  
form.getTableController('tabla_cuadro_comisiones').setSource(list);
form.refreshElement('tabla_cuadro_comisiones');

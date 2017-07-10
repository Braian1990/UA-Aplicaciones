SELECT NVL(DECODE(is_numeric(acr.attribute13),
                  0, REPLACE(SUBSTR(acr.attribute13,1, INSTR(acr.attribute13, '-', 1)-1),' ', ''),
                  acr.attribute13), 
           flv.attribute7) ||';'|| --nro_comercio,
       flv.attribute3 ||';'|| --tipo_tarjeta,
       flv.attribute4 ||';'|| --emisor,
       acr.attribute9 ||';'|| --tarjeta,
       TO_CHAR(acr.receipt_date,'YYYYMMDD') ||';'|| --fecha_autorizacion,
       acr.attribute11 ||';'|| --cod_autorizacion,
       REPLACE(acr.amount,',','.') ||';'|| -- monto,
       acr.currency_code ||';'|| --moneda,
       acr.attribute10 ||';'|| --cuotas,
       acr.cash_receipt_id linea --id recibo
FROM ar_cash_receipts acr,
     ar_cash_receipt_history acrh,
     ar_receipt_methods arm,
     fnd_lookup_values_vl flv
WHERE flv.tag IS NOT NULL  -- metodo de cobro mapeado para presentacion
AND flv.lookup_type = 'XX_METODOS_COBRO'
AND arm.attribute13 = flv.lookup_code  
AND acr.receipt_method_id = arm.receipt_method_id
AND acr.attribute12 IS NULL --estado presentacion: Si está vacio no se presentó para conciliar
AND acr.receipt_date >= TO_DATE('01/12/2016', 'DD/MM/YYYY')  -- fecha inicio conciliacion de cupones
AND acr.receipt_date <= SYSDATE
AND acrh.status = 'REMITTED' -- solo selecciona los recibos con el estado REMITIDO
AND acrh.current_record_flag = 'Y'
AND acr.cash_receipt_id = acrh.cash_receipt_id;


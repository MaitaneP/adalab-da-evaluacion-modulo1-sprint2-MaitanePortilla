#  EJERCICIOS 2ª EVALUACIÓN SQL. MÓDULO 1 - SPRINT 2
-- --------------------------------------------------
/* Para esta evaluación usaremos la BBDD de northwind con la que ya estamos familiarizadas de los ejercicios de pair programming. 
En esta evaluación tendréis que contestar a las siguientes preguntas: */

USE northwind;

/* 1. Selecciona todos los campos de los productos, que pertenezcan a los proveedores con códigos: 1, 3, 7, 8 y 9, que tengan stock en 
	  el almacén, y al mismo tiempo que sus precios unitarios estén entre 50 y 100. Por último, ordena los resultados por código de proveedor 
	  de forma ascendente.*/

SELECT * 
	FROM products
    WHERE supplier_id IN (1, 3, 7, 8, 9)
			AND units_in_stock IS NOT NULL
            AND unit_price BETWEEN 50 AND 100
	ORDER BY supplier_id;

-- Los únicos productos que cumplen las 3 condiciones son 'Carnarvon Tigers' (ID producto = 18) y 'Sir Rodney's Marmalade' (ID producto = 20).
              
              
/* 2. Devuelve el nombre y apellidos y el id de los empleados con códigos entre el 3 y el 6, además que hayan vendido a clientes que tengan 
	  códigos que comiencen con las letras de la A hasta la G. Por último, en esta búsqueda queremos filtrar solo por aquellos envíos que la 
	  fecha de pedido este comprendida entre el 22 y el 31 de Diciembre de cualquier año.*/

SELECT DISTINCT first_name, last_name, employee_id # DISTINCT elimina los duplicados (procedentes de distindos pedidos que cumplen las condiciones)
	FROM employees
    NATURAL JOIN orders
    WHERE employee_id BETWEEN 3 AND 6
			AND customer_id REGEXP '^[A-G].*' 
            AND order_date IN (SELECT order_date
									FROM orders
									WHERE MONTH(order_date) = 12 AND (DAY(order_date) BETWEEN 22 AND 31));
                                    
-- Los empleados que cumplen las 3 condiciones son Janet Leverling (ID empleado = 3), Margaret Peacock (ID empleado = 4) y Michael Suyama (ID empleado = 6).


/* 3. Calcula el precio de venta de cada pedido una vez aplicado el descuento. Muestra el id del la orden, el id del producto, el nombre del 
	  producto, el precio unitario, la cantidad, el descuento y el precio de venta después de haber aplicado el descuento.*/

-- A continuación se presentan las columnas solicitadas con el precio de venta total de cada producto en cada pedido, una vez aplicado el descuento.
-- Se muestran los resultados ordenados en orden ascendente de número de pedido y número de producto para facilitar la lectura.
SELECT order_details.order_id, order_details.product_id, products.product_name, order_details.unit_price, order_details.quantity, 
		order_details.discount, ROUND((order_details.unit_price * order_details.quantity * (1 - order_details.discount)), 2) AS PrecioTotalProductoPedido
	FROM order_details
	INNER JOIN products
    USING (product_id)
    ORDER BY order_details.order_id, order_details.product_id;
      
-- Si se desea saber el precio de venta final (una vez aplicado el descuento) para cada pedido completo el resultado se obtendría con la siguiente query, 
-- pero al dar valores totales por pedido no es posible mostrar las columnas correspondientes a cada producto de cada pedido:
SELECT order_details.order_id, ROUND(SUM((order_details.unit_price * order_details.quantity * (1 - order_details.discount))), 2) AS PrecioTotalVentaPedido
	FROM order_details
	INNER JOIN products
    USING (product_id)
    GROUP BY order_details.order_id;


/* 4. Usando una subconsulta, muestra los productos cuyos precios estén por encima del precio medio total de los productos de la BBDD.*/

SELECT *
	FROM products
    WHERE unit_price > (SELECT ROUND(AVG(unit_price), 2)
							FROM products);


/* 5. ¿Qué productos ha vendido cada empleado y cuál es la cantidad vendida de cada uno de ellos?*/

SELECT orders.employee_id, employees.first_name, employees.last_name, order_details.product_id, products.product_name, SUM(order_details.quantity) AS CantidadTotalVendedorProducto
	FROM order_details
	INNER JOIN products
    USING (product_id)
    INNER JOIN orders
    USING (order_id)
    INNER JOIN employees
    USING (employee_id)
    GROUP BY orders.employee_id, order_details.product_id;


/* 6. Basándonos en la query anterior, ¿qué empleado es el que vende más productos? Soluciona este ejercicio con una subquery*/

SELECT orders.employee_id, employees.first_name, employees.last_name, SUM(order_details.quantity) AS CantidadMejorVendedor
	FROM order_details
	INNER JOIN orders
    USING (order_id)
    INNER JOIN employees
    USING (employee_id)
    GROUP BY orders.employee_id
    HAVING SUM(order_details.quantity) >= ALL (SELECT SUM(order_details.quantity) AS CantidadTotalVendedor
													FROM order_details 
													INNER JOIN orders
													USING (order_id)
													GROUP BY orders.employee_id);

-- La empleada que vende más productos en total es Margaret Peacock (ID empleada = 4) con un total de 9798 productos vendidos.


/* 7. BONUS ¿Podríais solucionar este mismo ejercicio con una CTE?*/
  
WITH CantidadTotalVendedor
  AS (SELECT employee_id, SUM(order_details.quantity) AS CantVendedor
			FROM order_details 
			INNER JOIN orders
			USING (order_id)
			GROUP BY orders.employee_id)    
SELECT e.employee_id, e.first_name, e.last_name, q.CantVendedor AS CantidadMejorVendedor
	FROM employees AS e, CantidadTotalVendedor AS q
    WHERE e.employee_id = q.employee_id
    ORDER BY CantidadMejorVendedor DESC
    LIMIT 1;
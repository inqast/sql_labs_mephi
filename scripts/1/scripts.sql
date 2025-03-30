/* Найдите производителей (maker) и модели всех мотоциклов,
   которые имеют мощность более 150 лошадиных сил,
   стоят менее 20 тысяч долларов и являются спортивными (тип Sport).
   Также отсортируйте результаты по мощности в порядке убывания.
 */

SELECT v.maker, m.model
FROM motorcycle m
LEFT JOIN vehicle v USING (model)
WHERE m.horsepower > 150 AND m.price < 20000 AND m.type = 'Sport'
ORDER BY m.horsepower DESC;

/* Извлечь данные о всех автомобилях, которые имеют:
   - Мощность двигателя более 150 лошадиных сил.
   - Объем двигателя менее 3 литров.
   - Цену менее 35 тысяч долларов.
   В выводе должны быть указаны
   - производитель (maker),
   - номер модели (model),
   - мощность (horsepower),
   - объем двигателя (engine_capacity),
   - тип транспортного средства, который будет обозначен как Car.
 */
WITH cars AS (
    SELECT v.maker, c.model, c.horsepower, c.engine_capacity, 'Car' as vehicle_type
    FROM car c LEFT JOIN vehicle v USING (model)
    WHERE c.horsepower > 150 AND c.engine_capacity < 3 AND c.price < 35000
),
/* Извлечь данные о всех мотоциклах, которые имеют:
   - Мощность двигателя более 150 лошадиных сил.
   - Объем двигателя менее 1,5 литров.
   - Цену менее 20 тысяч долларов.
   В выводе должны быть указаны
   - производитель (maker)
   - номер модели (model)
   - мощность (horsepower)
   - объем двигателя (engine_capacity)
   - тип транспортного средства, который будет обозначен как Motorcycle.
 */
motos AS (
    SELECT v.maker, m.model, m.horsepower, m.engine_capacity, 'Motorcycle' as vehicle_type
    FROM motorcycle m LEFT JOIN vehicle v USING (model)
    WHERE m.horsepower > 150 AND m.engine_capacity < 1.5 AND m.price < 20000
),
/* Извлечь данные обо всех велосипедах, которые имеют:
   - Количество передач больше 18.
   - Цену менее 4 тысяч долларов.
   В выводе должны быть указаны
   - производитель (maker)
   - номер модели (model)
   - а также NULL для мощности и объема двигателя так как эти характеристики не применимы для велосипедов.
   - Тип транспортного средства будет обозначен как Bicycle.
 */
bikes AS (
     SELECT v.maker, b.model, 'Bicycle' as vehicle_type
     FROM bicycle b LEFT JOIN vehicle v USING (model)
     WHERE b.gear_count > 18 AND b.price < 4000
)
/* Результаты должны быть объединены в один набор данных
   отсортированы по мощности в порядке убывания.
   Для велосипедов, у которых нет значения мощности, они будут располагаться внизу списка.
 */
SELECT maker, model, horsepower, engine_capacity, vehicle_type FROM cars
UNION ALL
SELECT maker, model, horsepower, engine_capacity, vehicle_type FROM motos
UNION ALL
SELECT maker, model, null, null, vehicle_type FROM bikes
ORDER BY horsepower DESC NULLS LAST;
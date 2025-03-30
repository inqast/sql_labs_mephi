/* Определить, какие автомобили из каждого класса имеют наименьшую среднюю позицию в гонках
   вывести информацию о каждом таком автомобиле для данного класса, включая:
   - его класс,
   - среднюю позицию
   - количество гонок, в которых он участвовал.
   Также отсортировать результаты по средней позиции.
 */
-- Аггрегируем нужные для ранжирования данные и ранжируем
WITH avg_positions_with_races AS (
    SELECT
        r.car AS car_name,
        c.class AS car_class,
        AVG(r.position) AS average_position,
        COUNT(*) AS race_count,
        ROW_NUMBER() OVER (PARTITION BY c.class ORDER BY AVG(r.position)) AS pos
    FROM results r LEFT JOIN cars c on c.name = r.car
    GROUP BY r.car, c.class
),
-- Выбираем лучших
top_positions AS (
    SELECT car_name, car_class, average_position, race_count
    FROM avg_positions_with_races
    WHERE pos = 1
    ORDER BY average_position ASC
)
SELECT *
FROM top_positions;

/* Определить автомобиль, который имеет наименьшую среднюю позицию в гонках среди всех автомобилей
   вывести информацию об этом автомобиле,
   - включая его класс,
   - среднюю позицию,
   - количество гонок, в которых он участвовал,
   - страну производства класса автомобиля.
   (Тут похоже ошибка в условии либо в схеме данных - так как страна есть у класса,
   но в классе могут быть разные производители из разных стран)
   Если несколько автомобилей имеют одинаковую наименьшую среднюю позицию,
   выбрать один из них по алфавиту (по имени автомобиля).
 */
-- Агрегируем данные
with cars_top AS (
    SELECT
        c.name AS car_name,
        AVG(r.position) AS average_position,
        COUNT(*) AS race_count
    FROM results r
        LEFT JOIN cars c on r.car = c.name
    GROUP BY c.name
),
-- Выбираем победителя
top_car as (
    SELECT *
    FROM cars_top
    ORDER BY average_position, car_name ASC
    LIMIT 1
)
SELECT tc.car_name,
       cl.class AS car_class,
       tc.average_position,
       tc.race_count,
       cl.country AS car_country
FROM top_car tc
    JOIN cars c on tc.car_name = c.name
    JOIN classes cl USING (class);

/* Определить классы автомобилей, которые имеют наименьшую среднюю позицию в гонках,
   вывести информацию о каждом автомобиле из этих классов, включая:
   - его имя,
   - среднюю позицию,
   - количество гонок, в которых он участвовал,
   - страну производства класса автомобиля,
   - а также общее количество гонок, в которых участвовали автомобили этих классов.
   Если несколько классов имеют одинаковую среднюю позицию, выбрать все из них.
 */
-- Агрегируем данные по классам
with class_top AS (
    SELECT
        c.class AS class_name,
        AVG(r.position) AS average_position,
        COUNT(*) AS race_count,
        DENSE_RANK() over (ORDER BY AVG(r.position)) AS rank
    FROM results r
             LEFT JOIN cars c on r.car = c.name
    GROUP BY c.class
),
-- Считаем гонки каждой машины
car_races AS (
    SELECT r.car, COUNT(*) AS count
    FROM results r
    GROUP BY r.car
),
-- Выбираем победителей
 top_classes as (
     SELECT *
     FROM class_top
     WHERE rank = 1
 )
SELECT
    c.name,
    cl.class AS car_class,
    tc.average_position,
    car_races.count AS race_count,
    cl.country AS car_country,
    tc.race_count AS total_races
FROM top_classes tc
    JOIN cars c ON tc.class_name = c.class
    JOIN car_races ON car_races.car = c.name
    JOIN classes cl USING (class);


/* Определить, какие автомобили имеют среднюю позицию
   лучше (меньше) средней позиции всех автомобилей в своем классе
   (то есть автомобилей в классе должно быть минимум два, чтобы выбрать один из них).
   Вывести информацию об этих автомобилях, включая их
   - имя,
   - класс,
   - среднюю позицию,
   - количество гонок, в которых они участвовали,
   - страну производства класса автомобиля.
   Также отсортировать результаты по классу и затем по средней позиции в порядке возрастания.
 */
-- Агрегируем данные по классам
with class_avg AS (
    SELECT
        c.class AS class_name,
        AVG(r.position) AS average_position,
        COUNT(DISTINCT car) AS cars_count
    FROM results r
             LEFT JOIN cars c on r.car = c.name
    GROUP BY c.class
    HAVING COUNT(DISTINCT car) > 1
),
-- Агрегируем данные по машинам
 cars_avg AS (
     SELECT
         c.name AS car_name,
         AVG(r.position) AS average_position,
         COUNT(*) AS race_count
     FROM results r
              LEFT JOIN cars c on r.car = c.name
     GROUP BY c.name
 ),
-- Выбираем победителей
     top_cars as (
         SELECT c.name, class_avg.class_name, cars_avg.average_position, cars_avg.race_count
         FROM class_avg
                  JOIN cars c on class_avg.class_name = c.class
                  JOIN cars_avg on cars_avg.car_name = c.name
         WHERE cars_avg.average_position < class_avg.average_position
     )
SELECT c.name,
       cl.class AS car_class,
       tc.average_position,
       tc.race_count,
       cl.country AS car_country
FROM top_cars tc
         JOIN cars c on tc.name = c.name
         JOIN classes cl USING (class);


/* Какое то очень кривое условие, которое еще и не сходится с ожидаемыми данными -
   интерпретирую его так, что вывести нужно инфо о каждом авто-лузере в классе.

   Определить, какие классы автомобилей имеют
   наибольшее количество автомобилей с низкой средней позицией (больше 3.0) (так больше или меньше?)
   вывести информацию о каждом автомобиле из этих классов, включая его
   - имя,
   - класс,
   - среднюю позицию,
   - количество гонок, в которых он участвовал,
   - страну производства класса автомобиля,
   - общее количество гонок для каждого класса.
   Отсортировать результаты по количеству автомобилей с низкой средней позицией.
 */
-- Агрегируем данные по неудачникам
with losers AS (
         SELECT
             c.name AS car_name,
             c.class AS car_class,
             AVG(r.position) AS average_position,
             COUNT(*) AS race_count
         FROM results r
                  LEFT JOIN cars c on r.car = c.name
         GROUP BY c.name, c.class
         HAVING AVG(r.position) > 3
),
-- Подчитаем количество гонок в классе
class_count AS (
    SELECT c.class    AS class_name,
           COUNT(car) AS cars_count
    FROM results r
             LEFT JOIN cars c on r.car = c.name
    GROUP BY c.class
),
-- Подчитаем количество неудачников в классе
losers_in_class AS (
    SELECT car_class, COUNT(*) as count
    FROM losers
    GROUP BY car_class
)
SELECT
    l.car_name,
    l.car_class,
    l.average_position,
    l.race_count,
    c.country AS car_country,
    cc.cars_count AS total_races,
    cl.count AS low_position_count
FROM losers l
LEFT JOIN class_count cc on l.car_class = cc.class_name
LEFT JOIN losers_in_class cl on l.car_class = cl.car_class
LEFT JOIN classes c on c.class = l.car_class
ORDER BY low_position_count;
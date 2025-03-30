/*
 Определить, какие клиенты сделали более двух бронирований в разных отелях,
 и вывести информацию о каждом таком клиенте, включая
 - его имя,
 - электронную почту,
 - телефон,
 - общее количество бронирований,
 - а также список отелей, в которых они бронировали номера (объединенные в одно поле через запятую с помощью CONCAT).
 - Также подсчитать среднюю длительность их пребывания (в днях) по всем бронированиям.
 Отсортировать результаты по количеству бронирований в порядке убывания.
 */
 SELECT
     c.name,
     c.phone,
     c.email,
     COUNT(*) AS booking_count,
     STRING_AGG(DISTINCT h.name, ', '),
     AVG(b.check_out_date - b.check_in_date) as avg_stay
 FROM booking b
 LEFT JOIN room r on r.id_room = b.id_room
 LEFT JOIN hotel h on h.id_hotel = r.id_hotel
 LEFT JOIN customer c on b.id_customer = c.id_customer
 GROUP BY c.name, c.phone, c.email
 HAVING COUNT(DISTINCT r.id_hotel) > 1 AND COUNT(b.id_booking) > 2
 ORDER BY booking_count DESC;

/*
    Необходимо провести анализ клиентов,
    которые сделали более двух бронирований в разных отелях
    и потратили более 500 долларов на свои бронирования.

 Вывести для каждого такого клиента следующие данные:
 - ID_customer,
 - имя,
 - общее количество бронирований,
 - общее количество уникальных отелей, в которых они бронировали номера,
 - общую сумму, потраченную на бронирования.
 Результаты отсортировать по общей сумме, потраченной клиентами, в порядке возрастания.
 */
SELECT
    c.id_customer,
    c.name,
    COUNT(DISTINCT r.id_hotel) AS unique_hotels,
    -- В ожидаемом результате не учитывается, что оплатить придется все ночи, в схеме указано что в price цена за одну.
    -- Так что ответ не сойдется с ожидаемым, но будет верным
    SUM(r.price * (b.check_out_date - b.check_in_date)) as total_spent,
    COUNT(*) AS total_bookings
    FROM booking b
         LEFT JOIN room r on r.id_room = b.id_room
         LEFT JOIN hotel h on h.id_hotel = r.id_hotel
         LEFT JOIN customer c on b.id_customer = c.id_customer
GROUP BY c.id_customer, c.name
HAVING
    COUNT(DISTINCT r.id_hotel) > 1 AND
    COUNT(b.id_booking) > 2 AND
    SUM(r.price * (b.check_out_date - b.check_in_date)) > 500
ORDER BY total_spent;

/*
 Определите категорию каждого отеля на основе средней стоимости номера:
 - «Дешевый»: средняя стоимость менее 175 долларов.
 - «Средний»: средняя стоимость от 175 до 300 долларов.
 - «Дорогой»: средняя стоимость более 300 долларов.

 Для каждого клиента определите предпочитаемый тип отеля на основании условия ниже:
 - Если у клиента есть хотя бы один «дорогой» отель, присвойте ему категорию «дорогой».
 - Если у клиента нет «дорогих» отелей, но есть хотя бы один «средний», присвойте ему категорию «средний».
 - Если у клиента нет «дорогих» и «средних» отелей, но есть «дешевые», присвойте ему категорию предпочитаемых отелей «дешевый».

 Выведите для каждого клиента следующую информацию:
 - ID_customer: уникальный идентификатор клиента.
 - name: имя клиента.
 - preferred_hotel_type: предпочитаемый тип отеля.
 - visited_hotels: список уникальных отелей, которые посетил клиент

 Отсортируйте клиентов так, чтобы сначала шли клиенты с «дешевыми» отелями, затем со «средними» и в конце — с «дорогими».
 */
-- Подсчитаем среднюю цену по отелям.
WITH hotel_avg_price AS (
    SELECT
        h.id_hotel,
        AVG(r.price) AS avg_price
    FROM hotel h
    LEFT JOIN room r USING (id_hotel)
    GROUP BY h.id_hotel
-- Собираем сырой результат
), visited_hotels AS (
    SELECT
        b.id_customer,
        STRING_AGG(DISTINCT h.name, ', ') AS visited_hotels,
        MAX(p.avg_price) AS most_expansive_hotel
    FROM booking b
    LEFT JOIN public.room r USING (id_room)
    LEFT JOIN hotel h USING (id_hotel)
    LEFT JOIN hotel_avg_price p USING (id_hotel)
    GROUP BY b.id_customer
)
-- Подставляем категории
SELECT
    c.id_customer,
    c.name,
    CASE
        WHEN h.most_expansive_hotel < 175 THEN 'Дешевый'
        WHEN h.most_expansive_hotel < 300 THEN 'Средний'
        ELSE 'Дорогой'
    END AS category,
    h.visited_hotels
FROM visited_hotels h
    LEFT JOIN customer c USING (id_customer)
ORDER BY h.most_expansive_hotel ASC;



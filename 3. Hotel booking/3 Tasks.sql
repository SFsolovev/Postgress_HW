--Задача 1
--Определить, какие клиенты сделали более двух бронирований в разных отелях, и вывести информацию о каждом таком клиенте, 
--включая его имя, электронную почту, телефон, общее количество бронирований, а также список отелей, 
--в которых они бронировали номера (объединенные в одно поле через запятую). 
--Также подсчитать среднюю длительность их пребывания (в днях) по всем бронированиям. 
--Отсортировать результаты по количеству бронирований в порядке убывания.
--Решение задачи должно представлять из себя один SQL-запрос.
--Ожидаемый вывод для тестовых данных
--Bob Brown	bob.brown@example.com	+2233445566	3	Grand Hotel, Ocean View Resort	3.0000
--Ethan Hunt	ethan.hunt@example.com	+5566778899	3	Mountain Retreat, Ocean View Resort	3.0000

SELECT c.name, c.email, c.phone,
       COUNT(b.ID_booking) AS total_bookings,
       STRING_AGG(DISTINCT h.name, ', ') AS hotels,
       ROUND(AVG(b.check_out_date - b.check_in_date), 4) AS avg_stay_days
  FROM Customer c
       JOIN Booking b ON c.ID_customer = b.ID_customer
       JOIN Room r    ON b.ID_room     = r.ID_room
       JOIN Hotel h   ON r.ID_hotel    = h.ID_hotel
 GROUP BY c.ID_customer, c.name, c.email, c.phone
HAVING COUNT(b.ID_booking) > 2 AND COUNT(DISTINCT h.ID_hotel) > 1
ORDER BY total_bookings DESC;

--Задача 2
--Необходимо провести анализ клиентов, которые сделали более двух бронирований в разных отелях 
--и потратили более 500 долларов на свои бронирования. Для этого:
--Определить клиентов, которые сделали более двух бронирований и забронировали номера в более чем одном отеле. Вывести для каждого такого клиента следующие данные: ID_customer, имя, общее количество бронирований, общее количество уникальных отелей, в которых они бронировали номера, и общую сумму, потраченную на бронирования.
--Также определить клиентов, которые потратили более 500 долларов на бронирования, и вывести для них ID_customer, имя, общую сумму, потраченную на бронирования, и общее количество бронирований.
--В результате объединить данные из первых двух пунктов, чтобы получить список клиентов, которые соответствуют условиям обоих запросов. Отобразить поля: ID_customer, имя, общее количество бронирований, общую сумму, потраченную на бронирования, и общее количество уникальных отелей.
--Результаты отсортировать по общей сумме, потраченной клиентами, в порядке возрастания.
--Решение задачи должно представлять из себя один SQL-запрос.
--Ожидаемый вывод для тестовых данных
--ID_customer	name	total_bookings	total_spent	unique_hotels
--4	Bob Brown	3	820.00	2
--7	Ethan Hunt	3	850.00	2

SELECT t.ID_customer, t.name, t.total_bookings, t.total_spent, t.unique_hotels
  FROM (SELECT c.ID_customer, c.name,
               COUNT(b.ID_booking) AS total_bookings,
               COUNT(DISTINCT h.ID_hotel) AS unique_hotels,
               SUM((b.check_out_date - b.check_in_date) * r.price) AS total_spent
          FROM Customer c
               JOIN Booking b ON c.ID_customer = b.ID_customer
               JOIN Room r    ON b.ID_room     = r.ID_room
               JOIN Hotel h   ON r.ID_hotel    = h.ID_hotel
         GROUP BY c.ID_customer, c.name) t
 WHERE t.total_bookings > 2
   AND t.unique_hotels  > 1
   AND t.total_spent    > 500
 ORDER BY t.total_spent;

--Задача 3
--Вам необходимо провести анализ данных о бронированиях в отелях и определить предпочтения клиентов по типу отелей. 
--Для этого выполните следующие шаги:
--Категоризация отелей.
--Определите категорию каждого отеля на основе средней стоимости номера:
--«Дешевый»: средняя стоимость менее 175 долларов.
--«Средний»: средняя стоимость от 175 до 300 долларов.
--«Дорогой»: средняя стоимость более 300 долларов.
--Анализ предпочтений клиентов.
--Для каждого клиента определите предпочитаемый тип отеля на основании условия ниже:
--Если у клиента есть хотя бы один «дорогой» отель, присвойте ему категорию «дорогой».
--Если у клиента нет «дорогих» отелей, но есть хотя бы один «средний», присвойте ему категорию «средний».
--Если у клиента нет «дорогих» и «средних» отелей, но есть «дешевые», присвойте ему категорию предпочитаемых отелей «дешевый».
--Вывод информации.
--Выведите для каждого клиента следующую информацию:
--ID_customer: уникальный идентификатор клиента.
--name: имя клиента.
--preferred_hotel_type: предпочитаемый тип отеля.
--visited_hotels: список уникальных отелей, которые посетил клиент.
--Сортировка результатов.
--Отсортируйте клиентов так, чтобы сначала шли клиенты с «дешевыми» отелями, затем со «средними» и в конце — с «дорогими».
--Решение задачи должно представлять из себя один SQL-запрос.
--Ожидаемый вывод для тестовых данных
--ID_customer	name	preferred_hotel_type	visited_hotels
--10	Hannah Montana	Дешевый	City Center Inn
--1	John Doe	Средний	City Center Inn,Grand Hotel
--2	Jane Smith	Средний	Grand Hotel
--3	Alice Johnson	Средний	Grand Hotel
--4	Bob Brown	Средний	Grand Hotel,Ocean View Resort
--5	Charlie White	Средний	Ocean View Resort
--6	Diana Prince	Средний	Ocean View Resort
--7	Ethan Hunt	Дорогой	Mountain Retreat,Ocean View Resort
--8	Fiona Apple	Дорогой	Mountain Retreat
--9	George Washington	Дорогой	City Center Inn,Mountain Retreat

SELECT c.ID_customer, c.name,
       CASE
       WHEN MAX(CASE
                WHEN hotel_avg.avg_price > 300               THEN 3
                WHEN hotel_avg.avg_price BETWEEN 175 AND 300 THEN 2
                ELSE 1
                END) = 3 THEN 'Дорогой'
       WHEN MAX(CASE
                WHEN hotel_avg.avg_price > 300               THEN 3
                WHEN hotel_avg.avg_price BETWEEN 175 AND 300 THEN 2
                ELSE 1
                END) = 2 THEN 'Средний'
       ELSE 'Дешевый'
       END AS preferred_hotel_type,
       STRING_AGG(DISTINCT h.name, ',') AS visited_hotels
  FROM Customer c
       JOIN Booking b ON c.ID_customer = b.ID_customer
       JOIN Room r    ON b.ID_room     = r.ID_room
       JOIN Hotel h   ON r.ID_hotel    = h.ID_hotel
       JOIN (SELECT h.ID_hotel, AVG(r.price) AS avg_price
               FROM Hotel h
                    JOIN Room r ON h.ID_hotel = r.ID_hotel
              GROUP BY h.ID_hotel) hotel_avg ON h.ID_hotel = hotel_avg.ID_hotel
GROUP BY c.ID_customer, c.name
ORDER BY CASE
         WHEN MAX(CASE
                  WHEN hotel_avg.avg_price > 300               THEN 3
                  WHEN hotel_avg.avg_price BETWEEN 175 AND 300 THEN 2
                  ELSE 1
                  END) = 1 THEN 1
         WHEN MAX(CASE
                  WHEN hotel_avg.avg_price > 300               THEN 3
                  WHEN hotel_avg.avg_price BETWEEN 175 AND 300 THEN 2
                  ELSE 1
                  END) = 2 THEN 2
         ELSE 3
         END;

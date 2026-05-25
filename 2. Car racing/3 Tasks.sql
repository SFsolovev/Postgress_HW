--Задача 1
--Определить, какие автомобили из каждого класса имеют наименьшую среднюю позицию в гонках, 
--и вывести информацию о каждом таком автомобиле для данного класса, включая его класс, 
--среднюю позицию и количество гонок, в которых он участвовал.
--Также отсортировать результаты по средней позиции.
--Решение задачи должно представлять из себя один SQL-запрос.
--Ожидаемый вывод для тестовых данных
--car_name	car_class	average_position	race_count
--Ferrari 488	Convertible	1.0000	1
--Ford Mustang	SportsCar	1.0000	1
--Toyota RAV4	SUV	2.0000	1
--Mercedes-Benz S-Class	Luxury Sedan	2.0000	1
--BMW 3 Series	Sedan	3.0000	1
--Chevrolet Camaro	Coupe	4.0000	1
--Renault Clio	Hatchback	5.0000	1
-- Ford F-150	Pickup	6.0000	1

SELECT t.car_name, t.car_class, ROUND(t.average_position, 4) AS average_position, t.race_count
  FROM (SELECT c.name  AS car_name,
               c.class AS car_class,
               AVG(r.position::DECIMAL) AS average_position,
               COUNT(*) AS race_count,
               RANK() OVER (PARTITION BY c.class ORDER BY AVG(r.position::DECIMAL)) AS rank_in_class
          FROM Cars c
               JOIN Results r ON c.name = r.car
         GROUP BY c.name, c.class) t
 WHERE t.rank_in_class = 1
 ORDER BY t.average_position;

--Задача 2
--Определить автомобиль, который имеет наименьшую среднюю позицию в гонках среди всех автомобилей, 
--и вывести информацию об этом автомобиле, включая его класс, среднюю позицию, 
--количество гонок, в которых он участвовал, и страну производства класса автомобиля. 
--Если несколько автомобилей имеют одинаковую наименьшую среднюю позицию, выбрать один из них по алфавиту (по имени автомобиля).
--Решение задачи должно представлять из себя один SQL-запрос.
--Ожидаемый вывод для тестовых данных
--car_name	car_class	average_position	race_count	car_country
--Ferrari 488	Convertible	1.0000	1	Italy

SELECT c.name  AS car_name,
       c.class AS car_class,
       ROUND(AVG(r.position::DECIMAL), 4) AS average_position,
       COUNT(*)   AS race_count,
       cl.country AS car_country
  FROM Cars c
       JOIN Results r ON c.name = r.car
       JOIN Classes cl ON c.class = cl.class
 GROUP BY c.name, c.class, cl.country
 ORDER BY AVG(r.position::DECIMAL), c.name
 LIMIT 1;

--Задача 3
--Определить классы автомобилей, которые имеют наименьшую среднюю позицию в гонках, 
--и вывести информацию о каждом автомобиле из этих классов, включая его имя, среднюю позицию, 
--количество гонок, в которых он участвовал, страну производства класса автомобиля, 
--а также общее количество гонок, в которых участвовали автомобили этих классов. 
--Если несколько классов имеют одинаковую среднюю позицию, выбрать все из них.
--Решение задачи должно представлять из себя один SQL-запрос.
--Ожидаемый вывод для тестовых данных
--car_name	car_class	average_position	race_count	car_country	total_races
--Ferrari 488	Convertible	1.0000	1	Italy	1
--Ford Mustang	SportsCar	1.0000	1	USA	1

SELECT c.name  AS car_name,
       c.class AS car_class,
       ROUND(AVG(r.position::DECIMAL), 4) AS average_position,
       COUNT(*)   AS race_count,
       cl.country AS car_country,
       (SELECT COUNT(*) FROM Cars c2 JOIN Results r2 ON c2.name = r2.car WHERE c2.class = c.class) AS total_races
  FROM Cars c
       JOIN Results r  ON c.name  = r.car
       JOIN Classes cl ON c.class = cl.class
 WHERE c.class IN (SELECT class_avg.car_class
                     FROM (SELECT c3.class AS car_class, AVG(r3.position::DECIMAL) AS avg_position
                             FROM Cars c3
                                  JOIN Results r3 ON c3.name = r3.car
                            GROUP BY c3.class) class_avg
                    WHERE class_avg.avg_position = (SELECT MIN(t.avg_position)
                                                      FROM (SELECT c4.class, AVG(r4.position::DECIMAL) AS avg_position
                                                              FROM Cars c4
                                                                   JOIN Results r4 ON c4.name = r4.car
                                                             GROUP BY c4.class) t))
GROUP BY c.name, c.class, cl.country
ORDER BY average_position;

--Задача 4
--Определить, какие автомобили имеют среднюю позицию лучше (меньше) средней позиции всех автомобилей 
--в своем классе (то есть автомобилей в классе должно быть минимум два, чтобы выбрать один из них).
--Вывести информацию об этих автомобилях, включая их имя, класс, среднюю позицию, количество гонок, 
--в которых они участвовали, и страну производства класса автомобиля. 
--Также отсортировать результаты по классу и затем по средней позиции в порядке возрастания.
--Решение задачи должно представлять из себя один SQL-запрос.
--Ожидаемый вывод для тестовых данных
--car_name	car_class	average_position	race_count	car_country
--BMW 3 Series	Sedan	3.0	1	Germany
--Toyota RAV4	SUV	2.0000	1	Japan

SELECT cs.car_name, cs.car_class, ROUND(cs.average_position, 4) AS average_position, cs.race_count, cs.car_country
  FROM (SELECT c.name     AS car_name,
               c.class    AS car_class,
               cl.country AS car_country,
               AVG(r.position::DECIMAL) AS average_position,
               COUNT(*) AS race_count
          FROM Cars c
               JOIN Results r  ON c.name  = r.car
               JOIN Classes cl ON c.class = cl.class
         GROUP BY c.name, c.class, cl.country) cs
 WHERE cs.car_class IN (SELECT c2.class
                          FROM Cars c2
                               JOIN Results r2 ON c2.name = r2.car
                         GROUP BY c2.class
                         HAVING COUNT(DISTINCT c2.name) >= 2)
   AND cs.average_position < (SELECT AVG(car_avg.average_position)
                                FROM (SELECT c3.name, c3.class, AVG(r3.position::DECIMAL) AS average_position
                                        FROM Cars c3
                                             JOIN Results r3 ON c3.name = r3.car
                                       GROUP BY c3.name, c3.class) car_avg
                               WHERE car_avg.class = cs.car_class)
ORDER BY cs.car_class, cs.average_position;

--Задача 5
--Определить, какие классы автомобилей имеют наибольшее количество автомобилей с низкой средней позицией (больше 3.0) 
--и вывести информацию о каждом автомобиле из этих классов, включая его имя, класс, среднюю позицию, 
--количество гонок, в которых он участвовал, страну производства класса автомобиля, 
--а также общее количество гонок для каждого класса. 
--Отсортировать результаты по количеству автомобилей с низкой средней позицией.
--Решение задачи должно представлять из себя один SQL-запрос.
--Ожидаемый вывод для тестовых данных
--car_name	car_class	average_position	race_count	car_country	total_races	low_position_count
--Audi A4	Sedan	8.0000	1	Germany	2	2
--Chevrolet Camaro	Coupe	4.0000	1	USA	1	1
--Renault Clio	Hatchback	5.0000	1	France	1	1
--Ford F-150	Pickup	6.0000	1	USA	1	1

SELECT cs.car_name, cs.car_class, ROUND(cs.average_position, 4) AS average_position, cs.race_count, cs.car_country,
       (SELECT COUNT(*)
          FROM Cars c2
               JOIN Results r2 ON c2.name = r2.car
         WHERE c2.class = cs.car_class) AS total_races,
       (SELECT COUNT(*)
          FROM (SELECT c3.name, c3.class, AVG(r3.position::DECIMAL) AS average_position
                  FROM Cars c3
                       JOIN Results r3 ON c3.name = r3.car
                 GROUP BY c3.name, c3.class) t
         WHERE t.class = cs.car_class
           AND t.average_position > 3.0) AS low_position_count
  FROM (SELECT c.name     AS car_name,
               c.class    AS car_class,
               cl.country AS car_country,
               AVG(r.position::DECIMAL) AS average_position,
               COUNT(*) AS race_count
          FROM Cars c
               JOIN Results r  ON c.name  = r.car
               JOIN Classes cl ON c.class = cl.class
         GROUP BY c.name, c.class, cl.country) cs
 WHERE cs.average_position > 3.0
 ORDER BY low_position_count DESC, cs.car_class;

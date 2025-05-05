SELECT * FROM work;
SELECT * FROM museum;
SELECT * FROM museum_hours;
SELECT * FROM canvas_size;
SELECT * FROM product_size;
SELECT * FROM artist;
SELECT * FROM subject;

-- 1) Fetch all the paintings which are not displayed on any museums?
SELECT * FROM work w WHERE NOT EXISTS 
(SELECT artist_id FROM museum m
 WHERE w.museum_id = m.museum_id);
SELECT * FROM work
WHERE museum_id IS NULL;
-- 2) Are there museuems without any paintings?
SELECT * FROM museum m 
WHERE NOT EXISTS (SELECT museum_id FROM work w WHERE w.museum_id = m.museum_id);

-- 3) How many paintings have an asking price of more than their regular price? 
SELECT * 
FROM product_size
WHERE sale_price > regular_price;
-- 4) Identify the paintings whose asking price is less than 50% of its regular price
SELECT * 
FROM product_size
WHERE sale_price < (regular_price/2);
-- 5) Which canva size costs the most?
SELECT c.size_id,c.label,MAX(p.sale_price) AS most_exp
FROM canvas_size c 
JOIN product_size p
ON c.size_id=p.size_id
GROUP BY c.size_id,c.label
ORDER BY most_exp DESC
LIMIT 1;

SELECT c.size_id,c.label,p.sale_price,
RANK()OVER(ORDER BY p.sale_price DESC) AS most_exp
FROM canvas_size c 
JOIN product_size p
ON c.size_id=p.size_id
LIMIT 1;


-- 7) Identify the museums with invalid city information in the given dataset
SELECT * FROM museum
WHERE city REGEXP '[0-9]';

-- 8) Museum_Hours table has 1 invalid entry. Identify it and remove it.
SELECT * FROM museum_hours;
update museum_hours
set open = str_to_date(open,'%h:%i:%p'),
	close= str_to_date(close,'%h:%i:%p');
SELECT * FROM museum_hours
WHERE open > close;

WITH DUPL AS (	SELECT museum_id,day,open,close,
				ROW_NUMBER()OVER(PARTITION BY museum_id,day,open,close ORDER BY museum_id)AS ROW_NUM
				FROM museum_hours
				) 

DELETE FROM museum_hours
WHERE museum_id IN (
SELECT museum_id
FROM DUPL
WHERE ROW_NUM>1);
				
-- 9) Fetch the top 10 most famous painting subject

SELECT
s.subject, 
count(s.subject) AS no_subjects,
RANK()OVER(PARTITION BY s.subject ORDER BY count(s.subject) DESC) AS RANK_SUB
FROM WORK w JOIN subject s ON w.work_id=s.work_id
GROUP BY s.subject
ORDER BY no_subjects DESC
LIMIT 10;

-- 10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.



SELECT distinct(m.name),m.city,m.state,m.country
FROM museum m JOIN museum_hours mh1 
ON m.museum_id = mh1.museum_id
where mh1.day ='Sunday' 
AND EXISTS (SELECT * FROM museum_hours mh2
			WHERE mh1.museum_id=mh2.museum_id
			AND mh2.day='Monday'
);

-- 11) How many museums are open every single day
WITH EVERYdayOPEN AS(SELECT  
						  museum_id,
						  COUNT(distinct(day)) AS Museum_open7days
					FROM  museum_hours
					GROUP BY museum_id
					HAVING COUNT(distinct(day)) = 7)
SELECT COUNT(*)
FROM EVERYdayOPEN;

-- 12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
WITH MOST_POP_PAINT AS (SELECT m.museum_id,m.name,
						COUNT(work_id) AS No_painting,
						RANK() OVER(ORDER BY COUNT(work_id) DESC) AS RANK_PAINTING
						FROM museum m
						JOIN work w 
						ON m.museum_id = w.museum_id
						GROUP BY m.museum_id,m.name)
SELECT *
FROM MOST_POP_PAINT
WHERE RANK_PAINTING <=5;

-- 13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
SELECT * FROM artist;
SELECT * FROM work;

WITH POPULAR_ARTIST AS (SELECT a.artist_id, a.full_name, COUNT(work_id) AS NO_PAINT,
						RANK()OVER(ORDER BY COUNT(work_id) DESC ) AS RANK_ARTIST
						FROM artist a JOIN work w 
						ON a.artist_id=w.artist_id
						GROUP BY a.artist_id, a.full_name)
SELECT * FROM POPULAR_ARTIST
WHERE RANK_ARTIST <=5;

-- 14) Display the 3 least popular canva sizes
SELECT * FROM canvas_size;
SELECT * FROM WORK;
SELECT * FROM product_size;

WITH CANVA_SIZE_RANK AS(SELECT cs.size_id AS size_id,cs.label as Label ,COUNT(w.work_id),
						DENSE_RANK() OVER(ORDER BY COUNT(w.work_id) ASC) AS RANK_PAINTING
						FROM canvas_size cs
						JOIN product_size p ON cs.size_id = p.size_id
						JOIN work w ON p.work_id = w.work_id
						GROUP BY cs.size_id,cs.label)
SELECT size_id,Label,RANK_PAINTING FROM CANVA_SIZE_RANK 
LIMIT 3;

-- 15) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
SELECT * FROM museum_hours;
WITH RANK_LONG_OPEN AS (SELECT distinct(m.name) AS NAME ,m.city AS CITY,m.state AS STATE,mh.day AS DAY,
						TIME_FORMAT(mh.open,'%H:%i')as open,
						TIME_FORMAT(mh.close,'%H:%i') as close,
						TIMEDIFF(mh.close,mh.open) as Open_hours,
						DENSE_RANK()OVER(ORDER BY TIMEDIFF(mh.close,mh.open) DESC) AS RANK_HOUR_DIFF
						FROM museum_hours mh JOIN museum m 
						ON mh.museum_id=m.museum_id)
SELECT NAME, CITY, STATE, open,close, Open_hours FROM RANK_LONG_OPEN
WHERE RANK_HOUR_DIFF = 1;


-- 16) Which museum has the most no of most popular painting style
SELECT * FROM WORK;
WITH MOST_POP_PAINT AS (SELECT m.museum_id,m.name,w.style,
						COUNT(w.style) AS No_style,
						RANK() OVER(ORDER BY COUNT(work_id) DESC) AS RANK_STYLE
						FROM museum m
						JOIN work w 
						ON m.museum_id = w.museum_id
                        WHERE w.style <> ''
						GROUP BY m.museum_id,m.name,w.style)
SELECT * FROM MOST_POP_PAINT
WHERE RANK_STYLE = 1
;

SELECT m.museum_id,m.name,w.style,
COUNT(w.style) AS No_style
FROM museum m
JOIN work w 
ON m.museum_id = w.museum_id
WHERE w.style <> ''
GROUP BY m.museum_id,m.name,w.style
ORDER BY No_style DESC;




-- 17) Identify the artists whose paintings are displayed in multiple countries
SELECT * FROM WORK;
SELECT * FROM museum;
SELECT * FROM artist;

WITH ARTIST_MULT_COUNTR AS(	SELECT a.artist_id,a.full_name,m.country,count(m.country) AS NO_country,
							ROW_NUMBER() OVER(PARTITION BY artist_id ORDER BY count(m.country) DESC) AS NO_COUNTRIES
							FROM artist a 
							JOIN work w ON a.artist_id = w.artist_id
							JOIN museum m ON w.museum_id = m.museum_id
							GROUP BY m.country,a.artist_id,a.full_name
							ORDER BY artist_id,NO_country desc)
SELECT artist_id,full_name,country,NO_COUNTRIES 
FROM ARTIST_MULT_COUNTR
WHERE NO_COUNTRIES >=5
ORDER BY NO_COUNTRIES DESC
;

-- 18) Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.


WITH CTE_COUNTRY AS(SELECT 
					country,COUNT(museum_id) AS TOTAL_MUSEUM,RANK()OVER(ORDER BY COUNT(museum_id) desc) AS RANK_COUNTRY
					FROM museum
					GROUP BY country),
	CTE_CITY AS (SELECT 
					city,COUNT(museum_id) AS TOTAL_MUSEUM,RANK()OVER(ORDER BY COUNT(museum_id) desc) AS RANK_CITY
					FROM museum
					GROUP BY city)

SELECT
(SELECT GROUP_CONCAT( country SEPARATOR ', ')
FROM CTE_COUNTRY
WHERE RANK_COUNTRY = 1) AS COUNTRY_WITHMOST_MUSEUMS,
(SELECT GROUP_CONCAT(city SEPARATOR ', ')
FROM CTE_CITY
WHERE RANK_CITY = 1) AS CITY_WITHMOST_MUSEUM
;
-- 19) Identify the artist and the museum where the most expensive and least expensive painting is placed.
-- Display the artist name, sale_price, painting name, museum name, museum city and canvas label 
SELECT * FROM WORK;
SELECT * FROM museum;
SELECT * FROM artist;
SELECT * FROM product_size;
SELECT * FROM canvas_size;

WITH MOST_LEAST_EXP_PAIN AS(SELECT 	
								a.full_name,m.name AS Museum_name,p.sale_price,w.name AS Painting_name,m.city,cz.label,
                                RANK()OVER(ORDER BY sale_price DESC) AS RANK_MOST_EXPENS_PAINT,
                                RANK()OVER(ORDER BY sale_price)AS RANK_LEAST_EXP_PAINT
							FROM product_size p 
							JOIN work w ON w.work_id = p.work_id
							JOIN museum m ON w.museum_id = m.museum_id
							JOIN artist a ON w.artist_id = a.artist_id
                            join canvas_size cz on cz.size_id = p.size_id
							GROUP BY a.full_name,m.name ,p.sale_price,w.name,m.city,cz.label)

SELECT Museum_name,full_name,sale_price,Painting_name,city,label
FROM MOST_LEAST_EXP_PAIN 
WHERE RANK_MOST_EXPENS_PAINT = 1 OR RANK_LEAST_EXP_PAINT = 1
ORDER BY sale_price DESC;

-- 20) Which country has the 5th highest no of paintings?
SELECT * FROM WORK;
SELECT * FROM museum;

SELECT * 
FROM
	(SELECT m.country,COUNT(w.work_id) AS No_painting, 
	 RANK() OVER(ORDER BY COUNT(w.work_id) DESC) AS RANK_PAINTING_AMOUNT
	 FROM museum m
	 JOIN work w ON m.museum_id = w.museum_id
	 GROUP BY m.country) X
WHERE RANK_PAINTING_AMOUNT = 5;

-- Since uk and united_kingdom are the same we need to rename united_kingdom to UK

/* UPDATE museum
SET country = 'UK'
WHERE lower(country)='United Kingdom';*/


-- 21) Which are the 3 most popular and 3 least popular painting styles?
SELECT style, NO_PAINTING_STYLE FROM(
SELECT style, count(work_id) NO_PAINTING_STYLE,
RANK()OVER(ORDER BY count(work_id) DESC) AS RANK_MOST_POP,
RANK()OVER(ORDER BY count(work_id)) AS RANk_LEAST_POP
FROM WORK
where style <> ''
GROUP BY style) X
WHERE RANK_MOST_POP <=3 OR RANk_LEAST_POP <= 3
ORDER BY NO_PAINTING_STYLE DESC;

-- 22) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
SELECT * FROM artist;
SELECT * FROM work;
SELECT * FROM subject;
SELECT * FROM museum;

WITH MOST_PORT AS (	SELECT a.full_name,a.nationality, s.subject,COUNT(s.subject) AS no_Portraits,
					RANK()OVER(ORDER BY COUNT(s.subject) DESC) AS RANK_NO_PORTRAITS
					FROM artist a 
					JOIN work w ON a.artist_id = w.artist_id
					JOIN subject s ON w.work_id = s.work_id
                    JOIN museum m ON w.museum_id = m.museum_id
					WHERE s.subject = 'Portraits'
                    AND m.country <> 'USA'
					GROUP BY a.full_name,s.subject,a.nationality)
SELECT * FROM MOST_PORT
WHERE RANK_NO_PORTRAITS = 1;


	
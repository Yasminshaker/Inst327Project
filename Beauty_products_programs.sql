-- -------------------------------------------------------------------------------
# Most Used Beauty Products Stored Programs 

# Team 12: KAAY: Yasmin Shaker, Adriana Saavedra, Kimberly Alfaro, Anmol Riyat
# May 13, 2025 
# INST 327: Group Project Deliverable 4
-- -------------------------------------------------------------------------------

USE team12_most_used_beauty_products_db;

--
### VIEWS ###
--
# View 1: Average rating by brand
DROP VIEW IF EXISTS view1_average_rating_by_brand;
CREATE VIEW view1_average_rating_by_brand AS
SELECT CONCAT('The brand ', brand, ' has the average rating of ', ROUND(AVG(Rating), 2), ' out of 5.') AS average_rating_statement
FROM product_info 
JOIN brand USING (brand_id)
GROUP BY brand;
# Purpose of view 1: Shows average rating of brands.


# View 2: Lowest priced products
DROP VIEW IF EXISTS view2_lowest_priced_product;
CREATE VIEW view2_lowest_priced_product AS
SELECT product_name, price_usd, brand, skin_type, Rating
FROM product_info 
JOIN brand USING (brand_id)
JOIN skin_type USING (skin_type_id)
WHERE price_usd = (SELECT MIN(price_usd) FROM product_info);
# Purpose of view 2: Lists lowest priced products and their associated brand, skin_type, and rating.


# View 3: product info grouped by rating categories 
DROP VIEW IF EXISTS view3_packaging_type_by_main_ing_and_rating;
CREATE VIEW view3_packaging_type_by_main_ing_and_rating AS
SELECT product_id, product_name, price_usd, rating, packaging_type, main_ingredient, 
	CASE 
        WHEN rating <= 2.5 THEN 'Low-rated'
        WHEN rating <= 4 THEN 'Moderate'
        ELSE 'High-rated'
    END AS rating_category
FROM product_info 
JOIN packaging_type USING (packaging_type_id)
JOIN main_ingredient USING (main_ingredient_id)
ORDER BY product_id;
# Purpose of view 3: Lists products by product ID along with their price, rating, packaging type, and main ingredient, and categorizes each product by a rating level.


# View 4: highest priced product by gender target 
DROP VIEW IF EXISTS view4_highest_priced_by_gender_target;
CREATE VIEW view4_highest_priced_by_gender_target AS
SELECT product_name, Rating, price_usd, gender_target
FROM product_info JOIN gender_target USING (gender_target_id)
WHERE (gender_target, price_usd) 
	IN (SELECT gender_target, MAX(price_usd)
FROM product_info 
JOIN gender_target USING (gender_target_id)
GROUP BY gender_target);
# purpose of view 4: display the highest priced product for each gender target (Male, Female, Unisex) along with its rating.


--
### PROCEDURES ###
--
# Procedure 1: Get products and rating by skin type
DROP PROCEDURE IF EXISTS procedure1_get_products_by_skin_type;
DELIMITER //
CREATE PROCEDURE procedure1_get_products_by_skin_type(IN skin_type_name VARCHAR(20))
BEGIN
    SELECT product_name, skin_type, brand, price_usd, rating
    FROM product_info 
    JOIN skin_type USING (skin_type_id)
    JOIN brand USING (brand_id)
    WHERE skin_type = skin_type_name
    ORDER BY rating DESC;
END//
DELIMITER ;
# Purpose of procedure 1: Returns products based on skin type.
# Sample Call:
CALL team12_most_used_beauty_products_db.procedure1_get_products_by_skin_type('sensitive');


# Procedure 2: Get rating of brands
DROP PROCEDURE IF EXISTS procedure2_Get_Brand_Rating;
DELIMITER //
CREATE PROCEDURE procedure2_Get_Brand_Rating (IN input_brand VARCHAR(25))
BEGIN
    SELECT Brand AS Brand_Name,
        ROUND(AVG(Rating), 2) AS Average_Rating,
        SUM(number_of_reviews) AS Total_Reviews
    FROM product_info 
    JOIN brand USING (Brand_id)  
    WHERE Brand = input_brand 
    GROUP BY Brand;
END //
DELIMITER ;
# purpose of procedure 2: shows the average rating and total number of reviews for a given brand.
# Sample Call:
call team12_most_used_beauty_products_db.procedure2_Get_Brand_Rating('Charlotte Tilbury');


--
### FUNCTIONS ###
--
# Function 1: Total number products associated with a specific brand
DROP FUNCTION IF EXISTS function1_count_num_of_brands;
DELIMITER //
CREATE FUNCTION function1_count_num_of_brands(
    Brand VARCHAR(45))
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE amount INT;
    SELECT COUNT(*)
    INTO amount
    FROM product_info pi
    JOIN brand b ON pi.brand_id = b.brand_id
    WHERE b.brand = Brand;
    RETURN amount;
END //
DELIMITER ;
# Purpose of Function 1: Returns count of products associated with a specific brand
# Sample Call:
select team12_most_used_beauty_products_db.function1_count_num_of_brands('Bobby Brown');


#Function 2: Female targeted brands for sensitive skin
DROP FUNCTION IF EXISTS function2_count_female_sensitive_brands;
DELIMITER //
CREATE FUNCTION function2_count_female_sensitive_brands()
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE brand_count INT;
    SELECT COUNT(DISTINCT b.brand)
    INTO brand_count
    FROM product_info pi
    JOIN brand b ON pi.brand_id = b.brand_id
    JOIN gender_target gt ON pi.gender_target_id = gt.gender_target_id
    JOIN skin_type st ON pi.skin_type_id = st.skin_type_id
    WHERE gt.gender_target = 'Female'
      AND st.skin_type = 'Sensitive';
    RETURN brand_count;
END //
DELIMITER ;
# Purpose of Function 2: Returns number of female targeted brands for sensitive skin
# Sample Call:
select team12_most_used_beauty_products_db.function2_count_female_sensitive_brands();

--
### TRIGGER ###
--
# Trigger 1: preventing new products from being entered with a negative price
DELIMITER //
DROP TRIGGER IF EXISTS preventing_negative_price;
CREATE TRIGGER preventing_negative_price
BEFORE INSERT ON product_info
FOR EACH ROW
BEGIN
    IF NEW.price_usd < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Product cannot be inserted due to invalid price';
    END IF;
END//
DELIMITER ;

# Purpose of Trigger: Prevent new products to be inserted with a negative price into the products_info table and raises an error.
# Example of inserting a product with a negative price:
INSERT INTO product_info (
    product_id, product_name, price_usd, Rating, number_of_reviews, Product_Size_ML,
    brand_id, gender_target_id, packaging_type_id, skin_type_id,
    usage_frequency_id, main_ingredient_id, country_id)
VALUES (999, 'Magic Mascara', -12.99, 2.4, 100, 50, 9, 2, 1, 1, 3, 7, 1);


# Example of inserting a product with a regular price:
INSERT INTO product_info (
    product_id, product_name, price_usd, Rating, number_of_reviews, Product_Size_ML,
    brand_id, gender_target_id, packaging_type_id, skin_type_id,
    usage_frequency_id, main_ingredient_id, country_id)
VALUES (999, 'Magic Serum', 24.99, 4.4, 200, 2500, 20, 1, 2, 1, 2, 5, 2);


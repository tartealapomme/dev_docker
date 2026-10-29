ALTER TABLE products ADD COLUMN IF NOT EXISTS sku text;
UPDATE products SET sku = 'SKU-' || id WHERE sku IS NULL;

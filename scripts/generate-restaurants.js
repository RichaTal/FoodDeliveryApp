const fs = require('fs');
const path = require('path');

// Cuisine types for variety
const cuisineTypes = [
  'Italian', 'Chinese', 'Mexican', 'Indian', 'Japanese', 'Thai', 'American',
  'French', 'Mediterranean', 'Korean', 'Vietnamese', 'Greek', 'Spanish',
  'Turkish', 'Lebanese', 'Brazilian', 'German', 'British', 'Caribbean', 'Fusion'
];

// Menu category templates by cuisine
const categoryTemplates = {
  'Italian': ['Pizzas', 'Pastas', 'Appetizers', 'Desserts'],
  'Chinese': ['Dim Sum', 'Noodles', 'Rice Dishes', 'Soups'],
  'Mexican': ['Tacos', 'Burritos', 'Quesadillas', 'Appetizers'],
  'Indian': ['Curries', 'Biryani', 'Breads', 'Appetizers'],
  'Japanese': ['Sushi', 'Ramen', 'Teriyaki', 'Appetizers'],
  'Thai': ['Curries', 'Noodles', 'Stir Fries', 'Appetizers'],
  'American': ['Burgers', 'Sandwiches', 'Salads', 'Sides'],
  'French': ['Entrees', 'Soups', 'Salads', 'Desserts'],
  'Mediterranean': ['Mezze', 'Grills', 'Salads', 'Desserts'],
  'Korean': ['BBQ', 'Rice Bowls', 'Noodles', 'Appetizers'],
  'Vietnamese': ['Pho', 'Banh Mi', 'Rice Dishes', 'Appetizers'],
  'Greek': ['Gyros', 'Souvlaki', 'Salads', 'Desserts'],
  'Spanish': ['Tapas', 'Paella', 'Soups', 'Desserts'],
  'Turkish': ['Kebabs', 'Mezze', 'Grills', 'Desserts'],
  'Lebanese': ['Mezze', 'Grills', 'Salads', 'Desserts'],
  'Brazilian': ['Grills', 'Rice Dishes', 'Appetizers', 'Desserts'],
  'German': ['Schnitzel', 'Sausages', 'Sides', 'Desserts'],
  'British': ['Fish & Chips', 'Pies', 'Sides', 'Desserts'],
  'Caribbean': ['Jerk', 'Rice Dishes', 'Soups', 'Desserts'],
  'Fusion': ['Specialties', 'Appetizers', 'Sides', 'Desserts']
};

// Menu item templates
const itemTemplates = {
  'Pizzas': [
    { name: 'Margherita', desc: 'Classic tomato sauce, mozzarella, fresh basil', price: 12.99 },
    { name: 'Pepperoni', desc: 'Tomato sauce, mozzarella, spicy pepperoni', price: 14.99 },
    { name: 'Quattro Stagioni', desc: 'Artichokes, mushrooms, ham, olives', price: 15.99 },
    { name: 'Hawaiian', desc: 'Ham, pineapple, mozzarella', price: 13.99 },
    { name: 'Vegetarian', desc: 'Mixed vegetables, mozzarella', price: 13.49 }
  ],
  'Pastas': [
    { name: 'Spaghetti Carbonara', desc: 'Spaghetti, guanciale, egg yolk, Pecorino', price: 13.99 },
    { name: 'Penne Arrabbiata', desc: 'Penne with spicy tomato and garlic sauce', price: 11.99 },
    { name: 'Fettuccine Alfredo', desc: 'Fettuccine with butter and Parmesan cream', price: 13.49 },
    { name: 'Lasagna', desc: 'Layered pasta with meat sauce and cheese', price: 14.99 },
    { name: 'Ravioli', desc: 'Stuffed pasta with ricotta and spinach', price: 12.99 }
  ],
  'Dim Sum': [
    { name: 'Har Gow', desc: 'Steamed shrimp dumplings', price: 8.99 },
    { name: 'Siu Mai', desc: 'Open-top pork and shrimp dumplings', price: 8.49 },
    { name: 'Char Siu Bao', desc: 'Steamed BBQ pork buns', price: 7.99 },
    { name: 'Spring Rolls', desc: 'Crispy vegetable spring rolls', price: 6.99 },
    { name: 'Xiao Long Bao', desc: 'Soup dumplings with pork', price: 9.99 }
  ],
  'Noodles': [
    { name: 'Beef Chow Fun', desc: 'Stir-fried wide rice noodles with beef', price: 14.99 },
    { name: 'Dan Dan Noodles', desc: 'Spicy Sichuan noodles with minced pork', price: 12.99 },
    { name: 'Wonton Soup', desc: 'Pork and shrimp wontons in clear broth', price: 11.49 },
    { name: 'Lo Mein', desc: 'Stir-fried noodles with vegetables', price: 11.99 },
    { name: 'Pad Thai', desc: 'Thai-style stir-fried noodles', price: 12.49 }
  ],
  'Tacos': [
    { name: 'Beef Tacos', desc: 'Seasoned ground beef with lettuce and cheese', price: 9.99 },
    { name: 'Chicken Tacos', desc: 'Grilled chicken with salsa and avocado', price: 9.99 },
    { name: 'Fish Tacos', desc: 'Battered fish with cabbage slaw', price: 10.99 },
    { name: 'Vegetarian Tacos', desc: 'Black beans, corn, and vegetables', price: 8.99 }
  ],
  'Curries': [
    { name: 'Chicken Curry', desc: 'Tender chicken in rich curry sauce', price: 13.99 },
    { name: 'Lamb Curry', desc: 'Slow-cooked lamb in aromatic spices', price: 15.99 },
    { name: 'Vegetable Curry', desc: 'Mixed vegetables in coconut curry', price: 11.99 },
    { name: 'Butter Chicken', desc: 'Creamy tomato-based curry', price: 14.49 }
  ],
  'Sushi': [
    { name: 'Salmon Roll', desc: 'Fresh salmon with rice and nori', price: 8.99 },
    { name: 'Tuna Roll', desc: 'Premium tuna with rice and nori', price: 9.99 },
    { name: 'California Roll', desc: 'Crab, avocado, and cucumber', price: 7.99 },
    { name: 'Dragon Roll', desc: 'Eel, cucumber, and avocado', price: 12.99 }
  ],
  'Burgers': [
    { name: 'Classic Burger', desc: 'Beef patty with lettuce, tomato, onion', price: 10.99 },
    { name: 'Cheeseburger', desc: 'Beef patty with cheese and special sauce', price: 11.99 },
    { name: 'Chicken Burger', desc: 'Grilled chicken breast with fixings', price: 10.49 },
    { name: 'Veggie Burger', desc: 'Plant-based patty with vegetables', price: 9.99 }
  ],
  'Appetizers': [
    { name: 'Mozzarella Sticks', desc: 'Breaded mozzarella with marinara', price: 7.99 },
    { name: 'Chicken Wings', desc: 'Crispy wings with your choice of sauce', price: 9.99 },
    { name: 'Nachos', desc: 'Tortilla chips with cheese and jalapeños', price: 8.99 },
    { name: 'Spring Rolls', desc: 'Crispy vegetable rolls', price: 6.99 }
  ],
  'Desserts': [
    { name: 'Chocolate Cake', desc: 'Rich chocolate layer cake', price: 6.99 },
    { name: 'Ice Cream', desc: 'Vanilla, chocolate, or strawberry', price: 4.99 },
    { name: 'Cheesecake', desc: 'New York style cheesecake', price: 7.99 },
    { name: 'Tiramisu', desc: 'Classic Italian dessert', price: 7.49 }
  ],
  // Generic templates for categories not specifically defined
  'Rice Dishes': [
    { name: 'Fried Rice', desc: 'Stir-fried rice with vegetables and protein', price: 11.99 },
    { name: 'Biryani', desc: 'Fragrant spiced rice with meat', price: 13.99 },
    { name: 'Risotto', desc: 'Creamy Italian rice dish', price: 12.99 }
  ],
  'Soups': [
    { name: 'Chicken Noodle Soup', desc: 'Classic comfort soup', price: 8.99 },
    { name: 'Tomato Soup', desc: 'Creamy tomato soup', price: 7.99 },
    { name: 'Miso Soup', desc: 'Traditional Japanese soup', price: 6.99 }
  ],
  'Salads': [
    { name: 'Caesar Salad', desc: 'Romaine lettuce with Caesar dressing', price: 9.99 },
    { name: 'Greek Salad', desc: 'Fresh vegetables with feta cheese', price: 10.99 },
    { name: 'Garden Salad', desc: 'Mixed greens with vegetables', price: 8.99 }
  ],
  'Sides': [
    { name: 'French Fries', desc: 'Crispy golden fries', price: 4.99 },
    { name: 'Onion Rings', desc: 'Battered and fried onion rings', price: 5.99 },
    { name: 'Coleslaw', desc: 'Fresh cabbage salad', price: 3.99 }
  ]
};

// Generate UUID-like string
function generateUUID(index) {
  const hex = index.toString(16).padStart(8, '0');
  return `${hex}-${hex.substring(0,4)}-4${hex.substring(4,7)}-8${hex.substring(0,3)}-${hex}${hex.substring(0,4)}`;
}

// Generate all data in one pass
function generateAllData() {
  const restaurants = [];
  const categories = [];
  const menuItems = [];
  
  const baseLat = 40.7128; // NYC area
  const baseLng = -74.0060;
  
  let categoryIndex = 1000000;
  let itemIndex = 2000000;
  
  for (let i = 1; i <= 200; i++) {
    const cuisine = cuisineTypes[i % cuisineTypes.length];
    const restaurantId = generateUUID(i);
    const lat = baseLat + (Math.random() - 0.5) * 0.1;
    const lng = baseLng + (Math.random() - 0.5) * 0.1;
    const isOpen = Math.random() > 0.1; // 90% open
    
    restaurants.push(`(
    '${restaurantId}',
    '${cuisine} Restaurant ${i}',
    '${Math.floor(Math.random() * 9999) + 1} ${cuisine} Street, Area ${Math.floor(i / 100) + 1}',
    ${lat.toFixed(7)},
    ${lng.toFixed(7)},
    ${isOpen}
)`);
    
    // Generate categories for this restaurant
    const cats = categoryTemplates[cuisine] || ['Main Dishes', 'Appetizers', 'Sides', 'Desserts'];
    const numCategories = 2 + Math.floor(Math.random() * 3); // 2-4 categories
    
    const restaurantCategories = [];
    for (let j = 0; j < numCategories && j < cats.length; j++) {
      const categoryId = generateUUID(categoryIndex++);
      const categoryName = cats[j];
      restaurantCategories.push({ id: categoryId, name: categoryName, order: j + 1 });
      
      categories.push(`(
    '${categoryId}',
    '${restaurantId}',
    '${categoryName}',
    ${j + 1}
)`);
      
      // Generate menu items for this category
      const items = itemTemplates[categoryName] || itemTemplates['Appetizers'];
      const numItems = 3 + Math.floor(Math.random() * 3); // 3-5 items
      
      for (let k = 0; k < numItems && k < items.length; k++) {
        const item = items[k];
        const itemId = generateUUID(itemIndex++);
        const price = (item.price + (Math.random() - 0.5) * 2).toFixed(2);
        
        menuItems.push(`(
    '${itemId}',
    '${categoryId}',
    '${restaurantId}',
    '${item.name}',
    '${item.desc}',
    ${price},
    TRUE
)`);
      }
    }
  }
  
  return { restaurants, categories, menuItems };
}

// Main generation
const header = `-- ============================================================
--  Food Delivery App — PostgreSQL Initialisation Script
--  Executed automatically on first container start
--  Generated with 200 restaurants
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ──────────────────────────────────────────────────────────────
--  TABLES
-- ──────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS restaurants (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255) NOT NULL,
    address     TEXT         NOT NULL,
    lat         DECIMAL(10, 7) NOT NULL,
    lng         DECIMAL(10, 7) NOT NULL,
    is_open     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS menu_categories (
    id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID         NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name          VARCHAR(255) NOT NULL,
    display_order INT          NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS menu_items (
    id            UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id   UUID           NOT NULL REFERENCES menu_categories(id) ON DELETE CASCADE,
    restaurant_id UUID           NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name          VARCHAR(255)   NOT NULL,
    description   TEXT,
    price         DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    is_available  BOOLEAN        NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS drivers (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(255) NOT NULL,
    phone      VARCHAR(20)  NOT NULL UNIQUE,
    vehicle    VARCHAR(100) NOT NULL,
    is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id   UUID           NOT NULL REFERENCES restaurants(id),
    driver_id       UUID           REFERENCES drivers(id),
    status          VARCHAR(50)    NOT NULL DEFAULT 'PENDING',
    total_amount    DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    payment_status  VARCHAR(50)    NOT NULL DEFAULT 'PENDING',
    payment_txn_id  VARCHAR(255),
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
    id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID           NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    menu_item_id    UUID           NOT NULL,
    name            VARCHAR(255)   NOT NULL,  -- snapshot of item name at time of order
    price_at_time   DECIMAL(10, 2) NOT NULL CHECK (price_at_time >= 0),  -- snapshot price
    quantity        INT            NOT NULL CHECK (quantity > 0)
);

-- ──────────────────────────────────────────────────────────────
--  INDEXES
-- ──────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_orders_status
    ON orders (status);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
    ON order_items (order_id);

CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant_id
    ON menu_items (restaurant_id);

-- ──────────────────────────────────────────────────────────────
--  SEED DATA
-- ──────────────────────────────────────────────────────────────

`;

console.log('Generating 200 restaurants with menus...');
const { restaurants, categories, menuItems } = generateAllData();

const restaurantsSQL = `-- Restaurants (200 restaurants)
INSERT INTO restaurants (id, name, address, lat, lng, is_open) VALUES
${restaurants.join(',\n')};

`;

const categoriesSQL = `-- Menu Categories
INSERT INTO menu_categories (id, restaurant_id, name, display_order) VALUES
${categories.join(',\n')};

`;

const menuItemsSQL = `-- Menu Items
INSERT INTO menu_items (id, category_id, restaurant_id, name, description, price, is_available) VALUES
${menuItems.join(',\n')};

`;

const driversSQL = `-- Drivers (3 drivers)
INSERT INTO drivers (id, name, phone, vehicle, is_active) VALUES
(
    'e1111111-1111-4111-8111-111111111111',
    'Alex Rivera',
    '+1-555-0101',
    'Honda PCX 150 Scooter',
    TRUE
),
(
    'e2222222-2222-4222-8222-222222222222',
    'Sam Chen',
    '+1-555-0102',
    'Yamaha NMAX 155 Scooter',
    TRUE
),
(
    'e3333333-3333-4333-8333-333333333333',
    'Jordan Lee',
    '+1-555-0103',
    'Trek FX3 Disc Bicycle',
    TRUE
);
`;

const fullSQL = header + restaurantsSQL + categoriesSQL + menuItemsSQL + driversSQL;

// Write to file
const outputPath = path.join(__dirname, '..', 'infra', 'postgres', 'init.sql');
fs.writeFileSync(outputPath, fullSQL, 'utf8');
console.log(`Generated init.sql with 200 restaurants at ${outputPath}`);
console.log(`File size: ${(fullSQL.length / 1024 / 1024).toFixed(2)} MB`);
console.log(`Restaurants: ${restaurants.length}`);
console.log(`Categories: ${categories.length}`);
console.log(`Menu Items: ${menuItems.length}`);

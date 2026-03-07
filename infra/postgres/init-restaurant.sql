-- ============================================================
--  Restaurant Database — PostgreSQL Initialisation Script
--  Executed automatically on first container start
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

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

-- ──────────────────────────────────────────────────────────────
--  INDEXES
-- ──────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant_id
    ON menu_items (restaurant_id);

-- Performance indexes for menu queries (original working indexes)
CREATE INDEX IF NOT EXISTS idx_menu_categories_restaurant_id
    ON menu_categories (restaurant_id);

CREATE INDEX IF NOT EXISTS idx_menu_items_category_id
    ON menu_items (category_id);

CREATE INDEX IF NOT EXISTS idx_menu_categories_display_order
    ON menu_categories (restaurant_id, display_order);

-- ──────────────────────────────────────────────────────────────
--  SEED DATA
-- ──────────────────────────────────────────────────────────────

-- Restaurants (200 restaurants)
INSERT INTO restaurants (id, name, address, lat, lng, is_open) VALUES
(
    '00000001-0000-4000-8000-000000010000',
    'Chinese Restaurant 1',
    '4003 Chinese Street, Area 1',
    40.6815702,
    -74.0186814,
    true
),
(
    '00000002-0000-4000-8000-000000020000',
    'Mexican Restaurant 2',
    '657 Mexican Street, Area 1',
    40.7496479,
    -74.0115200,
    true
),
(
    '00000003-0000-4000-8000-000000030000',
    'Indian Restaurant 3',
    '5543 Indian Street, Area 1',
    40.6965987,
    -74.0525845,
    true
),
(
    '00000004-0000-4000-8000-000000040000',
    'Japanese Restaurant 4',
    '5397 Japanese Street, Area 1',
    40.6963814,
    -73.9574879,
    true
),
(
    '00000005-0000-4000-8000-000000050000',
    'Thai Restaurant 5',
    '1670 Thai Street, Area 1',
    40.7462503,
    -74.0186079,
    true
),
(
    '00000006-0000-4000-8000-000000060000',
    'American Restaurant 6',
    '4363 American Street, Area 1',
    40.6873869,
    -74.0002625,
    true
),
(
    '00000007-0000-4000-8000-000000070000',
    'French Restaurant 7',
    '9949 French Street, Area 1',
    40.7324079,
    -74.0514853,
    true
),
(
    '00000008-0000-4000-8000-000000080000',
    'Mediterranean Restaurant 8',
    '2492 Mediterranean Street, Area 1',
    40.7602023,
    -73.9726237,
    true
),
(
    '00000009-0000-4000-8000-000000090000',
    'Korean Restaurant 9',
    '4441 Korean Street, Area 1',
    40.7016051,
    -73.9775766,
    true
),
(
    '0000000a-0000-4000-8000-0000000a0000',
    'Vietnamese Restaurant 10',
    '1037 Vietnamese Street, Area 1',
    40.6700323,
    -74.0320216,
    false
),
(
    '0000000b-0000-4000-8000-0000000b0000',
    'Greek Restaurant 11',
    '5558 Greek Street, Area 1',
    40.6782776,
    -74.0195206,
    true
),
(
    '0000000c-0000-4000-8000-0000000c0000',
    'Spanish Restaurant 12',
    '7044 Spanish Street, Area 1',
    40.7041796,
    -73.9604256,
    true
),
(
    '0000000d-0000-4000-8000-0000000d0000',
    'Turkish Restaurant 13',
    '4612 Turkish Street, Area 1',
    40.7182533,
    -74.0408985,
    true
),
(
    '0000000e-0000-4000-8000-0000000e0000',
    'Lebanese Restaurant 14',
    '9419 Lebanese Street, Area 1',
    40.7296612,
    -74.0095743,
    true
),
(
    '0000000f-0000-4000-8000-0000000f0000',
    'Brazilian Restaurant 15',
    '1949 Brazilian Street, Area 1',
    40.6696085,
    -74.0169319,
    true
),
(
    '00000010-0000-4001-8000-000000100000',
    'German Restaurant 16',
    '8065 German Street, Area 1',
    40.6712586,
    -74.0062116,
    true
),
(
    '00000011-0000-4001-8000-000000110000',
    'British Restaurant 17',
    '6286 British Street, Area 1',
    40.7517343,
    -74.0056018,
    true
),
(
    '00000012-0000-4001-8000-000000120000',
    'Caribbean Restaurant 18',
    '5165 Caribbean Street, Area 1',
    40.7074393,
    -73.9616906,
    true
),
(
    '00000013-0000-4001-8000-000000130000',
    'Fusion Restaurant 19',
    '4468 Fusion Street, Area 1',
    40.7406188,
    -73.9896779,
    true
),
(
    '00000014-0000-4001-8000-000000140000',
    'Italian Restaurant 20',
    '7503 Italian Street, Area 1',
    40.6996314,
    -74.0165029,
    true
),
(
    '00000015-0000-4001-8000-000000150000',
    'Chinese Restaurant 21',
    '2446 Chinese Street, Area 1',
    40.7406363,
    -74.0384340,
    true
),
(
    '00000016-0000-4001-8000-000000160000',
    'Mexican Restaurant 22',
    '3208 Mexican Street, Area 1',
    40.7554086,
    -74.0431480,
    true
),
(
    '00000017-0000-4001-8000-000000170000',
    'Indian Restaurant 23',
    '5163 Indian Street, Area 1',
    40.7079714,
    -74.0142837,
    true
),
(
    '00000018-0000-4001-8000-000000180000',
    'Japanese Restaurant 24',
    '6940 Japanese Street, Area 1',
    40.7063622,
    -73.9948058,
    true
),
(
    '00000019-0000-4001-8000-000000190000',
    'Thai Restaurant 25',
    '9324 Thai Street, Area 1',
    40.6878592,
    -73.9825927,
    true
),
(
    '0000001a-0000-4001-8000-0000001a0000',
    'American Restaurant 26',
    '2295 American Street, Area 1',
    40.7477591,
    -74.0045152,
    true
),
(
    '0000001b-0000-4001-8000-0000001b0000',
    'French Restaurant 27',
    '3421 French Street, Area 1',
    40.7299876,
    -74.0273996,
    true
),
(
    '0000001c-0000-4001-8000-0000001c0000',
    'Mediterranean Restaurant 28',
    '5074 Mediterranean Street, Area 1',
    40.7005311,
    -74.0012696,
    true
),
(
    '0000001d-0000-4001-8000-0000001d0000',
    'Korean Restaurant 29',
    '5040 Korean Street, Area 1',
    40.7372150,
    -74.0378488,
    true
),
(
    '0000001e-0000-4001-8000-0000001e0000',
    'Vietnamese Restaurant 30',
    '4732 Vietnamese Street, Area 1',
    40.6948271,
    -73.9997785,
    true
),
(
    '0000001f-0000-4001-8000-0000001f0000',
    'Greek Restaurant 31',
    '6335 Greek Street, Area 1',
    40.7069127,
    -74.0332743,
    true
),
(
    '00000020-0000-4002-8000-000000200000',
    'Spanish Restaurant 32',
    '1154 Spanish Street, Area 1',
    40.7328256,
    -74.0402316,
    true
),
(
    '00000021-0000-4002-8000-000000210000',
    'Turkish Restaurant 33',
    '108 Turkish Street, Area 1',
    40.7101472,
    -73.9963753,
    true
),
(
    '00000022-0000-4002-8000-000000220000',
    'Lebanese Restaurant 34',
    '1256 Lebanese Street, Area 1',
    40.6749334,
    -73.9750317,
    true
),
(
    '00000023-0000-4002-8000-000000230000',
    'Brazilian Restaurant 35',
    '6617 Brazilian Street, Area 1',
    40.7430568,
    -74.0018077,
    true
),
(
    '00000024-0000-4002-8000-000000240000',
    'German Restaurant 36',
    '956 German Street, Area 1',
    40.7183236,
    -73.9859217,
    false
),
(
    '00000025-0000-4002-8000-000000250000',
    'British Restaurant 37',
    '4118 British Street, Area 1',
    40.7023967,
    -73.9906347,
    true
),
(
    '00000026-0000-4002-8000-000000260000',
    'Caribbean Restaurant 38',
    '269 Caribbean Street, Area 1',
    40.6870241,
    -73.9867238,
    true
),
(
    '00000027-0000-4002-8000-000000270000',
    'Fusion Restaurant 39',
    '4779 Fusion Street, Area 1',
    40.6916044,
    -73.9674022,
    false
),
(
    '00000028-0000-4002-8000-000000280000',
    'Italian Restaurant 40',
    '796 Italian Street, Area 1',
    40.6908247,
    -73.9983059,
    true
),
(
    '00000029-0000-4002-8000-000000290000',
    'Chinese Restaurant 41',
    '8241 Chinese Street, Area 1',
    40.7191891,
    -74.0024619,
    true
),
(
    '0000002a-0000-4002-8000-0000002a0000',
    'Mexican Restaurant 42',
    '7922 Mexican Street, Area 1',
    40.7311882,
    -74.0507748,
    true
),
(
    '0000002b-0000-4002-8000-0000002b0000',
    'Indian Restaurant 43',
    '7299 Indian Street, Area 1',
    40.6689537,
    -74.0314559,
    true
),
(
    '0000002c-0000-4002-8000-0000002c0000',
    'Japanese Restaurant 44',
    '2242 Japanese Street, Area 1',
    40.6894857,
    -73.9579852,
    true
),
(
    '0000002d-0000-4002-8000-0000002d0000',
    'Thai Restaurant 45',
    '764 Thai Street, Area 1',
    40.6848586,
    -74.0513145,
    true
),
(
    '0000002e-0000-4002-8000-0000002e0000',
    'American Restaurant 46',
    '7569 American Street, Area 1',
    40.7388545,
    -74.0259297,
    true
),
(
    '0000002f-0000-4002-8000-0000002f0000',
    'French Restaurant 47',
    '7849 French Street, Area 1',
    40.7097730,
    -73.9833047,
    true
),
(
    '00000030-0000-4003-8000-000000300000',
    'Mediterranean Restaurant 48',
    '6550 Mediterranean Street, Area 1',
    40.6872491,
    -74.0412379,
    true
),
(
    '00000031-0000-4003-8000-000000310000',
    'Korean Restaurant 49',
    '847 Korean Street, Area 1',
    40.7066171,
    -73.9606483,
    true
),
(
    '00000032-0000-4003-8000-000000320000',
    'Vietnamese Restaurant 50',
    '8381 Vietnamese Street, Area 1',
    40.7617313,
    -73.9745630,
    true
),
(
    '00000033-0000-4003-8000-000000330000',
    'Greek Restaurant 51',
    '5281 Greek Street, Area 1',
    40.6687874,
    -74.0115234,
    true
),
(
    '00000034-0000-4003-8000-000000340000',
    'Spanish Restaurant 52',
    '5849 Spanish Street, Area 1',
    40.7363608,
    -74.0215074,
    true
),
(
    '00000035-0000-4003-8000-000000350000',
    'Turkish Restaurant 53',
    '6603 Turkish Street, Area 1',
    40.6765874,
    -73.9777378,
    true
),
(
    '00000036-0000-4003-8000-000000360000',
    'Lebanese Restaurant 54',
    '4999 Lebanese Street, Area 1',
    40.6979429,
    -74.0475096,
    false
),
(
    '00000037-0000-4003-8000-000000370000',
    'Brazilian Restaurant 55',
    '9609 Brazilian Street, Area 1',
    40.7115309,
    -74.0183680,
    true
),
(
    '00000038-0000-4003-8000-000000380000',
    'German Restaurant 56',
    '9814 German Street, Area 1',
    40.7555515,
    -74.0110650,
    true
),
(
    '00000039-0000-4003-8000-000000390000',
    'British Restaurant 57',
    '4608 British Street, Area 1',
    40.7296728,
    -73.9991054,
    true
),
(
    '0000003a-0000-4003-8000-0000003a0000',
    'Caribbean Restaurant 58',
    '1977 Caribbean Street, Area 1',
    40.7145122,
    -73.9773500,
    true
),
(
    '0000003b-0000-4003-8000-0000003b0000',
    'Fusion Restaurant 59',
    '1397 Fusion Street, Area 1',
    40.7449200,
    -73.9703732,
    true
),
(
    '0000003c-0000-4003-8000-0000003c0000',
    'Italian Restaurant 60',
    '9340 Italian Street, Area 1',
    40.7501886,
    -73.9748553,
    true
),
(
    '0000003d-0000-4003-8000-0000003d0000',
    'Chinese Restaurant 61',
    '4415 Chinese Street, Area 1',
    40.7501438,
    -73.9965315,
    true
),
(
    '0000003e-0000-4003-8000-0000003e0000',
    'Mexican Restaurant 62',
    '2832 Mexican Street, Area 1',
    40.7234475,
    -73.9685572,
    true
),
(
    '0000003f-0000-4003-8000-0000003f0000',
    'Indian Restaurant 63',
    '3559 Indian Street, Area 1',
    40.7050657,
    -74.0442195,
    true
),
(
    '00000040-0000-4004-8000-000000400000',
    'Japanese Restaurant 64',
    '7099 Japanese Street, Area 1',
    40.7204097,
    -73.9824470,
    true
),
(
    '00000041-0000-4004-8000-000000410000',
    'Thai Restaurant 65',
    '9900 Thai Street, Area 1',
    40.7426830,
    -74.0252851,
    true
),
(
    '00000042-0000-4004-8000-000000420000',
    'American Restaurant 66',
    '1101 American Street, Area 1',
    40.7035217,
    -73.9620451,
    true
),
(
    '00000043-0000-4004-8000-000000430000',
    'French Restaurant 67',
    '6791 French Street, Area 1',
    40.7219582,
    -73.9634336,
    false
),
(
    '00000044-0000-4004-8000-000000440000',
    'Mediterranean Restaurant 68',
    '4802 Mediterranean Street, Area 1',
    40.6905365,
    -74.0124550,
    true
),
(
    '00000045-0000-4004-8000-000000450000',
    'Korean Restaurant 69',
    '2800 Korean Street, Area 1',
    40.6693739,
    -73.9956459,
    true
),
(
    '00000046-0000-4004-8000-000000460000',
    'Vietnamese Restaurant 70',
    '3254 Vietnamese Street, Area 1',
    40.6690365,
    -74.0556805,
    false
),
(
    '00000047-0000-4004-8000-000000470000',
    'Greek Restaurant 71',
    '8315 Greek Street, Area 1',
    40.6997223,
    -74.0524706,
    true
),
(
    '00000048-0000-4004-8000-000000480000',
    'Spanish Restaurant 72',
    '8391 Spanish Street, Area 1',
    40.7430830,
    -73.9655579,
    true
),
(
    '00000049-0000-4004-8000-000000490000',
    'Turkish Restaurant 73',
    '5652 Turkish Street, Area 1',
    40.7467889,
    -74.0414399,
    true
),
(
    '0000004a-0000-4004-8000-0000004a0000',
    'Lebanese Restaurant 74',
    '5837 Lebanese Street, Area 1',
    40.7156939,
    -74.0147409,
    true
),
(
    '0000004b-0000-4004-8000-0000004b0000',
    'Brazilian Restaurant 75',
    '6356 Brazilian Street, Area 1',
    40.7398624,
    -73.9691592,
    true
),
(
    '0000004c-0000-4004-8000-0000004c0000',
    'German Restaurant 76',
    '8697 German Street, Area 1',
    40.6736212,
    -73.9802713,
    true
),
(
    '0000004d-0000-4004-8000-0000004d0000',
    'British Restaurant 77',
    '5160 British Street, Area 1',
    40.6907384,
    -74.0358893,
    true
),
(
    '0000004e-0000-4004-8000-0000004e0000',
    'Caribbean Restaurant 78',
    '1355 Caribbean Street, Area 1',
    40.6967906,
    -73.9787675,
    true
),
(
    '0000004f-0000-4004-8000-0000004f0000',
    'Fusion Restaurant 79',
    '9187 Fusion Street, Area 1',
    40.6905953,
    -74.0079736,
    true
),
(
    '00000050-0000-4005-8000-000000500000',
    'Italian Restaurant 80',
    '8374 Italian Street, Area 1',
    40.7055784,
    -74.0114538,
    true
),
(
    '00000051-0000-4005-8000-000000510000',
    'Chinese Restaurant 81',
    '5117 Chinese Street, Area 1',
    40.6953739,
    -73.9863158,
    false
),
(
    '00000052-0000-4005-8000-000000520000',
    'Mexican Restaurant 82',
    '935 Mexican Street, Area 1',
    40.7425165,
    -74.0419531,
    true
),
(
    '00000053-0000-4005-8000-000000530000',
    'Indian Restaurant 83',
    '6597 Indian Street, Area 1',
    40.7164672,
    -73.9728638,
    false
),
(
    '00000054-0000-4005-8000-000000540000',
    'Japanese Restaurant 84',
    '4423 Japanese Street, Area 1',
    40.7004674,
    -74.0407427,
    true
),
(
    '00000055-0000-4005-8000-000000550000',
    'Thai Restaurant 85',
    '7296 Thai Street, Area 1',
    40.7436258,
    -74.0421545,
    true
),
(
    '00000056-0000-4005-8000-000000560000',
    'American Restaurant 86',
    '4857 American Street, Area 1',
    40.6964432,
    -73.9897447,
    true
),
(
    '00000057-0000-4005-8000-000000570000',
    'French Restaurant 87',
    '2776 French Street, Area 1',
    40.6887270,
    -74.0257427,
    true
),
(
    '00000058-0000-4005-8000-000000580000',
    'Mediterranean Restaurant 88',
    '278 Mediterranean Street, Area 1',
    40.6869274,
    -73.9918162,
    true
),
(
    '00000059-0000-4005-8000-000000590000',
    'Korean Restaurant 89',
    '7837 Korean Street, Area 1',
    40.7387942,
    -74.0508801,
    true
),
(
    '0000005a-0000-4005-8000-0000005a0000',
    'Vietnamese Restaurant 90',
    '3714 Vietnamese Street, Area 1',
    40.6849680,
    -74.0011963,
    true
),
(
    '0000005b-0000-4005-8000-0000005b0000',
    'Greek Restaurant 91',
    '99 Greek Street, Area 1',
    40.6918990,
    -74.0438610,
    true
),
(
    '0000005c-0000-4005-8000-0000005c0000',
    'Spanish Restaurant 92',
    '638 Spanish Street, Area 1',
    40.7133154,
    -74.0038319,
    true
),
(
    '0000005d-0000-4005-8000-0000005d0000',
    'Turkish Restaurant 93',
    '8005 Turkish Street, Area 1',
    40.6847070,
    -73.9682079,
    true
),
(
    '0000005e-0000-4005-8000-0000005e0000',
    'Lebanese Restaurant 94',
    '2986 Lebanese Street, Area 1',
    40.6808912,
    -73.9868069,
    true
),
(
    '0000005f-0000-4005-8000-0000005f0000',
    'Brazilian Restaurant 95',
    '5499 Brazilian Street, Area 1',
    40.7404499,
    -74.0259668,
    true
),
(
    '00000060-0000-4006-8000-000000600000',
    'German Restaurant 96',
    '108 German Street, Area 1',
    40.6643611,
    -73.9746463,
    true
),
(
    '00000061-0000-4006-8000-000000610000',
    'British Restaurant 97',
    '2837 British Street, Area 1',
    40.6658629,
    -74.0331372,
    true
),
(
    '00000062-0000-4006-8000-000000620000',
    'Caribbean Restaurant 98',
    '7598 Caribbean Street, Area 1',
    40.6808145,
    -73.9640024,
    true
),
(
    '00000063-0000-4006-8000-000000630000',
    'Fusion Restaurant 99',
    '4532 Fusion Street, Area 1',
    40.7546250,
    -73.9858295,
    true
),
(
    '00000064-0000-4006-8000-000000640000',
    'Italian Restaurant 100',
    '552 Italian Street, Area 2',
    40.7180732,
    -74.0243249,
    true
),
(
    '00000065-0000-4006-8000-000000650000',
    'Chinese Restaurant 101',
    '6902 Chinese Street, Area 2',
    40.7448697,
    -74.0125268,
    true
),
(
    '00000066-0000-4006-8000-000000660000',
    'Mexican Restaurant 102',
    '855 Mexican Street, Area 2',
    40.6966688,
    -74.0059657,
    true
),
(
    '00000067-0000-4006-8000-000000670000',
    'Indian Restaurant 103',
    '7918 Indian Street, Area 2',
    40.7600616,
    -73.9696831,
    true
),
(
    '00000068-0000-4006-8000-000000680000',
    'Japanese Restaurant 104',
    '2800 Japanese Street, Area 2',
    40.6794927,
    -73.9786665,
    true
),
(
    '00000069-0000-4006-8000-000000690000',
    'Thai Restaurant 105',
    '2921 Thai Street, Area 2',
    40.7538545,
    -73.9697953,
    false
),
(
    '0000006a-0000-4006-8000-0000006a0000',
    'American Restaurant 106',
    '6954 American Street, Area 2',
    40.7571759,
    -73.9678686,
    true
),
(
    '0000006b-0000-4006-8000-0000006b0000',
    'French Restaurant 107',
    '1219 French Street, Area 2',
    40.7437281,
    -73.9859297,
    true
),
(
    '0000006c-0000-4006-8000-0000006c0000',
    'Mediterranean Restaurant 108',
    '5709 Mediterranean Street, Area 2',
    40.7538930,
    -74.0529991,
    true
),
(
    '0000006d-0000-4006-8000-0000006d0000',
    'Korean Restaurant 109',
    '1273 Korean Street, Area 2',
    40.7068199,
    -74.0481932,
    true
),
(
    '0000006e-0000-4006-8000-0000006e0000',
    'Vietnamese Restaurant 110',
    '180 Vietnamese Street, Area 2',
    40.6845900,
    -73.9807351,
    false
),
(
    '0000006f-0000-4006-8000-0000006f0000',
    'Greek Restaurant 111',
    '7945 Greek Street, Area 2',
    40.7034730,
    -74.0408506,
    true
),
(
    '00000070-0000-4007-8000-000000700000',
    'Spanish Restaurant 112',
    '6418 Spanish Street, Area 2',
    40.6672094,
    -73.9733137,
    true
),
(
    '00000071-0000-4007-8000-000000710000',
    'Turkish Restaurant 113',
    '323 Turkish Street, Area 2',
    40.6633862,
    -73.9943510,
    true
),
(
    '00000072-0000-4007-8000-000000720000',
    'Lebanese Restaurant 114',
    '4316 Lebanese Street, Area 2',
    40.7410187,
    -73.9962831,
    true
),
(
    '00000073-0000-4007-8000-000000730000',
    'Brazilian Restaurant 115',
    '8789 Brazilian Street, Area 2',
    40.7501986,
    -74.0266791,
    true
),
(
    '00000074-0000-4007-8000-000000740000',
    'German Restaurant 116',
    '6049 German Street, Area 2',
    40.7325669,
    -73.9764396,
    true
),
(
    '00000075-0000-4007-8000-000000750000',
    'British Restaurant 117',
    '3409 British Street, Area 2',
    40.6827409,
    -74.0435383,
    true
),
(
    '00000076-0000-4007-8000-000000760000',
    'Caribbean Restaurant 118',
    '4065 Caribbean Street, Area 2',
    40.7199237,
    -74.0063757,
    true
),
(
    '00000077-0000-4007-8000-000000770000',
    'Fusion Restaurant 119',
    '549 Fusion Street, Area 2',
    40.6930413,
    -74.0311817,
    true
),
(
    '00000078-0000-4007-8000-000000780000',
    'Italian Restaurant 120',
    '1334 Italian Street, Area 2',
    40.6947645,
    -73.9854784,
    true
),
(
    '00000079-0000-4007-8000-000000790000',
    'Chinese Restaurant 121',
    '6268 Chinese Street, Area 2',
    40.6757281,
    -74.0400578,
    true
),
(
    '0000007a-0000-4007-8000-0000007a0000',
    'Mexican Restaurant 122',
    '7372 Mexican Street, Area 2',
    40.7229672,
    -74.0175375,
    true
),
(
    '0000007b-0000-4007-8000-0000007b0000',
    'Indian Restaurant 123',
    '3687 Indian Street, Area 2',
    40.7166210,
    -74.0274890,
    true
),
(
    '0000007c-0000-4007-8000-0000007c0000',
    'Japanese Restaurant 124',
    '2245 Japanese Street, Area 2',
    40.7317358,
    -73.9667023,
    true
),
(
    '0000007d-0000-4007-8000-0000007d0000',
    'Thai Restaurant 125',
    '5123 Thai Street, Area 2',
    40.6852624,
    -74.0250142,
    true
),
(
    '0000007e-0000-4007-8000-0000007e0000',
    'American Restaurant 126',
    '8470 American Street, Area 2',
    40.6715768,
    -74.0101221,
    true
),
(
    '0000007f-0000-4007-8000-0000007f0000',
    'French Restaurant 127',
    '4238 French Street, Area 2',
    40.6709445,
    -74.0159921,
    true
),
(
    '00000080-0000-4008-8000-000000800000',
    'Mediterranean Restaurant 128',
    '8968 Mediterranean Street, Area 2',
    40.7203655,
    -74.0344498,
    true
),
(
    '00000081-0000-4008-8000-000000810000',
    'Korean Restaurant 129',
    '5282 Korean Street, Area 2',
    40.6919317,
    -73.9799161,
    true
),
(
    '00000082-0000-4008-8000-000000820000',
    'Vietnamese Restaurant 130',
    '7336 Vietnamese Street, Area 2',
    40.7518409,
    -73.9640846,
    true
),
(
    '00000083-0000-4008-8000-000000830000',
    'Greek Restaurant 131',
    '4028 Greek Street, Area 2',
    40.6752050,
    -73.9659837,
    true
),
(
    '00000084-0000-4008-8000-000000840000',
    'Spanish Restaurant 132',
    '4922 Spanish Street, Area 2',
    40.6822407,
    -73.9851263,
    true
),
(
    '00000085-0000-4008-8000-000000850000',
    'Turkish Restaurant 133',
    '7791 Turkish Street, Area 2',
    40.7566610,
    -74.0505040,
    true
),
(
    '00000086-0000-4008-8000-000000860000',
    'Lebanese Restaurant 134',
    '9410 Lebanese Street, Area 2',
    40.7265616,
    -73.9689991,
    true
),
(
    '00000087-0000-4008-8000-000000870000',
    'Brazilian Restaurant 135',
    '6134 Brazilian Street, Area 2',
    40.7051746,
    -74.0041327,
    true
),
(
    '00000088-0000-4008-8000-000000880000',
    'German Restaurant 136',
    '4831 German Street, Area 2',
    40.6906031,
    -73.9983453,
    false
),
(
    '00000089-0000-4008-8000-000000890000',
    'British Restaurant 137',
    '5117 British Street, Area 2',
    40.7420316,
    -73.9743592,
    true
),
(
    '0000008a-0000-4008-8000-0000008a0000',
    'Caribbean Restaurant 138',
    '1567 Caribbean Street, Area 2',
    40.7545567,
    -74.0248783,
    true
),
(
    '0000008b-0000-4008-8000-0000008b0000',
    'Fusion Restaurant 139',
    '6464 Fusion Street, Area 2',
    40.7290638,
    -74.0360034,
    true
),
(
    '0000008c-0000-4008-8000-0000008c0000',
    'Italian Restaurant 140',
    '5663 Italian Street, Area 2',
    40.6751715,
    -74.0202297,
    true
),
(
    '0000008d-0000-4008-8000-0000008d0000',
    'Chinese Restaurant 141',
    '8880 Chinese Street, Area 2',
    40.6973854,
    -74.0380777,
    true
),
(
    '0000008e-0000-4008-8000-0000008e0000',
    'Mexican Restaurant 142',
    '6846 Mexican Street, Area 2',
    40.7356427,
    -74.0009103,
    false
),
(
    '0000008f-0000-4008-8000-0000008f0000',
    'Indian Restaurant 143',
    '2440 Indian Street, Area 2',
    40.7444621,
    -74.0056361,
    true
),
(
    '00000090-0000-4009-8000-000000900000',
    'Japanese Restaurant 144',
    '291 Japanese Street, Area 2',
    40.6982044,
    -73.9764854,
    true
),
(
    '00000091-0000-4009-8000-000000910000',
    'Thai Restaurant 145',
    '825 Thai Street, Area 2',
    40.6955630,
    -74.0396510,
    true
),
(
    '00000092-0000-4009-8000-000000920000',
    'American Restaurant 146',
    '6267 American Street, Area 2',
    40.7560284,
    -74.0469129,
    true
),
(
    '00000093-0000-4009-8000-000000930000',
    'French Restaurant 147',
    '1686 French Street, Area 2',
    40.6722010,
    -74.0065877,
    true
),
(
    '00000094-0000-4009-8000-000000940000',
    'Mediterranean Restaurant 148',
    '5845 Mediterranean Street, Area 2',
    40.7370134,
    -73.9967856,
    true
),
(
    '00000095-0000-4009-8000-000000950000',
    'Korean Restaurant 149',
    '3392 Korean Street, Area 2',
    40.7432417,
    -73.9905909,
    true
),
(
    '00000096-0000-4009-8000-000000960000',
    'Vietnamese Restaurant 150',
    '8172 Vietnamese Street, Area 2',
    40.7326305,
    -73.9733496,
    true
),
(
    '00000097-0000-4009-8000-000000970000',
    'Greek Restaurant 151',
    '2352 Greek Street, Area 2',
    40.6654124,
    -73.9859985,
    true
),
(
    '00000098-0000-4009-8000-000000980000',
    'Spanish Restaurant 152',
    '4370 Spanish Street, Area 2',
    40.6902787,
    -74.0471094,
    true
),
(
    '00000099-0000-4009-8000-000000990000',
    'Turkish Restaurant 153',
    '501 Turkish Street, Area 2',
    40.6987066,
    -73.9674918,
    true
),
(
    '0000009a-0000-4009-8000-0000009a0000',
    'Lebanese Restaurant 154',
    '7479 Lebanese Street, Area 2',
    40.7455200,
    -73.9775412,
    true
),
(
    '0000009b-0000-4009-8000-0000009b0000',
    'Brazilian Restaurant 155',
    '6511 Brazilian Street, Area 2',
    40.7338093,
    -73.9835789,
    true
),
(
    '0000009c-0000-4009-8000-0000009c0000',
    'German Restaurant 156',
    '7592 German Street, Area 2',
    40.7086831,
    -73.9883867,
    true
),
(
    '0000009d-0000-4009-8000-0000009d0000',
    'British Restaurant 157',
    '1877 British Street, Area 2',
    40.6866055,
    -73.9580399,
    true
),
(
    '0000009e-0000-4009-8000-0000009e0000',
    'Caribbean Restaurant 158',
    '6533 Caribbean Street, Area 2',
    40.7168734,
    -73.9736586,
    true
),
(
    '0000009f-0000-4009-8000-0000009f0000',
    'Fusion Restaurant 159',
    '4345 Fusion Street, Area 2',
    40.6987661,
    -74.0488469,
    true
),
(
    '000000a0-0000-400a-8000-000000a00000',
    'Italian Restaurant 160',
    '8834 Italian Street, Area 2',
    40.7046583,
    -74.0542420,
    true
),
(
    '000000a1-0000-400a-8000-000000a10000',
    'Chinese Restaurant 161',
    '6881 Chinese Street, Area 2',
    40.7077200,
    -73.9994170,
    true
),
(
    '000000a2-0000-400a-8000-000000a20000',
    'Mexican Restaurant 162',
    '4821 Mexican Street, Area 2',
    40.7317294,
    -73.9985854,
    true
),
(
    '000000a3-0000-400a-8000-000000a30000',
    'Indian Restaurant 163',
    '6659 Indian Street, Area 2',
    40.7115487,
    -74.0000194,
    true
),
(
    '000000a4-0000-400a-8000-000000a40000',
    'Japanese Restaurant 164',
    '4487 Japanese Street, Area 2',
    40.6947673,
    -73.9578998,
    true
),
(
    '000000a5-0000-400a-8000-000000a50000',
    'Thai Restaurant 165',
    '4352 Thai Street, Area 2',
    40.6810896,
    -73.9919153,
    true
),
(
    '000000a6-0000-400a-8000-000000a60000',
    'American Restaurant 166',
    '3079 American Street, Area 2',
    40.7070766,
    -74.0187023,
    true
),
(
    '000000a7-0000-400a-8000-000000a70000',
    'French Restaurant 167',
    '7412 French Street, Area 2',
    40.7015866,
    -74.0051900,
    true
),
(
    '000000a8-0000-400a-8000-000000a80000',
    'Mediterranean Restaurant 168',
    '8830 Mediterranean Street, Area 2',
    40.6982549,
    -73.9910803,
    true
),
(
    '000000a9-0000-400a-8000-000000a90000',
    'Korean Restaurant 169',
    '5734 Korean Street, Area 2',
    40.7460837,
    -74.0388226,
    true
),
(
    '000000aa-0000-400a-8000-000000aa0000',
    'Vietnamese Restaurant 170',
    '1505 Vietnamese Street, Area 2',
    40.6986089,
    -74.0378360,
    true
),
(
    '000000ab-0000-400a-8000-000000ab0000',
    'Greek Restaurant 171',
    '9878 Greek Street, Area 2',
    40.7092403,
    -74.0537077,
    true
),
(
    '000000ac-0000-400a-8000-000000ac0000',
    'Spanish Restaurant 172',
    '5009 Spanish Street, Area 2',
    40.6645355,
    -73.9884198,
    true
),
(
    '000000ad-0000-400a-8000-000000ad0000',
    'Turkish Restaurant 173',
    '4167 Turkish Street, Area 2',
    40.7269015,
    -73.9961711,
    true
),
(
    '000000ae-0000-400a-8000-000000ae0000',
    'Lebanese Restaurant 174',
    '2095 Lebanese Street, Area 2',
    40.7567154,
    -73.9724809,
    true
),
(
    '000000af-0000-400a-8000-000000af0000',
    'Brazilian Restaurant 175',
    '5701 Brazilian Street, Area 2',
    40.7048428,
    -73.9861647,
    true
),
(
    '000000b0-0000-400b-8000-000000b00000',
    'German Restaurant 176',
    '4717 German Street, Area 2',
    40.7210320,
    -74.0314339,
    true
),
(
    '000000b1-0000-400b-8000-000000b10000',
    'British Restaurant 177',
    '3099 British Street, Area 2',
    40.6912198,
    -73.9857734,
    true
),
(
    '000000b2-0000-400b-8000-000000b20000',
    'Caribbean Restaurant 178',
    '1101 Caribbean Street, Area 2',
    40.7027810,
    -74.0146299,
    true
),
(
    '000000b3-0000-400b-8000-000000b30000',
    'Fusion Restaurant 179',
    '2515 Fusion Street, Area 2',
    40.7010130,
    -73.9860619,
    true
),
(
    '000000b4-0000-400b-8000-000000b40000',
    'Italian Restaurant 180',
    '5786 Italian Street, Area 2',
    40.7403491,
    -74.0340161,
    true
),
(
    '000000b5-0000-400b-8000-000000b50000',
    'Chinese Restaurant 181',
    '5837 Chinese Street, Area 2',
    40.7390733,
    -74.0146836,
    true
),
(
    '000000b6-0000-400b-8000-000000b60000',
    'Mexican Restaurant 182',
    '4360 Mexican Street, Area 2',
    40.6761861,
    -73.9849860,
    true
),
(
    '000000b7-0000-400b-8000-000000b70000',
    'Indian Restaurant 183',
    '208 Indian Street, Area 2',
    40.7548372,
    -74.0314455,
    false
),
(
    '000000b8-0000-400b-8000-000000b80000',
    'Japanese Restaurant 184',
    '2673 Japanese Street, Area 2',
    40.6644953,
    -74.0026281,
    true
),
(
    '000000b9-0000-400b-8000-000000b90000',
    'Thai Restaurant 185',
    '3940 Thai Street, Area 2',
    40.7352440,
    -74.0238041,
    true
),
(
    '000000ba-0000-400b-8000-000000ba0000',
    'American Restaurant 186',
    '281 American Street, Area 2',
    40.7597975,
    -74.0000348,
    true
),
(
    '000000bb-0000-400b-8000-000000bb0000',
    'French Restaurant 187',
    '136 French Street, Area 2',
    40.7385025,
    -73.9810357,
    true
),
(
    '000000bc-0000-400b-8000-000000bc0000',
    'Mediterranean Restaurant 188',
    '6889 Mediterranean Street, Area 2',
    40.6723364,
    -74.0511031,
    true
),
(
    '000000bd-0000-400b-8000-000000bd0000',
    'Korean Restaurant 189',
    '8467 Korean Street, Area 2',
    40.7605568,
    -73.9574022,
    true
),
(
    '000000be-0000-400b-8000-000000be0000',
    'Vietnamese Restaurant 190',
    '9762 Vietnamese Street, Area 2',
    40.6983335,
    -73.9761990,
    true
),
(
    '000000bf-0000-400b-8000-000000bf0000',
    'Greek Restaurant 191',
    '2395 Greek Street, Area 2',
    40.7144888,
    -73.9778063,
    true
),
(
    '000000c0-0000-400c-8000-000000c00000',
    'Spanish Restaurant 192',
    '7107 Spanish Street, Area 2',
    40.6883065,
    -74.0185787,
    true
),
(
    '000000c1-0000-400c-8000-000000c10000',
    'Turkish Restaurant 193',
    '6584 Turkish Street, Area 2',
    40.7290925,
    -74.0270229,
    true
),
(
    '000000c2-0000-400c-8000-000000c20000',
    'Lebanese Restaurant 194',
    '3653 Lebanese Street, Area 2',
    40.6790352,
    -74.0011949,
    true
),
(
    '000000c3-0000-400c-8000-000000c30000',
    'Brazilian Restaurant 195',
    '9332 Brazilian Street, Area 2',
    40.7054558,
    -73.9689756,
    true
),
(
    '000000c4-0000-400c-8000-000000c40000',
    'German Restaurant 196',
    '3522 German Street, Area 2',
    40.7116201,
    -73.9891807,
    false
),
(
    '000000c5-0000-400c-8000-000000c50000',
    'British Restaurant 197',
    '1393 British Street, Area 2',
    40.7319855,
    -73.9944346,
    true
),
(
    '000000c6-0000-400c-8000-000000c60000',
    'Caribbean Restaurant 198',
    '6989 Caribbean Street, Area 2',
    40.6829556,
    -73.9919527,
    false
),
(
    '000000c7-0000-400c-8000-000000c70000',
    'Fusion Restaurant 199',
    '9569 Fusion Street, Area 2',
    40.7585118,
    -74.0273284,
    true
),
(
    '000000c8-0000-400c-8000-000000c80000',
    'Italian Restaurant 200',
    '7553 Italian Street, Area 3',
    40.6679473,
    -74.0225843,
    true
);

-- Menu Categories
INSERT INTO menu_categories (id, restaurant_id, name, display_order) VALUES
(
    '000f4240-000f-4424-8000-000f4240000f',
    '00000001-0000-4000-8000-000000010000',
    'Dim Sum',
    1
),
(
    '000f4241-000f-4424-8000-000f4241000f',
    '00000001-0000-4000-8000-000000010000',
    'Noodles',
    2
),
(
    '000f4242-000f-4424-8000-000f4242000f',
    '00000001-0000-4000-8000-000000010000',
    'Rice Dishes',
    3
),
(
    '000f4243-000f-4424-8000-000f4243000f',
    '00000002-0000-4000-8000-000000020000',
    'Tacos',
    1
),
(
    '000f4244-000f-4424-8000-000f4244000f',
    '00000002-0000-4000-8000-000000020000',
    'Burritos',
    2
),
(
    '000f4245-000f-4424-8000-000f4245000f',
    '00000002-0000-4000-8000-000000020000',
    'Quesadillas',
    3
),
(
    '000f4246-000f-4424-8000-000f4246000f',
    '00000003-0000-4000-8000-000000030000',
    'Curries',
    1
),
(
    '000f4247-000f-4424-8000-000f4247000f',
    '00000003-0000-4000-8000-000000030000',
    'Biryani',
    2
),
(
    '000f4248-000f-4424-8000-000f4248000f',
    '00000003-0000-4000-8000-000000030000',
    'Breads',
    3
),
(
    '000f4249-000f-4424-8000-000f4249000f',
    '00000004-0000-4000-8000-000000040000',
    'Sushi',
    1
),
(
    '000f424a-000f-4424-8000-000f424a000f',
    '00000004-0000-4000-8000-000000040000',
    'Ramen',
    2
),
(
    '000f424b-000f-4424-8000-000f424b000f',
    '00000005-0000-4000-8000-000000050000',
    'Curries',
    1
),
(
    '000f424c-000f-4424-8000-000f424c000f',
    '00000005-0000-4000-8000-000000050000',
    'Noodles',
    2
),
(
    '000f424d-000f-4424-8000-000f424d000f',
    '00000005-0000-4000-8000-000000050000',
    'Stir Fries',
    3
),
(
    '000f424e-000f-4424-8000-000f424e000f',
    '00000005-0000-4000-8000-000000050000',
    'Appetizers',
    4
),
(
    '000f424f-000f-4424-8000-000f424f000f',
    '00000006-0000-4000-8000-000000060000',
    'Burgers',
    1
),
(
    '000f4250-000f-4425-8000-000f4250000f',
    '00000006-0000-4000-8000-000000060000',
    'Sandwiches',
    2
),
(
    '000f4251-000f-4425-8000-000f4251000f',
    '00000006-0000-4000-8000-000000060000',
    'Salads',
    3
),
(
    '000f4252-000f-4425-8000-000f4252000f',
    '00000007-0000-4000-8000-000000070000',
    'Entrees',
    1
),
(
    '000f4253-000f-4425-8000-000f4253000f',
    '00000007-0000-4000-8000-000000070000',
    'Soups',
    2
),
(
    '000f4254-000f-4425-8000-000f4254000f',
    '00000007-0000-4000-8000-000000070000',
    'Salads',
    3
),
(
    '000f4255-000f-4425-8000-000f4255000f',
    '00000007-0000-4000-8000-000000070000',
    'Desserts',
    4
),
(
    '000f4256-000f-4425-8000-000f4256000f',
    '00000008-0000-4000-8000-000000080000',
    'Mezze',
    1
),
(
    '000f4257-000f-4425-8000-000f4257000f',
    '00000008-0000-4000-8000-000000080000',
    'Grills',
    2
),
(
    '000f4258-000f-4425-8000-000f4258000f',
    '00000009-0000-4000-8000-000000090000',
    'BBQ',
    1
),
(
    '000f4259-000f-4425-8000-000f4259000f',
    '00000009-0000-4000-8000-000000090000',
    'Rice Bowls',
    2
),
(
    '000f425a-000f-4425-8000-000f425a000f',
    '00000009-0000-4000-8000-000000090000',
    'Noodles',
    3
),
(
    '000f425b-000f-4425-8000-000f425b000f',
    '00000009-0000-4000-8000-000000090000',
    'Appetizers',
    4
),
(
    '000f425c-000f-4425-8000-000f425c000f',
    '0000000a-0000-4000-8000-0000000a0000',
    'Pho',
    1
),
(
    '000f425d-000f-4425-8000-000f425d000f',
    '0000000a-0000-4000-8000-0000000a0000',
    'Banh Mi',
    2
),
(
    '000f425e-000f-4425-8000-000f425e000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Gyros',
    1
),
(
    '000f425f-000f-4425-8000-000f425f000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Souvlaki',
    2
),
(
    '000f4260-000f-4426-8000-000f4260000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Salads',
    3
),
(
    '000f4261-000f-4426-8000-000f4261000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Tapas',
    1
),
(
    '000f4262-000f-4426-8000-000f4262000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Paella',
    2
),
(
    '000f4263-000f-4426-8000-000f4263000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Soups',
    3
),
(
    '000f4264-000f-4426-8000-000f4264000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Kebabs',
    1
),
(
    '000f4265-000f-4426-8000-000f4265000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Mezze',
    2
),
(
    '000f4266-000f-4426-8000-000f4266000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Grills',
    3
),
(
    '000f4267-000f-4426-8000-000f4267000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Desserts',
    4
),
(
    '000f4268-000f-4426-8000-000f4268000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Mezze',
    1
),
(
    '000f4269-000f-4426-8000-000f4269000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Grills',
    2
),
(
    '000f426a-000f-4426-8000-000f426a000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Salads',
    3
),
(
    '000f426b-000f-4426-8000-000f426b000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Grills',
    1
),
(
    '000f426c-000f-4426-8000-000f426c000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Rice Dishes',
    2
),
(
    '000f426d-000f-4426-8000-000f426d000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Appetizers',
    3
),
(
    '000f426e-000f-4426-8000-000f426e000f',
    '00000010-0000-4001-8000-000000100000',
    'Schnitzel',
    1
),
(
    '000f426f-000f-4426-8000-000f426f000f',
    '00000010-0000-4001-8000-000000100000',
    'Sausages',
    2
),
(
    '000f4270-000f-4427-8000-000f4270000f',
    '00000011-0000-4001-8000-000000110000',
    'Fish & Chips',
    1
),
(
    '000f4271-000f-4427-8000-000f4271000f',
    '00000011-0000-4001-8000-000000110000',
    'Pies',
    2
),
(
    '000f4272-000f-4427-8000-000f4272000f',
    '00000011-0000-4001-8000-000000110000',
    'Sides',
    3
),
(
    '000f4273-000f-4427-8000-000f4273000f',
    '00000011-0000-4001-8000-000000110000',
    'Desserts',
    4
),
(
    '000f4274-000f-4427-8000-000f4274000f',
    '00000012-0000-4001-8000-000000120000',
    'Jerk',
    1
),
(
    '000f4275-000f-4427-8000-000f4275000f',
    '00000012-0000-4001-8000-000000120000',
    'Rice Dishes',
    2
),
(
    '000f4276-000f-4427-8000-000f4276000f',
    '00000012-0000-4001-8000-000000120000',
    'Soups',
    3
),
(
    '000f4277-000f-4427-8000-000f4277000f',
    '00000012-0000-4001-8000-000000120000',
    'Desserts',
    4
),
(
    '000f4278-000f-4427-8000-000f4278000f',
    '00000013-0000-4001-8000-000000130000',
    'Specialties',
    1
),
(
    '000f4279-000f-4427-8000-000f4279000f',
    '00000013-0000-4001-8000-000000130000',
    'Appetizers',
    2
),
(
    '000f427a-000f-4427-8000-000f427a000f',
    '00000014-0000-4001-8000-000000140000',
    'Pizzas',
    1
),
(
    '000f427b-000f-4427-8000-000f427b000f',
    '00000014-0000-4001-8000-000000140000',
    'Pastas',
    2
),
(
    '000f427c-000f-4427-8000-000f427c000f',
    '00000014-0000-4001-8000-000000140000',
    'Appetizers',
    3
),
(
    '000f427d-000f-4427-8000-000f427d000f',
    '00000015-0000-4001-8000-000000150000',
    'Dim Sum',
    1
),
(
    '000f427e-000f-4427-8000-000f427e000f',
    '00000015-0000-4001-8000-000000150000',
    'Noodles',
    2
),
(
    '000f427f-000f-4427-8000-000f427f000f',
    '00000015-0000-4001-8000-000000150000',
    'Rice Dishes',
    3
),
(
    '000f4280-000f-4428-8000-000f4280000f',
    '00000016-0000-4001-8000-000000160000',
    'Tacos',
    1
),
(
    '000f4281-000f-4428-8000-000f4281000f',
    '00000016-0000-4001-8000-000000160000',
    'Burritos',
    2
),
(
    '000f4282-000f-4428-8000-000f4282000f',
    '00000016-0000-4001-8000-000000160000',
    'Quesadillas',
    3
),
(
    '000f4283-000f-4428-8000-000f4283000f',
    '00000017-0000-4001-8000-000000170000',
    'Curries',
    1
),
(
    '000f4284-000f-4428-8000-000f4284000f',
    '00000017-0000-4001-8000-000000170000',
    'Biryani',
    2
),
(
    '000f4285-000f-4428-8000-000f4285000f',
    '00000017-0000-4001-8000-000000170000',
    'Breads',
    3
),
(
    '000f4286-000f-4428-8000-000f4286000f',
    '00000018-0000-4001-8000-000000180000',
    'Sushi',
    1
),
(
    '000f4287-000f-4428-8000-000f4287000f',
    '00000018-0000-4001-8000-000000180000',
    'Ramen',
    2
),
(
    '000f4288-000f-4428-8000-000f4288000f',
    '00000019-0000-4001-8000-000000190000',
    'Curries',
    1
),
(
    '000f4289-000f-4428-8000-000f4289000f',
    '00000019-0000-4001-8000-000000190000',
    'Noodles',
    2
),
(
    '000f428a-000f-4428-8000-000f428a000f',
    '00000019-0000-4001-8000-000000190000',
    'Stir Fries',
    3
),
(
    '000f428b-000f-4428-8000-000f428b000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Burgers',
    1
),
(
    '000f428c-000f-4428-8000-000f428c000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Sandwiches',
    2
),
(
    '000f428d-000f-4428-8000-000f428d000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Salads',
    3
),
(
    '000f428e-000f-4428-8000-000f428e000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Sides',
    4
),
(
    '000f428f-000f-4428-8000-000f428f000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Entrees',
    1
),
(
    '000f4290-000f-4429-8000-000f4290000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Soups',
    2
),
(
    '000f4291-000f-4429-8000-000f4291000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Salads',
    3
),
(
    '000f4292-000f-4429-8000-000f4292000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Desserts',
    4
),
(
    '000f4293-000f-4429-8000-000f4293000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Mezze',
    1
),
(
    '000f4294-000f-4429-8000-000f4294000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Grills',
    2
),
(
    '000f4295-000f-4429-8000-000f4295000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Salads',
    3
),
(
    '000f4296-000f-4429-8000-000f4296000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'BBQ',
    1
),
(
    '000f4297-000f-4429-8000-000f4297000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Rice Bowls',
    2
),
(
    '000f4298-000f-4429-8000-000f4298000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Noodles',
    3
),
(
    '000f4299-000f-4429-8000-000f4299000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Pho',
    1
),
(
    '000f429a-000f-4429-8000-000f429a000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Banh Mi',
    2
),
(
    '000f429b-000f-4429-8000-000f429b000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Rice Dishes',
    3
),
(
    '000f429c-000f-4429-8000-000f429c000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Appetizers',
    4
),
(
    '000f429d-000f-4429-8000-000f429d000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Gyros',
    1
),
(
    '000f429e-000f-4429-8000-000f429e000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Souvlaki',
    2
),
(
    '000f429f-000f-4429-8000-000f429f000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Salads',
    3
),
(
    '000f42a0-000f-442a-8000-000f42a0000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Desserts',
    4
),
(
    '000f42a1-000f-442a-8000-000f42a1000f',
    '00000020-0000-4002-8000-000000200000',
    'Tapas',
    1
),
(
    '000f42a2-000f-442a-8000-000f42a2000f',
    '00000020-0000-4002-8000-000000200000',
    'Paella',
    2
),
(
    '000f42a3-000f-442a-8000-000f42a3000f',
    '00000021-0000-4002-8000-000000210000',
    'Kebabs',
    1
),
(
    '000f42a4-000f-442a-8000-000f42a4000f',
    '00000021-0000-4002-8000-000000210000',
    'Mezze',
    2
),
(
    '000f42a5-000f-442a-8000-000f42a5000f',
    '00000021-0000-4002-8000-000000210000',
    'Grills',
    3
),
(
    '000f42a6-000f-442a-8000-000f42a6000f',
    '00000021-0000-4002-8000-000000210000',
    'Desserts',
    4
),
(
    '000f42a7-000f-442a-8000-000f42a7000f',
    '00000022-0000-4002-8000-000000220000',
    'Mezze',
    1
),
(
    '000f42a8-000f-442a-8000-000f42a8000f',
    '00000022-0000-4002-8000-000000220000',
    'Grills',
    2
),
(
    '000f42a9-000f-442a-8000-000f42a9000f',
    '00000022-0000-4002-8000-000000220000',
    'Salads',
    3
),
(
    '000f42aa-000f-442a-8000-000f42aa000f',
    '00000022-0000-4002-8000-000000220000',
    'Desserts',
    4
),
(
    '000f42ab-000f-442a-8000-000f42ab000f',
    '00000023-0000-4002-8000-000000230000',
    'Grills',
    1
),
(
    '000f42ac-000f-442a-8000-000f42ac000f',
    '00000023-0000-4002-8000-000000230000',
    'Rice Dishes',
    2
),
(
    '000f42ad-000f-442a-8000-000f42ad000f',
    '00000024-0000-4002-8000-000000240000',
    'Schnitzel',
    1
),
(
    '000f42ae-000f-442a-8000-000f42ae000f',
    '00000024-0000-4002-8000-000000240000',
    'Sausages',
    2
),
(
    '000f42af-000f-442a-8000-000f42af000f',
    '00000025-0000-4002-8000-000000250000',
    'Fish & Chips',
    1
),
(
    '000f42b0-000f-442b-8000-000f42b0000f',
    '00000025-0000-4002-8000-000000250000',
    'Pies',
    2
),
(
    '000f42b1-000f-442b-8000-000f42b1000f',
    '00000025-0000-4002-8000-000000250000',
    'Sides',
    3
),
(
    '000f42b2-000f-442b-8000-000f42b2000f',
    '00000026-0000-4002-8000-000000260000',
    'Jerk',
    1
),
(
    '000f42b3-000f-442b-8000-000f42b3000f',
    '00000026-0000-4002-8000-000000260000',
    'Rice Dishes',
    2
),
(
    '000f42b4-000f-442b-8000-000f42b4000f',
    '00000026-0000-4002-8000-000000260000',
    'Soups',
    3
),
(
    '000f42b5-000f-442b-8000-000f42b5000f',
    '00000027-0000-4002-8000-000000270000',
    'Specialties',
    1
),
(
    '000f42b6-000f-442b-8000-000f42b6000f',
    '00000027-0000-4002-8000-000000270000',
    'Appetizers',
    2
),
(
    '000f42b7-000f-442b-8000-000f42b7000f',
    '00000027-0000-4002-8000-000000270000',
    'Sides',
    3
),
(
    '000f42b8-000f-442b-8000-000f42b8000f',
    '00000027-0000-4002-8000-000000270000',
    'Desserts',
    4
),
(
    '000f42b9-000f-442b-8000-000f42b9000f',
    '00000028-0000-4002-8000-000000280000',
    'Pizzas',
    1
),
(
    '000f42ba-000f-442b-8000-000f42ba000f',
    '00000028-0000-4002-8000-000000280000',
    'Pastas',
    2
),
(
    '000f42bb-000f-442b-8000-000f42bb000f',
    '00000028-0000-4002-8000-000000280000',
    'Appetizers',
    3
),
(
    '000f42bc-000f-442b-8000-000f42bc000f',
    '00000028-0000-4002-8000-000000280000',
    'Desserts',
    4
),
(
    '000f42bd-000f-442b-8000-000f42bd000f',
    '00000029-0000-4002-8000-000000290000',
    'Dim Sum',
    1
),
(
    '000f42be-000f-442b-8000-000f42be000f',
    '00000029-0000-4002-8000-000000290000',
    'Noodles',
    2
),
(
    '000f42bf-000f-442b-8000-000f42bf000f',
    '0000002a-0000-4002-8000-0000002a0000',
    'Tacos',
    1
),
(
    '000f42c0-000f-442c-8000-000f42c0000f',
    '0000002a-0000-4002-8000-0000002a0000',
    'Burritos',
    2
),
(
    '000f42c1-000f-442c-8000-000f42c1000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Curries',
    1
),
(
    '000f42c2-000f-442c-8000-000f42c2000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Biryani',
    2
),
(
    '000f42c3-000f-442c-8000-000f42c3000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Breads',
    3
),
(
    '000f42c4-000f-442c-8000-000f42c4000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Appetizers',
    4
),
(
    '000f42c5-000f-442c-8000-000f42c5000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Sushi',
    1
),
(
    '000f42c6-000f-442c-8000-000f42c6000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Ramen',
    2
),
(
    '000f42c7-000f-442c-8000-000f42c7000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Teriyaki',
    3
),
(
    '000f42c8-000f-442c-8000-000f42c8000f',
    '0000002d-0000-4002-8000-0000002d0000',
    'Curries',
    1
),
(
    '000f42c9-000f-442c-8000-000f42c9000f',
    '0000002d-0000-4002-8000-0000002d0000',
    'Noodles',
    2
),
(
    '000f42ca-000f-442c-8000-000f42ca000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Burgers',
    1
),
(
    '000f42cb-000f-442c-8000-000f42cb000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Sandwiches',
    2
),
(
    '000f42cc-000f-442c-8000-000f42cc000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Salads',
    3
),
(
    '000f42cd-000f-442c-8000-000f42cd000f',
    '0000002f-0000-4002-8000-0000002f0000',
    'Entrees',
    1
),
(
    '000f42ce-000f-442c-8000-000f42ce000f',
    '0000002f-0000-4002-8000-0000002f0000',
    'Soups',
    2
),
(
    '000f42cf-000f-442c-8000-000f42cf000f',
    '00000030-0000-4003-8000-000000300000',
    'Mezze',
    1
),
(
    '000f42d0-000f-442d-8000-000f42d0000f',
    '00000030-0000-4003-8000-000000300000',
    'Grills',
    2
),
(
    '000f42d1-000f-442d-8000-000f42d1000f',
    '00000030-0000-4003-8000-000000300000',
    'Salads',
    3
),
(
    '000f42d2-000f-442d-8000-000f42d2000f',
    '00000030-0000-4003-8000-000000300000',
    'Desserts',
    4
),
(
    '000f42d3-000f-442d-8000-000f42d3000f',
    '00000031-0000-4003-8000-000000310000',
    'BBQ',
    1
),
(
    '000f42d4-000f-442d-8000-000f42d4000f',
    '00000031-0000-4003-8000-000000310000',
    'Rice Bowls',
    2
),
(
    '000f42d5-000f-442d-8000-000f42d5000f',
    '00000032-0000-4003-8000-000000320000',
    'Pho',
    1
),
(
    '000f42d6-000f-442d-8000-000f42d6000f',
    '00000032-0000-4003-8000-000000320000',
    'Banh Mi',
    2
),
(
    '000f42d7-000f-442d-8000-000f42d7000f',
    '00000033-0000-4003-8000-000000330000',
    'Gyros',
    1
),
(
    '000f42d8-000f-442d-8000-000f42d8000f',
    '00000033-0000-4003-8000-000000330000',
    'Souvlaki',
    2
),
(
    '000f42d9-000f-442d-8000-000f42d9000f',
    '00000033-0000-4003-8000-000000330000',
    'Salads',
    3
),
(
    '000f42da-000f-442d-8000-000f42da000f',
    '00000034-0000-4003-8000-000000340000',
    'Tapas',
    1
),
(
    '000f42db-000f-442d-8000-000f42db000f',
    '00000034-0000-4003-8000-000000340000',
    'Paella',
    2
),
(
    '000f42dc-000f-442d-8000-000f42dc000f',
    '00000034-0000-4003-8000-000000340000',
    'Soups',
    3
),
(
    '000f42dd-000f-442d-8000-000f42dd000f',
    '00000035-0000-4003-8000-000000350000',
    'Kebabs',
    1
),
(
    '000f42de-000f-442d-8000-000f42de000f',
    '00000035-0000-4003-8000-000000350000',
    'Mezze',
    2
),
(
    '000f42df-000f-442d-8000-000f42df000f',
    '00000036-0000-4003-8000-000000360000',
    'Mezze',
    1
),
(
    '000f42e0-000f-442e-8000-000f42e0000f',
    '00000036-0000-4003-8000-000000360000',
    'Grills',
    2
),
(
    '000f42e1-000f-442e-8000-000f42e1000f',
    '00000037-0000-4003-8000-000000370000',
    'Grills',
    1
),
(
    '000f42e2-000f-442e-8000-000f42e2000f',
    '00000037-0000-4003-8000-000000370000',
    'Rice Dishes',
    2
),
(
    '000f42e3-000f-442e-8000-000f42e3000f',
    '00000037-0000-4003-8000-000000370000',
    'Appetizers',
    3
),
(
    '000f42e4-000f-442e-8000-000f42e4000f',
    '00000037-0000-4003-8000-000000370000',
    'Desserts',
    4
),
(
    '000f42e5-000f-442e-8000-000f42e5000f',
    '00000038-0000-4003-8000-000000380000',
    'Schnitzel',
    1
),
(
    '000f42e6-000f-442e-8000-000f42e6000f',
    '00000038-0000-4003-8000-000000380000',
    'Sausages',
    2
),
(
    '000f42e7-000f-442e-8000-000f42e7000f',
    '00000038-0000-4003-8000-000000380000',
    'Sides',
    3
),
(
    '000f42e8-000f-442e-8000-000f42e8000f',
    '00000038-0000-4003-8000-000000380000',
    'Desserts',
    4
),
(
    '000f42e9-000f-442e-8000-000f42e9000f',
    '00000039-0000-4003-8000-000000390000',
    'Fish & Chips',
    1
),
(
    '000f42ea-000f-442e-8000-000f42ea000f',
    '00000039-0000-4003-8000-000000390000',
    'Pies',
    2
),
(
    '000f42eb-000f-442e-8000-000f42eb000f',
    '00000039-0000-4003-8000-000000390000',
    'Sides',
    3
),
(
    '000f42ec-000f-442e-8000-000f42ec000f',
    '0000003a-0000-4003-8000-0000003a0000',
    'Jerk',
    1
),
(
    '000f42ed-000f-442e-8000-000f42ed000f',
    '0000003a-0000-4003-8000-0000003a0000',
    'Rice Dishes',
    2
),
(
    '000f42ee-000f-442e-8000-000f42ee000f',
    '0000003b-0000-4003-8000-0000003b0000',
    'Specialties',
    1
),
(
    '000f42ef-000f-442e-8000-000f42ef000f',
    '0000003b-0000-4003-8000-0000003b0000',
    'Appetizers',
    2
),
(
    '000f42f0-000f-442f-8000-000f42f0000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Pizzas',
    1
),
(
    '000f42f1-000f-442f-8000-000f42f1000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Pastas',
    2
),
(
    '000f42f2-000f-442f-8000-000f42f2000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Appetizers',
    3
),
(
    '000f42f3-000f-442f-8000-000f42f3000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Desserts',
    4
),
(
    '000f42f4-000f-442f-8000-000f42f4000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Dim Sum',
    1
),
(
    '000f42f5-000f-442f-8000-000f42f5000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Noodles',
    2
),
(
    '000f42f6-000f-442f-8000-000f42f6000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Rice Dishes',
    3
),
(
    '000f42f7-000f-442f-8000-000f42f7000f',
    '0000003e-0000-4003-8000-0000003e0000',
    'Tacos',
    1
),
(
    '000f42f8-000f-442f-8000-000f42f8000f',
    '0000003e-0000-4003-8000-0000003e0000',
    'Burritos',
    2
),
(
    '000f42f9-000f-442f-8000-000f42f9000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Curries',
    1
),
(
    '000f42fa-000f-442f-8000-000f42fa000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Biryani',
    2
),
(
    '000f42fb-000f-442f-8000-000f42fb000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Breads',
    3
),
(
    '000f42fc-000f-442f-8000-000f42fc000f',
    '00000040-0000-4004-8000-000000400000',
    'Sushi',
    1
),
(
    '000f42fd-000f-442f-8000-000f42fd000f',
    '00000040-0000-4004-8000-000000400000',
    'Ramen',
    2
),
(
    '000f42fe-000f-442f-8000-000f42fe000f',
    '00000040-0000-4004-8000-000000400000',
    'Teriyaki',
    3
),
(
    '000f42ff-000f-442f-8000-000f42ff000f',
    '00000040-0000-4004-8000-000000400000',
    'Appetizers',
    4
),
(
    '000f4300-000f-4430-8000-000f4300000f',
    '00000041-0000-4004-8000-000000410000',
    'Curries',
    1
),
(
    '000f4301-000f-4430-8000-000f4301000f',
    '00000041-0000-4004-8000-000000410000',
    'Noodles',
    2
),
(
    '000f4302-000f-4430-8000-000f4302000f',
    '00000041-0000-4004-8000-000000410000',
    'Stir Fries',
    3
),
(
    '000f4303-000f-4430-8000-000f4303000f',
    '00000041-0000-4004-8000-000000410000',
    'Appetizers',
    4
),
(
    '000f4304-000f-4430-8000-000f4304000f',
    '00000042-0000-4004-8000-000000420000',
    'Burgers',
    1
),
(
    '000f4305-000f-4430-8000-000f4305000f',
    '00000042-0000-4004-8000-000000420000',
    'Sandwiches',
    2
),
(
    '000f4306-000f-4430-8000-000f4306000f',
    '00000043-0000-4004-8000-000000430000',
    'Entrees',
    1
),
(
    '000f4307-000f-4430-8000-000f4307000f',
    '00000043-0000-4004-8000-000000430000',
    'Soups',
    2
),
(
    '000f4308-000f-4430-8000-000f4308000f',
    '00000043-0000-4004-8000-000000430000',
    'Salads',
    3
),
(
    '000f4309-000f-4430-8000-000f4309000f',
    '00000044-0000-4004-8000-000000440000',
    'Mezze',
    1
),
(
    '000f430a-000f-4430-8000-000f430a000f',
    '00000044-0000-4004-8000-000000440000',
    'Grills',
    2
),
(
    '000f430b-000f-4430-8000-000f430b000f',
    '00000044-0000-4004-8000-000000440000',
    'Salads',
    3
),
(
    '000f430c-000f-4430-8000-000f430c000f',
    '00000045-0000-4004-8000-000000450000',
    'BBQ',
    1
),
(
    '000f430d-000f-4430-8000-000f430d000f',
    '00000045-0000-4004-8000-000000450000',
    'Rice Bowls',
    2
),
(
    '000f430e-000f-4430-8000-000f430e000f',
    '00000046-0000-4004-8000-000000460000',
    'Pho',
    1
),
(
    '000f430f-000f-4430-8000-000f430f000f',
    '00000046-0000-4004-8000-000000460000',
    'Banh Mi',
    2
),
(
    '000f4310-000f-4431-8000-000f4310000f',
    '00000046-0000-4004-8000-000000460000',
    'Rice Dishes',
    3
),
(
    '000f4311-000f-4431-8000-000f4311000f',
    '00000047-0000-4004-8000-000000470000',
    'Gyros',
    1
),
(
    '000f4312-000f-4431-8000-000f4312000f',
    '00000047-0000-4004-8000-000000470000',
    'Souvlaki',
    2
),
(
    '000f4313-000f-4431-8000-000f4313000f',
    '00000048-0000-4004-8000-000000480000',
    'Tapas',
    1
),
(
    '000f4314-000f-4431-8000-000f4314000f',
    '00000048-0000-4004-8000-000000480000',
    'Paella',
    2
),
(
    '000f4315-000f-4431-8000-000f4315000f',
    '00000048-0000-4004-8000-000000480000',
    'Soups',
    3
),
(
    '000f4316-000f-4431-8000-000f4316000f',
    '00000048-0000-4004-8000-000000480000',
    'Desserts',
    4
),
(
    '000f4317-000f-4431-8000-000f4317000f',
    '00000049-0000-4004-8000-000000490000',
    'Kebabs',
    1
),
(
    '000f4318-000f-4431-8000-000f4318000f',
    '00000049-0000-4004-8000-000000490000',
    'Mezze',
    2
),
(
    '000f4319-000f-4431-8000-000f4319000f',
    '00000049-0000-4004-8000-000000490000',
    'Grills',
    3
),
(
    '000f431a-000f-4431-8000-000f431a000f',
    '0000004a-0000-4004-8000-0000004a0000',
    'Mezze',
    1
),
(
    '000f431b-000f-4431-8000-000f431b000f',
    '0000004a-0000-4004-8000-0000004a0000',
    'Grills',
    2
),
(
    '000f431c-000f-4431-8000-000f431c000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Grills',
    1
),
(
    '000f431d-000f-4431-8000-000f431d000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Rice Dishes',
    2
),
(
    '000f431e-000f-4431-8000-000f431e000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Appetizers',
    3
),
(
    '000f431f-000f-4431-8000-000f431f000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Desserts',
    4
),
(
    '000f4320-000f-4432-8000-000f4320000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Schnitzel',
    1
),
(
    '000f4321-000f-4432-8000-000f4321000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Sausages',
    2
),
(
    '000f4322-000f-4432-8000-000f4322000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Sides',
    3
),
(
    '000f4323-000f-4432-8000-000f4323000f',
    '0000004d-0000-4004-8000-0000004d0000',
    'Fish & Chips',
    1
),
(
    '000f4324-000f-4432-8000-000f4324000f',
    '0000004d-0000-4004-8000-0000004d0000',
    'Pies',
    2
),
(
    '000f4325-000f-4432-8000-000f4325000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Jerk',
    1
),
(
    '000f4326-000f-4432-8000-000f4326000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Rice Dishes',
    2
),
(
    '000f4327-000f-4432-8000-000f4327000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Soups',
    3
),
(
    '000f4328-000f-4432-8000-000f4328000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Desserts',
    4
),
(
    '000f4329-000f-4432-8000-000f4329000f',
    '0000004f-0000-4004-8000-0000004f0000',
    'Specialties',
    1
),
(
    '000f432a-000f-4432-8000-000f432a000f',
    '0000004f-0000-4004-8000-0000004f0000',
    'Appetizers',
    2
),
(
    '000f432b-000f-4432-8000-000f432b000f',
    '00000050-0000-4005-8000-000000500000',
    'Pizzas',
    1
),
(
    '000f432c-000f-4432-8000-000f432c000f',
    '00000050-0000-4005-8000-000000500000',
    'Pastas',
    2
),
(
    '000f432d-000f-4432-8000-000f432d000f',
    '00000051-0000-4005-8000-000000510000',
    'Dim Sum',
    1
),
(
    '000f432e-000f-4432-8000-000f432e000f',
    '00000051-0000-4005-8000-000000510000',
    'Noodles',
    2
),
(
    '000f432f-000f-4432-8000-000f432f000f',
    '00000052-0000-4005-8000-000000520000',
    'Tacos',
    1
),
(
    '000f4330-000f-4433-8000-000f4330000f',
    '00000052-0000-4005-8000-000000520000',
    'Burritos',
    2
),
(
    '000f4331-000f-4433-8000-000f4331000f',
    '00000053-0000-4005-8000-000000530000',
    'Curries',
    1
),
(
    '000f4332-000f-4433-8000-000f4332000f',
    '00000053-0000-4005-8000-000000530000',
    'Biryani',
    2
),
(
    '000f4333-000f-4433-8000-000f4333000f',
    '00000054-0000-4005-8000-000000540000',
    'Sushi',
    1
),
(
    '000f4334-000f-4433-8000-000f4334000f',
    '00000054-0000-4005-8000-000000540000',
    'Ramen',
    2
),
(
    '000f4335-000f-4433-8000-000f4335000f',
    '00000055-0000-4005-8000-000000550000',
    'Curries',
    1
),
(
    '000f4336-000f-4433-8000-000f4336000f',
    '00000055-0000-4005-8000-000000550000',
    'Noodles',
    2
),
(
    '000f4337-000f-4433-8000-000f4337000f',
    '00000055-0000-4005-8000-000000550000',
    'Stir Fries',
    3
),
(
    '000f4338-000f-4433-8000-000f4338000f',
    '00000056-0000-4005-8000-000000560000',
    'Burgers',
    1
),
(
    '000f4339-000f-4433-8000-000f4339000f',
    '00000056-0000-4005-8000-000000560000',
    'Sandwiches',
    2
),
(
    '000f433a-000f-4433-8000-000f433a000f',
    '00000056-0000-4005-8000-000000560000',
    'Salads',
    3
),
(
    '000f433b-000f-4433-8000-000f433b000f',
    '00000057-0000-4005-8000-000000570000',
    'Entrees',
    1
),
(
    '000f433c-000f-4433-8000-000f433c000f',
    '00000057-0000-4005-8000-000000570000',
    'Soups',
    2
),
(
    '000f433d-000f-4433-8000-000f433d000f',
    '00000057-0000-4005-8000-000000570000',
    'Salads',
    3
),
(
    '000f433e-000f-4433-8000-000f433e000f',
    '00000057-0000-4005-8000-000000570000',
    'Desserts',
    4
),
(
    '000f433f-000f-4433-8000-000f433f000f',
    '00000058-0000-4005-8000-000000580000',
    'Mezze',
    1
),
(
    '000f4340-000f-4434-8000-000f4340000f',
    '00000058-0000-4005-8000-000000580000',
    'Grills',
    2
),
(
    '000f4341-000f-4434-8000-000f4341000f',
    '00000058-0000-4005-8000-000000580000',
    'Salads',
    3
),
(
    '000f4342-000f-4434-8000-000f4342000f',
    '00000058-0000-4005-8000-000000580000',
    'Desserts',
    4
),
(
    '000f4343-000f-4434-8000-000f4343000f',
    '00000059-0000-4005-8000-000000590000',
    'BBQ',
    1
),
(
    '000f4344-000f-4434-8000-000f4344000f',
    '00000059-0000-4005-8000-000000590000',
    'Rice Bowls',
    2
),
(
    '000f4345-000f-4434-8000-000f4345000f',
    '00000059-0000-4005-8000-000000590000',
    'Noodles',
    3
),
(
    '000f4346-000f-4434-8000-000f4346000f',
    '00000059-0000-4005-8000-000000590000',
    'Appetizers',
    4
),
(
    '000f4347-000f-4434-8000-000f4347000f',
    '0000005a-0000-4005-8000-0000005a0000',
    'Pho',
    1
),
(
    '000f4348-000f-4434-8000-000f4348000f',
    '0000005a-0000-4005-8000-0000005a0000',
    'Banh Mi',
    2
),
(
    '000f4349-000f-4434-8000-000f4349000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Gyros',
    1
),
(
    '000f434a-000f-4434-8000-000f434a000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Souvlaki',
    2
),
(
    '000f434b-000f-4434-8000-000f434b000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Salads',
    3
),
(
    '000f434c-000f-4434-8000-000f434c000f',
    '0000005c-0000-4005-8000-0000005c0000',
    'Tapas',
    1
),
(
    '000f434d-000f-4434-8000-000f434d000f',
    '0000005c-0000-4005-8000-0000005c0000',
    'Paella',
    2
),
(
    '000f434e-000f-4434-8000-000f434e000f',
    '0000005d-0000-4005-8000-0000005d0000',
    'Kebabs',
    1
),
(
    '000f434f-000f-4434-8000-000f434f000f',
    '0000005d-0000-4005-8000-0000005d0000',
    'Mezze',
    2
),
(
    '000f4350-000f-4435-8000-000f4350000f',
    '0000005e-0000-4005-8000-0000005e0000',
    'Mezze',
    1
),
(
    '000f4351-000f-4435-8000-000f4351000f',
    '0000005e-0000-4005-8000-0000005e0000',
    'Grills',
    2
),
(
    '000f4352-000f-4435-8000-000f4352000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Grills',
    1
),
(
    '000f4353-000f-4435-8000-000f4353000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Rice Dishes',
    2
),
(
    '000f4354-000f-4435-8000-000f4354000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Appetizers',
    3
),
(
    '000f4355-000f-4435-8000-000f4355000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Desserts',
    4
),
(
    '000f4356-000f-4435-8000-000f4356000f',
    '00000060-0000-4006-8000-000000600000',
    'Schnitzel',
    1
),
(
    '000f4357-000f-4435-8000-000f4357000f',
    '00000060-0000-4006-8000-000000600000',
    'Sausages',
    2
),
(
    '000f4358-000f-4435-8000-000f4358000f',
    '00000060-0000-4006-8000-000000600000',
    'Sides',
    3
),
(
    '000f4359-000f-4435-8000-000f4359000f',
    '00000061-0000-4006-8000-000000610000',
    'Fish & Chips',
    1
),
(
    '000f435a-000f-4435-8000-000f435a000f',
    '00000061-0000-4006-8000-000000610000',
    'Pies',
    2
),
(
    '000f435b-000f-4435-8000-000f435b000f',
    '00000062-0000-4006-8000-000000620000',
    'Jerk',
    1
),
(
    '000f435c-000f-4435-8000-000f435c000f',
    '00000062-0000-4006-8000-000000620000',
    'Rice Dishes',
    2
),
(
    '000f435d-000f-4435-8000-000f435d000f',
    '00000062-0000-4006-8000-000000620000',
    'Soups',
    3
),
(
    '000f435e-000f-4435-8000-000f435e000f',
    '00000063-0000-4006-8000-000000630000',
    'Specialties',
    1
),
(
    '000f435f-000f-4435-8000-000f435f000f',
    '00000063-0000-4006-8000-000000630000',
    'Appetizers',
    2
),
(
    '000f4360-000f-4436-8000-000f4360000f',
    '00000063-0000-4006-8000-000000630000',
    'Sides',
    3
),
(
    '000f4361-000f-4436-8000-000f4361000f',
    '00000063-0000-4006-8000-000000630000',
    'Desserts',
    4
),
(
    '000f4362-000f-4436-8000-000f4362000f',
    '00000064-0000-4006-8000-000000640000',
    'Pizzas',
    1
),
(
    '000f4363-000f-4436-8000-000f4363000f',
    '00000064-0000-4006-8000-000000640000',
    'Pastas',
    2
),
(
    '000f4364-000f-4436-8000-000f4364000f',
    '00000064-0000-4006-8000-000000640000',
    'Appetizers',
    3
),
(
    '000f4365-000f-4436-8000-000f4365000f',
    '00000064-0000-4006-8000-000000640000',
    'Desserts',
    4
),
(
    '000f4366-000f-4436-8000-000f4366000f',
    '00000065-0000-4006-8000-000000650000',
    'Dim Sum',
    1
),
(
    '000f4367-000f-4436-8000-000f4367000f',
    '00000065-0000-4006-8000-000000650000',
    'Noodles',
    2
),
(
    '000f4368-000f-4436-8000-000f4368000f',
    '00000065-0000-4006-8000-000000650000',
    'Rice Dishes',
    3
),
(
    '000f4369-000f-4436-8000-000f4369000f',
    '00000066-0000-4006-8000-000000660000',
    'Tacos',
    1
),
(
    '000f436a-000f-4436-8000-000f436a000f',
    '00000066-0000-4006-8000-000000660000',
    'Burritos',
    2
),
(
    '000f436b-000f-4436-8000-000f436b000f',
    '00000066-0000-4006-8000-000000660000',
    'Quesadillas',
    3
),
(
    '000f436c-000f-4436-8000-000f436c000f',
    '00000066-0000-4006-8000-000000660000',
    'Appetizers',
    4
),
(
    '000f436d-000f-4436-8000-000f436d000f',
    '00000067-0000-4006-8000-000000670000',
    'Curries',
    1
),
(
    '000f436e-000f-4436-8000-000f436e000f',
    '00000067-0000-4006-8000-000000670000',
    'Biryani',
    2
),
(
    '000f436f-000f-4436-8000-000f436f000f',
    '00000067-0000-4006-8000-000000670000',
    'Breads',
    3
),
(
    '000f4370-000f-4437-8000-000f4370000f',
    '00000067-0000-4006-8000-000000670000',
    'Appetizers',
    4
),
(
    '000f4371-000f-4437-8000-000f4371000f',
    '00000068-0000-4006-8000-000000680000',
    'Sushi',
    1
),
(
    '000f4372-000f-4437-8000-000f4372000f',
    '00000068-0000-4006-8000-000000680000',
    'Ramen',
    2
),
(
    '000f4373-000f-4437-8000-000f4373000f',
    '00000069-0000-4006-8000-000000690000',
    'Curries',
    1
),
(
    '000f4374-000f-4437-8000-000f4374000f',
    '00000069-0000-4006-8000-000000690000',
    'Noodles',
    2
),
(
    '000f4375-000f-4437-8000-000f4375000f',
    '00000069-0000-4006-8000-000000690000',
    'Stir Fries',
    3
),
(
    '000f4376-000f-4437-8000-000f4376000f',
    '0000006a-0000-4006-8000-0000006a0000',
    'Burgers',
    1
),
(
    '000f4377-000f-4437-8000-000f4377000f',
    '0000006a-0000-4006-8000-0000006a0000',
    'Sandwiches',
    2
),
(
    '000f4378-000f-4437-8000-000f4378000f',
    '0000006b-0000-4006-8000-0000006b0000',
    'Entrees',
    1
),
(
    '000f4379-000f-4437-8000-000f4379000f',
    '0000006b-0000-4006-8000-0000006b0000',
    'Soups',
    2
),
(
    '000f437a-000f-4437-8000-000f437a000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Mezze',
    1
),
(
    '000f437b-000f-4437-8000-000f437b000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Grills',
    2
),
(
    '000f437c-000f-4437-8000-000f437c000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Salads',
    3
),
(
    '000f437d-000f-4437-8000-000f437d000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Desserts',
    4
),
(
    '000f437e-000f-4437-8000-000f437e000f',
    '0000006d-0000-4006-8000-0000006d0000',
    'BBQ',
    1
),
(
    '000f437f-000f-4437-8000-000f437f000f',
    '0000006d-0000-4006-8000-0000006d0000',
    'Rice Bowls',
    2
),
(
    '000f4380-000f-4438-8000-000f4380000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Pho',
    1
),
(
    '000f4381-000f-4438-8000-000f4381000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Banh Mi',
    2
),
(
    '000f4382-000f-4438-8000-000f4382000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Rice Dishes',
    3
),
(
    '000f4383-000f-4438-8000-000f4383000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Gyros',
    1
),
(
    '000f4384-000f-4438-8000-000f4384000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Souvlaki',
    2
),
(
    '000f4385-000f-4438-8000-000f4385000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Salads',
    3
),
(
    '000f4386-000f-4438-8000-000f4386000f',
    '00000070-0000-4007-8000-000000700000',
    'Tapas',
    1
),
(
    '000f4387-000f-4438-8000-000f4387000f',
    '00000070-0000-4007-8000-000000700000',
    'Paella',
    2
),
(
    '000f4388-000f-4438-8000-000f4388000f',
    '00000071-0000-4007-8000-000000710000',
    'Kebabs',
    1
),
(
    '000f4389-000f-4438-8000-000f4389000f',
    '00000071-0000-4007-8000-000000710000',
    'Mezze',
    2
),
(
    '000f438a-000f-4438-8000-000f438a000f',
    '00000071-0000-4007-8000-000000710000',
    'Grills',
    3
),
(
    '000f438b-000f-4438-8000-000f438b000f',
    '00000071-0000-4007-8000-000000710000',
    'Desserts',
    4
),
(
    '000f438c-000f-4438-8000-000f438c000f',
    '00000072-0000-4007-8000-000000720000',
    'Mezze',
    1
),
(
    '000f438d-000f-4438-8000-000f438d000f',
    '00000072-0000-4007-8000-000000720000',
    'Grills',
    2
),
(
    '000f438e-000f-4438-8000-000f438e000f',
    '00000073-0000-4007-8000-000000730000',
    'Grills',
    1
),
(
    '000f438f-000f-4438-8000-000f438f000f',
    '00000073-0000-4007-8000-000000730000',
    'Rice Dishes',
    2
),
(
    '000f4390-000f-4439-8000-000f4390000f',
    '00000074-0000-4007-8000-000000740000',
    'Schnitzel',
    1
),
(
    '000f4391-000f-4439-8000-000f4391000f',
    '00000074-0000-4007-8000-000000740000',
    'Sausages',
    2
),
(
    '000f4392-000f-4439-8000-000f4392000f',
    '00000074-0000-4007-8000-000000740000',
    'Sides',
    3
),
(
    '000f4393-000f-4439-8000-000f4393000f',
    '00000075-0000-4007-8000-000000750000',
    'Fish & Chips',
    1
),
(
    '000f4394-000f-4439-8000-000f4394000f',
    '00000075-0000-4007-8000-000000750000',
    'Pies',
    2
),
(
    '000f4395-000f-4439-8000-000f4395000f',
    '00000076-0000-4007-8000-000000760000',
    'Jerk',
    1
),
(
    '000f4396-000f-4439-8000-000f4396000f',
    '00000076-0000-4007-8000-000000760000',
    'Rice Dishes',
    2
),
(
    '000f4397-000f-4439-8000-000f4397000f',
    '00000076-0000-4007-8000-000000760000',
    'Soups',
    3
),
(
    '000f4398-000f-4439-8000-000f4398000f',
    '00000076-0000-4007-8000-000000760000',
    'Desserts',
    4
),
(
    '000f4399-000f-4439-8000-000f4399000f',
    '00000077-0000-4007-8000-000000770000',
    'Specialties',
    1
),
(
    '000f439a-000f-4439-8000-000f439a000f',
    '00000077-0000-4007-8000-000000770000',
    'Appetizers',
    2
),
(
    '000f439b-000f-4439-8000-000f439b000f',
    '00000077-0000-4007-8000-000000770000',
    'Sides',
    3
),
(
    '000f439c-000f-4439-8000-000f439c000f',
    '00000077-0000-4007-8000-000000770000',
    'Desserts',
    4
),
(
    '000f439d-000f-4439-8000-000f439d000f',
    '00000078-0000-4007-8000-000000780000',
    'Pizzas',
    1
),
(
    '000f439e-000f-4439-8000-000f439e000f',
    '00000078-0000-4007-8000-000000780000',
    'Pastas',
    2
),
(
    '000f439f-000f-4439-8000-000f439f000f',
    '00000078-0000-4007-8000-000000780000',
    'Appetizers',
    3
),
(
    '000f43a0-000f-443a-8000-000f43a0000f',
    '00000079-0000-4007-8000-000000790000',
    'Dim Sum',
    1
),
(
    '000f43a1-000f-443a-8000-000f43a1000f',
    '00000079-0000-4007-8000-000000790000',
    'Noodles',
    2
),
(
    '000f43a2-000f-443a-8000-000f43a2000f',
    '00000079-0000-4007-8000-000000790000',
    'Rice Dishes',
    3
),
(
    '000f43a3-000f-443a-8000-000f43a3000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Tacos',
    1
),
(
    '000f43a4-000f-443a-8000-000f43a4000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Burritos',
    2
),
(
    '000f43a5-000f-443a-8000-000f43a5000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Quesadillas',
    3
),
(
    '000f43a6-000f-443a-8000-000f43a6000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Curries',
    1
),
(
    '000f43a7-000f-443a-8000-000f43a7000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Biryani',
    2
),
(
    '000f43a8-000f-443a-8000-000f43a8000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Breads',
    3
),
(
    '000f43a9-000f-443a-8000-000f43a9000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Sushi',
    1
),
(
    '000f43aa-000f-443a-8000-000f43aa000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Ramen',
    2
),
(
    '000f43ab-000f-443a-8000-000f43ab000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Teriyaki',
    3
),
(
    '000f43ac-000f-443a-8000-000f43ac000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Appetizers',
    4
),
(
    '000f43ad-000f-443a-8000-000f43ad000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Curries',
    1
),
(
    '000f43ae-000f-443a-8000-000f43ae000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Noodles',
    2
),
(
    '000f43af-000f-443a-8000-000f43af000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Stir Fries',
    3
),
(
    '000f43b0-000f-443b-8000-000f43b0000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Appetizers',
    4
),
(
    '000f43b1-000f-443b-8000-000f43b1000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Burgers',
    1
),
(
    '000f43b2-000f-443b-8000-000f43b2000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Sandwiches',
    2
),
(
    '000f43b3-000f-443b-8000-000f43b3000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Salads',
    3
),
(
    '000f43b4-000f-443b-8000-000f43b4000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Sides',
    4
),
(
    '000f43b5-000f-443b-8000-000f43b5000f',
    '0000007f-0000-4007-8000-0000007f0000',
    'Entrees',
    1
),
(
    '000f43b6-000f-443b-8000-000f43b6000f',
    '0000007f-0000-4007-8000-0000007f0000',
    'Soups',
    2
),
(
    '000f43b7-000f-443b-8000-000f43b7000f',
    '00000080-0000-4008-8000-000000800000',
    'Mezze',
    1
),
(
    '000f43b8-000f-443b-8000-000f43b8000f',
    '00000080-0000-4008-8000-000000800000',
    'Grills',
    2
),
(
    '000f43b9-000f-443b-8000-000f43b9000f',
    '00000080-0000-4008-8000-000000800000',
    'Salads',
    3
),
(
    '000f43ba-000f-443b-8000-000f43ba000f',
    '00000081-0000-4008-8000-000000810000',
    'BBQ',
    1
),
(
    '000f43bb-000f-443b-8000-000f43bb000f',
    '00000081-0000-4008-8000-000000810000',
    'Rice Bowls',
    2
),
(
    '000f43bc-000f-443b-8000-000f43bc000f',
    '00000081-0000-4008-8000-000000810000',
    'Noodles',
    3
),
(
    '000f43bd-000f-443b-8000-000f43bd000f',
    '00000082-0000-4008-8000-000000820000',
    'Pho',
    1
),
(
    '000f43be-000f-443b-8000-000f43be000f',
    '00000082-0000-4008-8000-000000820000',
    'Banh Mi',
    2
),
(
    '000f43bf-000f-443b-8000-000f43bf000f',
    '00000082-0000-4008-8000-000000820000',
    'Rice Dishes',
    3
),
(
    '000f43c0-000f-443c-8000-000f43c0000f',
    '00000082-0000-4008-8000-000000820000',
    'Appetizers',
    4
),
(
    '000f43c1-000f-443c-8000-000f43c1000f',
    '00000083-0000-4008-8000-000000830000',
    'Gyros',
    1
),
(
    '000f43c2-000f-443c-8000-000f43c2000f',
    '00000083-0000-4008-8000-000000830000',
    'Souvlaki',
    2
),
(
    '000f43c3-000f-443c-8000-000f43c3000f',
    '00000083-0000-4008-8000-000000830000',
    'Salads',
    3
),
(
    '000f43c4-000f-443c-8000-000f43c4000f',
    '00000084-0000-4008-8000-000000840000',
    'Tapas',
    1
),
(
    '000f43c5-000f-443c-8000-000f43c5000f',
    '00000084-0000-4008-8000-000000840000',
    'Paella',
    2
),
(
    '000f43c6-000f-443c-8000-000f43c6000f',
    '00000084-0000-4008-8000-000000840000',
    'Soups',
    3
),
(
    '000f43c7-000f-443c-8000-000f43c7000f',
    '00000084-0000-4008-8000-000000840000',
    'Desserts',
    4
),
(
    '000f43c8-000f-443c-8000-000f43c8000f',
    '00000085-0000-4008-8000-000000850000',
    'Kebabs',
    1
),
(
    '000f43c9-000f-443c-8000-000f43c9000f',
    '00000085-0000-4008-8000-000000850000',
    'Mezze',
    2
),
(
    '000f43ca-000f-443c-8000-000f43ca000f',
    '00000085-0000-4008-8000-000000850000',
    'Grills',
    3
),
(
    '000f43cb-000f-443c-8000-000f43cb000f',
    '00000086-0000-4008-8000-000000860000',
    'Mezze',
    1
),
(
    '000f43cc-000f-443c-8000-000f43cc000f',
    '00000086-0000-4008-8000-000000860000',
    'Grills',
    2
),
(
    '000f43cd-000f-443c-8000-000f43cd000f',
    '00000087-0000-4008-8000-000000870000',
    'Grills',
    1
),
(
    '000f43ce-000f-443c-8000-000f43ce000f',
    '00000087-0000-4008-8000-000000870000',
    'Rice Dishes',
    2
),
(
    '000f43cf-000f-443c-8000-000f43cf000f',
    '00000088-0000-4008-8000-000000880000',
    'Schnitzel',
    1
),
(
    '000f43d0-000f-443d-8000-000f43d0000f',
    '00000088-0000-4008-8000-000000880000',
    'Sausages',
    2
),
(
    '000f43d1-000f-443d-8000-000f43d1000f',
    '00000088-0000-4008-8000-000000880000',
    'Sides',
    3
),
(
    '000f43d2-000f-443d-8000-000f43d2000f',
    '00000088-0000-4008-8000-000000880000',
    'Desserts',
    4
),
(
    '000f43d3-000f-443d-8000-000f43d3000f',
    '00000089-0000-4008-8000-000000890000',
    'Fish & Chips',
    1
),
(
    '000f43d4-000f-443d-8000-000f43d4000f',
    '00000089-0000-4008-8000-000000890000',
    'Pies',
    2
),
(
    '000f43d5-000f-443d-8000-000f43d5000f',
    '00000089-0000-4008-8000-000000890000',
    'Sides',
    3
),
(
    '000f43d6-000f-443d-8000-000f43d6000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Jerk',
    1
),
(
    '000f43d7-000f-443d-8000-000f43d7000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Rice Dishes',
    2
),
(
    '000f43d8-000f-443d-8000-000f43d8000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Soups',
    3
),
(
    '000f43d9-000f-443d-8000-000f43d9000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Specialties',
    1
),
(
    '000f43da-000f-443d-8000-000f43da000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Appetizers',
    2
),
(
    '000f43db-000f-443d-8000-000f43db000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Sides',
    3
),
(
    '000f43dc-000f-443d-8000-000f43dc000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Desserts',
    4
),
(
    '000f43dd-000f-443d-8000-000f43dd000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Pizzas',
    1
),
(
    '000f43de-000f-443d-8000-000f43de000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Pastas',
    2
),
(
    '000f43df-000f-443d-8000-000f43df000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Appetizers',
    3
),
(
    '000f43e0-000f-443e-8000-000f43e0000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Desserts',
    4
),
(
    '000f43e1-000f-443e-8000-000f43e1000f',
    '0000008d-0000-4008-8000-0000008d0000',
    'Dim Sum',
    1
),
(
    '000f43e2-000f-443e-8000-000f43e2000f',
    '0000008d-0000-4008-8000-0000008d0000',
    'Noodles',
    2
),
(
    '000f43e3-000f-443e-8000-000f43e3000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Tacos',
    1
),
(
    '000f43e4-000f-443e-8000-000f43e4000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Burritos',
    2
),
(
    '000f43e5-000f-443e-8000-000f43e5000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Quesadillas',
    3
),
(
    '000f43e6-000f-443e-8000-000f43e6000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Appetizers',
    4
),
(
    '000f43e7-000f-443e-8000-000f43e7000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Curries',
    1
),
(
    '000f43e8-000f-443e-8000-000f43e8000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Biryani',
    2
),
(
    '000f43e9-000f-443e-8000-000f43e9000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Breads',
    3
),
(
    '000f43ea-000f-443e-8000-000f43ea000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Appetizers',
    4
),
(
    '000f43eb-000f-443e-8000-000f43eb000f',
    '00000090-0000-4009-8000-000000900000',
    'Sushi',
    1
),
(
    '000f43ec-000f-443e-8000-000f43ec000f',
    '00000090-0000-4009-8000-000000900000',
    'Ramen',
    2
),
(
    '000f43ed-000f-443e-8000-000f43ed000f',
    '00000090-0000-4009-8000-000000900000',
    'Teriyaki',
    3
),
(
    '000f43ee-000f-443e-8000-000f43ee000f',
    '00000091-0000-4009-8000-000000910000',
    'Curries',
    1
),
(
    '000f43ef-000f-443e-8000-000f43ef000f',
    '00000091-0000-4009-8000-000000910000',
    'Noodles',
    2
),
(
    '000f43f0-000f-443f-8000-000f43f0000f',
    '00000092-0000-4009-8000-000000920000',
    'Burgers',
    1
),
(
    '000f43f1-000f-443f-8000-000f43f1000f',
    '00000092-0000-4009-8000-000000920000',
    'Sandwiches',
    2
),
(
    '000f43f2-000f-443f-8000-000f43f2000f',
    '00000093-0000-4009-8000-000000930000',
    'Entrees',
    1
),
(
    '000f43f3-000f-443f-8000-000f43f3000f',
    '00000093-0000-4009-8000-000000930000',
    'Soups',
    2
),
(
    '000f43f4-000f-443f-8000-000f43f4000f',
    '00000093-0000-4009-8000-000000930000',
    'Salads',
    3
),
(
    '000f43f5-000f-443f-8000-000f43f5000f',
    '00000094-0000-4009-8000-000000940000',
    'Mezze',
    1
),
(
    '000f43f6-000f-443f-8000-000f43f6000f',
    '00000094-0000-4009-8000-000000940000',
    'Grills',
    2
),
(
    '000f43f7-000f-443f-8000-000f43f7000f',
    '00000095-0000-4009-8000-000000950000',
    'BBQ',
    1
),
(
    '000f43f8-000f-443f-8000-000f43f8000f',
    '00000095-0000-4009-8000-000000950000',
    'Rice Bowls',
    2
),
(
    '000f43f9-000f-443f-8000-000f43f9000f',
    '00000095-0000-4009-8000-000000950000',
    'Noodles',
    3
),
(
    '000f43fa-000f-443f-8000-000f43fa000f',
    '00000096-0000-4009-8000-000000960000',
    'Pho',
    1
),
(
    '000f43fb-000f-443f-8000-000f43fb000f',
    '00000096-0000-4009-8000-000000960000',
    'Banh Mi',
    2
),
(
    '000f43fc-000f-443f-8000-000f43fc000f',
    '00000096-0000-4009-8000-000000960000',
    'Rice Dishes',
    3
),
(
    '000f43fd-000f-443f-8000-000f43fd000f',
    '00000097-0000-4009-8000-000000970000',
    'Gyros',
    1
),
(
    '000f43fe-000f-443f-8000-000f43fe000f',
    '00000097-0000-4009-8000-000000970000',
    'Souvlaki',
    2
),
(
    '000f43ff-000f-443f-8000-000f43ff000f',
    '00000098-0000-4009-8000-000000980000',
    'Tapas',
    1
),
(
    '000f4400-000f-4440-8000-000f4400000f',
    '00000098-0000-4009-8000-000000980000',
    'Paella',
    2
),
(
    '000f4401-000f-4440-8000-000f4401000f',
    '00000098-0000-4009-8000-000000980000',
    'Soups',
    3
),
(
    '000f4402-000f-4440-8000-000f4402000f',
    '00000098-0000-4009-8000-000000980000',
    'Desserts',
    4
),
(
    '000f4403-000f-4440-8000-000f4403000f',
    '00000099-0000-4009-8000-000000990000',
    'Kebabs',
    1
),
(
    '000f4404-000f-4440-8000-000f4404000f',
    '00000099-0000-4009-8000-000000990000',
    'Mezze',
    2
),
(
    '000f4405-000f-4440-8000-000f4405000f',
    '00000099-0000-4009-8000-000000990000',
    'Grills',
    3
),
(
    '000f4406-000f-4440-8000-000f4406000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Mezze',
    1
),
(
    '000f4407-000f-4440-8000-000f4407000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Grills',
    2
),
(
    '000f4408-000f-4440-8000-000f4408000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Salads',
    3
),
(
    '000f4409-000f-4440-8000-000f4409000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Grills',
    1
),
(
    '000f440a-000f-4440-8000-000f440a000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Rice Dishes',
    2
),
(
    '000f440b-000f-4440-8000-000f440b000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Appetizers',
    3
),
(
    '000f440c-000f-4440-8000-000f440c000f',
    '0000009c-0000-4009-8000-0000009c0000',
    'Schnitzel',
    1
),
(
    '000f440d-000f-4440-8000-000f440d000f',
    '0000009c-0000-4009-8000-0000009c0000',
    'Sausages',
    2
),
(
    '000f440e-000f-4440-8000-000f440e000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Fish & Chips',
    1
),
(
    '000f440f-000f-4440-8000-000f440f000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Pies',
    2
),
(
    '000f4410-000f-4441-8000-000f4410000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Sides',
    3
),
(
    '000f4411-000f-4441-8000-000f4411000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Desserts',
    4
),
(
    '000f4412-000f-4441-8000-000f4412000f',
    '0000009e-0000-4009-8000-0000009e0000',
    'Jerk',
    1
),
(
    '000f4413-000f-4441-8000-000f4413000f',
    '0000009e-0000-4009-8000-0000009e0000',
    'Rice Dishes',
    2
),
(
    '000f4414-000f-4441-8000-000f4414000f',
    '0000009f-0000-4009-8000-0000009f0000',
    'Specialties',
    1
),
(
    '000f4415-000f-4441-8000-000f4415000f',
    '0000009f-0000-4009-8000-0000009f0000',
    'Appetizers',
    2
),
(
    '000f4416-000f-4441-8000-000f4416000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Pizzas',
    1
),
(
    '000f4417-000f-4441-8000-000f4417000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Pastas',
    2
),
(
    '000f4418-000f-4441-8000-000f4418000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Appetizers',
    3
),
(
    '000f4419-000f-4441-8000-000f4419000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Dim Sum',
    1
),
(
    '000f441a-000f-4441-8000-000f441a000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Noodles',
    2
),
(
    '000f441b-000f-4441-8000-000f441b000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Rice Dishes',
    3
),
(
    '000f441c-000f-4441-8000-000f441c000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Tacos',
    1
),
(
    '000f441d-000f-4441-8000-000f441d000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Burritos',
    2
),
(
    '000f441e-000f-4441-8000-000f441e000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Quesadillas',
    3
),
(
    '000f441f-000f-4441-8000-000f441f000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Curries',
    1
),
(
    '000f4420-000f-4442-8000-000f4420000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Biryani',
    2
),
(
    '000f4421-000f-4442-8000-000f4421000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Breads',
    3
),
(
    '000f4422-000f-4442-8000-000f4422000f',
    '000000a4-0000-400a-8000-000000a40000',
    'Sushi',
    1
),
(
    '000f4423-000f-4442-8000-000f4423000f',
    '000000a4-0000-400a-8000-000000a40000',
    'Ramen',
    2
),
(
    '000f4424-000f-4442-8000-000f4424000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Curries',
    1
),
(
    '000f4425-000f-4442-8000-000f4425000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Noodles',
    2
),
(
    '000f4426-000f-4442-8000-000f4426000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Stir Fries',
    3
),
(
    '000f4427-000f-4442-8000-000f4427000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Appetizers',
    4
),
(
    '000f4428-000f-4442-8000-000f4428000f',
    '000000a6-0000-400a-8000-000000a60000',
    'Burgers',
    1
),
(
    '000f4429-000f-4442-8000-000f4429000f',
    '000000a6-0000-400a-8000-000000a60000',
    'Sandwiches',
    2
),
(
    '000f442a-000f-4442-8000-000f442a000f',
    '000000a7-0000-400a-8000-000000a70000',
    'Entrees',
    1
),
(
    '000f442b-000f-4442-8000-000f442b000f',
    '000000a7-0000-400a-8000-000000a70000',
    'Soups',
    2
),
(
    '000f442c-000f-4442-8000-000f442c000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Mezze',
    1
),
(
    '000f442d-000f-4442-8000-000f442d000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Grills',
    2
),
(
    '000f442e-000f-4442-8000-000f442e000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Salads',
    3
),
(
    '000f442f-000f-4442-8000-000f442f000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Desserts',
    4
),
(
    '000f4430-000f-4443-8000-000f4430000f',
    '000000a9-0000-400a-8000-000000a90000',
    'BBQ',
    1
),
(
    '000f4431-000f-4443-8000-000f4431000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Rice Bowls',
    2
),
(
    '000f4432-000f-4443-8000-000f4432000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Noodles',
    3
),
(
    '000f4433-000f-4443-8000-000f4433000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Pho',
    1
),
(
    '000f4434-000f-4443-8000-000f4434000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Banh Mi',
    2
),
(
    '000f4435-000f-4443-8000-000f4435000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Rice Dishes',
    3
),
(
    '000f4436-000f-4443-8000-000f4436000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Gyros',
    1
),
(
    '000f4437-000f-4443-8000-000f4437000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Souvlaki',
    2
),
(
    '000f4438-000f-4443-8000-000f4438000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Salads',
    3
),
(
    '000f4439-000f-4443-8000-000f4439000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Desserts',
    4
),
(
    '000f443a-000f-4443-8000-000f443a000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Tapas',
    1
),
(
    '000f443b-000f-4443-8000-000f443b000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Paella',
    2
),
(
    '000f443c-000f-4443-8000-000f443c000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Soups',
    3
),
(
    '000f443d-000f-4443-8000-000f443d000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Desserts',
    4
),
(
    '000f443e-000f-4443-8000-000f443e000f',
    '000000ad-0000-400a-8000-000000ad0000',
    'Kebabs',
    1
),
(
    '000f443f-000f-4443-8000-000f443f000f',
    '000000ad-0000-400a-8000-000000ad0000',
    'Mezze',
    2
),
(
    '000f4440-000f-4444-8000-000f4440000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Mezze',
    1
),
(
    '000f4441-000f-4444-8000-000f4441000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Grills',
    2
),
(
    '000f4442-000f-4444-8000-000f4442000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Salads',
    3
),
(
    '000f4443-000f-4444-8000-000f4443000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Desserts',
    4
),
(
    '000f4444-000f-4444-8000-000f4444000f',
    '000000af-0000-400a-8000-000000af0000',
    'Grills',
    1
),
(
    '000f4445-000f-4444-8000-000f4445000f',
    '000000af-0000-400a-8000-000000af0000',
    'Rice Dishes',
    2
),
(
    '000f4446-000f-4444-8000-000f4446000f',
    '000000b0-0000-400b-8000-000000b00000',
    'Schnitzel',
    1
),
(
    '000f4447-000f-4444-8000-000f4447000f',
    '000000b0-0000-400b-8000-000000b00000',
    'Sausages',
    2
),
(
    '000f4448-000f-4444-8000-000f4448000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Fish & Chips',
    1
),
(
    '000f4449-000f-4444-8000-000f4449000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Pies',
    2
),
(
    '000f444a-000f-4444-8000-000f444a000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Sides',
    3
),
(
    '000f444b-000f-4444-8000-000f444b000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Desserts',
    4
),
(
    '000f444c-000f-4444-8000-000f444c000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Jerk',
    1
),
(
    '000f444d-000f-4444-8000-000f444d000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Rice Dishes',
    2
),
(
    '000f444e-000f-4444-8000-000f444e000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Soups',
    3
),
(
    '000f444f-000f-4444-8000-000f444f000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Desserts',
    4
),
(
    '000f4450-000f-4445-8000-000f4450000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Specialties',
    1
),
(
    '000f4451-000f-4445-8000-000f4451000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Appetizers',
    2
),
(
    '000f4452-000f-4445-8000-000f4452000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Sides',
    3
),
(
    '000f4453-000f-4445-8000-000f4453000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Desserts',
    4
),
(
    '000f4454-000f-4445-8000-000f4454000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Pizzas',
    1
),
(
    '000f4455-000f-4445-8000-000f4455000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Pastas',
    2
),
(
    '000f4456-000f-4445-8000-000f4456000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Appetizers',
    3
),
(
    '000f4457-000f-4445-8000-000f4457000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Desserts',
    4
),
(
    '000f4458-000f-4445-8000-000f4458000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Dim Sum',
    1
),
(
    '000f4459-000f-4445-8000-000f4459000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Noodles',
    2
),
(
    '000f445a-000f-4445-8000-000f445a000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Rice Dishes',
    3
),
(
    '000f445b-000f-4445-8000-000f445b000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Soups',
    4
),
(
    '000f445c-000f-4445-8000-000f445c000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Tacos',
    1
),
(
    '000f445d-000f-4445-8000-000f445d000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Burritos',
    2
),
(
    '000f445e-000f-4445-8000-000f445e000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Quesadillas',
    3
),
(
    '000f445f-000f-4445-8000-000f445f000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Curries',
    1
),
(
    '000f4460-000f-4446-8000-000f4460000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Biryani',
    2
),
(
    '000f4461-000f-4446-8000-000f4461000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Breads',
    3
),
(
    '000f4462-000f-4446-8000-000f4462000f',
    '000000b8-0000-400b-8000-000000b80000',
    'Sushi',
    1
),
(
    '000f4463-000f-4446-8000-000f4463000f',
    '000000b8-0000-400b-8000-000000b80000',
    'Ramen',
    2
),
(
    '000f4464-000f-4446-8000-000f4464000f',
    '000000b9-0000-400b-8000-000000b90000',
    'Curries',
    1
),
(
    '000f4465-000f-4446-8000-000f4465000f',
    '000000b9-0000-400b-8000-000000b90000',
    'Noodles',
    2
),
(
    '000f4466-000f-4446-8000-000f4466000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Burgers',
    1
),
(
    '000f4467-000f-4446-8000-000f4467000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Sandwiches',
    2
),
(
    '000f4468-000f-4446-8000-000f4468000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Salads',
    3
),
(
    '000f4469-000f-4446-8000-000f4469000f',
    '000000bb-0000-400b-8000-000000bb0000',
    'Entrees',
    1
),
(
    '000f446a-000f-4446-8000-000f446a000f',
    '000000bb-0000-400b-8000-000000bb0000',
    'Soups',
    2
),
(
    '000f446b-000f-4446-8000-000f446b000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Mezze',
    1
),
(
    '000f446c-000f-4446-8000-000f446c000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Grills',
    2
),
(
    '000f446d-000f-4446-8000-000f446d000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Salads',
    3
),
(
    '000f446e-000f-4446-8000-000f446e000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Desserts',
    4
),
(
    '000f446f-000f-4446-8000-000f446f000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'BBQ',
    1
),
(
    '000f4470-000f-4447-8000-000f4470000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Rice Bowls',
    2
),
(
    '000f4471-000f-4447-8000-000f4471000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Noodles',
    3
),
(
    '000f4472-000f-4447-8000-000f4472000f',
    '000000be-0000-400b-8000-000000be0000',
    'Pho',
    1
),
(
    '000f4473-000f-4447-8000-000f4473000f',
    '000000be-0000-400b-8000-000000be0000',
    'Banh Mi',
    2
),
(
    '000f4474-000f-4447-8000-000f4474000f',
    '000000be-0000-400b-8000-000000be0000',
    'Rice Dishes',
    3
),
(
    '000f4475-000f-4447-8000-000f4475000f',
    '000000be-0000-400b-8000-000000be0000',
    'Appetizers',
    4
),
(
    '000f4476-000f-4447-8000-000f4476000f',
    '000000bf-0000-400b-8000-000000bf0000',
    'Gyros',
    1
),
(
    '000f4477-000f-4447-8000-000f4477000f',
    '000000bf-0000-400b-8000-000000bf0000',
    'Souvlaki',
    2
),
(
    '000f4478-000f-4447-8000-000f4478000f',
    '000000c0-0000-400c-8000-000000c00000',
    'Tapas',
    1
),
(
    '000f4479-000f-4447-8000-000f4479000f',
    '000000c0-0000-400c-8000-000000c00000',
    'Paella',
    2
),
(
    '000f447a-000f-4447-8000-000f447a000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Kebabs',
    1
),
(
    '000f447b-000f-4447-8000-000f447b000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Mezze',
    2
),
(
    '000f447c-000f-4447-8000-000f447c000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Grills',
    3
),
(
    '000f447d-000f-4447-8000-000f447d000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Mezze',
    1
),
(
    '000f447e-000f-4447-8000-000f447e000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Grills',
    2
),
(
    '000f447f-000f-4447-8000-000f447f000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Salads',
    3
),
(
    '000f4480-000f-4448-8000-000f4480000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Desserts',
    4
),
(
    '000f4481-000f-4448-8000-000f4481000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Grills',
    1
),
(
    '000f4482-000f-4448-8000-000f4482000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Rice Dishes',
    2
),
(
    '000f4483-000f-4448-8000-000f4483000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Appetizers',
    3
),
(
    '000f4484-000f-4448-8000-000f4484000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Desserts',
    4
),
(
    '000f4485-000f-4448-8000-000f4485000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Schnitzel',
    1
),
(
    '000f4486-000f-4448-8000-000f4486000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Sausages',
    2
),
(
    '000f4487-000f-4448-8000-000f4487000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Sides',
    3
),
(
    '000f4488-000f-4448-8000-000f4488000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Fish & Chips',
    1
),
(
    '000f4489-000f-4448-8000-000f4489000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Pies',
    2
),
(
    '000f448a-000f-4448-8000-000f448a000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Sides',
    3
),
(
    '000f448b-000f-4448-8000-000f448b000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Desserts',
    4
),
(
    '000f448c-000f-4448-8000-000f448c000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Jerk',
    1
),
(
    '000f448d-000f-4448-8000-000f448d000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Rice Dishes',
    2
),
(
    '000f448e-000f-4448-8000-000f448e000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Soups',
    3
),
(
    '000f448f-000f-4448-8000-000f448f000f',
    '000000c7-0000-400c-8000-000000c70000',
    'Specialties',
    1
),
(
    '000f4490-000f-4449-8000-000f4490000f',
    '000000c7-0000-400c-8000-000000c70000',
    'Appetizers',
    2
),
(
    '000f4491-000f-4449-8000-000f4491000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Pizzas',
    1
),
(
    '000f4492-000f-4449-8000-000f4492000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Pastas',
    2
);

-- Menu Items
-- Menu Items
INSERT INTO menu_items (id, category_id, restaurant_id, name, description, price, is_available) VALUES
(
    '001e8480-001e-4848-8001-001e8480001e',
    '000f4240-000f-4424-8000-000f4240000f',
    '00000001-0000-4000-8000-000000010000',
    'Har Gow',
    'Steamed shrimp dumplings',
    9.94,
    TRUE
),
(
    '001e8481-001e-4848-8001-001e8481001e',
    '000f4240-000f-4424-8000-000f4240000f',
    '00000001-0000-4000-8000-000000010000',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    7.78,
    TRUE
),
(
    '001e8482-001e-4848-8001-001e8482001e',
    '000f4240-000f-4424-8000-000f4240000f',
    '00000001-0000-4000-8000-000000010000',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    7.05,
    TRUE
),
(
    '001e8483-001e-4848-8001-001e8483001e',
    '000f4240-000f-4424-8000-000f4240000f',
    '00000001-0000-4000-8000-000000010000',
    'Spring Rolls',
    'Crispy vegetable spring rolls',
    6.47,
    TRUE
),
(
    '001e8484-001e-4848-8001-001e8484001e',
    '000f4240-000f-4424-8000-000f4240000f',
    '00000001-0000-4000-8000-000000010000',
    'Xiao Long Bao',
    'Soup dumplings with pork',
    10.19,
    TRUE
),
(
    '001e8485-001e-4848-8001-001e8485001e',
    '000f4241-000f-4424-8000-000f4241000f',
    '00000001-0000-4000-8000-000000010000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    14.83,
    TRUE
),
(
    '001e8486-001e-4848-8001-001e8486001e',
    '000f4241-000f-4424-8000-000f4241000f',
    '00000001-0000-4000-8000-000000010000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.57,
    TRUE
),
(
    '001e8487-001e-4848-8001-001e8487001e',
    '000f4241-000f-4424-8000-000f4241000f',
    '00000001-0000-4000-8000-000000010000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    10.70,
    TRUE
),
(
    '001e8488-001e-4848-8001-001e8488001e',
    '000f4241-000f-4424-8000-000f4241000f',
    '00000001-0000-4000-8000-000000010000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    11.41,
    TRUE
),
(
    '001e8489-001e-4848-8001-001e8489001e',
    '000f4242-000f-4424-8000-000f4242000f',
    '00000001-0000-4000-8000-000000010000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.59,
    TRUE
),
(
    '001e848a-001e-4848-8001-001e848a001e',
    '000f4242-000f-4424-8000-000f4242000f',
    '00000001-0000-4000-8000-000000010000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.88,
    TRUE
),
(
    '001e848b-001e-4848-8001-001e848b001e',
    '000f4242-000f-4424-8000-000f4242000f',
    '00000001-0000-4000-8000-000000010000',
    'Risotto',
    'Creamy Italian rice dish',
    12.78,
    TRUE
),
(
    '001e848c-001e-4848-8001-001e848c001e',
    '000f4243-000f-4424-8000-000f4243000f',
    '00000002-0000-4000-8000-000000020000',
    'Beef Tacos',
    'Seasoned ground beef with lettuce and cheese',
    9.65,
    TRUE
),
(
    '001e848d-001e-4848-8001-001e848d001e',
    '000f4243-000f-4424-8000-000f4243000f',
    '00000002-0000-4000-8000-000000020000',
    'Chicken Tacos',
    'Grilled chicken with salsa and avocado',
    10.00,
    TRUE
),
(
    '001e848e-001e-4848-8001-001e848e001e',
    '000f4243-000f-4424-8000-000f4243000f',
    '00000002-0000-4000-8000-000000020000',
    'Fish Tacos',
    'Battered fish with cabbage slaw',
    10.64,
    TRUE
),
(
    '001e848f-001e-4848-8001-001e848f001e',
    '000f4243-000f-4424-8000-000f4243000f',
    '00000002-0000-4000-8000-000000020000',
    'Vegetarian Tacos',
    'Black beans, corn, and vegetables',
    9.11,
    TRUE
),
(
    '001e8490-001e-4849-8001-001e8490001e',
    '000f4244-000f-4424-8000-000f4244000f',
    '00000002-0000-4000-8000-000000020000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.81,
    TRUE
),
(
    '001e8491-001e-4849-8001-001e8491001e',
    '000f4244-000f-4424-8000-000f4244000f',
    '00000002-0000-4000-8000-000000020000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.87,
    TRUE
),
(
    '001e8492-001e-4849-8001-001e8492001e',
    '000f4244-000f-4424-8000-000f4244000f',
    '00000002-0000-4000-8000-000000020000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.77,
    TRUE
),
(
    '001e8493-001e-4849-8001-001e8493001e',
    '000f4245-000f-4424-8000-000f4245000f',
    '00000002-0000-4000-8000-000000020000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.64,
    TRUE
),
(
    '001e8494-001e-4849-8001-001e8494001e',
    '000f4245-000f-4424-8000-000f4245000f',
    '00000002-0000-4000-8000-000000020000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.71,
    TRUE
),
(
    '001e8495-001e-4849-8001-001e8495001e',
    '000f4245-000f-4424-8000-000f4245000f',
    '00000002-0000-4000-8000-000000020000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.87,
    TRUE
),
(
    '001e8496-001e-4849-8001-001e8496001e',
    '000f4245-000f-4424-8000-000f4245000f',
    '00000002-0000-4000-8000-000000020000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.43,
    TRUE
),
(
    '001e8497-001e-4849-8001-001e8497001e',
    '000f4246-000f-4424-8000-000f4246000f',
    '00000003-0000-4000-8000-000000030000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    13.57,
    TRUE
),
(
    '001e8498-001e-4849-8001-001e8498001e',
    '000f4246-000f-4424-8000-000f4246000f',
    '00000003-0000-4000-8000-000000030000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.17,
    TRUE
),
(
    '001e8499-001e-4849-8001-001e8499001e',
    '000f4246-000f-4424-8000-000f4246000f',
    '00000003-0000-4000-8000-000000030000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.36,
    TRUE
),
(
    '001e849a-001e-4849-8001-001e849a001e',
    '000f4247-000f-4424-8000-000f4247000f',
    '00000003-0000-4000-8000-000000030000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.51,
    TRUE
),
(
    '001e849b-001e-4849-8001-001e849b001e',
    '000f4247-000f-4424-8000-000f4247000f',
    '00000003-0000-4000-8000-000000030000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.62,
    TRUE
),
(
    '001e849c-001e-4849-8001-001e849c001e',
    '000f4247-000f-4424-8000-000f4247000f',
    '00000003-0000-4000-8000-000000030000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.49,
    TRUE
),
(
    '001e849d-001e-4849-8001-001e849d001e',
    '000f4248-000f-4424-8000-000f4248000f',
    '00000003-0000-4000-8000-000000030000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.42,
    TRUE
),
(
    '001e849e-001e-4849-8001-001e849e001e',
    '000f4248-000f-4424-8000-000f4248000f',
    '00000003-0000-4000-8000-000000030000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.30,
    TRUE
),
(
    '001e849f-001e-4849-8001-001e849f001e',
    '000f4248-000f-4424-8000-000f4248000f',
    '00000003-0000-4000-8000-000000030000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.26,
    TRUE
),
(
    '001e84a0-001e-484a-8001-001e84a0001e',
    '000f4248-000f-4424-8000-000f4248000f',
    '00000003-0000-4000-8000-000000030000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.89,
    TRUE
),
(
    '001e84a1-001e-484a-8001-001e84a1001e',
    '000f4249-000f-4424-8000-000f4249000f',
    '00000004-0000-4000-8000-000000040000',
    'Salmon Roll',
    'Fresh salmon with rice and nori',
    8.08,
    TRUE
),
(
    '001e84a2-001e-484a-8001-001e84a2001e',
    '000f4249-000f-4424-8000-000f4249000f',
    '00000004-0000-4000-8000-000000040000',
    'Tuna Roll',
    'Premium tuna with rice and nori',
    10.20,
    TRUE
),
(
    '001e84a3-001e-484a-8001-001e84a3001e',
    '000f4249-000f-4424-8000-000f4249000f',
    '00000004-0000-4000-8000-000000040000',
    'California Roll',
    'Crab, avocado, and cucumber',
    8.45,
    TRUE
),
(
    '001e84a4-001e-484a-8001-001e84a4001e',
    '000f424a-000f-4424-8000-000f424a000f',
    '00000004-0000-4000-8000-000000040000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.99,
    TRUE
),
(
    '001e84a5-001e-484a-8001-001e84a5001e',
    '000f424a-000f-4424-8000-000f424a000f',
    '00000004-0000-4000-8000-000000040000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.66,
    TRUE
),
(
    '001e84a6-001e-484a-8001-001e84a6001e',
    '000f424a-000f-4424-8000-000f424a000f',
    '00000004-0000-4000-8000-000000040000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.46,
    TRUE
),
(
    '001e84a7-001e-484a-8001-001e84a7001e',
    '000f424a-000f-4424-8000-000f424a000f',
    '00000004-0000-4000-8000-000000040000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.51,
    TRUE
),
(
    '001e84a8-001e-484a-8001-001e84a8001e',
    '000f424b-000f-4424-8000-000f424b000f',
    '00000005-0000-4000-8000-000000050000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    13.09,
    TRUE
),
(
    '001e84a9-001e-484a-8001-001e84a9001e',
    '000f424b-000f-4424-8000-000f424b000f',
    '00000005-0000-4000-8000-000000050000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.41,
    TRUE
),
(
    '001e84aa-001e-484a-8001-001e84aa001e',
    '000f424b-000f-4424-8000-000f424b000f',
    '00000005-0000-4000-8000-000000050000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.84,
    TRUE
),
(
    '001e84ab-001e-484a-8001-001e84ab001e',
    '000f424b-000f-4424-8000-000f424b000f',
    '00000005-0000-4000-8000-000000050000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    15.49,
    TRUE
),
(
    '001e84ac-001e-484a-8001-001e84ac001e',
    '000f424c-000f-4424-8000-000f424c000f',
    '00000005-0000-4000-8000-000000050000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.88,
    TRUE
),
(
    '001e84ad-001e-484a-8001-001e84ad001e',
    '000f424c-000f-4424-8000-000f424c000f',
    '00000005-0000-4000-8000-000000050000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.36,
    TRUE
),
(
    '001e84ae-001e-484a-8001-001e84ae001e',
    '000f424c-000f-4424-8000-000f424c000f',
    '00000005-0000-4000-8000-000000050000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    12.48,
    TRUE
),
(
    '001e84af-001e-484a-8001-001e84af001e',
    '000f424d-000f-4424-8000-000f424d000f',
    '00000005-0000-4000-8000-000000050000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.31,
    TRUE
),
(
    '001e84b0-001e-484b-8001-001e84b0001e',
    '000f424d-000f-4424-8000-000f424d000f',
    '00000005-0000-4000-8000-000000050000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.50,
    TRUE
),
(
    '001e84b1-001e-484b-8001-001e84b1001e',
    '000f424d-000f-4424-8000-000f424d000f',
    '00000005-0000-4000-8000-000000050000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.76,
    TRUE
),
(
    '001e84b2-001e-484b-8001-001e84b2001e',
    '000f424e-000f-4424-8000-000f424e000f',
    '00000005-0000-4000-8000-000000050000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.09,
    TRUE
),
(
    '001e84b3-001e-484b-8001-001e84b3001e',
    '000f424e-000f-4424-8000-000f424e000f',
    '00000005-0000-4000-8000-000000050000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.87,
    TRUE
),
(
    '001e84b4-001e-484b-8001-001e84b4001e',
    '000f424e-000f-4424-8000-000f424e000f',
    '00000005-0000-4000-8000-000000050000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.38,
    TRUE
),
(
    '001e84b5-001e-484b-8001-001e84b5001e',
    '000f424e-000f-4424-8000-000f424e000f',
    '00000005-0000-4000-8000-000000050000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    5.99,
    TRUE
),
(
    '001e84b6-001e-484b-8001-001e84b6001e',
    '000f424f-000f-4424-8000-000f424f000f',
    '00000006-0000-4000-8000-000000060000',
    'Classic Burger',
    'Beef patty with lettuce, tomato, onion',
    11.62,
    TRUE
),
(
    '001e84b7-001e-484b-8001-001e84b7001e',
    '000f424f-000f-4424-8000-000f424f000f',
    '00000006-0000-4000-8000-000000060000',
    'Cheeseburger',
    'Beef patty with cheese and special sauce',
    12.72,
    TRUE
),
(
    '001e84b8-001e-484b-8001-001e84b8001e',
    '000f424f-000f-4424-8000-000f424f000f',
    '00000006-0000-4000-8000-000000060000',
    'Chicken Burger',
    'Grilled chicken breast with fixings',
    10.02,
    TRUE
),
(
    '001e84b9-001e-484b-8001-001e84b9001e',
    '000f4250-000f-4425-8000-000f4250000f',
    '00000006-0000-4000-8000-000000060000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.54,
    TRUE
),
(
    '001e84ba-001e-484b-8001-001e84ba001e',
    '000f4250-000f-4425-8000-000f4250000f',
    '00000006-0000-4000-8000-000000060000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.93,
    TRUE
),
(
    '001e84bb-001e-484b-8001-001e84bb001e',
    '000f4250-000f-4425-8000-000f4250000f',
    '00000006-0000-4000-8000-000000060000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.82,
    TRUE
),
(
    '001e84bc-001e-484b-8001-001e84bc001e',
    '000f4250-000f-4425-8000-000f4250000f',
    '00000006-0000-4000-8000-000000060000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.59,
    TRUE
),
(
    '001e84bd-001e-484b-8001-001e84bd001e',
    '000f4251-000f-4425-8000-000f4251000f',
    '00000006-0000-4000-8000-000000060000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.20,
    TRUE
),
(
    '001e84be-001e-484b-8001-001e84be001e',
    '000f4251-000f-4425-8000-000f4251000f',
    '00000006-0000-4000-8000-000000060000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.34,
    TRUE
),
(
    '001e84bf-001e-484b-8001-001e84bf001e',
    '000f4251-000f-4425-8000-000f4251000f',
    '00000006-0000-4000-8000-000000060000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.88,
    TRUE
),
(
    '001e84c0-001e-484c-8001-001e84c0001e',
    '000f4252-000f-4425-8000-000f4252000f',
    '00000007-0000-4000-8000-000000070000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.46,
    TRUE
),
(
    '001e84c1-001e-484c-8001-001e84c1001e',
    '000f4252-000f-4425-8000-000f4252000f',
    '00000007-0000-4000-8000-000000070000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.29,
    TRUE
),
(
    '001e84c2-001e-484c-8001-001e84c2001e',
    '000f4252-000f-4425-8000-000f4252000f',
    '00000007-0000-4000-8000-000000070000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.63,
    TRUE
),
(
    '001e84c3-001e-484c-8001-001e84c3001e',
    '000f4253-000f-4425-8000-000f4253000f',
    '00000007-0000-4000-8000-000000070000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.18,
    TRUE
),
(
    '001e84c4-001e-484c-8001-001e84c4001e',
    '000f4253-000f-4425-8000-000f4253000f',
    '00000007-0000-4000-8000-000000070000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.77,
    TRUE
),
(
    '001e84c5-001e-484c-8001-001e84c5001e',
    '000f4253-000f-4425-8000-000f4253000f',
    '00000007-0000-4000-8000-000000070000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.33,
    TRUE
),
(
    '001e84c6-001e-484c-8001-001e84c6001e',
    '000f4254-000f-4425-8000-000f4254000f',
    '00000007-0000-4000-8000-000000070000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.76,
    TRUE
),
(
    '001e84c7-001e-484c-8001-001e84c7001e',
    '000f4254-000f-4425-8000-000f4254000f',
    '00000007-0000-4000-8000-000000070000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.82,
    TRUE
),
(
    '001e84c8-001e-484c-8001-001e84c8001e',
    '000f4254-000f-4425-8000-000f4254000f',
    '00000007-0000-4000-8000-000000070000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.53,
    TRUE
),
(
    '001e84c9-001e-484c-8001-001e84c9001e',
    '000f4255-000f-4425-8000-000f4255000f',
    '00000007-0000-4000-8000-000000070000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.93,
    TRUE
),
(
    '001e84ca-001e-484c-8001-001e84ca001e',
    '000f4255-000f-4425-8000-000f4255000f',
    '00000007-0000-4000-8000-000000070000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.63,
    TRUE
),
(
    '001e84cb-001e-484c-8001-001e84cb001e',
    '000f4255-000f-4425-8000-000f4255000f',
    '00000007-0000-4000-8000-000000070000',
    'Cheesecake',
    'New York style cheesecake',
    7.70,
    TRUE
),
(
    '001e84cc-001e-484c-8001-001e84cc001e',
    '000f4255-000f-4425-8000-000f4255000f',
    '00000007-0000-4000-8000-000000070000',
    'Tiramisu',
    'Classic Italian dessert',
    7.88,
    TRUE
),
(
    '001e84cd-001e-484c-8001-001e84cd001e',
    '000f4256-000f-4425-8000-000f4256000f',
    '00000008-0000-4000-8000-000000080000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.54,
    TRUE
),
(
    '001e84ce-001e-484c-8001-001e84ce001e',
    '000f4256-000f-4425-8000-000f4256000f',
    '00000008-0000-4000-8000-000000080000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.71,
    TRUE
),
(
    '001e84cf-001e-484c-8001-001e84cf001e',
    '000f4256-000f-4425-8000-000f4256000f',
    '00000008-0000-4000-8000-000000080000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.03,
    TRUE
),
(
    '001e84d0-001e-484d-8001-001e84d0001e',
    '000f4257-000f-4425-8000-000f4257000f',
    '00000008-0000-4000-8000-000000080000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.37,
    TRUE
),
(
    '001e84d1-001e-484d-8001-001e84d1001e',
    '000f4257-000f-4425-8000-000f4257000f',
    '00000008-0000-4000-8000-000000080000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.58,
    TRUE
),
(
    '001e84d2-001e-484d-8001-001e84d2001e',
    '000f4257-000f-4425-8000-000f4257000f',
    '00000008-0000-4000-8000-000000080000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.28,
    TRUE
),
(
    '001e84d3-001e-484d-8001-001e84d3001e',
    '000f4257-000f-4425-8000-000f4257000f',
    '00000008-0000-4000-8000-000000080000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.35,
    TRUE
),
(
    '001e84d4-001e-484d-8001-001e84d4001e',
    '000f4258-000f-4425-8000-000f4258000f',
    '00000009-0000-4000-8000-000000090000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.18,
    TRUE
),
(
    '001e84d5-001e-484d-8001-001e84d5001e',
    '000f4258-000f-4425-8000-000f4258000f',
    '00000009-0000-4000-8000-000000090000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.46,
    TRUE
),
(
    '001e84d6-001e-484d-8001-001e84d6001e',
    '000f4258-000f-4425-8000-000f4258000f',
    '00000009-0000-4000-8000-000000090000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.98,
    TRUE
),
(
    '001e84d7-001e-484d-8001-001e84d7001e',
    '000f4259-000f-4425-8000-000f4259000f',
    '00000009-0000-4000-8000-000000090000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.20,
    TRUE
),
(
    '001e84d8-001e-484d-8001-001e84d8001e',
    '000f4259-000f-4425-8000-000f4259000f',
    '00000009-0000-4000-8000-000000090000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.51,
    TRUE
),
(
    '001e84d9-001e-484d-8001-001e84d9001e',
    '000f4259-000f-4425-8000-000f4259000f',
    '00000009-0000-4000-8000-000000090000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.48,
    TRUE
),
(
    '001e84da-001e-484d-8001-001e84da001e',
    '000f4259-000f-4425-8000-000f4259000f',
    '00000009-0000-4000-8000-000000090000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.67,
    TRUE
),
(
    '001e84db-001e-484d-8001-001e84db001e',
    '000f425a-000f-4425-8000-000f425a000f',
    '00000009-0000-4000-8000-000000090000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    14.73,
    TRUE
),
(
    '001e84dc-001e-484d-8001-001e84dc001e',
    '000f425a-000f-4425-8000-000f425a000f',
    '00000009-0000-4000-8000-000000090000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.88,
    TRUE
),
(
    '001e84dd-001e-484d-8001-001e84dd001e',
    '000f425a-000f-4425-8000-000f425a000f',
    '00000009-0000-4000-8000-000000090000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    12.31,
    TRUE
),
(
    '001e84de-001e-484d-8001-001e84de001e',
    '000f425a-000f-4425-8000-000f425a000f',
    '00000009-0000-4000-8000-000000090000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    11.58,
    TRUE
),
(
    '001e84df-001e-484d-8001-001e84df001e',
    '000f425a-000f-4425-8000-000f425a000f',
    '00000009-0000-4000-8000-000000090000',
    'Pad Thai',
    'Thai-style stir-fried noodles',
    13.43,
    TRUE
),
(
    '001e84e0-001e-484e-8001-001e84e0001e',
    '000f425b-000f-4425-8000-000f425b000f',
    '00000009-0000-4000-8000-000000090000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.45,
    TRUE
),
(
    '001e84e1-001e-484e-8001-001e84e1001e',
    '000f425b-000f-4425-8000-000f425b000f',
    '00000009-0000-4000-8000-000000090000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.11,
    TRUE
),
(
    '001e84e2-001e-484e-8001-001e84e2001e',
    '000f425b-000f-4425-8000-000f425b000f',
    '00000009-0000-4000-8000-000000090000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.24,
    TRUE
),
(
    '001e84e3-001e-484e-8001-001e84e3001e',
    '000f425b-000f-4425-8000-000f425b000f',
    '00000009-0000-4000-8000-000000090000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.51,
    TRUE
),
(
    '001e84e4-001e-484e-8001-001e84e4001e',
    '000f425c-000f-4425-8000-000f425c000f',
    '0000000a-0000-4000-8000-0000000a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.97,
    TRUE
),
(
    '001e84e5-001e-484e-8001-001e84e5001e',
    '000f425c-000f-4425-8000-000f425c000f',
    '0000000a-0000-4000-8000-0000000a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.18,
    TRUE
),
(
    '001e84e6-001e-484e-8001-001e84e6001e',
    '000f425c-000f-4425-8000-000f425c000f',
    '0000000a-0000-4000-8000-0000000a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.75,
    TRUE
),
(
    '001e84e7-001e-484e-8001-001e84e7001e',
    '000f425d-000f-4425-8000-000f425d000f',
    '0000000a-0000-4000-8000-0000000a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.42,
    TRUE
),
(
    '001e84e8-001e-484e-8001-001e84e8001e',
    '000f425d-000f-4425-8000-000f425d000f',
    '0000000a-0000-4000-8000-0000000a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.42,
    TRUE
),
(
    '001e84e9-001e-484e-8001-001e84e9001e',
    '000f425d-000f-4425-8000-000f425d000f',
    '0000000a-0000-4000-8000-0000000a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.62,
    TRUE
),
(
    '001e84ea-001e-484e-8001-001e84ea001e',
    '000f425d-000f-4425-8000-000f425d000f',
    '0000000a-0000-4000-8000-0000000a0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.48,
    TRUE
),
(
    '001e84eb-001e-484e-8001-001e84eb001e',
    '000f425e-000f-4425-8000-000f425e000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.69,
    TRUE
),
(
    '001e84ec-001e-484e-8001-001e84ec001e',
    '000f425e-000f-4425-8000-000f425e000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.53,
    TRUE
),
(
    '001e84ed-001e-484e-8001-001e84ed001e',
    '000f425e-000f-4425-8000-000f425e000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.91,
    TRUE
),
(
    '001e84ee-001e-484e-8001-001e84ee001e',
    '000f425e-000f-4425-8000-000f425e000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.32,
    TRUE
),
(
    '001e84ef-001e-484e-8001-001e84ef001e',
    '000f425f-000f-4425-8000-000f425f000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.37,
    TRUE
),
(
    '001e84f0-001e-484f-8001-001e84f0001e',
    '000f425f-000f-4425-8000-000f425f000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.28,
    TRUE
),
(
    '001e84f1-001e-484f-8001-001e84f1001e',
    '000f425f-000f-4425-8000-000f425f000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.19,
    TRUE
),
(
    '001e84f2-001e-484f-8001-001e84f2001e',
    '000f425f-000f-4425-8000-000f425f000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.04,
    TRUE
),
(
    '001e84f3-001e-484f-8001-001e84f3001e',
    '000f4260-000f-4426-8000-000f4260000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.84,
    TRUE
),
(
    '001e84f4-001e-484f-8001-001e84f4001e',
    '000f4260-000f-4426-8000-000f4260000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.24,
    TRUE
),
(
    '001e84f5-001e-484f-8001-001e84f5001e',
    '000f4260-000f-4426-8000-000f4260000f',
    '0000000b-0000-4000-8000-0000000b0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.14,
    TRUE
),
(
    '001e84f6-001e-484f-8001-001e84f6001e',
    '000f4261-000f-4426-8000-000f4261000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.26,
    TRUE
),
(
    '001e84f7-001e-484f-8001-001e84f7001e',
    '000f4261-000f-4426-8000-000f4261000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.51,
    TRUE
),
(
    '001e84f8-001e-484f-8001-001e84f8001e',
    '000f4261-000f-4426-8000-000f4261000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.46,
    TRUE
),
(
    '001e84f9-001e-484f-8001-001e84f9001e',
    '000f4261-000f-4426-8000-000f4261000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.36,
    TRUE
),
(
    '001e84fa-001e-484f-8001-001e84fa001e',
    '000f4262-000f-4426-8000-000f4262000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.77,
    TRUE
),
(
    '001e84fb-001e-484f-8001-001e84fb001e',
    '000f4262-000f-4426-8000-000f4262000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.82,
    TRUE
),
(
    '001e84fc-001e-484f-8001-001e84fc001e',
    '000f4262-000f-4426-8000-000f4262000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.00,
    TRUE
),
(
    '001e84fd-001e-484f-8001-001e84fd001e',
    '000f4263-000f-4426-8000-000f4263000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.77,
    TRUE
),
(
    '001e84fe-001e-484f-8001-001e84fe001e',
    '000f4263-000f-4426-8000-000f4263000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.61,
    TRUE
),
(
    '001e84ff-001e-484f-8001-001e84ff001e',
    '000f4263-000f-4426-8000-000f4263000f',
    '0000000c-0000-4000-8000-0000000c0000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.96,
    TRUE
),
(
    '001e8500-001e-4850-8001-001e8500001e',
    '000f4264-000f-4426-8000-000f4264000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.90,
    TRUE
),
(
    '001e8501-001e-4850-8001-001e8501001e',
    '000f4264-000f-4426-8000-000f4264000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.25,
    TRUE
),
(
    '001e8502-001e-4850-8001-001e8502001e',
    '000f4264-000f-4426-8000-000f4264000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.46,
    TRUE
),
(
    '001e8503-001e-4850-8001-001e8503001e',
    '000f4264-000f-4426-8000-000f4264000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.46,
    TRUE
),
(
    '001e8504-001e-4850-8001-001e8504001e',
    '000f4265-000f-4426-8000-000f4265000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.04,
    TRUE
),
(
    '001e8505-001e-4850-8001-001e8505001e',
    '000f4265-000f-4426-8000-000f4265000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.47,
    TRUE
),
(
    '001e8506-001e-4850-8001-001e8506001e',
    '000f4265-000f-4426-8000-000f4265000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.20,
    TRUE
),
(
    '001e8507-001e-4850-8001-001e8507001e',
    '000f4265-000f-4426-8000-000f4265000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.92,
    TRUE
),
(
    '001e8508-001e-4850-8001-001e8508001e',
    '000f4266-000f-4426-8000-000f4266000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.78,
    TRUE
),
(
    '001e8509-001e-4850-8001-001e8509001e',
    '000f4266-000f-4426-8000-000f4266000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.58,
    TRUE
),
(
    '001e850a-001e-4850-8001-001e850a001e',
    '000f4266-000f-4426-8000-000f4266000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.13,
    TRUE
),
(
    '001e850b-001e-4850-8001-001e850b001e',
    '000f4266-000f-4426-8000-000f4266000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.31,
    TRUE
),
(
    '001e850c-001e-4850-8001-001e850c001e',
    '000f4267-000f-4426-8000-000f4267000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.55,
    TRUE
),
(
    '001e850d-001e-4850-8001-001e850d001e',
    '000f4267-000f-4426-8000-000f4267000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.90,
    TRUE
),
(
    '001e850e-001e-4850-8001-001e850e001e',
    '000f4267-000f-4426-8000-000f4267000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Cheesecake',
    'New York style cheesecake',
    7.92,
    TRUE
),
(
    '001e850f-001e-4850-8001-001e850f001e',
    '000f4267-000f-4426-8000-000f4267000f',
    '0000000d-0000-4000-8000-0000000d0000',
    'Tiramisu',
    'Classic Italian dessert',
    8.43,
    TRUE
),
(
    '001e8510-001e-4851-8001-001e8510001e',
    '000f4268-000f-4426-8000-000f4268000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.30,
    TRUE
),
(
    '001e8511-001e-4851-8001-001e8511001e',
    '000f4268-000f-4426-8000-000f4268000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.58,
    TRUE
),
(
    '001e8512-001e-4851-8001-001e8512001e',
    '000f4268-000f-4426-8000-000f4268000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.67,
    TRUE
),
(
    '001e8513-001e-4851-8001-001e8513001e',
    '000f4269-000f-4426-8000-000f4269000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.90,
    TRUE
),
(
    '001e8514-001e-4851-8001-001e8514001e',
    '000f4269-000f-4426-8000-000f4269000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.35,
    TRUE
),
(
    '001e8515-001e-4851-8001-001e8515001e',
    '000f4269-000f-4426-8000-000f4269000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.54,
    TRUE
),
(
    '001e8516-001e-4851-8001-001e8516001e',
    '000f426a-000f-4426-8000-000f426a000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.63,
    TRUE
),
(
    '001e8517-001e-4851-8001-001e8517001e',
    '000f426a-000f-4426-8000-000f426a000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.30,
    TRUE
),
(
    '001e8518-001e-4851-8001-001e8518001e',
    '000f426a-000f-4426-8000-000f426a000f',
    '0000000e-0000-4000-8000-0000000e0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.33,
    TRUE
),
(
    '001e8519-001e-4851-8001-001e8519001e',
    '000f426b-000f-4426-8000-000f426b000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.38,
    TRUE
),
(
    '001e851a-001e-4851-8001-001e851a001e',
    '000f426b-000f-4426-8000-000f426b000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.07,
    TRUE
),
(
    '001e851b-001e-4851-8001-001e851b001e',
    '000f426b-000f-4426-8000-000f426b000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.24,
    TRUE
),
(
    '001e851c-001e-4851-8001-001e851c001e',
    '000f426b-000f-4426-8000-000f426b000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.51,
    TRUE
),
(
    '001e851d-001e-4851-8001-001e851d001e',
    '000f426c-000f-4426-8000-000f426c000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.27,
    TRUE
),
(
    '001e851e-001e-4851-8001-001e851e001e',
    '000f426c-000f-4426-8000-000f426c000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.27,
    TRUE
),
(
    '001e851f-001e-4851-8001-001e851f001e',
    '000f426c-000f-4426-8000-000f426c000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Risotto',
    'Creamy Italian rice dish',
    12.36,
    TRUE
),
(
    '001e8520-001e-4852-8001-001e8520001e',
    '000f426d-000f-4426-8000-000f426d000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.42,
    TRUE
),
(
    '001e8521-001e-4852-8001-001e8521001e',
    '000f426d-000f-4426-8000-000f426d000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.42,
    TRUE
),
(
    '001e8522-001e-4852-8001-001e8522001e',
    '000f426d-000f-4426-8000-000f426d000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.55,
    TRUE
),
(
    '001e8523-001e-4852-8001-001e8523001e',
    '000f426d-000f-4426-8000-000f426d000f',
    '0000000f-0000-4000-8000-0000000f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.47,
    TRUE
),
(
    '001e8524-001e-4852-8001-001e8524001e',
    '000f426e-000f-4426-8000-000f426e000f',
    '00000010-0000-4001-8000-000000100000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.74,
    TRUE
),
(
    '001e8525-001e-4852-8001-001e8525001e',
    '000f426e-000f-4426-8000-000f426e000f',
    '00000010-0000-4001-8000-000000100000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.07,
    TRUE
),
(
    '001e8526-001e-4852-8001-001e8526001e',
    '000f426e-000f-4426-8000-000f426e000f',
    '00000010-0000-4001-8000-000000100000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.58,
    TRUE
),
(
    '001e8527-001e-4852-8001-001e8527001e',
    '000f426e-000f-4426-8000-000f426e000f',
    '00000010-0000-4001-8000-000000100000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.04,
    TRUE
),
(
    '001e8528-001e-4852-8001-001e8528001e',
    '000f426f-000f-4426-8000-000f426f000f',
    '00000010-0000-4001-8000-000000100000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.71,
    TRUE
),
(
    '001e8529-001e-4852-8001-001e8529001e',
    '000f426f-000f-4426-8000-000f426f000f',
    '00000010-0000-4001-8000-000000100000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.39,
    TRUE
),
(
    '001e852a-001e-4852-8001-001e852a001e',
    '000f426f-000f-4426-8000-000f426f000f',
    '00000010-0000-4001-8000-000000100000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.95,
    TRUE
),
(
    '001e852b-001e-4852-8001-001e852b001e',
    '000f4270-000f-4427-8000-000f4270000f',
    '00000011-0000-4001-8000-000000110000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.28,
    TRUE
),
(
    '001e852c-001e-4852-8001-001e852c001e',
    '000f4270-000f-4427-8000-000f4270000f',
    '00000011-0000-4001-8000-000000110000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.84,
    TRUE
),
(
    '001e852d-001e-4852-8001-001e852d001e',
    '000f4270-000f-4427-8000-000f4270000f',
    '00000011-0000-4001-8000-000000110000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.88,
    TRUE
),
(
    '001e852e-001e-4852-8001-001e852e001e',
    '000f4270-000f-4427-8000-000f4270000f',
    '00000011-0000-4001-8000-000000110000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.47,
    TRUE
),
(
    '001e852f-001e-4852-8001-001e852f001e',
    '000f4271-000f-4427-8000-000f4271000f',
    '00000011-0000-4001-8000-000000110000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.03,
    TRUE
),
(
    '001e8530-001e-4853-8001-001e8530001e',
    '000f4271-000f-4427-8000-000f4271000f',
    '00000011-0000-4001-8000-000000110000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.75,
    TRUE
),
(
    '001e8531-001e-4853-8001-001e8531001e',
    '000f4271-000f-4427-8000-000f4271000f',
    '00000011-0000-4001-8000-000000110000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.61,
    TRUE
),
(
    '001e8532-001e-4853-8001-001e8532001e',
    '000f4272-000f-4427-8000-000f4272000f',
    '00000011-0000-4001-8000-000000110000',
    'French Fries',
    'Crispy golden fries',
    4.32,
    TRUE
),
(
    '001e8533-001e-4853-8001-001e8533001e',
    '000f4272-000f-4427-8000-000f4272000f',
    '00000011-0000-4001-8000-000000110000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.10,
    TRUE
),
(
    '001e8534-001e-4853-8001-001e8534001e',
    '000f4272-000f-4427-8000-000f4272000f',
    '00000011-0000-4001-8000-000000110000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.62,
    TRUE
),
(
    '001e8535-001e-4853-8001-001e8535001e',
    '000f4273-000f-4427-8000-000f4273000f',
    '00000011-0000-4001-8000-000000110000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.54,
    TRUE
),
(
    '001e8536-001e-4853-8001-001e8536001e',
    '000f4273-000f-4427-8000-000f4273000f',
    '00000011-0000-4001-8000-000000110000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.61,
    TRUE
),
(
    '001e8537-001e-4853-8001-001e8537001e',
    '000f4273-000f-4427-8000-000f4273000f',
    '00000011-0000-4001-8000-000000110000',
    'Cheesecake',
    'New York style cheesecake',
    7.44,
    TRUE
),
(
    '001e8538-001e-4853-8001-001e8538001e',
    '000f4273-000f-4427-8000-000f4273000f',
    '00000011-0000-4001-8000-000000110000',
    'Tiramisu',
    'Classic Italian dessert',
    7.71,
    TRUE
),
(
    '001e8539-001e-4853-8001-001e8539001e',
    '000f4274-000f-4427-8000-000f4274000f',
    '00000012-0000-4001-8000-000000120000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.99,
    TRUE
),
(
    '001e853a-001e-4853-8001-001e853a001e',
    '000f4274-000f-4427-8000-000f4274000f',
    '00000012-0000-4001-8000-000000120000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.43,
    TRUE
),
(
    '001e853b-001e-4853-8001-001e853b001e',
    '000f4274-000f-4427-8000-000f4274000f',
    '00000012-0000-4001-8000-000000120000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.83,
    TRUE
),
(
    '001e853c-001e-4853-8001-001e853c001e',
    '000f4275-000f-4427-8000-000f4275000f',
    '00000012-0000-4001-8000-000000120000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.60,
    TRUE
),
(
    '001e853d-001e-4853-8001-001e853d001e',
    '000f4275-000f-4427-8000-000f4275000f',
    '00000012-0000-4001-8000-000000120000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.40,
    TRUE
),
(
    '001e853e-001e-4853-8001-001e853e001e',
    '000f4275-000f-4427-8000-000f4275000f',
    '00000012-0000-4001-8000-000000120000',
    'Risotto',
    'Creamy Italian rice dish',
    12.30,
    TRUE
),
(
    '001e853f-001e-4853-8001-001e853f001e',
    '000f4276-000f-4427-8000-000f4276000f',
    '00000012-0000-4001-8000-000000120000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.08,
    TRUE
),
(
    '001e8540-001e-4854-8001-001e8540001e',
    '000f4276-000f-4427-8000-000f4276000f',
    '00000012-0000-4001-8000-000000120000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.21,
    TRUE
),
(
    '001e8541-001e-4854-8001-001e8541001e',
    '000f4276-000f-4427-8000-000f4276000f',
    '00000012-0000-4001-8000-000000120000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.85,
    TRUE
),
(
    '001e8542-001e-4854-8001-001e8542001e',
    '000f4277-000f-4427-8000-000f4277000f',
    '00000012-0000-4001-8000-000000120000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.81,
    TRUE
),
(
    '001e8543-001e-4854-8001-001e8543001e',
    '000f4277-000f-4427-8000-000f4277000f',
    '00000012-0000-4001-8000-000000120000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.45,
    TRUE
),
(
    '001e8544-001e-4854-8001-001e8544001e',
    '000f4277-000f-4427-8000-000f4277000f',
    '00000012-0000-4001-8000-000000120000',
    'Cheesecake',
    'New York style cheesecake',
    7.65,
    TRUE
),
(
    '001e8545-001e-4854-8001-001e8545001e',
    '000f4277-000f-4427-8000-000f4277000f',
    '00000012-0000-4001-8000-000000120000',
    'Tiramisu',
    'Classic Italian dessert',
    7.92,
    TRUE
),
(
    '001e8546-001e-4854-8001-001e8546001e',
    '000f4278-000f-4427-8000-000f4278000f',
    '00000013-0000-4001-8000-000000130000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.28,
    TRUE
),
(
    '001e8547-001e-4854-8001-001e8547001e',
    '000f4278-000f-4427-8000-000f4278000f',
    '00000013-0000-4001-8000-000000130000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.86,
    TRUE
),
(
    '001e8548-001e-4854-8001-001e8548001e',
    '000f4278-000f-4427-8000-000f4278000f',
    '00000013-0000-4001-8000-000000130000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.22,
    TRUE
),
(
    '001e8549-001e-4854-8001-001e8549001e',
    '000f4279-000f-4427-8000-000f4279000f',
    '00000013-0000-4001-8000-000000130000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.37,
    TRUE
),
(
    '001e854a-001e-4854-8001-001e854a001e',
    '000f4279-000f-4427-8000-000f4279000f',
    '00000013-0000-4001-8000-000000130000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.56,
    TRUE
),
(
    '001e854b-001e-4854-8001-001e854b001e',
    '000f4279-000f-4427-8000-000f4279000f',
    '00000013-0000-4001-8000-000000130000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.05,
    TRUE
),
(
    '001e854c-001e-4854-8001-001e854c001e',
    '000f4279-000f-4427-8000-000f4279000f',
    '00000013-0000-4001-8000-000000130000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.84,
    TRUE
),
(
    '001e854d-001e-4854-8001-001e854d001e',
    '000f427a-000f-4427-8000-000f427a000f',
    '00000014-0000-4001-8000-000000140000',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    12.63,
    TRUE
),
(
    '001e854e-001e-4854-8001-001e854e001e',
    '000f427a-000f-4427-8000-000f427a000f',
    '00000014-0000-4001-8000-000000140000',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    14.24,
    TRUE
),
(
    '001e854f-001e-4854-8001-001e854f001e',
    '000f427a-000f-4427-8000-000f427a000f',
    '00000014-0000-4001-8000-000000140000',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives',
    15.73,
    TRUE
),
(
    '001e8550-001e-4855-8001-001e8550001e',
    '000f427a-000f-4427-8000-000f427a000f',
    '00000014-0000-4001-8000-000000140000',
    'Hawaiian',
    'Ham, pineapple, mozzarella',
    13.29,
    TRUE
),
(
    '001e8551-001e-4855-8001-001e8551001e',
    '000f427b-000f-4427-8000-000f427b000f',
    '00000014-0000-4001-8000-000000140000',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino',
    14.77,
    TRUE
),
(
    '001e8552-001e-4855-8001-001e8552001e',
    '000f427b-000f-4427-8000-000f427b000f',
    '00000014-0000-4001-8000-000000140000',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    12.63,
    TRUE
),
(
    '001e8553-001e-4855-8001-001e8553001e',
    '000f427b-000f-4427-8000-000f427b000f',
    '00000014-0000-4001-8000-000000140000',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream',
    14.45,
    TRUE
),
(
    '001e8554-001e-4855-8001-001e8554001e',
    '000f427b-000f-4427-8000-000f427b000f',
    '00000014-0000-4001-8000-000000140000',
    'Lasagna',
    'Layered pasta with meat sauce and cheese',
    14.20,
    TRUE
),
(
    '001e8555-001e-4855-8001-001e8555001e',
    '000f427c-000f-4427-8000-000f427c000f',
    '00000014-0000-4001-8000-000000140000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.13,
    TRUE
),
(
    '001e8556-001e-4855-8001-001e8556001e',
    '000f427c-000f-4427-8000-000f427c000f',
    '00000014-0000-4001-8000-000000140000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.64,
    TRUE
),
(
    '001e8557-001e-4855-8001-001e8557001e',
    '000f427c-000f-4427-8000-000f427c000f',
    '00000014-0000-4001-8000-000000140000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.66,
    TRUE
),
(
    '001e8558-001e-4855-8001-001e8558001e',
    '000f427d-000f-4427-8000-000f427d000f',
    '00000015-0000-4001-8000-000000150000',
    'Har Gow',
    'Steamed shrimp dumplings',
    8.45,
    TRUE
),
(
    '001e8559-001e-4855-8001-001e8559001e',
    '000f427d-000f-4427-8000-000f427d000f',
    '00000015-0000-4001-8000-000000150000',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    8.64,
    TRUE
),
(
    '001e855a-001e-4855-8001-001e855a001e',
    '000f427d-000f-4427-8000-000f427d000f',
    '00000015-0000-4001-8000-000000150000',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    8.26,
    TRUE
),
(
    '001e855b-001e-4855-8001-001e855b001e',
    '000f427e-000f-4427-8000-000f427e000f',
    '00000015-0000-4001-8000-000000150000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.86,
    TRUE
),
(
    '001e855c-001e-4855-8001-001e855c001e',
    '000f427e-000f-4427-8000-000f427e000f',
    '00000015-0000-4001-8000-000000150000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.56,
    TRUE
),
(
    '001e855d-001e-4855-8001-001e855d001e',
    '000f427e-000f-4427-8000-000f427e000f',
    '00000015-0000-4001-8000-000000150000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    12.41,
    TRUE
),
(
    '001e855e-001e-4855-8001-001e855e001e',
    '000f427f-000f-4427-8000-000f427f000f',
    '00000015-0000-4001-8000-000000150000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.78,
    TRUE
),
(
    '001e855f-001e-4855-8001-001e855f001e',
    '000f427f-000f-4427-8000-000f427f000f',
    '00000015-0000-4001-8000-000000150000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.22,
    TRUE
),
(
    '001e8560-001e-4856-8001-001e8560001e',
    '000f427f-000f-4427-8000-000f427f000f',
    '00000015-0000-4001-8000-000000150000',
    'Risotto',
    'Creamy Italian rice dish',
    12.03,
    TRUE
),
(
    '001e8561-001e-4856-8001-001e8561001e',
    '000f4280-000f-4428-8000-000f4280000f',
    '00000016-0000-4001-8000-000000160000',
    'Beef Tacos',
    'Seasoned ground beef with lettuce and cheese',
    9.11,
    TRUE
),
(
    '001e8562-001e-4856-8001-001e8562001e',
    '000f4280-000f-4428-8000-000f4280000f',
    '00000016-0000-4001-8000-000000160000',
    'Chicken Tacos',
    'Grilled chicken with salsa and avocado',
    9.28,
    TRUE
),
(
    '001e8563-001e-4856-8001-001e8563001e',
    '000f4280-000f-4428-8000-000f4280000f',
    '00000016-0000-4001-8000-000000160000',
    'Fish Tacos',
    'Battered fish with cabbage slaw',
    10.13,
    TRUE
),
(
    '001e8564-001e-4856-8001-001e8564001e',
    '000f4280-000f-4428-8000-000f4280000f',
    '00000016-0000-4001-8000-000000160000',
    'Vegetarian Tacos',
    'Black beans, corn, and vegetables',
    9.95,
    TRUE
),
(
    '001e8565-001e-4856-8001-001e8565001e',
    '000f4281-000f-4428-8000-000f4281000f',
    '00000016-0000-4001-8000-000000160000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.84,
    TRUE
),
(
    '001e8566-001e-4856-8001-001e8566001e',
    '000f4281-000f-4428-8000-000f4281000f',
    '00000016-0000-4001-8000-000000160000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.17,
    TRUE
),
(
    '001e8567-001e-4856-8001-001e8567001e',
    '000f4281-000f-4428-8000-000f4281000f',
    '00000016-0000-4001-8000-000000160000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.90,
    TRUE
),
(
    '001e8568-001e-4856-8001-001e8568001e',
    '000f4281-000f-4428-8000-000f4281000f',
    '00000016-0000-4001-8000-000000160000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.55,
    TRUE
),
(
    '001e8569-001e-4856-8001-001e8569001e',
    '000f4282-000f-4428-8000-000f4282000f',
    '00000016-0000-4001-8000-000000160000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.32,
    TRUE
),
(
    '001e856a-001e-4856-8001-001e856a001e',
    '000f4282-000f-4428-8000-000f4282000f',
    '00000016-0000-4001-8000-000000160000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.19,
    TRUE
),
(
    '001e856b-001e-4856-8001-001e856b001e',
    '000f4282-000f-4428-8000-000f4282000f',
    '00000016-0000-4001-8000-000000160000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.96,
    TRUE
),
(
    '001e856c-001e-4856-8001-001e856c001e',
    '000f4282-000f-4428-8000-000f4282000f',
    '00000016-0000-4001-8000-000000160000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.04,
    TRUE
),
(
    '001e856d-001e-4856-8001-001e856d001e',
    '000f4283-000f-4428-8000-000f4283000f',
    '00000017-0000-4001-8000-000000170000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    13.69,
    TRUE
),
(
    '001e856e-001e-4856-8001-001e856e001e',
    '000f4283-000f-4428-8000-000f4283000f',
    '00000017-0000-4001-8000-000000170000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.33,
    TRUE
),
(
    '001e856f-001e-4856-8001-001e856f001e',
    '000f4283-000f-4428-8000-000f4283000f',
    '00000017-0000-4001-8000-000000170000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    12.21,
    TRUE
),
(
    '001e8570-001e-4857-8001-001e8570001e',
    '000f4284-000f-4428-8000-000f4284000f',
    '00000017-0000-4001-8000-000000170000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.76,
    TRUE
),
(
    '001e8571-001e-4857-8001-001e8571001e',
    '000f4284-000f-4428-8000-000f4284000f',
    '00000017-0000-4001-8000-000000170000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.96,
    TRUE
),
(
    '001e8572-001e-4857-8001-001e8572001e',
    '000f4284-000f-4428-8000-000f4284000f',
    '00000017-0000-4001-8000-000000170000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.85,
    TRUE
),
(
    '001e8573-001e-4857-8001-001e8573001e',
    '000f4284-000f-4428-8000-000f4284000f',
    '00000017-0000-4001-8000-000000170000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.60,
    TRUE
),
(
    '001e8574-001e-4857-8001-001e8574001e',
    '000f4285-000f-4428-8000-000f4285000f',
    '00000017-0000-4001-8000-000000170000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.42,
    TRUE
),
(
    '001e8575-001e-4857-8001-001e8575001e',
    '000f4285-000f-4428-8000-000f4285000f',
    '00000017-0000-4001-8000-000000170000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.14,
    TRUE
),
(
    '001e8576-001e-4857-8001-001e8576001e',
    '000f4285-000f-4428-8000-000f4285000f',
    '00000017-0000-4001-8000-000000170000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.88,
    TRUE
),
(
    '001e8577-001e-4857-8001-001e8577001e',
    '000f4285-000f-4428-8000-000f4285000f',
    '00000017-0000-4001-8000-000000170000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.66,
    TRUE
),
(
    '001e8578-001e-4857-8001-001e8578001e',
    '000f4286-000f-4428-8000-000f4286000f',
    '00000018-0000-4001-8000-000000180000',
    'Salmon Roll',
    'Fresh salmon with rice and nori',
    9.86,
    TRUE
),
(
    '001e8579-001e-4857-8001-001e8579001e',
    '000f4286-000f-4428-8000-000f4286000f',
    '00000018-0000-4001-8000-000000180000',
    'Tuna Roll',
    'Premium tuna with rice and nori',
    10.78,
    TRUE
),
(
    '001e857a-001e-4857-8001-001e857a001e',
    '000f4286-000f-4428-8000-000f4286000f',
    '00000018-0000-4001-8000-000000180000',
    'California Roll',
    'Crab, avocado, and cucumber',
    7.47,
    TRUE
),
(
    '001e857b-001e-4857-8001-001e857b001e',
    '000f4287-000f-4428-8000-000f4287000f',
    '00000018-0000-4001-8000-000000180000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.73,
    TRUE
),
(
    '001e857c-001e-4857-8001-001e857c001e',
    '000f4287-000f-4428-8000-000f4287000f',
    '00000018-0000-4001-8000-000000180000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.02,
    TRUE
),
(
    '001e857d-001e-4857-8001-001e857d001e',
    '000f4287-000f-4428-8000-000f4287000f',
    '00000018-0000-4001-8000-000000180000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.90,
    TRUE
),
(
    '001e857e-001e-4857-8001-001e857e001e',
    '000f4288-000f-4428-8000-000f4288000f',
    '00000019-0000-4001-8000-000000190000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    13.32,
    TRUE
),
(
    '001e857f-001e-4857-8001-001e857f001e',
    '000f4288-000f-4428-8000-000f4288000f',
    '00000019-0000-4001-8000-000000190000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.91,
    TRUE
),
(
    '001e8580-001e-4858-8001-001e8580001e',
    '000f4288-000f-4428-8000-000f4288000f',
    '00000019-0000-4001-8000-000000190000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    12.58,
    TRUE
),
(
    '001e8581-001e-4858-8001-001e8581001e',
    '000f4289-000f-4428-8000-000f4289000f',
    '00000019-0000-4001-8000-000000190000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.02,
    TRUE
),
(
    '001e8582-001e-4858-8001-001e8582001e',
    '000f4289-000f-4428-8000-000f4289000f',
    '00000019-0000-4001-8000-000000190000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.85,
    TRUE
),
(
    '001e8583-001e-4858-8001-001e8583001e',
    '000f4289-000f-4428-8000-000f4289000f',
    '00000019-0000-4001-8000-000000190000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.01,
    TRUE
),
(
    '001e8584-001e-4858-8001-001e8584001e',
    '000f4289-000f-4428-8000-000f4289000f',
    '00000019-0000-4001-8000-000000190000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    12.81,
    TRUE
),
(
    '001e8585-001e-4858-8001-001e8585001e',
    '000f4289-000f-4428-8000-000f4289000f',
    '00000019-0000-4001-8000-000000190000',
    'Pad Thai',
    'Thai-style stir-fried noodles',
    13.32,
    TRUE
),
(
    '001e8586-001e-4858-8001-001e8586001e',
    '000f428a-000f-4428-8000-000f428a000f',
    '00000019-0000-4001-8000-000000190000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.19,
    TRUE
),
(
    '001e8587-001e-4858-8001-001e8587001e',
    '000f428a-000f-4428-8000-000f428a000f',
    '00000019-0000-4001-8000-000000190000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.32,
    TRUE
),
(
    '001e8588-001e-4858-8001-001e8588001e',
    '000f428a-000f-4428-8000-000f428a000f',
    '00000019-0000-4001-8000-000000190000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.16,
    TRUE
),
(
    '001e8589-001e-4858-8001-001e8589001e',
    '000f428a-000f-4428-8000-000f428a000f',
    '00000019-0000-4001-8000-000000190000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.16,
    TRUE
),
(
    '001e858a-001e-4858-8001-001e858a001e',
    '000f428b-000f-4428-8000-000f428b000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Classic Burger',
    'Beef patty with lettuce, tomato, onion',
    11.42,
    TRUE
),
(
    '001e858b-001e-4858-8001-001e858b001e',
    '000f428b-000f-4428-8000-000f428b000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Cheeseburger',
    'Beef patty with cheese and special sauce',
    11.72,
    TRUE
),
(
    '001e858c-001e-4858-8001-001e858c001e',
    '000f428b-000f-4428-8000-000f428b000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Chicken Burger',
    'Grilled chicken breast with fixings',
    9.69,
    TRUE
),
(
    '001e858d-001e-4858-8001-001e858d001e',
    '000f428c-000f-4428-8000-000f428c000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.09,
    TRUE
),
(
    '001e858e-001e-4858-8001-001e858e001e',
    '000f428c-000f-4428-8000-000f428c000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.26,
    TRUE
),
(
    '001e858f-001e-4858-8001-001e858f001e',
    '000f428c-000f-4428-8000-000f428c000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.70,
    TRUE
),
(
    '001e8590-001e-4859-8001-001e8590001e',
    '000f428c-000f-4428-8000-000f428c000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.92,
    TRUE
),
(
    '001e8591-001e-4859-8001-001e8591001e',
    '000f428d-000f-4428-8000-000f428d000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.08,
    TRUE
),
(
    '001e8592-001e-4859-8001-001e8592001e',
    '000f428d-000f-4428-8000-000f428d000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.65,
    TRUE
),
(
    '001e8593-001e-4859-8001-001e8593001e',
    '000f428d-000f-4428-8000-000f428d000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.45,
    TRUE
),
(
    '001e8594-001e-4859-8001-001e8594001e',
    '000f428e-000f-4428-8000-000f428e000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'French Fries',
    'Crispy golden fries',
    5.28,
    TRUE
),
(
    '001e8595-001e-4859-8001-001e8595001e',
    '000f428e-000f-4428-8000-000f428e000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.83,
    TRUE
),
(
    '001e8596-001e-4859-8001-001e8596001e',
    '000f428e-000f-4428-8000-000f428e000f',
    '0000001a-0000-4001-8000-0000001a0000',
    'Coleslaw',
    'Fresh cabbage salad',
    3.99,
    TRUE
),
(
    '001e8597-001e-4859-8001-001e8597001e',
    '000f428f-000f-4428-8000-000f428f000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.58,
    TRUE
),
(
    '001e8598-001e-4859-8001-001e8598001e',
    '000f428f-000f-4428-8000-000f428f000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.43,
    TRUE
),
(
    '001e8599-001e-4859-8001-001e8599001e',
    '000f428f-000f-4428-8000-000f428f000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.80,
    TRUE
),
(
    '001e859a-001e-4859-8001-001e859a001e',
    '000f4290-000f-4429-8000-000f4290000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.24,
    TRUE
),
(
    '001e859b-001e-4859-8001-001e859b001e',
    '000f4290-000f-4429-8000-000f4290000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.32,
    TRUE
),
(
    '001e859c-001e-4859-8001-001e859c001e',
    '000f4290-000f-4429-8000-000f4290000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.25,
    TRUE
),
(
    '001e859d-001e-4859-8001-001e859d001e',
    '000f4291-000f-4429-8000-000f4291000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.20,
    TRUE
),
(
    '001e859e-001e-4859-8001-001e859e001e',
    '000f4291-000f-4429-8000-000f4291000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.20,
    TRUE
),
(
    '001e859f-001e-4859-8001-001e859f001e',
    '000f4291-000f-4429-8000-000f4291000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.82,
    TRUE
),
(
    '001e85a0-001e-485a-8001-001e85a0001e',
    '000f4292-000f-4429-8000-000f4292000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.02,
    TRUE
),
(
    '001e85a1-001e-485a-8001-001e85a1001e',
    '000f4292-000f-4429-8000-000f4292000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.75,
    TRUE
),
(
    '001e85a2-001e-485a-8001-001e85a2001e',
    '000f4292-000f-4429-8000-000f4292000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Cheesecake',
    'New York style cheesecake',
    8.34,
    TRUE
),
(
    '001e85a3-001e-485a-8001-001e85a3001e',
    '000f4292-000f-4429-8000-000f4292000f',
    '0000001b-0000-4001-8000-0000001b0000',
    'Tiramisu',
    'Classic Italian dessert',
    8.34,
    TRUE
),
(
    '001e85a4-001e-485a-8001-001e85a4001e',
    '000f4293-000f-4429-8000-000f4293000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.01,
    TRUE
),
(
    '001e85a5-001e-485a-8001-001e85a5001e',
    '000f4293-000f-4429-8000-000f4293000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.89,
    TRUE
),
(
    '001e85a6-001e-485a-8001-001e85a6001e',
    '000f4293-000f-4429-8000-000f4293000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.30,
    TRUE
),
(
    '001e85a7-001e-485a-8001-001e85a7001e',
    '000f4294-000f-4429-8000-000f4294000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.94,
    TRUE
),
(
    '001e85a8-001e-485a-8001-001e85a8001e',
    '000f4294-000f-4429-8000-000f4294000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.85,
    TRUE
),
(
    '001e85a9-001e-485a-8001-001e85a9001e',
    '000f4294-000f-4429-8000-000f4294000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.38,
    TRUE
),
(
    '001e85aa-001e-485a-8001-001e85aa001e',
    '000f4295-000f-4429-8000-000f4295000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.21,
    TRUE
),
(
    '001e85ab-001e-485a-8001-001e85ab001e',
    '000f4295-000f-4429-8000-000f4295000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.63,
    TRUE
),
(
    '001e85ac-001e-485a-8001-001e85ac001e',
    '000f4295-000f-4429-8000-000f4295000f',
    '0000001c-0000-4001-8000-0000001c0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.74,
    TRUE
),
(
    '001e85ad-001e-485a-8001-001e85ad001e',
    '000f4296-000f-4429-8000-000f4296000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.42,
    TRUE
),
(
    '001e85ae-001e-485a-8001-001e85ae001e',
    '000f4296-000f-4429-8000-000f4296000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.27,
    TRUE
),
(
    '001e85af-001e-485a-8001-001e85af001e',
    '000f4296-000f-4429-8000-000f4296000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.98,
    TRUE
),
(
    '001e85b0-001e-485b-8001-001e85b0001e',
    '000f4297-000f-4429-8000-000f4297000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.74,
    TRUE
),
(
    '001e85b1-001e-485b-8001-001e85b1001e',
    '000f4297-000f-4429-8000-000f4297000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.16,
    TRUE
),
(
    '001e85b2-001e-485b-8001-001e85b2001e',
    '000f4297-000f-4429-8000-000f4297000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.47,
    TRUE
),
(
    '001e85b3-001e-485b-8001-001e85b3001e',
    '000f4298-000f-4429-8000-000f4298000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.48,
    TRUE
),
(
    '001e85b4-001e-485b-8001-001e85b4001e',
    '000f4298-000f-4429-8000-000f4298000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.71,
    TRUE
),
(
    '001e85b5-001e-485b-8001-001e85b5001e',
    '000f4298-000f-4429-8000-000f4298000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.61,
    TRUE
),
(
    '001e85b6-001e-485b-8001-001e85b6001e',
    '000f4298-000f-4429-8000-000f4298000f',
    '0000001d-0000-4001-8000-0000001d0000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    11.43,
    TRUE
),
(
    '001e85b7-001e-485b-8001-001e85b7001e',
    '000f4299-000f-4429-8000-000f4299000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.93,
    TRUE
),
(
    '001e85b8-001e-485b-8001-001e85b8001e',
    '000f4299-000f-4429-8000-000f4299000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.39,
    TRUE
),
(
    '001e85b9-001e-485b-8001-001e85b9001e',
    '000f4299-000f-4429-8000-000f4299000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.17,
    TRUE
),
(
    '001e85ba-001e-485b-8001-001e85ba001e',
    '000f4299-000f-4429-8000-000f4299000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.30,
    TRUE
),
(
    '001e85bb-001e-485b-8001-001e85bb001e',
    '000f429a-000f-4429-8000-000f429a000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.02,
    TRUE
),
(
    '001e85bc-001e-485b-8001-001e85bc001e',
    '000f429a-000f-4429-8000-000f429a000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.55,
    TRUE
),
(
    '001e85bd-001e-485b-8001-001e85bd001e',
    '000f429a-000f-4429-8000-000f429a000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.32,
    TRUE
),
(
    '001e85be-001e-485b-8001-001e85be001e',
    '000f429a-000f-4429-8000-000f429a000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.83,
    TRUE
),
(
    '001e85bf-001e-485b-8001-001e85bf001e',
    '000f429b-000f-4429-8000-000f429b000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.33,
    TRUE
),
(
    '001e85c0-001e-485c-8001-001e85c0001e',
    '000f429b-000f-4429-8000-000f429b000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.03,
    TRUE
),
(
    '001e85c1-001e-485c-8001-001e85c1001e',
    '000f429b-000f-4429-8000-000f429b000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Risotto',
    'Creamy Italian rice dish',
    13.36,
    TRUE
),
(
    '001e85c2-001e-485c-8001-001e85c2001e',
    '000f429c-000f-4429-8000-000f429c000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.78,
    TRUE
),
(
    '001e85c3-001e-485c-8001-001e85c3001e',
    '000f429c-000f-4429-8000-000f429c000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.33,
    TRUE
),
(
    '001e85c4-001e-485c-8001-001e85c4001e',
    '000f429c-000f-4429-8000-000f429c000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.68,
    TRUE
),
(
    '001e85c5-001e-485c-8001-001e85c5001e',
    '000f429c-000f-4429-8000-000f429c000f',
    '0000001e-0000-4001-8000-0000001e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.58,
    TRUE
),
(
    '001e85c6-001e-485c-8001-001e85c6001e',
    '000f429d-000f-4429-8000-000f429d000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.97,
    TRUE
),
(
    '001e85c7-001e-485c-8001-001e85c7001e',
    '000f429d-000f-4429-8000-000f429d000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.11,
    TRUE
),
(
    '001e85c8-001e-485c-8001-001e85c8001e',
    '000f429d-000f-4429-8000-000f429d000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.77,
    TRUE
),
(
    '001e85c9-001e-485c-8001-001e85c9001e',
    '000f429d-000f-4429-8000-000f429d000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.87,
    TRUE
),
(
    '001e85ca-001e-485c-8001-001e85ca001e',
    '000f429e-000f-4429-8000-000f429e000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.41,
    TRUE
),
(
    '001e85cb-001e-485c-8001-001e85cb001e',
    '000f429e-000f-4429-8000-000f429e000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.30,
    TRUE
),
(
    '001e85cc-001e-485c-8001-001e85cc001e',
    '000f429e-000f-4429-8000-000f429e000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.14,
    TRUE
),
(
    '001e85cd-001e-485c-8001-001e85cd001e',
    '000f429e-000f-4429-8000-000f429e000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.89,
    TRUE
),
(
    '001e85ce-001e-485c-8001-001e85ce001e',
    '000f429f-000f-4429-8000-000f429f000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.79,
    TRUE
),
(
    '001e85cf-001e-485c-8001-001e85cf001e',
    '000f429f-000f-4429-8000-000f429f000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.13,
    TRUE
),
(
    '001e85d0-001e-485d-8001-001e85d0001e',
    '000f429f-000f-4429-8000-000f429f000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.81,
    TRUE
),
(
    '001e85d1-001e-485d-8001-001e85d1001e',
    '000f42a0-000f-442a-8000-000f42a0000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.89,
    TRUE
),
(
    '001e85d2-001e-485d-8001-001e85d2001e',
    '000f42a0-000f-442a-8000-000f42a0000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.52,
    TRUE
),
(
    '001e85d3-001e-485d-8001-001e85d3001e',
    '000f42a0-000f-442a-8000-000f42a0000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Cheesecake',
    'New York style cheesecake',
    8.57,
    TRUE
),
(
    '001e85d4-001e-485d-8001-001e85d4001e',
    '000f42a0-000f-442a-8000-000f42a0000f',
    '0000001f-0000-4001-8000-0000001f0000',
    'Tiramisu',
    'Classic Italian dessert',
    6.91,
    TRUE
),
(
    '001e85d5-001e-485d-8001-001e85d5001e',
    '000f42a1-000f-442a-8000-000f42a1000f',
    '00000020-0000-4002-8000-000000200000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.97,
    TRUE
),
(
    '001e85d6-001e-485d-8001-001e85d6001e',
    '000f42a1-000f-442a-8000-000f42a1000f',
    '00000020-0000-4002-8000-000000200000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.89,
    TRUE
),
(
    '001e85d7-001e-485d-8001-001e85d7001e',
    '000f42a1-000f-442a-8000-000f42a1000f',
    '00000020-0000-4002-8000-000000200000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.66,
    TRUE
),
(
    '001e85d8-001e-485d-8001-001e85d8001e',
    '000f42a1-000f-442a-8000-000f42a1000f',
    '00000020-0000-4002-8000-000000200000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.65,
    TRUE
),
(
    '001e85d9-001e-485d-8001-001e85d9001e',
    '000f42a2-000f-442a-8000-000f42a2000f',
    '00000020-0000-4002-8000-000000200000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.34,
    TRUE
),
(
    '001e85da-001e-485d-8001-001e85da001e',
    '000f42a2-000f-442a-8000-000f42a2000f',
    '00000020-0000-4002-8000-000000200000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.74,
    TRUE
),
(
    '001e85db-001e-485d-8001-001e85db001e',
    '000f42a2-000f-442a-8000-000f42a2000f',
    '00000020-0000-4002-8000-000000200000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.24,
    TRUE
),
(
    '001e85dc-001e-485d-8001-001e85dc001e',
    '000f42a2-000f-442a-8000-000f42a2000f',
    '00000020-0000-4002-8000-000000200000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.57,
    TRUE
),
(
    '001e85dd-001e-485d-8001-001e85dd001e',
    '000f42a3-000f-442a-8000-000f42a3000f',
    '00000021-0000-4002-8000-000000210000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.95,
    TRUE
),
(
    '001e85de-001e-485d-8001-001e85de001e',
    '000f42a3-000f-442a-8000-000f42a3000f',
    '00000021-0000-4002-8000-000000210000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.42,
    TRUE
),
(
    '001e85df-001e-485d-8001-001e85df001e',
    '000f42a3-000f-442a-8000-000f42a3000f',
    '00000021-0000-4002-8000-000000210000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.80,
    TRUE
),
(
    '001e85e0-001e-485e-8001-001e85e0001e',
    '000f42a3-000f-442a-8000-000f42a3000f',
    '00000021-0000-4002-8000-000000210000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.87,
    TRUE
),
(
    '001e85e1-001e-485e-8001-001e85e1001e',
    '000f42a4-000f-442a-8000-000f42a4000f',
    '00000021-0000-4002-8000-000000210000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.80,
    TRUE
),
(
    '001e85e2-001e-485e-8001-001e85e2001e',
    '000f42a4-000f-442a-8000-000f42a4000f',
    '00000021-0000-4002-8000-000000210000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.20,
    TRUE
),
(
    '001e85e3-001e-485e-8001-001e85e3001e',
    '000f42a4-000f-442a-8000-000f42a4000f',
    '00000021-0000-4002-8000-000000210000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.47,
    TRUE
),
(
    '001e85e4-001e-485e-8001-001e85e4001e',
    '000f42a5-000f-442a-8000-000f42a5000f',
    '00000021-0000-4002-8000-000000210000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.49,
    TRUE
),
(
    '001e85e5-001e-485e-8001-001e85e5001e',
    '000f42a5-000f-442a-8000-000f42a5000f',
    '00000021-0000-4002-8000-000000210000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.66,
    TRUE
),
(
    '001e85e6-001e-485e-8001-001e85e6001e',
    '000f42a5-000f-442a-8000-000f42a5000f',
    '00000021-0000-4002-8000-000000210000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.32,
    TRUE
),
(
    '001e85e7-001e-485e-8001-001e85e7001e',
    '000f42a5-000f-442a-8000-000f42a5000f',
    '00000021-0000-4002-8000-000000210000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.34,
    TRUE
),
(
    '001e85e8-001e-485e-8001-001e85e8001e',
    '000f42a6-000f-442a-8000-000f42a6000f',
    '00000021-0000-4002-8000-000000210000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.52,
    TRUE
),
(
    '001e85e9-001e-485e-8001-001e85e9001e',
    '000f42a6-000f-442a-8000-000f42a6000f',
    '00000021-0000-4002-8000-000000210000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.02,
    TRUE
),
(
    '001e85ea-001e-485e-8001-001e85ea001e',
    '000f42a6-000f-442a-8000-000f42a6000f',
    '00000021-0000-4002-8000-000000210000',
    'Cheesecake',
    'New York style cheesecake',
    7.73,
    TRUE
),
(
    '001e85eb-001e-485e-8001-001e85eb001e',
    '000f42a7-000f-442a-8000-000f42a7000f',
    '00000022-0000-4002-8000-000000220000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.63,
    TRUE
),
(
    '001e85ec-001e-485e-8001-001e85ec001e',
    '000f42a7-000f-442a-8000-000f42a7000f',
    '00000022-0000-4002-8000-000000220000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.47,
    TRUE
),
(
    '001e85ed-001e-485e-8001-001e85ed001e',
    '000f42a7-000f-442a-8000-000f42a7000f',
    '00000022-0000-4002-8000-000000220000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.88,
    TRUE
),
(
    '001e85ee-001e-485e-8001-001e85ee001e',
    '000f42a8-000f-442a-8000-000f42a8000f',
    '00000022-0000-4002-8000-000000220000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.29,
    TRUE
),
(
    '001e85ef-001e-485e-8001-001e85ef001e',
    '000f42a8-000f-442a-8000-000f42a8000f',
    '00000022-0000-4002-8000-000000220000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.46,
    TRUE
),
(
    '001e85f0-001e-485f-8001-001e85f0001e',
    '000f42a8-000f-442a-8000-000f42a8000f',
    '00000022-0000-4002-8000-000000220000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.02,
    TRUE
),
(
    '001e85f1-001e-485f-8001-001e85f1001e',
    '000f42a9-000f-442a-8000-000f42a9000f',
    '00000022-0000-4002-8000-000000220000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.24,
    TRUE
),
(
    '001e85f2-001e-485f-8001-001e85f2001e',
    '000f42a9-000f-442a-8000-000f42a9000f',
    '00000022-0000-4002-8000-000000220000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.02,
    TRUE
),
(
    '001e85f3-001e-485f-8001-001e85f3001e',
    '000f42a9-000f-442a-8000-000f42a9000f',
    '00000022-0000-4002-8000-000000220000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.84,
    TRUE
),
(
    '001e85f4-001e-485f-8001-001e85f4001e',
    '000f42aa-000f-442a-8000-000f42aa000f',
    '00000022-0000-4002-8000-000000220000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.16,
    TRUE
),
(
    '001e85f5-001e-485f-8001-001e85f5001e',
    '000f42aa-000f-442a-8000-000f42aa000f',
    '00000022-0000-4002-8000-000000220000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.02,
    TRUE
),
(
    '001e85f6-001e-485f-8001-001e85f6001e',
    '000f42aa-000f-442a-8000-000f42aa000f',
    '00000022-0000-4002-8000-000000220000',
    'Cheesecake',
    'New York style cheesecake',
    7.47,
    TRUE
),
(
    '001e85f7-001e-485f-8001-001e85f7001e',
    '000f42aa-000f-442a-8000-000f42aa000f',
    '00000022-0000-4002-8000-000000220000',
    'Tiramisu',
    'Classic Italian dessert',
    6.87,
    TRUE
),
(
    '001e85f8-001e-485f-8001-001e85f8001e',
    '000f42ab-000f-442a-8000-000f42ab000f',
    '00000023-0000-4002-8000-000000230000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.38,
    TRUE
),
(
    '001e85f9-001e-485f-8001-001e85f9001e',
    '000f42ab-000f-442a-8000-000f42ab000f',
    '00000023-0000-4002-8000-000000230000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.32,
    TRUE
),
(
    '001e85fa-001e-485f-8001-001e85fa001e',
    '000f42ab-000f-442a-8000-000f42ab000f',
    '00000023-0000-4002-8000-000000230000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.89,
    TRUE
),
(
    '001e85fb-001e-485f-8001-001e85fb001e',
    '000f42ac-000f-442a-8000-000f42ac000f',
    '00000023-0000-4002-8000-000000230000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.22,
    TRUE
),
(
    '001e85fc-001e-485f-8001-001e85fc001e',
    '000f42ac-000f-442a-8000-000f42ac000f',
    '00000023-0000-4002-8000-000000230000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.00,
    TRUE
),
(
    '001e85fd-001e-485f-8001-001e85fd001e',
    '000f42ac-000f-442a-8000-000f42ac000f',
    '00000023-0000-4002-8000-000000230000',
    'Risotto',
    'Creamy Italian rice dish',
    12.33,
    TRUE
),
(
    '001e85fe-001e-485f-8001-001e85fe001e',
    '000f42ad-000f-442a-8000-000f42ad000f',
    '00000024-0000-4002-8000-000000240000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.27,
    TRUE
),
(
    '001e85ff-001e-485f-8001-001e85ff001e',
    '000f42ad-000f-442a-8000-000f42ad000f',
    '00000024-0000-4002-8000-000000240000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.31,
    TRUE
),
(
    '001e8600-001e-4860-8001-001e8600001e',
    '000f42ad-000f-442a-8000-000f42ad000f',
    '00000024-0000-4002-8000-000000240000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.84,
    TRUE
),
(
    '001e8601-001e-4860-8001-001e8601001e',
    '000f42ad-000f-442a-8000-000f42ad000f',
    '00000024-0000-4002-8000-000000240000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.54,
    TRUE
),
(
    '001e8602-001e-4860-8001-001e8602001e',
    '000f42ae-000f-442a-8000-000f42ae000f',
    '00000024-0000-4002-8000-000000240000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.83,
    TRUE
),
(
    '001e8603-001e-4860-8001-001e8603001e',
    '000f42ae-000f-442a-8000-000f42ae000f',
    '00000024-0000-4002-8000-000000240000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.64,
    TRUE
),
(
    '001e8604-001e-4860-8001-001e8604001e',
    '000f42ae-000f-442a-8000-000f42ae000f',
    '00000024-0000-4002-8000-000000240000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.93,
    TRUE
),
(
    '001e8605-001e-4860-8001-001e8605001e',
    '000f42af-000f-442a-8000-000f42af000f',
    '00000025-0000-4002-8000-000000250000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.35,
    TRUE
),
(
    '001e8606-001e-4860-8001-001e8606001e',
    '000f42af-000f-442a-8000-000f42af000f',
    '00000025-0000-4002-8000-000000250000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.27,
    TRUE
),
(
    '001e8607-001e-4860-8001-001e8607001e',
    '000f42af-000f-442a-8000-000f42af000f',
    '00000025-0000-4002-8000-000000250000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.47,
    TRUE
),
(
    '001e8608-001e-4860-8001-001e8608001e',
    '000f42af-000f-442a-8000-000f42af000f',
    '00000025-0000-4002-8000-000000250000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.16,
    TRUE
),
(
    '001e8609-001e-4860-8001-001e8609001e',
    '000f42b0-000f-442b-8000-000f42b0000f',
    '00000025-0000-4002-8000-000000250000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.51,
    TRUE
),
(
    '001e860a-001e-4860-8001-001e860a001e',
    '000f42b0-000f-442b-8000-000f42b0000f',
    '00000025-0000-4002-8000-000000250000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.35,
    TRUE
),
(
    '001e860b-001e-4860-8001-001e860b001e',
    '000f42b0-000f-442b-8000-000f42b0000f',
    '00000025-0000-4002-8000-000000250000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.15,
    TRUE
),
(
    '001e860c-001e-4860-8001-001e860c001e',
    '000f42b0-000f-442b-8000-000f42b0000f',
    '00000025-0000-4002-8000-000000250000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.36,
    TRUE
),
(
    '001e860d-001e-4860-8001-001e860d001e',
    '000f42b1-000f-442b-8000-000f42b1000f',
    '00000025-0000-4002-8000-000000250000',
    'French Fries',
    'Crispy golden fries',
    5.85,
    TRUE
),
(
    '001e860e-001e-4860-8001-001e860e001e',
    '000f42b1-000f-442b-8000-000f42b1000f',
    '00000025-0000-4002-8000-000000250000',
    'Onion Rings',
    'Battered and fried onion rings',
    5.78,
    TRUE
),
(
    '001e860f-001e-4860-8001-001e860f001e',
    '000f42b1-000f-442b-8000-000f42b1000f',
    '00000025-0000-4002-8000-000000250000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.50,
    TRUE
),
(
    '001e8610-001e-4861-8001-001e8610001e',
    '000f42b2-000f-442b-8000-000f42b2000f',
    '00000026-0000-4002-8000-000000260000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.47,
    TRUE
),
(
    '001e8611-001e-4861-8001-001e8611001e',
    '000f42b2-000f-442b-8000-000f42b2000f',
    '00000026-0000-4002-8000-000000260000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.41,
    TRUE
),
(
    '001e8612-001e-4861-8001-001e8612001e',
    '000f42b2-000f-442b-8000-000f42b2000f',
    '00000026-0000-4002-8000-000000260000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.08,
    TRUE
),
(
    '001e8613-001e-4861-8001-001e8613001e',
    '000f42b2-000f-442b-8000-000f42b2000f',
    '00000026-0000-4002-8000-000000260000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.01,
    TRUE
),
(
    '001e8614-001e-4861-8001-001e8614001e',
    '000f42b3-000f-442b-8000-000f42b3000f',
    '00000026-0000-4002-8000-000000260000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.32,
    TRUE
),
(
    '001e8615-001e-4861-8001-001e8615001e',
    '000f42b3-000f-442b-8000-000f42b3000f',
    '00000026-0000-4002-8000-000000260000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.20,
    TRUE
),
(
    '001e8616-001e-4861-8001-001e8616001e',
    '000f42b3-000f-442b-8000-000f42b3000f',
    '00000026-0000-4002-8000-000000260000',
    'Risotto',
    'Creamy Italian rice dish',
    12.58,
    TRUE
),
(
    '001e8617-001e-4861-8001-001e8617001e',
    '000f42b4-000f-442b-8000-000f42b4000f',
    '00000026-0000-4002-8000-000000260000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.23,
    TRUE
),
(
    '001e8618-001e-4861-8001-001e8618001e',
    '000f42b4-000f-442b-8000-000f42b4000f',
    '00000026-0000-4002-8000-000000260000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.06,
    TRUE
),
(
    '001e8619-001e-4861-8001-001e8619001e',
    '000f42b4-000f-442b-8000-000f42b4000f',
    '00000026-0000-4002-8000-000000260000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.11,
    TRUE
),
(
    '001e861a-001e-4861-8001-001e861a001e',
    '000f42b5-000f-442b-8000-000f42b5000f',
    '00000027-0000-4002-8000-000000270000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.98,
    TRUE
),
(
    '001e861b-001e-4861-8001-001e861b001e',
    '000f42b5-000f-442b-8000-000f42b5000f',
    '00000027-0000-4002-8000-000000270000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.24,
    TRUE
),
(
    '001e861c-001e-4861-8001-001e861c001e',
    '000f42b5-000f-442b-8000-000f42b5000f',
    '00000027-0000-4002-8000-000000270000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.03,
    TRUE
),
(
    '001e861d-001e-4861-8001-001e861d001e',
    '000f42b6-000f-442b-8000-000f42b6000f',
    '00000027-0000-4002-8000-000000270000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.39,
    TRUE
),
(
    '001e861e-001e-4861-8001-001e861e001e',
    '000f42b6-000f-442b-8000-000f42b6000f',
    '00000027-0000-4002-8000-000000270000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.40,
    TRUE
),
(
    '001e861f-001e-4861-8001-001e861f001e',
    '000f42b6-000f-442b-8000-000f42b6000f',
    '00000027-0000-4002-8000-000000270000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.71,
    TRUE
),
(
    '001e8620-001e-4862-8001-001e8620001e',
    '000f42b6-000f-442b-8000-000f42b6000f',
    '00000027-0000-4002-8000-000000270000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.32,
    TRUE
),
(
    '001e8621-001e-4862-8001-001e8621001e',
    '000f42b7-000f-442b-8000-000f42b7000f',
    '00000027-0000-4002-8000-000000270000',
    'French Fries',
    'Crispy golden fries',
    5.72,
    TRUE
),
(
    '001e8622-001e-4862-8001-001e8622001e',
    '000f42b7-000f-442b-8000-000f42b7000f',
    '00000027-0000-4002-8000-000000270000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.36,
    TRUE
),
(
    '001e8623-001e-4862-8001-001e8623001e',
    '000f42b7-000f-442b-8000-000f42b7000f',
    '00000027-0000-4002-8000-000000270000',
    'Coleslaw',
    'Fresh cabbage salad',
    3.75,
    TRUE
),
(
    '001e8624-001e-4862-8001-001e8624001e',
    '000f42b8-000f-442b-8000-000f42b8000f',
    '00000027-0000-4002-8000-000000270000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.22,
    TRUE
),
(
    '001e8625-001e-4862-8001-001e8625001e',
    '000f42b8-000f-442b-8000-000f42b8000f',
    '00000027-0000-4002-8000-000000270000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.67,
    TRUE
),
(
    '001e8626-001e-4862-8001-001e8626001e',
    '000f42b8-000f-442b-8000-000f42b8000f',
    '00000027-0000-4002-8000-000000270000',
    'Cheesecake',
    'New York style cheesecake',
    8.59,
    TRUE
),
(
    '001e8627-001e-4862-8001-001e8627001e',
    '000f42b8-000f-442b-8000-000f42b8000f',
    '00000027-0000-4002-8000-000000270000',
    'Tiramisu',
    'Classic Italian dessert',
    7.93,
    TRUE
),
(
    '001e8628-001e-4862-8001-001e8628001e',
    '000f42b9-000f-442b-8000-000f42b9000f',
    '00000028-0000-4002-8000-000000280000',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    12.31,
    TRUE
),
(
    '001e8629-001e-4862-8001-001e8629001e',
    '000f42b9-000f-442b-8000-000f42b9000f',
    '00000028-0000-4002-8000-000000280000',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    14.21,
    TRUE
),
(
    '001e862a-001e-4862-8001-001e862a001e',
    '000f42b9-000f-442b-8000-000f42b9000f',
    '00000028-0000-4002-8000-000000280000',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives',
    15.65,
    TRUE
),
(
    '001e862b-001e-4862-8001-001e862b001e',
    '000f42ba-000f-442b-8000-000f42ba000f',
    '00000028-0000-4002-8000-000000280000',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino',
    13.84,
    TRUE
),
(
    '001e862c-001e-4862-8001-001e862c001e',
    '000f42ba-000f-442b-8000-000f42ba000f',
    '00000028-0000-4002-8000-000000280000',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    12.28,
    TRUE
),
(
    '001e862d-001e-4862-8001-001e862d001e',
    '000f42ba-000f-442b-8000-000f42ba000f',
    '00000028-0000-4002-8000-000000280000',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream',
    12.98,
    TRUE
),
(
    '001e862e-001e-4862-8001-001e862e001e',
    '000f42ba-000f-442b-8000-000f42ba000f',
    '00000028-0000-4002-8000-000000280000',
    'Lasagna',
    'Layered pasta with meat sauce and cheese',
    15.86,
    TRUE
),
(
    '001e862f-001e-4862-8001-001e862f001e',
    '000f42ba-000f-442b-8000-000f42ba000f',
    '00000028-0000-4002-8000-000000280000',
    'Ravioli',
    'Stuffed pasta with ricotta and spinach',
    13.67,
    TRUE
),
(
    '001e8630-001e-4863-8001-001e8630001e',
    '000f42bb-000f-442b-8000-000f42bb000f',
    '00000028-0000-4002-8000-000000280000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.04,
    TRUE
),
(
    '001e8631-001e-4863-8001-001e8631001e',
    '000f42bb-000f-442b-8000-000f42bb000f',
    '00000028-0000-4002-8000-000000280000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.47,
    TRUE
),
(
    '001e8632-001e-4863-8001-001e8632001e',
    '000f42bb-000f-442b-8000-000f42bb000f',
    '00000028-0000-4002-8000-000000280000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.55,
    TRUE
),
(
    '001e8633-001e-4863-8001-001e8633001e',
    '000f42bc-000f-442b-8000-000f42bc000f',
    '00000028-0000-4002-8000-000000280000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.55,
    TRUE
),
(
    '001e8634-001e-4863-8001-001e8634001e',
    '000f42bc-000f-442b-8000-000f42bc000f',
    '00000028-0000-4002-8000-000000280000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.07,
    TRUE
),
(
    '001e8635-001e-4863-8001-001e8635001e',
    '000f42bc-000f-442b-8000-000f42bc000f',
    '00000028-0000-4002-8000-000000280000',
    'Cheesecake',
    'New York style cheesecake',
    7.70,
    TRUE
),
(
    '001e8636-001e-4863-8001-001e8636001e',
    '000f42bd-000f-442b-8000-000f42bd000f',
    '00000029-0000-4002-8000-000000290000',
    'Har Gow',
    'Steamed shrimp dumplings',
    8.01,
    TRUE
),
(
    '001e8637-001e-4863-8001-001e8637001e',
    '000f42bd-000f-442b-8000-000f42bd000f',
    '00000029-0000-4002-8000-000000290000',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    9.47,
    TRUE
),
(
    '001e8638-001e-4863-8001-001e8638001e',
    '000f42bd-000f-442b-8000-000f42bd000f',
    '00000029-0000-4002-8000-000000290000',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    7.38,
    TRUE
),
(
    '001e8639-001e-4863-8001-001e8639001e',
    '000f42be-000f-442b-8000-000f42be000f',
    '00000029-0000-4002-8000-000000290000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.83,
    TRUE
),
(
    '001e863a-001e-4863-8001-001e863a001e',
    '000f42be-000f-442b-8000-000f42be000f',
    '00000029-0000-4002-8000-000000290000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.52,
    TRUE
),
(
    '001e863b-001e-4863-8001-001e863b001e',
    '000f42be-000f-442b-8000-000f42be000f',
    '00000029-0000-4002-8000-000000290000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    10.60,
    TRUE
),
(
    '001e863c-001e-4863-8001-001e863c001e',
    '000f42be-000f-442b-8000-000f42be000f',
    '00000029-0000-4002-8000-000000290000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    12.14,
    TRUE
),
(
    '001e863d-001e-4863-8001-001e863d001e',
    '000f42be-000f-442b-8000-000f42be000f',
    '00000029-0000-4002-8000-000000290000',
    'Pad Thai',
    'Thai-style stir-fried noodles',
    12.96,
    TRUE
),
(
    '001e863e-001e-4863-8001-001e863e001e',
    '000f42bf-000f-442b-8000-000f42bf000f',
    '0000002a-0000-4002-8000-0000002a0000',
    'Beef Tacos',
    'Seasoned ground beef with lettuce and cheese',
    9.10,
    TRUE
),
(
    '001e863f-001e-4863-8001-001e863f001e',
    '000f42bf-000f-442b-8000-000f42bf000f',
    '0000002a-0000-4002-8000-0000002a0000',
    'Chicken Tacos',
    'Grilled chicken with salsa and avocado',
    9.46,
    TRUE
),
(
    '001e8640-001e-4864-8001-001e8640001e',
    '000f42bf-000f-442b-8000-000f42bf000f',
    '0000002a-0000-4002-8000-0000002a0000',
    'Fish Tacos',
    'Battered fish with cabbage slaw',
    10.79,
    TRUE
),
(
    '001e8641-001e-4864-8001-001e8641001e',
    '000f42bf-000f-442b-8000-000f42bf000f',
    '0000002a-0000-4002-8000-0000002a0000',
    'Vegetarian Tacos',
    'Black beans, corn, and vegetables',
    9.36,
    TRUE
),
(
    '001e8642-001e-4864-8001-001e8642001e',
    '000f42c0-000f-442c-8000-000f42c0000f',
    '0000002a-0000-4002-8000-0000002a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.23,
    TRUE
),
(
    '001e8643-001e-4864-8001-001e8643001e',
    '000f42c0-000f-442c-8000-000f42c0000f',
    '0000002a-0000-4002-8000-0000002a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.02,
    TRUE
),
(
    '001e8644-001e-4864-8001-001e8644001e',
    '000f42c0-000f-442c-8000-000f42c0000f',
    '0000002a-0000-4002-8000-0000002a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.08,
    TRUE
),
(
    '001e8645-001e-4864-8001-001e8645001e',
    '000f42c0-000f-442c-8000-000f42c0000f',
    '0000002a-0000-4002-8000-0000002a0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.01,
    TRUE
),
(
    '001e8646-001e-4864-8001-001e8646001e',
    '000f42c1-000f-442c-8000-000f42c1000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    14.55,
    TRUE
),
(
    '001e8647-001e-4864-8001-001e8647001e',
    '000f42c1-000f-442c-8000-000f42c1000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    16.03,
    TRUE
),
(
    '001e8648-001e-4864-8001-001e8648001e',
    '000f42c1-000f-442c-8000-000f42c1000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    12.34,
    TRUE
),
(
    '001e8649-001e-4864-8001-001e8649001e',
    '000f42c1-000f-442c-8000-000f42c1000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    14.85,
    TRUE
),
(
    '001e864a-001e-4864-8001-001e864a001e',
    '000f42c2-000f-442c-8000-000f42c2000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.98,
    TRUE
),
(
    '001e864b-001e-4864-8001-001e864b001e',
    '000f42c2-000f-442c-8000-000f42c2000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.36,
    TRUE
),
(
    '001e864c-001e-4864-8001-001e864c001e',
    '000f42c2-000f-442c-8000-000f42c2000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.28,
    TRUE
),
(
    '001e864d-001e-4864-8001-001e864d001e',
    '000f42c2-000f-442c-8000-000f42c2000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.48,
    TRUE
),
(
    '001e864e-001e-4864-8001-001e864e001e',
    '000f42c3-000f-442c-8000-000f42c3000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.58,
    TRUE
),
(
    '001e864f-001e-4864-8001-001e864f001e',
    '000f42c3-000f-442c-8000-000f42c3000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.19,
    TRUE
),
(
    '001e8650-001e-4865-8001-001e8650001e',
    '000f42c3-000f-442c-8000-000f42c3000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.11,
    TRUE
),
(
    '001e8651-001e-4865-8001-001e8651001e',
    '000f42c3-000f-442c-8000-000f42c3000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.12,
    TRUE
),
(
    '001e8652-001e-4865-8001-001e8652001e',
    '000f42c4-000f-442c-8000-000f42c4000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.76,
    TRUE
),
(
    '001e8653-001e-4865-8001-001e8653001e',
    '000f42c4-000f-442c-8000-000f42c4000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.03,
    TRUE
),
(
    '001e8654-001e-4865-8001-001e8654001e',
    '000f42c4-000f-442c-8000-000f42c4000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.46,
    TRUE
),
(
    '001e8655-001e-4865-8001-001e8655001e',
    '000f42c4-000f-442c-8000-000f42c4000f',
    '0000002b-0000-4002-8000-0000002b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    5.99,
    TRUE
),
(
    '001e8656-001e-4865-8001-001e8656001e',
    '000f42c5-000f-442c-8000-000f42c5000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Salmon Roll',
    'Fresh salmon with rice and nori',
    8.00,
    TRUE
),
(
    '001e8657-001e-4865-8001-001e8657001e',
    '000f42c5-000f-442c-8000-000f42c5000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Tuna Roll',
    'Premium tuna with rice and nori',
    9.79,
    TRUE
),
(
    '001e8658-001e-4865-8001-001e8658001e',
    '000f42c5-000f-442c-8000-000f42c5000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'California Roll',
    'Crab, avocado, and cucumber',
    7.47,
    TRUE
),
(
    '001e8659-001e-4865-8001-001e8659001e',
    '000f42c5-000f-442c-8000-000f42c5000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Dragon Roll',
    'Eel, cucumber, and avocado',
    12.69,
    TRUE
),
(
    '001e865a-001e-4865-8001-001e865a001e',
    '000f42c6-000f-442c-8000-000f42c6000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.71,
    TRUE
),
(
    '001e865b-001e-4865-8001-001e865b001e',
    '000f42c6-000f-442c-8000-000f42c6000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.45,
    TRUE
),
(
    '001e865c-001e-4865-8001-001e865c001e',
    '000f42c6-000f-442c-8000-000f42c6000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.51,
    TRUE
),
(
    '001e865d-001e-4865-8001-001e865d001e',
    '000f42c7-000f-442c-8000-000f42c7000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.04,
    TRUE
),
(
    '001e865e-001e-4865-8001-001e865e001e',
    '000f42c7-000f-442c-8000-000f42c7000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.88,
    TRUE
),
(
    '001e865f-001e-4865-8001-001e865f001e',
    '000f42c7-000f-442c-8000-000f42c7000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.56,
    TRUE
),
(
    '001e8660-001e-4866-8001-001e8660001e',
    '000f42c7-000f-442c-8000-000f42c7000f',
    '0000002c-0000-4002-8000-0000002c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.17,
    TRUE
),
(
    '001e8661-001e-4866-8001-001e8661001e',
    '000f42c8-000f-442c-8000-000f42c8000f',
    '0000002d-0000-4002-8000-0000002d0000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    14.62,
    TRUE
),
(
    '001e8662-001e-4866-8001-001e8662001e',
    '000f42c8-000f-442c-8000-000f42c8000f',
    '0000002d-0000-4002-8000-0000002d0000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.25,
    TRUE
),
(
    '001e8663-001e-4866-8001-001e8663001e',
    '000f42c8-000f-442c-8000-000f42c8000f',
    '0000002d-0000-4002-8000-0000002d0000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.49,
    TRUE
),
(
    '001e8664-001e-4866-8001-001e8664001e',
    '000f42c9-000f-442c-8000-000f42c9000f',
    '0000002d-0000-4002-8000-0000002d0000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.57,
    TRUE
),
(
    '001e8665-001e-4866-8001-001e8665001e',
    '000f42c9-000f-442c-8000-000f42c9000f',
    '0000002d-0000-4002-8000-0000002d0000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.99,
    TRUE
),
(
    '001e8666-001e-4866-8001-001e8666001e',
    '000f42c9-000f-442c-8000-000f42c9000f',
    '0000002d-0000-4002-8000-0000002d0000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.37,
    TRUE
),
(
    '001e8667-001e-4866-8001-001e8667001e',
    '000f42ca-000f-442c-8000-000f42ca000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Classic Burger',
    'Beef patty with lettuce, tomato, onion',
    10.38,
    TRUE
),
(
    '001e8668-001e-4866-8001-001e8668001e',
    '000f42ca-000f-442c-8000-000f42ca000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Cheeseburger',
    'Beef patty with cheese and special sauce',
    11.05,
    TRUE
),
(
    '001e8669-001e-4866-8001-001e8669001e',
    '000f42ca-000f-442c-8000-000f42ca000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Chicken Burger',
    'Grilled chicken breast with fixings',
    10.99,
    TRUE
),
(
    '001e866a-001e-4866-8001-001e866a001e',
    '000f42ca-000f-442c-8000-000f42ca000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Veggie Burger',
    'Plant-based patty with vegetables',
    10.81,
    TRUE
),
(
    '001e866b-001e-4866-8001-001e866b001e',
    '000f42cb-000f-442c-8000-000f42cb000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.25,
    TRUE
),
(
    '001e866c-001e-4866-8001-001e866c001e',
    '000f42cb-000f-442c-8000-000f42cb000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.62,
    TRUE
),
(
    '001e866d-001e-4866-8001-001e866d001e',
    '000f42cb-000f-442c-8000-000f42cb000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.10,
    TRUE
),
(
    '001e866e-001e-4866-8001-001e866e001e',
    '000f42cc-000f-442c-8000-000f42cc000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.65,
    TRUE
),
(
    '001e866f-001e-4866-8001-001e866f001e',
    '000f42cc-000f-442c-8000-000f42cc000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.33,
    TRUE
),
(
    '001e8670-001e-4867-8001-001e8670001e',
    '000f42cc-000f-442c-8000-000f42cc000f',
    '0000002e-0000-4002-8000-0000002e0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.43,
    TRUE
),
(
    '001e8671-001e-4867-8001-001e8671001e',
    '000f42cd-000f-442c-8000-000f42cd000f',
    '0000002f-0000-4002-8000-0000002f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.65,
    TRUE
),
(
    '001e8672-001e-4867-8001-001e8672001e',
    '000f42cd-000f-442c-8000-000f42cd000f',
    '0000002f-0000-4002-8000-0000002f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.14,
    TRUE
),
(
    '001e8673-001e-4867-8001-001e8673001e',
    '000f42cd-000f-442c-8000-000f42cd000f',
    '0000002f-0000-4002-8000-0000002f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.56,
    TRUE
),
(
    '001e8674-001e-4867-8001-001e8674001e',
    '000f42cd-000f-442c-8000-000f42cd000f',
    '0000002f-0000-4002-8000-0000002f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.67,
    TRUE
),
(
    '001e8675-001e-4867-8001-001e8675001e',
    '000f42ce-000f-442c-8000-000f42ce000f',
    '0000002f-0000-4002-8000-0000002f0000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    8.56,
    TRUE
),
(
    '001e8676-001e-4867-8001-001e8676001e',
    '000f42ce-000f-442c-8000-000f42ce000f',
    '0000002f-0000-4002-8000-0000002f0000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.50,
    TRUE
),
(
    '001e8677-001e-4867-8001-001e8677001e',
    '000f42ce-000f-442c-8000-000f42ce000f',
    '0000002f-0000-4002-8000-0000002f0000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.56,
    TRUE
),
(
    '001e8678-001e-4867-8001-001e8678001e',
    '000f42cf-000f-442c-8000-000f42cf000f',
    '00000030-0000-4003-8000-000000300000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.62,
    TRUE
),
(
    '001e8679-001e-4867-8001-001e8679001e',
    '000f42cf-000f-442c-8000-000f42cf000f',
    '00000030-0000-4003-8000-000000300000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.91,
    TRUE
),
(
    '001e867a-001e-4867-8001-001e867a001e',
    '000f42cf-000f-442c-8000-000f42cf000f',
    '00000030-0000-4003-8000-000000300000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.74,
    TRUE
),
(
    '001e867b-001e-4867-8001-001e867b001e',
    '000f42cf-000f-442c-8000-000f42cf000f',
    '00000030-0000-4003-8000-000000300000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.19,
    TRUE
),
(
    '001e867c-001e-4867-8001-001e867c001e',
    '000f42d0-000f-442d-8000-000f42d0000f',
    '00000030-0000-4003-8000-000000300000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.50,
    TRUE
),
(
    '001e867d-001e-4867-8001-001e867d001e',
    '000f42d0-000f-442d-8000-000f42d0000f',
    '00000030-0000-4003-8000-000000300000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.27,
    TRUE
),
(
    '001e867e-001e-4867-8001-001e867e001e',
    '000f42d0-000f-442d-8000-000f42d0000f',
    '00000030-0000-4003-8000-000000300000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.50,
    TRUE
),
(
    '001e867f-001e-4867-8001-001e867f001e',
    '000f42d0-000f-442d-8000-000f42d0000f',
    '00000030-0000-4003-8000-000000300000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.56,
    TRUE
),
(
    '001e8680-001e-4868-8001-001e8680001e',
    '000f42d1-000f-442d-8000-000f42d1000f',
    '00000030-0000-4003-8000-000000300000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.91,
    TRUE
),
(
    '001e8681-001e-4868-8001-001e8681001e',
    '000f42d1-000f-442d-8000-000f42d1000f',
    '00000030-0000-4003-8000-000000300000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.92,
    TRUE
),
(
    '001e8682-001e-4868-8001-001e8682001e',
    '000f42d1-000f-442d-8000-000f42d1000f',
    '00000030-0000-4003-8000-000000300000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.43,
    TRUE
),
(
    '001e8683-001e-4868-8001-001e8683001e',
    '000f42d2-000f-442d-8000-000f42d2000f',
    '00000030-0000-4003-8000-000000300000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.22,
    TRUE
),
(
    '001e8684-001e-4868-8001-001e8684001e',
    '000f42d2-000f-442d-8000-000f42d2000f',
    '00000030-0000-4003-8000-000000300000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.39,
    TRUE
),
(
    '001e8685-001e-4868-8001-001e8685001e',
    '000f42d2-000f-442d-8000-000f42d2000f',
    '00000030-0000-4003-8000-000000300000',
    'Cheesecake',
    'New York style cheesecake',
    8.86,
    TRUE
),
(
    '001e8686-001e-4868-8001-001e8686001e',
    '000f42d2-000f-442d-8000-000f42d2000f',
    '00000030-0000-4003-8000-000000300000',
    'Tiramisu',
    'Classic Italian dessert',
    6.57,
    TRUE
),
(
    '001e8687-001e-4868-8001-001e8687001e',
    '000f42d3-000f-442d-8000-000f42d3000f',
    '00000031-0000-4003-8000-000000310000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.38,
    TRUE
),
(
    '001e8688-001e-4868-8001-001e8688001e',
    '000f42d3-000f-442d-8000-000f42d3000f',
    '00000031-0000-4003-8000-000000310000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.09,
    TRUE
),
(
    '001e8689-001e-4868-8001-001e8689001e',
    '000f42d3-000f-442d-8000-000f42d3000f',
    '00000031-0000-4003-8000-000000310000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.37,
    TRUE
),
(
    '001e868a-001e-4868-8001-001e868a001e',
    '000f42d3-000f-442d-8000-000f42d3000f',
    '00000031-0000-4003-8000-000000310000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.62,
    TRUE
),
(
    '001e868b-001e-4868-8001-001e868b001e',
    '000f42d4-000f-442d-8000-000f42d4000f',
    '00000031-0000-4003-8000-000000310000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.72,
    TRUE
),
(
    '001e868c-001e-4868-8001-001e868c001e',
    '000f42d4-000f-442d-8000-000f42d4000f',
    '00000031-0000-4003-8000-000000310000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.42,
    TRUE
),
(
    '001e868d-001e-4868-8001-001e868d001e',
    '000f42d4-000f-442d-8000-000f42d4000f',
    '00000031-0000-4003-8000-000000310000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.61,
    TRUE
),
(
    '001e868e-001e-4868-8001-001e868e001e',
    '000f42d4-000f-442d-8000-000f42d4000f',
    '00000031-0000-4003-8000-000000310000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.14,
    TRUE
),
(
    '001e868f-001e-4868-8001-001e868f001e',
    '000f42d5-000f-442d-8000-000f42d5000f',
    '00000032-0000-4003-8000-000000320000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.95,
    TRUE
),
(
    '001e8690-001e-4869-8001-001e8690001e',
    '000f42d5-000f-442d-8000-000f42d5000f',
    '00000032-0000-4003-8000-000000320000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.80,
    TRUE
),
(
    '001e8691-001e-4869-8001-001e8691001e',
    '000f42d5-000f-442d-8000-000f42d5000f',
    '00000032-0000-4003-8000-000000320000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.60,
    TRUE
),
(
    '001e8692-001e-4869-8001-001e8692001e',
    '000f42d5-000f-442d-8000-000f42d5000f',
    '00000032-0000-4003-8000-000000320000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.76,
    TRUE
),
(
    '001e8693-001e-4869-8001-001e8693001e',
    '000f42d6-000f-442d-8000-000f42d6000f',
    '00000032-0000-4003-8000-000000320000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.31,
    TRUE
),
(
    '001e8694-001e-4869-8001-001e8694001e',
    '000f42d6-000f-442d-8000-000f42d6000f',
    '00000032-0000-4003-8000-000000320000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.75,
    TRUE
),
(
    '001e8695-001e-4869-8001-001e8695001e',
    '000f42d6-000f-442d-8000-000f42d6000f',
    '00000032-0000-4003-8000-000000320000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.70,
    TRUE
),
(
    '001e8696-001e-4869-8001-001e8696001e',
    '000f42d6-000f-442d-8000-000f42d6000f',
    '00000032-0000-4003-8000-000000320000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.45,
    TRUE
),
(
    '001e8697-001e-4869-8001-001e8697001e',
    '000f42d7-000f-442d-8000-000f42d7000f',
    '00000033-0000-4003-8000-000000330000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.18,
    TRUE
),
(
    '001e8698-001e-4869-8001-001e8698001e',
    '000f42d7-000f-442d-8000-000f42d7000f',
    '00000033-0000-4003-8000-000000330000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.04,
    TRUE
),
(
    '001e8699-001e-4869-8001-001e8699001e',
    '000f42d7-000f-442d-8000-000f42d7000f',
    '00000033-0000-4003-8000-000000330000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.64,
    TRUE
),
(
    '001e869a-001e-4869-8001-001e869a001e',
    '000f42d8-000f-442d-8000-000f42d8000f',
    '00000033-0000-4003-8000-000000330000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.77,
    TRUE
),
(
    '001e869b-001e-4869-8001-001e869b001e',
    '000f42d8-000f-442d-8000-000f42d8000f',
    '00000033-0000-4003-8000-000000330000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.16,
    TRUE
),
(
    '001e869c-001e-4869-8001-001e869c001e',
    '000f42d8-000f-442d-8000-000f42d8000f',
    '00000033-0000-4003-8000-000000330000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.24,
    TRUE
),
(
    '001e869d-001e-4869-8001-001e869d001e',
    '000f42d8-000f-442d-8000-000f42d8000f',
    '00000033-0000-4003-8000-000000330000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.57,
    TRUE
),
(
    '001e869e-001e-4869-8001-001e869e001e',
    '000f42d9-000f-442d-8000-000f42d9000f',
    '00000033-0000-4003-8000-000000330000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.07,
    TRUE
),
(
    '001e869f-001e-4869-8001-001e869f001e',
    '000f42d9-000f-442d-8000-000f42d9000f',
    '00000033-0000-4003-8000-000000330000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.75,
    TRUE
),
(
    '001e86a0-001e-486a-8001-001e86a0001e',
    '000f42d9-000f-442d-8000-000f42d9000f',
    '00000033-0000-4003-8000-000000330000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.64,
    TRUE
),
(
    '001e86a1-001e-486a-8001-001e86a1001e',
    '000f42da-000f-442d-8000-000f42da000f',
    '00000034-0000-4003-8000-000000340000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.90,
    TRUE
),
(
    '001e86a2-001e-486a-8001-001e86a2001e',
    '000f42da-000f-442d-8000-000f42da000f',
    '00000034-0000-4003-8000-000000340000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.57,
    TRUE
),
(
    '001e86a3-001e-486a-8001-001e86a3001e',
    '000f42da-000f-442d-8000-000f42da000f',
    '00000034-0000-4003-8000-000000340000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.54,
    TRUE
),
(
    '001e86a4-001e-486a-8001-001e86a4001e',
    '000f42da-000f-442d-8000-000f42da000f',
    '00000034-0000-4003-8000-000000340000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.56,
    TRUE
),
(
    '001e86a5-001e-486a-8001-001e86a5001e',
    '000f42db-000f-442d-8000-000f42db000f',
    '00000034-0000-4003-8000-000000340000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.84,
    TRUE
),
(
    '001e86a6-001e-486a-8001-001e86a6001e',
    '000f42db-000f-442d-8000-000f42db000f',
    '00000034-0000-4003-8000-000000340000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.78,
    TRUE
),
(
    '001e86a7-001e-486a-8001-001e86a7001e',
    '000f42db-000f-442d-8000-000f42db000f',
    '00000034-0000-4003-8000-000000340000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.53,
    TRUE
),
(
    '001e86a8-001e-486a-8001-001e86a8001e',
    '000f42db-000f-442d-8000-000f42db000f',
    '00000034-0000-4003-8000-000000340000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.84,
    TRUE
),
(
    '001e86a9-001e-486a-8001-001e86a9001e',
    '000f42dc-000f-442d-8000-000f42dc000f',
    '00000034-0000-4003-8000-000000340000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    8.85,
    TRUE
),
(
    '001e86aa-001e-486a-8001-001e86aa001e',
    '000f42dc-000f-442d-8000-000f42dc000f',
    '00000034-0000-4003-8000-000000340000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.63,
    TRUE
),
(
    '001e86ab-001e-486a-8001-001e86ab001e',
    '000f42dc-000f-442d-8000-000f42dc000f',
    '00000034-0000-4003-8000-000000340000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.18,
    TRUE
),
(
    '001e86ac-001e-486a-8001-001e86ac001e',
    '000f42dd-000f-442d-8000-000f42dd000f',
    '00000035-0000-4003-8000-000000350000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.72,
    TRUE
),
(
    '001e86ad-001e-486a-8001-001e86ad001e',
    '000f42dd-000f-442d-8000-000f42dd000f',
    '00000035-0000-4003-8000-000000350000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.30,
    TRUE
),
(
    '001e86ae-001e-486a-8001-001e86ae001e',
    '000f42dd-000f-442d-8000-000f42dd000f',
    '00000035-0000-4003-8000-000000350000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.23,
    TRUE
),
(
    '001e86af-001e-486a-8001-001e86af001e',
    '000f42dd-000f-442d-8000-000f42dd000f',
    '00000035-0000-4003-8000-000000350000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.68,
    TRUE
),
(
    '001e86b0-001e-486b-8001-001e86b0001e',
    '000f42de-000f-442d-8000-000f42de000f',
    '00000035-0000-4003-8000-000000350000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.53,
    TRUE
),
(
    '001e86b1-001e-486b-8001-001e86b1001e',
    '000f42de-000f-442d-8000-000f42de000f',
    '00000035-0000-4003-8000-000000350000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.49,
    TRUE
),
(
    '001e86b2-001e-486b-8001-001e86b2001e',
    '000f42de-000f-442d-8000-000f42de000f',
    '00000035-0000-4003-8000-000000350000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.24,
    TRUE
),
(
    '001e86b3-001e-486b-8001-001e86b3001e',
    '000f42df-000f-442d-8000-000f42df000f',
    '00000036-0000-4003-8000-000000360000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.96,
    TRUE
),
(
    '001e86b4-001e-486b-8001-001e86b4001e',
    '000f42df-000f-442d-8000-000f42df000f',
    '00000036-0000-4003-8000-000000360000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.41,
    TRUE
),
(
    '001e86b5-001e-486b-8001-001e86b5001e',
    '000f42df-000f-442d-8000-000f42df000f',
    '00000036-0000-4003-8000-000000360000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.87,
    TRUE
),
(
    '001e86b6-001e-486b-8001-001e86b6001e',
    '000f42df-000f-442d-8000-000f42df000f',
    '00000036-0000-4003-8000-000000360000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.52,
    TRUE
),
(
    '001e86b7-001e-486b-8001-001e86b7001e',
    '000f42e0-000f-442e-8000-000f42e0000f',
    '00000036-0000-4003-8000-000000360000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.25,
    TRUE
),
(
    '001e86b8-001e-486b-8001-001e86b8001e',
    '000f42e0-000f-442e-8000-000f42e0000f',
    '00000036-0000-4003-8000-000000360000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.09,
    TRUE
),
(
    '001e86b9-001e-486b-8001-001e86b9001e',
    '000f42e0-000f-442e-8000-000f42e0000f',
    '00000036-0000-4003-8000-000000360000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.41,
    TRUE
),
(
    '001e86ba-001e-486b-8001-001e86ba001e',
    '000f42e0-000f-442e-8000-000f42e0000f',
    '00000036-0000-4003-8000-000000360000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.47,
    TRUE
),
(
    '001e86bb-001e-486b-8001-001e86bb001e',
    '000f42e1-000f-442e-8000-000f42e1000f',
    '00000037-0000-4003-8000-000000370000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.52,
    TRUE
),
(
    '001e86bc-001e-486b-8001-001e86bc001e',
    '000f42e1-000f-442e-8000-000f42e1000f',
    '00000037-0000-4003-8000-000000370000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.92,
    TRUE
),
(
    '001e86bd-001e-486b-8001-001e86bd001e',
    '000f42e1-000f-442e-8000-000f42e1000f',
    '00000037-0000-4003-8000-000000370000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.42,
    TRUE
),
(
    '001e86be-001e-486b-8001-001e86be001e',
    '000f42e1-000f-442e-8000-000f42e1000f',
    '00000037-0000-4003-8000-000000370000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.42,
    TRUE
),
(
    '001e86bf-001e-486b-8001-001e86bf001e',
    '000f42e2-000f-442e-8000-000f42e2000f',
    '00000037-0000-4003-8000-000000370000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.71,
    TRUE
),
(
    '001e86c0-001e-486c-8001-001e86c0001e',
    '000f42e2-000f-442e-8000-000f42e2000f',
    '00000037-0000-4003-8000-000000370000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.32,
    TRUE
),
(
    '001e86c1-001e-486c-8001-001e86c1001e',
    '000f42e2-000f-442e-8000-000f42e2000f',
    '00000037-0000-4003-8000-000000370000',
    'Risotto',
    'Creamy Italian rice dish',
    13.94,
    TRUE
),
(
    '001e86c2-001e-486c-8001-001e86c2001e',
    '000f42e3-000f-442e-8000-000f42e3000f',
    '00000037-0000-4003-8000-000000370000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.74,
    TRUE
),
(
    '001e86c3-001e-486c-8001-001e86c3001e',
    '000f42e3-000f-442e-8000-000f42e3000f',
    '00000037-0000-4003-8000-000000370000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.88,
    TRUE
),
(
    '001e86c4-001e-486c-8001-001e86c4001e',
    '000f42e3-000f-442e-8000-000f42e3000f',
    '00000037-0000-4003-8000-000000370000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.75,
    TRUE
),
(
    '001e86c5-001e-486c-8001-001e86c5001e',
    '000f42e3-000f-442e-8000-000f42e3000f',
    '00000037-0000-4003-8000-000000370000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.93,
    TRUE
),
(
    '001e86c6-001e-486c-8001-001e86c6001e',
    '000f42e4-000f-442e-8000-000f42e4000f',
    '00000037-0000-4003-8000-000000370000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.46,
    TRUE
),
(
    '001e86c7-001e-486c-8001-001e86c7001e',
    '000f42e4-000f-442e-8000-000f42e4000f',
    '00000037-0000-4003-8000-000000370000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.07,
    TRUE
),
(
    '001e86c8-001e-486c-8001-001e86c8001e',
    '000f42e4-000f-442e-8000-000f42e4000f',
    '00000037-0000-4003-8000-000000370000',
    'Cheesecake',
    'New York style cheesecake',
    8.73,
    TRUE
),
(
    '001e86c9-001e-486c-8001-001e86c9001e',
    '000f42e4-000f-442e-8000-000f42e4000f',
    '00000037-0000-4003-8000-000000370000',
    'Tiramisu',
    'Classic Italian dessert',
    8.38,
    TRUE
),
(
    '001e86ca-001e-486c-8001-001e86ca001e',
    '000f42e5-000f-442e-8000-000f42e5000f',
    '00000038-0000-4003-8000-000000380000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.56,
    TRUE
),
(
    '001e86cb-001e-486c-8001-001e86cb001e',
    '000f42e5-000f-442e-8000-000f42e5000f',
    '00000038-0000-4003-8000-000000380000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.39,
    TRUE
),
(
    '001e86cc-001e-486c-8001-001e86cc001e',
    '000f42e5-000f-442e-8000-000f42e5000f',
    '00000038-0000-4003-8000-000000380000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.42,
    TRUE
),
(
    '001e86cd-001e-486c-8001-001e86cd001e',
    '000f42e6-000f-442e-8000-000f42e6000f',
    '00000038-0000-4003-8000-000000380000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.75,
    TRUE
),
(
    '001e86ce-001e-486c-8001-001e86ce001e',
    '000f42e6-000f-442e-8000-000f42e6000f',
    '00000038-0000-4003-8000-000000380000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.65,
    TRUE
),
(
    '001e86cf-001e-486c-8001-001e86cf001e',
    '000f42e6-000f-442e-8000-000f42e6000f',
    '00000038-0000-4003-8000-000000380000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.11,
    TRUE
),
(
    '001e86d0-001e-486d-8001-001e86d0001e',
    '000f42e7-000f-442e-8000-000f42e7000f',
    '00000038-0000-4003-8000-000000380000',
    'French Fries',
    'Crispy golden fries',
    5.76,
    TRUE
),
(
    '001e86d1-001e-486d-8001-001e86d1001e',
    '000f42e7-000f-442e-8000-000f42e7000f',
    '00000038-0000-4003-8000-000000380000',
    'Onion Rings',
    'Battered and fried onion rings',
    5.52,
    TRUE
),
(
    '001e86d2-001e-486d-8001-001e86d2001e',
    '000f42e7-000f-442e-8000-000f42e7000f',
    '00000038-0000-4003-8000-000000380000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.34,
    TRUE
),
(
    '001e86d3-001e-486d-8001-001e86d3001e',
    '000f42e8-000f-442e-8000-000f42e8000f',
    '00000038-0000-4003-8000-000000380000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.22,
    TRUE
),
(
    '001e86d4-001e-486d-8001-001e86d4001e',
    '000f42e8-000f-442e-8000-000f42e8000f',
    '00000038-0000-4003-8000-000000380000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.06,
    TRUE
),
(
    '001e86d5-001e-486d-8001-001e86d5001e',
    '000f42e8-000f-442e-8000-000f42e8000f',
    '00000038-0000-4003-8000-000000380000',
    'Cheesecake',
    'New York style cheesecake',
    8.53,
    TRUE
),
(
    '001e86d6-001e-486d-8001-001e86d6001e',
    '000f42e8-000f-442e-8000-000f42e8000f',
    '00000038-0000-4003-8000-000000380000',
    'Tiramisu',
    'Classic Italian dessert',
    7.62,
    TRUE
),
(
    '001e86d7-001e-486d-8001-001e86d7001e',
    '000f42e9-000f-442e-8000-000f42e9000f',
    '00000039-0000-4003-8000-000000390000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.61,
    TRUE
),
(
    '001e86d8-001e-486d-8001-001e86d8001e',
    '000f42e9-000f-442e-8000-000f42e9000f',
    '00000039-0000-4003-8000-000000390000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.88,
    TRUE
),
(
    '001e86d9-001e-486d-8001-001e86d9001e',
    '000f42e9-000f-442e-8000-000f42e9000f',
    '00000039-0000-4003-8000-000000390000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.33,
    TRUE
),
(
    '001e86da-001e-486d-8001-001e86da001e',
    '000f42e9-000f-442e-8000-000f42e9000f',
    '00000039-0000-4003-8000-000000390000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.36,
    TRUE
),
(
    '001e86db-001e-486d-8001-001e86db001e',
    '000f42ea-000f-442e-8000-000f42ea000f',
    '00000039-0000-4003-8000-000000390000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.03,
    TRUE
),
(
    '001e86dc-001e-486d-8001-001e86dc001e',
    '000f42ea-000f-442e-8000-000f42ea000f',
    '00000039-0000-4003-8000-000000390000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.08,
    TRUE
),
(
    '001e86dd-001e-486d-8001-001e86dd001e',
    '000f42ea-000f-442e-8000-000f42ea000f',
    '00000039-0000-4003-8000-000000390000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.27,
    TRUE
),
(
    '001e86de-001e-486d-8001-001e86de001e',
    '000f42eb-000f-442e-8000-000f42eb000f',
    '00000039-0000-4003-8000-000000390000',
    'French Fries',
    'Crispy golden fries',
    4.81,
    TRUE
),
(
    '001e86df-001e-486d-8001-001e86df001e',
    '000f42eb-000f-442e-8000-000f42eb000f',
    '00000039-0000-4003-8000-000000390000',
    'Onion Rings',
    'Battered and fried onion rings',
    5.80,
    TRUE
),
(
    '001e86e0-001e-486e-8001-001e86e0001e',
    '000f42eb-000f-442e-8000-000f42eb000f',
    '00000039-0000-4003-8000-000000390000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.84,
    TRUE
),
(
    '001e86e1-001e-486e-8001-001e86e1001e',
    '000f42ec-000f-442e-8000-000f42ec000f',
    '0000003a-0000-4003-8000-0000003a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.40,
    TRUE
),
(
    '001e86e2-001e-486e-8001-001e86e2001e',
    '000f42ec-000f-442e-8000-000f42ec000f',
    '0000003a-0000-4003-8000-0000003a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.13,
    TRUE
),
(
    '001e86e3-001e-486e-8001-001e86e3001e',
    '000f42ec-000f-442e-8000-000f42ec000f',
    '0000003a-0000-4003-8000-0000003a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.75,
    TRUE
),
(
    '001e86e4-001e-486e-8001-001e86e4001e',
    '000f42ed-000f-442e-8000-000f42ed000f',
    '0000003a-0000-4003-8000-0000003a0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.36,
    TRUE
),
(
    '001e86e5-001e-486e-8001-001e86e5001e',
    '000f42ed-000f-442e-8000-000f42ed000f',
    '0000003a-0000-4003-8000-0000003a0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.31,
    TRUE
),
(
    '001e86e6-001e-486e-8001-001e86e6001e',
    '000f42ed-000f-442e-8000-000f42ed000f',
    '0000003a-0000-4003-8000-0000003a0000',
    'Risotto',
    'Creamy Italian rice dish',
    13.26,
    TRUE
),
(
    '001e86e7-001e-486e-8001-001e86e7001e',
    '000f42ee-000f-442e-8000-000f42ee000f',
    '0000003b-0000-4003-8000-0000003b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.21,
    TRUE
),
(
    '001e86e8-001e-486e-8001-001e86e8001e',
    '000f42ee-000f-442e-8000-000f42ee000f',
    '0000003b-0000-4003-8000-0000003b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.38,
    TRUE
),
(
    '001e86e9-001e-486e-8001-001e86e9001e',
    '000f42ee-000f-442e-8000-000f42ee000f',
    '0000003b-0000-4003-8000-0000003b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.60,
    TRUE
),
(
    '001e86ea-001e-486e-8001-001e86ea001e',
    '000f42ee-000f-442e-8000-000f42ee000f',
    '0000003b-0000-4003-8000-0000003b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.10,
    TRUE
),
(
    '001e86eb-001e-486e-8001-001e86eb001e',
    '000f42ef-000f-442e-8000-000f42ef000f',
    '0000003b-0000-4003-8000-0000003b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.92,
    TRUE
),
(
    '001e86ec-001e-486e-8001-001e86ec001e',
    '000f42ef-000f-442e-8000-000f42ef000f',
    '0000003b-0000-4003-8000-0000003b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.45,
    TRUE
),
(
    '001e86ed-001e-486e-8001-001e86ed001e',
    '000f42ef-000f-442e-8000-000f42ef000f',
    '0000003b-0000-4003-8000-0000003b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.88,
    TRUE
),
(
    '001e86ee-001e-486e-8001-001e86ee001e',
    '000f42ef-000f-442e-8000-000f42ef000f',
    '0000003b-0000-4003-8000-0000003b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.98,
    TRUE
),
(
    '001e86ef-001e-486e-8001-001e86ef001e',
    '000f42f0-000f-442f-8000-000f42f0000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    12.35,
    TRUE
),
(
    '001e86f0-001e-486f-8001-001e86f0001e',
    '000f42f0-000f-442f-8000-000f42f0000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    14.45,
    TRUE
),
(
    '001e86f1-001e-486f-8001-001e86f1001e',
    '000f42f0-000f-442f-8000-000f42f0000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives',
    15.17,
    TRUE
),
(
    '001e86f2-001e-486f-8001-001e86f2001e',
    '000f42f0-000f-442f-8000-000f42f0000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Hawaiian',
    'Ham, pineapple, mozzarella',
    14.64,
    TRUE
),
(
    '001e86f3-001e-486f-8001-001e86f3001e',
    '000f42f1-000f-442f-8000-000f42f1000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino',
    13.23,
    TRUE
),
(
    '001e86f4-001e-486f-8001-001e86f4001e',
    '000f42f1-000f-442f-8000-000f42f1000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    11.33,
    TRUE
),
(
    '001e86f5-001e-486f-8001-001e86f5001e',
    '000f42f1-000f-442f-8000-000f42f1000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream',
    14.21,
    TRUE
),
(
    '001e86f6-001e-486f-8001-001e86f6001e',
    '000f42f2-000f-442f-8000-000f42f2000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.65,
    TRUE
),
(
    '001e86f7-001e-486f-8001-001e86f7001e',
    '000f42f2-000f-442f-8000-000f42f2000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.28,
    TRUE
),
(
    '001e86f8-001e-486f-8001-001e86f8001e',
    '000f42f2-000f-442f-8000-000f42f2000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.12,
    TRUE
),
(
    '001e86f9-001e-486f-8001-001e86f9001e',
    '000f42f2-000f-442f-8000-000f42f2000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.44,
    TRUE
),
(
    '001e86fa-001e-486f-8001-001e86fa001e',
    '000f42f3-000f-442f-8000-000f42f3000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.86,
    TRUE
),
(
    '001e86fb-001e-486f-8001-001e86fb001e',
    '000f42f3-000f-442f-8000-000f42f3000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.87,
    TRUE
),
(
    '001e86fc-001e-486f-8001-001e86fc001e',
    '000f42f3-000f-442f-8000-000f42f3000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Cheesecake',
    'New York style cheesecake',
    7.33,
    TRUE
),
(
    '001e86fd-001e-486f-8001-001e86fd001e',
    '000f42f3-000f-442f-8000-000f42f3000f',
    '0000003c-0000-4003-8000-0000003c0000',
    'Tiramisu',
    'Classic Italian dessert',
    8.38,
    TRUE
),
(
    '001e86fe-001e-486f-8001-001e86fe001e',
    '000f42f4-000f-442f-8000-000f42f4000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Har Gow',
    'Steamed shrimp dumplings',
    8.49,
    TRUE
),
(
    '001e86ff-001e-486f-8001-001e86ff001e',
    '000f42f4-000f-442f-8000-000f42f4000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    9.45,
    TRUE
),
(
    '001e8700-001e-4870-8001-001e8700001e',
    '000f42f4-000f-442f-8000-000f42f4000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    7.22,
    TRUE
),
(
    '001e8701-001e-4870-8001-001e8701001e',
    '000f42f4-000f-442f-8000-000f42f4000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Spring Rolls',
    'Crispy vegetable spring rolls',
    6.32,
    TRUE
),
(
    '001e8702-001e-4870-8001-001e8702001e',
    '000f42f5-000f-442f-8000-000f42f5000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    14.02,
    TRUE
),
(
    '001e8703-001e-4870-8001-001e8703001e',
    '000f42f5-000f-442f-8000-000f42f5000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.94,
    TRUE
),
(
    '001e8704-001e-4870-8001-001e8704001e',
    '000f42f5-000f-442f-8000-000f42f5000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.57,
    TRUE
),
(
    '001e8705-001e-4870-8001-001e8705001e',
    '000f42f6-000f-442f-8000-000f42f6000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.74,
    TRUE
),
(
    '001e8706-001e-4870-8001-001e8706001e',
    '000f42f6-000f-442f-8000-000f42f6000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.48,
    TRUE
),
(
    '001e8707-001e-4870-8001-001e8707001e',
    '000f42f6-000f-442f-8000-000f42f6000f',
    '0000003d-0000-4003-8000-0000003d0000',
    'Risotto',
    'Creamy Italian rice dish',
    12.52,
    TRUE
),
(
    '001e8708-001e-4870-8001-001e8708001e',
    '000f42f7-000f-442f-8000-000f42f7000f',
    '0000003e-0000-4003-8000-0000003e0000',
    'Beef Tacos',
    'Seasoned ground beef with lettuce and cheese',
    10.28,
    TRUE
),
(
    '001e8709-001e-4870-8001-001e8709001e',
    '000f42f7-000f-442f-8000-000f42f7000f',
    '0000003e-0000-4003-8000-0000003e0000',
    'Chicken Tacos',
    'Grilled chicken with salsa and avocado',
    10.21,
    TRUE
),
(
    '001e870a-001e-4870-8001-001e870a001e',
    '000f42f7-000f-442f-8000-000f42f7000f',
    '0000003e-0000-4003-8000-0000003e0000',
    'Fish Tacos',
    'Battered fish with cabbage slaw',
    11.62,
    TRUE
),
(
    '001e870b-001e-4870-8001-001e870b001e',
    '000f42f8-000f-442f-8000-000f42f8000f',
    '0000003e-0000-4003-8000-0000003e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.35,
    TRUE
),
(
    '001e870c-001e-4870-8001-001e870c001e',
    '000f42f8-000f-442f-8000-000f42f8000f',
    '0000003e-0000-4003-8000-0000003e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.55,
    TRUE
),
(
    '001e870d-001e-4870-8001-001e870d001e',
    '000f42f8-000f-442f-8000-000f42f8000f',
    '0000003e-0000-4003-8000-0000003e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.64,
    TRUE
),
(
    '001e870e-001e-4870-8001-001e870e001e',
    '000f42f9-000f-442f-8000-000f42f9000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    13.69,
    TRUE
),
(
    '001e870f-001e-4870-8001-001e870f001e',
    '000f42f9-000f-442f-8000-000f42f9000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.83,
    TRUE
),
(
    '001e8710-001e-4871-8001-001e8710001e',
    '000f42f9-000f-442f-8000-000f42f9000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    12.84,
    TRUE
),
(
    '001e8711-001e-4871-8001-001e8711001e',
    '000f42f9-000f-442f-8000-000f42f9000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    13.95,
    TRUE
),
(
    '001e8712-001e-4871-8001-001e8712001e',
    '000f42fa-000f-442f-8000-000f42fa000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.36,
    TRUE
),
(
    '001e8713-001e-4871-8001-001e8713001e',
    '000f42fa-000f-442f-8000-000f42fa000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.31,
    TRUE
),
(
    '001e8714-001e-4871-8001-001e8714001e',
    '000f42fa-000f-442f-8000-000f42fa000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.71,
    TRUE
),
(
    '001e8715-001e-4871-8001-001e8715001e',
    '000f42fb-000f-442f-8000-000f42fb000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.78,
    TRUE
),
(
    '001e8716-001e-4871-8001-001e8716001e',
    '000f42fb-000f-442f-8000-000f42fb000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.81,
    TRUE
),
(
    '001e8717-001e-4871-8001-001e8717001e',
    '000f42fb-000f-442f-8000-000f42fb000f',
    '0000003f-0000-4003-8000-0000003f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.53,
    TRUE
),
(
    '001e8718-001e-4871-8001-001e8718001e',
    '000f42fc-000f-442f-8000-000f42fc000f',
    '00000040-0000-4004-8000-000000400000',
    'Salmon Roll',
    'Fresh salmon with rice and nori',
    9.87,
    TRUE
),
(
    '001e8719-001e-4871-8001-001e8719001e',
    '000f42fc-000f-442f-8000-000f42fc000f',
    '00000040-0000-4004-8000-000000400000',
    'Tuna Roll',
    'Premium tuna with rice and nori',
    10.70,
    TRUE
),
(
    '001e871a-001e-4871-8001-001e871a001e',
    '000f42fc-000f-442f-8000-000f42fc000f',
    '00000040-0000-4004-8000-000000400000',
    'California Roll',
    'Crab, avocado, and cucumber',
    7.75,
    TRUE
),
(
    '001e871b-001e-4871-8001-001e871b001e',
    '000f42fc-000f-442f-8000-000f42fc000f',
    '00000040-0000-4004-8000-000000400000',
    'Dragon Roll',
    'Eel, cucumber, and avocado',
    13.53,
    TRUE
),
(
    '001e871c-001e-4871-8001-001e871c001e',
    '000f42fd-000f-442f-8000-000f42fd000f',
    '00000040-0000-4004-8000-000000400000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.20,
    TRUE
),
(
    '001e871d-001e-4871-8001-001e871d001e',
    '000f42fd-000f-442f-8000-000f42fd000f',
    '00000040-0000-4004-8000-000000400000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.71,
    TRUE
),
(
    '001e871e-001e-4871-8001-001e871e001e',
    '000f42fd-000f-442f-8000-000f42fd000f',
    '00000040-0000-4004-8000-000000400000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.20,
    TRUE
),
(
    '001e871f-001e-4871-8001-001e871f001e',
    '000f42fe-000f-442f-8000-000f42fe000f',
    '00000040-0000-4004-8000-000000400000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.23,
    TRUE
),
(
    '001e8720-001e-4872-8001-001e8720001e',
    '000f42fe-000f-442f-8000-000f42fe000f',
    '00000040-0000-4004-8000-000000400000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.72,
    TRUE
),
(
    '001e8721-001e-4872-8001-001e8721001e',
    '000f42fe-000f-442f-8000-000f42fe000f',
    '00000040-0000-4004-8000-000000400000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.01,
    TRUE
),
(
    '001e8722-001e-4872-8001-001e8722001e',
    '000f42fe-000f-442f-8000-000f42fe000f',
    '00000040-0000-4004-8000-000000400000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.96,
    TRUE
),
(
    '001e8723-001e-4872-8001-001e8723001e',
    '000f42ff-000f-442f-8000-000f42ff000f',
    '00000040-0000-4004-8000-000000400000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.69,
    TRUE
),
(
    '001e8724-001e-4872-8001-001e8724001e',
    '000f42ff-000f-442f-8000-000f42ff000f',
    '00000040-0000-4004-8000-000000400000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.18,
    TRUE
),
(
    '001e8725-001e-4872-8001-001e8725001e',
    '000f42ff-000f-442f-8000-000f42ff000f',
    '00000040-0000-4004-8000-000000400000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.91,
    TRUE
),
(
    '001e8726-001e-4872-8001-001e8726001e',
    '000f42ff-000f-442f-8000-000f42ff000f',
    '00000040-0000-4004-8000-000000400000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.16,
    TRUE
),
(
    '001e8727-001e-4872-8001-001e8727001e',
    '000f4300-000f-4430-8000-000f4300000f',
    '00000041-0000-4004-8000-000000410000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    14.49,
    TRUE
),
(
    '001e8728-001e-4872-8001-001e8728001e',
    '000f4300-000f-4430-8000-000f4300000f',
    '00000041-0000-4004-8000-000000410000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.10,
    TRUE
),
(
    '001e8729-001e-4872-8001-001e8729001e',
    '000f4300-000f-4430-8000-000f4300000f',
    '00000041-0000-4004-8000-000000410000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.38,
    TRUE
),
(
    '001e872a-001e-4872-8001-001e872a001e',
    '000f4301-000f-4430-8000-000f4301000f',
    '00000041-0000-4004-8000-000000410000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.69,
    TRUE
),
(
    '001e872b-001e-4872-8001-001e872b001e',
    '000f4301-000f-4430-8000-000f4301000f',
    '00000041-0000-4004-8000-000000410000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.21,
    TRUE
),
(
    '001e872c-001e-4872-8001-001e872c001e',
    '000f4301-000f-4430-8000-000f4301000f',
    '00000041-0000-4004-8000-000000410000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.81,
    TRUE
),
(
    '001e872d-001e-4872-8001-001e872d001e',
    '000f4301-000f-4430-8000-000f4301000f',
    '00000041-0000-4004-8000-000000410000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    12.21,
    TRUE
),
(
    '001e872e-001e-4872-8001-001e872e001e',
    '000f4302-000f-4430-8000-000f4302000f',
    '00000041-0000-4004-8000-000000410000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.81,
    TRUE
),
(
    '001e872f-001e-4872-8001-001e872f001e',
    '000f4302-000f-4430-8000-000f4302000f',
    '00000041-0000-4004-8000-000000410000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.62,
    TRUE
),
(
    '001e8730-001e-4873-8001-001e8730001e',
    '000f4302-000f-4430-8000-000f4302000f',
    '00000041-0000-4004-8000-000000410000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.56,
    TRUE
),
(
    '001e8731-001e-4873-8001-001e8731001e',
    '000f4303-000f-4430-8000-000f4303000f',
    '00000041-0000-4004-8000-000000410000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.66,
    TRUE
),
(
    '001e8732-001e-4873-8001-001e8732001e',
    '000f4303-000f-4430-8000-000f4303000f',
    '00000041-0000-4004-8000-000000410000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.13,
    TRUE
),
(
    '001e8733-001e-4873-8001-001e8733001e',
    '000f4303-000f-4430-8000-000f4303000f',
    '00000041-0000-4004-8000-000000410000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.41,
    TRUE
),
(
    '001e8734-001e-4873-8001-001e8734001e',
    '000f4304-000f-4430-8000-000f4304000f',
    '00000042-0000-4004-8000-000000420000',
    'Classic Burger',
    'Beef patty with lettuce, tomato, onion',
    11.59,
    TRUE
),
(
    '001e8735-001e-4873-8001-001e8735001e',
    '000f4304-000f-4430-8000-000f4304000f',
    '00000042-0000-4004-8000-000000420000',
    'Cheeseburger',
    'Beef patty with cheese and special sauce',
    11.10,
    TRUE
),
(
    '001e8736-001e-4873-8001-001e8736001e',
    '000f4304-000f-4430-8000-000f4304000f',
    '00000042-0000-4004-8000-000000420000',
    'Chicken Burger',
    'Grilled chicken breast with fixings',
    10.04,
    TRUE
),
(
    '001e8737-001e-4873-8001-001e8737001e',
    '000f4304-000f-4430-8000-000f4304000f',
    '00000042-0000-4004-8000-000000420000',
    'Veggie Burger',
    'Plant-based patty with vegetables',
    9.34,
    TRUE
),
(
    '001e8738-001e-4873-8001-001e8738001e',
    '000f4305-000f-4430-8000-000f4305000f',
    '00000042-0000-4004-8000-000000420000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.24,
    TRUE
),
(
    '001e8739-001e-4873-8001-001e8739001e',
    '000f4305-000f-4430-8000-000f4305000f',
    '00000042-0000-4004-8000-000000420000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.70,
    TRUE
),
(
    '001e873a-001e-4873-8001-001e873a001e',
    '000f4305-000f-4430-8000-000f4305000f',
    '00000042-0000-4004-8000-000000420000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.01,
    TRUE
),
(
    '001e873b-001e-4873-8001-001e873b001e',
    '000f4305-000f-4430-8000-000f4305000f',
    '00000042-0000-4004-8000-000000420000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.49,
    TRUE
),
(
    '001e873c-001e-4873-8001-001e873c001e',
    '000f4306-000f-4430-8000-000f4306000f',
    '00000043-0000-4004-8000-000000430000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.22,
    TRUE
),
(
    '001e873d-001e-4873-8001-001e873d001e',
    '000f4306-000f-4430-8000-000f4306000f',
    '00000043-0000-4004-8000-000000430000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.90,
    TRUE
),
(
    '001e873e-001e-4873-8001-001e873e001e',
    '000f4306-000f-4430-8000-000f4306000f',
    '00000043-0000-4004-8000-000000430000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.28,
    TRUE
),
(
    '001e873f-001e-4873-8001-001e873f001e',
    '000f4307-000f-4430-8000-000f4307000f',
    '00000043-0000-4004-8000-000000430000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    8.16,
    TRUE
),
(
    '001e8740-001e-4874-8001-001e8740001e',
    '000f4307-000f-4430-8000-000f4307000f',
    '00000043-0000-4004-8000-000000430000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.13,
    TRUE
),
(
    '001e8741-001e-4874-8001-001e8741001e',
    '000f4307-000f-4430-8000-000f4307000f',
    '00000043-0000-4004-8000-000000430000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.40,
    TRUE
),
(
    '001e8742-001e-4874-8001-001e8742001e',
    '000f4308-000f-4430-8000-000f4308000f',
    '00000043-0000-4004-8000-000000430000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.70,
    TRUE
),
(
    '001e8743-001e-4874-8001-001e8743001e',
    '000f4308-000f-4430-8000-000f4308000f',
    '00000043-0000-4004-8000-000000430000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.92,
    TRUE
),
(
    '001e8744-001e-4874-8001-001e8744001e',
    '000f4308-000f-4430-8000-000f4308000f',
    '00000043-0000-4004-8000-000000430000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.88,
    TRUE
),
(
    '001e8745-001e-4874-8001-001e8745001e',
    '000f4309-000f-4430-8000-000f4309000f',
    '00000044-0000-4004-8000-000000440000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.43,
    TRUE
),
(
    '001e8746-001e-4874-8001-001e8746001e',
    '000f4309-000f-4430-8000-000f4309000f',
    '00000044-0000-4004-8000-000000440000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.08,
    TRUE
),
(
    '001e8747-001e-4874-8001-001e8747001e',
    '000f4309-000f-4430-8000-000f4309000f',
    '00000044-0000-4004-8000-000000440000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.93,
    TRUE
),
(
    '001e8748-001e-4874-8001-001e8748001e',
    '000f430a-000f-4430-8000-000f430a000f',
    '00000044-0000-4004-8000-000000440000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.83,
    TRUE
),
(
    '001e8749-001e-4874-8001-001e8749001e',
    '000f430a-000f-4430-8000-000f430a000f',
    '00000044-0000-4004-8000-000000440000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.03,
    TRUE
),
(
    '001e874a-001e-4874-8001-001e874a001e',
    '000f430a-000f-4430-8000-000f430a000f',
    '00000044-0000-4004-8000-000000440000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.14,
    TRUE
),
(
    '001e874b-001e-4874-8001-001e874b001e',
    '000f430b-000f-4430-8000-000f430b000f',
    '00000044-0000-4004-8000-000000440000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.02,
    TRUE
),
(
    '001e874c-001e-4874-8001-001e874c001e',
    '000f430b-000f-4430-8000-000f430b000f',
    '00000044-0000-4004-8000-000000440000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.29,
    TRUE
),
(
    '001e874d-001e-4874-8001-001e874d001e',
    '000f430b-000f-4430-8000-000f430b000f',
    '00000044-0000-4004-8000-000000440000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.50,
    TRUE
),
(
    '001e874e-001e-4874-8001-001e874e001e',
    '000f430c-000f-4430-8000-000f430c000f',
    '00000045-0000-4004-8000-000000450000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.14,
    TRUE
),
(
    '001e874f-001e-4874-8001-001e874f001e',
    '000f430c-000f-4430-8000-000f430c000f',
    '00000045-0000-4004-8000-000000450000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.22,
    TRUE
),
(
    '001e8750-001e-4875-8001-001e8750001e',
    '000f430c-000f-4430-8000-000f430c000f',
    '00000045-0000-4004-8000-000000450000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.71,
    TRUE
),
(
    '001e8751-001e-4875-8001-001e8751001e',
    '000f430d-000f-4430-8000-000f430d000f',
    '00000045-0000-4004-8000-000000450000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.79,
    TRUE
),
(
    '001e8752-001e-4875-8001-001e8752001e',
    '000f430d-000f-4430-8000-000f430d000f',
    '00000045-0000-4004-8000-000000450000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.80,
    TRUE
),
(
    '001e8753-001e-4875-8001-001e8753001e',
    '000f430d-000f-4430-8000-000f430d000f',
    '00000045-0000-4004-8000-000000450000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.77,
    TRUE
),
(
    '001e8754-001e-4875-8001-001e8754001e',
    '000f430e-000f-4430-8000-000f430e000f',
    '00000046-0000-4004-8000-000000460000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.42,
    TRUE
),
(
    '001e8755-001e-4875-8001-001e8755001e',
    '000f430e-000f-4430-8000-000f430e000f',
    '00000046-0000-4004-8000-000000460000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.18,
    TRUE
),
(
    '001e8756-001e-4875-8001-001e8756001e',
    '000f430e-000f-4430-8000-000f430e000f',
    '00000046-0000-4004-8000-000000460000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.78,
    TRUE
),
(
    '001e8757-001e-4875-8001-001e8757001e',
    '000f430e-000f-4430-8000-000f430e000f',
    '00000046-0000-4004-8000-000000460000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.74,
    TRUE
),
(
    '001e8758-001e-4875-8001-001e8758001e',
    '000f430f-000f-4430-8000-000f430f000f',
    '00000046-0000-4004-8000-000000460000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.63,
    TRUE
),
(
    '001e8759-001e-4875-8001-001e8759001e',
    '000f430f-000f-4430-8000-000f430f000f',
    '00000046-0000-4004-8000-000000460000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.29,
    TRUE
),
(
    '001e875a-001e-4875-8001-001e875a001e',
    '000f430f-000f-4430-8000-000f430f000f',
    '00000046-0000-4004-8000-000000460000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.38,
    TRUE
),
(
    '001e875b-001e-4875-8001-001e875b001e',
    '000f430f-000f-4430-8000-000f430f000f',
    '00000046-0000-4004-8000-000000460000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.75,
    TRUE
),
(
    '001e875c-001e-4875-8001-001e875c001e',
    '000f4310-000f-4431-8000-000f4310000f',
    '00000046-0000-4004-8000-000000460000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.09,
    TRUE
),
(
    '001e875d-001e-4875-8001-001e875d001e',
    '000f4310-000f-4431-8000-000f4310000f',
    '00000046-0000-4004-8000-000000460000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.11,
    TRUE
),
(
    '001e875e-001e-4875-8001-001e875e001e',
    '000f4310-000f-4431-8000-000f4310000f',
    '00000046-0000-4004-8000-000000460000',
    'Risotto',
    'Creamy Italian rice dish',
    13.93,
    TRUE
),
(
    '001e875f-001e-4875-8001-001e875f001e',
    '000f4311-000f-4431-8000-000f4311000f',
    '00000047-0000-4004-8000-000000470000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.68,
    TRUE
),
(
    '001e8760-001e-4876-8001-001e8760001e',
    '000f4311-000f-4431-8000-000f4311000f',
    '00000047-0000-4004-8000-000000470000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.20,
    TRUE
),
(
    '001e8761-001e-4876-8001-001e8761001e',
    '000f4311-000f-4431-8000-000f4311000f',
    '00000047-0000-4004-8000-000000470000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.95,
    TRUE
),
(
    '001e8762-001e-4876-8001-001e8762001e',
    '000f4311-000f-4431-8000-000f4311000f',
    '00000047-0000-4004-8000-000000470000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.63,
    TRUE
),
(
    '001e8763-001e-4876-8001-001e8763001e',
    '000f4312-000f-4431-8000-000f4312000f',
    '00000047-0000-4004-8000-000000470000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.67,
    TRUE
),
(
    '001e8764-001e-4876-8001-001e8764001e',
    '000f4312-000f-4431-8000-000f4312000f',
    '00000047-0000-4004-8000-000000470000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.57,
    TRUE
),
(
    '001e8765-001e-4876-8001-001e8765001e',
    '000f4312-000f-4431-8000-000f4312000f',
    '00000047-0000-4004-8000-000000470000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.88,
    TRUE
),
(
    '001e8766-001e-4876-8001-001e8766001e',
    '000f4313-000f-4431-8000-000f4313000f',
    '00000048-0000-4004-8000-000000480000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.30,
    TRUE
),
(
    '001e8767-001e-4876-8001-001e8767001e',
    '000f4313-000f-4431-8000-000f4313000f',
    '00000048-0000-4004-8000-000000480000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.54,
    TRUE
),
(
    '001e8768-001e-4876-8001-001e8768001e',
    '000f4313-000f-4431-8000-000f4313000f',
    '00000048-0000-4004-8000-000000480000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.69,
    TRUE
),
(
    '001e8769-001e-4876-8001-001e8769001e',
    '000f4313-000f-4431-8000-000f4313000f',
    '00000048-0000-4004-8000-000000480000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.83,
    TRUE
),
(
    '001e876a-001e-4876-8001-001e876a001e',
    '000f4314-000f-4431-8000-000f4314000f',
    '00000048-0000-4004-8000-000000480000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.27,
    TRUE
),
(
    '001e876b-001e-4876-8001-001e876b001e',
    '000f4314-000f-4431-8000-000f4314000f',
    '00000048-0000-4004-8000-000000480000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.60,
    TRUE
),
(
    '001e876c-001e-4876-8001-001e876c001e',
    '000f4314-000f-4431-8000-000f4314000f',
    '00000048-0000-4004-8000-000000480000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.15,
    TRUE
),
(
    '001e876d-001e-4876-8001-001e876d001e',
    '000f4314-000f-4431-8000-000f4314000f',
    '00000048-0000-4004-8000-000000480000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.67,
    TRUE
),
(
    '001e876e-001e-4876-8001-001e876e001e',
    '000f4315-000f-4431-8000-000f4315000f',
    '00000048-0000-4004-8000-000000480000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    8.78,
    TRUE
),
(
    '001e876f-001e-4876-8001-001e876f001e',
    '000f4315-000f-4431-8000-000f4315000f',
    '00000048-0000-4004-8000-000000480000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.91,
    TRUE
),
(
    '001e8770-001e-4877-8001-001e8770001e',
    '000f4315-000f-4431-8000-000f4315000f',
    '00000048-0000-4004-8000-000000480000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.34,
    TRUE
),
(
    '001e8771-001e-4877-8001-001e8771001e',
    '000f4316-000f-4431-8000-000f4316000f',
    '00000048-0000-4004-8000-000000480000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.16,
    TRUE
),
(
    '001e8772-001e-4877-8001-001e8772001e',
    '000f4316-000f-4431-8000-000f4316000f',
    '00000048-0000-4004-8000-000000480000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.20,
    TRUE
),
(
    '001e8773-001e-4877-8001-001e8773001e',
    '000f4316-000f-4431-8000-000f4316000f',
    '00000048-0000-4004-8000-000000480000',
    'Cheesecake',
    'New York style cheesecake',
    8.06,
    TRUE
),
(
    '001e8774-001e-4877-8001-001e8774001e',
    '000f4316-000f-4431-8000-000f4316000f',
    '00000048-0000-4004-8000-000000480000',
    'Tiramisu',
    'Classic Italian dessert',
    6.74,
    TRUE
),
(
    '001e8775-001e-4877-8001-001e8775001e',
    '000f4317-000f-4431-8000-000f4317000f',
    '00000049-0000-4004-8000-000000490000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.19,
    TRUE
),
(
    '001e8776-001e-4877-8001-001e8776001e',
    '000f4317-000f-4431-8000-000f4317000f',
    '00000049-0000-4004-8000-000000490000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.07,
    TRUE
),
(
    '001e8777-001e-4877-8001-001e8777001e',
    '000f4317-000f-4431-8000-000f4317000f',
    '00000049-0000-4004-8000-000000490000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.33,
    TRUE
),
(
    '001e8778-001e-4877-8001-001e8778001e',
    '000f4317-000f-4431-8000-000f4317000f',
    '00000049-0000-4004-8000-000000490000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.61,
    TRUE
),
(
    '001e8779-001e-4877-8001-001e8779001e',
    '000f4318-000f-4431-8000-000f4318000f',
    '00000049-0000-4004-8000-000000490000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.03,
    TRUE
),
(
    '001e877a-001e-4877-8001-001e877a001e',
    '000f4318-000f-4431-8000-000f4318000f',
    '00000049-0000-4004-8000-000000490000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.43,
    TRUE
),
(
    '001e877b-001e-4877-8001-001e877b001e',
    '000f4318-000f-4431-8000-000f4318000f',
    '00000049-0000-4004-8000-000000490000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.23,
    TRUE
),
(
    '001e877c-001e-4877-8001-001e877c001e',
    '000f4318-000f-4431-8000-000f4318000f',
    '00000049-0000-4004-8000-000000490000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.17,
    TRUE
),
(
    '001e877d-001e-4877-8001-001e877d001e',
    '000f4319-000f-4431-8000-000f4319000f',
    '00000049-0000-4004-8000-000000490000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.32,
    TRUE
),
(
    '001e877e-001e-4877-8001-001e877e001e',
    '000f4319-000f-4431-8000-000f4319000f',
    '00000049-0000-4004-8000-000000490000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.10,
    TRUE
),
(
    '001e877f-001e-4877-8001-001e877f001e',
    '000f4319-000f-4431-8000-000f4319000f',
    '00000049-0000-4004-8000-000000490000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.53,
    TRUE
),
(
    '001e8780-001e-4878-8001-001e8780001e',
    '000f4319-000f-4431-8000-000f4319000f',
    '00000049-0000-4004-8000-000000490000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.49,
    TRUE
),
(
    '001e8781-001e-4878-8001-001e8781001e',
    '000f431a-000f-4431-8000-000f431a000f',
    '0000004a-0000-4004-8000-0000004a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.19,
    TRUE
),
(
    '001e8782-001e-4878-8001-001e8782001e',
    '000f431a-000f-4431-8000-000f431a000f',
    '0000004a-0000-4004-8000-0000004a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.89,
    TRUE
),
(
    '001e8783-001e-4878-8001-001e8783001e',
    '000f431a-000f-4431-8000-000f431a000f',
    '0000004a-0000-4004-8000-0000004a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.18,
    TRUE
),
(
    '001e8784-001e-4878-8001-001e8784001e',
    '000f431a-000f-4431-8000-000f431a000f',
    '0000004a-0000-4004-8000-0000004a0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.68,
    TRUE
),
(
    '001e8785-001e-4878-8001-001e8785001e',
    '000f431b-000f-4431-8000-000f431b000f',
    '0000004a-0000-4004-8000-0000004a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.14,
    TRUE
),
(
    '001e8786-001e-4878-8001-001e8786001e',
    '000f431b-000f-4431-8000-000f431b000f',
    '0000004a-0000-4004-8000-0000004a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.45,
    TRUE
),
(
    '001e8787-001e-4878-8001-001e8787001e',
    '000f431b-000f-4431-8000-000f431b000f',
    '0000004a-0000-4004-8000-0000004a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.66,
    TRUE
),
(
    '001e8788-001e-4878-8001-001e8788001e',
    '000f431c-000f-4431-8000-000f431c000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.10,
    TRUE
),
(
    '001e8789-001e-4878-8001-001e8789001e',
    '000f431c-000f-4431-8000-000f431c000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.70,
    TRUE
),
(
    '001e878a-001e-4878-8001-001e878a001e',
    '000f431c-000f-4431-8000-000f431c000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.94,
    TRUE
),
(
    '001e878b-001e-4878-8001-001e878b001e',
    '000f431c-000f-4431-8000-000f431c000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.38,
    TRUE
),
(
    '001e878c-001e-4878-8001-001e878c001e',
    '000f431d-000f-4431-8000-000f431d000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.58,
    TRUE
),
(
    '001e878d-001e-4878-8001-001e878d001e',
    '000f431d-000f-4431-8000-000f431d000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.47,
    TRUE
),
(
    '001e878e-001e-4878-8001-001e878e001e',
    '000f431d-000f-4431-8000-000f431d000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Risotto',
    'Creamy Italian rice dish',
    13.59,
    TRUE
),
(
    '001e878f-001e-4878-8001-001e878f001e',
    '000f431e-000f-4431-8000-000f431e000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.55,
    TRUE
),
(
    '001e8790-001e-4879-8001-001e8790001e',
    '000f431e-000f-4431-8000-000f431e000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.28,
    TRUE
),
(
    '001e8791-001e-4879-8001-001e8791001e',
    '000f431e-000f-4431-8000-000f431e000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.17,
    TRUE
),
(
    '001e8792-001e-4879-8001-001e8792001e',
    '000f431e-000f-4431-8000-000f431e000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.90,
    TRUE
),
(
    '001e8793-001e-4879-8001-001e8793001e',
    '000f431f-000f-4431-8000-000f431f000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.00,
    TRUE
),
(
    '001e8794-001e-4879-8001-001e8794001e',
    '000f431f-000f-4431-8000-000f431f000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.72,
    TRUE
),
(
    '001e8795-001e-4879-8001-001e8795001e',
    '000f431f-000f-4431-8000-000f431f000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Cheesecake',
    'New York style cheesecake',
    7.38,
    TRUE
),
(
    '001e8796-001e-4879-8001-001e8796001e',
    '000f431f-000f-4431-8000-000f431f000f',
    '0000004b-0000-4004-8000-0000004b0000',
    'Tiramisu',
    'Classic Italian dessert',
    7.62,
    TRUE
),
(
    '001e8797-001e-4879-8001-001e8797001e',
    '000f4320-000f-4432-8000-000f4320000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.70,
    TRUE
),
(
    '001e8798-001e-4879-8001-001e8798001e',
    '000f4320-000f-4432-8000-000f4320000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.43,
    TRUE
),
(
    '001e8799-001e-4879-8001-001e8799001e',
    '000f4320-000f-4432-8000-000f4320000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.23,
    TRUE
),
(
    '001e879a-001e-4879-8001-001e879a001e',
    '000f4320-000f-4432-8000-000f4320000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.37,
    TRUE
),
(
    '001e879b-001e-4879-8001-001e879b001e',
    '000f4321-000f-4432-8000-000f4321000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.41,
    TRUE
),
(
    '001e879c-001e-4879-8001-001e879c001e',
    '000f4321-000f-4432-8000-000f4321000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.71,
    TRUE
),
(
    '001e879d-001e-4879-8001-001e879d001e',
    '000f4321-000f-4432-8000-000f4321000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.64,
    TRUE
),
(
    '001e879e-001e-4879-8001-001e879e001e',
    '000f4321-000f-4432-8000-000f4321000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.22,
    TRUE
),
(
    '001e879f-001e-4879-8001-001e879f001e',
    '000f4322-000f-4432-8000-000f4322000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'French Fries',
    'Crispy golden fries',
    5.27,
    TRUE
),
(
    '001e87a0-001e-487a-8001-001e87a0001e',
    '000f4322-000f-4432-8000-000f4322000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.74,
    TRUE
),
(
    '001e87a1-001e-487a-8001-001e87a1001e',
    '000f4322-000f-4432-8000-000f4322000f',
    '0000004c-0000-4004-8000-0000004c0000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.65,
    TRUE
),
(
    '001e87a2-001e-487a-8001-001e87a2001e',
    '000f4323-000f-4432-8000-000f4323000f',
    '0000004d-0000-4004-8000-0000004d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.57,
    TRUE
),
(
    '001e87a3-001e-487a-8001-001e87a3001e',
    '000f4323-000f-4432-8000-000f4323000f',
    '0000004d-0000-4004-8000-0000004d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.51,
    TRUE
),
(
    '001e87a4-001e-487a-8001-001e87a4001e',
    '000f4323-000f-4432-8000-000f4323000f',
    '0000004d-0000-4004-8000-0000004d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.97,
    TRUE
),
(
    '001e87a5-001e-487a-8001-001e87a5001e',
    '000f4323-000f-4432-8000-000f4323000f',
    '0000004d-0000-4004-8000-0000004d0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.36,
    TRUE
),
(
    '001e87a6-001e-487a-8001-001e87a6001e',
    '000f4324-000f-4432-8000-000f4324000f',
    '0000004d-0000-4004-8000-0000004d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.06,
    TRUE
),
(
    '001e87a7-001e-487a-8001-001e87a7001e',
    '000f4324-000f-4432-8000-000f4324000f',
    '0000004d-0000-4004-8000-0000004d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.31,
    TRUE
),
(
    '001e87a8-001e-487a-8001-001e87a8001e',
    '000f4324-000f-4432-8000-000f4324000f',
    '0000004d-0000-4004-8000-0000004d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.65,
    TRUE
),
(
    '001e87a9-001e-487a-8001-001e87a9001e',
    '000f4324-000f-4432-8000-000f4324000f',
    '0000004d-0000-4004-8000-0000004d0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.17,
    TRUE
),
(
    '001e87aa-001e-487a-8001-001e87aa001e',
    '000f4325-000f-4432-8000-000f4325000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.98,
    TRUE
),
(
    '001e87ab-001e-487a-8001-001e87ab001e',
    '000f4325-000f-4432-8000-000f4325000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.97,
    TRUE
),
(
    '001e87ac-001e-487a-8001-001e87ac001e',
    '000f4325-000f-4432-8000-000f4325000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.18,
    TRUE
),
(
    '001e87ad-001e-487a-8001-001e87ad001e',
    '000f4326-000f-4432-8000-000f4326000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.70,
    TRUE
),
(
    '001e87ae-001e-487a-8001-001e87ae001e',
    '000f4326-000f-4432-8000-000f4326000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.77,
    TRUE
),
(
    '001e87af-001e-487a-8001-001e87af001e',
    '000f4326-000f-4432-8000-000f4326000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Risotto',
    'Creamy Italian rice dish',
    13.86,
    TRUE
),
(
    '001e87b0-001e-487b-8001-001e87b0001e',
    '000f4327-000f-4432-8000-000f4327000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.01,
    TRUE
),
(
    '001e87b1-001e-487b-8001-001e87b1001e',
    '000f4327-000f-4432-8000-000f4327000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.18,
    TRUE
),
(
    '001e87b2-001e-487b-8001-001e87b2001e',
    '000f4327-000f-4432-8000-000f4327000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.53,
    TRUE
),
(
    '001e87b3-001e-487b-8001-001e87b3001e',
    '000f4328-000f-4432-8000-000f4328000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.25,
    TRUE
),
(
    '001e87b4-001e-487b-8001-001e87b4001e',
    '000f4328-000f-4432-8000-000f4328000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.58,
    TRUE
),
(
    '001e87b5-001e-487b-8001-001e87b5001e',
    '000f4328-000f-4432-8000-000f4328000f',
    '0000004e-0000-4004-8000-0000004e0000',
    'Cheesecake',
    'New York style cheesecake',
    8.04,
    TRUE
),
(
    '001e87b6-001e-487b-8001-001e87b6001e',
    '000f4329-000f-4432-8000-000f4329000f',
    '0000004f-0000-4004-8000-0000004f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.85,
    TRUE
),
(
    '001e87b7-001e-487b-8001-001e87b7001e',
    '000f4329-000f-4432-8000-000f4329000f',
    '0000004f-0000-4004-8000-0000004f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.37,
    TRUE
),
(
    '001e87b8-001e-487b-8001-001e87b8001e',
    '000f4329-000f-4432-8000-000f4329000f',
    '0000004f-0000-4004-8000-0000004f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.46,
    TRUE
),
(
    '001e87b9-001e-487b-8001-001e87b9001e',
    '000f432a-000f-4432-8000-000f432a000f',
    '0000004f-0000-4004-8000-0000004f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.30,
    TRUE
),
(
    '001e87ba-001e-487b-8001-001e87ba001e',
    '000f432a-000f-4432-8000-000f432a000f',
    '0000004f-0000-4004-8000-0000004f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.51,
    TRUE
),
(
    '001e87bb-001e-487b-8001-001e87bb001e',
    '000f432a-000f-4432-8000-000f432a000f',
    '0000004f-0000-4004-8000-0000004f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.21,
    TRUE
),
(
    '001e87bc-001e-487b-8001-001e87bc001e',
    '000f432a-000f-4432-8000-000f432a000f',
    '0000004f-0000-4004-8000-0000004f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.24,
    TRUE
),
(
    '001e87bd-001e-487b-8001-001e87bd001e',
    '000f432b-000f-4432-8000-000f432b000f',
    '00000050-0000-4005-8000-000000500000',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    12.10,
    TRUE
),
(
    '001e87be-001e-487b-8001-001e87be001e',
    '000f432b-000f-4432-8000-000f432b000f',
    '00000050-0000-4005-8000-000000500000',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    14.63,
    TRUE
),
(
    '001e87bf-001e-487b-8001-001e87bf001e',
    '000f432b-000f-4432-8000-000f432b000f',
    '00000050-0000-4005-8000-000000500000',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives',
    15.69,
    TRUE
),
(
    '001e87c0-001e-487c-8001-001e87c0001e',
    '000f432b-000f-4432-8000-000f432b000f',
    '00000050-0000-4005-8000-000000500000',
    'Hawaiian',
    'Ham, pineapple, mozzarella',
    14.37,
    TRUE
),
(
    '001e87c1-001e-487c-8001-001e87c1001e',
    '000f432b-000f-4432-8000-000f432b000f',
    '00000050-0000-4005-8000-000000500000',
    'Vegetarian',
    'Mixed vegetables, mozzarella',
    12.80,
    TRUE
),
(
    '001e87c2-001e-487c-8001-001e87c2001e',
    '000f432c-000f-4432-8000-000f432c000f',
    '00000050-0000-4005-8000-000000500000',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino',
    14.77,
    TRUE
),
(
    '001e87c3-001e-487c-8001-001e87c3001e',
    '000f432c-000f-4432-8000-000f432c000f',
    '00000050-0000-4005-8000-000000500000',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    12.61,
    TRUE
),
(
    '001e87c4-001e-487c-8001-001e87c4001e',
    '000f432c-000f-4432-8000-000f432c000f',
    '00000050-0000-4005-8000-000000500000',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream',
    13.16,
    TRUE
),
(
    '001e87c5-001e-487c-8001-001e87c5001e',
    '000f432c-000f-4432-8000-000f432c000f',
    '00000050-0000-4005-8000-000000500000',
    'Lasagna',
    'Layered pasta with meat sauce and cheese',
    15.27,
    TRUE
),
(
    '001e87c6-001e-487c-8001-001e87c6001e',
    '000f432d-000f-4432-8000-000f432d000f',
    '00000051-0000-4005-8000-000000510000',
    'Har Gow',
    'Steamed shrimp dumplings',
    8.70,
    TRUE
),
(
    '001e87c7-001e-487c-8001-001e87c7001e',
    '000f432d-000f-4432-8000-000f432d000f',
    '00000051-0000-4005-8000-000000510000',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    9.22,
    TRUE
),
(
    '001e87c8-001e-487c-8001-001e87c8001e',
    '000f432d-000f-4432-8000-000f432d000f',
    '00000051-0000-4005-8000-000000510000',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    8.03,
    TRUE
),
(
    '001e87c9-001e-487c-8001-001e87c9001e',
    '000f432d-000f-4432-8000-000f432d000f',
    '00000051-0000-4005-8000-000000510000',
    'Spring Rolls',
    'Crispy vegetable spring rolls',
    7.86,
    TRUE
),
(
    '001e87ca-001e-487c-8001-001e87ca001e',
    '000f432e-000f-4432-8000-000f432e000f',
    '00000051-0000-4005-8000-000000510000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.93,
    TRUE
),
(
    '001e87cb-001e-487c-8001-001e87cb001e',
    '000f432e-000f-4432-8000-000f432e000f',
    '00000051-0000-4005-8000-000000510000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.03,
    TRUE
),
(
    '001e87cc-001e-487c-8001-001e87cc001e',
    '000f432e-000f-4432-8000-000f432e000f',
    '00000051-0000-4005-8000-000000510000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.68,
    TRUE
),
(
    '001e87cd-001e-487c-8001-001e87cd001e',
    '000f432f-000f-4432-8000-000f432f000f',
    '00000052-0000-4005-8000-000000520000',
    'Beef Tacos',
    'Seasoned ground beef with lettuce and cheese',
    10.24,
    TRUE
),
(
    '001e87ce-001e-487c-8001-001e87ce001e',
    '000f432f-000f-4432-8000-000f432f000f',
    '00000052-0000-4005-8000-000000520000',
    'Chicken Tacos',
    'Grilled chicken with salsa and avocado',
    10.92,
    TRUE
),
(
    '001e87cf-001e-487c-8001-001e87cf001e',
    '000f432f-000f-4432-8000-000f432f000f',
    '00000052-0000-4005-8000-000000520000',
    'Fish Tacos',
    'Battered fish with cabbage slaw',
    10.10,
    TRUE
),
(
    '001e87d0-001e-487d-8001-001e87d0001e',
    '000f432f-000f-4432-8000-000f432f000f',
    '00000052-0000-4005-8000-000000520000',
    'Vegetarian Tacos',
    'Black beans, corn, and vegetables',
    9.19,
    TRUE
),
(
    '001e87d1-001e-487d-8001-001e87d1001e',
    '000f4330-000f-4433-8000-000f4330000f',
    '00000052-0000-4005-8000-000000520000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.02,
    TRUE
),
(
    '001e87d2-001e-487d-8001-001e87d2001e',
    '000f4330-000f-4433-8000-000f4330000f',
    '00000052-0000-4005-8000-000000520000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.30,
    TRUE
),
(
    '001e87d3-001e-487d-8001-001e87d3001e',
    '000f4330-000f-4433-8000-000f4330000f',
    '00000052-0000-4005-8000-000000520000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.97,
    TRUE
),
(
    '001e87d4-001e-487d-8001-001e87d4001e',
    '000f4330-000f-4433-8000-000f4330000f',
    '00000052-0000-4005-8000-000000520000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.73,
    TRUE
),
(
    '001e87d5-001e-487d-8001-001e87d5001e',
    '000f4331-000f-4433-8000-000f4331000f',
    '00000053-0000-4005-8000-000000530000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    14.45,
    TRUE
),
(
    '001e87d6-001e-487d-8001-001e87d6001e',
    '000f4331-000f-4433-8000-000f4331000f',
    '00000053-0000-4005-8000-000000530000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    16.29,
    TRUE
),
(
    '001e87d7-001e-487d-8001-001e87d7001e',
    '000f4331-000f-4433-8000-000f4331000f',
    '00000053-0000-4005-8000-000000530000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    12.09,
    TRUE
),
(
    '001e87d8-001e-487d-8001-001e87d8001e',
    '000f4331-000f-4433-8000-000f4331000f',
    '00000053-0000-4005-8000-000000530000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    15.13,
    TRUE
),
(
    '001e87d9-001e-487d-8001-001e87d9001e',
    '000f4332-000f-4433-8000-000f4332000f',
    '00000053-0000-4005-8000-000000530000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.45,
    TRUE
),
(
    '001e87da-001e-487d-8001-001e87da001e',
    '000f4332-000f-4433-8000-000f4332000f',
    '00000053-0000-4005-8000-000000530000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.20,
    TRUE
),
(
    '001e87db-001e-487d-8001-001e87db001e',
    '000f4332-000f-4433-8000-000f4332000f',
    '00000053-0000-4005-8000-000000530000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.77,
    TRUE
),
(
    '001e87dc-001e-487d-8001-001e87dc001e',
    '000f4332-000f-4433-8000-000f4332000f',
    '00000053-0000-4005-8000-000000530000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.19,
    TRUE
),
(
    '001e87dd-001e-487d-8001-001e87dd001e',
    '000f4333-000f-4433-8000-000f4333000f',
    '00000054-0000-4005-8000-000000540000',
    'Salmon Roll',
    'Fresh salmon with rice and nori',
    8.83,
    TRUE
),
(
    '001e87de-001e-487d-8001-001e87de001e',
    '000f4333-000f-4433-8000-000f4333000f',
    '00000054-0000-4005-8000-000000540000',
    'Tuna Roll',
    'Premium tuna with rice and nori',
    9.72,
    TRUE
),
(
    '001e87df-001e-487d-8001-001e87df001e',
    '000f4333-000f-4433-8000-000f4333000f',
    '00000054-0000-4005-8000-000000540000',
    'California Roll',
    'Crab, avocado, and cucumber',
    8.84,
    TRUE
),
(
    '001e87e0-001e-487e-8001-001e87e0001e',
    '000f4333-000f-4433-8000-000f4333000f',
    '00000054-0000-4005-8000-000000540000',
    'Dragon Roll',
    'Eel, cucumber, and avocado',
    12.63,
    TRUE
),
(
    '001e87e1-001e-487e-8001-001e87e1001e',
    '000f4334-000f-4433-8000-000f4334000f',
    '00000054-0000-4005-8000-000000540000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.03,
    TRUE
),
(
    '001e87e2-001e-487e-8001-001e87e2001e',
    '000f4334-000f-4433-8000-000f4334000f',
    '00000054-0000-4005-8000-000000540000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.54,
    TRUE
),
(
    '001e87e3-001e-487e-8001-001e87e3001e',
    '000f4334-000f-4433-8000-000f4334000f',
    '00000054-0000-4005-8000-000000540000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.33,
    TRUE
),
(
    '001e87e4-001e-487e-8001-001e87e4001e',
    '000f4334-000f-4433-8000-000f4334000f',
    '00000054-0000-4005-8000-000000540000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.59,
    TRUE
),
(
    '001e87e5-001e-487e-8001-001e87e5001e',
    '000f4335-000f-4433-8000-000f4335000f',
    '00000055-0000-4005-8000-000000550000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    14.07,
    TRUE
),
(
    '001e87e6-001e-487e-8001-001e87e6001e',
    '000f4335-000f-4433-8000-000f4335000f',
    '00000055-0000-4005-8000-000000550000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    16.37,
    TRUE
),
(
    '001e87e7-001e-487e-8001-001e87e7001e',
    '000f4335-000f-4433-8000-000f4335000f',
    '00000055-0000-4005-8000-000000550000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.16,
    TRUE
),
(
    '001e87e8-001e-487e-8001-001e87e8001e',
    '000f4336-000f-4433-8000-000f4336000f',
    '00000055-0000-4005-8000-000000550000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    14.51,
    TRUE
),
(
    '001e87e9-001e-487e-8001-001e87e9001e',
    '000f4336-000f-4433-8000-000f4336000f',
    '00000055-0000-4005-8000-000000550000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.69,
    TRUE
),
(
    '001e87ea-001e-487e-8001-001e87ea001e',
    '000f4336-000f-4433-8000-000f4336000f',
    '00000055-0000-4005-8000-000000550000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    10.89,
    TRUE
),
(
    '001e87eb-001e-487e-8001-001e87eb001e',
    '000f4336-000f-4433-8000-000f4336000f',
    '00000055-0000-4005-8000-000000550000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    12.00,
    TRUE
),
(
    '001e87ec-001e-487e-8001-001e87ec001e',
    '000f4337-000f-4433-8000-000f4337000f',
    '00000055-0000-4005-8000-000000550000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.49,
    TRUE
),
(
    '001e87ed-001e-487e-8001-001e87ed001e',
    '000f4337-000f-4433-8000-000f4337000f',
    '00000055-0000-4005-8000-000000550000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.09,
    TRUE
),
(
    '001e87ee-001e-487e-8001-001e87ee001e',
    '000f4337-000f-4433-8000-000f4337000f',
    '00000055-0000-4005-8000-000000550000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.78,
    TRUE
),
(
    '001e87ef-001e-487e-8001-001e87ef001e',
    '000f4337-000f-4433-8000-000f4337000f',
    '00000055-0000-4005-8000-000000550000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.68,
    TRUE
),
(
    '001e87f0-001e-487f-8001-001e87f0001e',
    '000f4338-000f-4433-8000-000f4338000f',
    '00000056-0000-4005-8000-000000560000',
    'Classic Burger',
    'Beef patty with lettuce, tomato, onion',
    10.79,
    TRUE
),
(
    '001e87f1-001e-487f-8001-001e87f1001e',
    '000f4338-000f-4433-8000-000f4338000f',
    '00000056-0000-4005-8000-000000560000',
    'Cheeseburger',
    'Beef patty with cheese and special sauce',
    11.26,
    TRUE
),
(
    '001e87f2-001e-487f-8001-001e87f2001e',
    '000f4338-000f-4433-8000-000f4338000f',
    '00000056-0000-4005-8000-000000560000',
    'Chicken Burger',
    'Grilled chicken breast with fixings',
    10.51,
    TRUE
),
(
    '001e87f3-001e-487f-8001-001e87f3001e',
    '000f4338-000f-4433-8000-000f4338000f',
    '00000056-0000-4005-8000-000000560000',
    'Veggie Burger',
    'Plant-based patty with vegetables',
    10.65,
    TRUE
),
(
    '001e87f4-001e-487f-8001-001e87f4001e',
    '000f4339-000f-4433-8000-000f4339000f',
    '00000056-0000-4005-8000-000000560000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.30,
    TRUE
),
(
    '001e87f5-001e-487f-8001-001e87f5001e',
    '000f4339-000f-4433-8000-000f4339000f',
    '00000056-0000-4005-8000-000000560000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.13,
    TRUE
),
(
    '001e87f6-001e-487f-8001-001e87f6001e',
    '000f4339-000f-4433-8000-000f4339000f',
    '00000056-0000-4005-8000-000000560000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.84,
    TRUE
),
(
    '001e87f7-001e-487f-8001-001e87f7001e',
    '000f4339-000f-4433-8000-000f4339000f',
    '00000056-0000-4005-8000-000000560000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.18,
    TRUE
),
(
    '001e87f8-001e-487f-8001-001e87f8001e',
    '000f433a-000f-4433-8000-000f433a000f',
    '00000056-0000-4005-8000-000000560000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.93,
    TRUE
),
(
    '001e87f9-001e-487f-8001-001e87f9001e',
    '000f433a-000f-4433-8000-000f433a000f',
    '00000056-0000-4005-8000-000000560000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.92,
    TRUE
),
(
    '001e87fa-001e-487f-8001-001e87fa001e',
    '000f433a-000f-4433-8000-000f433a000f',
    '00000056-0000-4005-8000-000000560000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.26,
    TRUE
),
(
    '001e87fb-001e-487f-8001-001e87fb001e',
    '000f433b-000f-4433-8000-000f433b000f',
    '00000057-0000-4005-8000-000000570000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.83,
    TRUE
),
(
    '001e87fc-001e-487f-8001-001e87fc001e',
    '000f433b-000f-4433-8000-000f433b000f',
    '00000057-0000-4005-8000-000000570000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.41,
    TRUE
),
(
    '001e87fd-001e-487f-8001-001e87fd001e',
    '000f433b-000f-4433-8000-000f433b000f',
    '00000057-0000-4005-8000-000000570000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.80,
    TRUE
),
(
    '001e87fe-001e-487f-8001-001e87fe001e',
    '000f433b-000f-4433-8000-000f433b000f',
    '00000057-0000-4005-8000-000000570000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.79,
    TRUE
),
(
    '001e87ff-001e-487f-8001-001e87ff001e',
    '000f433c-000f-4433-8000-000f433c000f',
    '00000057-0000-4005-8000-000000570000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    8.32,
    TRUE
),
(
    '001e8800-001e-4880-8001-001e8800001e',
    '000f433c-000f-4433-8000-000f433c000f',
    '00000057-0000-4005-8000-000000570000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.59,
    TRUE
),
(
    '001e8801-001e-4880-8001-001e8801001e',
    '000f433c-000f-4433-8000-000f433c000f',
    '00000057-0000-4005-8000-000000570000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.45,
    TRUE
),
(
    '001e8802-001e-4880-8001-001e8802001e',
    '000f433d-000f-4433-8000-000f433d000f',
    '00000057-0000-4005-8000-000000570000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.94,
    TRUE
),
(
    '001e8803-001e-4880-8001-001e8803001e',
    '000f433d-000f-4433-8000-000f433d000f',
    '00000057-0000-4005-8000-000000570000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.52,
    TRUE
),
(
    '001e8804-001e-4880-8001-001e8804001e',
    '000f433d-000f-4433-8000-000f433d000f',
    '00000057-0000-4005-8000-000000570000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.82,
    TRUE
),
(
    '001e8805-001e-4880-8001-001e8805001e',
    '000f433e-000f-4433-8000-000f433e000f',
    '00000057-0000-4005-8000-000000570000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.38,
    TRUE
),
(
    '001e8806-001e-4880-8001-001e8806001e',
    '000f433e-000f-4433-8000-000f433e000f',
    '00000057-0000-4005-8000-000000570000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.51,
    TRUE
),
(
    '001e8807-001e-4880-8001-001e8807001e',
    '000f433e-000f-4433-8000-000f433e000f',
    '00000057-0000-4005-8000-000000570000',
    'Cheesecake',
    'New York style cheesecake',
    7.98,
    TRUE
),
(
    '001e8808-001e-4880-8001-001e8808001e',
    '000f433f-000f-4433-8000-000f433f000f',
    '00000058-0000-4005-8000-000000580000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.20,
    TRUE
),
(
    '001e8809-001e-4880-8001-001e8809001e',
    '000f433f-000f-4433-8000-000f433f000f',
    '00000058-0000-4005-8000-000000580000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.08,
    TRUE
),
(
    '001e880a-001e-4880-8001-001e880a001e',
    '000f433f-000f-4433-8000-000f433f000f',
    '00000058-0000-4005-8000-000000580000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.80,
    TRUE
),
(
    '001e880b-001e-4880-8001-001e880b001e',
    '000f4340-000f-4434-8000-000f4340000f',
    '00000058-0000-4005-8000-000000580000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.08,
    TRUE
),
(
    '001e880c-001e-4880-8001-001e880c001e',
    '000f4340-000f-4434-8000-000f4340000f',
    '00000058-0000-4005-8000-000000580000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.26,
    TRUE
),
(
    '001e880d-001e-4880-8001-001e880d001e',
    '000f4340-000f-4434-8000-000f4340000f',
    '00000058-0000-4005-8000-000000580000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.84,
    TRUE
),
(
    '001e880e-001e-4880-8001-001e880e001e',
    '000f4340-000f-4434-8000-000f4340000f',
    '00000058-0000-4005-8000-000000580000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.55,
    TRUE
),
(
    '001e880f-001e-4880-8001-001e880f001e',
    '000f4341-000f-4434-8000-000f4341000f',
    '00000058-0000-4005-8000-000000580000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.26,
    TRUE
),
(
    '001e8810-001e-4881-8001-001e8810001e',
    '000f4341-000f-4434-8000-000f4341000f',
    '00000058-0000-4005-8000-000000580000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.44,
    TRUE
),
(
    '001e8811-001e-4881-8001-001e8811001e',
    '000f4341-000f-4434-8000-000f4341000f',
    '00000058-0000-4005-8000-000000580000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.29,
    TRUE
),
(
    '001e8812-001e-4881-8001-001e8812001e',
    '000f4342-000f-4434-8000-000f4342000f',
    '00000058-0000-4005-8000-000000580000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.70,
    TRUE
),
(
    '001e8813-001e-4881-8001-001e8813001e',
    '000f4342-000f-4434-8000-000f4342000f',
    '00000058-0000-4005-8000-000000580000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.10,
    TRUE
),
(
    '001e8814-001e-4881-8001-001e8814001e',
    '000f4342-000f-4434-8000-000f4342000f',
    '00000058-0000-4005-8000-000000580000',
    'Cheesecake',
    'New York style cheesecake',
    7.59,
    TRUE
),
(
    '001e8815-001e-4881-8001-001e8815001e',
    '000f4343-000f-4434-8000-000f4343000f',
    '00000059-0000-4005-8000-000000590000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.03,
    TRUE
),
(
    '001e8816-001e-4881-8001-001e8816001e',
    '000f4343-000f-4434-8000-000f4343000f',
    '00000059-0000-4005-8000-000000590000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.89,
    TRUE
),
(
    '001e8817-001e-4881-8001-001e8817001e',
    '000f4343-000f-4434-8000-000f4343000f',
    '00000059-0000-4005-8000-000000590000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.87,
    TRUE
),
(
    '001e8818-001e-4881-8001-001e8818001e',
    '000f4344-000f-4434-8000-000f4344000f',
    '00000059-0000-4005-8000-000000590000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.29,
    TRUE
),
(
    '001e8819-001e-4881-8001-001e8819001e',
    '000f4344-000f-4434-8000-000f4344000f',
    '00000059-0000-4005-8000-000000590000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.56,
    TRUE
),
(
    '001e881a-001e-4881-8001-001e881a001e',
    '000f4344-000f-4434-8000-000f4344000f',
    '00000059-0000-4005-8000-000000590000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.17,
    TRUE
),
(
    '001e881b-001e-4881-8001-001e881b001e',
    '000f4344-000f-4434-8000-000f4344000f',
    '00000059-0000-4005-8000-000000590000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.99,
    TRUE
),
(
    '001e881c-001e-4881-8001-001e881c001e',
    '000f4345-000f-4434-8000-000f4345000f',
    '00000059-0000-4005-8000-000000590000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.23,
    TRUE
),
(
    '001e881d-001e-4881-8001-001e881d001e',
    '000f4345-000f-4434-8000-000f4345000f',
    '00000059-0000-4005-8000-000000590000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.83,
    TRUE
),
(
    '001e881e-001e-4881-8001-001e881e001e',
    '000f4345-000f-4434-8000-000f4345000f',
    '00000059-0000-4005-8000-000000590000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    12.32,
    TRUE
),
(
    '001e881f-001e-4881-8001-001e881f001e',
    '000f4345-000f-4434-8000-000f4345000f',
    '00000059-0000-4005-8000-000000590000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    12.33,
    TRUE
),
(
    '001e8820-001e-4882-8001-001e8820001e',
    '000f4346-000f-4434-8000-000f4346000f',
    '00000059-0000-4005-8000-000000590000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.68,
    TRUE
),
(
    '001e8821-001e-4882-8001-001e8821001e',
    '000f4346-000f-4434-8000-000f4346000f',
    '00000059-0000-4005-8000-000000590000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.33,
    TRUE
),
(
    '001e8822-001e-4882-8001-001e8822001e',
    '000f4346-000f-4434-8000-000f4346000f',
    '00000059-0000-4005-8000-000000590000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.45,
    TRUE
),
(
    '001e8823-001e-4882-8001-001e8823001e',
    '000f4346-000f-4434-8000-000f4346000f',
    '00000059-0000-4005-8000-000000590000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.90,
    TRUE
),
(
    '001e8824-001e-4882-8001-001e8824001e',
    '000f4347-000f-4434-8000-000f4347000f',
    '0000005a-0000-4005-8000-0000005a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.12,
    TRUE
),
(
    '001e8825-001e-4882-8001-001e8825001e',
    '000f4347-000f-4434-8000-000f4347000f',
    '0000005a-0000-4005-8000-0000005a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.88,
    TRUE
),
(
    '001e8826-001e-4882-8001-001e8826001e',
    '000f4347-000f-4434-8000-000f4347000f',
    '0000005a-0000-4005-8000-0000005a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.77,
    TRUE
),
(
    '001e8827-001e-4882-8001-001e8827001e',
    '000f4347-000f-4434-8000-000f4347000f',
    '0000005a-0000-4005-8000-0000005a0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.88,
    TRUE
),
(
    '001e8828-001e-4882-8001-001e8828001e',
    '000f4348-000f-4434-8000-000f4348000f',
    '0000005a-0000-4005-8000-0000005a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.42,
    TRUE
),
(
    '001e8829-001e-4882-8001-001e8829001e',
    '000f4348-000f-4434-8000-000f4348000f',
    '0000005a-0000-4005-8000-0000005a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.62,
    TRUE
),
(
    '001e882a-001e-4882-8001-001e882a001e',
    '000f4348-000f-4434-8000-000f4348000f',
    '0000005a-0000-4005-8000-0000005a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.38,
    TRUE
),
(
    '001e882b-001e-4882-8001-001e882b001e',
    '000f4348-000f-4434-8000-000f4348000f',
    '0000005a-0000-4005-8000-0000005a0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.57,
    TRUE
),
(
    '001e882c-001e-4882-8001-001e882c001e',
    '000f4349-000f-4434-8000-000f4349000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.04,
    TRUE
),
(
    '001e882d-001e-4882-8001-001e882d001e',
    '000f4349-000f-4434-8000-000f4349000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.18,
    TRUE
),
(
    '001e882e-001e-4882-8001-001e882e001e',
    '000f4349-000f-4434-8000-000f4349000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.83,
    TRUE
),
(
    '001e882f-001e-4882-8001-001e882f001e',
    '000f4349-000f-4434-8000-000f4349000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.49,
    TRUE
),
(
    '001e8830-001e-4883-8001-001e8830001e',
    '000f434a-000f-4434-8000-000f434a000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.25,
    TRUE
),
(
    '001e8831-001e-4883-8001-001e8831001e',
    '000f434a-000f-4434-8000-000f434a000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.35,
    TRUE
),
(
    '001e8832-001e-4883-8001-001e8832001e',
    '000f434a-000f-4434-8000-000f434a000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.09,
    TRUE
),
(
    '001e8833-001e-4883-8001-001e8833001e',
    '000f434a-000f-4434-8000-000f434a000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.25,
    TRUE
),
(
    '001e8834-001e-4883-8001-001e8834001e',
    '000f434b-000f-4434-8000-000f434b000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.48,
    TRUE
),
(
    '001e8835-001e-4883-8001-001e8835001e',
    '000f434b-000f-4434-8000-000f434b000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.68,
    TRUE
),
(
    '001e8836-001e-4883-8001-001e8836001e',
    '000f434b-000f-4434-8000-000f434b000f',
    '0000005b-0000-4005-8000-0000005b0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.32,
    TRUE
),
(
    '001e8837-001e-4883-8001-001e8837001e',
    '000f434c-000f-4434-8000-000f434c000f',
    '0000005c-0000-4005-8000-0000005c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.31,
    TRUE
),
(
    '001e8838-001e-4883-8001-001e8838001e',
    '000f434c-000f-4434-8000-000f434c000f',
    '0000005c-0000-4005-8000-0000005c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.90,
    TRUE
),
(
    '001e8839-001e-4883-8001-001e8839001e',
    '000f434c-000f-4434-8000-000f434c000f',
    '0000005c-0000-4005-8000-0000005c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.76,
    TRUE
),
(
    '001e883a-001e-4883-8001-001e883a001e',
    '000f434d-000f-4434-8000-000f434d000f',
    '0000005c-0000-4005-8000-0000005c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.11,
    TRUE
),
(
    '001e883b-001e-4883-8001-001e883b001e',
    '000f434d-000f-4434-8000-000f434d000f',
    '0000005c-0000-4005-8000-0000005c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.38,
    TRUE
),
(
    '001e883c-001e-4883-8001-001e883c001e',
    '000f434d-000f-4434-8000-000f434d000f',
    '0000005c-0000-4005-8000-0000005c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.69,
    TRUE
),
(
    '001e883d-001e-4883-8001-001e883d001e',
    '000f434e-000f-4434-8000-000f434e000f',
    '0000005d-0000-4005-8000-0000005d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.60,
    TRUE
),
(
    '001e883e-001e-4883-8001-001e883e001e',
    '000f434e-000f-4434-8000-000f434e000f',
    '0000005d-0000-4005-8000-0000005d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.27,
    TRUE
),
(
    '001e883f-001e-4883-8001-001e883f001e',
    '000f434e-000f-4434-8000-000f434e000f',
    '0000005d-0000-4005-8000-0000005d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.70,
    TRUE
),
(
    '001e8840-001e-4884-8001-001e8840001e',
    '000f434f-000f-4434-8000-000f434f000f',
    '0000005d-0000-4005-8000-0000005d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.53,
    TRUE
),
(
    '001e8841-001e-4884-8001-001e8841001e',
    '000f434f-000f-4434-8000-000f434f000f',
    '0000005d-0000-4005-8000-0000005d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.92,
    TRUE
),
(
    '001e8842-001e-4884-8001-001e8842001e',
    '000f434f-000f-4434-8000-000f434f000f',
    '0000005d-0000-4005-8000-0000005d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.73,
    TRUE
),
(
    '001e8843-001e-4884-8001-001e8843001e',
    '000f434f-000f-4434-8000-000f434f000f',
    '0000005d-0000-4005-8000-0000005d0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.66,
    TRUE
),
(
    '001e8844-001e-4884-8001-001e8844001e',
    '000f4350-000f-4435-8000-000f4350000f',
    '0000005e-0000-4005-8000-0000005e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.33,
    TRUE
),
(
    '001e8845-001e-4884-8001-001e8845001e',
    '000f4350-000f-4435-8000-000f4350000f',
    '0000005e-0000-4005-8000-0000005e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.38,
    TRUE
),
(
    '001e8846-001e-4884-8001-001e8846001e',
    '000f4350-000f-4435-8000-000f4350000f',
    '0000005e-0000-4005-8000-0000005e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.63,
    TRUE
),
(
    '001e8847-001e-4884-8001-001e8847001e',
    '000f4350-000f-4435-8000-000f4350000f',
    '0000005e-0000-4005-8000-0000005e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.32,
    TRUE
),
(
    '001e8848-001e-4884-8001-001e8848001e',
    '000f4351-000f-4435-8000-000f4351000f',
    '0000005e-0000-4005-8000-0000005e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.20,
    TRUE
),
(
    '001e8849-001e-4884-8001-001e8849001e',
    '000f4351-000f-4435-8000-000f4351000f',
    '0000005e-0000-4005-8000-0000005e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.22,
    TRUE
),
(
    '001e884a-001e-4884-8001-001e884a001e',
    '000f4351-000f-4435-8000-000f4351000f',
    '0000005e-0000-4005-8000-0000005e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.23,
    TRUE
),
(
    '001e884b-001e-4884-8001-001e884b001e',
    '000f4352-000f-4435-8000-000f4352000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.23,
    TRUE
),
(
    '001e884c-001e-4884-8001-001e884c001e',
    '000f4352-000f-4435-8000-000f4352000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.75,
    TRUE
),
(
    '001e884d-001e-4884-8001-001e884d001e',
    '000f4352-000f-4435-8000-000f4352000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.05,
    TRUE
),
(
    '001e884e-001e-4884-8001-001e884e001e',
    '000f4353-000f-4435-8000-000f4353000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.82,
    TRUE
),
(
    '001e884f-001e-4884-8001-001e884f001e',
    '000f4353-000f-4435-8000-000f4353000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.35,
    TRUE
),
(
    '001e8850-001e-4885-8001-001e8850001e',
    '000f4353-000f-4435-8000-000f4353000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Risotto',
    'Creamy Italian rice dish',
    13.20,
    TRUE
),
(
    '001e8851-001e-4885-8001-001e8851001e',
    '000f4354-000f-4435-8000-000f4354000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.21,
    TRUE
),
(
    '001e8852-001e-4885-8001-001e8852001e',
    '000f4354-000f-4435-8000-000f4354000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.51,
    TRUE
),
(
    '001e8853-001e-4885-8001-001e8853001e',
    '000f4354-000f-4435-8000-000f4354000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.50,
    TRUE
),
(
    '001e8854-001e-4885-8001-001e8854001e',
    '000f4354-000f-4435-8000-000f4354000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.46,
    TRUE
),
(
    '001e8855-001e-4885-8001-001e8855001e',
    '000f4355-000f-4435-8000-000f4355000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.96,
    TRUE
),
(
    '001e8856-001e-4885-8001-001e8856001e',
    '000f4355-000f-4435-8000-000f4355000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.22,
    TRUE
),
(
    '001e8857-001e-4885-8001-001e8857001e',
    '000f4355-000f-4435-8000-000f4355000f',
    '0000005f-0000-4005-8000-0000005f0000',
    'Cheesecake',
    'New York style cheesecake',
    7.31,
    TRUE
),
(
    '001e8858-001e-4885-8001-001e8858001e',
    '000f4356-000f-4435-8000-000f4356000f',
    '00000060-0000-4006-8000-000000600000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.14,
    TRUE
),
(
    '001e8859-001e-4885-8001-001e8859001e',
    '000f4356-000f-4435-8000-000f4356000f',
    '00000060-0000-4006-8000-000000600000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.23,
    TRUE
),
(
    '001e885a-001e-4885-8001-001e885a001e',
    '000f4356-000f-4435-8000-000f4356000f',
    '00000060-0000-4006-8000-000000600000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.01,
    TRUE
),
(
    '001e885b-001e-4885-8001-001e885b001e',
    '000f4357-000f-4435-8000-000f4357000f',
    '00000060-0000-4006-8000-000000600000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.11,
    TRUE
),
(
    '001e885c-001e-4885-8001-001e885c001e',
    '000f4357-000f-4435-8000-000f4357000f',
    '00000060-0000-4006-8000-000000600000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.10,
    TRUE
),
(
    '001e885d-001e-4885-8001-001e885d001e',
    '000f4357-000f-4435-8000-000f4357000f',
    '00000060-0000-4006-8000-000000600000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.85,
    TRUE
),
(
    '001e885e-001e-4885-8001-001e885e001e',
    '000f4358-000f-4435-8000-000f4358000f',
    '00000060-0000-4006-8000-000000600000',
    'French Fries',
    'Crispy golden fries',
    4.02,
    TRUE
),
(
    '001e885f-001e-4885-8001-001e885f001e',
    '000f4358-000f-4435-8000-000f4358000f',
    '00000060-0000-4006-8000-000000600000',
    'Onion Rings',
    'Battered and fried onion rings',
    5.80,
    TRUE
),
(
    '001e8860-001e-4886-8001-001e8860001e',
    '000f4358-000f-4435-8000-000f4358000f',
    '00000060-0000-4006-8000-000000600000',
    'Coleslaw',
    'Fresh cabbage salad',
    3.51,
    TRUE
),
(
    '001e8861-001e-4886-8001-001e8861001e',
    '000f4359-000f-4435-8000-000f4359000f',
    '00000061-0000-4006-8000-000000610000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.30,
    TRUE
),
(
    '001e8862-001e-4886-8001-001e8862001e',
    '000f4359-000f-4435-8000-000f4359000f',
    '00000061-0000-4006-8000-000000610000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.03,
    TRUE
),
(
    '001e8863-001e-4886-8001-001e8863001e',
    '000f4359-000f-4435-8000-000f4359000f',
    '00000061-0000-4006-8000-000000610000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.65,
    TRUE
),
(
    '001e8864-001e-4886-8001-001e8864001e',
    '000f435a-000f-4435-8000-000f435a000f',
    '00000061-0000-4006-8000-000000610000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.54,
    TRUE
),
(
    '001e8865-001e-4886-8001-001e8865001e',
    '000f435a-000f-4435-8000-000f435a000f',
    '00000061-0000-4006-8000-000000610000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.94,
    TRUE
),
(
    '001e8866-001e-4886-8001-001e8866001e',
    '000f435a-000f-4435-8000-000f435a000f',
    '00000061-0000-4006-8000-000000610000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.27,
    TRUE
),
(
    '001e8867-001e-4886-8001-001e8867001e',
    '000f435a-000f-4435-8000-000f435a000f',
    '00000061-0000-4006-8000-000000610000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.90,
    TRUE
),
(
    '001e8868-001e-4886-8001-001e8868001e',
    '000f435b-000f-4435-8000-000f435b000f',
    '00000062-0000-4006-8000-000000620000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.42,
    TRUE
),
(
    '001e8869-001e-4886-8001-001e8869001e',
    '000f435b-000f-4435-8000-000f435b000f',
    '00000062-0000-4006-8000-000000620000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.99,
    TRUE
),
(
    '001e886a-001e-4886-8001-001e886a001e',
    '000f435b-000f-4435-8000-000f435b000f',
    '00000062-0000-4006-8000-000000620000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.64,
    TRUE
),
(
    '001e886b-001e-4886-8001-001e886b001e',
    '000f435b-000f-4435-8000-000f435b000f',
    '00000062-0000-4006-8000-000000620000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.98,
    TRUE
),
(
    '001e886c-001e-4886-8001-001e886c001e',
    '000f435c-000f-4435-8000-000f435c000f',
    '00000062-0000-4006-8000-000000620000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.65,
    TRUE
),
(
    '001e886d-001e-4886-8001-001e886d001e',
    '000f435c-000f-4435-8000-000f435c000f',
    '00000062-0000-4006-8000-000000620000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.82,
    TRUE
),
(
    '001e886e-001e-4886-8001-001e886e001e',
    '000f435c-000f-4435-8000-000f435c000f',
    '00000062-0000-4006-8000-000000620000',
    'Risotto',
    'Creamy Italian rice dish',
    12.88,
    TRUE
),
(
    '001e886f-001e-4886-8001-001e886f001e',
    '000f435d-000f-4435-8000-000f435d000f',
    '00000062-0000-4006-8000-000000620000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.04,
    TRUE
),
(
    '001e8870-001e-4887-8001-001e8870001e',
    '000f435d-000f-4435-8000-000f435d000f',
    '00000062-0000-4006-8000-000000620000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.73,
    TRUE
),
(
    '001e8871-001e-4887-8001-001e8871001e',
    '000f435d-000f-4435-8000-000f435d000f',
    '00000062-0000-4006-8000-000000620000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.44,
    TRUE
),
(
    '001e8872-001e-4887-8001-001e8872001e',
    '000f435e-000f-4435-8000-000f435e000f',
    '00000063-0000-4006-8000-000000630000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.75,
    TRUE
),
(
    '001e8873-001e-4887-8001-001e8873001e',
    '000f435e-000f-4435-8000-000f435e000f',
    '00000063-0000-4006-8000-000000630000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.49,
    TRUE
),
(
    '001e8874-001e-4887-8001-001e8874001e',
    '000f435e-000f-4435-8000-000f435e000f',
    '00000063-0000-4006-8000-000000630000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.12,
    TRUE
),
(
    '001e8875-001e-4887-8001-001e8875001e',
    '000f435e-000f-4435-8000-000f435e000f',
    '00000063-0000-4006-8000-000000630000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.15,
    TRUE
),
(
    '001e8876-001e-4887-8001-001e8876001e',
    '000f435f-000f-4435-8000-000f435f000f',
    '00000063-0000-4006-8000-000000630000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.90,
    TRUE
),
(
    '001e8877-001e-4887-8001-001e8877001e',
    '000f435f-000f-4435-8000-000f435f000f',
    '00000063-0000-4006-8000-000000630000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.62,
    TRUE
),
(
    '001e8878-001e-4887-8001-001e8878001e',
    '000f435f-000f-4435-8000-000f435f000f',
    '00000063-0000-4006-8000-000000630000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.77,
    TRUE
),
(
    '001e8879-001e-4887-8001-001e8879001e',
    '000f435f-000f-4435-8000-000f435f000f',
    '00000063-0000-4006-8000-000000630000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.16,
    TRUE
),
(
    '001e887a-001e-4887-8001-001e887a001e',
    '000f4360-000f-4436-8000-000f4360000f',
    '00000063-0000-4006-8000-000000630000',
    'French Fries',
    'Crispy golden fries',
    5.73,
    TRUE
),
(
    '001e887b-001e-4887-8001-001e887b001e',
    '000f4360-000f-4436-8000-000f4360000f',
    '00000063-0000-4006-8000-000000630000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.70,
    TRUE
),
(
    '001e887c-001e-4887-8001-001e887c001e',
    '000f4360-000f-4436-8000-000f4360000f',
    '00000063-0000-4006-8000-000000630000',
    'Coleslaw',
    'Fresh cabbage salad',
    3.15,
    TRUE
),
(
    '001e887d-001e-4887-8001-001e887d001e',
    '000f4361-000f-4436-8000-000f4361000f',
    '00000063-0000-4006-8000-000000630000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.94,
    TRUE
),
(
    '001e887e-001e-4887-8001-001e887e001e',
    '000f4361-000f-4436-8000-000f4361000f',
    '00000063-0000-4006-8000-000000630000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.28,
    TRUE
),
(
    '001e887f-001e-4887-8001-001e887f001e',
    '000f4361-000f-4436-8000-000f4361000f',
    '00000063-0000-4006-8000-000000630000',
    'Cheesecake',
    'New York style cheesecake',
    7.88,
    TRUE
),
(
    '001e8880-001e-4888-8001-001e8880001e',
    '000f4361-000f-4436-8000-000f4361000f',
    '00000063-0000-4006-8000-000000630000',
    'Tiramisu',
    'Classic Italian dessert',
    7.51,
    TRUE
),
(
    '001e8881-001e-4888-8001-001e8881001e',
    '000f4362-000f-4436-8000-000f4362000f',
    '00000064-0000-4006-8000-000000640000',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    12.45,
    TRUE
),
(
    '001e8882-001e-4888-8001-001e8882001e',
    '000f4362-000f-4436-8000-000f4362000f',
    '00000064-0000-4006-8000-000000640000',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    14.29,
    TRUE
),
(
    '001e8883-001e-4888-8001-001e8883001e',
    '000f4362-000f-4436-8000-000f4362000f',
    '00000064-0000-4006-8000-000000640000',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives',
    15.90,
    TRUE
),
(
    '001e8884-001e-4888-8001-001e8884001e',
    '000f4362-000f-4436-8000-000f4362000f',
    '00000064-0000-4006-8000-000000640000',
    'Hawaiian',
    'Ham, pineapple, mozzarella',
    14.39,
    TRUE
),
(
    '001e8885-001e-4888-8001-001e8885001e',
    '000f4362-000f-4436-8000-000f4362000f',
    '00000064-0000-4006-8000-000000640000',
    'Vegetarian',
    'Mixed vegetables, mozzarella',
    14.45,
    TRUE
),
(
    '001e8886-001e-4888-8001-001e8886001e',
    '000f4363-000f-4436-8000-000f4363000f',
    '00000064-0000-4006-8000-000000640000',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino',
    14.16,
    TRUE
),
(
    '001e8887-001e-4888-8001-001e8887001e',
    '000f4363-000f-4436-8000-000f4363000f',
    '00000064-0000-4006-8000-000000640000',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    12.49,
    TRUE
),
(
    '001e8888-001e-4888-8001-001e8888001e',
    '000f4363-000f-4436-8000-000f4363000f',
    '00000064-0000-4006-8000-000000640000',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream',
    14.19,
    TRUE
),
(
    '001e8889-001e-4888-8001-001e8889001e',
    '000f4364-000f-4436-8000-000f4364000f',
    '00000064-0000-4006-8000-000000640000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.13,
    TRUE
),
(
    '001e888a-001e-4888-8001-001e888a001e',
    '000f4364-000f-4436-8000-000f4364000f',
    '00000064-0000-4006-8000-000000640000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.98,
    TRUE
),
(
    '001e888b-001e-4888-8001-001e888b001e',
    '000f4364-000f-4436-8000-000f4364000f',
    '00000064-0000-4006-8000-000000640000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.03,
    TRUE
),
(
    '001e888c-001e-4888-8001-001e888c001e',
    '000f4365-000f-4436-8000-000f4365000f',
    '00000064-0000-4006-8000-000000640000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.87,
    TRUE
),
(
    '001e888d-001e-4888-8001-001e888d001e',
    '000f4365-000f-4436-8000-000f4365000f',
    '00000064-0000-4006-8000-000000640000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.64,
    TRUE
),
(
    '001e888e-001e-4888-8001-001e888e001e',
    '000f4365-000f-4436-8000-000f4365000f',
    '00000064-0000-4006-8000-000000640000',
    'Cheesecake',
    'New York style cheesecake',
    8.73,
    TRUE
),
(
    '001e888f-001e-4888-8001-001e888f001e',
    '000f4365-000f-4436-8000-000f4365000f',
    '00000064-0000-4006-8000-000000640000',
    'Tiramisu',
    'Classic Italian dessert',
    8.25,
    TRUE
),
(
    '001e8890-001e-4889-8001-001e8890001e',
    '000f4366-000f-4436-8000-000f4366000f',
    '00000065-0000-4006-8000-000000650000',
    'Har Gow',
    'Steamed shrimp dumplings',
    9.82,
    TRUE
),
(
    '001e8891-001e-4889-8001-001e8891001e',
    '000f4366-000f-4436-8000-000f4366000f',
    '00000065-0000-4006-8000-000000650000',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    8.92,
    TRUE
),
(
    '001e8892-001e-4889-8001-001e8892001e',
    '000f4366-000f-4436-8000-000f4366000f',
    '00000065-0000-4006-8000-000000650000',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    8.55,
    TRUE
),
(
    '001e8893-001e-4889-8001-001e8893001e',
    '000f4366-000f-4436-8000-000f4366000f',
    '00000065-0000-4006-8000-000000650000',
    'Spring Rolls',
    'Crispy vegetable spring rolls',
    7.74,
    TRUE
),
(
    '001e8894-001e-4889-8001-001e8894001e',
    '000f4367-000f-4436-8000-000f4367000f',
    '00000065-0000-4006-8000-000000650000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    14.28,
    TRUE
),
(
    '001e8895-001e-4889-8001-001e8895001e',
    '000f4367-000f-4436-8000-000f4367000f',
    '00000065-0000-4006-8000-000000650000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.79,
    TRUE
),
(
    '001e8896-001e-4889-8001-001e8896001e',
    '000f4367-000f-4436-8000-000f4367000f',
    '00000065-0000-4006-8000-000000650000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.60,
    TRUE
),
(
    '001e8897-001e-4889-8001-001e8897001e',
    '000f4367-000f-4436-8000-000f4367000f',
    '00000065-0000-4006-8000-000000650000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    11.55,
    TRUE
),
(
    '001e8898-001e-4889-8001-001e8898001e',
    '000f4368-000f-4436-8000-000f4368000f',
    '00000065-0000-4006-8000-000000650000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.86,
    TRUE
),
(
    '001e8899-001e-4889-8001-001e8899001e',
    '000f4368-000f-4436-8000-000f4368000f',
    '00000065-0000-4006-8000-000000650000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.99,
    TRUE
),
(
    '001e889a-001e-4889-8001-001e889a001e',
    '000f4368-000f-4436-8000-000f4368000f',
    '00000065-0000-4006-8000-000000650000',
    'Risotto',
    'Creamy Italian rice dish',
    12.55,
    TRUE
),
(
    '001e889b-001e-4889-8001-001e889b001e',
    '000f4369-000f-4436-8000-000f4369000f',
    '00000066-0000-4006-8000-000000660000',
    'Beef Tacos',
    'Seasoned ground beef with lettuce and cheese',
    9.51,
    TRUE
),
(
    '001e889c-001e-4889-8001-001e889c001e',
    '000f4369-000f-4436-8000-000f4369000f',
    '00000066-0000-4006-8000-000000660000',
    'Chicken Tacos',
    'Grilled chicken with salsa and avocado',
    10.36,
    TRUE
),
(
    '001e889d-001e-4889-8001-001e889d001e',
    '000f4369-000f-4436-8000-000f4369000f',
    '00000066-0000-4006-8000-000000660000',
    'Fish Tacos',
    'Battered fish with cabbage slaw',
    10.64,
    TRUE
),
(
    '001e889e-001e-4889-8001-001e889e001e',
    '000f436a-000f-4436-8000-000f436a000f',
    '00000066-0000-4006-8000-000000660000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.02,
    TRUE
),
(
    '001e889f-001e-4889-8001-001e889f001e',
    '000f436a-000f-4436-8000-000f436a000f',
    '00000066-0000-4006-8000-000000660000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.91,
    TRUE
),
(
    '001e88a0-001e-488a-8001-001e88a0001e',
    '000f436a-000f-4436-8000-000f436a000f',
    '00000066-0000-4006-8000-000000660000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.02,
    TRUE
),
(
    '001e88a1-001e-488a-8001-001e88a1001e',
    '000f436a-000f-4436-8000-000f436a000f',
    '00000066-0000-4006-8000-000000660000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.56,
    TRUE
),
(
    '001e88a2-001e-488a-8001-001e88a2001e',
    '000f436b-000f-4436-8000-000f436b000f',
    '00000066-0000-4006-8000-000000660000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.68,
    TRUE
),
(
    '001e88a3-001e-488a-8001-001e88a3001e',
    '000f436b-000f-4436-8000-000f436b000f',
    '00000066-0000-4006-8000-000000660000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.48,
    TRUE
),
(
    '001e88a4-001e-488a-8001-001e88a4001e',
    '000f436b-000f-4436-8000-000f436b000f',
    '00000066-0000-4006-8000-000000660000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.27,
    TRUE
),
(
    '001e88a5-001e-488a-8001-001e88a5001e',
    '000f436b-000f-4436-8000-000f436b000f',
    '00000066-0000-4006-8000-000000660000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.28,
    TRUE
),
(
    '001e88a6-001e-488a-8001-001e88a6001e',
    '000f436c-000f-4436-8000-000f436c000f',
    '00000066-0000-4006-8000-000000660000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.28,
    TRUE
),
(
    '001e88a7-001e-488a-8001-001e88a7001e',
    '000f436c-000f-4436-8000-000f436c000f',
    '00000066-0000-4006-8000-000000660000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.83,
    TRUE
),
(
    '001e88a8-001e-488a-8001-001e88a8001e',
    '000f436c-000f-4436-8000-000f436c000f',
    '00000066-0000-4006-8000-000000660000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.61,
    TRUE
),
(
    '001e88a9-001e-488a-8001-001e88a9001e',
    '000f436c-000f-4436-8000-000f436c000f',
    '00000066-0000-4006-8000-000000660000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.08,
    TRUE
),
(
    '001e88aa-001e-488a-8001-001e88aa001e',
    '000f436d-000f-4436-8000-000f436d000f',
    '00000067-0000-4006-8000-000000670000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    14.50,
    TRUE
),
(
    '001e88ab-001e-488a-8001-001e88ab001e',
    '000f436d-000f-4436-8000-000f436d000f',
    '00000067-0000-4006-8000-000000670000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.95,
    TRUE
),
(
    '001e88ac-001e-488a-8001-001e88ac001e',
    '000f436d-000f-4436-8000-000f436d000f',
    '00000067-0000-4006-8000-000000670000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    12.20,
    TRUE
),
(
    '001e88ad-001e-488a-8001-001e88ad001e',
    '000f436d-000f-4436-8000-000f436d000f',
    '00000067-0000-4006-8000-000000670000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    13.93,
    TRUE
),
(
    '001e88ae-001e-488a-8001-001e88ae001e',
    '000f436e-000f-4436-8000-000f436e000f',
    '00000067-0000-4006-8000-000000670000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.02,
    TRUE
),
(
    '001e88af-001e-488a-8001-001e88af001e',
    '000f436e-000f-4436-8000-000f436e000f',
    '00000067-0000-4006-8000-000000670000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.10,
    TRUE
),
(
    '001e88b0-001e-488b-8001-001e88b0001e',
    '000f436e-000f-4436-8000-000f436e000f',
    '00000067-0000-4006-8000-000000670000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.16,
    TRUE
),
(
    '001e88b1-001e-488b-8001-001e88b1001e',
    '000f436e-000f-4436-8000-000f436e000f',
    '00000067-0000-4006-8000-000000670000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.03,
    TRUE
),
(
    '001e88b2-001e-488b-8001-001e88b2001e',
    '000f436f-000f-4436-8000-000f436f000f',
    '00000067-0000-4006-8000-000000670000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.30,
    TRUE
),
(
    '001e88b3-001e-488b-8001-001e88b3001e',
    '000f436f-000f-4436-8000-000f436f000f',
    '00000067-0000-4006-8000-000000670000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.40,
    TRUE
),
(
    '001e88b4-001e-488b-8001-001e88b4001e',
    '000f436f-000f-4436-8000-000f436f000f',
    '00000067-0000-4006-8000-000000670000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.23,
    TRUE
),
(
    '001e88b5-001e-488b-8001-001e88b5001e',
    '000f4370-000f-4437-8000-000f4370000f',
    '00000067-0000-4006-8000-000000670000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.58,
    TRUE
),
(
    '001e88b6-001e-488b-8001-001e88b6001e',
    '000f4370-000f-4437-8000-000f4370000f',
    '00000067-0000-4006-8000-000000670000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.68,
    TRUE
),
(
    '001e88b7-001e-488b-8001-001e88b7001e',
    '000f4370-000f-4437-8000-000f4370000f',
    '00000067-0000-4006-8000-000000670000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.15,
    TRUE
),
(
    '001e88b8-001e-488b-8001-001e88b8001e',
    '000f4370-000f-4437-8000-000f4370000f',
    '00000067-0000-4006-8000-000000670000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.04,
    TRUE
),
(
    '001e88b9-001e-488b-8001-001e88b9001e',
    '000f4371-000f-4437-8000-000f4371000f',
    '00000068-0000-4006-8000-000000680000',
    'Salmon Roll',
    'Fresh salmon with rice and nori',
    8.28,
    TRUE
),
(
    '001e88ba-001e-488b-8001-001e88ba001e',
    '000f4371-000f-4437-8000-000f4371000f',
    '00000068-0000-4006-8000-000000680000',
    'Tuna Roll',
    'Premium tuna with rice and nori',
    10.92,
    TRUE
),
(
    '001e88bb-001e-488b-8001-001e88bb001e',
    '000f4371-000f-4437-8000-000f4371000f',
    '00000068-0000-4006-8000-000000680000',
    'California Roll',
    'Crab, avocado, and cucumber',
    7.82,
    TRUE
),
(
    '001e88bc-001e-488b-8001-001e88bc001e',
    '000f4372-000f-4437-8000-000f4372000f',
    '00000068-0000-4006-8000-000000680000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.04,
    TRUE
),
(
    '001e88bd-001e-488b-8001-001e88bd001e',
    '000f4372-000f-4437-8000-000f4372000f',
    '00000068-0000-4006-8000-000000680000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.91,
    TRUE
),
(
    '001e88be-001e-488b-8001-001e88be001e',
    '000f4372-000f-4437-8000-000f4372000f',
    '00000068-0000-4006-8000-000000680000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.90,
    TRUE
),
(
    '001e88bf-001e-488b-8001-001e88bf001e',
    '000f4373-000f-4437-8000-000f4373000f',
    '00000069-0000-4006-8000-000000690000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    13.15,
    TRUE
),
(
    '001e88c0-001e-488c-8001-001e88c0001e',
    '000f4373-000f-4437-8000-000f4373000f',
    '00000069-0000-4006-8000-000000690000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    16.32,
    TRUE
),
(
    '001e88c1-001e-488c-8001-001e88c1001e',
    '000f4373-000f-4437-8000-000f4373000f',
    '00000069-0000-4006-8000-000000690000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.45,
    TRUE
),
(
    '001e88c2-001e-488c-8001-001e88c2001e',
    '000f4373-000f-4437-8000-000f4373000f',
    '00000069-0000-4006-8000-000000690000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    14.22,
    TRUE
),
(
    '001e88c3-001e-488c-8001-001e88c3001e',
    '000f4374-000f-4437-8000-000f4374000f',
    '00000069-0000-4006-8000-000000690000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    14.76,
    TRUE
),
(
    '001e88c4-001e-488c-8001-001e88c4001e',
    '000f4374-000f-4437-8000-000f4374000f',
    '00000069-0000-4006-8000-000000690000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.15,
    TRUE
),
(
    '001e88c5-001e-488c-8001-001e88c5001e',
    '000f4374-000f-4437-8000-000f4374000f',
    '00000069-0000-4006-8000-000000690000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    10.77,
    TRUE
),
(
    '001e88c6-001e-488c-8001-001e88c6001e',
    '000f4375-000f-4437-8000-000f4375000f',
    '00000069-0000-4006-8000-000000690000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.08,
    TRUE
),
(
    '001e88c7-001e-488c-8001-001e88c7001e',
    '000f4375-000f-4437-8000-000f4375000f',
    '00000069-0000-4006-8000-000000690000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.89,
    TRUE
),
(
    '001e88c8-001e-488c-8001-001e88c8001e',
    '000f4375-000f-4437-8000-000f4375000f',
    '00000069-0000-4006-8000-000000690000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.26,
    TRUE
),
(
    '001e88c9-001e-488c-8001-001e88c9001e',
    '000f4375-000f-4437-8000-000f4375000f',
    '00000069-0000-4006-8000-000000690000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.12,
    TRUE
),
(
    '001e88ca-001e-488c-8001-001e88ca001e',
    '000f4376-000f-4437-8000-000f4376000f',
    '0000006a-0000-4006-8000-0000006a0000',
    'Classic Burger',
    'Beef patty with lettuce, tomato, onion',
    11.00,
    TRUE
),
(
    '001e88cb-001e-488c-8001-001e88cb001e',
    '000f4376-000f-4437-8000-000f4376000f',
    '0000006a-0000-4006-8000-0000006a0000',
    'Cheeseburger',
    'Beef patty with cheese and special sauce',
    11.29,
    TRUE
),
(
    '001e88cc-001e-488c-8001-001e88cc001e',
    '000f4376-000f-4437-8000-000f4376000f',
    '0000006a-0000-4006-8000-0000006a0000',
    'Chicken Burger',
    'Grilled chicken breast with fixings',
    9.51,
    TRUE
),
(
    '001e88cd-001e-488c-8001-001e88cd001e',
    '000f4377-000f-4437-8000-000f4377000f',
    '0000006a-0000-4006-8000-0000006a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.30,
    TRUE
),
(
    '001e88ce-001e-488c-8001-001e88ce001e',
    '000f4377-000f-4437-8000-000f4377000f',
    '0000006a-0000-4006-8000-0000006a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.34,
    TRUE
),
(
    '001e88cf-001e-488c-8001-001e88cf001e',
    '000f4377-000f-4437-8000-000f4377000f',
    '0000006a-0000-4006-8000-0000006a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.87,
    TRUE
),
(
    '001e88d0-001e-488d-8001-001e88d0001e',
    '000f4378-000f-4437-8000-000f4378000f',
    '0000006b-0000-4006-8000-0000006b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.41,
    TRUE
),
(
    '001e88d1-001e-488d-8001-001e88d1001e',
    '000f4378-000f-4437-8000-000f4378000f',
    '0000006b-0000-4006-8000-0000006b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.04,
    TRUE
),
(
    '001e88d2-001e-488d-8001-001e88d2001e',
    '000f4378-000f-4437-8000-000f4378000f',
    '0000006b-0000-4006-8000-0000006b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.88,
    TRUE
),
(
    '001e88d3-001e-488d-8001-001e88d3001e',
    '000f4378-000f-4437-8000-000f4378000f',
    '0000006b-0000-4006-8000-0000006b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.58,
    TRUE
),
(
    '001e88d4-001e-488d-8001-001e88d4001e',
    '000f4379-000f-4437-8000-000f4379000f',
    '0000006b-0000-4006-8000-0000006b0000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.90,
    TRUE
),
(
    '001e88d5-001e-488d-8001-001e88d5001e',
    '000f4379-000f-4437-8000-000f4379000f',
    '0000006b-0000-4006-8000-0000006b0000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.72,
    TRUE
),
(
    '001e88d6-001e-488d-8001-001e88d6001e',
    '000f4379-000f-4437-8000-000f4379000f',
    '0000006b-0000-4006-8000-0000006b0000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.62,
    TRUE
),
(
    '001e88d7-001e-488d-8001-001e88d7001e',
    '000f437a-000f-4437-8000-000f437a000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.72,
    TRUE
),
(
    '001e88d8-001e-488d-8001-001e88d8001e',
    '000f437a-000f-4437-8000-000f437a000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.87,
    TRUE
),
(
    '001e88d9-001e-488d-8001-001e88d9001e',
    '000f437a-000f-4437-8000-000f437a000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.68,
    TRUE
),
(
    '001e88da-001e-488d-8001-001e88da001e',
    '000f437b-000f-4437-8000-000f437b000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.20,
    TRUE
),
(
    '001e88db-001e-488d-8001-001e88db001e',
    '000f437b-000f-4437-8000-000f437b000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.67,
    TRUE
),
(
    '001e88dc-001e-488d-8001-001e88dc001e',
    '000f437b-000f-4437-8000-000f437b000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.19,
    TRUE
),
(
    '001e88dd-001e-488d-8001-001e88dd001e',
    '000f437b-000f-4437-8000-000f437b000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.22,
    TRUE
),
(
    '001e88de-001e-488d-8001-001e88de001e',
    '000f437c-000f-4437-8000-000f437c000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.64,
    TRUE
),
(
    '001e88df-001e-488d-8001-001e88df001e',
    '000f437c-000f-4437-8000-000f437c000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.21,
    TRUE
),
(
    '001e88e0-001e-488e-8001-001e88e0001e',
    '000f437c-000f-4437-8000-000f437c000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.68,
    TRUE
),
(
    '001e88e1-001e-488e-8001-001e88e1001e',
    '000f437d-000f-4437-8000-000f437d000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.58,
    TRUE
),
(
    '001e88e2-001e-488e-8001-001e88e2001e',
    '000f437d-000f-4437-8000-000f437d000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.29,
    TRUE
),
(
    '001e88e3-001e-488e-8001-001e88e3001e',
    '000f437d-000f-4437-8000-000f437d000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Cheesecake',
    'New York style cheesecake',
    8.24,
    TRUE
),
(
    '001e88e4-001e-488e-8001-001e88e4001e',
    '000f437d-000f-4437-8000-000f437d000f',
    '0000006c-0000-4006-8000-0000006c0000',
    'Tiramisu',
    'Classic Italian dessert',
    7.13,
    TRUE
),
(
    '001e88e5-001e-488e-8001-001e88e5001e',
    '000f437e-000f-4437-8000-000f437e000f',
    '0000006d-0000-4006-8000-0000006d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.71,
    TRUE
),
(
    '001e88e6-001e-488e-8001-001e88e6001e',
    '000f437e-000f-4437-8000-000f437e000f',
    '0000006d-0000-4006-8000-0000006d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.85,
    TRUE
),
(
    '001e88e7-001e-488e-8001-001e88e7001e',
    '000f437e-000f-4437-8000-000f437e000f',
    '0000006d-0000-4006-8000-0000006d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.89,
    TRUE
),
(
    '001e88e8-001e-488e-8001-001e88e8001e',
    '000f437f-000f-4437-8000-000f437f000f',
    '0000006d-0000-4006-8000-0000006d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.68,
    TRUE
),
(
    '001e88e9-001e-488e-8001-001e88e9001e',
    '000f437f-000f-4437-8000-000f437f000f',
    '0000006d-0000-4006-8000-0000006d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.93,
    TRUE
),
(
    '001e88ea-001e-488e-8001-001e88ea001e',
    '000f437f-000f-4437-8000-000f437f000f',
    '0000006d-0000-4006-8000-0000006d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.85,
    TRUE
),
(
    '001e88eb-001e-488e-8001-001e88eb001e',
    '000f437f-000f-4437-8000-000f437f000f',
    '0000006d-0000-4006-8000-0000006d0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.93,
    TRUE
),
(
    '001e88ec-001e-488e-8001-001e88ec001e',
    '000f4380-000f-4438-8000-000f4380000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.71,
    TRUE
),
(
    '001e88ed-001e-488e-8001-001e88ed001e',
    '000f4380-000f-4438-8000-000f4380000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.38,
    TRUE
),
(
    '001e88ee-001e-488e-8001-001e88ee001e',
    '000f4380-000f-4438-8000-000f4380000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.96,
    TRUE
),
(
    '001e88ef-001e-488e-8001-001e88ef001e',
    '000f4380-000f-4438-8000-000f4380000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.70,
    TRUE
),
(
    '001e88f0-001e-488f-8001-001e88f0001e',
    '000f4381-000f-4438-8000-000f4381000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.61,
    TRUE
),
(
    '001e88f1-001e-488f-8001-001e88f1001e',
    '000f4381-000f-4438-8000-000f4381000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.56,
    TRUE
),
(
    '001e88f2-001e-488f-8001-001e88f2001e',
    '000f4381-000f-4438-8000-000f4381000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.88,
    TRUE
),
(
    '001e88f3-001e-488f-8001-001e88f3001e',
    '000f4381-000f-4438-8000-000f4381000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.20,
    TRUE
),
(
    '001e88f4-001e-488f-8001-001e88f4001e',
    '000f4382-000f-4438-8000-000f4382000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.86,
    TRUE
),
(
    '001e88f5-001e-488f-8001-001e88f5001e',
    '000f4382-000f-4438-8000-000f4382000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.32,
    TRUE
),
(
    '001e88f6-001e-488f-8001-001e88f6001e',
    '000f4382-000f-4438-8000-000f4382000f',
    '0000006e-0000-4006-8000-0000006e0000',
    'Risotto',
    'Creamy Italian rice dish',
    13.05,
    TRUE
),
(
    '001e88f7-001e-488f-8001-001e88f7001e',
    '000f4383-000f-4438-8000-000f4383000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.40,
    TRUE
),
(
    '001e88f8-001e-488f-8001-001e88f8001e',
    '000f4383-000f-4438-8000-000f4383000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.68,
    TRUE
),
(
    '001e88f9-001e-488f-8001-001e88f9001e',
    '000f4383-000f-4438-8000-000f4383000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.88,
    TRUE
),
(
    '001e88fa-001e-488f-8001-001e88fa001e',
    '000f4383-000f-4438-8000-000f4383000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.16,
    TRUE
),
(
    '001e88fb-001e-488f-8001-001e88fb001e',
    '000f4384-000f-4438-8000-000f4384000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.97,
    TRUE
),
(
    '001e88fc-001e-488f-8001-001e88fc001e',
    '000f4384-000f-4438-8000-000f4384000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.13,
    TRUE
),
(
    '001e88fd-001e-488f-8001-001e88fd001e',
    '000f4384-000f-4438-8000-000f4384000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.37,
    TRUE
),
(
    '001e88fe-001e-488f-8001-001e88fe001e',
    '000f4385-000f-4438-8000-000f4385000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.26,
    TRUE
),
(
    '001e88ff-001e-488f-8001-001e88ff001e',
    '000f4385-000f-4438-8000-000f4385000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.99,
    TRUE
),
(
    '001e8900-001e-4890-8001-001e8900001e',
    '000f4385-000f-4438-8000-000f4385000f',
    '0000006f-0000-4006-8000-0000006f0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.31,
    TRUE
),
(
    '001e8901-001e-4890-8001-001e8901001e',
    '000f4386-000f-4438-8000-000f4386000f',
    '00000070-0000-4007-8000-000000700000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.86,
    TRUE
),
(
    '001e8902-001e-4890-8001-001e8902001e',
    '000f4386-000f-4438-8000-000f4386000f',
    '00000070-0000-4007-8000-000000700000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.46,
    TRUE
),
(
    '001e8903-001e-4890-8001-001e8903001e',
    '000f4386-000f-4438-8000-000f4386000f',
    '00000070-0000-4007-8000-000000700000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.70,
    TRUE
),
(
    '001e8904-001e-4890-8001-001e8904001e',
    '000f4386-000f-4438-8000-000f4386000f',
    '00000070-0000-4007-8000-000000700000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.70,
    TRUE
),
(
    '001e8905-001e-4890-8001-001e8905001e',
    '000f4387-000f-4438-8000-000f4387000f',
    '00000070-0000-4007-8000-000000700000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.24,
    TRUE
),
(
    '001e8906-001e-4890-8001-001e8906001e',
    '000f4387-000f-4438-8000-000f4387000f',
    '00000070-0000-4007-8000-000000700000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.34,
    TRUE
),
(
    '001e8907-001e-4890-8001-001e8907001e',
    '000f4387-000f-4438-8000-000f4387000f',
    '00000070-0000-4007-8000-000000700000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.34,
    TRUE
),
(
    '001e8908-001e-4890-8001-001e8908001e',
    '000f4388-000f-4438-8000-000f4388000f',
    '00000071-0000-4007-8000-000000710000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.23,
    TRUE
),
(
    '001e8909-001e-4890-8001-001e8909001e',
    '000f4388-000f-4438-8000-000f4388000f',
    '00000071-0000-4007-8000-000000710000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.61,
    TRUE
),
(
    '001e890a-001e-4890-8001-001e890a001e',
    '000f4388-000f-4438-8000-000f4388000f',
    '00000071-0000-4007-8000-000000710000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.64,
    TRUE
),
(
    '001e890b-001e-4890-8001-001e890b001e',
    '000f4388-000f-4438-8000-000f4388000f',
    '00000071-0000-4007-8000-000000710000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.93,
    TRUE
),
(
    '001e890c-001e-4890-8001-001e890c001e',
    '000f4389-000f-4438-8000-000f4389000f',
    '00000071-0000-4007-8000-000000710000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.53,
    TRUE
),
(
    '001e890d-001e-4890-8001-001e890d001e',
    '000f4389-000f-4438-8000-000f4389000f',
    '00000071-0000-4007-8000-000000710000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.89,
    TRUE
),
(
    '001e890e-001e-4890-8001-001e890e001e',
    '000f4389-000f-4438-8000-000f4389000f',
    '00000071-0000-4007-8000-000000710000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.23,
    TRUE
),
(
    '001e890f-001e-4890-8001-001e890f001e',
    '000f438a-000f-4438-8000-000f438a000f',
    '00000071-0000-4007-8000-000000710000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.45,
    TRUE
),
(
    '001e8910-001e-4891-8001-001e8910001e',
    '000f438a-000f-4438-8000-000f438a000f',
    '00000071-0000-4007-8000-000000710000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.68,
    TRUE
),
(
    '001e8911-001e-4891-8001-001e8911001e',
    '000f438a-000f-4438-8000-000f438a000f',
    '00000071-0000-4007-8000-000000710000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.39,
    TRUE
),
(
    '001e8912-001e-4891-8001-001e8912001e',
    '000f438a-000f-4438-8000-000f438a000f',
    '00000071-0000-4007-8000-000000710000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.93,
    TRUE
),
(
    '001e8913-001e-4891-8001-001e8913001e',
    '000f438b-000f-4438-8000-000f438b000f',
    '00000071-0000-4007-8000-000000710000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.55,
    TRUE
),
(
    '001e8914-001e-4891-8001-001e8914001e',
    '000f438b-000f-4438-8000-000f438b000f',
    '00000071-0000-4007-8000-000000710000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.28,
    TRUE
),
(
    '001e8915-001e-4891-8001-001e8915001e',
    '000f438b-000f-4438-8000-000f438b000f',
    '00000071-0000-4007-8000-000000710000',
    'Cheesecake',
    'New York style cheesecake',
    8.59,
    TRUE
),
(
    '001e8916-001e-4891-8001-001e8916001e',
    '000f438c-000f-4438-8000-000f438c000f',
    '00000072-0000-4007-8000-000000720000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.12,
    TRUE
),
(
    '001e8917-001e-4891-8001-001e8917001e',
    '000f438c-000f-4438-8000-000f438c000f',
    '00000072-0000-4007-8000-000000720000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.19,
    TRUE
),
(
    '001e8918-001e-4891-8001-001e8918001e',
    '000f438c-000f-4438-8000-000f438c000f',
    '00000072-0000-4007-8000-000000720000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.85,
    TRUE
),
(
    '001e8919-001e-4891-8001-001e8919001e',
    '000f438c-000f-4438-8000-000f438c000f',
    '00000072-0000-4007-8000-000000720000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.24,
    TRUE
),
(
    '001e891a-001e-4891-8001-001e891a001e',
    '000f438d-000f-4438-8000-000f438d000f',
    '00000072-0000-4007-8000-000000720000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.66,
    TRUE
),
(
    '001e891b-001e-4891-8001-001e891b001e',
    '000f438d-000f-4438-8000-000f438d000f',
    '00000072-0000-4007-8000-000000720000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.38,
    TRUE
),
(
    '001e891c-001e-4891-8001-001e891c001e',
    '000f438d-000f-4438-8000-000f438d000f',
    '00000072-0000-4007-8000-000000720000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.82,
    TRUE
),
(
    '001e891d-001e-4891-8001-001e891d001e',
    '000f438d-000f-4438-8000-000f438d000f',
    '00000072-0000-4007-8000-000000720000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.74,
    TRUE
),
(
    '001e891e-001e-4891-8001-001e891e001e',
    '000f438e-000f-4438-8000-000f438e000f',
    '00000073-0000-4007-8000-000000730000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.09,
    TRUE
),
(
    '001e891f-001e-4891-8001-001e891f001e',
    '000f438e-000f-4438-8000-000f438e000f',
    '00000073-0000-4007-8000-000000730000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.55,
    TRUE
),
(
    '001e8920-001e-4892-8001-001e8920001e',
    '000f438e-000f-4438-8000-000f438e000f',
    '00000073-0000-4007-8000-000000730000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.74,
    TRUE
),
(
    '001e8921-001e-4892-8001-001e8921001e',
    '000f438e-000f-4438-8000-000f438e000f',
    '00000073-0000-4007-8000-000000730000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.56,
    TRUE
),
(
    '001e8922-001e-4892-8001-001e8922001e',
    '000f438f-000f-4438-8000-000f438f000f',
    '00000073-0000-4007-8000-000000730000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.37,
    TRUE
),
(
    '001e8923-001e-4892-8001-001e8923001e',
    '000f438f-000f-4438-8000-000f438f000f',
    '00000073-0000-4007-8000-000000730000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.30,
    TRUE
),
(
    '001e8924-001e-4892-8001-001e8924001e',
    '000f438f-000f-4438-8000-000f438f000f',
    '00000073-0000-4007-8000-000000730000',
    'Risotto',
    'Creamy Italian rice dish',
    13.27,
    TRUE
),
(
    '001e8925-001e-4892-8001-001e8925001e',
    '000f4390-000f-4439-8000-000f4390000f',
    '00000074-0000-4007-8000-000000740000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.96,
    TRUE
),
(
    '001e8926-001e-4892-8001-001e8926001e',
    '000f4390-000f-4439-8000-000f4390000f',
    '00000074-0000-4007-8000-000000740000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.02,
    TRUE
),
(
    '001e8927-001e-4892-8001-001e8927001e',
    '000f4390-000f-4439-8000-000f4390000f',
    '00000074-0000-4007-8000-000000740000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.00,
    TRUE
),
(
    '001e8928-001e-4892-8001-001e8928001e',
    '000f4390-000f-4439-8000-000f4390000f',
    '00000074-0000-4007-8000-000000740000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.24,
    TRUE
),
(
    '001e8929-001e-4892-8001-001e8929001e',
    '000f4391-000f-4439-8000-000f4391000f',
    '00000074-0000-4007-8000-000000740000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.90,
    TRUE
),
(
    '001e892a-001e-4892-8001-001e892a001e',
    '000f4391-000f-4439-8000-000f4391000f',
    '00000074-0000-4007-8000-000000740000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.87,
    TRUE
),
(
    '001e892b-001e-4892-8001-001e892b001e',
    '000f4391-000f-4439-8000-000f4391000f',
    '00000074-0000-4007-8000-000000740000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.79,
    TRUE
),
(
    '001e892c-001e-4892-8001-001e892c001e',
    '000f4392-000f-4439-8000-000f4392000f',
    '00000074-0000-4007-8000-000000740000',
    'French Fries',
    'Crispy golden fries',
    4.06,
    TRUE
),
(
    '001e892d-001e-4892-8001-001e892d001e',
    '000f4392-000f-4439-8000-000f4392000f',
    '00000074-0000-4007-8000-000000740000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.37,
    TRUE
),
(
    '001e892e-001e-4892-8001-001e892e001e',
    '000f4392-000f-4439-8000-000f4392000f',
    '00000074-0000-4007-8000-000000740000',
    'Coleslaw',
    'Fresh cabbage salad',
    3.14,
    TRUE
),
(
    '001e892f-001e-4892-8001-001e892f001e',
    '000f4393-000f-4439-8000-000f4393000f',
    '00000075-0000-4007-8000-000000750000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.52,
    TRUE
),
(
    '001e8930-001e-4893-8001-001e8930001e',
    '000f4393-000f-4439-8000-000f4393000f',
    '00000075-0000-4007-8000-000000750000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.10,
    TRUE
),
(
    '001e8931-001e-4893-8001-001e8931001e',
    '000f4393-000f-4439-8000-000f4393000f',
    '00000075-0000-4007-8000-000000750000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.92,
    TRUE
),
(
    '001e8932-001e-4893-8001-001e8932001e',
    '000f4393-000f-4439-8000-000f4393000f',
    '00000075-0000-4007-8000-000000750000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.03,
    TRUE
),
(
    '001e8933-001e-4893-8001-001e8933001e',
    '000f4394-000f-4439-8000-000f4394000f',
    '00000075-0000-4007-8000-000000750000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.70,
    TRUE
),
(
    '001e8934-001e-4893-8001-001e8934001e',
    '000f4394-000f-4439-8000-000f4394000f',
    '00000075-0000-4007-8000-000000750000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.93,
    TRUE
),
(
    '001e8935-001e-4893-8001-001e8935001e',
    '000f4394-000f-4439-8000-000f4394000f',
    '00000075-0000-4007-8000-000000750000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.04,
    TRUE
),
(
    '001e8936-001e-4893-8001-001e8936001e',
    '000f4394-000f-4439-8000-000f4394000f',
    '00000075-0000-4007-8000-000000750000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.24,
    TRUE
),
(
    '001e8937-001e-4893-8001-001e8937001e',
    '000f4395-000f-4439-8000-000f4395000f',
    '00000076-0000-4007-8000-000000760000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.71,
    TRUE
),
(
    '001e8938-001e-4893-8001-001e8938001e',
    '000f4395-000f-4439-8000-000f4395000f',
    '00000076-0000-4007-8000-000000760000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.98,
    TRUE
),
(
    '001e8939-001e-4893-8001-001e8939001e',
    '000f4395-000f-4439-8000-000f4395000f',
    '00000076-0000-4007-8000-000000760000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.84,
    TRUE
),
(
    '001e893a-001e-4893-8001-001e893a001e',
    '000f4396-000f-4439-8000-000f4396000f',
    '00000076-0000-4007-8000-000000760000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.36,
    TRUE
),
(
    '001e893b-001e-4893-8001-001e893b001e',
    '000f4396-000f-4439-8000-000f4396000f',
    '00000076-0000-4007-8000-000000760000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.13,
    TRUE
),
(
    '001e893c-001e-4893-8001-001e893c001e',
    '000f4396-000f-4439-8000-000f4396000f',
    '00000076-0000-4007-8000-000000760000',
    'Risotto',
    'Creamy Italian rice dish',
    13.78,
    TRUE
),
(
    '001e893d-001e-4893-8001-001e893d001e',
    '000f4397-000f-4439-8000-000f4397000f',
    '00000076-0000-4007-8000-000000760000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.15,
    TRUE
),
(
    '001e893e-001e-4893-8001-001e893e001e',
    '000f4397-000f-4439-8000-000f4397000f',
    '00000076-0000-4007-8000-000000760000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.71,
    TRUE
),
(
    '001e893f-001e-4893-8001-001e893f001e',
    '000f4397-000f-4439-8000-000f4397000f',
    '00000076-0000-4007-8000-000000760000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.52,
    TRUE
),
(
    '001e8940-001e-4894-8001-001e8940001e',
    '000f4398-000f-4439-8000-000f4398000f',
    '00000076-0000-4007-8000-000000760000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.07,
    TRUE
),
(
    '001e8941-001e-4894-8001-001e8941001e',
    '000f4398-000f-4439-8000-000f4398000f',
    '00000076-0000-4007-8000-000000760000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.96,
    TRUE
),
(
    '001e8942-001e-4894-8001-001e8942001e',
    '000f4398-000f-4439-8000-000f4398000f',
    '00000076-0000-4007-8000-000000760000',
    'Cheesecake',
    'New York style cheesecake',
    7.28,
    TRUE
),
(
    '001e8943-001e-4894-8001-001e8943001e',
    '000f4398-000f-4439-8000-000f4398000f',
    '00000076-0000-4007-8000-000000760000',
    'Tiramisu',
    'Classic Italian dessert',
    7.18,
    TRUE
),
(
    '001e8944-001e-4894-8001-001e8944001e',
    '000f4399-000f-4439-8000-000f4399000f',
    '00000077-0000-4007-8000-000000770000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.79,
    TRUE
),
(
    '001e8945-001e-4894-8001-001e8945001e',
    '000f4399-000f-4439-8000-000f4399000f',
    '00000077-0000-4007-8000-000000770000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.31,
    TRUE
),
(
    '001e8946-001e-4894-8001-001e8946001e',
    '000f4399-000f-4439-8000-000f4399000f',
    '00000077-0000-4007-8000-000000770000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.00,
    TRUE
),
(
    '001e8947-001e-4894-8001-001e8947001e',
    '000f439a-000f-4439-8000-000f439a000f',
    '00000077-0000-4007-8000-000000770000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.92,
    TRUE
),
(
    '001e8948-001e-4894-8001-001e8948001e',
    '000f439a-000f-4439-8000-000f439a000f',
    '00000077-0000-4007-8000-000000770000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.71,
    TRUE
),
(
    '001e8949-001e-4894-8001-001e8949001e',
    '000f439a-000f-4439-8000-000f439a000f',
    '00000077-0000-4007-8000-000000770000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.02,
    TRUE
),
(
    '001e894a-001e-4894-8001-001e894a001e',
    '000f439a-000f-4439-8000-000f439a000f',
    '00000077-0000-4007-8000-000000770000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.18,
    TRUE
),
(
    '001e894b-001e-4894-8001-001e894b001e',
    '000f439b-000f-4439-8000-000f439b000f',
    '00000077-0000-4007-8000-000000770000',
    'French Fries',
    'Crispy golden fries',
    5.10,
    TRUE
),
(
    '001e894c-001e-4894-8001-001e894c001e',
    '000f439b-000f-4439-8000-000f439b000f',
    '00000077-0000-4007-8000-000000770000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.07,
    TRUE
),
(
    '001e894d-001e-4894-8001-001e894d001e',
    '000f439b-000f-4439-8000-000f439b000f',
    '00000077-0000-4007-8000-000000770000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.80,
    TRUE
),
(
    '001e894e-001e-4894-8001-001e894e001e',
    '000f439c-000f-4439-8000-000f439c000f',
    '00000077-0000-4007-8000-000000770000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.51,
    TRUE
),
(
    '001e894f-001e-4894-8001-001e894f001e',
    '000f439c-000f-4439-8000-000f439c000f',
    '00000077-0000-4007-8000-000000770000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.48,
    TRUE
),
(
    '001e8950-001e-4895-8001-001e8950001e',
    '000f439c-000f-4439-8000-000f439c000f',
    '00000077-0000-4007-8000-000000770000',
    'Cheesecake',
    'New York style cheesecake',
    8.14,
    TRUE
),
(
    '001e8951-001e-4895-8001-001e8951001e',
    '000f439d-000f-4439-8000-000f439d000f',
    '00000078-0000-4007-8000-000000780000',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    13.61,
    TRUE
),
(
    '001e8952-001e-4895-8001-001e8952001e',
    '000f439d-000f-4439-8000-000f439d000f',
    '00000078-0000-4007-8000-000000780000',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    15.89,
    TRUE
),
(
    '001e8953-001e-4895-8001-001e8953001e',
    '000f439d-000f-4439-8000-000f439d000f',
    '00000078-0000-4007-8000-000000780000',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives',
    16.25,
    TRUE
),
(
    '001e8954-001e-4895-8001-001e8954001e',
    '000f439d-000f-4439-8000-000f439d000f',
    '00000078-0000-4007-8000-000000780000',
    'Hawaiian',
    'Ham, pineapple, mozzarella',
    14.89,
    TRUE
),
(
    '001e8955-001e-4895-8001-001e8955001e',
    '000f439e-000f-4439-8000-000f439e000f',
    '00000078-0000-4007-8000-000000780000',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino',
    13.07,
    TRUE
),
(
    '001e8956-001e-4895-8001-001e8956001e',
    '000f439e-000f-4439-8000-000f439e000f',
    '00000078-0000-4007-8000-000000780000',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    11.98,
    TRUE
),
(
    '001e8957-001e-4895-8001-001e8957001e',
    '000f439e-000f-4439-8000-000f439e000f',
    '00000078-0000-4007-8000-000000780000',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream',
    13.69,
    TRUE
),
(
    '001e8958-001e-4895-8001-001e8958001e',
    '000f439f-000f-4439-8000-000f439f000f',
    '00000078-0000-4007-8000-000000780000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.01,
    TRUE
),
(
    '001e8959-001e-4895-8001-001e8959001e',
    '000f439f-000f-4439-8000-000f439f000f',
    '00000078-0000-4007-8000-000000780000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.90,
    TRUE
),
(
    '001e895a-001e-4895-8001-001e895a001e',
    '000f439f-000f-4439-8000-000f439f000f',
    '00000078-0000-4007-8000-000000780000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.49,
    TRUE
),
(
    '001e895b-001e-4895-8001-001e895b001e',
    '000f439f-000f-4439-8000-000f439f000f',
    '00000078-0000-4007-8000-000000780000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.88,
    TRUE
),
(
    '001e895c-001e-4895-8001-001e895c001e',
    '000f43a0-000f-443a-8000-000f43a0000f',
    '00000079-0000-4007-8000-000000790000',
    'Har Gow',
    'Steamed shrimp dumplings',
    9.71,
    TRUE
),
(
    '001e895d-001e-4895-8001-001e895d001e',
    '000f43a0-000f-443a-8000-000f43a0000f',
    '00000079-0000-4007-8000-000000790000',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    7.51,
    TRUE
),
(
    '001e895e-001e-4895-8001-001e895e001e',
    '000f43a0-000f-443a-8000-000f43a0000f',
    '00000079-0000-4007-8000-000000790000',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    8.31,
    TRUE
),
(
    '001e895f-001e-4895-8001-001e895f001e',
    '000f43a0-000f-443a-8000-000f43a0000f',
    '00000079-0000-4007-8000-000000790000',
    'Spring Rolls',
    'Crispy vegetable spring rolls',
    7.11,
    TRUE
),
(
    '001e8960-001e-4896-8001-001e8960001e',
    '000f43a1-000f-443a-8000-000f43a1000f',
    '00000079-0000-4007-8000-000000790000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.91,
    TRUE
),
(
    '001e8961-001e-4896-8001-001e8961001e',
    '000f43a1-000f-443a-8000-000f43a1000f',
    '00000079-0000-4007-8000-000000790000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.33,
    TRUE
),
(
    '001e8962-001e-4896-8001-001e8962001e',
    '000f43a1-000f-443a-8000-000f43a1000f',
    '00000079-0000-4007-8000-000000790000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    10.50,
    TRUE
),
(
    '001e8963-001e-4896-8001-001e8963001e',
    '000f43a2-000f-443a-8000-000f43a2000f',
    '00000079-0000-4007-8000-000000790000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.20,
    TRUE
),
(
    '001e8964-001e-4896-8001-001e8964001e',
    '000f43a2-000f-443a-8000-000f43a2000f',
    '00000079-0000-4007-8000-000000790000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.72,
    TRUE
),
(
    '001e8965-001e-4896-8001-001e8965001e',
    '000f43a2-000f-443a-8000-000f43a2000f',
    '00000079-0000-4007-8000-000000790000',
    'Risotto',
    'Creamy Italian rice dish',
    13.15,
    TRUE
),
(
    '001e8966-001e-4896-8001-001e8966001e',
    '000f43a3-000f-443a-8000-000f43a3000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Beef Tacos',
    'Seasoned ground beef with lettuce and cheese',
    9.06,
    TRUE
),
(
    '001e8967-001e-4896-8001-001e8967001e',
    '000f43a3-000f-443a-8000-000f43a3000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Chicken Tacos',
    'Grilled chicken with salsa and avocado',
    10.71,
    TRUE
),
(
    '001e8968-001e-4896-8001-001e8968001e',
    '000f43a3-000f-443a-8000-000f43a3000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Fish Tacos',
    'Battered fish with cabbage slaw',
    10.04,
    TRUE
),
(
    '001e8969-001e-4896-8001-001e8969001e',
    '000f43a3-000f-443a-8000-000f43a3000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Vegetarian Tacos',
    'Black beans, corn, and vegetables',
    9.08,
    TRUE
),
(
    '001e896a-001e-4896-8001-001e896a001e',
    '000f43a4-000f-443a-8000-000f43a4000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.64,
    TRUE
),
(
    '001e896b-001e-4896-8001-001e896b001e',
    '000f43a4-000f-443a-8000-000f43a4000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.59,
    TRUE
),
(
    '001e896c-001e-4896-8001-001e896c001e',
    '000f43a4-000f-443a-8000-000f43a4000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.20,
    TRUE
),
(
    '001e896d-001e-4896-8001-001e896d001e',
    '000f43a5-000f-443a-8000-000f43a5000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.62,
    TRUE
),
(
    '001e896e-001e-4896-8001-001e896e001e',
    '000f43a5-000f-443a-8000-000f43a5000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.92,
    TRUE
),
(
    '001e896f-001e-4896-8001-001e896f001e',
    '000f43a5-000f-443a-8000-000f43a5000f',
    '0000007a-0000-4007-8000-0000007a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.98,
    TRUE
),
(
    '001e8970-001e-4897-8001-001e8970001e',
    '000f43a6-000f-443a-8000-000f43a6000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    14.21,
    TRUE
),
(
    '001e8971-001e-4897-8001-001e8971001e',
    '000f43a6-000f-443a-8000-000f43a6000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.45,
    TRUE
),
(
    '001e8972-001e-4897-8001-001e8972001e',
    '000f43a6-000f-443a-8000-000f43a6000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.95,
    TRUE
),
(
    '001e8973-001e-4897-8001-001e8973001e',
    '000f43a6-000f-443a-8000-000f43a6000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    13.55,
    TRUE
),
(
    '001e8974-001e-4897-8001-001e8974001e',
    '000f43a7-000f-443a-8000-000f43a7000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.23,
    TRUE
),
(
    '001e8975-001e-4897-8001-001e8975001e',
    '000f43a7-000f-443a-8000-000f43a7000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.47,
    TRUE
),
(
    '001e8976-001e-4897-8001-001e8976001e',
    '000f43a7-000f-443a-8000-000f43a7000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.52,
    TRUE
),
(
    '001e8977-001e-4897-8001-001e8977001e',
    '000f43a7-000f-443a-8000-000f43a7000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.13,
    TRUE
),
(
    '001e8978-001e-4897-8001-001e8978001e',
    '000f43a8-000f-443a-8000-000f43a8000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.35,
    TRUE
),
(
    '001e8979-001e-4897-8001-001e8979001e',
    '000f43a8-000f-443a-8000-000f43a8000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.04,
    TRUE
),
(
    '001e897a-001e-4897-8001-001e897a001e',
    '000f43a8-000f-443a-8000-000f43a8000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.90,
    TRUE
),
(
    '001e897b-001e-4897-8001-001e897b001e',
    '000f43a8-000f-443a-8000-000f43a8000f',
    '0000007b-0000-4007-8000-0000007b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.28,
    TRUE
),
(
    '001e897c-001e-4897-8001-001e897c001e',
    '000f43a9-000f-443a-8000-000f43a9000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Salmon Roll',
    'Fresh salmon with rice and nori',
    8.08,
    TRUE
),
(
    '001e897d-001e-4897-8001-001e897d001e',
    '000f43a9-000f-443a-8000-000f43a9000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Tuna Roll',
    'Premium tuna with rice and nori',
    10.99,
    TRUE
),
(
    '001e897e-001e-4897-8001-001e897e001e',
    '000f43a9-000f-443a-8000-000f43a9000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'California Roll',
    'Crab, avocado, and cucumber',
    7.38,
    TRUE
),
(
    '001e897f-001e-4897-8001-001e897f001e',
    '000f43a9-000f-443a-8000-000f43a9000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Dragon Roll',
    'Eel, cucumber, and avocado',
    13.65,
    TRUE
),
(
    '001e8980-001e-4898-8001-001e8980001e',
    '000f43aa-000f-443a-8000-000f43aa000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.28,
    TRUE
),
(
    '001e8981-001e-4898-8001-001e8981001e',
    '000f43aa-000f-443a-8000-000f43aa000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.10,
    TRUE
),
(
    '001e8982-001e-4898-8001-001e8982001e',
    '000f43aa-000f-443a-8000-000f43aa000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.38,
    TRUE
),
(
    '001e8983-001e-4898-8001-001e8983001e',
    '000f43aa-000f-443a-8000-000f43aa000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.49,
    TRUE
),
(
    '001e8984-001e-4898-8001-001e8984001e',
    '000f43ab-000f-443a-8000-000f43ab000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.07,
    TRUE
),
(
    '001e8985-001e-4898-8001-001e8985001e',
    '000f43ab-000f-443a-8000-000f43ab000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.31,
    TRUE
),
(
    '001e8986-001e-4898-8001-001e8986001e',
    '000f43ab-000f-443a-8000-000f43ab000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.68,
    TRUE
),
(
    '001e8987-001e-4898-8001-001e8987001e',
    '000f43ac-000f-443a-8000-000f43ac000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.61,
    TRUE
),
(
    '001e8988-001e-4898-8001-001e8988001e',
    '000f43ac-000f-443a-8000-000f43ac000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.78,
    TRUE
),
(
    '001e8989-001e-4898-8001-001e8989001e',
    '000f43ac-000f-443a-8000-000f43ac000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.06,
    TRUE
),
(
    '001e898a-001e-4898-8001-001e898a001e',
    '000f43ac-000f-443a-8000-000f43ac000f',
    '0000007c-0000-4007-8000-0000007c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.12,
    TRUE
),
(
    '001e898b-001e-4898-8001-001e898b001e',
    '000f43ad-000f-443a-8000-000f43ad000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    14.37,
    TRUE
),
(
    '001e898c-001e-4898-8001-001e898c001e',
    '000f43ad-000f-443a-8000-000f43ad000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    16.53,
    TRUE
),
(
    '001e898d-001e-4898-8001-001e898d001e',
    '000f43ad-000f-443a-8000-000f43ad000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    12.38,
    TRUE
),
(
    '001e898e-001e-4898-8001-001e898e001e',
    '000f43ae-000f-443a-8000-000f43ae000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.16,
    TRUE
),
(
    '001e898f-001e-4898-8001-001e898f001e',
    '000f43ae-000f-443a-8000-000f43ae000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.79,
    TRUE
),
(
    '001e8990-001e-4899-8001-001e8990001e',
    '000f43ae-000f-443a-8000-000f43ae000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    10.84,
    TRUE
),
(
    '001e8991-001e-4899-8001-001e8991001e',
    '000f43ae-000f-443a-8000-000f43ae000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    11.44,
    TRUE
),
(
    '001e8992-001e-4899-8001-001e8992001e',
    '000f43ae-000f-443a-8000-000f43ae000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Pad Thai',
    'Thai-style stir-fried noodles',
    12.83,
    TRUE
),
(
    '001e8993-001e-4899-8001-001e8993001e',
    '000f43af-000f-443a-8000-000f43af000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.74,
    TRUE
),
(
    '001e8994-001e-4899-8001-001e8994001e',
    '000f43af-000f-443a-8000-000f43af000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.53,
    TRUE
),
(
    '001e8995-001e-4899-8001-001e8995001e',
    '000f43af-000f-443a-8000-000f43af000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.67,
    TRUE
),
(
    '001e8996-001e-4899-8001-001e8996001e',
    '000f43af-000f-443a-8000-000f43af000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.22,
    TRUE
),
(
    '001e8997-001e-4899-8001-001e8997001e',
    '000f43b0-000f-443b-8000-000f43b0000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.94,
    TRUE
),
(
    '001e8998-001e-4899-8001-001e8998001e',
    '000f43b0-000f-443b-8000-000f43b0000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.06,
    TRUE
),
(
    '001e8999-001e-4899-8001-001e8999001e',
    '000f43b0-000f-443b-8000-000f43b0000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.41,
    TRUE
),
(
    '001e899a-001e-4899-8001-001e899a001e',
    '000f43b0-000f-443b-8000-000f43b0000f',
    '0000007d-0000-4007-8000-0000007d0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.25,
    TRUE
),
(
    '001e899b-001e-4899-8001-001e899b001e',
    '000f43b1-000f-443b-8000-000f43b1000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Classic Burger',
    'Beef patty with lettuce, tomato, onion',
    11.05,
    TRUE
),
(
    '001e899c-001e-4899-8001-001e899c001e',
    '000f43b1-000f-443b-8000-000f43b1000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Cheeseburger',
    'Beef patty with cheese and special sauce',
    11.06,
    TRUE
),
(
    '001e899d-001e-4899-8001-001e899d001e',
    '000f43b1-000f-443b-8000-000f43b1000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Chicken Burger',
    'Grilled chicken breast with fixings',
    11.29,
    TRUE
),
(
    '001e899e-001e-4899-8001-001e899e001e',
    '000f43b1-000f-443b-8000-000f43b1000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Veggie Burger',
    'Plant-based patty with vegetables',
    10.14,
    TRUE
),
(
    '001e899f-001e-4899-8001-001e899f001e',
    '000f43b2-000f-443b-8000-000f43b2000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.78,
    TRUE
),
(
    '001e89a0-001e-489a-8001-001e89a0001e',
    '000f43b2-000f-443b-8000-000f43b2000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.64,
    TRUE
),
(
    '001e89a1-001e-489a-8001-001e89a1001e',
    '000f43b2-000f-443b-8000-000f43b2000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.63,
    TRUE
),
(
    '001e89a2-001e-489a-8001-001e89a2001e',
    '000f43b2-000f-443b-8000-000f43b2000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.83,
    TRUE
),
(
    '001e89a3-001e-489a-8001-001e89a3001e',
    '000f43b3-000f-443b-8000-000f43b3000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.50,
    TRUE
),
(
    '001e89a4-001e-489a-8001-001e89a4001e',
    '000f43b3-000f-443b-8000-000f43b3000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.75,
    TRUE
),
(
    '001e89a5-001e-489a-8001-001e89a5001e',
    '000f43b3-000f-443b-8000-000f43b3000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.99,
    TRUE
),
(
    '001e89a6-001e-489a-8001-001e89a6001e',
    '000f43b4-000f-443b-8000-000f43b4000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'French Fries',
    'Crispy golden fries',
    4.62,
    TRUE
),
(
    '001e89a7-001e-489a-8001-001e89a7001e',
    '000f43b4-000f-443b-8000-000f43b4000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Onion Rings',
    'Battered and fried onion rings',
    5.34,
    TRUE
),
(
    '001e89a8-001e-489a-8001-001e89a8001e',
    '000f43b4-000f-443b-8000-000f43b4000f',
    '0000007e-0000-4007-8000-0000007e0000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.83,
    TRUE
),
(
    '001e89a9-001e-489a-8001-001e89a9001e',
    '000f43b5-000f-443b-8000-000f43b5000f',
    '0000007f-0000-4007-8000-0000007f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.17,
    TRUE
),
(
    '001e89aa-001e-489a-8001-001e89aa001e',
    '000f43b5-000f-443b-8000-000f43b5000f',
    '0000007f-0000-4007-8000-0000007f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.73,
    TRUE
),
(
    '001e89ab-001e-489a-8001-001e89ab001e',
    '000f43b5-000f-443b-8000-000f43b5000f',
    '0000007f-0000-4007-8000-0000007f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.33,
    TRUE
),
(
    '001e89ac-001e-489a-8001-001e89ac001e',
    '000f43b6-000f-443b-8000-000f43b6000f',
    '0000007f-0000-4007-8000-0000007f0000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.36,
    TRUE
),
(
    '001e89ad-001e-489a-8001-001e89ad001e',
    '000f43b6-000f-443b-8000-000f43b6000f',
    '0000007f-0000-4007-8000-0000007f0000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.54,
    TRUE
),
(
    '001e89ae-001e-489a-8001-001e89ae001e',
    '000f43b6-000f-443b-8000-000f43b6000f',
    '0000007f-0000-4007-8000-0000007f0000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.74,
    TRUE
),
(
    '001e89af-001e-489a-8001-001e89af001e',
    '000f43b7-000f-443b-8000-000f43b7000f',
    '00000080-0000-4008-8000-000000800000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.54,
    TRUE
),
(
    '001e89b0-001e-489b-8001-001e89b0001e',
    '000f43b7-000f-443b-8000-000f43b7000f',
    '00000080-0000-4008-8000-000000800000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.74,
    TRUE
),
(
    '001e89b1-001e-489b-8001-001e89b1001e',
    '000f43b7-000f-443b-8000-000f43b7000f',
    '00000080-0000-4008-8000-000000800000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.46,
    TRUE
),
(
    '001e89b2-001e-489b-8001-001e89b2001e',
    '000f43b7-000f-443b-8000-000f43b7000f',
    '00000080-0000-4008-8000-000000800000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.68,
    TRUE
),
(
    '001e89b3-001e-489b-8001-001e89b3001e',
    '000f43b8-000f-443b-8000-000f43b8000f',
    '00000080-0000-4008-8000-000000800000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.00,
    TRUE
),
(
    '001e89b4-001e-489b-8001-001e89b4001e',
    '000f43b8-000f-443b-8000-000f43b8000f',
    '00000080-0000-4008-8000-000000800000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.69,
    TRUE
),
(
    '001e89b5-001e-489b-8001-001e89b5001e',
    '000f43b8-000f-443b-8000-000f43b8000f',
    '00000080-0000-4008-8000-000000800000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.62,
    TRUE
),
(
    '001e89b6-001e-489b-8001-001e89b6001e',
    '000f43b9-000f-443b-8000-000f43b9000f',
    '00000080-0000-4008-8000-000000800000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.54,
    TRUE
),
(
    '001e89b7-001e-489b-8001-001e89b7001e',
    '000f43b9-000f-443b-8000-000f43b9000f',
    '00000080-0000-4008-8000-000000800000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.64,
    TRUE
),
(
    '001e89b8-001e-489b-8001-001e89b8001e',
    '000f43b9-000f-443b-8000-000f43b9000f',
    '00000080-0000-4008-8000-000000800000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.58,
    TRUE
),
(
    '001e89b9-001e-489b-8001-001e89b9001e',
    '000f43ba-000f-443b-8000-000f43ba000f',
    '00000081-0000-4008-8000-000000810000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.62,
    TRUE
),
(
    '001e89ba-001e-489b-8001-001e89ba001e',
    '000f43ba-000f-443b-8000-000f43ba000f',
    '00000081-0000-4008-8000-000000810000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.62,
    TRUE
),
(
    '001e89bb-001e-489b-8001-001e89bb001e',
    '000f43ba-000f-443b-8000-000f43ba000f',
    '00000081-0000-4008-8000-000000810000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.41,
    TRUE
),
(
    '001e89bc-001e-489b-8001-001e89bc001e',
    '000f43ba-000f-443b-8000-000f43ba000f',
    '00000081-0000-4008-8000-000000810000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.35,
    TRUE
),
(
    '001e89bd-001e-489b-8001-001e89bd001e',
    '000f43bb-000f-443b-8000-000f43bb000f',
    '00000081-0000-4008-8000-000000810000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.57,
    TRUE
),
(
    '001e89be-001e-489b-8001-001e89be001e',
    '000f43bb-000f-443b-8000-000f43bb000f',
    '00000081-0000-4008-8000-000000810000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.66,
    TRUE
),
(
    '001e89bf-001e-489b-8001-001e89bf001e',
    '000f43bb-000f-443b-8000-000f43bb000f',
    '00000081-0000-4008-8000-000000810000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.54,
    TRUE
),
(
    '001e89c0-001e-489c-8001-001e89c0001e',
    '000f43bb-000f-443b-8000-000f43bb000f',
    '00000081-0000-4008-8000-000000810000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.39,
    TRUE
),
(
    '001e89c1-001e-489c-8001-001e89c1001e',
    '000f43bc-000f-443b-8000-000f43bc000f',
    '00000081-0000-4008-8000-000000810000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.83,
    TRUE
),
(
    '001e89c2-001e-489c-8001-001e89c2001e',
    '000f43bc-000f-443b-8000-000f43bc000f',
    '00000081-0000-4008-8000-000000810000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.98,
    TRUE
),
(
    '001e89c3-001e-489c-8001-001e89c3001e',
    '000f43bc-000f-443b-8000-000f43bc000f',
    '00000081-0000-4008-8000-000000810000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    12.28,
    TRUE
),
(
    '001e89c4-001e-489c-8001-001e89c4001e',
    '000f43bc-000f-443b-8000-000f43bc000f',
    '00000081-0000-4008-8000-000000810000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    12.74,
    TRUE
),
(
    '001e89c5-001e-489c-8001-001e89c5001e',
    '000f43bd-000f-443b-8000-000f43bd000f',
    '00000082-0000-4008-8000-000000820000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.22,
    TRUE
),
(
    '001e89c6-001e-489c-8001-001e89c6001e',
    '000f43bd-000f-443b-8000-000f43bd000f',
    '00000082-0000-4008-8000-000000820000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.28,
    TRUE
),
(
    '001e89c7-001e-489c-8001-001e89c7001e',
    '000f43bd-000f-443b-8000-000f43bd000f',
    '00000082-0000-4008-8000-000000820000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.70,
    TRUE
),
(
    '001e89c8-001e-489c-8001-001e89c8001e',
    '000f43bd-000f-443b-8000-000f43bd000f',
    '00000082-0000-4008-8000-000000820000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.16,
    TRUE
),
(
    '001e89c9-001e-489c-8001-001e89c9001e',
    '000f43be-000f-443b-8000-000f43be000f',
    '00000082-0000-4008-8000-000000820000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.05,
    TRUE
),
(
    '001e89ca-001e-489c-8001-001e89ca001e',
    '000f43be-000f-443b-8000-000f43be000f',
    '00000082-0000-4008-8000-000000820000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.68,
    TRUE
),
(
    '001e89cb-001e-489c-8001-001e89cb001e',
    '000f43be-000f-443b-8000-000f43be000f',
    '00000082-0000-4008-8000-000000820000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.97,
    TRUE
),
(
    '001e89cc-001e-489c-8001-001e89cc001e',
    '000f43be-000f-443b-8000-000f43be000f',
    '00000082-0000-4008-8000-000000820000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.47,
    TRUE
),
(
    '001e89cd-001e-489c-8001-001e89cd001e',
    '000f43bf-000f-443b-8000-000f43bf000f',
    '00000082-0000-4008-8000-000000820000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.31,
    TRUE
),
(
    '001e89ce-001e-489c-8001-001e89ce001e',
    '000f43bf-000f-443b-8000-000f43bf000f',
    '00000082-0000-4008-8000-000000820000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.35,
    TRUE
),
(
    '001e89cf-001e-489c-8001-001e89cf001e',
    '000f43bf-000f-443b-8000-000f43bf000f',
    '00000082-0000-4008-8000-000000820000',
    'Risotto',
    'Creamy Italian rice dish',
    13.63,
    TRUE
),
(
    '001e89d0-001e-489d-8001-001e89d0001e',
    '000f43c0-000f-443c-8000-000f43c0000f',
    '00000082-0000-4008-8000-000000820000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.12,
    TRUE
),
(
    '001e89d1-001e-489d-8001-001e89d1001e',
    '000f43c0-000f-443c-8000-000f43c0000f',
    '00000082-0000-4008-8000-000000820000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.70,
    TRUE
),
(
    '001e89d2-001e-489d-8001-001e89d2001e',
    '000f43c0-000f-443c-8000-000f43c0000f',
    '00000082-0000-4008-8000-000000820000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.20,
    TRUE
),
(
    '001e89d3-001e-489d-8001-001e89d3001e',
    '000f43c0-000f-443c-8000-000f43c0000f',
    '00000082-0000-4008-8000-000000820000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.50,
    TRUE
),
(
    '001e89d4-001e-489d-8001-001e89d4001e',
    '000f43c1-000f-443c-8000-000f43c1000f',
    '00000083-0000-4008-8000-000000830000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.58,
    TRUE
),
(
    '001e89d5-001e-489d-8001-001e89d5001e',
    '000f43c1-000f-443c-8000-000f43c1000f',
    '00000083-0000-4008-8000-000000830000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.49,
    TRUE
),
(
    '001e89d6-001e-489d-8001-001e89d6001e',
    '000f43c1-000f-443c-8000-000f43c1000f',
    '00000083-0000-4008-8000-000000830000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.86,
    TRUE
),
(
    '001e89d7-001e-489d-8001-001e89d7001e',
    '000f43c1-000f-443c-8000-000f43c1000f',
    '00000083-0000-4008-8000-000000830000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.79,
    TRUE
),
(
    '001e89d8-001e-489d-8001-001e89d8001e',
    '000f43c2-000f-443c-8000-000f43c2000f',
    '00000083-0000-4008-8000-000000830000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.72,
    TRUE
),
(
    '001e89d9-001e-489d-8001-001e89d9001e',
    '000f43c2-000f-443c-8000-000f43c2000f',
    '00000083-0000-4008-8000-000000830000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.35,
    TRUE
),
(
    '001e89da-001e-489d-8001-001e89da001e',
    '000f43c2-000f-443c-8000-000f43c2000f',
    '00000083-0000-4008-8000-000000830000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.57,
    TRUE
),
(
    '001e89db-001e-489d-8001-001e89db001e',
    '000f43c2-000f-443c-8000-000f43c2000f',
    '00000083-0000-4008-8000-000000830000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.46,
    TRUE
),
(
    '001e89dc-001e-489d-8001-001e89dc001e',
    '000f43c3-000f-443c-8000-000f43c3000f',
    '00000083-0000-4008-8000-000000830000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.65,
    TRUE
),
(
    '001e89dd-001e-489d-8001-001e89dd001e',
    '000f43c3-000f-443c-8000-000f43c3000f',
    '00000083-0000-4008-8000-000000830000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.89,
    TRUE
),
(
    '001e89de-001e-489d-8001-001e89de001e',
    '000f43c3-000f-443c-8000-000f43c3000f',
    '00000083-0000-4008-8000-000000830000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.28,
    TRUE
),
(
    '001e89df-001e-489d-8001-001e89df001e',
    '000f43c4-000f-443c-8000-000f43c4000f',
    '00000084-0000-4008-8000-000000840000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.56,
    TRUE
),
(
    '001e89e0-001e-489e-8001-001e89e0001e',
    '000f43c4-000f-443c-8000-000f43c4000f',
    '00000084-0000-4008-8000-000000840000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.03,
    TRUE
),
(
    '001e89e1-001e-489e-8001-001e89e1001e',
    '000f43c4-000f-443c-8000-000f43c4000f',
    '00000084-0000-4008-8000-000000840000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.12,
    TRUE
),
(
    '001e89e2-001e-489e-8001-001e89e2001e',
    '000f43c4-000f-443c-8000-000f43c4000f',
    '00000084-0000-4008-8000-000000840000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.55,
    TRUE
),
(
    '001e89e3-001e-489e-8001-001e89e3001e',
    '000f43c5-000f-443c-8000-000f43c5000f',
    '00000084-0000-4008-8000-000000840000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.94,
    TRUE
),
(
    '001e89e4-001e-489e-8001-001e89e4001e',
    '000f43c5-000f-443c-8000-000f43c5000f',
    '00000084-0000-4008-8000-000000840000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.79,
    TRUE
),
(
    '001e89e5-001e-489e-8001-001e89e5001e',
    '000f43c5-000f-443c-8000-000f43c5000f',
    '00000084-0000-4008-8000-000000840000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.74,
    TRUE
),
(
    '001e89e6-001e-489e-8001-001e89e6001e',
    '000f43c6-000f-443c-8000-000f43c6000f',
    '00000084-0000-4008-8000-000000840000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.39,
    TRUE
),
(
    '001e89e7-001e-489e-8001-001e89e7001e',
    '000f43c6-000f-443c-8000-000f43c6000f',
    '00000084-0000-4008-8000-000000840000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.26,
    TRUE
),
(
    '001e89e8-001e-489e-8001-001e89e8001e',
    '000f43c6-000f-443c-8000-000f43c6000f',
    '00000084-0000-4008-8000-000000840000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.37,
    TRUE
),
(
    '001e89e9-001e-489e-8001-001e89e9001e',
    '000f43c7-000f-443c-8000-000f43c7000f',
    '00000084-0000-4008-8000-000000840000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.71,
    TRUE
),
(
    '001e89ea-001e-489e-8001-001e89ea001e',
    '000f43c7-000f-443c-8000-000f43c7000f',
    '00000084-0000-4008-8000-000000840000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.90,
    TRUE
),
(
    '001e89eb-001e-489e-8001-001e89eb001e',
    '000f43c7-000f-443c-8000-000f43c7000f',
    '00000084-0000-4008-8000-000000840000',
    'Cheesecake',
    'New York style cheesecake',
    8.56,
    TRUE
),
(
    '001e89ec-001e-489e-8001-001e89ec001e',
    '000f43c7-000f-443c-8000-000f43c7000f',
    '00000084-0000-4008-8000-000000840000',
    'Tiramisu',
    'Classic Italian dessert',
    8.22,
    TRUE
),
(
    '001e89ed-001e-489e-8001-001e89ed001e',
    '000f43c8-000f-443c-8000-000f43c8000f',
    '00000085-0000-4008-8000-000000850000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.39,
    TRUE
),
(
    '001e89ee-001e-489e-8001-001e89ee001e',
    '000f43c8-000f-443c-8000-000f43c8000f',
    '00000085-0000-4008-8000-000000850000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.41,
    TRUE
),
(
    '001e89ef-001e-489e-8001-001e89ef001e',
    '000f43c8-000f-443c-8000-000f43c8000f',
    '00000085-0000-4008-8000-000000850000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.97,
    TRUE
),
(
    '001e89f0-001e-489f-8001-001e89f0001e',
    '000f43c8-000f-443c-8000-000f43c8000f',
    '00000085-0000-4008-8000-000000850000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.89,
    TRUE
),
(
    '001e89f1-001e-489f-8001-001e89f1001e',
    '000f43c9-000f-443c-8000-000f43c9000f',
    '00000085-0000-4008-8000-000000850000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.53,
    TRUE
),
(
    '001e89f2-001e-489f-8001-001e89f2001e',
    '000f43c9-000f-443c-8000-000f43c9000f',
    '00000085-0000-4008-8000-000000850000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.78,
    TRUE
),
(
    '001e89f3-001e-489f-8001-001e89f3001e',
    '000f43c9-000f-443c-8000-000f43c9000f',
    '00000085-0000-4008-8000-000000850000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.54,
    TRUE
),
(
    '001e89f4-001e-489f-8001-001e89f4001e',
    '000f43c9-000f-443c-8000-000f43c9000f',
    '00000085-0000-4008-8000-000000850000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.15,
    TRUE
),
(
    '001e89f5-001e-489f-8001-001e89f5001e',
    '000f43ca-000f-443c-8000-000f43ca000f',
    '00000085-0000-4008-8000-000000850000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.18,
    TRUE
),
(
    '001e89f6-001e-489f-8001-001e89f6001e',
    '000f43ca-000f-443c-8000-000f43ca000f',
    '00000085-0000-4008-8000-000000850000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.97,
    TRUE
),
(
    '001e89f7-001e-489f-8001-001e89f7001e',
    '000f43ca-000f-443c-8000-000f43ca000f',
    '00000085-0000-4008-8000-000000850000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.02,
    TRUE
),
(
    '001e89f8-001e-489f-8001-001e89f8001e',
    '000f43ca-000f-443c-8000-000f43ca000f',
    '00000085-0000-4008-8000-000000850000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.13,
    TRUE
),
(
    '001e89f9-001e-489f-8001-001e89f9001e',
    '000f43cb-000f-443c-8000-000f43cb000f',
    '00000086-0000-4008-8000-000000860000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.97,
    TRUE
),
(
    '001e89fa-001e-489f-8001-001e89fa001e',
    '000f43cb-000f-443c-8000-000f43cb000f',
    '00000086-0000-4008-8000-000000860000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.43,
    TRUE
),
(
    '001e89fb-001e-489f-8001-001e89fb001e',
    '000f43cb-000f-443c-8000-000f43cb000f',
    '00000086-0000-4008-8000-000000860000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.52,
    TRUE
),
(
    '001e89fc-001e-489f-8001-001e89fc001e',
    '000f43cb-000f-443c-8000-000f43cb000f',
    '00000086-0000-4008-8000-000000860000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.28,
    TRUE
),
(
    '001e89fd-001e-489f-8001-001e89fd001e',
    '000f43cc-000f-443c-8000-000f43cc000f',
    '00000086-0000-4008-8000-000000860000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.07,
    TRUE
),
(
    '001e89fe-001e-489f-8001-001e89fe001e',
    '000f43cc-000f-443c-8000-000f43cc000f',
    '00000086-0000-4008-8000-000000860000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.11,
    TRUE
),
(
    '001e89ff-001e-489f-8001-001e89ff001e',
    '000f43cc-000f-443c-8000-000f43cc000f',
    '00000086-0000-4008-8000-000000860000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.72,
    TRUE
),
(
    '001e8a00-001e-48a0-8001-001e8a00001e',
    '000f43cd-000f-443c-8000-000f43cd000f',
    '00000087-0000-4008-8000-000000870000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.34,
    TRUE
),
(
    '001e8a01-001e-48a0-8001-001e8a01001e',
    '000f43cd-000f-443c-8000-000f43cd000f',
    '00000087-0000-4008-8000-000000870000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.91,
    TRUE
),
(
    '001e8a02-001e-48a0-8001-001e8a02001e',
    '000f43cd-000f-443c-8000-000f43cd000f',
    '00000087-0000-4008-8000-000000870000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.48,
    TRUE
),
(
    '001e8a03-001e-48a0-8001-001e8a03001e',
    '000f43cd-000f-443c-8000-000f43cd000f',
    '00000087-0000-4008-8000-000000870000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.74,
    TRUE
),
(
    '001e8a04-001e-48a0-8001-001e8a04001e',
    '000f43ce-000f-443c-8000-000f43ce000f',
    '00000087-0000-4008-8000-000000870000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.47,
    TRUE
),
(
    '001e8a05-001e-48a0-8001-001e8a05001e',
    '000f43ce-000f-443c-8000-000f43ce000f',
    '00000087-0000-4008-8000-000000870000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.95,
    TRUE
),
(
    '001e8a06-001e-48a0-8001-001e8a06001e',
    '000f43ce-000f-443c-8000-000f43ce000f',
    '00000087-0000-4008-8000-000000870000',
    'Risotto',
    'Creamy Italian rice dish',
    12.51,
    TRUE
),
(
    '001e8a07-001e-48a0-8001-001e8a07001e',
    '000f43cf-000f-443c-8000-000f43cf000f',
    '00000088-0000-4008-8000-000000880000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.84,
    TRUE
),
(
    '001e8a08-001e-48a0-8001-001e8a08001e',
    '000f43cf-000f-443c-8000-000f43cf000f',
    '00000088-0000-4008-8000-000000880000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.25,
    TRUE
),
(
    '001e8a09-001e-48a0-8001-001e8a09001e',
    '000f43cf-000f-443c-8000-000f43cf000f',
    '00000088-0000-4008-8000-000000880000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.02,
    TRUE
),
(
    '001e8a0a-001e-48a0-8001-001e8a0a001e',
    '000f43cf-000f-443c-8000-000f43cf000f',
    '00000088-0000-4008-8000-000000880000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.14,
    TRUE
),
(
    '001e8a0b-001e-48a0-8001-001e8a0b001e',
    '000f43d0-000f-443d-8000-000f43d0000f',
    '00000088-0000-4008-8000-000000880000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.96,
    TRUE
),
(
    '001e8a0c-001e-48a0-8001-001e8a0c001e',
    '000f43d0-000f-443d-8000-000f43d0000f',
    '00000088-0000-4008-8000-000000880000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.14,
    TRUE
),
(
    '001e8a0d-001e-48a0-8001-001e8a0d001e',
    '000f43d0-000f-443d-8000-000f43d0000f',
    '00000088-0000-4008-8000-000000880000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.69,
    TRUE
),
(
    '001e8a0e-001e-48a0-8001-001e8a0e001e',
    '000f43d0-000f-443d-8000-000f43d0000f',
    '00000088-0000-4008-8000-000000880000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.67,
    TRUE
),
(
    '001e8a0f-001e-48a0-8001-001e8a0f001e',
    '000f43d1-000f-443d-8000-000f43d1000f',
    '00000088-0000-4008-8000-000000880000',
    'French Fries',
    'Crispy golden fries',
    5.52,
    TRUE
),
(
    '001e8a10-001e-48a1-8001-001e8a10001e',
    '000f43d1-000f-443d-8000-000f43d1000f',
    '00000088-0000-4008-8000-000000880000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.78,
    TRUE
),
(
    '001e8a11-001e-48a1-8001-001e8a11001e',
    '000f43d1-000f-443d-8000-000f43d1000f',
    '00000088-0000-4008-8000-000000880000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.07,
    TRUE
),
(
    '001e8a12-001e-48a1-8001-001e8a12001e',
    '000f43d2-000f-443d-8000-000f43d2000f',
    '00000088-0000-4008-8000-000000880000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.01,
    TRUE
),
(
    '001e8a13-001e-48a1-8001-001e8a13001e',
    '000f43d2-000f-443d-8000-000f43d2000f',
    '00000088-0000-4008-8000-000000880000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.25,
    TRUE
),
(
    '001e8a14-001e-48a1-8001-001e8a14001e',
    '000f43d2-000f-443d-8000-000f43d2000f',
    '00000088-0000-4008-8000-000000880000',
    'Cheesecake',
    'New York style cheesecake',
    8.22,
    TRUE
),
(
    '001e8a15-001e-48a1-8001-001e8a15001e',
    '000f43d2-000f-443d-8000-000f43d2000f',
    '00000088-0000-4008-8000-000000880000',
    'Tiramisu',
    'Classic Italian dessert',
    7.12,
    TRUE
),
(
    '001e8a16-001e-48a1-8001-001e8a16001e',
    '000f43d3-000f-443d-8000-000f43d3000f',
    '00000089-0000-4008-8000-000000890000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.81,
    TRUE
),
(
    '001e8a17-001e-48a1-8001-001e8a17001e',
    '000f43d3-000f-443d-8000-000f43d3000f',
    '00000089-0000-4008-8000-000000890000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.67,
    TRUE
),
(
    '001e8a18-001e-48a1-8001-001e8a18001e',
    '000f43d3-000f-443d-8000-000f43d3000f',
    '00000089-0000-4008-8000-000000890000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.53,
    TRUE
),
(
    '001e8a19-001e-48a1-8001-001e8a19001e',
    '000f43d3-000f-443d-8000-000f43d3000f',
    '00000089-0000-4008-8000-000000890000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.71,
    TRUE
),
(
    '001e8a1a-001e-48a1-8001-001e8a1a001e',
    '000f43d4-000f-443d-8000-000f43d4000f',
    '00000089-0000-4008-8000-000000890000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.87,
    TRUE
),
(
    '001e8a1b-001e-48a1-8001-001e8a1b001e',
    '000f43d4-000f-443d-8000-000f43d4000f',
    '00000089-0000-4008-8000-000000890000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.01,
    TRUE
),
(
    '001e8a1c-001e-48a1-8001-001e8a1c001e',
    '000f43d4-000f-443d-8000-000f43d4000f',
    '00000089-0000-4008-8000-000000890000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.44,
    TRUE
),
(
    '001e8a1d-001e-48a1-8001-001e8a1d001e',
    '000f43d5-000f-443d-8000-000f43d5000f',
    '00000089-0000-4008-8000-000000890000',
    'French Fries',
    'Crispy golden fries',
    4.42,
    TRUE
),
(
    '001e8a1e-001e-48a1-8001-001e8a1e001e',
    '000f43d5-000f-443d-8000-000f43d5000f',
    '00000089-0000-4008-8000-000000890000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.44,
    TRUE
),
(
    '001e8a1f-001e-48a1-8001-001e8a1f001e',
    '000f43d5-000f-443d-8000-000f43d5000f',
    '00000089-0000-4008-8000-000000890000',
    'Coleslaw',
    'Fresh cabbage salad',
    3.57,
    TRUE
),
(
    '001e8a20-001e-48a2-8001-001e8a20001e',
    '000f43d6-000f-443d-8000-000f43d6000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.39,
    TRUE
),
(
    '001e8a21-001e-48a2-8001-001e8a21001e',
    '000f43d6-000f-443d-8000-000f43d6000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.12,
    TRUE
),
(
    '001e8a22-001e-48a2-8001-001e8a22001e',
    '000f43d6-000f-443d-8000-000f43d6000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.92,
    TRUE
),
(
    '001e8a23-001e-48a2-8001-001e8a23001e',
    '000f43d6-000f-443d-8000-000f43d6000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.28,
    TRUE
),
(
    '001e8a24-001e-48a2-8001-001e8a24001e',
    '000f43d7-000f-443d-8000-000f43d7000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.91,
    TRUE
),
(
    '001e8a25-001e-48a2-8001-001e8a25001e',
    '000f43d7-000f-443d-8000-000f43d7000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.20,
    TRUE
),
(
    '001e8a26-001e-48a2-8001-001e8a26001e',
    '000f43d7-000f-443d-8000-000f43d7000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Risotto',
    'Creamy Italian rice dish',
    13.37,
    TRUE
),
(
    '001e8a27-001e-48a2-8001-001e8a27001e',
    '000f43d8-000f-443d-8000-000f43d8000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    8.20,
    TRUE
),
(
    '001e8a28-001e-48a2-8001-001e8a28001e',
    '000f43d8-000f-443d-8000-000f43d8000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.70,
    TRUE
),
(
    '001e8a29-001e-48a2-8001-001e8a29001e',
    '000f43d8-000f-443d-8000-000f43d8000f',
    '0000008a-0000-4008-8000-0000008a0000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.14,
    TRUE
),
(
    '001e8a2a-001e-48a2-8001-001e8a2a001e',
    '000f43d9-000f-443d-8000-000f43d9000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.82,
    TRUE
),
(
    '001e8a2b-001e-48a2-8001-001e8a2b001e',
    '000f43d9-000f-443d-8000-000f43d9000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.67,
    TRUE
),
(
    '001e8a2c-001e-48a2-8001-001e8a2c001e',
    '000f43d9-000f-443d-8000-000f43d9000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.86,
    TRUE
),
(
    '001e8a2d-001e-48a2-8001-001e8a2d001e',
    '000f43d9-000f-443d-8000-000f43d9000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.40,
    TRUE
),
(
    '001e8a2e-001e-48a2-8001-001e8a2e001e',
    '000f43da-000f-443d-8000-000f43da000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.34,
    TRUE
),
(
    '001e8a2f-001e-48a2-8001-001e8a2f001e',
    '000f43da-000f-443d-8000-000f43da000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.21,
    TRUE
),
(
    '001e8a30-001e-48a3-8001-001e8a30001e',
    '000f43da-000f-443d-8000-000f43da000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.70,
    TRUE
),
(
    '001e8a31-001e-48a3-8001-001e8a31001e',
    '000f43da-000f-443d-8000-000f43da000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.03,
    TRUE
),
(
    '001e8a32-001e-48a3-8001-001e8a32001e',
    '000f43db-000f-443d-8000-000f43db000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'French Fries',
    'Crispy golden fries',
    5.20,
    TRUE
),
(
    '001e8a33-001e-48a3-8001-001e8a33001e',
    '000f43db-000f-443d-8000-000f43db000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Onion Rings',
    'Battered and fried onion rings',
    5.48,
    TRUE
),
(
    '001e8a34-001e-48a3-8001-001e8a34001e',
    '000f43db-000f-443d-8000-000f43db000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.02,
    TRUE
),
(
    '001e8a35-001e-48a3-8001-001e8a35001e',
    '000f43dc-000f-443d-8000-000f43dc000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.48,
    TRUE
),
(
    '001e8a36-001e-48a3-8001-001e8a36001e',
    '000f43dc-000f-443d-8000-000f43dc000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.76,
    TRUE
),
(
    '001e8a37-001e-48a3-8001-001e8a37001e',
    '000f43dc-000f-443d-8000-000f43dc000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Cheesecake',
    'New York style cheesecake',
    8.34,
    TRUE
),
(
    '001e8a38-001e-48a3-8001-001e8a38001e',
    '000f43dc-000f-443d-8000-000f43dc000f',
    '0000008b-0000-4008-8000-0000008b0000',
    'Tiramisu',
    'Classic Italian dessert',
    7.17,
    TRUE
),
(
    '001e8a39-001e-48a3-8001-001e8a39001e',
    '000f43dd-000f-443d-8000-000f43dd000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    13.90,
    TRUE
),
(
    '001e8a3a-001e-48a3-8001-001e8a3a001e',
    '000f43dd-000f-443d-8000-000f43dd000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    14.06,
    TRUE
),
(
    '001e8a3b-001e-48a3-8001-001e8a3b001e',
    '000f43dd-000f-443d-8000-000f43dd000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives',
    16.08,
    TRUE
),
(
    '001e8a3c-001e-48a3-8001-001e8a3c001e',
    '000f43dd-000f-443d-8000-000f43dd000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Hawaiian',
    'Ham, pineapple, mozzarella',
    14.52,
    TRUE
),
(
    '001e8a3d-001e-48a3-8001-001e8a3d001e',
    '000f43de-000f-443d-8000-000f43de000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino',
    14.05,
    TRUE
),
(
    '001e8a3e-001e-48a3-8001-001e8a3e001e',
    '000f43de-000f-443d-8000-000f43de000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    12.48,
    TRUE
),
(
    '001e8a3f-001e-48a3-8001-001e8a3f001e',
    '000f43de-000f-443d-8000-000f43de000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream',
    14.25,
    TRUE
),
(
    '001e8a40-001e-48a4-8001-001e8a40001e',
    '000f43de-000f-443d-8000-000f43de000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Lasagna',
    'Layered pasta with meat sauce and cheese',
    14.65,
    TRUE
),
(
    '001e8a41-001e-48a4-8001-001e8a41001e',
    '000f43df-000f-443d-8000-000f43df000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.09,
    TRUE
),
(
    '001e8a42-001e-48a4-8001-001e8a42001e',
    '000f43df-000f-443d-8000-000f43df000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.04,
    TRUE
),
(
    '001e8a43-001e-48a4-8001-001e8a43001e',
    '000f43df-000f-443d-8000-000f43df000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.94,
    TRUE
),
(
    '001e8a44-001e-48a4-8001-001e8a44001e',
    '000f43df-000f-443d-8000-000f43df000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.11,
    TRUE
),
(
    '001e8a45-001e-48a4-8001-001e8a45001e',
    '000f43e0-000f-443e-8000-000f43e0000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.02,
    TRUE
),
(
    '001e8a46-001e-48a4-8001-001e8a46001e',
    '000f43e0-000f-443e-8000-000f43e0000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.77,
    TRUE
),
(
    '001e8a47-001e-48a4-8001-001e8a47001e',
    '000f43e0-000f-443e-8000-000f43e0000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Cheesecake',
    'New York style cheesecake',
    8.65,
    TRUE
),
(
    '001e8a48-001e-48a4-8001-001e8a48001e',
    '000f43e0-000f-443e-8000-000f43e0000f',
    '0000008c-0000-4008-8000-0000008c0000',
    'Tiramisu',
    'Classic Italian dessert',
    6.87,
    TRUE
),
(
    '001e8a49-001e-48a4-8001-001e8a49001e',
    '000f43e1-000f-443e-8000-000f43e1000f',
    '0000008d-0000-4008-8000-0000008d0000',
    'Har Gow',
    'Steamed shrimp dumplings',
    9.81,
    TRUE
),
(
    '001e8a4a-001e-48a4-8001-001e8a4a001e',
    '000f43e1-000f-443e-8000-000f43e1000f',
    '0000008d-0000-4008-8000-0000008d0000',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    8.44,
    TRUE
),
(
    '001e8a4b-001e-48a4-8001-001e8a4b001e',
    '000f43e1-000f-443e-8000-000f43e1000f',
    '0000008d-0000-4008-8000-0000008d0000',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    7.25,
    TRUE
),
(
    '001e8a4c-001e-48a4-8001-001e8a4c001e',
    '000f43e1-000f-443e-8000-000f43e1000f',
    '0000008d-0000-4008-8000-0000008d0000',
    'Spring Rolls',
    'Crispy vegetable spring rolls',
    7.33,
    TRUE
),
(
    '001e8a4d-001e-48a4-8001-001e8a4d001e',
    '000f43e2-000f-443e-8000-000f43e2000f',
    '0000008d-0000-4008-8000-0000008d0000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.78,
    TRUE
),
(
    '001e8a4e-001e-48a4-8001-001e8a4e001e',
    '000f43e2-000f-443e-8000-000f43e2000f',
    '0000008d-0000-4008-8000-0000008d0000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.81,
    TRUE
),
(
    '001e8a4f-001e-48a4-8001-001e8a4f001e',
    '000f43e2-000f-443e-8000-000f43e2000f',
    '0000008d-0000-4008-8000-0000008d0000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.40,
    TRUE
),
(
    '001e8a50-001e-48a5-8001-001e8a50001e',
    '000f43e3-000f-443e-8000-000f43e3000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Beef Tacos',
    'Seasoned ground beef with lettuce and cheese',
    9.29,
    TRUE
),
(
    '001e8a51-001e-48a5-8001-001e8a51001e',
    '000f43e3-000f-443e-8000-000f43e3000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Chicken Tacos',
    'Grilled chicken with salsa and avocado',
    9.60,
    TRUE
),
(
    '001e8a52-001e-48a5-8001-001e8a52001e',
    '000f43e3-000f-443e-8000-000f43e3000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Fish Tacos',
    'Battered fish with cabbage slaw',
    10.68,
    TRUE
),
(
    '001e8a53-001e-48a5-8001-001e8a53001e',
    '000f43e3-000f-443e-8000-000f43e3000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Vegetarian Tacos',
    'Black beans, corn, and vegetables',
    9.62,
    TRUE
),
(
    '001e8a54-001e-48a5-8001-001e8a54001e',
    '000f43e4-000f-443e-8000-000f43e4000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.18,
    TRUE
),
(
    '001e8a55-001e-48a5-8001-001e8a55001e',
    '000f43e4-000f-443e-8000-000f43e4000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.02,
    TRUE
),
(
    '001e8a56-001e-48a5-8001-001e8a56001e',
    '000f43e4-000f-443e-8000-000f43e4000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.03,
    TRUE
),
(
    '001e8a57-001e-48a5-8001-001e8a57001e',
    '000f43e4-000f-443e-8000-000f43e4000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.71,
    TRUE
),
(
    '001e8a58-001e-48a5-8001-001e8a58001e',
    '000f43e5-000f-443e-8000-000f43e5000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.05,
    TRUE
),
(
    '001e8a59-001e-48a5-8001-001e8a59001e',
    '000f43e5-000f-443e-8000-000f43e5000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.14,
    TRUE
),
(
    '001e8a5a-001e-48a5-8001-001e8a5a001e',
    '000f43e5-000f-443e-8000-000f43e5000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.33,
    TRUE
),
(
    '001e8a5b-001e-48a5-8001-001e8a5b001e',
    '000f43e5-000f-443e-8000-000f43e5000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    5.99,
    TRUE
),
(
    '001e8a5c-001e-48a5-8001-001e8a5c001e',
    '000f43e6-000f-443e-8000-000f43e6000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.90,
    TRUE
),
(
    '001e8a5d-001e-48a5-8001-001e8a5d001e',
    '000f43e6-000f-443e-8000-000f43e6000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.97,
    TRUE
),
(
    '001e8a5e-001e-48a5-8001-001e8a5e001e',
    '000f43e6-000f-443e-8000-000f43e6000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.74,
    TRUE
),
(
    '001e8a5f-001e-48a5-8001-001e8a5f001e',
    '000f43e6-000f-443e-8000-000f43e6000f',
    '0000008e-0000-4008-8000-0000008e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.85,
    TRUE
),
(
    '001e8a60-001e-48a6-8001-001e8a60001e',
    '000f43e7-000f-443e-8000-000f43e7000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    14.06,
    TRUE
),
(
    '001e8a61-001e-48a6-8001-001e8a61001e',
    '000f43e7-000f-443e-8000-000f43e7000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    16.03,
    TRUE
),
(
    '001e8a62-001e-48a6-8001-001e8a62001e',
    '000f43e7-000f-443e-8000-000f43e7000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.53,
    TRUE
),
(
    '001e8a63-001e-48a6-8001-001e8a63001e',
    '000f43e7-000f-443e-8000-000f43e7000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    13.69,
    TRUE
),
(
    '001e8a64-001e-48a6-8001-001e8a64001e',
    '000f43e8-000f-443e-8000-000f43e8000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.75,
    TRUE
),
(
    '001e8a65-001e-48a6-8001-001e8a65001e',
    '000f43e8-000f-443e-8000-000f43e8000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.74,
    TRUE
),
(
    '001e8a66-001e-48a6-8001-001e8a66001e',
    '000f43e8-000f-443e-8000-000f43e8000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.68,
    TRUE
),
(
    '001e8a67-001e-48a6-8001-001e8a67001e',
    '000f43e9-000f-443e-8000-000f43e9000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.17,
    TRUE
),
(
    '001e8a68-001e-48a6-8001-001e8a68001e',
    '000f43e9-000f-443e-8000-000f43e9000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.21,
    TRUE
),
(
    '001e8a69-001e-48a6-8001-001e8a69001e',
    '000f43e9-000f-443e-8000-000f43e9000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.64,
    TRUE
),
(
    '001e8a6a-001e-48a6-8001-001e8a6a001e',
    '000f43e9-000f-443e-8000-000f43e9000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.26,
    TRUE
),
(
    '001e8a6b-001e-48a6-8001-001e8a6b001e',
    '000f43ea-000f-443e-8000-000f43ea000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.50,
    TRUE
),
(
    '001e8a6c-001e-48a6-8001-001e8a6c001e',
    '000f43ea-000f-443e-8000-000f43ea000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.59,
    TRUE
),
(
    '001e8a6d-001e-48a6-8001-001e8a6d001e',
    '000f43ea-000f-443e-8000-000f43ea000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.03,
    TRUE
),
(
    '001e8a6e-001e-48a6-8001-001e8a6e001e',
    '000f43ea-000f-443e-8000-000f43ea000f',
    '0000008f-0000-4008-8000-0000008f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.55,
    TRUE
),
(
    '001e8a6f-001e-48a6-8001-001e8a6f001e',
    '000f43eb-000f-443e-8000-000f43eb000f',
    '00000090-0000-4009-8000-000000900000',
    'Salmon Roll',
    'Fresh salmon with rice and nori',
    9.88,
    TRUE
),
(
    '001e8a70-001e-48a7-8001-001e8a70001e',
    '000f43eb-000f-443e-8000-000f43eb000f',
    '00000090-0000-4009-8000-000000900000',
    'Tuna Roll',
    'Premium tuna with rice and nori',
    10.01,
    TRUE
),
(
    '001e8a71-001e-48a7-8001-001e8a71001e',
    '000f43eb-000f-443e-8000-000f43eb000f',
    '00000090-0000-4009-8000-000000900000',
    'California Roll',
    'Crab, avocado, and cucumber',
    8.08,
    TRUE
),
(
    '001e8a72-001e-48a7-8001-001e8a72001e',
    '000f43ec-000f-443e-8000-000f43ec000f',
    '00000090-0000-4009-8000-000000900000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.83,
    TRUE
),
(
    '001e8a73-001e-48a7-8001-001e8a73001e',
    '000f43ec-000f-443e-8000-000f43ec000f',
    '00000090-0000-4009-8000-000000900000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.66,
    TRUE
),
(
    '001e8a74-001e-48a7-8001-001e8a74001e',
    '000f43ec-000f-443e-8000-000f43ec000f',
    '00000090-0000-4009-8000-000000900000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.05,
    TRUE
),
(
    '001e8a75-001e-48a7-8001-001e8a75001e',
    '000f43ec-000f-443e-8000-000f43ec000f',
    '00000090-0000-4009-8000-000000900000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.24,
    TRUE
),
(
    '001e8a76-001e-48a7-8001-001e8a76001e',
    '000f43ed-000f-443e-8000-000f43ed000f',
    '00000090-0000-4009-8000-000000900000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.88,
    TRUE
),
(
    '001e8a77-001e-48a7-8001-001e8a77001e',
    '000f43ed-000f-443e-8000-000f43ed000f',
    '00000090-0000-4009-8000-000000900000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.09,
    TRUE
),
(
    '001e8a78-001e-48a7-8001-001e8a78001e',
    '000f43ed-000f-443e-8000-000f43ed000f',
    '00000090-0000-4009-8000-000000900000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.93,
    TRUE
),
(
    '001e8a79-001e-48a7-8001-001e8a79001e',
    '000f43ed-000f-443e-8000-000f43ed000f',
    '00000090-0000-4009-8000-000000900000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.71,
    TRUE
),
(
    '001e8a7a-001e-48a7-8001-001e8a7a001e',
    '000f43ee-000f-443e-8000-000f43ee000f',
    '00000091-0000-4009-8000-000000910000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    13.06,
    TRUE
),
(
    '001e8a7b-001e-48a7-8001-001e8a7b001e',
    '000f43ee-000f-443e-8000-000f43ee000f',
    '00000091-0000-4009-8000-000000910000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    16.31,
    TRUE
),
(
    '001e8a7c-001e-48a7-8001-001e8a7c001e',
    '000f43ee-000f-443e-8000-000f43ee000f',
    '00000091-0000-4009-8000-000000910000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    12.18,
    TRUE
),
(
    '001e8a7d-001e-48a7-8001-001e8a7d001e',
    '000f43ee-000f-443e-8000-000f43ee000f',
    '00000091-0000-4009-8000-000000910000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    15.00,
    TRUE
),
(
    '001e8a7e-001e-48a7-8001-001e8a7e001e',
    '000f43ef-000f-443e-8000-000f43ef000f',
    '00000091-0000-4009-8000-000000910000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.91,
    TRUE
),
(
    '001e8a7f-001e-48a7-8001-001e8a7f001e',
    '000f43ef-000f-443e-8000-000f43ef000f',
    '00000091-0000-4009-8000-000000910000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.69,
    TRUE
),
(
    '001e8a80-001e-48a8-8001-001e8a80001e',
    '000f43ef-000f-443e-8000-000f43ef000f',
    '00000091-0000-4009-8000-000000910000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.62,
    TRUE
),
(
    '001e8a81-001e-48a8-8001-001e8a81001e',
    '000f43f0-000f-443f-8000-000f43f0000f',
    '00000092-0000-4009-8000-000000920000',
    'Classic Burger',
    'Beef patty with lettuce, tomato, onion',
    11.86,
    TRUE
),
(
    '001e8a82-001e-48a8-8001-001e8a82001e',
    '000f43f0-000f-443f-8000-000f43f0000f',
    '00000092-0000-4009-8000-000000920000',
    'Cheeseburger',
    'Beef patty with cheese and special sauce',
    11.26,
    TRUE
),
(
    '001e8a83-001e-48a8-8001-001e8a83001e',
    '000f43f0-000f-443f-8000-000f43f0000f',
    '00000092-0000-4009-8000-000000920000',
    'Chicken Burger',
    'Grilled chicken breast with fixings',
    10.86,
    TRUE
),
(
    '001e8a84-001e-48a8-8001-001e8a84001e',
    '000f43f0-000f-443f-8000-000f43f0000f',
    '00000092-0000-4009-8000-000000920000',
    'Veggie Burger',
    'Plant-based patty with vegetables',
    10.76,
    TRUE
),
(
    '001e8a85-001e-48a8-8001-001e8a85001e',
    '000f43f1-000f-443f-8000-000f43f1000f',
    '00000092-0000-4009-8000-000000920000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.32,
    TRUE
),
(
    '001e8a86-001e-48a8-8001-001e8a86001e',
    '000f43f1-000f-443f-8000-000f43f1000f',
    '00000092-0000-4009-8000-000000920000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.35,
    TRUE
),
(
    '001e8a87-001e-48a8-8001-001e8a87001e',
    '000f43f1-000f-443f-8000-000f43f1000f',
    '00000092-0000-4009-8000-000000920000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.50,
    TRUE
),
(
    '001e8a88-001e-48a8-8001-001e8a88001e',
    '000f43f1-000f-443f-8000-000f43f1000f',
    '00000092-0000-4009-8000-000000920000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.65,
    TRUE
),
(
    '001e8a89-001e-48a8-8001-001e8a89001e',
    '000f43f2-000f-443f-8000-000f43f2000f',
    '00000093-0000-4009-8000-000000930000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.46,
    TRUE
),
(
    '001e8a8a-001e-48a8-8001-001e8a8a001e',
    '000f43f2-000f-443f-8000-000f43f2000f',
    '00000093-0000-4009-8000-000000930000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.35,
    TRUE
),
(
    '001e8a8b-001e-48a8-8001-001e8a8b001e',
    '000f43f2-000f-443f-8000-000f43f2000f',
    '00000093-0000-4009-8000-000000930000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.15,
    TRUE
),
(
    '001e8a8c-001e-48a8-8001-001e8a8c001e',
    '000f43f3-000f-443f-8000-000f43f3000f',
    '00000093-0000-4009-8000-000000930000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.14,
    TRUE
),
(
    '001e8a8d-001e-48a8-8001-001e8a8d001e',
    '000f43f3-000f-443f-8000-000f43f3000f',
    '00000093-0000-4009-8000-000000930000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.22,
    TRUE
),
(
    '001e8a8e-001e-48a8-8001-001e8a8e001e',
    '000f43f3-000f-443f-8000-000f43f3000f',
    '00000093-0000-4009-8000-000000930000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.83,
    TRUE
),
(
    '001e8a8f-001e-48a8-8001-001e8a8f001e',
    '000f43f4-000f-443f-8000-000f43f4000f',
    '00000093-0000-4009-8000-000000930000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.64,
    TRUE
),
(
    '001e8a90-001e-48a9-8001-001e8a90001e',
    '000f43f4-000f-443f-8000-000f43f4000f',
    '00000093-0000-4009-8000-000000930000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.65,
    TRUE
),
(
    '001e8a91-001e-48a9-8001-001e8a91001e',
    '000f43f4-000f-443f-8000-000f43f4000f',
    '00000093-0000-4009-8000-000000930000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.72,
    TRUE
),
(
    '001e8a92-001e-48a9-8001-001e8a92001e',
    '000f43f5-000f-443f-8000-000f43f5000f',
    '00000094-0000-4009-8000-000000940000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.94,
    TRUE
),
(
    '001e8a93-001e-48a9-8001-001e8a93001e',
    '000f43f5-000f-443f-8000-000f43f5000f',
    '00000094-0000-4009-8000-000000940000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.38,
    TRUE
),
(
    '001e8a94-001e-48a9-8001-001e8a94001e',
    '000f43f5-000f-443f-8000-000f43f5000f',
    '00000094-0000-4009-8000-000000940000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.65,
    TRUE
),
(
    '001e8a95-001e-48a9-8001-001e8a95001e',
    '000f43f5-000f-443f-8000-000f43f5000f',
    '00000094-0000-4009-8000-000000940000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.25,
    TRUE
),
(
    '001e8a96-001e-48a9-8001-001e8a96001e',
    '000f43f6-000f-443f-8000-000f43f6000f',
    '00000094-0000-4009-8000-000000940000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.23,
    TRUE
),
(
    '001e8a97-001e-48a9-8001-001e8a97001e',
    '000f43f6-000f-443f-8000-000f43f6000f',
    '00000094-0000-4009-8000-000000940000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.55,
    TRUE
),
(
    '001e8a98-001e-48a9-8001-001e8a98001e',
    '000f43f6-000f-443f-8000-000f43f6000f',
    '00000094-0000-4009-8000-000000940000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.48,
    TRUE
),
(
    '001e8a99-001e-48a9-8001-001e8a99001e',
    '000f43f6-000f-443f-8000-000f43f6000f',
    '00000094-0000-4009-8000-000000940000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.26,
    TRUE
),
(
    '001e8a9a-001e-48a9-8001-001e8a9a001e',
    '000f43f7-000f-443f-8000-000f43f7000f',
    '00000095-0000-4009-8000-000000950000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.60,
    TRUE
),
(
    '001e8a9b-001e-48a9-8001-001e8a9b001e',
    '000f43f7-000f-443f-8000-000f43f7000f',
    '00000095-0000-4009-8000-000000950000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.03,
    TRUE
),
(
    '001e8a9c-001e-48a9-8001-001e8a9c001e',
    '000f43f7-000f-443f-8000-000f43f7000f',
    '00000095-0000-4009-8000-000000950000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.53,
    TRUE
),
(
    '001e8a9d-001e-48a9-8001-001e8a9d001e',
    '000f43f7-000f-443f-8000-000f43f7000f',
    '00000095-0000-4009-8000-000000950000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.75,
    TRUE
),
(
    '001e8a9e-001e-48a9-8001-001e8a9e001e',
    '000f43f8-000f-443f-8000-000f43f8000f',
    '00000095-0000-4009-8000-000000950000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.33,
    TRUE
),
(
    '001e8a9f-001e-48a9-8001-001e8a9f001e',
    '000f43f8-000f-443f-8000-000f43f8000f',
    '00000095-0000-4009-8000-000000950000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.59,
    TRUE
),
(
    '001e8aa0-001e-48aa-8001-001e8aa0001e',
    '000f43f8-000f-443f-8000-000f43f8000f',
    '00000095-0000-4009-8000-000000950000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.05,
    TRUE
),
(
    '001e8aa1-001e-48aa-8001-001e8aa1001e',
    '000f43f8-000f-443f-8000-000f43f8000f',
    '00000095-0000-4009-8000-000000950000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.87,
    TRUE
),
(
    '001e8aa2-001e-48aa-8001-001e8aa2001e',
    '000f43f9-000f-443f-8000-000f43f9000f',
    '00000095-0000-4009-8000-000000950000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    14.91,
    TRUE
),
(
    '001e8aa3-001e-48aa-8001-001e8aa3001e',
    '000f43f9-000f-443f-8000-000f43f9000f',
    '00000095-0000-4009-8000-000000950000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.81,
    TRUE
),
(
    '001e8aa4-001e-48aa-8001-001e8aa4001e',
    '000f43f9-000f-443f-8000-000f43f9000f',
    '00000095-0000-4009-8000-000000950000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    12.04,
    TRUE
),
(
    '001e8aa5-001e-48aa-8001-001e8aa5001e',
    '000f43f9-000f-443f-8000-000f43f9000f',
    '00000095-0000-4009-8000-000000950000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    11.16,
    TRUE
),
(
    '001e8aa6-001e-48aa-8001-001e8aa6001e',
    '000f43f9-000f-443f-8000-000f43f9000f',
    '00000095-0000-4009-8000-000000950000',
    'Pad Thai',
    'Thai-style stir-fried noodles',
    12.14,
    TRUE
),
(
    '001e8aa7-001e-48aa-8001-001e8aa7001e',
    '000f43fa-000f-443f-8000-000f43fa000f',
    '00000096-0000-4009-8000-000000960000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.84,
    TRUE
),
(
    '001e8aa8-001e-48aa-8001-001e8aa8001e',
    '000f43fa-000f-443f-8000-000f43fa000f',
    '00000096-0000-4009-8000-000000960000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.22,
    TRUE
),
(
    '001e8aa9-001e-48aa-8001-001e8aa9001e',
    '000f43fa-000f-443f-8000-000f43fa000f',
    '00000096-0000-4009-8000-000000960000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.93,
    TRUE
),
(
    '001e8aaa-001e-48aa-8001-001e8aaa001e',
    '000f43fa-000f-443f-8000-000f43fa000f',
    '00000096-0000-4009-8000-000000960000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.02,
    TRUE
),
(
    '001e8aab-001e-48aa-8001-001e8aab001e',
    '000f43fb-000f-443f-8000-000f43fb000f',
    '00000096-0000-4009-8000-000000960000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.67,
    TRUE
),
(
    '001e8aac-001e-48aa-8001-001e8aac001e',
    '000f43fb-000f-443f-8000-000f43fb000f',
    '00000096-0000-4009-8000-000000960000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.00,
    TRUE
),
(
    '001e8aad-001e-48aa-8001-001e8aad001e',
    '000f43fb-000f-443f-8000-000f43fb000f',
    '00000096-0000-4009-8000-000000960000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.43,
    TRUE
),
(
    '001e8aae-001e-48aa-8001-001e8aae001e',
    '000f43fc-000f-443f-8000-000f43fc000f',
    '00000096-0000-4009-8000-000000960000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.65,
    TRUE
),
(
    '001e8aaf-001e-48aa-8001-001e8aaf001e',
    '000f43fc-000f-443f-8000-000f43fc000f',
    '00000096-0000-4009-8000-000000960000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.89,
    TRUE
),
(
    '001e8ab0-001e-48ab-8001-001e8ab0001e',
    '000f43fc-000f-443f-8000-000f43fc000f',
    '00000096-0000-4009-8000-000000960000',
    'Risotto',
    'Creamy Italian rice dish',
    13.55,
    TRUE
),
(
    '001e8ab1-001e-48ab-8001-001e8ab1001e',
    '000f43fd-000f-443f-8000-000f43fd000f',
    '00000097-0000-4009-8000-000000970000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.12,
    TRUE
),
(
    '001e8ab2-001e-48ab-8001-001e8ab2001e',
    '000f43fd-000f-443f-8000-000f43fd000f',
    '00000097-0000-4009-8000-000000970000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.69,
    TRUE
),
(
    '001e8ab3-001e-48ab-8001-001e8ab3001e',
    '000f43fd-000f-443f-8000-000f43fd000f',
    '00000097-0000-4009-8000-000000970000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.84,
    TRUE
),
(
    '001e8ab4-001e-48ab-8001-001e8ab4001e',
    '000f43fd-000f-443f-8000-000f43fd000f',
    '00000097-0000-4009-8000-000000970000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.64,
    TRUE
),
(
    '001e8ab5-001e-48ab-8001-001e8ab5001e',
    '000f43fe-000f-443f-8000-000f43fe000f',
    '00000097-0000-4009-8000-000000970000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.88,
    TRUE
),
(
    '001e8ab6-001e-48ab-8001-001e8ab6001e',
    '000f43fe-000f-443f-8000-000f43fe000f',
    '00000097-0000-4009-8000-000000970000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.03,
    TRUE
),
(
    '001e8ab7-001e-48ab-8001-001e8ab7001e',
    '000f43fe-000f-443f-8000-000f43fe000f',
    '00000097-0000-4009-8000-000000970000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.47,
    TRUE
),
(
    '001e8ab8-001e-48ab-8001-001e8ab8001e',
    '000f43fe-000f-443f-8000-000f43fe000f',
    '00000097-0000-4009-8000-000000970000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.49,
    TRUE
),
(
    '001e8ab9-001e-48ab-8001-001e8ab9001e',
    '000f43ff-000f-443f-8000-000f43ff000f',
    '00000098-0000-4009-8000-000000980000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.77,
    TRUE
),
(
    '001e8aba-001e-48ab-8001-001e8aba001e',
    '000f43ff-000f-443f-8000-000f43ff000f',
    '00000098-0000-4009-8000-000000980000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.43,
    TRUE
),
(
    '001e8abb-001e-48ab-8001-001e8abb001e',
    '000f43ff-000f-443f-8000-000f43ff000f',
    '00000098-0000-4009-8000-000000980000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.58,
    TRUE
),
(
    '001e8abc-001e-48ab-8001-001e8abc001e',
    '000f43ff-000f-443f-8000-000f43ff000f',
    '00000098-0000-4009-8000-000000980000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.32,
    TRUE
),
(
    '001e8abd-001e-48ab-8001-001e8abd001e',
    '000f4400-000f-4440-8000-000f4400000f',
    '00000098-0000-4009-8000-000000980000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.42,
    TRUE
),
(
    '001e8abe-001e-48ab-8001-001e8abe001e',
    '000f4400-000f-4440-8000-000f4400000f',
    '00000098-0000-4009-8000-000000980000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.66,
    TRUE
),
(
    '001e8abf-001e-48ab-8001-001e8abf001e',
    '000f4400-000f-4440-8000-000f4400000f',
    '00000098-0000-4009-8000-000000980000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.91,
    TRUE
),
(
    '001e8ac0-001e-48ac-8001-001e8ac0001e',
    '000f4401-000f-4440-8000-000f4401000f',
    '00000098-0000-4009-8000-000000980000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.03,
    TRUE
),
(
    '001e8ac1-001e-48ac-8001-001e8ac1001e',
    '000f4401-000f-4440-8000-000f4401000f',
    '00000098-0000-4009-8000-000000980000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.26,
    TRUE
),
(
    '001e8ac2-001e-48ac-8001-001e8ac2001e',
    '000f4401-000f-4440-8000-000f4401000f',
    '00000098-0000-4009-8000-000000980000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.06,
    TRUE
),
(
    '001e8ac3-001e-48ac-8001-001e8ac3001e',
    '000f4402-000f-4440-8000-000f4402000f',
    '00000098-0000-4009-8000-000000980000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.92,
    TRUE
),
(
    '001e8ac4-001e-48ac-8001-001e8ac4001e',
    '000f4402-000f-4440-8000-000f4402000f',
    '00000098-0000-4009-8000-000000980000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.73,
    TRUE
),
(
    '001e8ac5-001e-48ac-8001-001e8ac5001e',
    '000f4402-000f-4440-8000-000f4402000f',
    '00000098-0000-4009-8000-000000980000',
    'Cheesecake',
    'New York style cheesecake',
    7.87,
    TRUE
),
(
    '001e8ac6-001e-48ac-8001-001e8ac6001e',
    '000f4402-000f-4440-8000-000f4402000f',
    '00000098-0000-4009-8000-000000980000',
    'Tiramisu',
    'Classic Italian dessert',
    8.40,
    TRUE
),
(
    '001e8ac7-001e-48ac-8001-001e8ac7001e',
    '000f4403-000f-4440-8000-000f4403000f',
    '00000099-0000-4009-8000-000000990000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.23,
    TRUE
),
(
    '001e8ac8-001e-48ac-8001-001e8ac8001e',
    '000f4403-000f-4440-8000-000f4403000f',
    '00000099-0000-4009-8000-000000990000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.67,
    TRUE
),
(
    '001e8ac9-001e-48ac-8001-001e8ac9001e',
    '000f4403-000f-4440-8000-000f4403000f',
    '00000099-0000-4009-8000-000000990000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.82,
    TRUE
),
(
    '001e8aca-001e-48ac-8001-001e8aca001e',
    '000f4403-000f-4440-8000-000f4403000f',
    '00000099-0000-4009-8000-000000990000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.70,
    TRUE
),
(
    '001e8acb-001e-48ac-8001-001e8acb001e',
    '000f4404-000f-4440-8000-000f4404000f',
    '00000099-0000-4009-8000-000000990000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.39,
    TRUE
),
(
    '001e8acc-001e-48ac-8001-001e8acc001e',
    '000f4404-000f-4440-8000-000f4404000f',
    '00000099-0000-4009-8000-000000990000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.18,
    TRUE
),
(
    '001e8acd-001e-48ac-8001-001e8acd001e',
    '000f4404-000f-4440-8000-000f4404000f',
    '00000099-0000-4009-8000-000000990000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.59,
    TRUE
),
(
    '001e8ace-001e-48ac-8001-001e8ace001e',
    '000f4405-000f-4440-8000-000f4405000f',
    '00000099-0000-4009-8000-000000990000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.72,
    TRUE
),
(
    '001e8acf-001e-48ac-8001-001e8acf001e',
    '000f4405-000f-4440-8000-000f4405000f',
    '00000099-0000-4009-8000-000000990000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.68,
    TRUE
),
(
    '001e8ad0-001e-48ad-8001-001e8ad0001e',
    '000f4405-000f-4440-8000-000f4405000f',
    '00000099-0000-4009-8000-000000990000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.83,
    TRUE
),
(
    '001e8ad1-001e-48ad-8001-001e8ad1001e',
    '000f4406-000f-4440-8000-000f4406000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.76,
    TRUE
),
(
    '001e8ad2-001e-48ad-8001-001e8ad2001e',
    '000f4406-000f-4440-8000-000f4406000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.00,
    TRUE
),
(
    '001e8ad3-001e-48ad-8001-001e8ad3001e',
    '000f4406-000f-4440-8000-000f4406000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.77,
    TRUE
),
(
    '001e8ad4-001e-48ad-8001-001e8ad4001e',
    '000f4407-000f-4440-8000-000f4407000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.32,
    TRUE
),
(
    '001e8ad5-001e-48ad-8001-001e8ad5001e',
    '000f4407-000f-4440-8000-000f4407000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.04,
    TRUE
),
(
    '001e8ad6-001e-48ad-8001-001e8ad6001e',
    '000f4407-000f-4440-8000-000f4407000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.79,
    TRUE
),
(
    '001e8ad7-001e-48ad-8001-001e8ad7001e',
    '000f4407-000f-4440-8000-000f4407000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.56,
    TRUE
),
(
    '001e8ad8-001e-48ad-8001-001e8ad8001e',
    '000f4408-000f-4440-8000-000f4408000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.30,
    TRUE
),
(
    '001e8ad9-001e-48ad-8001-001e8ad9001e',
    '000f4408-000f-4440-8000-000f4408000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.02,
    TRUE
),
(
    '001e8ada-001e-48ad-8001-001e8ada001e',
    '000f4408-000f-4440-8000-000f4408000f',
    '0000009a-0000-4009-8000-0000009a0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.98,
    TRUE
),
(
    '001e8adb-001e-48ad-8001-001e8adb001e',
    '000f4409-000f-4440-8000-000f4409000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.40,
    TRUE
),
(
    '001e8adc-001e-48ad-8001-001e8adc001e',
    '000f4409-000f-4440-8000-000f4409000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.04,
    TRUE
),
(
    '001e8add-001e-48ad-8001-001e8add001e',
    '000f4409-000f-4440-8000-000f4409000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.65,
    TRUE
),
(
    '001e8ade-001e-48ad-8001-001e8ade001e',
    '000f4409-000f-4440-8000-000f4409000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.88,
    TRUE
),
(
    '001e8adf-001e-48ad-8001-001e8adf001e',
    '000f440a-000f-4440-8000-000f440a000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.69,
    TRUE
),
(
    '001e8ae0-001e-48ae-8001-001e8ae0001e',
    '000f440a-000f-4440-8000-000f440a000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.44,
    TRUE
),
(
    '001e8ae1-001e-48ae-8001-001e8ae1001e',
    '000f440a-000f-4440-8000-000f440a000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Risotto',
    'Creamy Italian rice dish',
    12.91,
    TRUE
),
(
    '001e8ae2-001e-48ae-8001-001e8ae2001e',
    '000f440b-000f-4440-8000-000f440b000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.32,
    TRUE
),
(
    '001e8ae3-001e-48ae-8001-001e8ae3001e',
    '000f440b-000f-4440-8000-000f440b000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.11,
    TRUE
),
(
    '001e8ae4-001e-48ae-8001-001e8ae4001e',
    '000f440b-000f-4440-8000-000f440b000f',
    '0000009b-0000-4009-8000-0000009b0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.34,
    TRUE
),
(
    '001e8ae5-001e-48ae-8001-001e8ae5001e',
    '000f440c-000f-4440-8000-000f440c000f',
    '0000009c-0000-4009-8000-0000009c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.48,
    TRUE
),
(
    '001e8ae6-001e-48ae-8001-001e8ae6001e',
    '000f440c-000f-4440-8000-000f440c000f',
    '0000009c-0000-4009-8000-0000009c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.67,
    TRUE
),
(
    '001e8ae7-001e-48ae-8001-001e8ae7001e',
    '000f440c-000f-4440-8000-000f440c000f',
    '0000009c-0000-4009-8000-0000009c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.64,
    TRUE
),
(
    '001e8ae8-001e-48ae-8001-001e8ae8001e',
    '000f440c-000f-4440-8000-000f440c000f',
    '0000009c-0000-4009-8000-0000009c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.87,
    TRUE
),
(
    '001e8ae9-001e-48ae-8001-001e8ae9001e',
    '000f440d-000f-4440-8000-000f440d000f',
    '0000009c-0000-4009-8000-0000009c0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.85,
    TRUE
),
(
    '001e8aea-001e-48ae-8001-001e8aea001e',
    '000f440d-000f-4440-8000-000f440d000f',
    '0000009c-0000-4009-8000-0000009c0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.38,
    TRUE
),
(
    '001e8aeb-001e-48ae-8001-001e8aeb001e',
    '000f440d-000f-4440-8000-000f440d000f',
    '0000009c-0000-4009-8000-0000009c0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.04,
    TRUE
),
(
    '001e8aec-001e-48ae-8001-001e8aec001e',
    '000f440d-000f-4440-8000-000f440d000f',
    '0000009c-0000-4009-8000-0000009c0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.01,
    TRUE
),
(
    '001e8aed-001e-48ae-8001-001e8aed001e',
    '000f440e-000f-4440-8000-000f440e000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.41,
    TRUE
),
(
    '001e8aee-001e-48ae-8001-001e8aee001e',
    '000f440e-000f-4440-8000-000f440e000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.31,
    TRUE
),
(
    '001e8aef-001e-48ae-8001-001e8aef001e',
    '000f440e-000f-4440-8000-000f440e000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.64,
    TRUE
),
(
    '001e8af0-001e-48af-8001-001e8af0001e',
    '000f440e-000f-4440-8000-000f440e000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.93,
    TRUE
),
(
    '001e8af1-001e-48af-8001-001e8af1001e',
    '000f440f-000f-4440-8000-000f440f000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.27,
    TRUE
),
(
    '001e8af2-001e-48af-8001-001e8af2001e',
    '000f440f-000f-4440-8000-000f440f000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.58,
    TRUE
),
(
    '001e8af3-001e-48af-8001-001e8af3001e',
    '000f440f-000f-4440-8000-000f440f000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.51,
    TRUE
),
(
    '001e8af4-001e-48af-8001-001e8af4001e',
    '000f4410-000f-4441-8000-000f4410000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'French Fries',
    'Crispy golden fries',
    4.11,
    TRUE
),
(
    '001e8af5-001e-48af-8001-001e8af5001e',
    '000f4410-000f-4441-8000-000f4410000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Onion Rings',
    'Battered and fried onion rings',
    5.61,
    TRUE
),
(
    '001e8af6-001e-48af-8001-001e8af6001e',
    '000f4410-000f-4441-8000-000f4410000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Coleslaw',
    'Fresh cabbage salad',
    3.66,
    TRUE
),
(
    '001e8af7-001e-48af-8001-001e8af7001e',
    '000f4411-000f-4441-8000-000f4411000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.06,
    TRUE
),
(
    '001e8af8-001e-48af-8001-001e8af8001e',
    '000f4411-000f-4441-8000-000f4411000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.36,
    TRUE
),
(
    '001e8af9-001e-48af-8001-001e8af9001e',
    '000f4411-000f-4441-8000-000f4411000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Cheesecake',
    'New York style cheesecake',
    7.30,
    TRUE
),
(
    '001e8afa-001e-48af-8001-001e8afa001e',
    '000f4411-000f-4441-8000-000f4411000f',
    '0000009d-0000-4009-8000-0000009d0000',
    'Tiramisu',
    'Classic Italian dessert',
    6.63,
    TRUE
),
(
    '001e8afb-001e-48af-8001-001e8afb001e',
    '000f4412-000f-4441-8000-000f4412000f',
    '0000009e-0000-4009-8000-0000009e0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.75,
    TRUE
),
(
    '001e8afc-001e-48af-8001-001e8afc001e',
    '000f4412-000f-4441-8000-000f4412000f',
    '0000009e-0000-4009-8000-0000009e0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.46,
    TRUE
),
(
    '001e8afd-001e-48af-8001-001e8afd001e',
    '000f4412-000f-4441-8000-000f4412000f',
    '0000009e-0000-4009-8000-0000009e0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.07,
    TRUE
),
(
    '001e8afe-001e-48af-8001-001e8afe001e',
    '000f4412-000f-4441-8000-000f4412000f',
    '0000009e-0000-4009-8000-0000009e0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.86,
    TRUE
),
(
    '001e8aff-001e-48af-8001-001e8aff001e',
    '000f4413-000f-4441-8000-000f4413000f',
    '0000009e-0000-4009-8000-0000009e0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.09,
    TRUE
),
(
    '001e8b00-001e-48b0-8001-001e8b00001e',
    '000f4413-000f-4441-8000-000f4413000f',
    '0000009e-0000-4009-8000-0000009e0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.70,
    TRUE
),
(
    '001e8b01-001e-48b0-8001-001e8b01001e',
    '000f4413-000f-4441-8000-000f4413000f',
    '0000009e-0000-4009-8000-0000009e0000',
    'Risotto',
    'Creamy Italian rice dish',
    13.32,
    TRUE
),
(
    '001e8b02-001e-48b0-8001-001e8b02001e',
    '000f4414-000f-4441-8000-000f4414000f',
    '0000009f-0000-4009-8000-0000009f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.03,
    TRUE
),
(
    '001e8b03-001e-48b0-8001-001e8b03001e',
    '000f4414-000f-4441-8000-000f4414000f',
    '0000009f-0000-4009-8000-0000009f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.62,
    TRUE
),
(
    '001e8b04-001e-48b0-8001-001e8b04001e',
    '000f4414-000f-4441-8000-000f4414000f',
    '0000009f-0000-4009-8000-0000009f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.25,
    TRUE
),
(
    '001e8b05-001e-48b0-8001-001e8b05001e',
    '000f4414-000f-4441-8000-000f4414000f',
    '0000009f-0000-4009-8000-0000009f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.67,
    TRUE
),
(
    '001e8b06-001e-48b0-8001-001e8b06001e',
    '000f4415-000f-4441-8000-000f4415000f',
    '0000009f-0000-4009-8000-0000009f0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.32,
    TRUE
),
(
    '001e8b07-001e-48b0-8001-001e8b07001e',
    '000f4415-000f-4441-8000-000f4415000f',
    '0000009f-0000-4009-8000-0000009f0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.10,
    TRUE
),
(
    '001e8b08-001e-48b0-8001-001e8b08001e',
    '000f4415-000f-4441-8000-000f4415000f',
    '0000009f-0000-4009-8000-0000009f0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.11,
    TRUE
),
(
    '001e8b09-001e-48b0-8001-001e8b09001e',
    '000f4415-000f-4441-8000-000f4415000f',
    '0000009f-0000-4009-8000-0000009f0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.99,
    TRUE
),
(
    '001e8b0a-001e-48b0-8001-001e8b0a001e',
    '000f4416-000f-4441-8000-000f4416000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    13.49,
    TRUE
),
(
    '001e8b0b-001e-48b0-8001-001e8b0b001e',
    '000f4416-000f-4441-8000-000f4416000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    15.71,
    TRUE
),
(
    '001e8b0c-001e-48b0-8001-001e8b0c001e',
    '000f4416-000f-4441-8000-000f4416000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives',
    15.01,
    TRUE
),
(
    '001e8b0d-001e-48b0-8001-001e8b0d001e',
    '000f4416-000f-4441-8000-000f4416000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Hawaiian',
    'Ham, pineapple, mozzarella',
    13.20,
    TRUE
),
(
    '001e8b0e-001e-48b0-8001-001e8b0e001e',
    '000f4417-000f-4441-8000-000f4417000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino',
    13.88,
    TRUE
),
(
    '001e8b0f-001e-48b0-8001-001e8b0f001e',
    '000f4417-000f-4441-8000-000f4417000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    11.98,
    TRUE
),
(
    '001e8b10-001e-48b1-8001-001e8b10001e',
    '000f4417-000f-4441-8000-000f4417000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream',
    12.57,
    TRUE
),
(
    '001e8b11-001e-48b1-8001-001e8b11001e',
    '000f4418-000f-4441-8000-000f4418000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.97,
    TRUE
),
(
    '001e8b12-001e-48b1-8001-001e8b12001e',
    '000f4418-000f-4441-8000-000f4418000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.78,
    TRUE
),
(
    '001e8b13-001e-48b1-8001-001e8b13001e',
    '000f4418-000f-4441-8000-000f4418000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.52,
    TRUE
),
(
    '001e8b14-001e-48b1-8001-001e8b14001e',
    '000f4418-000f-4441-8000-000f4418000f',
    '000000a0-0000-400a-8000-000000a00000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.44,
    TRUE
),
(
    '001e8b15-001e-48b1-8001-001e8b15001e',
    '000f4419-000f-4441-8000-000f4419000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Har Gow',
    'Steamed shrimp dumplings',
    9.49,
    TRUE
),
(
    '001e8b16-001e-48b1-8001-001e8b16001e',
    '000f4419-000f-4441-8000-000f4419000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    9.09,
    TRUE
),
(
    '001e8b17-001e-48b1-8001-001e8b17001e',
    '000f4419-000f-4441-8000-000f4419000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    8.29,
    TRUE
),
(
    '001e8b18-001e-48b1-8001-001e8b18001e',
    '000f441a-000f-4441-8000-000f441a000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    14.81,
    TRUE
),
(
    '001e8b19-001e-48b1-8001-001e8b19001e',
    '000f441a-000f-4441-8000-000f441a000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.90,
    TRUE
),
(
    '001e8b1a-001e-48b1-8001-001e8b1a001e',
    '000f441a-000f-4441-8000-000f441a000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.88,
    TRUE
),
(
    '001e8b1b-001e-48b1-8001-001e8b1b001e',
    '000f441b-000f-4441-8000-000f441b000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.72,
    TRUE
),
(
    '001e8b1c-001e-48b1-8001-001e8b1c001e',
    '000f441b-000f-4441-8000-000f441b000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.10,
    TRUE
),
(
    '001e8b1d-001e-48b1-8001-001e8b1d001e',
    '000f441b-000f-4441-8000-000f441b000f',
    '000000a1-0000-400a-8000-000000a10000',
    'Risotto',
    'Creamy Italian rice dish',
    12.80,
    TRUE
),
(
    '001e8b1e-001e-48b1-8001-001e8b1e001e',
    '000f441c-000f-4441-8000-000f441c000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Beef Tacos',
    'Seasoned ground beef with lettuce and cheese',
    9.47,
    TRUE
),
(
    '001e8b1f-001e-48b1-8001-001e8b1f001e',
    '000f441c-000f-4441-8000-000f441c000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Chicken Tacos',
    'Grilled chicken with salsa and avocado',
    10.83,
    TRUE
),
(
    '001e8b20-001e-48b2-8001-001e8b20001e',
    '000f441c-000f-4441-8000-000f441c000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Fish Tacos',
    'Battered fish with cabbage slaw',
    11.75,
    TRUE
),
(
    '001e8b21-001e-48b2-8001-001e8b21001e',
    '000f441d-000f-4441-8000-000f441d000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.56,
    TRUE
),
(
    '001e8b22-001e-48b2-8001-001e8b22001e',
    '000f441d-000f-4441-8000-000f441d000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.34,
    TRUE
),
(
    '001e8b23-001e-48b2-8001-001e8b23001e',
    '000f441d-000f-4441-8000-000f441d000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.02,
    TRUE
),
(
    '001e8b24-001e-48b2-8001-001e8b24001e',
    '000f441e-000f-4441-8000-000f441e000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.10,
    TRUE
),
(
    '001e8b25-001e-48b2-8001-001e8b25001e',
    '000f441e-000f-4441-8000-000f441e000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.52,
    TRUE
),
(
    '001e8b26-001e-48b2-8001-001e8b26001e',
    '000f441e-000f-4441-8000-000f441e000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.50,
    TRUE
),
(
    '001e8b27-001e-48b2-8001-001e8b27001e',
    '000f441e-000f-4441-8000-000f441e000f',
    '000000a2-0000-400a-8000-000000a20000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.94,
    TRUE
),
(
    '001e8b28-001e-48b2-8001-001e8b28001e',
    '000f441f-000f-4441-8000-000f441f000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    14.68,
    TRUE
),
(
    '001e8b29-001e-48b2-8001-001e8b29001e',
    '000f441f-000f-4441-8000-000f441f000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.67,
    TRUE
),
(
    '001e8b2a-001e-48b2-8001-001e8b2a001e',
    '000f441f-000f-4441-8000-000f441f000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.63,
    TRUE
),
(
    '001e8b2b-001e-48b2-8001-001e8b2b001e',
    '000f4420-000f-4442-8000-000f4420000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.07,
    TRUE
),
(
    '001e8b2c-001e-48b2-8001-001e8b2c001e',
    '000f4420-000f-4442-8000-000f4420000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.08,
    TRUE
),
(
    '001e8b2d-001e-48b2-8001-001e8b2d001e',
    '000f4420-000f-4442-8000-000f4420000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.58,
    TRUE
),
(
    '001e8b2e-001e-48b2-8001-001e8b2e001e',
    '000f4420-000f-4442-8000-000f4420000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.96,
    TRUE
),
(
    '001e8b2f-001e-48b2-8001-001e8b2f001e',
    '000f4421-000f-4442-8000-000f4421000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.36,
    TRUE
),
(
    '001e8b30-001e-48b3-8001-001e8b30001e',
    '000f4421-000f-4442-8000-000f4421000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.30,
    TRUE
),
(
    '001e8b31-001e-48b3-8001-001e8b31001e',
    '000f4421-000f-4442-8000-000f4421000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.44,
    TRUE
),
(
    '001e8b32-001e-48b3-8001-001e8b32001e',
    '000f4421-000f-4442-8000-000f4421000f',
    '000000a3-0000-400a-8000-000000a30000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.28,
    TRUE
),
(
    '001e8b33-001e-48b3-8001-001e8b33001e',
    '000f4422-000f-4442-8000-000f4422000f',
    '000000a4-0000-400a-8000-000000a40000',
    'Salmon Roll',
    'Fresh salmon with rice and nori',
    9.98,
    TRUE
),
(
    '001e8b34-001e-48b3-8001-001e8b34001e',
    '000f4422-000f-4442-8000-000f4422000f',
    '000000a4-0000-400a-8000-000000a40000',
    'Tuna Roll',
    'Premium tuna with rice and nori',
    10.58,
    TRUE
),
(
    '001e8b35-001e-48b3-8001-001e8b35001e',
    '000f4422-000f-4442-8000-000f4422000f',
    '000000a4-0000-400a-8000-000000a40000',
    'California Roll',
    'Crab, avocado, and cucumber',
    7.36,
    TRUE
),
(
    '001e8b36-001e-48b3-8001-001e8b36001e',
    '000f4423-000f-4442-8000-000f4423000f',
    '000000a4-0000-400a-8000-000000a40000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.65,
    TRUE
),
(
    '001e8b37-001e-48b3-8001-001e8b37001e',
    '000f4423-000f-4442-8000-000f4423000f',
    '000000a4-0000-400a-8000-000000a40000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.45,
    TRUE
),
(
    '001e8b38-001e-48b3-8001-001e8b38001e',
    '000f4423-000f-4442-8000-000f4423000f',
    '000000a4-0000-400a-8000-000000a40000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.31,
    TRUE
),
(
    '001e8b39-001e-48b3-8001-001e8b39001e',
    '000f4423-000f-4442-8000-000f4423000f',
    '000000a4-0000-400a-8000-000000a40000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.26,
    TRUE
),
(
    '001e8b3a-001e-48b3-8001-001e8b3a001e',
    '000f4424-000f-4442-8000-000f4424000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    13.27,
    TRUE
),
(
    '001e8b3b-001e-48b3-8001-001e8b3b001e',
    '000f4424-000f-4442-8000-000f4424000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.02,
    TRUE
),
(
    '001e8b3c-001e-48b3-8001-001e8b3c001e',
    '000f4424-000f-4442-8000-000f4424000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.37,
    TRUE
),
(
    '001e8b3d-001e-48b3-8001-001e8b3d001e',
    '000f4424-000f-4442-8000-000f4424000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    15.20,
    TRUE
),
(
    '001e8b3e-001e-48b3-8001-001e8b3e001e',
    '000f4425-000f-4442-8000-000f4425000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.06,
    TRUE
),
(
    '001e8b3f-001e-48b3-8001-001e8b3f001e',
    '000f4425-000f-4442-8000-000f4425000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.05,
    TRUE
),
(
    '001e8b40-001e-48b4-8001-001e8b40001e',
    '000f4425-000f-4442-8000-000f4425000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.97,
    TRUE
),
(
    '001e8b41-001e-48b4-8001-001e8b41001e',
    '000f4425-000f-4442-8000-000f4425000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    12.01,
    TRUE
),
(
    '001e8b42-001e-48b4-8001-001e8b42001e',
    '000f4426-000f-4442-8000-000f4426000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.49,
    TRUE
),
(
    '001e8b43-001e-48b4-8001-001e8b43001e',
    '000f4426-000f-4442-8000-000f4426000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.52,
    TRUE
),
(
    '001e8b44-001e-48b4-8001-001e8b44001e',
    '000f4426-000f-4442-8000-000f4426000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.18,
    TRUE
),
(
    '001e8b45-001e-48b4-8001-001e8b45001e',
    '000f4426-000f-4442-8000-000f4426000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.58,
    TRUE
),
(
    '001e8b46-001e-48b4-8001-001e8b46001e',
    '000f4427-000f-4442-8000-000f4427000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.13,
    TRUE
),
(
    '001e8b47-001e-48b4-8001-001e8b47001e',
    '000f4427-000f-4442-8000-000f4427000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.29,
    TRUE
),
(
    '001e8b48-001e-48b4-8001-001e8b48001e',
    '000f4427-000f-4442-8000-000f4427000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.87,
    TRUE
),
(
    '001e8b49-001e-48b4-8001-001e8b49001e',
    '000f4427-000f-4442-8000-000f4427000f',
    '000000a5-0000-400a-8000-000000a50000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.36,
    TRUE
),
(
    '001e8b4a-001e-48b4-8001-001e8b4a001e',
    '000f4428-000f-4442-8000-000f4428000f',
    '000000a6-0000-400a-8000-000000a60000',
    'Classic Burger',
    'Beef patty with lettuce, tomato, onion',
    10.89,
    TRUE
),
(
    '001e8b4b-001e-48b4-8001-001e8b4b001e',
    '000f4428-000f-4442-8000-000f4428000f',
    '000000a6-0000-400a-8000-000000a60000',
    'Cheeseburger',
    'Beef patty with cheese and special sauce',
    12.20,
    TRUE
),
(
    '001e8b4c-001e-48b4-8001-001e8b4c001e',
    '000f4428-000f-4442-8000-000f4428000f',
    '000000a6-0000-400a-8000-000000a60000',
    'Chicken Burger',
    'Grilled chicken breast with fixings',
    10.00,
    TRUE
),
(
    '001e8b4d-001e-48b4-8001-001e8b4d001e',
    '000f4428-000f-4442-8000-000f4428000f',
    '000000a6-0000-400a-8000-000000a60000',
    'Veggie Burger',
    'Plant-based patty with vegetables',
    9.38,
    TRUE
),
(
    '001e8b4e-001e-48b4-8001-001e8b4e001e',
    '000f4429-000f-4442-8000-000f4429000f',
    '000000a6-0000-400a-8000-000000a60000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.53,
    TRUE
),
(
    '001e8b4f-001e-48b4-8001-001e8b4f001e',
    '000f4429-000f-4442-8000-000f4429000f',
    '000000a6-0000-400a-8000-000000a60000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.79,
    TRUE
),
(
    '001e8b50-001e-48b5-8001-001e8b50001e',
    '000f4429-000f-4442-8000-000f4429000f',
    '000000a6-0000-400a-8000-000000a60000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.53,
    TRUE
),
(
    '001e8b51-001e-48b5-8001-001e8b51001e',
    '000f4429-000f-4442-8000-000f4429000f',
    '000000a6-0000-400a-8000-000000a60000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.54,
    TRUE
),
(
    '001e8b52-001e-48b5-8001-001e8b52001e',
    '000f442a-000f-4442-8000-000f442a000f',
    '000000a7-0000-400a-8000-000000a70000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.24,
    TRUE
),
(
    '001e8b53-001e-48b5-8001-001e8b53001e',
    '000f442a-000f-4442-8000-000f442a000f',
    '000000a7-0000-400a-8000-000000a70000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.29,
    TRUE
),
(
    '001e8b54-001e-48b5-8001-001e8b54001e',
    '000f442a-000f-4442-8000-000f442a000f',
    '000000a7-0000-400a-8000-000000a70000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.18,
    TRUE
),
(
    '001e8b55-001e-48b5-8001-001e8b55001e',
    '000f442a-000f-4442-8000-000f442a000f',
    '000000a7-0000-400a-8000-000000a70000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.78,
    TRUE
),
(
    '001e8b56-001e-48b5-8001-001e8b56001e',
    '000f442b-000f-4442-8000-000f442b000f',
    '000000a7-0000-400a-8000-000000a70000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    8.48,
    TRUE
),
(
    '001e8b57-001e-48b5-8001-001e8b57001e',
    '000f442b-000f-4442-8000-000f442b000f',
    '000000a7-0000-400a-8000-000000a70000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.14,
    TRUE
),
(
    '001e8b58-001e-48b5-8001-001e8b58001e',
    '000f442b-000f-4442-8000-000f442b000f',
    '000000a7-0000-400a-8000-000000a70000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.39,
    TRUE
),
(
    '001e8b59-001e-48b5-8001-001e8b59001e',
    '000f442c-000f-4442-8000-000f442c000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.55,
    TRUE
),
(
    '001e8b5a-001e-48b5-8001-001e8b5a001e',
    '000f442c-000f-4442-8000-000f442c000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.54,
    TRUE
),
(
    '001e8b5b-001e-48b5-8001-001e8b5b001e',
    '000f442c-000f-4442-8000-000f442c000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.94,
    TRUE
),
(
    '001e8b5c-001e-48b5-8001-001e8b5c001e',
    '000f442d-000f-4442-8000-000f442d000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.98,
    TRUE
),
(
    '001e8b5d-001e-48b5-8001-001e8b5d001e',
    '000f442d-000f-4442-8000-000f442d000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.70,
    TRUE
),
(
    '001e8b5e-001e-48b5-8001-001e8b5e001e',
    '000f442d-000f-4442-8000-000f442d000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.08,
    TRUE
),
(
    '001e8b5f-001e-48b5-8001-001e8b5f001e',
    '000f442d-000f-4442-8000-000f442d000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.19,
    TRUE
),
(
    '001e8b60-001e-48b6-8001-001e8b60001e',
    '000f442e-000f-4442-8000-000f442e000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.77,
    TRUE
),
(
    '001e8b61-001e-48b6-8001-001e8b61001e',
    '000f442e-000f-4442-8000-000f442e000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.30,
    TRUE
),
(
    '001e8b62-001e-48b6-8001-001e8b62001e',
    '000f442e-000f-4442-8000-000f442e000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.19,
    TRUE
),
(
    '001e8b63-001e-48b6-8001-001e8b63001e',
    '000f442f-000f-4442-8000-000f442f000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.33,
    TRUE
),
(
    '001e8b64-001e-48b6-8001-001e8b64001e',
    '000f442f-000f-4442-8000-000f442f000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.72,
    TRUE
),
(
    '001e8b65-001e-48b6-8001-001e8b65001e',
    '000f442f-000f-4442-8000-000f442f000f',
    '000000a8-0000-400a-8000-000000a80000',
    'Cheesecake',
    'New York style cheesecake',
    8.20,
    TRUE
),
(
    '001e8b66-001e-48b6-8001-001e8b66001e',
    '000f4430-000f-4443-8000-000f4430000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.44,
    TRUE
),
(
    '001e8b67-001e-48b6-8001-001e8b67001e',
    '000f4430-000f-4443-8000-000f4430000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.58,
    TRUE
),
(
    '001e8b68-001e-48b6-8001-001e8b68001e',
    '000f4430-000f-4443-8000-000f4430000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.93,
    TRUE
),
(
    '001e8b69-001e-48b6-8001-001e8b69001e',
    '000f4431-000f-4443-8000-000f4431000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.28,
    TRUE
),
(
    '001e8b6a-001e-48b6-8001-001e8b6a001e',
    '000f4431-000f-4443-8000-000f4431000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.54,
    TRUE
),
(
    '001e8b6b-001e-48b6-8001-001e8b6b001e',
    '000f4431-000f-4443-8000-000f4431000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.93,
    TRUE
),
(
    '001e8b6c-001e-48b6-8001-001e8b6c001e',
    '000f4431-000f-4443-8000-000f4431000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.91,
    TRUE
),
(
    '001e8b6d-001e-48b6-8001-001e8b6d001e',
    '000f4432-000f-4443-8000-000f4432000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.30,
    TRUE
),
(
    '001e8b6e-001e-48b6-8001-001e8b6e001e',
    '000f4432-000f-4443-8000-000f4432000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.70,
    TRUE
),
(
    '001e8b6f-001e-48b6-8001-001e8b6f001e',
    '000f4432-000f-4443-8000-000f4432000f',
    '000000a9-0000-400a-8000-000000a90000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    10.66,
    TRUE
),
(
    '001e8b70-001e-48b7-8001-001e8b70001e',
    '000f4433-000f-4443-8000-000f4433000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.42,
    TRUE
),
(
    '001e8b71-001e-48b7-8001-001e8b71001e',
    '000f4433-000f-4443-8000-000f4433000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.25,
    TRUE
),
(
    '001e8b72-001e-48b7-8001-001e8b72001e',
    '000f4433-000f-4443-8000-000f4433000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.38,
    TRUE
),
(
    '001e8b73-001e-48b7-8001-001e8b73001e',
    '000f4433-000f-4443-8000-000f4433000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.91,
    TRUE
),
(
    '001e8b74-001e-48b7-8001-001e8b74001e',
    '000f4434-000f-4443-8000-000f4434000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.41,
    TRUE
),
(
    '001e8b75-001e-48b7-8001-001e8b75001e',
    '000f4434-000f-4443-8000-000f4434000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.63,
    TRUE
),
(
    '001e8b76-001e-48b7-8001-001e8b76001e',
    '000f4434-000f-4443-8000-000f4434000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.45,
    TRUE
),
(
    '001e8b77-001e-48b7-8001-001e8b77001e',
    '000f4435-000f-4443-8000-000f4435000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.75,
    TRUE
),
(
    '001e8b78-001e-48b7-8001-001e8b78001e',
    '000f4435-000f-4443-8000-000f4435000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.56,
    TRUE
),
(
    '001e8b79-001e-48b7-8001-001e8b79001e',
    '000f4435-000f-4443-8000-000f4435000f',
    '000000aa-0000-400a-8000-000000aa0000',
    'Risotto',
    'Creamy Italian rice dish',
    13.20,
    TRUE
),
(
    '001e8b7a-001e-48b7-8001-001e8b7a001e',
    '000f4436-000f-4443-8000-000f4436000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.86,
    TRUE
),
(
    '001e8b7b-001e-48b7-8001-001e8b7b001e',
    '000f4436-000f-4443-8000-000f4436000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.12,
    TRUE
),
(
    '001e8b7c-001e-48b7-8001-001e8b7c001e',
    '000f4436-000f-4443-8000-000f4436000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.82,
    TRUE
),
(
    '001e8b7d-001e-48b7-8001-001e8b7d001e',
    '000f4437-000f-4443-8000-000f4437000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.61,
    TRUE
),
(
    '001e8b7e-001e-48b7-8001-001e8b7e001e',
    '000f4437-000f-4443-8000-000f4437000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.46,
    TRUE
),
(
    '001e8b7f-001e-48b7-8001-001e8b7f001e',
    '000f4437-000f-4443-8000-000f4437000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.85,
    TRUE
),
(
    '001e8b80-001e-48b8-8001-001e8b80001e',
    '000f4437-000f-4443-8000-000f4437000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.83,
    TRUE
),
(
    '001e8b81-001e-48b8-8001-001e8b81001e',
    '000f4438-000f-4443-8000-000f4438000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.75,
    TRUE
),
(
    '001e8b82-001e-48b8-8001-001e8b82001e',
    '000f4438-000f-4443-8000-000f4438000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.03,
    TRUE
),
(
    '001e8b83-001e-48b8-8001-001e8b83001e',
    '000f4438-000f-4443-8000-000f4438000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.29,
    TRUE
),
(
    '001e8b84-001e-48b8-8001-001e8b84001e',
    '000f4439-000f-4443-8000-000f4439000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.93,
    TRUE
),
(
    '001e8b85-001e-48b8-8001-001e8b85001e',
    '000f4439-000f-4443-8000-000f4439000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.00,
    TRUE
),
(
    '001e8b86-001e-48b8-8001-001e8b86001e',
    '000f4439-000f-4443-8000-000f4439000f',
    '000000ab-0000-400a-8000-000000ab0000',
    'Cheesecake',
    'New York style cheesecake',
    8.73,
    TRUE
),
(
    '001e8b87-001e-48b8-8001-001e8b87001e',
    '000f443a-000f-4443-8000-000f443a000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.95,
    TRUE
),
(
    '001e8b88-001e-48b8-8001-001e8b88001e',
    '000f443a-000f-4443-8000-000f443a000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.07,
    TRUE
),
(
    '001e8b89-001e-48b8-8001-001e8b89001e',
    '000f443a-000f-4443-8000-000f443a000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.97,
    TRUE
),
(
    '001e8b8a-001e-48b8-8001-001e8b8a001e',
    '000f443a-000f-4443-8000-000f443a000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.64,
    TRUE
),
(
    '001e8b8b-001e-48b8-8001-001e8b8b001e',
    '000f443b-000f-4443-8000-000f443b000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.37,
    TRUE
),
(
    '001e8b8c-001e-48b8-8001-001e8b8c001e',
    '000f443b-000f-4443-8000-000f443b000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.08,
    TRUE
),
(
    '001e8b8d-001e-48b8-8001-001e8b8d001e',
    '000f443b-000f-4443-8000-000f443b000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.33,
    TRUE
),
(
    '001e8b8e-001e-48b8-8001-001e8b8e001e',
    '000f443b-000f-4443-8000-000f443b000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.11,
    TRUE
),
(
    '001e8b8f-001e-48b8-8001-001e8b8f001e',
    '000f443c-000f-4443-8000-000f443c000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.83,
    TRUE
),
(
    '001e8b90-001e-48b9-8001-001e8b90001e',
    '000f443c-000f-4443-8000-000f443c000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.12,
    TRUE
),
(
    '001e8b91-001e-48b9-8001-001e8b91001e',
    '000f443c-000f-4443-8000-000f443c000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.78,
    TRUE
),
(
    '001e8b92-001e-48b9-8001-001e8b92001e',
    '000f443d-000f-4443-8000-000f443d000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.66,
    TRUE
),
(
    '001e8b93-001e-48b9-8001-001e8b93001e',
    '000f443d-000f-4443-8000-000f443d000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.04,
    TRUE
),
(
    '001e8b94-001e-48b9-8001-001e8b94001e',
    '000f443d-000f-4443-8000-000f443d000f',
    '000000ac-0000-400a-8000-000000ac0000',
    'Cheesecake',
    'New York style cheesecake',
    7.20,
    TRUE
),
(
    '001e8b95-001e-48b9-8001-001e8b95001e',
    '000f443e-000f-4443-8000-000f443e000f',
    '000000ad-0000-400a-8000-000000ad0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.50,
    TRUE
),
(
    '001e8b96-001e-48b9-8001-001e8b96001e',
    '000f443e-000f-4443-8000-000f443e000f',
    '000000ad-0000-400a-8000-000000ad0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.64,
    TRUE
),
(
    '001e8b97-001e-48b9-8001-001e8b97001e',
    '000f443e-000f-4443-8000-000f443e000f',
    '000000ad-0000-400a-8000-000000ad0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.27,
    TRUE
),
(
    '001e8b98-001e-48b9-8001-001e8b98001e',
    '000f443e-000f-4443-8000-000f443e000f',
    '000000ad-0000-400a-8000-000000ad0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.66,
    TRUE
),
(
    '001e8b99-001e-48b9-8001-001e8b99001e',
    '000f443f-000f-4443-8000-000f443f000f',
    '000000ad-0000-400a-8000-000000ad0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.19,
    TRUE
),
(
    '001e8b9a-001e-48b9-8001-001e8b9a001e',
    '000f443f-000f-4443-8000-000f443f000f',
    '000000ad-0000-400a-8000-000000ad0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.21,
    TRUE
),
(
    '001e8b9b-001e-48b9-8001-001e8b9b001e',
    '000f443f-000f-4443-8000-000f443f000f',
    '000000ad-0000-400a-8000-000000ad0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.48,
    TRUE
),
(
    '001e8b9c-001e-48b9-8001-001e8b9c001e',
    '000f4440-000f-4444-8000-000f4440000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.92,
    TRUE
),
(
    '001e8b9d-001e-48b9-8001-001e8b9d001e',
    '000f4440-000f-4444-8000-000f4440000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.81,
    TRUE
),
(
    '001e8b9e-001e-48b9-8001-001e8b9e001e',
    '000f4440-000f-4444-8000-000f4440000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.97,
    TRUE
),
(
    '001e8b9f-001e-48b9-8001-001e8b9f001e',
    '000f4441-000f-4444-8000-000f4441000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.08,
    TRUE
),
(
    '001e8ba0-001e-48ba-8001-001e8ba0001e',
    '000f4441-000f-4444-8000-000f4441000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.48,
    TRUE
),
(
    '001e8ba1-001e-48ba-8001-001e8ba1001e',
    '000f4441-000f-4444-8000-000f4441000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.70,
    TRUE
),
(
    '001e8ba2-001e-48ba-8001-001e8ba2001e',
    '000f4442-000f-4444-8000-000f4442000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.67,
    TRUE
),
(
    '001e8ba3-001e-48ba-8001-001e8ba3001e',
    '000f4442-000f-4444-8000-000f4442000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.83,
    TRUE
),
(
    '001e8ba4-001e-48ba-8001-001e8ba4001e',
    '000f4442-000f-4444-8000-000f4442000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.65,
    TRUE
),
(
    '001e8ba5-001e-48ba-8001-001e8ba5001e',
    '000f4443-000f-4444-8000-000f4443000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.66,
    TRUE
),
(
    '001e8ba6-001e-48ba-8001-001e8ba6001e',
    '000f4443-000f-4444-8000-000f4443000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.25,
    TRUE
),
(
    '001e8ba7-001e-48ba-8001-001e8ba7001e',
    '000f4443-000f-4444-8000-000f4443000f',
    '000000ae-0000-400a-8000-000000ae0000',
    'Cheesecake',
    'New York style cheesecake',
    7.52,
    TRUE
),
(
    '001e8ba8-001e-48ba-8001-001e8ba8001e',
    '000f4444-000f-4444-8000-000f4444000f',
    '000000af-0000-400a-8000-000000af0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.15,
    TRUE
),
(
    '001e8ba9-001e-48ba-8001-001e8ba9001e',
    '000f4444-000f-4444-8000-000f4444000f',
    '000000af-0000-400a-8000-000000af0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.33,
    TRUE
),
(
    '001e8baa-001e-48ba-8001-001e8baa001e',
    '000f4444-000f-4444-8000-000f4444000f',
    '000000af-0000-400a-8000-000000af0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.99,
    TRUE
),
(
    '001e8bab-001e-48ba-8001-001e8bab001e',
    '000f4445-000f-4444-8000-000f4445000f',
    '000000af-0000-400a-8000-000000af0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.04,
    TRUE
),
(
    '001e8bac-001e-48ba-8001-001e8bac001e',
    '000f4445-000f-4444-8000-000f4445000f',
    '000000af-0000-400a-8000-000000af0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.82,
    TRUE
),
(
    '001e8bad-001e-48ba-8001-001e8bad001e',
    '000f4445-000f-4444-8000-000f4445000f',
    '000000af-0000-400a-8000-000000af0000',
    'Risotto',
    'Creamy Italian rice dish',
    12.34,
    TRUE
),
(
    '001e8bae-001e-48ba-8001-001e8bae001e',
    '000f4446-000f-4444-8000-000f4446000f',
    '000000b0-0000-400b-8000-000000b00000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.67,
    TRUE
),
(
    '001e8baf-001e-48ba-8001-001e8baf001e',
    '000f4446-000f-4444-8000-000f4446000f',
    '000000b0-0000-400b-8000-000000b00000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.87,
    TRUE
),
(
    '001e8bb0-001e-48bb-8001-001e8bb0001e',
    '000f4446-000f-4444-8000-000f4446000f',
    '000000b0-0000-400b-8000-000000b00000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.89,
    TRUE
),
(
    '001e8bb1-001e-48bb-8001-001e8bb1001e',
    '000f4446-000f-4444-8000-000f4446000f',
    '000000b0-0000-400b-8000-000000b00000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.25,
    TRUE
),
(
    '001e8bb2-001e-48bb-8001-001e8bb2001e',
    '000f4447-000f-4444-8000-000f4447000f',
    '000000b0-0000-400b-8000-000000b00000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.98,
    TRUE
),
(
    '001e8bb3-001e-48bb-8001-001e8bb3001e',
    '000f4447-000f-4444-8000-000f4447000f',
    '000000b0-0000-400b-8000-000000b00000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.24,
    TRUE
),
(
    '001e8bb4-001e-48bb-8001-001e8bb4001e',
    '000f4447-000f-4444-8000-000f4447000f',
    '000000b0-0000-400b-8000-000000b00000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.56,
    TRUE
),
(
    '001e8bb5-001e-48bb-8001-001e8bb5001e',
    '000f4447-000f-4444-8000-000f4447000f',
    '000000b0-0000-400b-8000-000000b00000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.87,
    TRUE
),
(
    '001e8bb6-001e-48bb-8001-001e8bb6001e',
    '000f4448-000f-4444-8000-000f4448000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.96,
    TRUE
),
(
    '001e8bb7-001e-48bb-8001-001e8bb7001e',
    '000f4448-000f-4444-8000-000f4448000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.14,
    TRUE
),
(
    '001e8bb8-001e-48bb-8001-001e8bb8001e',
    '000f4448-000f-4444-8000-000f4448000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.94,
    TRUE
),
(
    '001e8bb9-001e-48bb-8001-001e8bb9001e',
    '000f4449-000f-4444-8000-000f4449000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.35,
    TRUE
),
(
    '001e8bba-001e-48bb-8001-001e8bba001e',
    '000f4449-000f-4444-8000-000f4449000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.43,
    TRUE
),
(
    '001e8bbb-001e-48bb-8001-001e8bbb001e',
    '000f4449-000f-4444-8000-000f4449000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.52,
    TRUE
),
(
    '001e8bbc-001e-48bb-8001-001e8bbc001e',
    '000f4449-000f-4444-8000-000f4449000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.40,
    TRUE
),
(
    '001e8bbd-001e-48bb-8001-001e8bbd001e',
    '000f444a-000f-4444-8000-000f444a000f',
    '000000b1-0000-400b-8000-000000b10000',
    'French Fries',
    'Crispy golden fries',
    4.78,
    TRUE
),
(
    '001e8bbe-001e-48bb-8001-001e8bbe001e',
    '000f444a-000f-4444-8000-000f444a000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.12,
    TRUE
),
(
    '001e8bbf-001e-48bb-8001-001e8bbf001e',
    '000f444a-000f-4444-8000-000f444a000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.72,
    TRUE
),
(
    '001e8bc0-001e-48bc-8001-001e8bc0001e',
    '000f444b-000f-4444-8000-000f444b000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.11,
    TRUE
),
(
    '001e8bc1-001e-48bc-8001-001e8bc1001e',
    '000f444b-000f-4444-8000-000f444b000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.27,
    TRUE
),
(
    '001e8bc2-001e-48bc-8001-001e8bc2001e',
    '000f444b-000f-4444-8000-000f444b000f',
    '000000b1-0000-400b-8000-000000b10000',
    'Cheesecake',
    'New York style cheesecake',
    8.48,
    TRUE
),
(
    '001e8bc3-001e-48bc-8001-001e8bc3001e',
    '000f444c-000f-4444-8000-000f444c000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.06,
    TRUE
),
(
    '001e8bc4-001e-48bc-8001-001e8bc4001e',
    '000f444c-000f-4444-8000-000f444c000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.73,
    TRUE
),
(
    '001e8bc5-001e-48bc-8001-001e8bc5001e',
    '000f444c-000f-4444-8000-000f444c000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.90,
    TRUE
),
(
    '001e8bc6-001e-48bc-8001-001e8bc6001e',
    '000f444c-000f-4444-8000-000f444c000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.17,
    TRUE
),
(
    '001e8bc7-001e-48bc-8001-001e8bc7001e',
    '000f444d-000f-4444-8000-000f444d000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.87,
    TRUE
),
(
    '001e8bc8-001e-48bc-8001-001e8bc8001e',
    '000f444d-000f-4444-8000-000f444d000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.36,
    TRUE
),
(
    '001e8bc9-001e-48bc-8001-001e8bc9001e',
    '000f444d-000f-4444-8000-000f444d000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Risotto',
    'Creamy Italian rice dish',
    12.61,
    TRUE
),
(
    '001e8bca-001e-48bc-8001-001e8bca001e',
    '000f444e-000f-4444-8000-000f444e000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    8.13,
    TRUE
),
(
    '001e8bcb-001e-48bc-8001-001e8bcb001e',
    '000f444e-000f-4444-8000-000f444e000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.31,
    TRUE
),
(
    '001e8bcc-001e-48bc-8001-001e8bcc001e',
    '000f444e-000f-4444-8000-000f444e000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.39,
    TRUE
),
(
    '001e8bcd-001e-48bc-8001-001e8bcd001e',
    '000f444f-000f-4444-8000-000f444f000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.98,
    TRUE
),
(
    '001e8bce-001e-48bc-8001-001e8bce001e',
    '000f444f-000f-4444-8000-000f444f000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.51,
    TRUE
),
(
    '001e8bcf-001e-48bc-8001-001e8bcf001e',
    '000f444f-000f-4444-8000-000f444f000f',
    '000000b2-0000-400b-8000-000000b20000',
    'Cheesecake',
    'New York style cheesecake',
    7.38,
    TRUE
),
(
    '001e8bd0-001e-48bd-8001-001e8bd0001e',
    '000f4450-000f-4445-8000-000f4450000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.94,
    TRUE
),
(
    '001e8bd1-001e-48bd-8001-001e8bd1001e',
    '000f4450-000f-4445-8000-000f4450000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.56,
    TRUE
),
(
    '001e8bd2-001e-48bd-8001-001e8bd2001e',
    '000f4450-000f-4445-8000-000f4450000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.04,
    TRUE
),
(
    '001e8bd3-001e-48bd-8001-001e8bd3001e',
    '000f4450-000f-4445-8000-000f4450000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.59,
    TRUE
),
(
    '001e8bd4-001e-48bd-8001-001e8bd4001e',
    '000f4451-000f-4445-8000-000f4451000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.11,
    TRUE
),
(
    '001e8bd5-001e-48bd-8001-001e8bd5001e',
    '000f4451-000f-4445-8000-000f4451000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.08,
    TRUE
),
(
    '001e8bd6-001e-48bd-8001-001e8bd6001e',
    '000f4451-000f-4445-8000-000f4451000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.56,
    TRUE
),
(
    '001e8bd7-001e-48bd-8001-001e8bd7001e',
    '000f4451-000f-4445-8000-000f4451000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.89,
    TRUE
),
(
    '001e8bd8-001e-48bd-8001-001e8bd8001e',
    '000f4452-000f-4445-8000-000f4452000f',
    '000000b3-0000-400b-8000-000000b30000',
    'French Fries',
    'Crispy golden fries',
    5.19,
    TRUE
),
(
    '001e8bd9-001e-48bd-8001-001e8bd9001e',
    '000f4452-000f-4445-8000-000f4452000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Onion Rings',
    'Battered and fried onion rings',
    5.82,
    TRUE
),
(
    '001e8bda-001e-48bd-8001-001e8bda001e',
    '000f4452-000f-4445-8000-000f4452000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.39,
    TRUE
),
(
    '001e8bdb-001e-48bd-8001-001e8bdb001e',
    '000f4453-000f-4445-8000-000f4453000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.66,
    TRUE
),
(
    '001e8bdc-001e-48bd-8001-001e8bdc001e',
    '000f4453-000f-4445-8000-000f4453000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.64,
    TRUE
),
(
    '001e8bdd-001e-48bd-8001-001e8bdd001e',
    '000f4453-000f-4445-8000-000f4453000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Cheesecake',
    'New York style cheesecake',
    8.82,
    TRUE
),
(
    '001e8bde-001e-48bd-8001-001e8bde001e',
    '000f4453-000f-4445-8000-000f4453000f',
    '000000b3-0000-400b-8000-000000b30000',
    'Tiramisu',
    'Classic Italian dessert',
    7.80,
    TRUE
),
(
    '001e8bdf-001e-48bd-8001-001e8bdf001e',
    '000f4454-000f-4445-8000-000f4454000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    13.11,
    TRUE
),
(
    '001e8be0-001e-48be-8001-001e8be0001e',
    '000f4454-000f-4445-8000-000f4454000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    15.39,
    TRUE
),
(
    '001e8be1-001e-48be-8001-001e8be1001e',
    '000f4454-000f-4445-8000-000f4454000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives',
    16.83,
    TRUE
),
(
    '001e8be2-001e-48be-8001-001e8be2001e',
    '000f4455-000f-4445-8000-000f4455000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino',
    14.04,
    TRUE
),
(
    '001e8be3-001e-48be-8001-001e8be3001e',
    '000f4455-000f-4445-8000-000f4455000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    11.73,
    TRUE
),
(
    '001e8be4-001e-48be-8001-001e8be4001e',
    '000f4455-000f-4445-8000-000f4455000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream',
    13.39,
    TRUE
),
(
    '001e8be5-001e-48be-8001-001e8be5001e',
    '000f4455-000f-4445-8000-000f4455000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Lasagna',
    'Layered pasta with meat sauce and cheese',
    15.07,
    TRUE
),
(
    '001e8be6-001e-48be-8001-001e8be6001e',
    '000f4455-000f-4445-8000-000f4455000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Ravioli',
    'Stuffed pasta with ricotta and spinach',
    13.61,
    TRUE
),
(
    '001e8be7-001e-48be-8001-001e8be7001e',
    '000f4456-000f-4445-8000-000f4456000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.88,
    TRUE
),
(
    '001e8be8-001e-48be-8001-001e8be8001e',
    '000f4456-000f-4445-8000-000f4456000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.39,
    TRUE
),
(
    '001e8be9-001e-48be-8001-001e8be9001e',
    '000f4456-000f-4445-8000-000f4456000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.64,
    TRUE
),
(
    '001e8bea-001e-48be-8001-001e8bea001e',
    '000f4456-000f-4445-8000-000f4456000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.99,
    TRUE
),
(
    '001e8beb-001e-48be-8001-001e8beb001e',
    '000f4457-000f-4445-8000-000f4457000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.60,
    TRUE
),
(
    '001e8bec-001e-48be-8001-001e8bec001e',
    '000f4457-000f-4445-8000-000f4457000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.39,
    TRUE
),
(
    '001e8bed-001e-48be-8001-001e8bed001e',
    '000f4457-000f-4445-8000-000f4457000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Cheesecake',
    'New York style cheesecake',
    8.54,
    TRUE
),
(
    '001e8bee-001e-48be-8001-001e8bee001e',
    '000f4457-000f-4445-8000-000f4457000f',
    '000000b4-0000-400b-8000-000000b40000',
    'Tiramisu',
    'Classic Italian dessert',
    7.19,
    TRUE
),
(
    '001e8bef-001e-48be-8001-001e8bef001e',
    '000f4458-000f-4445-8000-000f4458000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Har Gow',
    'Steamed shrimp dumplings',
    9.89,
    TRUE
),
(
    '001e8bf0-001e-48bf-8001-001e8bf0001e',
    '000f4458-000f-4445-8000-000f4458000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Siu Mai',
    'Open-top pork and shrimp dumplings',
    7.96,
    TRUE
),
(
    '001e8bf1-001e-48bf-8001-001e8bf1001e',
    '000f4458-000f-4445-8000-000f4458000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Char Siu Bao',
    'Steamed BBQ pork buns',
    8.97,
    TRUE
),
(
    '001e8bf2-001e-48bf-8001-001e8bf2001e',
    '000f4458-000f-4445-8000-000f4458000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Spring Rolls',
    'Crispy vegetable spring rolls',
    6.32,
    TRUE
),
(
    '001e8bf3-001e-48bf-8001-001e8bf3001e',
    '000f4459-000f-4445-8000-000f4459000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    15.03,
    TRUE
),
(
    '001e8bf4-001e-48bf-8001-001e8bf4001e',
    '000f4459-000f-4445-8000-000f4459000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    13.24,
    TRUE
),
(
    '001e8bf5-001e-48bf-8001-001e8bf5001e',
    '000f4459-000f-4445-8000-000f4459000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.42,
    TRUE
),
(
    '001e8bf6-001e-48bf-8001-001e8bf6001e',
    '000f4459-000f-4445-8000-000f4459000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    11.93,
    TRUE
),
(
    '001e8bf7-001e-48bf-8001-001e8bf7001e',
    '000f445a-000f-4445-8000-000f445a000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.41,
    TRUE
),
(
    '001e8bf8-001e-48bf-8001-001e8bf8001e',
    '000f445a-000f-4445-8000-000f445a000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Biryani',
    'Fragrant spiced rice with meat',
    13.20,
    TRUE
),
(
    '001e8bf9-001e-48bf-8001-001e8bf9001e',
    '000f445a-000f-4445-8000-000f445a000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Risotto',
    'Creamy Italian rice dish',
    13.65,
    TRUE
),
(
    '001e8bfa-001e-48bf-8001-001e8bfa001e',
    '000f445b-000f-4445-8000-000f445b000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    8.96,
    TRUE
),
(
    '001e8bfb-001e-48bf-8001-001e8bfb001e',
    '000f445b-000f-4445-8000-000f445b000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Tomato Soup',
    'Creamy tomato soup',
    7.51,
    TRUE
),
(
    '001e8bfc-001e-48bf-8001-001e8bfc001e',
    '000f445b-000f-4445-8000-000f445b000f',
    '000000b5-0000-400b-8000-000000b50000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.29,
    TRUE
),
(
    '001e8bfd-001e-48bf-8001-001e8bfd001e',
    '000f445c-000f-4445-8000-000f445c000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Beef Tacos',
    'Seasoned ground beef with lettuce and cheese',
    9.07,
    TRUE
),
(
    '001e8bfe-001e-48bf-8001-001e8bfe001e',
    '000f445c-000f-4445-8000-000f445c000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Chicken Tacos',
    'Grilled chicken with salsa and avocado',
    9.76,
    TRUE
),
(
    '001e8bff-001e-48bf-8001-001e8bff001e',
    '000f445c-000f-4445-8000-000f445c000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Fish Tacos',
    'Battered fish with cabbage slaw',
    10.38,
    TRUE
),
(
    '001e8c00-001e-48c0-8001-001e8c00001e',
    '000f445d-000f-4445-8000-000f445d000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.16,
    TRUE
),
(
    '001e8c01-001e-48c0-8001-001e8c01001e',
    '000f445d-000f-4445-8000-000f445d000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.70,
    TRUE
),
(
    '001e8c02-001e-48c0-8001-001e8c02001e',
    '000f445d-000f-4445-8000-000f445d000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.77,
    TRUE
),
(
    '001e8c03-001e-48c0-8001-001e8c03001e',
    '000f445d-000f-4445-8000-000f445d000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.95,
    TRUE
),
(
    '001e8c04-001e-48c0-8001-001e8c04001e',
    '000f445e-000f-4445-8000-000f445e000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.78,
    TRUE
),
(
    '001e8c05-001e-48c0-8001-001e8c05001e',
    '000f445e-000f-4445-8000-000f445e000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.46,
    TRUE
),
(
    '001e8c06-001e-48c0-8001-001e8c06001e',
    '000f445e-000f-4445-8000-000f445e000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.30,
    TRUE
),
(
    '001e8c07-001e-48c0-8001-001e8c07001e',
    '000f445e-000f-4445-8000-000f445e000f',
    '000000b6-0000-400b-8000-000000b60000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.82,
    TRUE
),
(
    '001e8c08-001e-48c0-8001-001e8c08001e',
    '000f445f-000f-4445-8000-000f445f000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    13.85,
    TRUE
),
(
    '001e8c09-001e-48c0-8001-001e8c09001e',
    '000f445f-000f-4445-8000-000f445f000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    15.09,
    TRUE
),
(
    '001e8c0a-001e-48c0-8001-001e8c0a001e',
    '000f445f-000f-4445-8000-000f445f000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.32,
    TRUE
),
(
    '001e8c0b-001e-48c0-8001-001e8c0b001e',
    '000f4460-000f-4446-8000-000f4460000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.76,
    TRUE
),
(
    '001e8c0c-001e-48c0-8001-001e8c0c001e',
    '000f4460-000f-4446-8000-000f4460000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.97,
    TRUE
),
(
    '001e8c0d-001e-48c0-8001-001e8c0d001e',
    '000f4460-000f-4446-8000-000f4460000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.06,
    TRUE
),
(
    '001e8c0e-001e-48c0-8001-001e8c0e001e',
    '000f4460-000f-4446-8000-000f4460000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.42,
    TRUE
),
(
    '001e8c0f-001e-48c0-8001-001e8c0f001e',
    '000f4461-000f-4446-8000-000f4461000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.31,
    TRUE
),
(
    '001e8c10-001e-48c1-8001-001e8c10001e',
    '000f4461-000f-4446-8000-000f4461000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.90,
    TRUE
),
(
    '001e8c11-001e-48c1-8001-001e8c11001e',
    '000f4461-000f-4446-8000-000f4461000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.44,
    TRUE
),
(
    '001e8c12-001e-48c1-8001-001e8c12001e',
    '000f4461-000f-4446-8000-000f4461000f',
    '000000b7-0000-400b-8000-000000b70000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.10,
    TRUE
),
(
    '001e8c13-001e-48c1-8001-001e8c13001e',
    '000f4462-000f-4446-8000-000f4462000f',
    '000000b8-0000-400b-8000-000000b80000',
    'Salmon Roll',
    'Fresh salmon with rice and nori',
    8.39,
    TRUE
),
(
    '001e8c14-001e-48c1-8001-001e8c14001e',
    '000f4462-000f-4446-8000-000f4462000f',
    '000000b8-0000-400b-8000-000000b80000',
    'Tuna Roll',
    'Premium tuna with rice and nori',
    9.37,
    TRUE
),
(
    '001e8c15-001e-48c1-8001-001e8c15001e',
    '000f4462-000f-4446-8000-000f4462000f',
    '000000b8-0000-400b-8000-000000b80000',
    'California Roll',
    'Crab, avocado, and cucumber',
    7.06,
    TRUE
),
(
    '001e8c16-001e-48c1-8001-001e8c16001e',
    '000f4462-000f-4446-8000-000f4462000f',
    '000000b8-0000-400b-8000-000000b80000',
    'Dragon Roll',
    'Eel, cucumber, and avocado',
    12.49,
    TRUE
),
(
    '001e8c17-001e-48c1-8001-001e8c17001e',
    '000f4463-000f-4446-8000-000f4463000f',
    '000000b8-0000-400b-8000-000000b80000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.26,
    TRUE
),
(
    '001e8c18-001e-48c1-8001-001e8c18001e',
    '000f4463-000f-4446-8000-000f4463000f',
    '000000b8-0000-400b-8000-000000b80000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.99,
    TRUE
),
(
    '001e8c19-001e-48c1-8001-001e8c19001e',
    '000f4463-000f-4446-8000-000f4463000f',
    '000000b8-0000-400b-8000-000000b80000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.44,
    TRUE
),
(
    '001e8c1a-001e-48c1-8001-001e8c1a001e',
    '000f4464-000f-4446-8000-000f4464000f',
    '000000b9-0000-400b-8000-000000b90000',
    'Chicken Curry',
    'Tender chicken in rich curry sauce',
    13.38,
    TRUE
),
(
    '001e8c1b-001e-48c1-8001-001e8c1b001e',
    '000f4464-000f-4446-8000-000f4464000f',
    '000000b9-0000-400b-8000-000000b90000',
    'Lamb Curry',
    'Slow-cooked lamb in aromatic spices',
    16.08,
    TRUE
),
(
    '001e8c1c-001e-48c1-8001-001e8c1c001e',
    '000f4464-000f-4446-8000-000f4464000f',
    '000000b9-0000-400b-8000-000000b90000',
    'Vegetable Curry',
    'Mixed vegetables in coconut curry',
    11.91,
    TRUE
),
(
    '001e8c1d-001e-48c1-8001-001e8c1d001e',
    '000f4464-000f-4446-8000-000f4464000f',
    '000000b9-0000-400b-8000-000000b90000',
    'Butter Chicken',
    'Creamy tomato-based curry',
    14.39,
    TRUE
),
(
    '001e8c1e-001e-48c1-8001-001e8c1e001e',
    '000f4465-000f-4446-8000-000f4465000f',
    '000000b9-0000-400b-8000-000000b90000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    14.80,
    TRUE
),
(
    '001e8c1f-001e-48c1-8001-001e8c1f001e',
    '000f4465-000f-4446-8000-000f4465000f',
    '000000b9-0000-400b-8000-000000b90000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.93,
    TRUE
),
(
    '001e8c20-001e-48c2-8001-001e8c20001e',
    '000f4465-000f-4446-8000-000f4465000f',
    '000000b9-0000-400b-8000-000000b90000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.01,
    TRUE
),
(
    '001e8c21-001e-48c2-8001-001e8c21001e',
    '000f4465-000f-4446-8000-000f4465000f',
    '000000b9-0000-400b-8000-000000b90000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    11.62,
    TRUE
),
(
    '001e8c22-001e-48c2-8001-001e8c22001e',
    '000f4466-000f-4446-8000-000f4466000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Classic Burger',
    'Beef patty with lettuce, tomato, onion',
    10.62,
    TRUE
),
(
    '001e8c23-001e-48c2-8001-001e8c23001e',
    '000f4466-000f-4446-8000-000f4466000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Cheeseburger',
    'Beef patty with cheese and special sauce',
    11.29,
    TRUE
),
(
    '001e8c24-001e-48c2-8001-001e8c24001e',
    '000f4466-000f-4446-8000-000f4466000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Chicken Burger',
    'Grilled chicken breast with fixings',
    11.29,
    TRUE
),
(
    '001e8c25-001e-48c2-8001-001e8c25001e',
    '000f4466-000f-4446-8000-000f4466000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Veggie Burger',
    'Plant-based patty with vegetables',
    10.32,
    TRUE
),
(
    '001e8c26-001e-48c2-8001-001e8c26001e',
    '000f4467-000f-4446-8000-000f4467000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.60,
    TRUE
),
(
    '001e8c27-001e-48c2-8001-001e8c27001e',
    '000f4467-000f-4446-8000-000f4467000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.73,
    TRUE
),
(
    '001e8c28-001e-48c2-8001-001e8c28001e',
    '000f4467-000f-4446-8000-000f4467000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.59,
    TRUE
),
(
    '001e8c29-001e-48c2-8001-001e8c29001e',
    '000f4467-000f-4446-8000-000f4467000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.26,
    TRUE
),
(
    '001e8c2a-001e-48c2-8001-001e8c2a001e',
    '000f4468-000f-4446-8000-000f4468000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    10.92,
    TRUE
),
(
    '001e8c2b-001e-48c2-8001-001e8c2b001e',
    '000f4468-000f-4446-8000-000f4468000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.91,
    TRUE
),
(
    '001e8c2c-001e-48c2-8001-001e8c2c001e',
    '000f4468-000f-4446-8000-000f4468000f',
    '000000ba-0000-400b-8000-000000ba0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.14,
    TRUE
),
(
    '001e8c2d-001e-48c2-8001-001e8c2d001e',
    '000f4469-000f-4446-8000-000f4469000f',
    '000000bb-0000-400b-8000-000000bb0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.07,
    TRUE
),
(
    '001e8c2e-001e-48c2-8001-001e8c2e001e',
    '000f4469-000f-4446-8000-000f4469000f',
    '000000bb-0000-400b-8000-000000bb0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.71,
    TRUE
),
(
    '001e8c2f-001e-48c2-8001-001e8c2f001e',
    '000f4469-000f-4446-8000-000f4469000f',
    '000000bb-0000-400b-8000-000000bb0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.94,
    TRUE
),
(
    '001e8c30-001e-48c3-8001-001e8c30001e',
    '000f4469-000f-4446-8000-000f4469000f',
    '000000bb-0000-400b-8000-000000bb0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.49,
    TRUE
),
(
    '001e8c31-001e-48c3-8001-001e8c31001e',
    '000f446a-000f-4446-8000-000f446a000f',
    '000000bb-0000-400b-8000-000000bb0000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    9.24,
    TRUE
),
(
    '001e8c32-001e-48c3-8001-001e8c32001e',
    '000f446a-000f-4446-8000-000f446a000f',
    '000000bb-0000-400b-8000-000000bb0000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.50,
    TRUE
),
(
    '001e8c33-001e-48c3-8001-001e8c33001e',
    '000f446a-000f-4446-8000-000f446a000f',
    '000000bb-0000-400b-8000-000000bb0000',
    'Miso Soup',
    'Traditional Japanese soup',
    6.39,
    TRUE
),
(
    '001e8c34-001e-48c3-8001-001e8c34001e',
    '000f446b-000f-4446-8000-000f446b000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.92,
    TRUE
),
(
    '001e8c35-001e-48c3-8001-001e8c35001e',
    '000f446b-000f-4446-8000-000f446b000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.15,
    TRUE
),
(
    '001e8c36-001e-48c3-8001-001e8c36001e',
    '000f446b-000f-4446-8000-000f446b000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.22,
    TRUE
),
(
    '001e8c37-001e-48c3-8001-001e8c37001e',
    '000f446b-000f-4446-8000-000f446b000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.28,
    TRUE
),
(
    '001e8c38-001e-48c3-8001-001e8c38001e',
    '000f446c-000f-4446-8000-000f446c000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.70,
    TRUE
),
(
    '001e8c39-001e-48c3-8001-001e8c39001e',
    '000f446c-000f-4446-8000-000f446c000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.68,
    TRUE
),
(
    '001e8c3a-001e-48c3-8001-001e8c3a001e',
    '000f446c-000f-4446-8000-000f446c000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.08,
    TRUE
),
(
    '001e8c3b-001e-48c3-8001-001e8c3b001e',
    '000f446c-000f-4446-8000-000f446c000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.74,
    TRUE
),
(
    '001e8c3c-001e-48c3-8001-001e8c3c001e',
    '000f446d-000f-4446-8000-000f446d000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.16,
    TRUE
),
(
    '001e8c3d-001e-48c3-8001-001e8c3d001e',
    '000f446d-000f-4446-8000-000f446d000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    11.17,
    TRUE
),
(
    '001e8c3e-001e-48c3-8001-001e8c3e001e',
    '000f446d-000f-4446-8000-000f446d000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Garden Salad',
    'Mixed greens with vegetables',
    8.28,
    TRUE
),
(
    '001e8c3f-001e-48c3-8001-001e8c3f001e',
    '000f446e-000f-4446-8000-000f446e000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    7.97,
    TRUE
),
(
    '001e8c40-001e-48c4-8001-001e8c40001e',
    '000f446e-000f-4446-8000-000f446e000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.11,
    TRUE
),
(
    '001e8c41-001e-48c4-8001-001e8c41001e',
    '000f446e-000f-4446-8000-000f446e000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Cheesecake',
    'New York style cheesecake',
    7.25,
    TRUE
),
(
    '001e8c42-001e-48c4-8001-001e8c42001e',
    '000f446e-000f-4446-8000-000f446e000f',
    '000000bc-0000-400b-8000-000000bc0000',
    'Tiramisu',
    'Classic Italian dessert',
    7.98,
    TRUE
),
(
    '001e8c43-001e-48c4-8001-001e8c43001e',
    '000f446f-000f-4446-8000-000f446f000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.62,
    TRUE
),
(
    '001e8c44-001e-48c4-8001-001e8c44001e',
    '000f446f-000f-4446-8000-000f446f000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.31,
    TRUE
),
(
    '001e8c45-001e-48c4-8001-001e8c45001e',
    '000f446f-000f-4446-8000-000f446f000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.42,
    TRUE
),
(
    '001e8c46-001e-48c4-8001-001e8c46001e',
    '000f4470-000f-4447-8000-000f4470000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.05,
    TRUE
),
(
    '001e8c47-001e-48c4-8001-001e8c47001e',
    '000f4470-000f-4447-8000-000f4470000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.63,
    TRUE
),
(
    '001e8c48-001e-48c4-8001-001e8c48001e',
    '000f4470-000f-4447-8000-000f4470000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.70,
    TRUE
),
(
    '001e8c49-001e-48c4-8001-001e8c49001e',
    '000f4470-000f-4447-8000-000f4470000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.70,
    TRUE
),
(
    '001e8c4a-001e-48c4-8001-001e8c4a001e',
    '000f4471-000f-4447-8000-000f4471000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Beef Chow Fun',
    'Stir-fried wide rice noodles with beef',
    14.08,
    TRUE
),
(
    '001e8c4b-001e-48c4-8001-001e8c4b001e',
    '000f4471-000f-4447-8000-000f4471000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Dan Dan Noodles',
    'Spicy Sichuan noodles with minced pork',
    12.53,
    TRUE
),
(
    '001e8c4c-001e-48c4-8001-001e8c4c001e',
    '000f4471-000f-4447-8000-000f4471000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Wonton Soup',
    'Pork and shrimp wontons in clear broth',
    11.23,
    TRUE
),
(
    '001e8c4d-001e-48c4-8001-001e8c4d001e',
    '000f4471-000f-4447-8000-000f4471000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Lo Mein',
    'Stir-fried noodles with vegetables',
    12.56,
    TRUE
),
(
    '001e8c4e-001e-48c4-8001-001e8c4e001e',
    '000f4471-000f-4447-8000-000f4471000f',
    '000000bd-0000-400b-8000-000000bd0000',
    'Pad Thai',
    'Thai-style stir-fried noodles',
    12.78,
    TRUE
),
(
    '001e8c4f-001e-48c4-8001-001e8c4f001e',
    '000f4472-000f-4447-8000-000f4472000f',
    '000000be-0000-400b-8000-000000be0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.12,
    TRUE
),
(
    '001e8c50-001e-48c5-8001-001e8c50001e',
    '000f4472-000f-4447-8000-000f4472000f',
    '000000be-0000-400b-8000-000000be0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.48,
    TRUE
),
(
    '001e8c51-001e-48c5-8001-001e8c51001e',
    '000f4472-000f-4447-8000-000f4472000f',
    '000000be-0000-400b-8000-000000be0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.96,
    TRUE
),
(
    '001e8c52-001e-48c5-8001-001e8c52001e',
    '000f4472-000f-4447-8000-000f4472000f',
    '000000be-0000-400b-8000-000000be0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.32,
    TRUE
),
(
    '001e8c53-001e-48c5-8001-001e8c53001e',
    '000f4473-000f-4447-8000-000f4473000f',
    '000000be-0000-400b-8000-000000be0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.43,
    TRUE
),
(
    '001e8c54-001e-48c5-8001-001e8c54001e',
    '000f4473-000f-4447-8000-000f4473000f',
    '000000be-0000-400b-8000-000000be0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.07,
    TRUE
),
(
    '001e8c55-001e-48c5-8001-001e8c55001e',
    '000f4473-000f-4447-8000-000f4473000f',
    '000000be-0000-400b-8000-000000be0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.09,
    TRUE
),
(
    '001e8c56-001e-48c5-8001-001e8c56001e',
    '000f4473-000f-4447-8000-000f4473000f',
    '000000be-0000-400b-8000-000000be0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.92,
    TRUE
),
(
    '001e8c57-001e-48c5-8001-001e8c57001e',
    '000f4474-000f-4447-8000-000f4474000f',
    '000000be-0000-400b-8000-000000be0000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.59,
    TRUE
),
(
    '001e8c58-001e-48c5-8001-001e8c58001e',
    '000f4474-000f-4447-8000-000f4474000f',
    '000000be-0000-400b-8000-000000be0000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.23,
    TRUE
),
(
    '001e8c59-001e-48c5-8001-001e8c59001e',
    '000f4474-000f-4447-8000-000f4474000f',
    '000000be-0000-400b-8000-000000be0000',
    'Risotto',
    'Creamy Italian rice dish',
    13.37,
    TRUE
),
(
    '001e8c5a-001e-48c5-8001-001e8c5a001e',
    '000f4475-000f-4447-8000-000f4475000f',
    '000000be-0000-400b-8000-000000be0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.96,
    TRUE
),
(
    '001e8c5b-001e-48c5-8001-001e8c5b001e',
    '000f4475-000f-4447-8000-000f4475000f',
    '000000be-0000-400b-8000-000000be0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.93,
    TRUE
),
(
    '001e8c5c-001e-48c5-8001-001e8c5c001e',
    '000f4475-000f-4447-8000-000f4475000f',
    '000000be-0000-400b-8000-000000be0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.26,
    TRUE
),
(
    '001e8c5d-001e-48c5-8001-001e8c5d001e',
    '000f4476-000f-4447-8000-000f4476000f',
    '000000bf-0000-400b-8000-000000bf0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.94,
    TRUE
),
(
    '001e8c5e-001e-48c5-8001-001e8c5e001e',
    '000f4476-000f-4447-8000-000f4476000f',
    '000000bf-0000-400b-8000-000000bf0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.45,
    TRUE
),
(
    '001e8c5f-001e-48c5-8001-001e8c5f001e',
    '000f4476-000f-4447-8000-000f4476000f',
    '000000bf-0000-400b-8000-000000bf0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.68,
    TRUE
),
(
    '001e8c60-001e-48c6-8001-001e8c60001e',
    '000f4476-000f-4447-8000-000f4476000f',
    '000000bf-0000-400b-8000-000000bf0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.27,
    TRUE
),
(
    '001e8c61-001e-48c6-8001-001e8c61001e',
    '000f4477-000f-4447-8000-000f4477000f',
    '000000bf-0000-400b-8000-000000bf0000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.41,
    TRUE
),
(
    '001e8c62-001e-48c6-8001-001e8c62001e',
    '000f4477-000f-4447-8000-000f4477000f',
    '000000bf-0000-400b-8000-000000bf0000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.20,
    TRUE
),
(
    '001e8c63-001e-48c6-8001-001e8c63001e',
    '000f4477-000f-4447-8000-000f4477000f',
    '000000bf-0000-400b-8000-000000bf0000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.18,
    TRUE
),
(
    '001e8c64-001e-48c6-8001-001e8c64001e',
    '000f4477-000f-4447-8000-000f4477000f',
    '000000bf-0000-400b-8000-000000bf0000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.61,
    TRUE
),
(
    '001e8c65-001e-48c6-8001-001e8c65001e',
    '000f4478-000f-4447-8000-000f4478000f',
    '000000c0-0000-400c-8000-000000c00000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.39,
    TRUE
),
(
    '001e8c66-001e-48c6-8001-001e8c66001e',
    '000f4478-000f-4447-8000-000f4478000f',
    '000000c0-0000-400c-8000-000000c00000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.97,
    TRUE
),
(
    '001e8c67-001e-48c6-8001-001e8c67001e',
    '000f4478-000f-4447-8000-000f4478000f',
    '000000c0-0000-400c-8000-000000c00000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.11,
    TRUE
),
(
    '001e8c68-001e-48c6-8001-001e8c68001e',
    '000f4478-000f-4447-8000-000f4478000f',
    '000000c0-0000-400c-8000-000000c00000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.46,
    TRUE
),
(
    '001e8c69-001e-48c6-8001-001e8c69001e',
    '000f4479-000f-4447-8000-000f4479000f',
    '000000c0-0000-400c-8000-000000c00000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.83,
    TRUE
),
(
    '001e8c6a-001e-48c6-8001-001e8c6a001e',
    '000f4479-000f-4447-8000-000f4479000f',
    '000000c0-0000-400c-8000-000000c00000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.34,
    TRUE
),
(
    '001e8c6b-001e-48c6-8001-001e8c6b001e',
    '000f4479-000f-4447-8000-000f4479000f',
    '000000c0-0000-400c-8000-000000c00000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.90,
    TRUE
),
(
    '001e8c6c-001e-48c6-8001-001e8c6c001e',
    '000f4479-000f-4447-8000-000f4479000f',
    '000000c0-0000-400c-8000-000000c00000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.02,
    TRUE
),
(
    '001e8c6d-001e-48c6-8001-001e8c6d001e',
    '000f447a-000f-4447-8000-000f447a000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.83,
    TRUE
),
(
    '001e8c6e-001e-48c6-8001-001e8c6e001e',
    '000f447a-000f-4447-8000-000f447a000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.96,
    TRUE
),
(
    '001e8c6f-001e-48c6-8001-001e8c6f001e',
    '000f447a-000f-4447-8000-000f447a000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.74,
    TRUE
),
(
    '001e8c70-001e-48c7-8001-001e8c70001e',
    '000f447a-000f-4447-8000-000f447a000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.29,
    TRUE
),
(
    '001e8c71-001e-48c7-8001-001e8c71001e',
    '000f447b-000f-4447-8000-000f447b000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.81,
    TRUE
),
(
    '001e8c72-001e-48c7-8001-001e8c72001e',
    '000f447b-000f-4447-8000-000f447b000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.82,
    TRUE
),
(
    '001e8c73-001e-48c7-8001-001e8c73001e',
    '000f447b-000f-4447-8000-000f447b000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.84,
    TRUE
),
(
    '001e8c74-001e-48c7-8001-001e8c74001e',
    '000f447b-000f-4447-8000-000f447b000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.78,
    TRUE
),
(
    '001e8c75-001e-48c7-8001-001e8c75001e',
    '000f447c-000f-4447-8000-000f447c000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.50,
    TRUE
),
(
    '001e8c76-001e-48c7-8001-001e8c76001e',
    '000f447c-000f-4447-8000-000f447c000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.70,
    TRUE
),
(
    '001e8c77-001e-48c7-8001-001e8c77001e',
    '000f447c-000f-4447-8000-000f447c000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.09,
    TRUE
),
(
    '001e8c78-001e-48c7-8001-001e8c78001e',
    '000f447c-000f-4447-8000-000f447c000f',
    '000000c1-0000-400c-8000-000000c10000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.65,
    TRUE
),
(
    '001e8c79-001e-48c7-8001-001e8c79001e',
    '000f447d-000f-4447-8000-000f447d000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.39,
    TRUE
),
(
    '001e8c7a-001e-48c7-8001-001e8c7a001e',
    '000f447d-000f-4447-8000-000f447d000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.66,
    TRUE
),
(
    '001e8c7b-001e-48c7-8001-001e8c7b001e',
    '000f447d-000f-4447-8000-000f447d000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.62,
    TRUE
),
(
    '001e8c7c-001e-48c7-8001-001e8c7c001e',
    '000f447e-000f-4447-8000-000f447e000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.06,
    TRUE
),
(
    '001e8c7d-001e-48c7-8001-001e8c7d001e',
    '000f447e-000f-4447-8000-000f447e000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.51,
    TRUE
),
(
    '001e8c7e-001e-48c7-8001-001e8c7e001e',
    '000f447e-000f-4447-8000-000f447e000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.71,
    TRUE
),
(
    '001e8c7f-001e-48c7-8001-001e8c7f001e',
    '000f447e-000f-4447-8000-000f447e000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.85,
    TRUE
),
(
    '001e8c80-001e-48c8-8001-001e8c80001e',
    '000f447f-000f-4447-8000-000f447f000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Caesar Salad',
    'Romaine lettuce with Caesar dressing',
    9.56,
    TRUE
),
(
    '001e8c81-001e-48c8-8001-001e8c81001e',
    '000f447f-000f-4447-8000-000f447f000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Greek Salad',
    'Fresh vegetables with feta cheese',
    10.56,
    TRUE
),
(
    '001e8c82-001e-48c8-8001-001e8c82001e',
    '000f447f-000f-4447-8000-000f447f000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Garden Salad',
    'Mixed greens with vegetables',
    9.35,
    TRUE
),
(
    '001e8c83-001e-48c8-8001-001e8c83001e',
    '000f4480-000f-4448-8000-000f4480000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.16,
    TRUE
),
(
    '001e8c84-001e-48c8-8001-001e8c84001e',
    '000f4480-000f-4448-8000-000f4480000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.54,
    TRUE
),
(
    '001e8c85-001e-48c8-8001-001e8c85001e',
    '000f4480-000f-4448-8000-000f4480000f',
    '000000c2-0000-400c-8000-000000c20000',
    'Cheesecake',
    'New York style cheesecake',
    7.03,
    TRUE
),
(
    '001e8c86-001e-48c8-8001-001e8c86001e',
    '000f4481-000f-4448-8000-000f4481000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.84,
    TRUE
),
(
    '001e8c87-001e-48c8-8001-001e8c87001e',
    '000f4481-000f-4448-8000-000f4481000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.69,
    TRUE
),
(
    '001e8c88-001e-48c8-8001-001e8c88001e',
    '000f4481-000f-4448-8000-000f4481000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.03,
    TRUE
),
(
    '001e8c89-001e-48c8-8001-001e8c89001e',
    '000f4481-000f-4448-8000-000f4481000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.09,
    TRUE
),
(
    '001e8c8a-001e-48c8-8001-001e8c8a001e',
    '000f4482-000f-4448-8000-000f4482000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    11.66,
    TRUE
),
(
    '001e8c8b-001e-48c8-8001-001e8c8b001e',
    '000f4482-000f-4448-8000-000f4482000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.88,
    TRUE
),
(
    '001e8c8c-001e-48c8-8001-001e8c8c001e',
    '000f4482-000f-4448-8000-000f4482000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Risotto',
    'Creamy Italian rice dish',
    12.97,
    TRUE
),
(
    '001e8c8d-001e-48c8-8001-001e8c8d001e',
    '000f4483-000f-4448-8000-000f4483000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.88,
    TRUE
),
(
    '001e8c8e-001e-48c8-8001-001e8c8e001e',
    '000f4483-000f-4448-8000-000f4483000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.47,
    TRUE
),
(
    '001e8c8f-001e-48c8-8001-001e8c8f001e',
    '000f4483-000f-4448-8000-000f4483000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.26,
    TRUE
),
(
    '001e8c90-001e-48c9-8001-001e8c90001e',
    '000f4484-000f-4448-8000-000f4484000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.52,
    TRUE
),
(
    '001e8c91-001e-48c9-8001-001e8c91001e',
    '000f4484-000f-4448-8000-000f4484000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    4.82,
    TRUE
),
(
    '001e8c92-001e-48c9-8001-001e8c92001e',
    '000f4484-000f-4448-8000-000f4484000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Cheesecake',
    'New York style cheesecake',
    8.53,
    TRUE
),
(
    '001e8c93-001e-48c9-8001-001e8c93001e',
    '000f4484-000f-4448-8000-000f4484000f',
    '000000c3-0000-400c-8000-000000c30000',
    'Tiramisu',
    'Classic Italian dessert',
    6.87,
    TRUE
),
(
    '001e8c94-001e-48c9-8001-001e8c94001e',
    '000f4485-000f-4448-8000-000f4485000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.50,
    TRUE
),
(
    '001e8c95-001e-48c9-8001-001e8c95001e',
    '000f4485-000f-4448-8000-000f4485000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.89,
    TRUE
),
(
    '001e8c96-001e-48c9-8001-001e8c96001e',
    '000f4485-000f-4448-8000-000f4485000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    9.22,
    TRUE
),
(
    '001e8c97-001e-48c9-8001-001e8c97001e',
    '000f4485-000f-4448-8000-000f4485000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.74,
    TRUE
),
(
    '001e8c98-001e-48c9-8001-001e8c98001e',
    '000f4486-000f-4448-8000-000f4486000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.97,
    TRUE
),
(
    '001e8c99-001e-48c9-8001-001e8c99001e',
    '000f4486-000f-4448-8000-000f4486000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.98,
    TRUE
),
(
    '001e8c9a-001e-48c9-8001-001e8c9a001e',
    '000f4486-000f-4448-8000-000f4486000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.35,
    TRUE
),
(
    '001e8c9b-001e-48c9-8001-001e8c9b001e',
    '000f4487-000f-4448-8000-000f4487000f',
    '000000c4-0000-400c-8000-000000c40000',
    'French Fries',
    'Crispy golden fries',
    5.84,
    TRUE
),
(
    '001e8c9c-001e-48c9-8001-001e8c9c001e',
    '000f4487-000f-4448-8000-000f4487000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Onion Rings',
    'Battered and fried onion rings',
    5.66,
    TRUE
),
(
    '001e8c9d-001e-48c9-8001-001e8c9d001e',
    '000f4487-000f-4448-8000-000f4487000f',
    '000000c4-0000-400c-8000-000000c40000',
    'Coleslaw',
    'Fresh cabbage salad',
    4.45,
    TRUE
),
(
    '001e8c9e-001e-48c9-8001-001e8c9e001e',
    '000f4488-000f-4448-8000-000f4488000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.77,
    TRUE
),
(
    '001e8c9f-001e-48c9-8001-001e8c9f001e',
    '000f4488-000f-4448-8000-000f4488000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.56,
    TRUE
),
(
    '001e8ca0-001e-48ca-8001-001e8ca0001e',
    '000f4488-000f-4448-8000-000f4488000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.31,
    TRUE
),
(
    '001e8ca1-001e-48ca-8001-001e8ca1001e',
    '000f4488-000f-4448-8000-000f4488000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.97,
    TRUE
),
(
    '001e8ca2-001e-48ca-8001-001e8ca2001e',
    '000f4489-000f-4448-8000-000f4489000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.96,
    TRUE
),
(
    '001e8ca3-001e-48ca-8001-001e8ca3001e',
    '000f4489-000f-4448-8000-000f4489000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.41,
    TRUE
),
(
    '001e8ca4-001e-48ca-8001-001e8ca4001e',
    '000f4489-000f-4448-8000-000f4489000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.26,
    TRUE
),
(
    '001e8ca5-001e-48ca-8001-001e8ca5001e',
    '000f4489-000f-4448-8000-000f4489000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    6.21,
    TRUE
),
(
    '001e8ca6-001e-48ca-8001-001e8ca6001e',
    '000f448a-000f-4448-8000-000f448a000f',
    '000000c5-0000-400c-8000-000000c50000',
    'French Fries',
    'Crispy golden fries',
    4.71,
    TRUE
),
(
    '001e8ca7-001e-48ca-8001-001e8ca7001e',
    '000f448a-000f-4448-8000-000f448a000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Onion Rings',
    'Battered and fried onion rings',
    6.46,
    TRUE
),
(
    '001e8ca8-001e-48ca-8001-001e8ca8001e',
    '000f448a-000f-4448-8000-000f448a000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Coleslaw',
    'Fresh cabbage salad',
    3.41,
    TRUE
),
(
    '001e8ca9-001e-48ca-8001-001e8ca9001e',
    '000f448b-000f-4448-8000-000f448b000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Chocolate Cake',
    'Rich chocolate layer cake',
    6.95,
    TRUE
),
(
    '001e8caa-001e-48ca-8001-001e8caa001e',
    '000f448b-000f-4448-8000-000f448b000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Ice Cream',
    'Vanilla, chocolate, or strawberry',
    5.55,
    TRUE
),
(
    '001e8cab-001e-48ca-8001-001e8cab001e',
    '000f448b-000f-4448-8000-000f448b000f',
    '000000c5-0000-400c-8000-000000c50000',
    'Cheesecake',
    'New York style cheesecake',
    7.94,
    TRUE
),
(
    '001e8cac-001e-48ca-8001-001e8cac001e',
    '000f448c-000f-4448-8000-000f448c000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.79,
    TRUE
),
(
    '001e8cad-001e-48ca-8001-001e8cad001e',
    '000f448c-000f-4448-8000-000f448c000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.74,
    TRUE
),
(
    '001e8cae-001e-48ca-8001-001e8cae001e',
    '000f448c-000f-4448-8000-000f448c000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.41,
    TRUE
),
(
    '001e8caf-001e-48ca-8001-001e8caf001e',
    '000f448d-000f-4448-8000-000f448d000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Fried Rice',
    'Stir-fried rice with vegetables and protein',
    12.69,
    TRUE
),
(
    '001e8cb0-001e-48cb-8001-001e8cb0001e',
    '000f448d-000f-4448-8000-000f448d000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Biryani',
    'Fragrant spiced rice with meat',
    14.81,
    TRUE
),
(
    '001e8cb1-001e-48cb-8001-001e8cb1001e',
    '000f448d-000f-4448-8000-000f448d000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Risotto',
    'Creamy Italian rice dish',
    13.87,
    TRUE
),
(
    '001e8cb2-001e-48cb-8001-001e8cb2001e',
    '000f448e-000f-4448-8000-000f448e000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Chicken Noodle Soup',
    'Classic comfort soup',
    8.23,
    TRUE
),
(
    '001e8cb3-001e-48cb-8001-001e8cb3001e',
    '000f448e-000f-4448-8000-000f448e000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Tomato Soup',
    'Creamy tomato soup',
    8.32,
    TRUE
),
(
    '001e8cb4-001e-48cb-8001-001e8cb4001e',
    '000f448e-000f-4448-8000-000f448e000f',
    '000000c6-0000-400c-8000-000000c60000',
    'Miso Soup',
    'Traditional Japanese soup',
    7.59,
    TRUE
),
(
    '001e8cb5-001e-48cb-8001-001e8cb5001e',
    '000f448f-000f-4448-8000-000f448f000f',
    '000000c7-0000-400c-8000-000000c70000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    7.86,
    TRUE
),
(
    '001e8cb6-001e-48cb-8001-001e8cb6001e',
    '000f448f-000f-4448-8000-000f448f000f',
    '000000c7-0000-400c-8000-000000c70000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    10.24,
    TRUE
),
(
    '001e8cb7-001e-48cb-8001-001e8cb7001e',
    '000f448f-000f-4448-8000-000f448f000f',
    '000000c7-0000-400c-8000-000000c70000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.81,
    TRUE
),
(
    '001e8cb8-001e-48cb-8001-001e8cb8001e',
    '000f448f-000f-4448-8000-000f448f000f',
    '000000c7-0000-400c-8000-000000c70000',
    'Spring Rolls',
    'Crispy vegetable rolls',
    7.18,
    TRUE
),
(
    '001e8cb9-001e-48cb-8001-001e8cb9001e',
    '000f4490-000f-4449-8000-000f4490000f',
    '000000c7-0000-400c-8000-000000c70000',
    'Mozzarella Sticks',
    'Breaded mozzarella with marinara',
    8.88,
    TRUE
),
(
    '001e8cba-001e-48cb-8001-001e8cba001e',
    '000f4490-000f-4449-8000-000f4490000f',
    '000000c7-0000-400c-8000-000000c70000',
    'Chicken Wings',
    'Crispy wings with your choice of sauce',
    9.72,
    TRUE
),
(
    '001e8cbb-001e-48cb-8001-001e8cbb001e',
    '000f4490-000f-4449-8000-000f4490000f',
    '000000c7-0000-400c-8000-000000c70000',
    'Nachos',
    'Tortilla chips with cheese and jalapeños',
    8.85,
    TRUE
),
(
    '001e8cbc-001e-48cb-8001-001e8cbc001e',
    '000f4491-000f-4449-8000-000f4491000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Margherita',
    'Classic tomato sauce, mozzarella, fresh basil',
    12.39,
    TRUE
),
(
    '001e8cbd-001e-48cb-8001-001e8cbd001e',
    '000f4491-000f-4449-8000-000f4491000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Pepperoni',
    'Tomato sauce, mozzarella, spicy pepperoni',
    14.07,
    TRUE
),
(
    '001e8cbe-001e-48cb-8001-001e8cbe001e',
    '000f4491-000f-4449-8000-000f4491000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Quattro Stagioni',
    'Artichokes, mushrooms, ham, olives',
    16.70,
    TRUE
),
(
    '001e8cbf-001e-48cb-8001-001e8cbf001e',
    '000f4491-000f-4449-8000-000f4491000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Hawaiian',
    'Ham, pineapple, mozzarella',
    14.85,
    TRUE
),
(
    '001e8cc0-001e-48cc-8001-001e8cc0001e',
    '000f4491-000f-4449-8000-000f4491000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Vegetarian',
    'Mixed vegetables, mozzarella',
    13.64,
    TRUE
),
(
    '001e8cc1-001e-48cc-8001-001e8cc1001e',
    '000f4492-000f-4449-8000-000f4492000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Spaghetti Carbonara',
    'Spaghetti, guanciale, egg yolk, Pecorino',
    14.65,
    TRUE
),
(
    '001e8cc2-001e-48cc-8001-001e8cc2001e',
    '000f4492-000f-4449-8000-000f4492000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Penne Arrabbiata',
    'Penne with spicy tomato and garlic sauce',
    12.28,
    TRUE
),
(
    '001e8cc3-001e-48cc-8001-001e8cc3001e',
    '000f4492-000f-4449-8000-000f4492000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Fettuccine Alfredo',
    'Fettuccine with butter and Parmesan cream',
    13.12,
    TRUE
),
(
    '001e8cc4-001e-48cc-8001-001e8cc4001e',
    '000f4492-000f-4449-8000-000f4492000f',
    '000000c8-0000-400c-8000-000000c80000',
    'Lasagna',
    'Layered pasta with meat sauce and cheese',
    13.99,
    TRUE
);

-- Drivers (3 drivers)

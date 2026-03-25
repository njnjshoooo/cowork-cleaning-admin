-- =============================================
-- Cowork Cleaning 供應商管理後台 - Supabase Schema
-- =============================================

-- ===== 先清除所有舊資料 =====
DROP TABLE IF EXISTS app_users CASCADE;
DROP TABLE IF EXISTS vendor_users CASCADE;
DROP TABLE IF EXISTS order_notes CASCADE;
DROP TABLE IF EXISTS order_tasks CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS schedules CASCADE;
DROP TABLE IF EXISTS case_handlers CASCADE;
DROP TABLE IF EXISTS global_products CASCADE;
DROP TABLE IF EXISTS vendor_notes CASCADE;
DROP TABLE IF EXISTS vendors CASCADE;
DROP FUNCTION IF EXISTS get_user_role();
DROP FUNCTION IF EXISTS get_user_vendor_id();

-- 1. 供應商
CREATE TABLE vendors (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  contact TEXT,
  phone TEXT,
  email TEXT,
  tax_id TEXT,
  address TEXT,
  bank_name TEXT,
  bank_account TEXT,
  contract_start TEXT,
  contract_end TEXT,
  payment_terms TEXT DEFAULT '月結30天',
  categories TEXT[] DEFAULT '{}',
  regions TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 供應商備註
CREATE TABLE vendor_notes (
  id TEXT PRIMARY KEY,
  vendor_id TEXT REFERENCES vendors(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TEXT NOT NULL
);

-- 3. 產品
CREATE TABLE global_products (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  retail_price NUMERIC DEFAULT 0,
  purchase_price NUMERIC DEFAULT 0,
  commission_amount NUMERIC DEFAULT 0,
  profit_mode TEXT DEFAULT 'price',
  vendor_id TEXT REFERENCES vendors(id),
  note TEXT DEFAULT ''
);

-- 4. 施工人員
CREATE TABLE case_handlers (
  id TEXT PRIMARY KEY,
  vendor_id TEXT REFERENCES vendors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  product_ids TEXT[] DEFAULT '{}',
  regions TEXT[] DEFAULT '{}'
);

-- 5. 排程
CREATE TABLE schedules (
  id SERIAL PRIMARY KEY,
  handler_id TEXT REFERENCES case_handlers(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  status TEXT DEFAULT 'unknown',
  UNIQUE(handler_id, date)
);

-- 6. 訂單
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  order_no TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TEXT,
  source TEXT,
  payment_method TEXT,
  customer_name TEXT,
  phone TEXT,
  email TEXT,
  tax_id TEXT,
  invoice_title TEXT,
  city TEXT,
  district TEXT,
  address TEXT,
  vendor_id TEXT,
  handler_id TEXT
);

-- 7. 訂單任務
CREATE TABLE order_tasks (
  id TEXT PRIMARY KEY,
  order_id TEXT REFERENCES orders(id) ON DELETE CASCADE,
  same_as_customer BOOLEAN DEFAULT true,
  contact_name TEXT DEFAULT '',
  contact_phone TEXT DEFAULT '',
  contact_city TEXT DEFAULT '',
  contact_district TEXT DEFAULT '',
  contact_address TEXT DEFAULT '',
  product_id TEXT,
  qty INTEGER DEFAULT 1,
  unit_price NUMERIC DEFAULT 0,
  total_price NUMERIC DEFAULT 0,
  start_date TEXT,
  start_time TEXT,
  end_date TEXT,
  end_time TEXT
);

-- 8. 訂單備註
CREATE TABLE order_notes (
  id TEXT PRIMARY KEY,
  order_id TEXT REFERENCES orders(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TEXT NOT NULL
);

-- 9. 廠商帳號
CREATE TABLE vendor_users (
  id TEXT PRIMARY KEY,
  vendor_id TEXT REFERENCES vendors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  permissions TEXT[] DEFAULT '{view}'
);

-- 10. 使用者角色對應（連接 Supabase Auth）
CREATE TABLE app_users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('admin', 'vendor')),
  vendor_id TEXT REFERENCES vendors(id),
  display_name TEXT
);

-- =============================================
-- 匯入測試資料
-- =============================================

-- 供應商
INSERT INTO vendors VALUES
  ('v1','居家整聊股份有限公司','整聊服務顧問','0905-901-216','sales@tidyman.tw','23456789','台北市信義區信義路五段7號10樓','台灣銀行','001-12345-678901','2025/01/01','2026/12/31','月結30天','{"整理收納","搬家清運"}','{"台北市","新北市","桃園市"}','active',NOW()),
  ('v2','清潔達人有限公司','王經理','0912-345-678','clean@example.tw','34567890','新北市板橋區文化路二段200號','合作金庫','006-23456-789012','2025/06/01','2026/05/31','月結60天','{"清潔除蟲","整理收納"}','{"新北市","桃園市","台中市"}','active',NOW()),
  ('v3','優質工程行','李師傅','0923-456-789','fix@example.tw','45678901','高雄市三民區建工路300號','第一銀行','007-34567-890123','2025/03/01','2027/02/28','即期付款','{"局部修繕"}','{"高雄市","屏東縣","台南市"}','active',NOW());

-- 供應商備註
INSERT INTO vendor_notes VALUES
  ('vn1','v1','2026/03 合約續約完成 ✅','2026/03/01 10:00');

-- 產品
INSERT INTO global_products VALUES
  ('gp1','整理收納','輕享受方案-整理收納×1',2800,1680,0,'price','v1','適合單一空間'),
  ('gp1b','整理收納','輕享受方案-整理收納×1',2800,1960,0,'price','v2','清潔達人版'),
  ('gp2','整理收納','輕享受方案-整理收納×2',5200,3120,0,'price','v1','適合兩個空間'),
  ('gp3','整理收納','深度整理方案',8800,5280,0,'price','v1','全屋深度整理'),
  ('gp4','清潔除蟲','居家深層清潔',3500,2100,0,'price','v2',''),
  ('gp5','清潔除蟲','除蟲防治服務',2000,0,400,'commission','v2','含藥劑費用'),
  ('gp6','清潔除蟲','冷氣清洗',800,480,0,'price','v2','單台'),
  ('gp7','搬家清運','一般搬家服務',5000,3000,0,'price','v1','含基本打包'),
  ('gp8','搬家清運','清運廢棄物',2500,0,500,'commission','v1','以重量計'),
  ('gp9','局部修繕','水電修繕',1500,900,0,'price','v3','基本工資'),
  ('gp10','局部修繕','油漆粉刷',200,120,0,'price','v3','每平方公尺'),
  ('gp11','局部修繕','地板修繕',300,180,0,'price','v3','每平方公尺');

-- 施工人員
INSERT INTO case_handlers VALUES
  ('ch1','v1','陳小明','0921-111-222','chen@tidyman.tw','{"gp1","gp2"}','{"台北市","新北市"}'),
  ('ch2','v1','林美華','0932-333-444','lin@tidyman.tw','{"gp3","gp7"}','{"台北市","桃園市"}'),
  ('ch3','v2','王大偉','0943-555-666','wang@clean.tw','{"gp4","gp5"}','{"台中市","彰化縣"}'),
  ('ch4','v3','李建國','0954-777-888','li@fix.tw','{"gp9","gp10","gp11"}','{"高雄市","屏東縣"}');

-- 排程
INSERT INTO schedules (handler_id, date, status) VALUES
  ('ch1','2026/03/23','available'),('ch1','2026/03/24','available'),('ch1','2026/03/25','available'),
  ('ch2','2026/03/24','available'),('ch2','2026/03/26','available'),
  ('ch3','2026/03/23','available'),('ch3','2026/03/25','available'),
  ('ch4','2026/03/22','available'),('ch4','2026/03/23','available');

-- 訂單
INSERT INTO orders VALUES
  ('o1','ORD-2026-001','assigned','2026/03/01','官網','信用卡','王小明','0912-345-678','wang@example.com','','','台北市','信義區','信義路五段7號','v1','ch1'),
  ('o2','ORD-2026-002','pending','2026/03/05','Line','匯款','陳美麗','0923-456-789','chen@example.com','12345678','陳美麗工作室','新北市','板橋區','文化路一段100號','',''),
  ('o3','ORD-2026-003','completed','2026/03/08','電話','現金','李大華','0934-567-890','','','','台中市','西屯區','台灣大道三段500號','v3','ch4');

-- 訂單任務
INSERT INTO order_tasks VALUES
  ('t1','o1',true,'','','','','','gp1',1,2800,2800,'2026/03/23','10:00','2026/03/23','15:00'),
  ('t2','o2',true,'','','','','','gp4',1,3500,3500,'2026/03/28','09:00','2026/03/28','12:00'),
  ('t3','o3',false,'李太太','0934-567-891','台中市','西屯區','台灣大道三段500號','gp9',2,1500,3000,'2026/03/10','14:00','2026/03/10','17:00'),
  ('t4','o3',true,'','','','','','gp11',3,300,900,'2026/03/11','09:00','2026/03/11','12:00');

-- 訂單備註
INSERT INTO order_notes VALUES
  ('n1','o1','客戶希望重點整理書房 📚','2026/03/01 14:30'),
  ('n2','o3','客戶反饋滿意 ✅','2026/03/11 18:00');

-- 廠商帳號
INSERT INTO vendor_users VALUES
  ('vu1','v1','管理員甲','admin1@tidyman.tw','{"all"}'),
  ('vu2','v1','業務乙','staff1@tidyman.tw','{"view","edit"}'),
  ('vu3','v2','管理員丙','admin@clean.tw','{"all"}'),
  ('vu4','v3','管理員丁','admin@fix.tw','{"all"}');

-- =============================================
-- 啟用 Row Level Security (RLS)
-- =============================================
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE global_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_handlers ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

-- Helper functions
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
  SELECT role FROM app_users WHERE id = auth.uid()
$$ LANGUAGE SQL SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_vendor_id()
RETURNS TEXT AS $$
  SELECT vendor_id FROM app_users WHERE id = auth.uid()
$$ LANGUAGE SQL SECURITY DEFINER;

-- app_users: 使用者可讀自己的資料
CREATE POLICY "Users can read own profile" ON app_users FOR SELECT TO authenticated USING (id = auth.uid());

-- vendors
CREATE POLICY "Admin full access vendors" ON vendors FOR ALL TO authenticated USING (get_user_role() = 'admin') WITH CHECK (get_user_role() = 'admin');
CREATE POLICY "Vendor read own" ON vendors FOR SELECT TO authenticated USING (get_user_role() = 'vendor' AND id = get_user_vendor_id());

-- vendor_notes
CREATE POLICY "Admin full access vendor_notes" ON vendor_notes FOR ALL TO authenticated USING (get_user_role() = 'admin') WITH CHECK (get_user_role() = 'admin');
CREATE POLICY "Vendor read own notes" ON vendor_notes FOR SELECT TO authenticated USING (get_user_role() = 'vendor' AND vendor_id = get_user_vendor_id());

-- global_products
CREATE POLICY "Admin full access products" ON global_products FOR ALL TO authenticated USING (get_user_role() = 'admin') WITH CHECK (get_user_role() = 'admin');
CREATE POLICY "Vendor read products" ON global_products FOR SELECT TO authenticated USING (get_user_role() = 'vendor');

-- case_handlers
CREATE POLICY "Admin full access handlers" ON case_handlers FOR ALL TO authenticated USING (get_user_role() = 'admin') WITH CHECK (get_user_role() = 'admin');
CREATE POLICY "Vendor read own handlers" ON case_handlers FOR SELECT TO authenticated USING (get_user_role() = 'vendor' AND vendor_id = get_user_vendor_id());

-- schedules
CREATE POLICY "Admin full access schedules" ON schedules FOR ALL TO authenticated USING (get_user_role() = 'admin') WITH CHECK (get_user_role() = 'admin');
CREATE POLICY "Vendor manage own schedules" ON schedules FOR ALL TO authenticated USING (get_user_role() = 'vendor' AND handler_id IN (SELECT id FROM case_handlers WHERE vendor_id = get_user_vendor_id())) WITH CHECK (get_user_role() = 'vendor' AND handler_id IN (SELECT id FROM case_handlers WHERE vendor_id = get_user_vendor_id()));

-- orders
CREATE POLICY "Admin full access orders" ON orders FOR ALL TO authenticated USING (get_user_role() = 'admin') WITH CHECK (get_user_role() = 'admin');
CREATE POLICY "Vendor read own orders" ON orders FOR SELECT TO authenticated USING (get_user_role() = 'vendor' AND vendor_id = get_user_vendor_id());

-- order_tasks
CREATE POLICY "Admin full access tasks" ON order_tasks FOR ALL TO authenticated USING (get_user_role() = 'admin') WITH CHECK (get_user_role() = 'admin');
CREATE POLICY "Vendor read own tasks" ON order_tasks FOR SELECT TO authenticated USING (get_user_role() = 'vendor' AND order_id IN (SELECT id FROM orders WHERE vendor_id = get_user_vendor_id()));

-- order_notes
CREATE POLICY "Admin full access notes" ON order_notes FOR ALL TO authenticated USING (get_user_role() = 'admin') WITH CHECK (get_user_role() = 'admin');
CREATE POLICY "Vendor read own notes" ON order_notes FOR SELECT TO authenticated USING (get_user_role() = 'vendor' AND order_id IN (SELECT id FROM orders WHERE vendor_id = get_user_vendor_id()));

-- vendor_users
CREATE POLICY "Admin full access vendor_users" ON vendor_users FOR ALL TO authenticated USING (get_user_role() = 'admin') WITH CHECK (get_user_role() = 'admin');
CREATE POLICY "Vendor read own users" ON vendor_users FOR SELECT TO authenticated USING (get_user_role() = 'vendor' AND vendor_id = get_user_vendor_id());

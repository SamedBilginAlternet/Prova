-- =============================================
-- Prova App — Seed Garments (MVP Catalog)
-- Run after uploading images to garment-images bucket
-- =============================================

-- Placeholder seed data — replace storage_path values with actual uploaded paths
-- Image naming convention: garments/{id}/original.jpg, garments/{id}/thumb.jpg

insert into public.garments (name_tr, name_en, brand, category, color, storage_path, thumbnail_path) values
  ('Beyaz Oversize Tişört', 'White Oversize T-Shirt', 'Prova Basics', 'top', 'beyaz', 'placeholders/white-tshirt.jpg', 'placeholders/white-tshirt-thumb.jpg'),
  ('Siyah Crop Tişört', 'Black Crop T-Shirt', 'Prova Basics', 'top', 'siyah', 'placeholders/black-crop.jpg', 'placeholders/black-crop-thumb.jpg'),
  ('Lacivert Blazer', 'Navy Blazer', 'Prova Studio', 'top', 'lacivert', 'placeholders/navy-blazer.jpg', 'placeholders/navy-blazer-thumb.jpg'),
  ('Ekru Triko Kazak', 'Ecru Knit Sweater', 'Prova Basics', 'top', 'ekru', 'placeholders/ecru-knit.jpg', 'placeholders/ecru-knit-thumb.jpg'),
  ('Çizgili Uzun Kollu', 'Striped Long Sleeve', 'Prova Basics', 'top', 'beyaz/siyah', 'placeholders/striped-ls.jpg', 'placeholders/striped-ls-thumb.jpg'),
  ('Siyah Yüksek Bel Pantolon', 'Black High-Waist Pants', 'Prova Studio', 'bottom', 'siyah', 'placeholders/black-pants.jpg', 'placeholders/black-pants-thumb.jpg'),
  ('Mavi Straight Jean', 'Blue Straight Jeans', 'Prova Denim', 'bottom', 'mavi', 'placeholders/blue-jeans.jpg', 'placeholders/blue-jeans-thumb.jpg'),
  ('Krem Bol Pantolon', 'Cream Wide-Leg Pants', 'Prova Studio', 'bottom', 'krem', 'placeholders/cream-wide.jpg', 'placeholders/cream-wide-thumb.jpg'),
  ('Siyah Mini Etek', 'Black Mini Skirt', 'Prova Basics', 'bottom', 'siyah', 'placeholders/black-mini.jpg', 'placeholders/black-mini-thumb.jpg'),
  ('Bej Midi Etek', 'Beige Midi Skirt', 'Prova Studio', 'bottom', 'bej', 'placeholders/beige-midi.jpg', 'placeholders/beige-midi-thumb.jpg'),
  ('Siyah Midi Elbise', 'Black Midi Dress', 'Prova Studio', 'dress', 'siyah', 'placeholders/black-midi-dress.jpg', 'placeholders/black-midi-dress-thumb.jpg'),
  ('Beyaz Yazlık Elbise', 'White Summer Dress', 'Prova Basics', 'dress', 'beyaz', 'placeholders/white-dress.jpg', 'placeholders/white-dress-thumb.jpg'),
  ('Bej Trençkot', 'Beige Trench Coat', 'Prova Studio', 'outerwear', 'bej', 'placeholders/trench.jpg', 'placeholders/trench-thumb.jpg'),
  ('Siyah Oversize Ceket', 'Black Oversize Jacket', 'Prova Studio', 'outerwear', 'siyah', 'placeholders/black-jacket.jpg', 'placeholders/black-jacket-thumb.jpg');

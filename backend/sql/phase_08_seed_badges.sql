-- StreetWatch Phase 8: seed default badges
-- Run this after phase_07_point_transactions.sql

insert into public.badges (code, name, description, points_reward)
values
  ('first_report', 'First Report', 'Submit your first infrastructure report', 50),
  ('verified_reporter', 'Verified Reporter', 'Get your first report verified', 75),
  ('sharp_eye', 'Sharp Eye', 'Submit 10 reports', 100),
  ('street_guardian', 'Street Guardian', 'Submit 25 reports', 150),
  ('century_club', 'Century Club', 'Submit 100 reports', 400),
  ('community_hero', 'Community Hero', 'Reach 1000 points', 0),
  ('fast_responder', 'Fast Responder', 'Reach 10 verified reports', 150),
  ('top_reporter', 'Top Reporter', 'Reach 2500 points', 0),
  ('first_vote', 'Civic Validator', 'Cast your first report vote', 20)
on conflict (code) do nothing;

# Arete

Arete is a Flutter and Supabase learning application for undergraduate Python
and data-science education. It combines formative lessons and quizzes with XP,
levels, badges, streaks, daily challenges, a leaderboard, and an open student
model that visualises skill mastery and recommends lessons from weaker skills.

## Research scope

The application supports an MSc evaluation of gamification and open student
modelling. It records consented learning activity, pre/post knowledge
assessments, System Usability Scale (SUS) responses, Intrinsic Motivation
Inventory (IMI) subscales, skill mastery, and lesson duration.

The software and analysis pipeline do not by themselves prove effectiveness.
Statistical conclusions must only be reported after the approved study has a
sufficient number of genuine, eligible participants and complete paired data.

## Technology

- Flutter for web and mobile clients
- Supabase Authentication and PostgreSQL
- Row-level security for participant records
- `fl_chart` for learner and research visualisations
- Python research scripts for pseudonymised exports and statistical analysis

## Local setup

1. Install the Flutter SDK supported by `pubspec.yaml`.
2. Create a Supabase project.
3. Apply `supabase/schema.sql`, then `supabase/seed.sql`.
4. Configure the Supabase URL and anonymous client key for the target
   environment. Never place a service-role key in the application.
5. Run `flutter pub get`.
6. Run `flutter run -d chrome` or another supported Flutter target.

For an existing Supabase project, reapply `supabase/schema.sql`. It uses
idempotent table, column, policy, and function definitions to add the current
research tables and quiz timing fields.

## Researcher access

Aggregate analytics are restricted to accounts listed in `researcher_roles`.
Grant access from the Supabase SQL editor using an administrator account:

```sql
insert into researcher_roles (user_id)
values ('RESEARCHER_PROFILE_UUID')
on conflict (user_id) do nothing;
```

Participants cannot grant this role to themselves. Leaderboard data is exposed
through a limited database function and does not require access to complete
profile records.

## Research data model

- `knowledge_assessments`: dedicated pre/post raw and maximum scores
- `feedback_responses`: SUS scores and optional open feedback
- `imi_responses`: four SDT-related IMI subscales and item responses
- `quiz_attempts`: raw score, maximum score, start time, and duration
- `learning_sessions`: lesson start/end and duration
- `skill_mastery`: the open student model's per-skill mastery values
- `user_goals`: learner-selected skill and target mastery

See [docs/data_dictionary.md](docs/data_dictionary.md) for definitions and
[docs/research_workflow.md](docs/research_workflow.md) for data-quality,
anonymisation, and analysis procedures.

## Verification

```text
flutter analyze
flutter test
```

Tests cover XP-to-level boundaries, mastery updates, score normalisation, and
SUS scoring. Database policies should additionally be exercised in a Supabase
staging project with participant and researcher accounts.

## Research scripts

`research_data_export.py` creates a structured workbook from the research
tables. `research_analysis.py` performs eligible quantitative analyses and
creates a pseudonymised qualitative-coding sheet. Thematic codes and themes
must be assigned and reviewed by the researcher; the script does not fabricate
qualitative findings.

Both scripts request the Supabase service-role key interactively. Use them only
on a trusted research machine and never commit or log that key.

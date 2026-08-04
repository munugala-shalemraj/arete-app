# Arete research data dictionary

All timestamps are stored in UTC. Participant-linked tables use the Supabase
profile UUID internally; exported analytical data should replace it with a
study-specific participant code.

| Table | Field | Type / range | Meaning |
|---|---|---|---|
| profiles | xp | integer, >= 0 | Total experience points earned |
| profiles | level | integer, >= 1 | `floor(xp / 100) + 1` |
| profiles | streak_days | integer, >= 0 | Consecutive active learning days |
| quiz_attempts | score | integer, 0..max_score | Correct quiz answers |
| quiz_attempts | max_score | integer, > 0 | Questions scored in the attempt |
| quiz_attempts | duration_seconds | integer, >= 0 | Elapsed quiz time when available |
| learning_sessions | duration_seconds | integer, >= 0 | Time spent in a lesson |
| skill_mastery | mastery_score | float, 0..1 | Blended mastery estimate for one skill |
| knowledge_assessments | assessment_type | `pre` or `post` | Evaluation time point |
| knowledge_assessments | score | integer, 0..max_score | Correct assessment answers |
| knowledge_assessments | max_score | integer, > 0 | Assessment question count |
| feedback_responses | sus_score | float, 0..100 | Standard SUS score |
| feedback_responses | open_feedback | text, optional | Participant's qualitative feedback |
| imi_responses | interest_enjoyment | float, 1..7 | IMI interest/enjoyment mean |
| imi_responses | perceived_competence | float, 1..7 | IMI competence mean |
| imi_responses | perceived_choice | float, 1..7 | IMI autonomy/choice mean |
| imi_responses | relatedness | float, 1..7 | IMI relatedness mean |
| imi_responses | responses | JSON object | Raw item-level Likert responses |
| user_goals | target_pct | integer, 1..100 | Learner-selected mastery target |

Derived percentages must use `score / max_score`; raw scores from quizzes of
different lengths must never be averaged directly.

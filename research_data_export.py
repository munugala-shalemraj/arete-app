"""
Arete Research Data Export
===========================
Pulls all participant data from Supabase and writes a clean
Excel workbook with one sheet per data type + a summary sheet.

Usage:
    pip install requests pandas openpyxl
    python research_data_export.py

You will be prompted for your Supabase service role key.
"""

import getpass
import sys
from datetime import datetime

try:
    import requests
    import pandas as pd
except ImportError:
    print("Missing dependencies. Run:  pip install requests pandas openpyxl")
    sys.exit(1)

SUPABASE_URL = "https://iscrbkcqzkqludqoobnj.supabase.co"

# ── Auth ──────────────────────────────────────────────────────────────────────

service_key = getpass.getpass("Enter Supabase service role key: ").strip()

headers = {
    "apikey":        service_key,
    "Authorization": f"Bearer {service_key}",
    "Content-Type":  "application/json",
}

# ── Fetch helpers ─────────────────────────────────────────────────────────────

def fetch(table, select="*", filters=""):
    url = f"{SUPABASE_URL}/rest/v1/{table}?select={select}{filters}"
    resp = requests.get(url, headers=headers)
    if resp.status_code != 200:
        print(f"  ERROR fetching {table}: {resp.status_code} {resp.text}")
        return []
    return resp.json()

# ── Pull data ─────────────────────────────────────────────────────────────────

print("\nFetching data from Supabase...")

profiles      = fetch("profiles",           "id,username,display_name,xp,level,streak_days,created_at")
feedback      = fetch("feedback_responses", "id,user_id,sus_score,imi_score,open_feedback,submitted_at")
imi           = fetch("imi_responses",      "id,user_id,interest_enjoyment,perceived_competence,perceived_choice,relatedness,submitted_at")
assessments   = fetch("knowledge_assessments", "id,user_id,assessment_type,score,max_score,submitted_at")
quiz_attempts = fetch("quiz_attempts",      "id,user_id,lesson_id,score,max_score,completed_at,started_at,duration_seconds")
skill_mastery = fetch("skill_mastery",      "user_id,skill_name,mastery_score,updated_at")

print(f"  Profiles:       {len(profiles)}")
print(f"  Feedback rows:  {len(feedback)}")
print(f"  IMI rows:       {len(imi)}")
print(f"  Assessments:    {len(assessments)}")
print(f"  Quiz attempts:  {len(quiz_attempts)}")
print(f"  Skill mastery:  {len(skill_mastery)}")

# ── DataFrames ────────────────────────────────────────────────────────────────

df_profiles = pd.DataFrame(profiles) if profiles else pd.DataFrame()
df_feedback = pd.DataFrame(feedback) if feedback else pd.DataFrame()
df_imi      = pd.DataFrame(imi)      if imi      else pd.DataFrame()
df_assessments = pd.DataFrame(assessments) if assessments else pd.DataFrame()
df_quiz     = pd.DataFrame(quiz_attempts) if quiz_attempts else pd.DataFrame()
df_skills   = pd.DataFrame(skill_mastery) if skill_mastery else pd.DataFrame()

# ── Parse pre/post test from feedback_responses ───────────────────────────────

if not df_assessments.empty:
    df_assessments["test_score"] = (
        df_assessments["score"] / df_assessments["max_score"]
    )
    df_pre = df_assessments[df_assessments["assessment_type"] == "pre"][[
        "user_id", "test_score", "submitted_at"
    ]].rename(columns={"test_score": "pre_test_score", "submitted_at": "pre_test_date"})
    df_post = df_assessments[df_assessments["assessment_type"] == "post"][[
        "user_id", "test_score", "submitted_at"
    ]].rename(columns={"test_score": "post_test_score", "submitted_at": "post_test_date"})
else:
    df_pre = pd.DataFrame(columns=["user_id", "pre_test_score", "pre_test_date"])
    df_post = pd.DataFrame(columns=["user_id", "post_test_score", "post_test_date"])

if not df_feedback.empty:
    df_feedback["test_type"] = df_feedback["open_feedback"].apply(
        lambda x: "pre_test"  if isinstance(x, str) and x.startswith("pre_test_score:")
             else "post_test" if isinstance(x, str) and x.startswith("post_test_score:")
             else "sus_survey" if pd.notna(df_feedback.get("sus_score", pd.Series()).iloc[0] if not df_feedback.empty else None)
             else "other"
    )
    # Re-derive cleanly per row
    def classify(row):
        fb = row.get("open_feedback", "")
        if isinstance(fb, str) and fb.startswith("pre_test_score:"):
            return "pre_test"
        if isinstance(fb, str) and fb.startswith("post_test_score:"):
            return "post_test"
        if pd.notna(row.get("sus_score")):
            return "sus_survey"
        return "other"

    df_feedback["test_type"]  = df_feedback.apply(classify, axis=1)
    df_feedback["test_score"] = df_feedback["open_feedback"].apply(
        lambda x: float(x.split(":")[1]) if isinstance(x, str) and ":" in x else None
    )

    if df_assessments.empty:
        df_pre  = df_feedback[df_feedback["test_type"] == "pre_test" ][["user_id", "test_score", "submitted_at"]].rename(
            columns={"test_score": "pre_test_score", "submitted_at": "pre_test_date"})
        df_post = df_feedback[df_feedback["test_type"] == "post_test"][["user_id", "test_score", "submitted_at"]].rename(
            columns={"test_score": "post_test_score", "submitted_at": "post_test_date"})
    df_sus  = df_feedback[df_feedback["test_type"] == "sus_survey"][["user_id", "sus_score", "submitted_at"]].rename(
        columns={"submitted_at": "sus_date"})
else:
    df_sus  = pd.DataFrame(columns=["user_id", "sus_score", "sus_date"])

# ── IMI average per participant ───────────────────────────────────────────────

if not df_imi.empty:
    df_imi_agg = df_imi.groupby("user_id").agg(
        imi_interest_enjoyment  =("interest_enjoyment",  "mean"),
        imi_perceived_competence=("perceived_competence","mean"),
        imi_perceived_choice    =("perceived_choice",    "mean"),
        imi_relatedness         =("relatedness",         "mean"),
        imi_submissions         =("id",                  "count"),
    ).reset_index()
    df_imi_agg["imi_overall_mean"] = df_imi_agg[[
        "imi_interest_enjoyment", "imi_perceived_competence",
        "imi_perceived_choice",   "imi_relatedness",
    ]].mean(axis=1).round(3)
else:
    df_imi_agg = pd.DataFrame(columns=["user_id"])

# ── Quiz stats per participant ────────────────────────────────────────────────

if not df_quiz.empty:
    df_quiz["score_ratio"] = df_quiz.apply(
        lambda row: row["score"] / row["max_score"]
        if pd.notna(row.get("max_score")) and row["max_score"] > 0 else None,
        axis=1,
    )
    df_quiz_agg = df_quiz.groupby("user_id").agg(
        quizzes_attempted=("id",    "count"),
        avg_quiz_score   =("score_ratio", "mean"),
        max_quiz_score   =("score_ratio", "max"),
        min_quiz_score   =("score_ratio", "min"),
    ).reset_index()
    df_quiz_agg["avg_quiz_score"] = df_quiz_agg["avg_quiz_score"].round(3)
else:
    df_quiz_agg = pd.DataFrame(columns=["user_id"])

# ── Skill mastery pivot ───────────────────────────────────────────────────────

if not df_skills.empty:
    df_skills_pivot = df_skills.pivot_table(
        index="user_id", columns="skill_name",
        values="mastery_score", aggfunc="last"
    ).reset_index()
    df_skills_pivot.columns.name = None
else:
    df_skills_pivot = pd.DataFrame(columns=["user_id"])

# ── Build per-participant summary ─────────────────────────────────────────────

if not df_profiles.empty:
    summary = df_profiles.rename(columns={
        "id": "user_id", "display_name": "display_name", "username": "username"
    }).copy()

    for df_merge, on in [
        (df_pre,         "user_id"),
        (df_post,        "user_id"),
        (df_sus,         "user_id"),
        (df_imi_agg,     "user_id"),
        (df_quiz_agg,    "user_id"),
        (df_skills_pivot,"user_id"),
    ]:
        if not df_merge.empty:
            summary = summary.merge(df_merge, on=on, how="left")

    # Learning gain = post - pre
    if "pre_test_score" in summary.columns and "post_test_score" in summary.columns:
        summary["learning_gain"] = (
            summary["post_test_score"] - summary["pre_test_score"]
        ).round(3)

    # Completion flags
    summary["completed_pre_test"]  = summary.get("pre_test_score",  pd.Series()).notna()
    summary["completed_post_test"] = summary.get("post_test_score", pd.Series()).notna()
    summary["completed_imi"]       = summary.get("imi_submissions",  pd.Series()).notna()
    summary["completed_sus"]       = summary.get("sus_score",        pd.Series()).notna()
else:
    summary = pd.DataFrame()

# ── Write Excel workbook ──────────────────────────────────────────────────────

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
filename  = f"arete_research_data_{timestamp}.xlsx"

print(f"\nWriting {filename}...")

with pd.ExcelWriter(filename, engine="openpyxl") as writer:

    # Sheet 1 — Participant Summary (main analysis sheet)
    if not summary.empty:
        summary.to_excel(writer, sheet_name="Participant Summary", index=False)

    # Sheet 2 — Pre & Post Test Scores
    if not df_assessments.empty:
        df_assessments.to_excel(writer, sheet_name="Pre & Post Tests", index=False)
    elif not df_pre.empty or not df_post.empty:
        tests = pd.concat([df_pre, df_post], ignore_index=True) if not df_post.empty else df_pre
        tests.to_excel(writer, sheet_name="Pre & Post Tests", index=False)

    # Sheet 3 — IMI Motivation Survey (raw)
    if not df_imi.empty:
        df_imi.to_excel(writer, sheet_name="IMI Survey", index=False)

    # Sheet 4 — SUS Usability Survey
    if not df_sus.empty:
        df_sus.to_excel(writer, sheet_name="SUS Survey", index=False)

    # Sheet 5 — Quiz Attempts (raw)
    if not df_quiz.empty:
        df_quiz.to_excel(writer, sheet_name="Quiz Attempts", index=False)

    # Sheet 6 — Skill Mastery
    if not df_skills.empty:
        df_skills.to_excel(writer, sheet_name="Skill Mastery", index=False)

    # Sheet 7 — Profiles
    if not df_profiles.empty:
        df_profiles.to_excel(writer, sheet_name="Profiles", index=False)

    # Auto-fit column widths
    for sheet in writer.sheets.values():
        for col in sheet.columns:
            max_len = max(
                (len(str(cell.value)) for cell in col if cell.value is not None),
                default=10
            )
            sheet.column_dimensions[col[0].column_letter].width = min(max_len + 4, 40)

print(f"\nDone. Saved: {filename}")
print("\nSheets included:")
print("  1. Participant Summary  — one row per participant, all measures merged")
print("  2. Pre & Post Tests     — raw pre/post test scores")
print("  3. IMI Survey           — motivation subscale scores")
print("  4. SUS Survey           — usability scores")
print("  5. Quiz Attempts        — every quiz attempt with score")
print("  6. Skill Mastery        — skill mastery scores per participant")
print("  7. Profiles             — XP, level, streak data")

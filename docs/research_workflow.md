# Research workflow

## Collection

1. Show the approved participant information and consent flow before account
   creation.
2. Exclude accounts without valid consent and accounts belonging to developers,
   supervisors, or testers from the study dataset.
3. Collect the pre-test before learning activity and the post-test after the
   defined intervention period.
4. Collect SUS, IMI, open feedback, quiz attempts, and learning-session data
   according to the approved protocol.

## Data-quality checks

Before analysis:

- confirm participant eligibility and consent;
- label pilot, test, withdrawn, and excluded accounts;
- check duplicate pre/post, SUS, and IMI submissions;
- verify `0 <= score <= max_score` and valid survey ranges;
- investigate missing or negative durations;
- report missing-data handling and every exclusion;
- calculate quiz percentages from both `score` and `max_score`;
- do not treat account count as completed-participant count.

## Pseudonymisation and access

Use study codes such as `P001` in analytical outputs. Keep the re-identification
mapping separate from exported research data and restrict it to the researcher
and supervisor when required. Aggregate analytics in the app require an entry
in `researcher_roles`; the service-role key is never used by the client.

## Quantitative analysis

Run paired pre/post analysis only for participants who completed both measures.
Report sample size, descriptive statistics, confidence intervals, the test and
its assumptions, p-value, and effect size. Treat SUS and IMI results as
descriptive when the achieved sample cannot support inference.

## Qualitative analysis

The analysis script exports pseudonymised feedback with blank `initial_code`,
`theme`, and `researcher_notes` columns. The researcher must read all responses,
develop and document a codebook, code the data consistently, review themes, and
retain an audit trail. Automated keyword counts are not a substitute for
thematic analysis.

## Retention and deletion

Follow the approved Newcastle University data-management plan. Store raw data
and the re-identification mapping only in approved restricted storage, keep
documented backups, record the retention deadline, and securely delete data at
withdrawal or expiry when required by the ethics approval. These are procedural
controls and cannot be guaranteed solely by application code.

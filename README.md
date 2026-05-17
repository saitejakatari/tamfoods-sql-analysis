# TamFoods Business Insights

SQL analysis of a fictional Chennai food-delivery platform's April 2026 data — surfacing a failed restaurant launch, supply gaps across four neighborhoods, and a counter-intuitive finding about customer tier value.

---

## 📋 The business question

TamFoods is a fictional food-delivery platform operating across four Chennai 
neighborhoods — Adyar, Mylapore, T. Nagar, and Velachery — with 12 partner 
restaurants spanning South Indian, Fast Food, Chinese, and Sweets cuisines.

The brief from the operations lead, Lakshmi: *"Here's last month's data. The 
exec team wants a read on how things are going. Can you put together findings 
by end of week?"* — a deliberately open-ended ask with no specific question, 
typical of how real analyst work begins.

This analysis answers that brief through a structured SQL workflow: profile 
the data, surface the biggest revenue and operational patterns, then dig into 
specific anomalies worth flagging.

---

## 📊 The dataset

The analysis uses two synthetic relational tables modeling a real food-
delivery platform's data structure:

- **`restaurants`** (12 rows) — restaurant_id, restaurant_name, area, cuisine, 
  opened_date
- **`orders`** (200 rows) — order_id, restaurant_id, customer_id, order_value, 
  payment_method, order_date, customer_rating, delivery_time_min, 
  items_count, customer_tier, time_of_day, day_type

The two tables are joined via `restaurant_id`. The dataset spans April 1–30, 
2026 (a single month), covering ~₹95,000 in total revenue across 4 cuisine 
categories and 4 Chennai neighborhoods.

> **Note:** The data is fictional, generated for portfolio purposes. The 
> restaurants and areas are real Chennai names; the numbers and patterns 
> are designed to surface analytically interesting findings.
> columns like `time_of_day` and `day_type` are available for future 
> exploration but weren't part of this initial analysis.

---

## Key findings

### 1. Madras Halwa Co — failure to launch

Madras Halwa Co, TamFoods' newest restaurant (Sweets, T. Nagar, opened 
December 2025), received **zero orders** during the entire month of April 
2026 — despite being the platform's only Sweets-category option.

This was surfaced using a **LEFT JOIN + IS NULL anti-join pattern** — a query 
shape that explicitly preserves restaurants with no matching orders, instead 
of silently dropping them as a standard INNER JOIN would.

**Business implication:** A four-month-old launch with zero pickup needs 
escalation to the partnerships team — either the restaurant has a setup 
issue (menu, photos, listing visibility) or the Sweets category itself 
isn't a viable vertical at this scale.

---

### 2. Cuisine-area supply gaps

Two of TamFoods' four neighborhoods are missing the platform's top-revenue 
cuisine: **Adyar and Velachery have zero South Indian restaurants**, despite 
South Indian generating ₹51,308 (54% of total monthly revenue) in the two 
areas that do offer it. Conversely, **Mylapore and T. Nagar have zero 
Fast Food or Chinese options** — categories that together generated ₹43,281 
in revenue from the other two areas.

This was surfaced using a **2D GROUP BY** on (area, cuisine) — the SQL 
equivalent of a pivot table with two grouping dimensions. The "finding" is 
not in the visible rows but in the **combinations that are missing from 
the output** — those absences are themselves the supply gaps.

**Business implication:** Each gap likely represents revenue currently going 
to competitor platforms. Highest-leverage move is recruiting 1–2 South 
Indian restaurants in Velachery, where existing order volume (63 orders 
across Fast Food and Chinese) confirms a healthy customer base ready for 
the strongest cuisine vertical.

---

### 3. Customer tier inversion — Bronze outspends Platinum per customer

A look at customer tier revenue reveals an unexpected pattern: per-customer 
revenue **decreases** as tier rises. Bronze customers averaged **₹1,353 per 
person**, Silver ₹1,254, Gold ₹1,184, and **Platinum just ₹1,074** — a 
clean inverse relationship across all four tiers.

This was surfaced by computing three aggregations in one query: `SUM(order_value)` 
for total revenue, `COUNT(DISTINCT customer_id)` for unique customer count, 
and a division of the two for per-customer revenue. **Without the per-customer 
metric, the raw revenue numbers would suggest Bronze is the most valuable tier 
— it's the largest by total revenue (₹48,728 vs. Platinum's ₹5,370). 
But that's an artifact of having 7x more Bronze customers, not higher per-person 
value.**

**Business implication:** If TamFoods' loyalty tiers are intended to reward 
high-spend customers, the assignment logic may not be working as designed. 
Recommended next step is auditing the tier-assignment criteria — is tier 
based on lifetime spend, order frequency, signup date, or something else? 
The answer determines whether this is a definitional mismatch or a genuine 
program-design issue.

---

## 🛠️ Tech used

**Tools**
- **SQLite** — relational database (chosen for its zero-setup local 
  deployment, ideal for portfolio work)
- **VS Code + SQLite extension (by alexcvzz)** — query development, 
  execution, and results viewing
- **Code Spell Checker (VS Code extension)** — automated typo detection 
  during SQL and markdown polish passes

**SQL Techniques demonstrated**
- Multi-table JOINs (INNER JOIN, LEFT JOIN)
- Anti-join pattern (LEFT JOIN + IS NULL) for "find records with no match" 
  queries
- GROUP BY with multi-column grouping (2D crosstab)
- HAVING with multiple group-level conditions (combining filters with AND)
- Aggregate functions: SUM, COUNT, AVG, MIN, MAX, COUNT(DISTINCT)
- Aggregation arithmetic (dividing one aggregate by another for ratio metrics)
- Defensive analyst habits: table aliasing, explicit ON clauses, 
  ROUND() for output, semicolon terminators

---

## 🚀 How to run

This project uses SQLite, which requires no installation or login. Setup 
takes ~5 minutes.

### Prerequisites
- Any text editor or SQL client (VS Code with the SQLite extension by 
  alexcvzz is recommended)
- Python 3 installed on your system (used only as a one-line utility to 
  load the data — no Python skill required)

### Step 1 — Clone or download this repository

```bash
git clone https://github.com/[your-username]/tamfoods-sql-analysis.git
cd tamfoods-sql-analysis
```

### Step 2 — Build the database from the SQL setup script

The `tamfoods.sql` script defines the schema (two tables) and inserts all 
data (200 orders + 12 restaurants). Run it once to create a local SQLite 
database file:

```bash
python -c "import sqlite3; conn=sqlite3.connect('tamfoods.db'); conn.executescript(open('tamfoods.sql').read()); conn.commit(); conn.close(); print('Database created.')"
```

(This one-liner uses Python's built-in `sqlite3` module to execute the SQL 
setup script — no additional packages needed. Any Python 3 install works.)

You should see `Database created.` printed, and a new file `tamfoods.db` 
will appear in the folder.

### Step 3 — Connect and explore

Open `tamfoods.db` in your SQL client of choice. In VS Code, this is:
- Press `Ctrl + Shift + P`
- Type **"SQLite: Open Database"** and select `tamfoods.db`
- The two tables (`orders`, `restaurants`) appear in the SQLite Explorer 
  sidebar

### Step 4 — Run the analysis

Open `tamfoods_analysis.sql`. Run individual queries by:
- Highlighting the query you want to run, OR
- Right-clicking inside it and selecting **"Run Query"**

Each query has a comment block above it explaining the business question, 
expected output, and any caveats. See the **KEY FINDINGS** block at the 
bottom of the file for a summary.

---

## 🌱 What's next

This SQL analysis is the first portfolio project in a broader data analytics 
learning path. Planned extensions:

- **Python + pandas reanalysis** — rebuild the same business questions in 
  pandas to demonstrate tool flexibility and prepare for production analytics 
  workflows
- **Visualization layer** — add matplotlib/seaborn charts to communicate the 
  cuisine-area gap and tier-inversion findings visually
- **AI-augmented analysis** — connect an LLM-based interface so a non-
  technical user (like Lakshmi) could ask questions of the database in 
  natural language

If you have feedback, questions, or spot anything I missed, please open an 
issue or reach out via [LinkedIn](https://www.linkedin.com/in/saitejakatari/).

---
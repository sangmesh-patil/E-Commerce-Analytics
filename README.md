\# Brazilian E-Commerce Analytics \& Relational Database Pipeline



\## 📌 Project Overview

This project processes the \*\*Olist Brazilian E-Commerce Dataset\*\* (\~100,000 orders from 2016-2018). It demonstrates a complete end-to-end data pipeline starting from raw staging ingestion and data quality profiling, moving into dimensional modeling (3NF), and culminating in advanced SQL analytics covering window functions, recursive CTEs, and query optimization.



\## 🗄️ Database Architecture (3NF Schema)

The raw dataset was normalized into a Third Normal Form (3NF) relational schema to ensure referential integrity, eliminate data anomalies, and prepare the dataset for enterprise-grade analytics.



```mermaid

erDiagram

&#x20;   dim\_geolocation ||--o{ dim\_customers : "provides spatial data"

&#x20;   dim\_geolocation ||--o{ dim\_sellers : "provides spatial data"

&#x20;   dim\_customers ||--o{ fact\_orders : "places"

&#x20;   fact\_orders ||--o{ fact\_order\_items : "contains"

&#x20;   fact\_orders ||--o{ fact\_order\_payments : "paid via"

&#x20;   fact\_orders ||--o| fact\_order\_reviews : "receives"

&#x20;   dim\_products ||--o{ fact\_order\_items : "is sold as"

&#x20;   dim\_sellers ||--o{ fact\_order\_items : "fulfills"



&#x20;   dim\_geolocation {

&#x20;       varchar zip\_code\_prefix PK

&#x20;       numeric lat

&#x20;       numeric lng

&#x20;       varchar city

&#x20;       varchar state

&#x20;   }

&#x20;   dim\_customers {

&#x20;       varchar customer\_id PK

&#x20;       varchar customer\_unique\_id

&#x20;       varchar zip\_code\_prefix FK

&#x20;   }

&#x20;   fact\_orders {

&#x20;       varchar order\_id PK

&#x20;       varchar customer\_id FK

&#x20;       timestamp order\_purchase\_timestamp

&#x20;       varchar order\_status

&#x20;   }

&#x20;   fact\_order\_items {

&#x20;       varchar order\_id PK,FK

&#x20;       int order\_item\_id PK

&#x20;       varchar product\_id FK

&#x20;       varchar seller\_id FK

&#x20;       numeric price

&#x20;       numeric freight\_value

&#x20;   }



E-Commerce-Analytics/

│

├── Data/                              # (Ignored via .gitignore)

│

├── docs/

│   └── data\_quality\_report.md         # Comprehensive profiling report

│

├── SQL\_Scripts/

│   ├── 01\_DDL\_and\_Data\_Load.sql       # Creates staging tables and loads raw CSVs

│   ├── 02\_Data\_Cleaning\_and\_Load.sql  # Cleans, dedupes, and populates 3NF schema

│   ├── 03\_Subqueries\_and\_CTEs.sql     # Recursive hierarchies and cohort analysis

│   ├── 04\_Window\_Functions.sql        # Moving averages, LAG gaps, running totals

│   └── 05\_Optimization.sql            # Stored procedures, indexes, EXPLAIN ANALYZE

│

├── .gitignore

└── README.md


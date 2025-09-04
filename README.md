# E-commerce Analytics Platform

A comprehensive analytics platform for e-commerce data analysis, featuring advanced SQL queries, cloud infrastructure, and interactive dashboards.

## Project Overview

This platform provides comprehensive analytics capabilities for e-commerce businesses, including customer segmentation, product performance analysis, and sales trend reporting.

## Database Schema

The database consists of 6 main tables with proper relationships:

### Core Tables
- **customers** - Customer information with segmentation
- **products** - Product catalog with categories and pricing
- **orders** - Order transactions with status tracking
- **order_items** - Junction table linking orders and products
- **reviews** - Product reviews and ratings
- **payments** - Payment transaction details

### Key Features
- Proper foreign key relationships
- Indexed columns for performance
- Realistic sample data (15 customers, 15 products, 15 orders)
- Customer segmentation (Bronze, Silver, Gold, Platinum)
- Multiple product categories and brands

## Getting Started

### Prerequisites

#### Local Development
- MySQL 8.0+ or compatible database
- Database management tool (MySQL Workbench, phpMyAdmin, etc.)
- Python 3.9+ (for AWS Lambda functions)

#### AWS Cloud Deployment
- AWS CLI configured with appropriate permissions
- AWS Account with billing enabled
- jq command-line JSON processor

### Installation Options

#### Option 1: Local Development
1. **Create the database schema:**
   ```sql
   SOURCE database_schema.sql;
   ```

2. **Load sample data:**
   ```sql
   SOURCE sample_data.sql;
   ```

3. **Run analytics queries:**
   ```sql
   SOURCE analytics_queries.sql;
   ```

#### Option 2: AWS Cloud Deployment
1. **Deploy infrastructure:**
   ```bash
   ./aws-deployment/deploy.sh dev
   ```

2. **Connect to RDS database:**
   ```bash
   mysql -h <RDS_ENDPOINT> -u admin -p ecommerce
   ```

3. **Load data and run queries:**
   ```sql
   SOURCE database_schema.sql;
   SOURCE sample_data.sql;
   SOURCE analytics_queries.sql;
   ```

## SQL Skills Demonstrated

### Aggregations
- SUM, AVG, COUNT functions
- GROUP BY clauses
- HAVING conditions

### Joins
- INNER JOIN for related data
- LEFT JOIN for optional relationships
- RIGHT JOIN for comprehensive data
- Complex multi-table joins

### Window Functions
- ROW_NUMBER() for ranking
- RANK() and DENSE_RANK() for tied rankings
- LAG() and LEAD() for time series analysis
- Running totals and moving averages

### Advanced Techniques
- Common Table Expressions (CTEs)
- Subqueries and correlated subqueries
- CASE statements for conditional logic
- Date/time functions for temporal analysis

## AWS Architecture

### Core Services
- **RDS MySQL** - Managed database service
- **S3** - Data lake storage
- **Lambda** - Serverless compute for data processing
- **Glue** - ETL service for data transformation
- **Athena** - Serverless query service for data lake
- **QuickSight** - Business intelligence dashboards

### Data Pipeline
1. **Data Ingestion** - RDS MySQL stores transactional data
2. **ETL Processing** - AWS Glue transforms data for analytics
3. **Data Lake** - S3 stores processed data in Parquet format
4. **Analytics** - Athena queries data lake for insights
5. **Visualization** - QuickSight creates interactive dashboards

## File Structure

```
ECommerce-Platform/
├── database_schema.sql          # Database schema definition
├── sample_data.sql             # Sample data for testing
├── analytics_queries.sql       # Core analytics queries
├── advanced_queries.sql        # Advanced analytical queries
├── setup_instructions.sql      # Database setup guide
├── dashboard.html              # Interactive web dashboard
├── requirements.txt            # Python dependencies
├── README.md                   # Project documentation
└── aws-infrastructure/         # AWS deployment files
    ├── cloudformation-template.yaml
    ├── parameters-dev.json
    └── parameters-dev2.json
└── aws-lambda/                 # Lambda functions
    └── data_processor.py
└── aws-athena/                 # Athena queries
    └── athena_queries.sql
└── aws-glue/                   # ETL scripts
    └── glue_etl_script.py
└── aws-quicksight/             # Dashboard configuration
    └── dashboard_config.json
└── aws-deployment/             # Deployment scripts
    └── deploy.sh
```

## Usage Examples

### Customer Analytics
```sql
-- Customer segment analysis
SELECT 
    customer_segment,
    COUNT(*) as total_customers,
    AVG(total_spent) as avg_spent,
    SUM(total_spent) as total_revenue
FROM customers 
GROUP BY customer_segment
ORDER BY total_revenue DESC;
```

### Product Performance
```sql
-- Top products by revenue
SELECT 
    p.product_name,
    p.category,
    SUM(oi.total_price) as total_revenue,
    AVG(r.rating) as avg_rating
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;
```

### Sales Trends
```sql
-- Monthly sales performance
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') as month,
    COUNT(*) as total_orders,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM orders
WHERE order_date >= '2023-01-01'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
```

## Resume Bullet Points

- **"Designed and implemented a comprehensive e-commerce analytics platform using MySQL, AWS RDS, and cloud data engineering services"**
- **"Developed complex SQL queries demonstrating advanced techniques including window functions, CTEs, and multi-table joins"**
- **"Built end-to-end data pipeline using AWS Glue, S3, Athena, and QuickSight for business intelligence dashboards"**
- **"Created interactive web dashboard with Chart.js for real-time data visualization and business insights"**

## Technical Skills

- **SQL**: Advanced queries, window functions, aggregations, joins
- **Database**: MySQL, AWS RDS, data modeling, indexing
- **Cloud**: AWS (RDS, S3, Lambda, Glue, Athena, QuickSight)
- **Data Engineering**: ETL processes, data lakes, data transformation
- **Visualization**: Chart.js, interactive dashboards, business intelligence
- **Infrastructure**: CloudFormation, Infrastructure as Code, automated deployment

## License

This project is for educational and portfolio purposes.
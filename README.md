# E-commerce Analytics Dashboard with AWS Integration

A comprehensive cloud-based analytics platform for a fictional e-commerce store, demonstrating advanced SQL skills, AWS cloud services, and modern data engineering practices. This project showcases end-to-end data pipeline development from database design to interactive dashboards.

## 🎯 Project Overview

This project simulates a complete e-commerce analytics platform with realistic data and provides extensive analytics capabilities using AWS cloud services. It demonstrates advanced SQL techniques, cloud data engineering, and business intelligence best practices.

## 📊 Database Schema

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

## 🚀 Getting Started

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
   SOURCE advanced_queries.sql;
   ```

#### Option 2: AWS Cloud Deployment
1. **Deploy complete AWS infrastructure:**
   ```bash
   ./aws-deployment/deploy.sh dev us-east-1
   ```

2. **Initialize database with sample data:**
   - Connect to RDS instance using provided credentials
   - Run database initialization scripts

3. **Access QuickSight dashboard:**
   - Configure data sources using provided configuration
   - Import dashboard templates

## 📈 SQL Skills Demonstrated

### 1. Aggregations (SUM, AVG, COUNT)
- **Revenue Analysis**: Total revenue by customer segment, monthly sales performance
- **Product Metrics**: Sales performance, inventory analysis
- **Customer Analytics**: Lifetime value calculations, purchase patterns

### 2. Joins (INNER, LEFT, RIGHT)
- **Complete Order Details**: Multi-table joins for comprehensive order information
- **Product Sales Data**: Including unsold products with LEFT JOIN
- **Payment Analysis**: Payment information with order context
- **Customer Journey**: Complete customer purchase history

### 3. Window Functions (ROW_NUMBER, RANK, OVER)
- **Customer Rankings**: Revenue-based customer rankings with various ranking functions
- **Category Performance**: Monthly sales rankings by product category
- **Running Analytics**: Running totals and moving averages
- **Percentile Analysis**: Customer and product performance percentiles

### 4. Grouping and Subqueries
- **Above-Average Analysis**: Customers and products exceeding averages
- **Growth Rate Calculations**: Month-over-month growth analysis
- **Top N Queries**: Top 3 products in each category
- **Segmentation Analysis**: Customer segment performance metrics

### 5. Advanced Analytics
- **Cohort Analysis**: Customer retention over time
- **RFM Analysis**: Recency, Frequency, Monetary customer segmentation
- **Product Recommendations**: "Customers who bought X also bought Y"
- **Churn Prediction**: Customer churn risk indicators
- **Geographic Analysis**: Sales performance by location

## 📋 Key Analytics Queries

### Executive Dashboard
- Total customers, orders, revenue, and key metrics
- Top 10 best-selling products
- Customer segment performance
- Payment method analysis

### Customer Analytics
- Customer lifetime value analysis
- Purchase pattern analysis by segment
- Customer retention rates
- Churn prediction indicators

### Product Analytics
- Product performance metrics
- Category market share analysis
- Inventory turnover analysis
- Product recommendation engine

### Sales Analytics
- Monthly sales trends
- Seasonal analysis with year-over-year comparison
- Geographic sales distribution
- Time-based sales patterns

## 🎯 Resume-Ready Features

This project demonstrates comprehensive cloud data engineering and analytics skills perfect for your resume:

> **"Designed and implemented a complete cloud-based e-commerce analytics platform using AWS services (RDS, S3, Lambda, Glue, Athena, QuickSight) to analyze customer purchase patterns, product performance, and sales trends. Built automated ETL pipelines, data lakes, and interactive dashboards using Infrastructure as Code and advanced SQL techniques."**

### Specific Technical Skills Highlighted:

#### Cloud & Infrastructure
- **AWS Services**: RDS, S3, Lambda, Glue, Athena, QuickSight, CloudFormation
- **Infrastructure as Code**: CloudFormation templates for automated deployment
- **Serverless Architecture**: Lambda functions for event-driven processing
- **Data Lake Design**: S3-based data lake with partitioning and lifecycle policies

#### Data Engineering
- **ETL Pipelines**: Automated data processing with AWS Glue
- **Data Modeling**: Normalized database schema with proper relationships
- **Data Lake Analytics**: Serverless querying with Amazon Athena
- **Real-time Processing**: Event-driven data processing with Lambda

#### SQL & Analytics
- **Advanced SQL**: Complex queries with CTEs, window functions, and subqueries
- **Business Intelligence**: Interactive dashboards with QuickSight
- **Data Analysis**: Customer segmentation, cohort analysis, and predictive analytics
- **Performance Optimization**: Proper indexing and query optimization

#### DevOps & Automation
- **CI/CD**: Automated deployment scripts and infrastructure provisioning
- **Monitoring**: CloudWatch integration for monitoring and alerting
- **Security**: IAM roles, VPC configuration, and data encryption
- **Scalability**: Auto-scaling and cost-optimized architecture

## ☁️ AWS Architecture

### Core AWS Services Used
- **Amazon RDS (MySQL)**: Primary database for transactional data
- **Amazon S3**: Data lake for analytics and data storage
- **AWS Lambda**: Serverless data processing and ETL
- **AWS Glue**: ETL jobs for data transformation
- **Amazon Athena**: Serverless query service for data lake analytics
- **Amazon QuickSight**: Business intelligence and dashboarding
- **AWS CloudFormation**: Infrastructure as Code (IaC)
- **Amazon EventBridge**: Event-driven processing

### Data Flow Architecture
```
RDS MySQL → Lambda (ETL) → S3 Data Lake → Athena → QuickSight
     ↓              ↓           ↓
  Real-time    Scheduled    Interactive
  Analytics    Processing   Dashboards
```

## 📁 File Structure

```
ECommerce-Platform/
├── README.md                           # Project documentation
├── requirements.txt                    # Python dependencies
├── setup_instructions.sql             # Database setup guide
├── database_schema.sql                # Database schema and table creation
├── sample_data.sql                    # Sample data insertion
├── analytics_queries.sql              # Core analytics queries
├── advanced_queries.sql               # Advanced analytical queries
├── aws-infrastructure/
│   └── cloudformation-template.yaml   # Complete AWS infrastructure
├── aws-lambda/
│   └── data_processor.py              # Lambda function for data processing
├── aws-glue/
│   └── glue_etl_script.py             # Glue ETL job for data transformation
├── aws-athena/
│   └── athena_queries.sql             # Athena queries for data lake analytics
├── aws-quicksight/
│   └── dashboard_config.json          # QuickSight dashboard configuration
└── aws-deployment/
    └── deploy.sh                      # Automated deployment script
```

## 🔍 Sample Query Examples

### Customer Revenue Analysis
```sql
SELECT 
    customer_segment,
    COUNT(DISTINCT customer_id) as total_customers,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY customer_segment
ORDER BY total_revenue DESC;
```

### Top Products with Window Functions
```sql
SELECT 
    product_name,
    total_revenue,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) as revenue_rank,
    PERCENT_RANK() OVER (ORDER BY total_revenue DESC) as percentile
FROM (
    SELECT 
        p.product_name,
        SUM(oi.total_price) as total_revenue
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_name
) product_sales
ORDER BY total_revenue DESC;
```

### Customer Cohort Analysis
```sql
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') as cohort_month,
        DATE_FORMAT(order_date, '%Y-%m') as order_month
    FROM orders
    GROUP BY customer_id, DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) as cohort_size,
    COUNT(DISTINCT CASE WHEN order_month = cohort_month THEN customer_id END) as retained_customers
FROM customer_cohorts
GROUP BY cohort_month
ORDER BY cohort_month;
```

## 🎨 Business Insights Generated

1. **Customer Segmentation**: Identified high-value customer segments for targeted marketing
2. **Product Performance**: Analyzed best-selling products and categories for inventory optimization
3. **Sales Trends**: Tracked monthly and seasonal sales patterns for business planning
4. **Customer Retention**: Measured customer retention rates and identified at-risk customers
5. **Geographic Analysis**: Analyzed sales performance across different regions
6. **Payment Patterns**: Understood customer payment preferences and transaction success rates

## 🚀 AWS Deployment Guide

### Quick Start (5 minutes)
```bash
# Clone the repository
git clone <repository-url>
cd ECommerce-Platform

# Deploy to AWS (requires AWS CLI configured)
./aws-deployment/deploy.sh dev us-east-1

# Follow the output instructions to initialize the database
```

### Manual AWS Setup
1. **Deploy Infrastructure**: Use CloudFormation template
2. **Initialize Database**: Connect to RDS and run SQL scripts
3. **Configure QuickSight**: Import dashboard configuration
4. **Test Lambda Functions**: Verify data processing pipeline

### Cost Optimization
- **Development Environment**: ~$50-100/month
- **Production Environment**: ~$200-500/month
- **Serverless Architecture**: Pay only for what you use
- **S3 Lifecycle Policies**: Automatic cost optimization

## 🔧 AWS Services Deep Dive

### Amazon RDS (MySQL)
- **Purpose**: Primary transactional database
- **Features**: Automated backups, multi-AZ deployment, encryption
- **Monitoring**: CloudWatch metrics and logs

### Amazon S3 Data Lake
- **Purpose**: Centralized data storage for analytics
- **Features**: Lifecycle policies, versioning, encryption
- **Structure**: Partitioned by date and data type

### AWS Lambda
- **Purpose**: Serverless data processing
- **Triggers**: EventBridge schedules, S3 events
- **Languages**: Python 3.9 with boto3

### AWS Glue
- **Purpose**: ETL data transformation
- **Features**: Auto-generated ETL code, job scheduling
- **Output**: Parquet files optimized for analytics

### Amazon Athena
- **Purpose**: Serverless SQL queries on S3 data
- **Features**: Pay-per-query, standard SQL
- **Integration**: Direct QuickSight connectivity

### Amazon QuickSight
- **Purpose**: Business intelligence dashboards
- **Features**: Interactive visualizations, sharing, mobile
- **Data Sources**: RDS, S3, Athena

## 🚀 Future Enhancements

- **Machine Learning**: SageMaker integration for predictive analytics
- **Real-time Streaming**: Kinesis for real-time data processing
- **Advanced Analytics**: Redshift for data warehouse capabilities
- **API Gateway**: RESTful APIs for external integrations
- **Containerization**: ECS/EKS for microservices architecture
- **Monitoring**: CloudWatch dashboards and alerting
- **Security**: KMS encryption, Secrets Manager
- **CI/CD**: CodePipeline for automated deployments

## 📊 Business Value

This project demonstrates real-world skills that employers value:
- **Cloud Architecture**: Modern, scalable, cost-effective solutions
- **Data Engineering**: End-to-end data pipeline development
- **Business Intelligence**: Actionable insights for decision-making
- **DevOps Practices**: Infrastructure as Code and automation
- **Security Best Practices**: IAM, encryption, and compliance

## 📞 Contact

This project demonstrates comprehensive cloud data engineering and analytics capabilities suitable for:
- **Data Engineer** roles
- **Cloud Solutions Architect** positions
- **Business Intelligence Developer** jobs
- **Data Analyst** with cloud focus
- **DevOps Engineer** with data expertise

---

*This project showcases end-to-end cloud data engineering skills through a realistic e-commerce analytics platform, perfect for demonstrating technical capabilities in interviews and on resumes.*
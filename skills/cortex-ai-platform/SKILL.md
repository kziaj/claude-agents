# Snowflake Cortex AI Platform

This skill provides comprehensive reference for Snowflake Cortex AI capabilities including Agents, AI SQL functions, Search, and Analyst features.

## 🧠 Cortex AI Overview

Snowflake Cortex AI is a fully-managed service that provides LLM-powered capabilities directly within Snowflake:

- **Cortex Agents**: Build conversational data agents
- **Cortex AI SQL**: LLM functions for text analysis and generation  
- **Cortex Search**: RAG (Retrieval Augmented Generation) search services
- **Cortex Analyst**: Natural language to SQL conversion

---

## 🤖 Cortex Agents

### Purpose
Build conversational agents that can interact with your data using natural language.

### Key Capabilities
- **Conversational Interface**: Natural language interaction with data
- **Data Context**: Agents understand your database schema and content
- **REST API**: Programmatic creation and management
- **Integration**: Slack, Microsoft Teams, and custom applications

### REST API Endpoints
```sql
-- Create Agent
POST /api/v2/cortex/agents

-- List Agents  
GET /api/v2/cortex/agents

-- Get Agent Details
GET /api/v2/cortex/agents/{agent_id}

-- Update Agent
PUT /api/v2/cortex/agents/{agent_id}

-- Delete Agent
DELETE /api/v2/cortex/agents/{agent_id}

-- Send Message to Agent
POST /api/v2/cortex/agents/{agent_id}/messages
```

### Agent Configuration Example
```yaml
name: "Sales Data Agent"
description: "Agent for analyzing sales performance data"
instructions: |
  You are a sales data analyst. Help users understand:
  - Revenue trends and forecasts
  - Customer acquisition metrics
  - Product performance analysis
  - Regional sales comparisons
database: "PROD_DB"
schema: "SALES_MART"
warehouse: "COMPUTE_WH"
```

### Integration Patterns
- **Slack Bot**: Direct integration with Slack channels
- **Teams Bot**: Microsoft Teams integration
- **Web Interface**: Custom web applications
- **API Integration**: Programmatic access for custom workflows

---

## 🔤 Cortex AI SQL Functions

### Core LLM Functions

#### COMPLETE() - Text Generation
```sql
-- Basic completion
SELECT SNOWFLAKE.CORTEX.COMPLETE(
  'llama3-8b',  -- model name
  'Summarize the key findings from this sales report: ' || report_text
) as summary
FROM sales_reports;

-- With options
SELECT SNOWFLAKE.CORTEX.COMPLETE(
  'mistral-large',
  'Generate product recommendations based on: ' || customer_profile,
  {
    'max_tokens': 500,
    'temperature': 0.3,
    'top_p': 0.9
  }
) as recommendations
FROM customer_profiles;
```

#### AI_SUMMARIZE() - Content Summarization
```sql
-- Summarize text content
SELECT 
  document_id,
  SNOWFLAKE.CORTEX.SUMMARIZE(document_content) as summary
FROM documents
WHERE document_type = 'research_report';
```

#### AI_EXTRACT_ANSWER() - Question Answering
```sql
-- Extract specific information
SELECT SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
  meeting_transcript,
  'What were the key action items discussed?'
) as action_items
FROM meeting_transcripts
WHERE meeting_date >= '2024-01-01';
```

#### AI_SENTIMENT() - Sentiment Analysis
```sql
-- Analyze sentiment
SELECT 
  feedback_id,
  feedback_text,
  SNOWFLAKE.CORTEX.SENTIMENT(feedback_text) as sentiment_score
FROM customer_feedback;
```

#### AI_TRANSLATE() - Language Translation
```sql
-- Translate content
SELECT SNOWFLAKE.CORTEX.TRANSLATE(
  product_description,
  'en',  -- from English
  'es'   -- to Spanish  
) as spanish_description
FROM products;
```

### Available Models
- **Meta Llama**: `llama3-8b`, `llama3-70b`
- **Mistral**: `mistral-large`, `mistral-7b`
- **Google**: `gemma-7b`
- **Reka**: `reka-flash`, `reka-core`

### Best Practices
- **Model Selection**: Use larger models (70b, large) for complex tasks
- **Temperature Control**: Lower (0.1-0.3) for factual, higher (0.7-0.9) for creative
- **Token Limits**: Be mindful of max_tokens for cost optimization
- **Batch Processing**: Process multiple records efficiently

---

## 🔍 Cortex Search

### Purpose
Build RAG (Retrieval Augmented Generation) applications with semantic search capabilities.

### Core Concepts
- **Search Services**: Managed search endpoints
- **Vector Embeddings**: Automatic text vectorization
- **Semantic Search**: Meaning-based search vs keyword matching
- **Context Retrieval**: Relevant context for LLM prompts

### Creating Search Services
```sql
-- Create search service
CREATE CORTEX SEARCH SERVICE customer_docs_search
ON customer_documentation
ATTRIBUTES title, content, category
WAREHOUSE = COMPUTE_WH;

-- Search the service
SELECT * FROM TABLE(
  customer_docs_search!SEARCH('how to reset password')
);
```

### Search Service Configuration
```sql
-- Advanced configuration
CREATE CORTEX SEARCH SERVICE product_search
ON products_table
ATTRIBUTES 
  product_name,
  description,  
  category,
  specifications
WAREHOUSE = SEARCH_WH
MAX_BUDGET = 1000  -- Cost control
TARGET_LAG = '1 minute';  -- Refresh frequency
```

### RAG Pattern Implementation
```sql
-- Step 1: Search for relevant context
WITH relevant_docs AS (
  SELECT parse_json(search_preview):chunk::string as context
  FROM TABLE(product_search!SEARCH(
    'sustainable materials in clothing'
  ))
  LIMIT 5
),

-- Step 2: Combine context for LLM
combined_context AS (
  SELECT listagg(context, '\n---\n') as full_context
  FROM relevant_docs
)

-- Step 3: Generate response with context
SELECT SNOWFLAKE.CORTEX.COMPLETE(
  'mistral-large',
  'Based on this context: ' || full_context || 
  '\n\nQuestion: What sustainable materials do we use in our clothing line?'
) as answer
FROM combined_context;
```

### Search Applications
- **Documentation Search**: Employee knowledge base
- **Product Recommendations**: E-commerce suggestions
- **Customer Support**: Automated help responses  
- **Research Assistant**: Academic/business research

---

## 📊 Cortex Analyst

### Purpose
Convert natural language questions into SQL queries and provide data insights.

### Key Features
- **Natural Language to SQL**: Automatic query generation
- **Schema Understanding**: Learns your data model
- **Business Context**: Understands metrics and KPIs
- **Conversational Interface**: Follow-up questions and clarifications

### Semantic Model Definition
```yaml
# semantic_model.yaml
name: sales_performance
description: "Sales performance analysis semantic model"
base_tables:
  - name: sales_fact
    description: "Daily sales transactions"
    columns:
      - name: sale_date
        type: date
        description: "Date of the sale"
      - name: revenue
        type: number
        description: "Revenue in USD"
      - name: customer_id
        type: string
        description: "Unique customer identifier"
  
  - name: customers_dim  
    description: "Customer dimension table"
    columns:
      - name: customer_id
        type: string
        description: "Unique customer identifier"
      - name: customer_segment
        type: string
        description: "Customer segment (Enterprise, SMB, Individual)"
      - name: region
        type: string
        description: "Geographic region"

relationships:
  - from: sales_fact.customer_id
    to: customers_dim.customer_id
    type: many_to_one

metrics:
  - name: total_revenue
    type: sum
    column: sales_fact.revenue
    description: "Sum of all revenue"
  
  - name: average_deal_size
    type: average  
    column: sales_fact.revenue
    description: "Average revenue per transaction"

dimensions:
  - name: customer_segment
    column: customers_dim.customer_segment
    
  - name: sales_month
    column: sales_fact.sale_date
    time_granularity: month
```

### Using Cortex Analyst
```sql
-- Create analyst instance
CREATE CORTEX ANALYST my_sales_analyst
SEMANTIC_MODEL = 'sales_performance_model'
WAREHOUSE = ANALYST_WH;

-- Ask natural language questions
SELECT * FROM TABLE(
  my_sales_analyst!ASK('What was our revenue growth last quarter?')
);

SELECT * FROM TABLE(
  my_sales_analyst!ASK('Show me top performing customer segments by region')
);

SELECT * FROM TABLE(
  my_sales_analyst!ASK('How does our average deal size compare month over month?')
);
```

### Question Types Supported
- **Aggregations**: "What's the total revenue this year?"
- **Comparisons**: "How does Q3 compare to Q2?"
- **Trends**: "Show me the revenue trend over time"
- **Filtering**: "What are sales for enterprise customers?"
- **Ranking**: "Which products perform best?"
- **Ratios**: "What's our conversion rate by channel?"

---

## 🔧 Integration Patterns

### Cortex + dbt Integration
```sql
-- Use Cortex functions in dbt models
{{ config(materialized='table') }}

SELECT 
  customer_id,
  feedback_text,
  SNOWFLAKE.CORTEX.SENTIMENT(feedback_text) as sentiment_score,
  SNOWFLAKE.CORTEX.SUMMARIZE(feedback_text) as feedback_summary,
  CASE 
    WHEN SNOWFLAKE.CORTEX.SENTIMENT(feedback_text) > 0.5 THEN 'Positive'
    WHEN SNOWFLAKE.CORTEX.SENTIMENT(feedback_text) < -0.5 THEN 'Negative'  
    ELSE 'Neutral'
  END as sentiment_category
FROM {{ ref('raw_customer_feedback') }}
WHERE feedback_text IS NOT NULL
```

### Multi-Model Approach
```sql
-- Use different models for different tasks
WITH analysis_results AS (
  SELECT 
    document_id,
    -- Fast model for classification
    SNOWFLAKE.CORTEX.COMPLETE(
      'mistral-7b',
      'Classify this document type: ' || title || '\nOptions: contract, invoice, report, email'
    ) as doc_type,
    
    -- Larger model for detailed analysis  
    SNOWFLAKE.CORTEX.COMPLETE(
      'llama3-70b', 
      'Provide a detailed analysis of key points in: ' || content
    ) as detailed_analysis
    
  FROM documents
)
SELECT * FROM analysis_results;
```

### Error Handling
```sql
-- Safe Cortex function usage
SELECT 
  id,
  TRY_CAST(
    SNOWFLAKE.CORTEX.SENTIMENT(feedback_text) AS FLOAT
  ) as sentiment_score,
  CASE 
    WHEN TRY_CAST(SNOWFLAKE.CORTEX.SENTIMENT(feedback_text) AS FLOAT) IS NULL 
    THEN 'Processing Error'
    ELSE 'Success'
  END as processing_status
FROM feedback_table;
```

---

## 💰 Cost Optimization

### Model Selection Strategy
- **Development/Testing**: Use smaller models (`mistral-7b`, `llama3-8b`)
- **Production Summarization**: `mistral-large` or `llama3-70b`
- **Production Generation**: `mistral-large` for quality, `llama3-8b` for speed
- **Simple Classification**: `gemma-7b` for cost efficiency

### Token Management
```sql
-- Optimize token usage
SELECT SNOWFLAKE.CORTEX.COMPLETE(
  'mistral-7b',
  'Summarize in 2 sentences: ' || LEFT(long_text, 4000),  -- Limit input
  {'max_tokens': 100}  -- Limit output
) as concise_summary
FROM large_documents;
```

### Batch Processing
```sql
-- Process multiple items efficiently
WITH batched_content AS (
  SELECT 
    batch_id,
    LISTAGG(content, '\n---\n') WITHIN GROUP (ORDER BY id) as combined_content
  FROM documents  
  WHERE LENGTH(content) < 1000  -- Stay under token limits
  GROUP BY batch_id
)
SELECT 
  batch_id,
  SNOWFLAKE.CORTEX.SUMMARIZE(combined_content) as batch_summary
FROM batched_content;
```

---

## 🚀 Common Use Cases

### 1. Customer Feedback Analysis
```sql
-- Comprehensive feedback processing
CREATE OR REPLACE VIEW customer_feedback_analysis AS
SELECT 
  feedback_id,
  customer_id,
  feedback_date,
  feedback_text,
  SNOWFLAKE.CORTEX.SENTIMENT(feedback_text) as sentiment_score,
  SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
    feedback_text, 
    'What specific product or service is mentioned?'
  ) as mentioned_product,
  SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
    feedback_text,
    'What is the main complaint or compliment?'  
  ) as main_issue,
  SNOWFLAKE.CORTEX.SUMMARIZE(feedback_text) as summary
FROM customer_feedback
WHERE LENGTH(feedback_text) > 50;
```

### 2. Document Intelligence
```sql
-- Automated document processing
CREATE OR REPLACE TABLE document_insights AS
SELECT 
  document_id,
  document_type,
  SNOWFLAKE.CORTEX.COMPLETE(
    'mistral-large',
    'Extract key information from this document: ' || document_content ||
    '\nProvide: 1) Document purpose 2) Key entities 3) Important dates 4) Action items'
  ) as key_information,
  SNOWFLAKE.CORTEX.SUMMARIZE(document_content) as executive_summary
FROM documents
WHERE document_content IS NOT NULL;
```

### 3. Sales Intelligence
```sql
-- Meeting transcript analysis
SELECT 
  meeting_id,
  participant_list,
  SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
    transcript,
    'What products or services were discussed?'
  ) as products_discussed,
  SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
    transcript,
    'What are the next steps or action items?'
  ) as action_items,
  SNOWFLAKE.CORTEX.EXTRACT_ANSWER(
    transcript,
    'What concerns or objections were raised?'
  ) as concerns,
  SNOWFLAKE.CORTEX.SENTIMENT(transcript) as meeting_sentiment
FROM sales_meeting_transcripts;
```

---

## 🔗 Reference Links

- **[Cortex Agents REST API](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents/cortex-agents-api)**: API endpoints and programmatic management
- **[Cortex Agents Tutorials](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents/tutorials)**: Getting started guides and integrations  
- **[GitHub Quickstart](https://github.com/Snowflake-Labs/sfguide-build-data-agents-using-snowflake-cortex-ai)**: Hands-on agent building guide
- **[Cortex AI SQL Functions](https://docs.snowflake.com/en/user-guide/snowflake-cortex/llm-functions)**: Complete function reference
- **[COMPLETE() Function](https://docs.snowflake.com/en/sql-reference/functions/complete-snowflake-cortex)**: Core LLM function details
- **[Cortex Search](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search)**: RAG and search capabilities
- **[Cortex Analyst](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)**: Natural language to SQL conversion

---

**Note**: This skill provides comprehensive reference for all Snowflake Cortex AI capabilities. Use in conjunction with the snowflake-cortex-agent for automated workflow execution.
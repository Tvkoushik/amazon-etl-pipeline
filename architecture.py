from diagrams import Diagram, Cluster, Edge
from diagrams.aws.analytics import Glue, Redshift, Quicksight, LakeFormation
from diagrams.aws.storage import S3
from diagrams.aws.migration import DMS
from diagrams.aws.integration import StepFunctions
from diagrams.aws.database import RDS
from diagrams.aws.general import User
from diagrams.aws.management import Cloudwatch
from diagrams.aws.security import IAM
from diagrams.onprem.client import User as EndUser
from diagrams.onprem.network import Nginx

# Diagram settings
with Diagram("Amazon ETL Pipeline Architecture", show=False, direction="LR"):

    # User interaction
    user = User("Data Engineers / Analysts")

    with Cluster("Source & Microservices", graph_attr={"bgcolor": "#f0f0f0"}):
        backend_microservices = Nginx("Amazon.com Microservices")
        source_db = RDS("PostgreSQL on RDS")
        backend_microservices >> source_db

    with Cluster("Data Ingestion", graph_attr={"bgcolor": "#e0ffe0"}):
        dms = DMS("AWS DMS - CDC")
        s3_raw = S3("S3 (Raw DMS data)")

    with Cluster("Data Processing & Transformation", graph_attr={"bgcolor": "#ffffcc"}):
        glue_staging_job = Glue("Glue Job - Raw to Staging")
        glue_dim_job = Glue("Glue Job - Staging to Dimensions")
        glue_fact_job = Glue("Glue Job - Dimensions to Facts")
        s3_staging = S3("S3 (Staging Data)")
        redshift_staging = Redshift("Redshift Staging")
        redshift_dimensions = Redshift("Redshift Dimensions")
        redshift_facts = Redshift("Redshift Facts")

    with Cluster("Monitoring & Orchestration", graph_attr={"bgcolor": "#ccffff"}):
        monitoring = Cloudwatch("CloudWatch Logs & Alerts")
        step_functions = StepFunctions("Step Functions Orchestration")

    with Cluster("Governance & Security", graph_attr={"bgcolor": "#ffe6e6"}):
        iam = IAM("IAM Roles")
        access_control = LakeFormation("Lake Formation / Access Policies")

    with Cluster("Visualization", graph_attr={"bgcolor": "#f5f5f5"}):
        quicksight = Quicksight("AWS QuickSight")

    # User interaction
    user >> Edge(label="Analyze", color="blue") >> quicksight

    # Data Ingestion Flow
    (
        source_db
        >> Edge(label="CDC Data", color="green", style="bold")
        >> dms
        >> Edge(label="Raw Files", color="darkgreen")
        >> s3_raw
    )

    # Data Processing & Transformation Flow
    (
        s3_raw
        >> Edge(label="Run Glue Job", color="orange")
        >> glue_staging_job
        >> Edge(label="Staging Data", color="orange")
        >> s3_staging
    )
    glue_staging_job >> redshift_staging
    (
        redshift_staging
        >> Edge(label="Load Dimensions", color="orange")
        >> glue_dim_job
        >> redshift_dimensions
    )
    (
        redshift_dimensions
        >> Edge(label="Load Facts", color="orange")
        >> glue_fact_job
        >> redshift_facts
    )

    # Monitoring & Orchestration Flow
    (
        step_functions
        >> Edge(label="Trigger Jobs", color="blue", style="dashed")
        >> glue_staging_job
    )
    step_functions >> glue_dim_job
    step_functions >> glue_fact_job
    glue_staging_job >> Edge(label="Logs", color="blue", style="dotted") >> monitoring
    glue_dim_job >> monitoring
    glue_fact_job >> monitoring

    # Security and Governance
    (
        step_functions
        >> Edge(label="IAM Role Assignment", color="red", style="dotted")
        >> iam
    )
    glue_staging_job >> access_control
    glue_dim_job >> access_control
    glue_fact_job >> access_control

    # Final Visualization
    redshift_facts >> Edge(label="Query", color="purple", style="bold") >> quicksight
    redshift_dimensions >> quicksight

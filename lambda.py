from diagrams import Diagram, Cluster, Edge
from diagrams.aws.analytics import Glue, Redshift, Quicksight, Athena,KinesisDataStreams
from diagrams.aws.storage import S3
from diagrams.aws.migration import DMS
from diagrams.aws.integration import StepFunctions
from diagrams.aws.database import RDS
from diagrams.aws.security import IAM
from diagrams.aws.compute import Lambda
from diagrams.aws.management import Cloudwatch
from diagrams.onprem.client import User

with Diagram("Lambda Architecture with Batch and Streaming", show=False, direction="LR"):

    user = User("Data Engineers / Analysts")

    # Batch Layer (Slow Path)
    with Cluster("Batch Layer (Slow Path)", graph_attr={"bgcolor": "#e0ffe0"}):
        source_db = RDS("PostgreSQL (RDS)")
        dms = DMS("DMS CDC - Batch")
        s3_slow = S3("S3 (Raw DMS CDC)")
        glue_slow_job = Glue("Glue Batch Job")
        redshift_slow = Redshift("Redshift for Batch Data")

        # Batch flow
        source_db >> Edge(label="CDC Data (Batch)", color="green") >> dms >> s3_slow
        s3_slow >> Edge(label="Run Glue ETL", color="orange") >> glue_slow_job >> redshift_slow

    # Fast Layer (Real-Time Path)
    with Cluster("Fast Layer (Real-Time)", graph_attr={"bgcolor": "#ffe0cc"}):
        source_db = RDS("PostgreSQL (RDS)")
        dms = DMS("DMS CDC - Batch")
        kinesis_stream = KinesisDataStreams("Kinesis Data Stream")
        glue_streaming_job = Glue("Glue Streaming Job")
        s3_fast = S3("Delta Lake on S3")
        redshift_fast = Redshift("Redshift for Real-Time Data")

        # Real-Time flow
        source_db >> Edge(label="CDC Data (Real-Time)", color="green") >> dms >> kinesis_stream >> Edge(label="Real-Time Data", color="blue") >> glue_streaming_job
        glue_streaming_job >> Edge(label="Store in Delta Lake", color="orange") >> s3_fast
        glue_streaming_job >> Edge(label="Store in Redshift", color="orange") >> redshift_fast

    # Serving Layer
    with Cluster("Serving Layer", graph_attr={"bgcolor": "#f0f0f0"}):
        redshift_combined = Redshift("Redshift (Batch + Fast)")
        athena = Athena("Athena for S3 Queries")
        quicksight = Quicksight("Amazon QuickSight")
        
        redshift_slow >> Edge(label="Combined Analytics", color="purple") >> redshift_combined
        redshift_fast >> redshift_combined
        s3_fast >> Edge(label="Query via Athena", color="purple") >> athena
        athena >> quicksight
        redshift_combined >> quicksight

    # Monitoring & Orchestration
    with Cluster("Monitoring & Orchestration", graph_attr={"bgcolor": "#ccffff"}):
        monitoring = Cloudwatch("CloudWatch Logs & Alerts")
        step_functions = StepFunctions("Step Functions Orchestration")

        step_functions >> Edge(label="Trigger Jobs", color="blue", style="dashed") >> glue_slow_job
        step_functions >> glue_streaming_job
        glue_slow_job >> Edge(label="Logs", color="blue", style="dotted") >> monitoring
        glue_streaming_job >> monitoring

    # Governance & Security
    with Cluster("Governance & Security", graph_attr={"bgcolor": "#ffe6e6"}):
        iam = IAM("IAM Roles and Access Control")
        glue_slow_job >> iam
        glue_streaming_job >> iam

    # Final Visualization
    user >> Edge(label="Analyze", color="blue") >> quicksight
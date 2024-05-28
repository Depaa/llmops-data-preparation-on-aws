import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglueml.transforms import EntityDetector


args = getResolvedOptions(sys.argv, ['JOB_NAME', 'SOURCE', 'DESTINATION'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Script generated for node Amazon S3
AmazonS3_node1716105954683 = glueContext.create_dynamic_frame.from_options(
  format_options={'multiline': False}, 
  connection_type='s3', 
  format='json', 
  connection_options={
    'paths': [args['SOURCE']]
  }, 
  transformation_ctx='AmazonS3_node1716105954683'
)

# Script generated for node Detect Sensitive Data
detection_parameters = {"EMAIL": [{
  "action": "REDACT",
  "actionOptions": {"redactText": "******"}
}]}

entity_detector = EntityDetector()
DetectSensitiveData_node1716884671757 = entity_detector.detect(AmazonS3_node1716105954683, detection_parameters, "DetectedEntities", "HIGH")


# Script generated for node Amazon S3
AmazonS3_node1716106268819 = glueContext.write_dynamic_frame.from_options(
  frame=DetectSensitiveData_node1716884671757, 
  connection_type='s3', 
  format='json', 
  connection_options={
    'path': args['DESTINATION'], 
    'partitionKeys': []
  }, 
  transformation_ctx='AmazonS3_node1716106268819'
)

job.commit()
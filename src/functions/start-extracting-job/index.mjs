import {
    TextractClient,
    StartDocumentTextDetectionCommand,
    StartDocumentAnalysisCommand
} from "@aws-sdk/client-textract";
const textractClient = new TextractClient();

const processEvent = async (event) => {
    for (const record of event.Records) {
        const startDocumentAnalysisCommand = await textractClient.send(new StartDocumentAnalysisCommand({
            DocumentLocation: {
                S3Object: {
                    Bucket: record.s3.bucket.name,
                    Name: record.s3.object.key
                }
            },
            NotificationChannel: {
                SNSTopicArn: process.env.NOTIFICATION_TOPIC_ARN,
                RoleArn: process.env.NOTIFICATION_ROLE_ARN
            },
        }));
        const documentAnalysis = await textractClient.send(startDocumentAnalysisCommand);
        console.info('Analysis done');
        console.debug(documentAnalysis);

        const startDocumentTextDetectionCommand = new StartDocumentTextDetectionCommand({
            DocumentLocation: {
                S3Object: {
                    Bucket: record.s3.bucket.name,
                    Name: record.s3.object.key
                }
            },
            NotificationChannel: {
                SNSTopicArn: process.env.NOTIFICATION_TOPIC_ARN,
                RoleArn: process.env.NOTIFICATION_ROLE_ARN
            },
            OutputConfig: {
                S3Bucket: process.env.SILVER_BUCKET_NAME,
                S3Prefix: "output/"
            }
        });
        const documentTextDetection = await textractClient.send(startDocumentTextDetectionCommand);
        console.info('Job started successfully');
        console.debug(documentTextDetection);
    }
};

export default async event => {
    return processEvent(event);
};
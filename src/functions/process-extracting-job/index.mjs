import {
    GetDocumentAnalysisCommand,
    GetDocumentTextDetectionCommand,
    TextractClient
} from "@aws-sdk/client-textract";
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3"; // ES Modules import

const textractClient = new TextractClient();
const ddbClient = DynamoDBDocumentClient.from(new DynamoDBClient());
const s3Client = new S3Client();


const saveMetadata = async (id, pages) => {
    const params = {
        TableName: process.env.METADATA_DATABASE_NAME,
        Item: {
            id,
            pages,
            createdAt: new Date().toISOString()
        }
    };
    console.debug(params);
    await ddbClient.send(new PutCommand(params));
    console.info('Metadata saved');
};

const saveText = async (id, data) => {
    const params = {
        Bucket: process.env.SILVER_BUCKET_NAME,
        Key: `${id}.json`,
        Body: JSON.stringify(data)
    };
    
    console.debug(params);
    await s3Client.send(new PutObjectCommand(params));
    console.info('Text saved');
};

const processEvent = async (event) => {
    // event contains records from SQS queue, process each record
    for (const record of event.Records) {
        console.debug(record);
        const message = JSON.parse(record.body);
        const job = JSON.parse(message.Message);

        const getParams = {
            JobId: job.JobId
        };
        console.debug(getParams);

        if (job.Status !== 'SUCCEEDED') {
            console.error('Job not succeeded');
            console.error(job);
        }

        let document;

        if (job.API === 'StartDocumentTextDetection') {
            const getDocumentTextDetectionCommand = new GetDocumentTextDetectionCommand(getParams);
            document = await textractClient.send(getDocumentTextDetectionCommand);
            console.info('Text detection done');
        } else if (job.API === 'StartDocumentAnalysis') {
            const getDocumentAnalysisCommand = new GetDocumentAnalysisCommand(getParams);
            document = await textractClient.send(getDocumentAnalysisCommand);
            console.info('Analysis done');
        } else {
            console.info('Job type not supported');
            console.info(job);
        }

        let text = '';
        for (const block of document.Blocks) {
            text += block.Text;
        }

        if (document.Warnings) {
            console.warn(JSON.stringify(document.Warnings));
        }

        const data = {
            text,
            pages: document.DocumentMetadata.Pages
        };
        await saveMetadata(job.JobId, data.pages);
        await saveText(job.JobId, data);
    }
};

export default async event => {
    return await processEvent(event);
};
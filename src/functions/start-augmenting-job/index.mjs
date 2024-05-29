import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";
import { ComprehendClient, DetectDominantLanguageCommand } from "@aws-sdk/client-comprehend";
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const s3Client = new S3Client();
const comprehendClient = new ComprehendClient({ region: 'us-east-1' });
const ddbClient = DynamoDBDocumentClient.from(new DynamoDBClient());

const saveMetadata = async (id, language) => {
    const params = {
        TableName: process.env.METADATA_DATABASE_NAME || 'dev-eu-central-1-data-prep-metadata',
        Key: { id },
        UpdateExpression: 'set #language = :language',
        ExpressionAttributeNames: {
            '#language': 'language'
        },
        ExpressionAttributeValues: {
            ':language': language
        }
    };
    console.debug(params);
    await ddbClient.send(new UpdateCommand(params));
    console.info('Metadata saved');
};

const processEvent = async (event) => {
    for (const record of event.Records) {
        const getObjectParams = {
            Bucket: record.s3.bucket.name,
            Key: record.s3.object.key,
        };
        console.debug(getObjectParams);
        const s3File = await s3Client.send(new GetObjectCommand(getObjectParams));
        console.info('File retrieved successfully');
        const s3String = await s3File.Body.transformToString();
        console.debug(s3String);
        const s3Json = JSON.parse(s3String);

        if (s3Json.text) {
            const classifyDocumentParams = {
                /**
                 * Keeping it simple, each request accept 10k bytes max. We are capping its size.
                 */
                Text: s3Json.text.substring(0, 10000),

            };
            console.debug(classifyDocumentParams);
            const language = await comprehendClient.send(new DetectDominantLanguageCommand(classifyDocumentParams));
            console.info('Detect dominant language completed');
            console.debug(language);
            if (language.Languages[0].Score > 0.9) {
                /**
                 * The id is in the first part of key. The last part has a "glue"-generated name on it.
                 */
                await saveMetadata(record.s3.object.key.split('/')[0], language.Languages[0].LanguageCode);
            }
        }
    }
};

export default async event => {
    return await processEvent(event);
};
import { GlueClient, StartJobRunCommand } from '@aws-sdk/client-glue';

const glueClient = new GlueClient();

const processEvent = async (event) => {
    for (const record of event.Records) {
        const bucket = record.s3.bucket.name;
        const key = record.s3.object.key;

        const params = {
            JobName: process.env.PII_REDACTION_ETL_JOB_NAME,
            Arguments: {
                '--SOURCE': `${bucket}${key}`,
                '--DESTINATION': `${process.env.GOLD_BUCKET_NAME}${key}`,
                '--JOB_NAME': process.env.PII_REDACTION_ETL_JOB_NAME
            },
        };
        console.debug(params);
        await glueClient.send(new StartJobRunCommand(params));
        console.info('Job run started');
    }
};

export default async event => {
    return await processEvent(event);
};
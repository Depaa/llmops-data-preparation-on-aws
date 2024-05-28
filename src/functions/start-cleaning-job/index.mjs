import { GlueClient, StartJobRunCommand } from '@aws-sdk/client-glue';

const glueClient = new GlueClient();

const processEvent = async (event) => {
    for (const record of event.Records) {
        const bucket = record.s3.bucket.name;
        const key = record.s3.object.key;

        const fileName = key.split('/').pop().split('.')[0];

        const params = {
            JobName: process.env.PII_REDACTION_ETL_JOB_NAME,
            Arguments: {
                '--SOURCE': `s3://${bucket}/${key}`,
                '--DESTINATION': `s3://${process.env.GOLD_BUCKET_NAME}/${fileName}`,
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
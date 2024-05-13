import { 
    GetDocumentAnalysisCommand, 
    GetDocumentTextDetectionCommand, 
    DocumentMetadata 
} from "@aws-sdk/client-textract";
const textractClient = new TextractClient();

const processEvent = async (event) => {
    // event contains records from SQS queue, process each record
    for (const record of event.Records) {
        
    }
};

export default async event => {
    return processEvent(event);
};
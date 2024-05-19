import middy from '@middy/core';
import inputOutputLogger from '@middy/input-output-logger';
import httpErrorHandlerMiddleware from '@middy/http-error-handler';
import service from './index.mjs';

export const handler = middy(service)
    .use(inputOutputLogger({
        logger: (request) => {
            console.debug(JSON.stringify(request.event) ?? JSON.stringify(request.response));
        }
    }))
    .use(httpErrorHandlerMiddleware());
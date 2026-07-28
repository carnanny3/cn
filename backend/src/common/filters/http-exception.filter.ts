import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const exceptionResponse =
      exception instanceof HttpException ? exception.getResponse() : null;

    let code = 'INTERNAL_ERROR';
    let message = 'An unexpected error occurred.';
    let details: Record<string, unknown> = {};

    if (typeof exceptionResponse === 'string') {
      message = exceptionResponse;
    } else if (exceptionResponse && typeof exceptionResponse === 'object') {
      const body = exceptionResponse as Record<string, unknown>;
      message = Array.isArray(body.message)
        ? (body.message as string[]).join('; ')
        : ((body.message as string) ?? message);
      code = (body.code as string) ?? codeFromStatus(status);
      details = (body.details as Record<string, unknown>) ?? {};
    } else {
      code = codeFromStatus(status);
    }

    response.status(status).json({
      error: { code, message, details },
    });
  }
}

function codeFromStatus(status: number): string {
  switch (status) {
    case HttpStatus.BAD_REQUEST:
      return 'VALIDATION_ERROR';
    case HttpStatus.UNAUTHORIZED:
      return 'UNAUTHORIZED';
    case HttpStatus.FORBIDDEN:
      return 'FORBIDDEN';
    case HttpStatus.NOT_FOUND:
      return 'NOT_FOUND';
    case HttpStatus.CONFLICT:
      return 'CONFLICT';
    // Raised by multer when an upload exceeds a route's file-size limit.
    case HttpStatus.PAYLOAD_TOO_LARGE:
      return 'FILE_TOO_LARGE';
    default:
      return 'INTERNAL_ERROR';
  }
}

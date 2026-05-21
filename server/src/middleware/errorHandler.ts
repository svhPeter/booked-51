import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { Prisma } from '@prisma/client';
import { logger } from '../config/logger';

export class AppError extends Error {
  public statusCode: number;
  public isOperational: boolean;

  constructor(message: string, statusCode: number = 500) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

const isProd = process.env.NODE_ENV === 'production';

function sendError(res: Response, status: number, message: string, details?: unknown) {
  const body: Record<string, unknown> = { error: message };
  if (!isProd && details) {
    body.details = details;
  }
  res.status(status).json(body);
}

export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  if (err instanceof AppError) {
    sendError(res, err.statusCode, err.message);
    return;
  }

  if (err instanceof ZodError) {
    sendError(res, 400, 'Validation failed', err.errors.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
    })));
    return;
  }

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') {
      const target = (err.meta?.target as string[] | undefined)?.join(', ') || 'field';
      sendError(res, 409, `A record with this ${target} already exists`);
      return;
    }
    if (err.code === 'P2025') {
      sendError(res, 404, 'Record not found');
      return;
    }
    if (err.code === 'P2003') {
      sendError(res, 400, 'Referenced record does not exist');
      return;
    }
    logger.error('Prisma error', { code: err.code, message: err.message });
    sendError(res, 500, 'Database error');
    return;
  }

  if (err instanceof Prisma.PrismaClientValidationError) {
    sendError(res, 400, 'Invalid data provided');
    return;
  }

  if (err instanceof Prisma.PrismaClientInitializationError) {
    logger.error('Database connection error');
    sendError(res, 503, 'Database unavailable');
    return;
  }

  logger.error('Unhandled error', { message: err.message, stack: isProd ? undefined : err.stack });

  if (isProd) {
    sendError(res, 500, 'Internal server error');
  } else {
    sendError(res, 500, err.message || 'Internal server error');
  }
};

export const notFoundHandler = (
  _req: Request,
  res: Response
): void => {
  res.status(404).json({ error: 'Route not found' });
};

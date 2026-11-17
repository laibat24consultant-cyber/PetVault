export class HttpError extends Error {
  constructor(status, message, code = undefined, details = undefined) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export function asyncRoute(handler) {
  return (req, res, next) => {
    Promise.resolve(handler(req, res, next)).catch(next);
  };
}

export function errorHandler(error, req, res, next) {
  if (res.headersSent) return next(error);

  if (error?.name === 'ZodError') {
    return res.status(400).json({
      error: 'Request validation failed.',
      details: error.issues.map((issue) => ({
        path: issue.path.join('.'),
        message: issue.message,
      })),
    });
  }
  if (error?.code === '23505') {
    return res.status(409).json({ error: 'A record with these details already exists.' });
  }
  if (error?.code === '23P01') {
    return res.status(409).json({ error: 'The requested time overlaps an existing booking.' });
  }
  if (error?.code === '23503') {
    return res.status(404).json({ error: 'The requested related record was not found.' });
  }

  const status = Number.isInteger(error?.status) ? error.status : 500;
  const message = status < 500
    ? error.message
    : 'The request could not be completed.';
  if (status >= 500) {
    console.error('api_error', {
      requestId: req.id,
      method: req.method,
      path: req.path,
      name: error?.name ?? 'Error',
      code: error?.code ?? null,
      table: error?.table ?? null,
      column: error?.column ?? null,
    });
  }
  return res.status(status).json({
    error: message,
    ...(error?.code && status < 500 ? { code: error.code } : {}),
    ...(error?.details && status < 500 ? { details: error.details } : {}),
  });
}

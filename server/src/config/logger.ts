const isProd = process.env.NODE_ENV === 'production';

function sanitize(obj: Record<string, unknown>): Record<string, unknown> {
  const blocked = ['password', 'token', 'secret', 'authorization', 'cookie', 'set-cookie'];
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) {
    if (blocked.some(b => k.toLowerCase().includes(b))) {
      out[k] = '[REDACTED]';
    } else if (typeof v === 'object' && v !== null && !Array.isArray(v)) {
      out[k] = sanitize(v as Record<string, unknown>);
    } else {
      out[k] = v;
    }
  }
  return out;
}

export const logger = {
  info(event: string, meta?: Record<string, unknown>) {
    const entry = { level: 'info', event, ...meta, timestamp: new Date().toISOString() };
    if (isProd) {
      console.log(JSON.stringify(entry));
    } else {
      const metaStr = meta ? ' ' + JSON.stringify(sanitize(meta)) : '';
      console.log(`[INFO] ${event}${metaStr}`);
    }
  },

  warn(event: string, meta?: Record<string, unknown>) {
    const entry = { level: 'warn', event, ...meta, timestamp: new Date().toISOString() };
    if (isProd) {
      console.warn(JSON.stringify(entry));
    } else {
      const metaStr = meta ? ' ' + JSON.stringify(sanitize(meta)) : '';
      console.warn(`[WARN] ${event}${metaStr}`);
    }
  },

  error(event: string, meta?: Record<string, unknown>) {
    const entry = { level: 'error', event, ...meta, timestamp: new Date().toISOString() };
    if (isProd) {
      console.error(JSON.stringify(entry));
    } else {
      const metaStr = meta ? ' ' + JSON.stringify(sanitize(meta)) : '';
      console.error(`[ERROR] ${event}${metaStr}`);
    }
  },
};

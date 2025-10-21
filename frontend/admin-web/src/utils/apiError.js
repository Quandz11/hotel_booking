import { message } from 'antd';

// Normalize and display API validation errors on antd Form
export function showFormErrors(form, err, fallbackMessage) {
  const payload = err?.response?.data ?? err;

  // express-validator style: { message, errors: [{ field, message, value }] }
  if (payload && Array.isArray(payload.errors) && payload.errors.length > 0) {
    const fieldMap = new Map();
    payload.errors.forEach((e) => {
      const name = e.field || e.param || e.path || 'form';
      const msg = e.message || e.msg || payload.message || fallbackMessage || 'Validation failed';
      if (!fieldMap.has(name)) fieldMap.set(name, []);
      fieldMap.get(name).push(msg);
    });

    const fields = Array.from(fieldMap.entries()).map(([name, errors]) => ({
      name,
      errors,
    }));

    form?.setFields?.(fields);
    message.error(payload.message || fallbackMessage || 'Validation failed');
    return;
  }

  // Mongoose errorHandler enriched: { message, errors?: [...] }
  if (payload && payload.message) {
    message.error(payload.message);
    return;
  }

  // Fallbacks
  if (typeof err === 'string') {
    message.error(err);
  } else {
    message.error(fallbackMessage || 'Validation failed');
  }
}


export async function createNotification(pool, userId, title, body) {
  const result = await pool.query(
    `INSERT INTO notifications (user_id, title, body)
     VALUES ($1, $2, $3)
     RETURNING id, user_id AS "userId", title, body,
               read_at AS "readAt", created_at AS "createdAt"`,
    [userId, title, body],
  );
  return result.rows[0];
}

export async function writeAuditEvent(
  pool,
  { actorId = null, action, resourceType, resourceId = null, metadata = {} },
) {
  try {
    await pool.query(
      `INSERT INTO audit_events
         (actor_id, action, resource_type, resource_id, metadata)
       VALUES ($1, $2, $3, $4, $5)`,
      [actorId, action, resourceType, resourceId, metadata],
    );
  } catch (error) {
    console.error('audit_event_write_failed', {
      action,
      resourceType,
      code: error.code ?? null,
    });
    throw error;
  }
}

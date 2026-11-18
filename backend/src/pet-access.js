import { HttpError } from './errors.js';
import { SUPPLY_ROLES, requireVerifiedSupplyRole } from './security.js';

export async function assertPetAccess(queryable, req, petId, section) {
  const petResult = await queryable.query(
    'SELECT id, owner_id FROM pets WHERE id = $1',
    [petId],
  );
  const pet = petResult.rows[0];
  if (!pet) throw new HttpError(404, 'Pet was not found.');
  if (req.user.activeRole === 'owner' && pet.owner_id === req.user.id) {
    return pet;
  }
  if (SUPPLY_ROLES.has(req.user.activeRole)) {
    await requireVerifiedSupplyRole(req, queryable);
    const grantResult = await queryable.query(
      `SELECT 1
         FROM pet_access_grants
        WHERE pet_id = $1
          AND owner_id = $2
          AND recipient_id = $3
          AND revoked_at IS NULL
          AND (expires_at IS NULL OR expires_at > now())
          AND sections && $4::text[]
        LIMIT 1`,
      [petId, pet.owner_id, req.user.id, [section]],
    );
    if (grantResult.rowCount > 0) return pet;
  }
  throw new HttpError(403, 'You do not have access to this pet information.');
}

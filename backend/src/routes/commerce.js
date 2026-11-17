import crypto from 'node:crypto';
import { z } from 'zod';
import { HttpError, asyncRoute } from '../errors.js';
import { inTransaction } from '../database.js';
import { requireVerifiedSupplyRole } from '../security.js';
import { createNotification, writeAuditEvent } from '../notifications.js';

const uuid = z.string().uuid();
const productSchema = z.object({
  name: z.string().trim().min(2).max(160),
  price: z.number().positive().max(1_000_000),
  stock: z.number().int().min(0).max(1_000_000),
  imageUrl: z.string().trim().max(2000).default(''),
}).strict();
const orderSchema = z.object({
  items: z.array(z.object({
    productId: uuid,
    quantity: z.number().int().min(1).max(100),
  }).strict()).min(1).max(50),
}).strict().superRefine((value, context) => {
  const ids = value.items.map((item) => item.productId);
  if (new Set(ids).size !== ids.length) {
    context.addIssue({
      code: 'custom',
      message: 'Each product may only appear once.',
      path: ['items'],
    });
  }
});

export function registerCommerceRoutes(publicRouter, router, { pool, config, requireRole }) {
  publicRouter.get('/products', asyncRoute(async (req, res) => {
    const result = await pool.query(
      `SELECT p.id, p.vendor_id, u.display_name AS vendor_name,
              p.name, p.price, p.stock, p.image_url, p.published,
              p.created_at, p.updated_at
         FROM products p
         JOIN users u ON u.id = p.vendor_id
        WHERE p.published = true AND p.stock > 0 AND u.deleted_at IS NULL
        ORDER BY p.name`,
    );
    res.json({ products: mapProducts(result.rows) });
  }));

  router.get('/products/mine', requireRole('vendor'), asyncRoute(async (req, res) => {
    await requireVerifiedSupplyRole(req, pool);
    const result = await pool.query(
      `SELECT id, vendor_id, name, price, stock, image_url, published,
              created_at, updated_at
         FROM products
        WHERE vendor_id = $1
        ORDER BY updated_at DESC`,
      [req.user.id],
    );
    res.json({ products: mapProducts(result.rows) });
  }));

  router.post('/products', requireRole('vendor'), asyncRoute(async (req, res) => {
    await requireVerifiedSupplyRole(req, pool);
    const body = productSchema.parse(req.body);
    const result = await pool.query(
      `INSERT INTO products (vendor_id, name, price, stock, image_url, published)
       VALUES ($1, $2, $3, $4, $5, true)
       RETURNING id, vendor_id, name, price, stock, image_url, published,
                 created_at, updated_at`,
      [req.user.id, body.name, body.price, body.stock, body.imageUrl],
    );
    const product = mapProduct(result.rows[0]);
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: 'product.created',
      resourceType: 'product',
      resourceId: product.id,
    });
    res.status(201).json({ product });
  }));

  router.patch('/products/:id', requireRole('vendor'), asyncRoute(async (req, res) => {
    await requireVerifiedSupplyRole(req, pool);
    const id = uuid.parse(req.params.id);
    const body = productSchema.parse(req.body);
    const result = await pool.query(
      `UPDATE products
          SET name = $3, price = $4, stock = $5, image_url = $6,
              updated_at = now()
        WHERE id = $1 AND vendor_id = $2
        RETURNING id, vendor_id, name, price, stock, image_url, published,
                  created_at, updated_at`,
      [id, req.user.id, body.name, body.price, body.stock, body.imageUrl],
    );
    if (!result.rows[0]) throw new HttpError(404, 'Product was not found.');
    res.json({ product: mapProduct(result.rows[0]) });
  }));

  router.get('/orders', requireRole('owner', 'vendor'), asyncRoute(async (req, res) => {
    if (req.user.activeRole === 'vendor') await requireVerifiedSupplyRole(req, pool);
    const result = await pool.query(
      `SELECT o.id, o.buyer_id, o.status, o.payment_status,
              o.payment_reference, o.total, o.created_at, o.updated_at,
              oi.product_id, oi.vendor_id, oi.quantity, oi.unit_price,
              oi.vendor_status,
              p.name AS product_name
         FROM orders o
         JOIN order_items oi ON oi.order_id = o.id
         JOIN products p ON p.id = oi.product_id
        WHERE ${req.user.activeRole === 'owner'
        ? 'o.buyer_id = $1'
        : 'oi.vendor_id = $1'}
        ORDER BY o.created_at DESC, o.id, p.name`,
      [req.user.id],
    );
    res.json({ orders: groupOrders(result.rows, req.user.activeRole) });
  }));

  router.post('/orders', requireRole('owner'), asyncRoute(async (req, res) => {
    const body = orderSchema.parse(req.body);
    const order = await inTransaction(pool, async (client) => {
      const ids = body.items.map((item) => item.productId).sort();
      const products = await client.query(
        `SELECT id, vendor_id, name, price, stock, published
           FROM products
          WHERE id = ANY($1::uuid[])
          ORDER BY id
          FOR SHARE`,
        [ids],
      );
      if (products.rowCount !== body.items.length ||
          products.rows.some((product) => !product.published)) {
        throw new HttpError(404, 'One or more products are unavailable.');
      }
      const byId = new Map(products.rows.map((product) => [product.id, product]));
      let totalCents = 0;
      const lines = body.items.map((item) => {
        const product = byId.get(item.productId);
        if (product.stock < item.quantity) {
          throw new HttpError(409, `${product.name} does not have enough stock.`);
        }
        const unitPriceCents = Math.round(Number(product.price) * 100);
        totalCents += unitPriceCents * item.quantity;
        return { ...item, product, unitPriceCents };
      });
      if (!Number.isSafeInteger(totalCents)) {
        throw new HttpError(400, 'Order total exceeds the supported amount.');
      }
      const created = await client.query(
        `INSERT INTO orders (buyer_id, total)
         VALUES ($1, $2)
         RETURNING id, buyer_id, status, payment_status,
                   payment_reference, total, created_at, updated_at`,
        [req.user.id, (totalCents / 100).toFixed(2)],
      );
      for (const line of lines) {
        await client.query(
          `INSERT INTO order_items
             (order_id, product_id, vendor_id, quantity, unit_price)
           VALUES ($1, $2, $3, $4, $5)`,
          [
            created.rows[0].id,
            line.product.id,
            line.product.vendor_id,
            line.quantity,
            (line.unitPriceCents / 100).toFixed(2),
          ],
        );
      }
      return created.rows[0];
    });
    await writeAuditEvent(pool, {
      actorId: req.user.id,
      action: 'order.created',
      resourceType: 'order',
      resourceId: order.id,
      metadata: { total: Number(order.total) },
    });
    res.status(201).json({
      order: await loadOrder(pool, order.id, req.user.id, req.user.activeRole),
    });
  }));

  router.post('/orders/:id/pay', requireRole('owner'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const body = z.object({ simulateUnavailable: z.boolean().default(false) })
      .strict().parse(req.body);
    if (body.simulateUnavailable || config.paymentProvider !== 'mock') {
      throw new HttpError(
        503,
        'Payments are unavailable. Configure a supported payment provider and retry.',
      );
    }
    const order = await inTransaction(pool, async (client) => {
      const orderResult = await client.query(
        `SELECT id, payment_status
           FROM orders
          WHERE id = $1 AND buyer_id = $2
          FOR UPDATE`,
        [id, req.user.id],
      );
      const current = orderResult.rows[0];
      if (!current) throw new HttpError(404, 'Order was not found.');
      if (current.payment_status === 'paid') return current;
      if (current.payment_status !== 'pending') {
        throw new HttpError(409, 'This order cannot be paid in its current state.');
      }
      const items = await client.query(
        `SELECT oi.product_id, oi.quantity, p.name, p.stock, p.published
           FROM order_items oi
           JOIN products p ON p.id = oi.product_id
          WHERE oi.order_id = $1
          ORDER BY oi.product_id
          FOR UPDATE OF p`,
        [id],
      );
      if (items.rows.some((item) => !item.published || item.stock < item.quantity)) {
        throw new HttpError(409, 'One or more products no longer have enough stock.');
      }
      for (const item of items.rows) {
        await client.query(
          'UPDATE products SET stock = stock - $2, updated_at = now() WHERE id = $1',
          [item.product_id, item.quantity],
        );
      }
      const paid = await client.query(
        `UPDATE orders
            SET payment_status = 'paid',
                payment_reference = $2,
                updated_at = now()
          WHERE id = $1
          RETURNING id, payment_status`,
        [id, `mock-${crypto.randomUUID()}`],
      );
      return paid.rows[0];
    });
    if (order.payment_status === 'paid') {
      const vendors = await pool.query(
        'SELECT DISTINCT vendor_id FROM order_items WHERE order_id = $1',
        [id],
      );
      await Promise.all(vendors.rows.map((vendor) => createNotification(
        pool,
        vendor.vendor_id,
        'New paid order',
        'An order containing your product has been paid.',
      )));
      await writeAuditEvent(pool, {
        actorId: req.user.id,
        action: 'order.payment_succeeded',
        resourceType: 'order',
        resourceId: id,
        metadata: { provider: 'mock' },
      });
    }
    res.json({ order: await loadOrder(pool, id, req.user.id, req.user.activeRole) });
  }));

  router.patch('/orders/:id/status', requireRole('vendor', 'owner'), asyncRoute(async (req, res) => {
    const id = uuid.parse(req.params.id);
    const { status } = z.object({
      status: z.enum(['Shipped', 'Delivered', 'Cancelled']),
    }).strict().parse(req.body);
    if (req.user.activeRole === 'vendor') await requireVerifiedSupplyRole(req, pool);
    const order = await inTransaction(pool, async (client) => {
      const result = await client.query(
        `SELECT o.id, o.buyer_id, o.status, o.payment_status
           FROM orders o
          WHERE o.id = $1
            AND ${req.user.activeRole === 'owner'
          ? 'o.buyer_id = $2'
          : 'EXISTS (SELECT 1 FROM order_items oi WHERE oi.order_id = o.id AND oi.vendor_id = $2)'}
          FOR UPDATE`,
        [id, req.user.id],
      );
      const current = result.rows[0];
      if (!current) throw new HttpError(404, 'Order was not found.');
      if (req.user.activeRole === 'owner') {
        const allowed = status === 'Cancelled' &&
          current.status === 'Processing' &&
          current.payment_status === 'pending';
        if (!allowed) {
          throw new HttpError(409, 'This order status transition is not allowed.');
        }
        const updated = await client.query(
          `UPDATE orders SET status = $2, updated_at = now()
            WHERE id = $1
            RETURNING id, buyer_id, status, payment_status`,
          [id, status],
        );
        return updated.rows[0];
      } else {
        if (current.payment_status !== 'paid') {
          throw new HttpError(409, 'Only paid orders can be shipped.');
        }
      }

      const itemResult = await client.query(
        `SELECT vendor_status FROM order_items
          WHERE order_id = $1 AND vendor_id = $2
          FOR UPDATE`,
        [id, req.user.id],
      );
      if (itemResult.rowCount === 0) throw new HttpError(404, 'Order was not found.');
      const currentItemStatus = itemResult.rows[0].vendor_status;
      const alreadyUpdated = currentItemStatus === status;
      const canTransition = (status === 'Shipped' && currentItemStatus === 'Processing') ||
        (status === 'Delivered' && currentItemStatus === 'Shipped');
      if (!alreadyUpdated && !canTransition) {
        throw new HttpError(409, 'This order status transition is not allowed.');
      }
      if (!alreadyUpdated) {
        await client.query(
          `UPDATE order_items SET vendor_status = $3
            WHERE order_id = $1 AND vendor_id = $2`,
          [id, req.user.id, status],
        );
        await client.query(
          `UPDATE orders
              SET status = CASE
                    WHEN NOT EXISTS (
                      SELECT 1 FROM order_items
                       WHERE order_id = $1 AND vendor_status <> 'Delivered'
                    ) THEN 'Delivered'
                    WHEN NOT EXISTS (
                      SELECT 1 FROM order_items
                       WHERE order_id = $1
                         AND vendor_status NOT IN ('Shipped', 'Delivered')
                    ) THEN 'Shipped'
                    ELSE status
                  END,
                  updated_at = now()
            WHERE id = $1`,
          [id],
        );
      }
      return current;
    });
    if (req.user.activeRole === 'owner') {
      const vendors = await pool.query(
        'SELECT DISTINCT vendor_id FROM order_items WHERE order_id = $1',
        [id],
      );
      await Promise.all(vendors.rows.map((vendor) => createNotification(
        pool,
        vendor.vendor_id,
        'Order status updated',
        `The buyer ${status.toLowerCase()} this order.`,
      )));
    } else {
      await createNotification(
        pool,
        order.buyer_id,
        'Order status updated',
        `Your order is now ${status.toLowerCase()}.`,
      );
    }
    res.json({
      order: await loadOrder(pool, id, req.user.id, req.user.activeRole),
    });
  }));
}

async function loadOrder(pool, orderId, viewerId, activeRole) {
  const result = await pool.query(
    `SELECT o.id, o.buyer_id, o.status, o.payment_status,
            o.payment_reference, o.total, o.created_at, o.updated_at,
            oi.product_id, oi.vendor_id, oi.quantity, oi.unit_price,
            oi.vendor_status,
            p.name AS product_name
       FROM orders o
       JOIN order_items oi ON oi.order_id = o.id
       JOIN products p ON p.id = oi.product_id
      WHERE o.id = $1 AND (
        ($3 = 'owner' AND o.buyer_id = $2) OR
        ($3 = 'vendor' AND oi.vendor_id = $2)
      )
      ORDER BY p.name`,
    [orderId, viewerId, activeRole],
  );
  const grouped = groupOrders(result.rows, activeRole);
  if (!grouped[0]) throw new HttpError(404, 'Order was not found.');
  return grouped[0];
}

function groupOrders(rows, activeRole) {
  const orders = new Map();
  for (const row of rows) {
    let order = orders.get(row.id);
    if (!order) {
      order = {
        id: row.id,
        buyerId: row.buyer_id,
        status: row.status,
        paymentStatus: row.payment_status,
        paymentReference: row.payment_reference,
        total: Number(row.total),
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        items: [],
        productIds: [],
        quantities: [],
      };
      orders.set(row.id, order);
    }
    order.items.push({
      productId: row.product_id,
      vendorId: row.vendor_id,
      productName: row.product_name,
      quantity: row.quantity,
      unitPrice: Number(row.unit_price),
      vendorStatus: row.vendor_status,
    });
    order.productIds.push(row.product_id);
    order.quantities.push(row.quantity);
  }
  const grouped = [...orders.values()];
  if (activeRole === 'vendor') {
    for (const order of grouped) {
      order.total = order.items.reduce(
        (sum, item) => sum + item.unitPrice * item.quantity,
        0,
      );
      order.status = order.items.every((item) => item.vendorStatus === 'Delivered')
        ? 'Delivered'
        : order.items.every((item) =>
          item.vendorStatus === 'Shipped' || item.vendorStatus === 'Delivered')
          ? 'Shipped'
          : 'Processing';
    }
  }
  return grouped;
}

function mapProducts(rows) {
  return rows.map(mapProduct);
}

function mapProduct(row) {
  return {
    id: row.id,
    vendorId: row.vendor_id,
    vendorName: row.vendor_name,
    name: row.name,
    price: Number(row.price),
    stock: row.stock,
    imageUrl: row.image_url,
    published: row.published,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

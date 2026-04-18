const { logger } = require('../utils/logger');

let pool;

if (process.env.DATABASE_URL) {
  // ─── PostgreSQL cho Render Free Tier ───────────────────
  const { Pool } = require('pg');

  const pgPool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
  });

  // Wrapper tương thích API mysql2
  pool = {
    execute: async (sql, params = []) => {
      let i = 0;
      const pgSql = sql.replace(/\?/g, () => `$${++i}`);
      const result = await pgPool.query(pgSql, params);
      return [result.rows, result.fields];
    },
    query: async (sql, params = []) => {
      let i = 0;
      const pgSql = sql.replace(/\?/g, () => `$${++i}`);
      const result = await pgPool.query(pgSql, params);
      return [result.rows, result.fields];
    },
    getConnection: async () => {
      const client = await pgPool.connect();
      return {
        query: client.query.bind(client),
        execute: async (sql, params = []) => {
          let i = 0;
          const pgSql = sql.replace(/\?/g, () => `$${++i}`);
          const result = await client.query(pgSql, params);
          return [result.rows];
        },
        release: client.release.bind(client),
      };
    },
    _pgPool: pgPool,
  };

  logger.info('📦 Using PostgreSQL (Render Free Tier)');

} else {
  // ─── MySQL cho Local Docker ─────────────────────────────
  const mysql = require('mysql2/promise');

  pool = mysql.createPool({
    host:               process.env.DB_HOST     || 'mysql',
    port:               parseInt(process.env.DB_PORT) || 3306,
    user:               process.env.DB_USER     || 'appuser',
    password:           process.env.DB_PASSWORD,
    database:           process.env.DB_NAME     || 'productdb',
    waitForConnections: true,
    connectionLimit:    10,
    queueLimit:         0,
    ssl:                false,
    connectTimeout:     10000,
    multipleStatements: false,
  });

  logger.info('📦 Using MySQL (Local Docker)');
}

async function testConnection() {
  const conn = await pool.getConnection();
  await conn.query('SELECT 1');
  conn.release();
}

module.exports = { pool, testConnection };

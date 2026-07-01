const request = require('supertest');
const app = require('../src/app');

describe('Tests d\'Intégration - Endpoints d\'API', () => {
  it('GET /api/health devrait retourner un code 200 et un statut valide', async () => {
    const res = await request(app).get('/api/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toHaveProperty('status');
    expect(res.body.status).toBe('UP');
  });

  it('GET /api/debug-ping devrait retourner un diagnostic compatible serverless', async () => {
    const res = await request(app).get('/api/debug-ping?ip=8.8.8.8');
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toBe('OK');
    expect(res.body.output).toContain('Diagnostic serverless OK');
  });
});

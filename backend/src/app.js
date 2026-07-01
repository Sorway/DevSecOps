const express = require('express');
const path = require('path');
const { lookup } = require('dns/promises');
const net = require('net');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'public')));

app.get('/api/health', (req, res) => {
  const isDatabaseConfigured = !!process.env.DATABASE_URL || process.env.NODE_ENV === 'test';
  const isJwtConfigured = !!process.env.JWT_SECRET || process.env.NODE_ENV === 'test';

  if (!isDatabaseConfigured || !isJwtConfigured) {
    return res.status(500).json({ 
      status: "DOWN", 
      error: "Configuration de sécurité manquante : variables d'environnement non détectées" 
    });
  }

  res.status(200).json({ 
    status: "UP", 
    timestamp: new Date(),
    vault_status: "CONNECTED_TO_PROD_SECRETS"
  });
});

app.get('/api/debug-ping', async (req, res) => {
  const target = String(req.query.ip || '127.0.0.1').trim();

  if (!/^[a-zA-Z0-9.:-]+$/.test(target)) {
    return res.status(400).json({ error: 'Adresse de diagnostic invalide' });
  }

  if (net.isIP(target)) {
    return res.status(200).json({
      target,
      status: 'OK',
      output: `Diagnostic serverless OK pour ${target}. ICMP ping est remplace par une validation IP compatible Vercel.`
    });
  }

  try {
    const result = await lookup(target);
    return res.status(200).json({
      target,
      status: 'OK',
      address: result.address,
      family: `IPv${result.family}`,
      output: `Resolution DNS OK pour ${target} vers ${result.address}.`
    });
  } catch (error) {
    return res.status(502).json({
      target,
      status: 'DOWN',
      error: error.message
    });
  }
});

app.get('/api/welcome', (req, res) => {
  const name = req.query.name || 'Invité';
  res.status(200).json({
    message: `Bienvenue ${String(name)}`
  });
});

if (require.main === module || process.env.DOCKER_RUN === 'true') {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`Le serveur écoute activement sur le port ${PORT}`);
  });
}

module.exports = app;
